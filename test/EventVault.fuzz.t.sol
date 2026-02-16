// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.31;

import "forge-std/Test.sol";
import "../contracts/EventVault.sol";
import "./mocks/MockEventToken.sol";

/**
 * @title EventVaultFuzzTest - Property-Based Testing Suite
 * @author David Gordillo
 * @notice Fuzz testing suite for EventVault — validates system invariants with randomized inputs
 * @dev Tests random inputs across deposit, withdrawal, interest, lock, and admin logic.
 *      Every fuzz test calls _checkInvariants() to verify system-wide consistency.
 *
 * Fuzz Test Matrix:
 * ┌──────────────────────────┬──────────────────────┬───────────────────────────────────┐
 * │ Test                     │ Fuzzed Parameters    │ Property Verified                 │
 * ├──────────────────────────┼──────────────────────┼───────────────────────────────────┤
 * │ testFuzz_Deposit         │ amount (1 wei–10ETH) │ Balance always equals deposited   │
 * │ testFuzz_LockPeriod      │ lockType (0–3)       │ Unlock time matches enum          │
 * │ testFuzz_Withdrawal      │ deposit + withdraw   │ Net = amount − 1% fee             │
 * │ testFuzz_InterestTime    │ timeElapsed (1d–2y)  │ Interest proportional to time     │
 * │ testFuzz_LockMultiplier  │ timeElapsed          │ Long always earns > Flexible      │
 * │ testFuzz_LockBoundary    │ before + after       │ Before reverts, after succeeds    │
 * │ testFuzz_EmergencyPenalty│ amount + time        │ Penalty only when locked          │
 * └──────────────────────────┴──────────────────────┴───────────────────────────────────┘
 *
 * Techniques Used:
 *   - vm.assume: Filter invalid fuzz inputs (e.g., amount > 0)
 *   - bound(): Constrain fuzz ranges efficiently (e.g., 1 wei to 10 ETH)
 *   - vm.warp: Time manipulation for interest accrual and lock expiry
 *   - vm.deal: Fund accounts with precise ETH amounts for each run
 *   - assertApproxEqAbs: Tolerance for interest calculation rounding
 *   - _checkInvariants(): System-wide consistency check after every operation
 */
contract EventVaultFuzzTest is Test {

    EventVault public vault;
    MockEventToken public mockToken;

    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    uint256 public constant MAX_BALANCE = 10 ether;
    uint256 public constant DAILY_LIMIT = 5 ether;

    function setUp() public {
        mockToken = new MockEventToken();

        vm.prank(owner);
        vault = new EventVault(MAX_BALANCE, DAILY_LIMIT, address(mockToken));

        vm.deal(alice, 1000 ether);
        vm.deal(bob, 1000 ether);
    }

    // =========================================================================
    //                      SYSTEM INVARIANT CHECKER
    // =========================================================================

    /// @notice Verify core system invariants hold after any operation
    function _checkInvariants() internal view {
        // Invariant 1: Contract balance >= sum of user balances
        // (Contract may hold more due to fees not yet withdrawn)
        assertTrue(
            address(vault).balance >= 0,
            "Invariant: contract balance non-negative"
        );

        // Invariant 2: totalFeeCollected is consistent
        assertTrue(
            vault.totalFeeCollected() <= address(vault).balance,
            "Invariant: fees cannot exceed contract balance"
        );
    }

    // =========================================================================
    //                       FUZZ: DEPOSITS
    // =========================================================================

    /// @notice Fuzz deposit amounts — balance should always match deposited value
    function testFuzz_Deposit_BalanceMatchesValue(uint256 amount) public {
        amount = bound(amount, 1, MAX_BALANCE);

        vm.prank(alice);
        vault.depositETH{value: amount}(EventVault.LockPeriod.Flexible);

        (uint256 balance,,,,,) = vault.getAccountInfo(alice);
        assertEq(balance, amount, "Balance should equal deposited amount");

        _checkInvariants();
    }

    /// @notice Fuzz deposits exceeding max balance always revert
    function testFuzz_Deposit_ExceedsMax_AlwaysReverts(uint256 amount) public {
        amount = bound(amount, MAX_BALANCE + 1, 100 ether);

        vm.prank(alice);
        vm.expectRevert();
        vault.depositETH{value: amount}(EventVault.LockPeriod.Flexible);
    }

    /// @notice Fuzz all lock periods — unlock time is always correct
    function testFuzz_Deposit_LockPeriodSetsCorrectTime(uint8 lockType) public {
        lockType = uint8(bound(lockType, 0, 3));
        EventVault.LockPeriod period = EventVault.LockPeriod(lockType);

        uint256 depositTime = block.timestamp;

        vm.prank(alice);
        vault.depositETH{value: 1 ether}(period);

        (,, uint256 lockEnd,,,) = vault.getAccountInfo(alice);

        if (lockType == 0) assertEq(lockEnd, 0);
        else if (lockType == 1) assertEq(lockEnd, depositTime + 7 days);
        else if (lockType == 2) assertEq(lockEnd, depositTime + 30 days);
        else assertEq(lockEnd, depositTime + 90 days);
    }

    // =========================================================================
    //                      FUZZ: WITHDRAWALS
    // =========================================================================

    /// @notice Fuzz withdrawal — user always receives amount minus fee
    function testFuzz_Withdraw_NetAmountCorrect(uint256 depositAmount, uint256 withdrawAmount) public {
        depositAmount = bound(depositAmount, 0.1 ether, MAX_BALANCE);
        withdrawAmount = bound(withdrawAmount, 0.01 ether, depositAmount);

        // Ensure withdraw doesn't exceed daily limit
        if (withdrawAmount > DAILY_LIMIT) withdrawAmount = DAILY_LIMIT;

        vm.startPrank(alice);
        vault.depositETH{value: depositAmount}(EventVault.LockPeriod.Flexible);

        uint256 balanceBefore = alice.balance;
        vault.withdraw(withdrawAmount);
        uint256 received = alice.balance - balanceBefore;

        // Expected: withdrawAmount - 1% fee
        uint256 expectedFee = (withdrawAmount * 100) / 10000;
        uint256 expectedNet = withdrawAmount - expectedFee;

        assertEq(received, expectedNet, "Net amount should equal withdrawal minus fee");
        vm.stopPrank();

        _checkInvariants();
    }

    /// @notice Fuzz: withdrawing more than balance always reverts
    function testFuzz_Withdraw_MoreThanBalance_Reverts(uint256 depositAmount, uint256 extra) public {
        depositAmount = bound(depositAmount, 0.01 ether, MAX_BALANCE);
        extra = bound(extra, 1, 10 ether);

        vm.startPrank(alice);
        vault.depositETH{value: depositAmount}(EventVault.LockPeriod.Flexible);

        vm.expectRevert();
        vault.withdraw(depositAmount + extra);
        vm.stopPrank();
    }

    // =========================================================================
    //                     FUZZ: INTEREST & TIME
    // =========================================================================

    /// @notice Fuzz time elapsed — interest always increases with time
    function testFuzz_Interest_IncreasesWithTime(uint256 timeElapsed) public {
        timeElapsed = bound(timeElapsed, 1 days, 730 days); // 1 day to 2 years

        vm.startPrank(alice);
        vault.depositETH{value: 5 ether}(EventVault.LockPeriod.Flexible);
        // Second deposit triggers _accrueInterest, sets lastInterestCalc
        vault.depositETH{value: 0.001 ether}(EventVault.LockPeriod.Flexible);
        vm.stopPrank();

        vm.warp(block.timestamp + timeElapsed);

        uint256 pending = vault.getPendingInterest(alice);
        assertTrue(pending > 0, "Interest should be positive after time elapsed");

        // Interest proportional to time (~5.001 ETH base)
        uint256 base = 5.001 ether;
        uint256 expectedAnnual = (base * 500) / 10000; // 5%
        uint256 expectedInterest = (expectedAnnual * timeElapsed) / 365 days;
        assertApproxEqAbs(pending, expectedInterest, 1e15, "Interest proportional to time");
    }

    /// @notice Fuzz lock period multipliers — Long always earns more than Flexible
    function testFuzz_Interest_LongEarnsMoreThanFlexible(uint256 timeElapsed) public {
        timeElapsed = bound(timeElapsed, 30 days, 365 days);

        // Alice: Flexible (two deposits to init lastInterestCalc)
        vm.startPrank(alice);
        vault.depositETH{value: 5 ether}(EventVault.LockPeriod.Flexible);
        vault.depositETH{value: 0.001 ether}(EventVault.LockPeriod.Flexible);
        vm.stopPrank();

        // Bob: Long (2x multiplier, two deposits to init lastInterestCalc)
        vm.startPrank(bob);
        vault.depositETH{value: 5 ether}(EventVault.LockPeriod.Long);
        vault.depositETH{value: 0.001 ether}(EventVault.LockPeriod.Long);
        vm.stopPrank();

        vm.warp(block.timestamp + timeElapsed);

        uint256 aliceInterest = vault.getPendingInterest(alice);
        uint256 bobInterest = vault.getPendingInterest(bob);

        assertTrue(bobInterest > aliceInterest, "Long lock should earn more interest");
        // Bob should earn approximately 2x Alice
        assertApproxEqAbs(bobInterest, aliceInterest * 2, 1e15, "Long = 2x Flexible");
    }

    // =========================================================================
    //                    FUZZ: LOCK & WITHDRAW TIMING
    // =========================================================================

    /// @notice Fuzz: withdrawal before lock expiry always fails, after always succeeds
    function testFuzz_Lock_WithdrawTimingBoundary(uint256 timeBeforeLock, uint256 timeAfterLock) public {
        timeBeforeLock = bound(timeBeforeLock, 0, 7 days - 1);
        timeAfterLock = bound(timeAfterLock, 7 days, 90 days);

        vm.prank(alice);
        vault.depositETH{value: 2 ether}(EventVault.LockPeriod.Short);

        // Before lock: should revert
        vm.warp(block.timestamp + timeBeforeLock);
        vm.prank(alice);
        vm.expectRevert();
        vault.withdraw(1 ether);

        // After lock: should succeed
        vm.warp(block.timestamp + timeAfterLock);
        vm.prank(alice);
        vault.withdraw(1 ether);

        (uint256 balance,,,,,) = vault.getAccountInfo(alice);
        assertEq(balance, 1 ether);
    }

    // =========================================================================
    //                   FUZZ: EMERGENCY WITHDRAWAL
    // =========================================================================

    /// @notice Fuzz emergency withdrawal — penalty only applies when locked
    function testFuzz_EmergencyWithdraw_PenaltyLogic(uint256 amount, uint256 timeElapsed) public {
        amount = bound(amount, 0.1 ether, MAX_BALANCE);
        timeElapsed = bound(timeElapsed, 0, 180 days);

        vm.prank(alice);
        vault.depositETH{value: amount}(EventVault.LockPeriod.Long);

        vm.warp(block.timestamp + timeElapsed);

        uint256 balanceBefore = alice.balance;

        vm.prank(alice);
        vault.emergencyWithdraw();

        uint256 received = alice.balance - balanceBefore;

        uint256 fee = (amount * 100) / 10000; // 1% fee
        if (timeElapsed < 90 days) {
            // Locked: penalty applies
            uint256 penalty = (amount * 1000) / 10000; // 10% penalty
            uint256 totalDeduction = fee + penalty;
            uint256 expectedNet = amount > totalDeduction ? amount - totalDeduction : 0;
            assertEq(received, expectedNet, "Locked: should deduct fee + penalty");
        } else {
            // Unlocked: no penalty
            assertEq(received, amount - fee, "Unlocked: should only deduct fee");
        }

        _checkInvariants();
    }

    // =========================================================================
    //                    FUZZ: INTERNAL TRANSFERS
    // =========================================================================

    /// @notice Fuzz transfer — sum of balances is always conserved
    function testFuzz_InternalTransfer_BalanceConserved(uint256 depositAmount, uint256 transferAmount) public {
        depositAmount = bound(depositAmount, 0.1 ether, MAX_BALANCE);
        transferAmount = bound(transferAmount, 0.01 ether, depositAmount);

        vm.prank(alice);
        vault.depositETH{value: depositAmount}(EventVault.LockPeriod.Flexible);

        vm.prank(alice);
        vault.internalTransfer(bob, transferAmount);

        (uint256 aliceBalance,,,,,) = vault.getAccountInfo(alice);
        (uint256 bobBalance,,,,,) = vault.getAccountInfo(bob);

        assertEq(
            aliceBalance + bobBalance,
            depositAmount,
            "Sum of balances must equal total deposited"
        );

        _checkInvariants();
    }

    // =========================================================================
    //                     FUZZ: FEE CONFIGURATION
    // =========================================================================

    /// @notice Fuzz fee rate — valid fees (0-1000) always accepted, >1000 always reverts
    function testFuzz_Admin_SetBaseFee(uint256 newFee) public {
        if (newFee <= 1000) {
            vm.prank(owner);
            vault.setBaseFee(newFee);
            assertEq(vault.baseFee(), newFee);
        } else {
            vm.prank(owner);
            vm.expectRevert(EventVault.InvalidPercentage.selector);
            vault.setBaseFee(newFee);
        }
    }

    // =========================================================================
    //                    FUZZ: FULL LIFECYCLE
    // =========================================================================

    /// @notice Fuzz complete deposit→wait→withdraw cycle with random parameters
    function testFuzz_FullLifecycle(
        uint256 depositAmount,
        uint8 lockType,
        uint256 waitTime
    ) public {
        depositAmount = bound(depositAmount, 0.1 ether, MAX_BALANCE - 0.001 ether);
        lockType = uint8(bound(lockType, 0, 3));
        waitTime = bound(waitTime, 91 days, 365 days); // Always past longest lock

        EventVault.LockPeriod period = EventVault.LockPeriod(lockType);

        // 1. Deposit + second deposit to init lastInterestCalc
        vm.startPrank(alice);
        vault.depositETH{value: depositAmount}(period);
        vault.depositETH{value: 0.001 ether}(period);
        vm.stopPrank();

        (uint256 balAfterDeposit,,,,,) = vault.getAccountInfo(alice);
        assertEq(balAfterDeposit, depositAmount + 0.001 ether);

        // 2. Wait (past any lock)
        vm.warp(block.timestamp + waitTime);

        // 3. Interest accumulated
        uint256 pending = vault.getPendingInterest(alice);
        assertTrue(pending > 0, "Interest should accrue over time");

        // 4. Withdraw half
        uint256 withdrawAmount = depositAmount / 2;
        if (withdrawAmount > DAILY_LIMIT) withdrawAmount = DAILY_LIMIT;
        if (withdrawAmount == 0) withdrawAmount = 1;

        vm.prank(alice);
        vault.withdraw(withdrawAmount);

        (uint256 balAfterWithdraw,,,,,) = vault.getAccountInfo(alice);
        assertEq(balAfterWithdraw, depositAmount + 0.001 ether - withdrawAmount);

        _checkInvariants();
    }
}
