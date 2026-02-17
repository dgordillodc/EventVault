/**
 * Application constants
 * Centralized configuration values for easy maintenance
 */

import { LockPeriod, LockPeriodOption } from '../types'

// =============================================================================
// CONTRACT ADDRESSES
// =============================================================================

export const CONTRACT_ADDRESS = '0x2ED519F7Dc7f8e2761b2aA0B52e0199b713D8863' as `0x${string}`
export const EVENT_TOKEN_ADDRESS = '0x030ae3125a9cdAD35B933D4f92CccdE78934A778' as `0x${string}`

// =============================================================================
// NETWORK CONFIGURATION
// =============================================================================

export const ARBITRUM_RPC_URL = 'https://arb1.arbitrum.io/rpc'
export const ARBISCAN_URL = 'https://arbiscan.io'

// =============================================================================
// LOCK PERIODS CONFIGURATION
// =============================================================================

export const LOCK_PERIOD_OPTIONS: LockPeriodOption[] = [
  { value: LockPeriod.Flexible, label: 'Flexible', days: 0, apy: '5%', apyValue: 5.0 },
  { value: LockPeriod.Short, label: '7 days', days: 7, apy: '6.25%', apyValue: 6.25 },
  { value: LockPeriod.Medium, label: '30 days', days: 30, apy: '7.5%', apyValue: 7.5 },
  { value: LockPeriod.Long, label: '90 days', days: 90, apy: '10%', apyValue: 10.0 },
]

// =============================================================================
// TIER CONFIGURATION
// =============================================================================

export const TIER_CONFIG = {
  0: { name: 'Bronze', color: 'text-orange-400', discount: 0 },
  1: { name: 'Silver', color: 'text-gray-300', discount: 25 },
  2: { name: 'Gold', color: 'text-yellow-400', discount: 50 },
  3: { name: 'Platinum', color: 'text-purple-400', discount: 75 },
} as const

// =============================================================================
// STATUS CONFIGURATION
// =============================================================================

export const STATUS_CONFIG = {
  0: { name: 'None', color: 'text-gray-500' },
  1: { name: 'Active', color: 'text-green-400' },
  2: { name: 'Frozen', color: 'text-red-400' },
} as const

// =============================================================================
// UI CONFIGURATION
// =============================================================================

export const TOAST_CONFIG = {
  position: 'top-center' as const,
  duration: 4000,
}

// =============================================================================
// EXTERNAL LINKS
// =============================================================================

export const EXTERNAL_LINKS = {
  contract: `${ARBISCAN_URL}/address/${CONTRACT_ADDRESS}`,
  eventToken: `${ARBISCAN_URL}/token/${EVENT_TOKEN_ADDRESS}`,
  github: 'https://github.com/dgordillodc/EventVault',
}
