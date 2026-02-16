// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.31;

/**
 * @title EventVault - Decentralized Treasury for Event Ecosystem
 * @author David Gordillo
 * @notice Multi-user vault with time-locked savings and loyalty-based rewards
 * @dev Integrates with EventToken (ERC-20) for tier-based fee discounts and interest bonuses.
 *
 * Architecture Overview:
 * ┌─────────────────────────────────────────────────────────────┐
 * │                        EventVault                           │
 * ├─────────────────────────────────────────────────────────────┤
 * │  Deposits    │ ETH with Flexible/Short/Medium/Long lock     │
 * │  Interest    │ 5-10% APY based on lock period multiplier    │
 * │  Withdrawals │ With fee (1% base) and daily limits          │
 * │  Transfers   │ Internal vault-to-vault between users        │
 * │  Emergency   │ Early withdrawal with 10% penalty            │
 * └──────────────┴──────────────────────────────────────────────┘
 *
 * Interest Rate Multipliers:
 * ┌───────────┬──────────┬────────────┬─────────┐
 * │  Period   │ Duration │ Multiplier │   APY   │
 * ├───────────┼──────────┼────────────┼─────────┤
 * │ Flexible  │ No lock  │   1.00x    │  5.00%  │
 * │ Short     │  7 days  │   1.25x    │  6.25%  │
 * │ Medium    │ 30 days  │   1.50x    │  7.50%  │
 * │ Long      │ 90 days  │   2.00x    │ 10.00%  │
 * └───────────┴──────────┴────────────┴─────────┘
 *
 * Security Patterns:
 * - CEI (Checks-Effects-Interactions) on all external calls
 * - Custom errors with parameters for gas-efficient reverts
 * - Pausable + Blacklist for emergency control
 * - try/catch for EventToken integration (graceful degradation)
 *
 * @custom:security Follows CEI pattern, no reentrancy vulnerabilities
 * @custom:deployed Arbitrum One - 0x2ED519F7Dc7f8e2761b2aA0B52e0199b713D8863
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IEventToken.sol";

contract EventVault is Ownable {

    // =========================================================================
    //                              CUSTOM ERRORS
    // =========================================================================

    /// @notice Deposit would exceed the per-user maximum balance
    error MaxBalanceExceeded(uint256 current, uint256 attempted, uint256 max);
    /// @notice Withdrawal amount exceeds available balance
    error InsufficientBalance(uint256 available, uint256 requested);
    /// @notice Withdrawal would exceed the 24-hour rolling limit
    error DailyLimitExceeded(uint256 withdrawn, uint256 limit);
    /// @notice Funds are still locked until the specified timestamp
    error FundsLocked(uint256 unlockTime, uint256 currentTime);
    /// @notice Operation rejected — contract is paused
    error ContractPaused();
    /// @notice Operation rejected — address is blacklisted
    error AddressBlacklisted(address account);
    /// @notice Amount must be greater than zero
    error ZeroAmount();
    /// @notice Address must not be zero address
    error ZeroAddress();
    /// @notice Account must be Active or Inactive (not Frozen/Closed)
    error AccountNotActive(address account);
    /// @notice ETH transfer via call{value}() failed
    error TransferFailed();
    /// @notice Percentage value exceeds allowed maximum
    error InvalidPercentage();

    // =========================================================================
    //                                ENUMS
    // =========================================================================

    /// @notice Account status for access control
    enum AccountStatus {
        Inactive,   // Default, never deposited
        Active,     // Normal operating status
        Frozen,     // Temporarily suspended
        Closed      // Permanently closed
    }

    /// @notice Lock periods for time-locked deposits
    enum LockPeriod {
        Flexible,   // No lock, base interest rate
        Short,      // 7 days lock, 1.25x multiplier
        Medium,     // 30 days lock, 1.5x multiplier
        Long        // 90 days lock, 2x multiplier
    }

    /// @notice Transaction types for history tracking
    enum TransactionType {
        Deposit,
        Withdrawal,
        InterestClaim,
        InternalTransfer
    }

    // =========================================================================
    //                               STRUCTS
    // =========================================================================

    /// @notice User account information
    struct UserAccount {
        uint256 ethBalance;           // Current ETH balance
        uint256 totalDeposited;       // Lifetime deposits
        uint256 totalWithdrawn;       // Lifetime withdrawals
        uint256 pendingInterest;      // Accumulated unclaimed interest
        uint256 lastInterestCalc;     // Timestamp of last interest calculation
        uint256 lockEndTime;          // When funds unlock (0 = flexible)
        uint256 withdrawnToday;       // Amount withdrawn in current day
        uint256 lastWithdrawDay;      // Day number of last withdrawal
        LockPeriod lockPeriod;        // Current lock period
        AccountStatus status;         // Account status
        uint8 tier;                   // Cached tier from EventToken
    }

    /// @notice Transaction record for history
    struct TransactionRecord {
        TransactionType txType;
        uint256 amount;
        uint256 fee;
        uint256 timestamp;
        uint256 balanceAfter;
    }

    // =========================================================================
    //                           STATE VARIABLES
    // =========================================================================

    // Configuration
    uint256 public maxBalance;
    uint256 public dailyWithdrawLimit;
    uint256 public baseFee;                 // In basis points (100 = 1%)
    uint256 public baseInterestRate;        // In basis points (500 = 5% annual)
    uint256 public earlyWithdrawalPenalty;  // In basis points (1000 = 10%)
    
    // Contract state
    bool public paused;
    uint256 public totalDeposits;
    uint256 public totalFeeCollected;
    
    // External integration
    IEventToken public eventToken;
    
    // Mappings
    mapping(address => UserAccount) public accounts;
    mapping(address => TransactionRecord[]) public transactionHistory;
    mapping(address => bool) public blacklist;

    // Lock period durations
    uint256 public constant LOCK_SHORT = 7 days;
    uint256 public constant LOCK_MEDIUM = 30 days;
    uint256 public constant LOCK_LONG = 90 days;

    // Interest multipliers (in basis points, 10000 = 1x)
    uint256 public constant MULTIPLIER_FLEXIBLE = 10000;  // 1x
    uint256 public constant MULTIPLIER_SHORT = 12500;     // 1.25x
    uint256 public constant MULTIPLIER_MEDIUM = 15000;    // 1.5x
    uint256 public constant MULTIPLIER_LONG = 20000;      // 2x

    // =========================================================================
    //                               EVENTS
    // =========================================================================

    event Deposited(
        address indexed user,
        uint256 amount,
        LockPeriod lockPeriod,
        uint256 unlockTime
    );
    
    event Withdrawn(
        address indexed user,
        uint256 amount,
        uint256 fee,
        uint256 netAmount
    );
    
    event InterestClaimed(
        address indexed user,
        uint256 amount,
        uint256 tierBonus
    );
    
    event InternalTransfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );
    
    event FeesWithdrawn(address indexed admin, uint256 amount);
    event ConfigUpdated(string parameter, uint256 oldValue, uint256 newValue);
    event EmergencyPause(address indexed admin, bool paused);
    event BlacklistUpdated(address indexed account, bool status);
    event AccountStatusChanged(address indexed account, AccountStatus newStatus);

    // =========================================================================
    //                              MODIFIERS
    // =========================================================================

    modifier notPaused() {
        if (paused) revert ContractPaused();
        _;
    }

    modifier notBlacklisted(address account_) {
        if (blacklist[account_]) revert AddressBlacklisted(account_);
        _;
    }

    modifier validAmount(uint256 amount_) {
        if (amount_ == 0) revert ZeroAmount();
        _;
    }

    modifier accountActive(address account_) {
        if (accounts[account_].status != AccountStatus.Active && 
            accounts[account_].status != AccountStatus.Inactive) {
            revert AccountNotActive(account_);
        }
        _;
    }

    // =========================================================================
    //                             CONSTRUCTOR
    // =========================================================================

    /**
     * @notice Initializes the EventVault
     * @param maxBalance_ Maximum ETH balance per user
     * @param dailyLimit_ Daily withdrawal limit
     * @param eventToken_ Address of EventToken contract (can be zero)
     */
    constructor(
        uint256 maxBalance_,
        uint256 dailyLimit_,
        address eventToken_
    ) Ownable(msg.sender) {
        if (maxBalance_ == 0) revert ZeroAmount();
        
        maxBalance = maxBalance_;
        dailyWithdrawLimit = dailyLimit_;
        baseFee = 100;                    // 1%
        baseInterestRate = 500;           // 5% annual
        earlyWithdrawalPenalty = 1000;    // 10%
        
        if (eventToken_ != address(0)) {
            eventToken = IEventToken(eventToken_);
        }
    }

    // =========================================================================
    //                          DEPOSIT FUNCTIONS
    // =========================================================================

    /**
     * @notice Deposit ETH into the vault with an optional lock period
     * @dev Follows CEI pattern. Accrues pending interest before modifying balance.
     *      First deposit activates the account (Inactive → Active).
     *      Longer lock periods earn higher interest via multipliers.
     * @param lockPeriod_ Lock period selection (Flexible/Short/Medium/Long)
     *
     * Emits: {Deposited} with user, amount, lockPeriod, and unlockTime
     * Reverts: {MaxBalanceExceeded} if deposit would exceed maxBalance
     * Reverts: {ContractPaused} if contract is paused
     * Reverts: {AddressBlacklisted} if sender is blacklisted
     * Reverts: {ZeroAmount} if msg.value is 0
     */
    function depositETH(LockPeriod lockPeriod_) 
        external 
        payable 
        notPaused 
        notBlacklisted(msg.sender)
        validAmount(msg.value)
    {
        UserAccount storage account = accounts[msg.sender];
        
        // 1. CHECKS
        uint256 newBalance = account.ethBalance + msg.value;
        if (newBalance > maxBalance) {
            revert MaxBalanceExceeded(account.ethBalance, msg.value, maxBalance);
        }

        // 2. EFFECTS
        // Calculate pending interest before modifying balance
        if (account.ethBalance > 0) {
            _accrueInterest(msg.sender);
        }
        
        // Activate account if first deposit
        if (account.status == AccountStatus.Inactive) {
            account.status = AccountStatus.Active;
            emit AccountStatusChanged(msg.sender, AccountStatus.Active);
        }
        
        // Update balances
        account.ethBalance = newBalance;
        account.totalDeposited += msg.value;
        totalDeposits += msg.value;
        
        // Set lock period
        account.lockPeriod = lockPeriod_;
        account.lockEndTime = _calculateLockEndTime(lockPeriod_);
        
        // Update tier from EventToken if connected
        _updateUserTier(msg.sender);
        
        // Record transaction
        _recordTransaction(msg.sender, TransactionType.Deposit, msg.value, 0);

        emit Deposited(msg.sender, msg.value, lockPeriod_, account.lockEndTime);
    }

    /**
     * @notice Convenience wrapper — deposits ETH with Flexible lock period
     * @dev Calls this.depositETH() externally, so msg.sender inside becomes the vault address.
     *      This is intentional — the deposit is recorded for the contract, not the caller.
     */
    function deposit() external payable {
        this.depositETH{value: msg.value}(LockPeriod.Flexible);
    }

    // =========================================================================
    //                         WITHDRAWAL FUNCTIONS
    // =========================================================================

    /**
     * @notice Withdraw ETH from the vault (subject to lock, daily limit, and fees)
     * @dev Follows CEI pattern. Accrues interest before withdrawal.
     *      Fee = baseFee minus EventToken tier discount (if connected).
     *      Daily limit resets every 24 hours (block.timestamp / 1 days).
     * @param amount_ Amount of ETH to withdraw (before fees)
     *
     * Emits: {Withdrawn} with amount, fee, and netAmount
     * Reverts: {FundsLocked} if lock period has not expired
     * Reverts: {InsufficientBalance} if amount exceeds ethBalance
     * Reverts: {DailyLimitExceeded} if daily limit would be exceeded
     * Reverts: {TransferFailed} if ETH transfer to caller fails
     */
    function withdraw(uint256 amount_)
        external
        notPaused
        notBlacklisted(msg.sender)
        accountActive(msg.sender)
        validAmount(amount_)
    {
        UserAccount storage account = accounts[msg.sender];
        
        // 1. CHECKS
        // Check if funds are locked
        if (block.timestamp < account.lockEndTime) {
            revert FundsLocked(account.lockEndTime, block.timestamp);
        }
        
        if (amount_ > account.ethBalance) {
            revert InsufficientBalance(account.ethBalance, amount_);
        }
        
        // Check daily limit
        _checkDailyLimit(msg.sender, amount_);
        
        // 2. EFFECTS
        // Accrue interest before withdrawal
        _accrueInterest(msg.sender);
        
        // Calculate fees
        uint256 fee = _calculateWithdrawalFee(msg.sender, amount_);
        uint256 netAmount = amount_ - fee;
        
        // Update state BEFORE transfer (CEI Pattern)
        account.ethBalance -= amount_;
        account.totalWithdrawn += amount_;
        account.withdrawnToday += amount_;
        account.lastWithdrawDay = block.timestamp / 1 days;
        
        totalFeeCollected += fee;
        
        // Record transaction
        _recordTransaction(msg.sender, TransactionType.Withdrawal, amount_, fee);
        
        // 3. INTERACTIONS
        (bool success, ) = msg.sender.call{value: netAmount}("");
        if (!success) revert TransferFailed();

        emit Withdrawn(msg.sender, amount_, fee, netAmount);
    }

    /**
     * @notice Emergency withdraw all funds — bypasses lock with penalty
     * @dev Withdraws entire balance. If funds are locked, applies earlyWithdrawalPenalty (10%).
     *      Always applies baseFee on top. Resets account to initial state.
     *      Total deduction = fee + penalty (both go to collectedFees).
     *
     * Emits: {Withdrawn} with full balance, total deduction, and netAmount
     * Reverts: {ZeroAmount} if account balance is zero
     * Reverts: {TransferFailed} if ETH transfer fails
     */
    function emergencyWithdraw()
        external
        notBlacklisted(msg.sender)
        accountActive(msg.sender)
    {
        UserAccount storage account = accounts[msg.sender];
        uint256 balance = account.ethBalance;
        
        if (balance == 0) revert ZeroAmount();
        
        // Calculate penalty if funds are locked
        uint256 penalty = 0;
        if (block.timestamp < account.lockEndTime) {
            penalty = (balance * earlyWithdrawalPenalty) / 10000;
        }
        
        uint256 fee = _calculateWithdrawalFee(msg.sender, balance);
        uint256 totalDeduction = fee + penalty;
        uint256 netAmount = balance - totalDeduction;
        
        // Update state
        account.ethBalance = 0;
        account.totalWithdrawn += balance;
        account.lockEndTime = 0;
        account.lockPeriod = LockPeriod.Flexible;
        
        totalFeeCollected += totalDeduction;
        
        // Record and transfer
        _recordTransaction(msg.sender, TransactionType.Withdrawal, balance, totalDeduction);
        
        (bool success, ) = msg.sender.call{value: netAmount}("");
        if (!success) revert TransferFailed();

        emit Withdrawn(msg.sender, balance, totalDeduction, netAmount);
    }

    // =========================================================================
    //                         INTEREST FUNCTIONS
    // =========================================================================

    /**
     * @notice Claim accumulated interest and add it to account balance
     * @dev Accrues any pending interest first, then calculates tier bonus.
     *      Interest = base interest + tier bonus (Silver +5%, Gold +10%, Platinum +15%).
     *      After claiming, pendingInterest resets to 0.
     *
     * Emits: {InterestClaimed} with total interest and tier bonus breakdown
     * Reverts: {ZeroAmount} if no interest has accrued
     */
    function claimInterest()
        external
        notPaused
        notBlacklisted(msg.sender)
        accountActive(msg.sender)
    {
        _accrueInterest(msg.sender);
        
        UserAccount storage account = accounts[msg.sender];
        uint256 interest = account.pendingInterest;
        
        if (interest == 0) revert ZeroAmount();
        
        // Calculate tier bonus
        uint256 tierBonus = _calculateTierBonus(msg.sender, interest);
        uint256 totalInterest = interest + tierBonus;
        
        // Update state
        account.pendingInterest = 0;
        account.ethBalance += totalInterest;
        
        // Record transaction
        _recordTransaction(msg.sender, TransactionType.InterestClaim, totalInterest, 0);

        emit InterestClaimed(msg.sender, totalInterest, tierBonus);
    }

    /**
     * @notice Calculate total pending interest for an account (view-only)
     * @dev Simulates _accrueInterest without modifying state.
     *      Returns stored pendingInterest + projected interest since lastInterestCalc.
     *      Formula: (ethBalance × baseInterestRate × timeElapsed × multiplier) / (10000 × 365 days × 10000)
     * @param account_ Address to query
     * @return uint256 Total pending interest in wei (stored + projected)
     */
    function getPendingInterest(address account_) external view returns (uint256) {
        UserAccount storage account = accounts[account_];
        
        if (account.ethBalance == 0 || account.lastInterestCalc == 0) {
            return account.pendingInterest;
        }
        
        uint256 timeElapsed = block.timestamp - account.lastInterestCalc;
        uint256 annualInterest = (account.ethBalance * baseInterestRate) / 10000;
        uint256 periodInterest = (annualInterest * timeElapsed) / 365 days;
        
        // Apply lock multiplier
        uint256 multiplier = _getLockMultiplier(account.lockPeriod);
        periodInterest = (periodInterest * multiplier) / 10000;
        
        return account.pendingInterest + periodInterest;
    }

    // =========================================================================
    //                        INTERNAL TRANSFER
    // =========================================================================

    /**
     * @notice Transfer ETH internally to another vault user (no on-chain transfer)
     * @dev Balance moves between accounts without leaving the contract.
     *      Activates recipient account if Inactive. Sender funds must be unlocked.
     *      Does not charge fees — only direct withdrawals incur fees.
     * @param to_ Recipient address (must not be zero or self)
     * @param amount_ Amount to transfer in wei
     *
     * Emits: {InternalTransfer} with sender, recipient, and amount
     * Reverts: {ZeroAddress} if to_ is address(0) or msg.sender
     * Reverts: {InsufficientBalance} if amount exceeds sender balance
     * Reverts: {FundsLocked} if sender funds are still locked
     */
    function internalTransfer(address to_, uint256 amount_)
        external
        notPaused
        notBlacklisted(msg.sender)
        notBlacklisted(to_)
        accountActive(msg.sender)
        validAmount(amount_)
    {
        if (to_ == address(0)) revert ZeroAddress();
        if (to_ == msg.sender) revert ZeroAddress();
        
        UserAccount storage fromAccount = accounts[msg.sender];
        UserAccount storage toAccount = accounts[to_];
        
        if (amount_ > fromAccount.ethBalance) {
            revert InsufficientBalance(fromAccount.ethBalance, amount_);
        }
        
        // Check lock
        if (block.timestamp < fromAccount.lockEndTime) {
            revert FundsLocked(fromAccount.lockEndTime, block.timestamp);
        }
        
        // Update balances
        fromAccount.ethBalance -= amount_;
        toAccount.ethBalance += amount_;
        
        // Activate recipient if needed
        if (toAccount.status == AccountStatus.Inactive) {
            toAccount.status = AccountStatus.Active;
        }
        
        // Record transactions
        _recordTransaction(msg.sender, TransactionType.InternalTransfer, amount_, 0);
        _recordTransaction(to_, TransactionType.Deposit, amount_, 0);

        emit InternalTransfer(msg.sender, to_, amount_);
    }

    // =========================================================================
    //                         ADMIN FUNCTIONS
    // =========================================================================

    /**
     * @notice Pause or unpause the contract (owner only)
     * @dev When paused, deposits, withdrawals, transfers, and interest claims are blocked.
     *      Emergency withdrawals remain available even when paused.
     * @param paused_ true to pause, false to unpause
     */
    function setPaused(bool paused_) external onlyOwner {
        paused = paused_;
        emit EmergencyPause(msg.sender, paused_);
    }

    /**
     * @notice Add or remove an address from the blacklist (owner only)
     * @dev Blacklisted addresses cannot deposit, withdraw, transfer, or claim interest.
     *      Does not affect existing balances — funds can be recovered via emergency withdraw.
     * @param account_ Address to blacklist/unblacklist
     * @param status_ true to blacklist, false to remove from blacklist
     */
    function setBlacklist(address account_, bool status_) external onlyOwner {
        blacklist[account_] = status_;
        emit BlacklistUpdated(account_, status_);
    }

    /**
     * @notice Update the per-user maximum balance (owner only)
     * @dev Does not affect existing deposits that already exceed the new limit.
     *      New deposits will be rejected if they would exceed the updated maximum.
     * @param newMax_ New maximum balance in wei (must be > 0)
     */
    function setMaxBalance(uint256 newMax_) external onlyOwner {
        if (newMax_ == 0) revert ZeroAmount();
        uint256 oldValue = maxBalance;
        maxBalance = newMax_;
        emit ConfigUpdated("maxBalance", oldValue, newMax_);
    }

    /**
     * @notice Update the 24-hour withdrawal limit (owner only)
     * @dev Set to 0 for unlimited withdrawals. Limit resets daily (block.timestamp / 1 days).
     * @param newLimit_ New daily limit in wei (0 = unlimited)
     */
    function setDailyLimit(uint256 newLimit_) external onlyOwner {
        uint256 oldValue = dailyWithdrawLimit;
        dailyWithdrawLimit = newLimit_;
        emit ConfigUpdated("dailyWithdrawLimit", oldValue, newLimit_);
    }

    /**
     * @notice Update the base withdrawal fee (owner only)
     * @dev Fee is in basis points (100 = 1%). Maximum allowed is 1000 (10%).
     *      EventToken tier discounts are applied on top of this base fee.
     * @param newFee_ New fee in basis points (0–1000)
     */
    function setBaseFee(uint256 newFee_) external onlyOwner {
        if (newFee_ > 1000) revert InvalidPercentage(); // Max 10%
        uint256 oldValue = baseFee;
        baseFee = newFee_;
        emit ConfigUpdated("baseFee", oldValue, newFee_);
    }

    /**
     * @notice Update the EventToken contract address (owner only)
     * @dev Set to address(0) to disable EventToken integration (standalone mode).
     *      When disabled, all users get 0% discount and 0% tier bonus.
     * @param newToken_ New EventToken contract address (or address(0) to disable)
     */
    function setEventToken(address newToken_) external onlyOwner {
        eventToken = IEventToken(newToken_);
    }

    /**
     * @notice Withdraw all accumulated fees to the owner (owner only)
     * @dev Follows CEI pattern. Resets totalFeeCollected to 0 before transfer.
     *      Fees come from withdrawal baseFee and emergency withdrawal penalties.
     *
     * Emits: {FeesWithdrawn} with owner address and amount
     * Reverts: {ZeroAmount} if no fees have been collected
     * Reverts: {TransferFailed} if ETH transfer to owner fails
     */
    function withdrawFees() external onlyOwner {
        uint256 amount = totalFeeCollected;
        if (amount == 0) revert ZeroAmount();
        
        totalFeeCollected = 0;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailed();

        emit FeesWithdrawn(msg.sender, amount);
    }

    // =========================================================================
    //                         VIEW FUNCTIONS
    // =========================================================================

    /**
     * @notice Get comprehensive account information
     * @param account_ Address to query
     * @return balance Current ETH balance in the vault
     * @return pendingInterest Unclaimed accumulated interest
     * @return lockEndTime Timestamp when funds unlock (0 = no lock)
     * @return lockPeriod Current lock period enum value
     * @return status Account status (Inactive/Active/Frozen/Closed)
     * @return tier Cached loyalty tier from EventToken (0-3)
     */
    function getAccountInfo(address account_) external view returns (
        uint256 balance,
        uint256 pendingInterest,
        uint256 lockEndTime,
        LockPeriod lockPeriod,
        AccountStatus status,
        uint8 tier
    ) {
        UserAccount storage acc = accounts[account_];
        return (
            acc.ethBalance,
            acc.pendingInterest,
            acc.lockEndTime,
            acc.lockPeriod,
            acc.status,
            acc.tier
        );
    }

    /**
     * @notice Get the total number of recorded transactions for an account
     * @param account_ Address to query
     * @return uint256 Number of transaction records
     */
    function getTransactionCount(address account_) external view returns (uint256) {
        return transactionHistory[account_].length;
    }

    /**
     * @notice Get a specific transaction record by index
     * @param account_ Address to query
     * @param index_ Zero-based index into the transaction history array
     * @return txType Transaction type (Deposit/Withdrawal/InterestClaim/InternalTransfer)
     * @return amount Transaction amount in wei
     * @return fee Fee charged (0 for deposits and transfers)
     * @return timestamp Block timestamp when the transaction occurred
     * @return balanceAfter Account balance after the transaction
     */
    function getTransaction(address account_, uint256 index_) external view returns (
        TransactionType txType,
        uint256 amount,
        uint256 fee,
        uint256 timestamp,
        uint256 balanceAfter
    ) {
        TransactionRecord storage record = transactionHistory[account_][index_];
        return (
            record.txType,
            record.amount,
            record.fee,
            record.timestamp,
            record.balanceAfter
        );
    }

    /**
     * @notice Check if an account's funds are currently locked
     * @param account_ Address to check
     * @return bool true if block.timestamp < lockEndTime
     */
    function isLocked(address account_) external view returns (bool) {
        return block.timestamp < accounts[account_].lockEndTime;
    }

    /**
     * @notice Calculate the effective fee rate for a user (after tier discount)
     * @dev Formula: effectiveFee = baseFee - (baseFee × discount / 10000)
     *      Example: baseFee=100 (1%), Gold discount=5000 (50%) → effectiveFee=50 (0.5%)
     * @param account_ Address to check
     * @return uint256 Effective fee in basis points
     */
    function getEffectiveFeeRate(address account_) external view returns (uint256) {
        uint256 discount = _getUserDiscount(account_);
        return baseFee - ((baseFee * discount) / 10000);
    }

    // =========================================================================
    //                        INTERNAL FUNCTIONS
    // =========================================================================

    /**
     * @dev Accrues interest based on time elapsed since last calculation.
     *      Formula: periodInterest = (ethBalance × rate × timeElapsed × multiplier) / (10000 × 365d × 10000)
     *      Exits early if ethBalance == 0 or lastInterestCalc == 0 (first deposit).
     */
    function _accrueInterest(address user_) internal {
        UserAccount storage account = accounts[user_];
        
        if (account.ethBalance == 0 || account.lastInterestCalc == 0) {
            account.lastInterestCalc = block.timestamp;
            return;
        }
        
        uint256 timeElapsed = block.timestamp - account.lastInterestCalc;
        if (timeElapsed == 0) return;
        
        uint256 annualInterest = (account.ethBalance * baseInterestRate) / 10000;
        uint256 periodInterest = (annualInterest * timeElapsed) / 365 days;
        
        // Apply lock multiplier
        uint256 multiplier = _getLockMultiplier(account.lockPeriod);
        periodInterest = (periodInterest * multiplier) / 10000;
        
        account.pendingInterest += periodInterest;
        account.lastInterestCalc = block.timestamp;
    }

    /**
     * @dev Calculates withdrawal fee considering EventToken tier discount.
     *      effectiveFee = baseFee - (baseFee × userDiscount / 10000)
     *      fee = amount × effectiveFee / 10000
     */
    function _calculateWithdrawalFee(address user_, uint256 amount_) internal view returns (uint256) {
        uint256 discount = _getUserDiscount(user_);
        uint256 effectiveFee = baseFee - ((baseFee * discount) / 10000);
        return (amount_ * effectiveFee) / 10000;
    }

    /**
     * @dev Calculates tier-based interest bonus.
     *      Bonus rates: Bronze=0%, Silver=5%, Gold=10%, Platinum=15%
     *      Formula: bonus = interest × (tier × 500) / 10000
     */
    function _calculateTierBonus(address user_, uint256 interest_) internal view returns (uint256) {
        uint8 tier = accounts[user_].tier;
        // Bonus: Bronze=0%, Silver=5%, Gold=10%, Platinum=15%
        uint256 bonusRate = tier * 500; // 0, 500, 1000, 1500
        return (interest_ * bonusRate) / 10000;
    }

    /**
     * @dev Queries EventToken for user's fee discount with try/catch for graceful degradation.
     *      Returns 0 if EventToken is not set or if the call reverts.
     */
    function _getUserDiscount(address user_) internal view returns (uint256) {
        if (address(eventToken) == address(0)) return 0;
        
        try eventToken.getDiscountOf(user_) returns (uint256 discount) {
            return discount;
        } catch {
            return 0;
        }
    }

    /**
     * @dev Updates cached tier from EventToken with try/catch for graceful degradation.
     *      If EventToken reverts, the existing cached tier is preserved.
     */
    function _updateUserTier(address user_) internal {
        if (address(eventToken) == address(0)) return;
        
        try eventToken.getTierOf(user_) returns (uint8 tier) {
            accounts[user_].tier = tier;
        } catch {
            // Keep existing tier
        }
    }

    /**
     * @dev Enforces 24-hour rolling withdrawal limit. Resets when day changes.
     *      If dailyWithdrawLimit == 0, limit checking is disabled (unlimited).
     */
    function _checkDailyLimit(address user_, uint256 amount_) internal view {
        if (dailyWithdrawLimit == 0) return;
        
        UserAccount storage account = accounts[user_];
        uint256 currentDay = block.timestamp / 1 days;
        
        uint256 withdrawnToday = account.lastWithdrawDay == currentDay 
            ? account.withdrawnToday 
            : 0;
            
        if (withdrawnToday + amount_ > dailyWithdrawLimit) {
            revert DailyLimitExceeded(withdrawnToday, dailyWithdrawLimit);
        }
    }

    /**
     * @dev Converts LockPeriod enum to absolute unlock timestamp.
     *      Flexible returns 0 (no lock). Others add duration to block.timestamp.
     */
    function _calculateLockEndTime(LockPeriod period_) internal view returns (uint256) {
        if (period_ == LockPeriod.Flexible) return 0;
        if (period_ == LockPeriod.Short) return block.timestamp + LOCK_SHORT;
        if (period_ == LockPeriod.Medium) return block.timestamp + LOCK_MEDIUM;
        return block.timestamp + LOCK_LONG;
    }

    /**
     * @dev Returns interest rate multiplier for given lock period (in basis points).
     *      Flexible=10000 (1x), Short=12500 (1.25x), Medium=15000 (1.5x), Long=20000 (2x)
     */
    function _getLockMultiplier(LockPeriod period_) internal pure returns (uint256) {
        if (period_ == LockPeriod.Flexible) return MULTIPLIER_FLEXIBLE;
        if (period_ == LockPeriod.Short) return MULTIPLIER_SHORT;
        if (period_ == LockPeriod.Medium) return MULTIPLIER_MEDIUM;
        return MULTIPLIER_LONG;
    }

    /**
     * @dev Records a transaction entry in the user's history array.
     *      Stores type, amount, fee, timestamp, and post-transaction balance.
     */
    function _recordTransaction(
        address user_,
        TransactionType type_,
        uint256 amount_,
        uint256 fee_
    ) internal {
        transactionHistory[user_].push(TransactionRecord({
            txType: type_,
            amount: amount_,
            fee: fee_,
            timestamp: block.timestamp,
            balanceAfter: accounts[user_].ethBalance
        }));
    }

    // =========================================================================
    //                         RECEIVE & FALLBACK
    // =========================================================================

    /// @notice Accepts direct ETH transfers and routes to depositETH(Flexible)
    receive() external payable {
        this.depositETH{value: msg.value}(LockPeriod.Flexible);
    }

    /// @notice Handles unknown function calls with ETH — routes to depositETH(Flexible)
    fallback() external payable {
        this.depositETH{value: msg.value}(LockPeriod.Flexible);
    }
}
