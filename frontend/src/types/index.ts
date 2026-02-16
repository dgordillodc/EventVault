/**
 * Type definitions for EventVault dApp
 * Centralized types for better maintainability and type safety
 */

// =============================================================================
// ENUMS - Match smart contract enums
// =============================================================================

export enum LockPeriod {
  Flexible = 0,
  Short = 1,    // 7 days
  Medium = 2,   // 30 days
  Long = 3,     // 90 days
}

export enum AccountStatus {
  None = 0,
  Active = 1,
  Frozen = 2,
}

export enum Tier {
  Bronze = 0,
  Silver = 1,
  Gold = 2,
  Platinum = 3,
}

// =============================================================================
// INTERFACES
// =============================================================================

export interface AccountInfo {
  balance: bigint
  pendingInterest: bigint
  lockEndTime: number
  lockPeriod: LockPeriod
  status: AccountStatus
  tier: Tier
}

export interface ContractConfig {
  maxBalance: bigint | undefined
  dailyLimit: bigint | undefined
  baseFee: bigint | undefined
  baseInterestRate: bigint | undefined
  totalDeposited: bigint | undefined
  isPaused: boolean | undefined
}

export interface LockPeriodOption {
  value: LockPeriod
  label: string
  days: number
  apy: string
  apyValue: number
}

export interface ValidationResult {
  isValid: boolean
  error: string | null
}

// =============================================================================
// COMPONENT PROPS
// =============================================================================

export interface StatsCardProps {
  icon: React.ReactNode
  label: string
  value: string
  valueColor?: string
}

export interface DepositCardProps {
  depositAmount: string
  setDepositAmount: (value: string) => void
  lockPeriod: LockPeriod
  setLockPeriod: (value: LockPeriod) => void
  onDeposit: () => void
  isDepositing: boolean
  maxBalance: bigint | undefined
}

export interface WithdrawCardProps {
  withdrawAmount: string
  setWithdrawAmount: (value: string) => void
  onWithdraw: () => void
  isWithdrawing: boolean
  isLocked: boolean | undefined
  lockEndTime: number | undefined
  balance: bigint | undefined
  effectiveFee: bigint | undefined
}

export interface InterestCardProps {
  pendingInterest: bigint | undefined
  lockPeriod: LockPeriod | undefined
  tier: Tier | undefined
  onClaim: () => void
  isClaiming: boolean
}

export interface ContractInfoCardProps {
  config: ContractConfig
  txCount: number
}
