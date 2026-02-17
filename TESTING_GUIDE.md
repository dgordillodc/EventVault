# 🧪 EventVault Testing Guide

Complete testing guide for EventVault smart contract.

**Result: 19/19 manual tests passed ✅ | 100/100 automated tests passed ✅**

---

## Part 1: Manual Testing (Remix IDE)

### 📋 Test Environment Setup

#### Prerequisites
- Remix IDE ([remix.ethereum.org](https://remix.ethereum.org))
- Remix VM (Cancun) - provides test accounts with 100 ETH each
- Solidity Compiler 0.8.31

#### File Structure in Remix
```
contracts/
├── EventVault.sol
└── interfaces/
    └── IEventToken.sol
```

#### Deployment Parameters
```solidity
maxBalance_:  5000000000000000000   // 5 ETH
dailyLimit_:  1000000000000000000   // 1 ETH  
eventToken_:  0x0000000000000000000000000000000000000000
```

#### Accounts
- **Account 1** (0x5B38...eddC4): Contract Owner
- **Account 2**: Regular User

---

### 🧪 Test Results

### 1. Deposit Tests

#### Test 1.1 — Basic Deposit (Flexible) ✅
```
Account:   Account 1
Value:     1 Ether
Function:  depositETH(0)
Expected:  Success
Result:    ✅ PASSED — balance = 1 ETH, status = Active, lockPeriod = 0
```

#### Test 1.2 — Deposit with Lock Period (Medium) ✅
```
Account:   Account 1
Value:     2 Ether
Function:  depositETH(2)
Expected:  Success, lockEndTime set
Result:    ✅ PASSED — balance = 3 ETH, lockPeriod = 2, lockEndTime = 1772841041
```

#### Test 1.3 — Exceed Max Balance ✅
```
Account:   Account 1
Value:     6 Ether
Function:  depositETH(0)
Expected:  Revert
Result:    ✅ PASSED — MaxBalanceExceeded
```

#### Test 1.4 — Zero Amount ✅
```
Account:   Account 1
Value:     0
Function:  depositETH(0)
Expected:  Revert
Result:    ✅ PASSED — ZeroAmount
```

---

### 2. Withdrawal Tests

#### Test 2.1 — Withdraw Locked Funds ✅
```
Account:   Account 1 (has Medium lock)
Function:  withdraw(500000000000000000)  // 0.5 ETH
Expected:  Revert
Result:    ✅ PASSED — FundsLocked
```

#### Test 2.2 — Basic Withdrawal ✅
```
Account:   Account 2 (deposited 2 ETH Flexible first)
Function:  withdraw(500000000000000000)  // 0.5 ETH
Expected:  Success, fee deducted
Result:    ✅ PASSED — Withdrawn event emitted with fee
```

#### Test 2.3 — Exceed Daily Limit ✅
```
Account:   Account 2 (already withdrew 0.5 ETH today)
Function:  withdraw(1000000000000000000)  // 1 ETH
Expected:  Revert
Result:    ✅ PASSED — DailyLimitExceeded
```

#### Test 2.4 — Insufficient Balance ✅
```
Account:   Account 2
Function:  withdraw(5000000000000000000)  // 5 ETH
Expected:  Revert
Result:    ✅ PASSED — InsufficientBalance
```

---

### 3. Interest Tests

#### Test 3.1 — Calculate Pending Interest ✅
```
Account:   Account 2
Function:  getPendingInterest(address)
Expected:  Returns accumulated interest > 0
Result:    ✅ PASSED — Returned 354356925418 (interest accruing)
```

#### Test 3.2 — Claim Interest ✅
```
Account:   Account 2
Function:  claimInterest()
Expected:  Success
Result:    ✅ PASSED — Interest claimed
```

---

### 4. Admin Tests (Account 1 — Owner)

#### Test 4.1 — Update Base Fee ✅
```
Account:   Account 1 (owner)
Function:  setBaseFee(200)  // 2%
Expected:  Success
Result:    ✅ PASSED — Fee updated
```

#### Test 4.2 — Pause Contract ✅
```
Account:   Account 1 (owner)
Function:  setPaused(true)
Expected:  Success
Result:    ✅ PASSED — Contract paused
```

#### Test 4.3 — Deposit While Paused ✅
```
Account:   Account 2
Value:     1 Ether
Function:  depositETH(0)
Expected:  Revert
Result:    ✅ PASSED — ContractPaused
```

#### Test 4.4 — Unpause Contract ✅
```
Account:   Account 1 (owner)
Function:  setPaused(false)
Expected:  Success
Result:    ✅ PASSED — Contract unpaused
```

#### Test 4.5 — Non-Owner Access ✅
```
Account:   Account 2 (not owner)
Function:  setBaseFee(300)
Expected:  Revert
Result:    ✅ PASSED — OwnableUnauthorizedAccount
```

---

### 5. Security Tests

#### Test 5.1 — Blacklist Address ✅
```
Account:   Account 1 (owner)
Function:  setBlacklist(Account2_address, true)
Expected:  Success
Result:    ✅ PASSED — Address blacklisted
```

#### Test 5.2 — Operation While Blacklisted ✅
```
Account:   Account 2 (blacklisted)
Value:     1 Ether
Function:  depositETH(0)
Expected:  Revert
Result:    ✅ PASSED — AddressBlacklisted
```

#### Test 5.3 — Remove from Blacklist ✅
```
Account:   Account 1 (owner)
Function:  setBlacklist(Account2_address, false)
Expected:  Success
Result:    ✅ PASSED — Blacklist removed
```

---

### 6. Fee Collection

#### Test 6.1 — Withdraw Accumulated Fees ✅
```
Account:   Account 1 (owner)
Function:  withdrawFees()
Expected:  Success
Result:    ✅ PASSED — Fees collected
```

---

### 📊 Manual Test Summary

| # | Category | Test | Result |
|---|----------|------|--------|
| 1.1 | Deposit | Basic Flexible | ✅ |
| 1.2 | Deposit | With Lock (Medium) | ✅ |
| 1.3 | Deposit | Exceed Max Balance | ✅ |
| 1.4 | Deposit | Zero Amount | ✅ |
| 2.1 | Withdraw | Locked Funds | ✅ |
| 2.2 | Withdraw | Basic Withdrawal | ✅ |
| 2.3 | Withdraw | Exceed Daily Limit | ✅ |
| 2.4 | Withdraw | Insufficient Balance | ✅ |
| 3.1 | Interest | Calculate Pending | ✅ |
| 3.2 | Interest | Claim Interest | ✅ |
| 4.1 | Admin | Update Fee | ✅ |
| 4.2 | Admin | Pause Contract | ✅ |
| 4.3 | Admin | Deposit While Paused | ✅ |
| 4.4 | Admin | Unpause Contract | ✅ |
| 4.5 | Admin | Non-Owner Access | ✅ |
| 5.1 | Security | Blacklist Address | ✅ |
| 5.2 | Security | Operation Blacklisted | ✅ |
| 5.3 | Security | Remove Blacklist | ✅ |
| 6.1 | Fees | Withdraw Fees | ✅ |

**Total: 19/19 passed ✅**

---

## Part 2: Foundry Automated Testing

Professional-grade test suite with **100 tests** (88 unit + 12 fuzz).

**Result: 100/100 tests passed ✅ — 100% coverage across all metrics**

### Run Tests

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone and enter the project
git clone https://github.com/dgordillodc/EventVault.git
cd EventVault

# Install dependencies
forge install foundry-rs/forge-std
forge install OpenZeppelin/openzeppelin-contracts

# Run all tests
forge test -vvv

# Run with gas report
forge test --gas-report

# Run coverage
forge coverage

# Run only fuzz tests
forge test --match-contract Fuzz -vvv
```

### Coverage Report

| File | Lines | Statements | Branches | Functions |
|------|-------|------------|----------|-----------|
| EventVault.sol | 100.00% (210/210) | 100.00% (235/235) | 100.00% (41/41) | 100.00% (35/35) |
| MockEventToken.sol | 100.00% (12/12) | 100.00% (7/7) | 100.00% (4/4) | 100.00% (5/5) |

> ✅ **100% coverage across all metrics** — Lines, Statements, Branches, and Functions

---

## Notes

- All ETH values in wei (1 ETH = 10^18 wei)
- Lock periods: 0=Flexible, 1=Short(7d), 2=Medium(30d), 3=Long(90d)
- Fees in basis points (100 = 1%, 200 = 2%)
- Daily limit resets every 24 hours
- Bug found and fixed during B5 testing: `withdraw()` was not validating fund lock status
