/**
 * Validation functions for EventVault operations
 * Validates user input before sending transactions to the contract
 */

import { ValidationResult } from '../types'
import { formatETH } from './utils'

// =============================================================================
// DEPOSIT VALIDATION
// =============================================================================

interface DepositValidationParams {
  amount: string
  currentBalance: bigint | undefined
  maxBalance: bigint | undefined
}

export function validateDeposit({
  amount,
  currentBalance,
  maxBalance,
}: DepositValidationParams): ValidationResult {
  const numAmount = Number(amount)

  // Check if amount is provided and valid
  if (!amount || numAmount <= 0) {
    return {
      isValid: false,
      error: 'Enter an amount greater than 0',
    }
  }

  // Check max balance limit
  const maxBalanceNum = maxBalance ? Number(maxBalance) / 1e18 : 5
  const currentBalanceNum = currentBalance ? Number(currentBalance) / 1e18 : 0
  const newTotal = currentBalanceNum + numAmount

  if (newTotal > maxBalanceNum) {
    const available = maxBalanceNum - currentBalanceNum
    return {
      isValid: false,
      error: `Exceeds max balance (${maxBalanceNum} ETH). You can deposit up to ${available.toFixed(4)} ETH`,
    }
  }

  return { isValid: true, error: null }
}

// =============================================================================
// WITHDRAW VALIDATION
// =============================================================================

interface WithdrawValidationParams {
  amount: string
  currentBalance: bigint | undefined
  isLocked: boolean | undefined
  lockEndTime: number | undefined
  dailyLimit: bigint | undefined
}

export function validateWithdraw({
  amount,
  currentBalance,
  isLocked,
  lockEndTime,
  dailyLimit,
}: WithdrawValidationParams): ValidationResult {
  const numAmount = Number(amount)

  // Check if amount is provided and valid
  if (!amount || numAmount <= 0) {
    return {
      isValid: false,
      error: 'Enter an amount greater than 0',
    }
  }

  // Check if funds are locked
  if (isLocked && lockEndTime) {
    const unlockDate = new Date(lockEndTime * 1000).toLocaleDateString()
    return {
      isValid: false,
      error: `Funds locked until ${unlockDate}`,
    }
  }

  // Check sufficient balance
  const currentBalanceNum = currentBalance ? Number(currentBalance) / 1e18 : 0
  if (numAmount > currentBalanceNum) {
    return {
      isValid: false,
      error: `Insufficient balance. Max: ${currentBalanceNum.toFixed(6)} ETH`,
    }
  }

  // Check daily limit
  const dailyLimitNum = dailyLimit ? Number(dailyLimit) / 1e18 : 1
  if (numAmount > dailyLimitNum) {
    return {
      isValid: false,
      error: `Exceeds daily limit (${dailyLimitNum} ETH)`,
    }
  }

  return { isValid: true, error: null }
}

// =============================================================================
// CLAIM VALIDATION
// =============================================================================

interface ClaimValidationParams {
  pendingInterest: bigint | undefined
}

export function validateClaim({
  pendingInterest,
}: ClaimValidationParams): ValidationResult {
  if (!pendingInterest || pendingInterest === 0n) {
    return {
      isValid: false,
      error: 'No interest to claim',
    }
  }

  return { isValid: true, error: null }
}
