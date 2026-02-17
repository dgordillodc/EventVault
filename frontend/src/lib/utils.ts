/**
 * Utility functions for formatting and display
 */

import { formatEther } from 'viem'
import { LOCK_PERIOD_OPTIONS, TIER_CONFIG, STATUS_CONFIG } from './constants'
import { LockPeriod, Tier, AccountStatus } from '../types'

// =============================================================================
// ETH FORMATTING
// =============================================================================

/**
 * Format wei to ETH with specified decimal places
 */
export function formatETH(wei: bigint | undefined, decimals: number = 4): string {
  if (!wei) return '0'
  const eth = formatEther(wei)
  return Number(eth).toFixed(decimals)
}

// =============================================================================
// ADDRESS FORMATTING
// =============================================================================

/**
 * Shorten address for display (0x1234...5678)
 */
export function shortenAddress(address: string): string {
  if (!address) return ''
  return `${address.slice(0, 6)}...${address.slice(-4)}`
}

// =============================================================================
// PERCENTAGE FORMATTING
// =============================================================================

/**
 * Convert basis points to percentage string
 * @param bps - Basis points (100 = 1%)
 */
export function bpsToPercent(bps: bigint | number): string {
  const num = typeof bps === 'bigint' ? Number(bps) : bps
  return (num / 100).toFixed(2)
}

// =============================================================================
// LOCK PERIOD HELPERS
// =============================================================================

/**
 * Get lock period display name
 */
export function getLockPeriodName(period: LockPeriod | number): string {
  const option = LOCK_PERIOD_OPTIONS.find(opt => opt.value === period)
  return option?.label || 'Unknown'
}

/**
 * Get APY for lock period
 */
export function getLockPeriodAPY(period: LockPeriod | number): string {
  const option = LOCK_PERIOD_OPTIONS.find(opt => opt.value === period)
  return option?.apyValue.toFixed(2) || '5.00'
}

// =============================================================================
// TIER HELPERS
// =============================================================================

/**
 * Get tier display name
 */
export function getTierName(tier: Tier | number): string {
  return TIER_CONFIG[tier as keyof typeof TIER_CONFIG]?.name || 'Bronze'
}

/**
 * Get tier color class
 */
export function getTierColor(tier: Tier | number): string {
  return TIER_CONFIG[tier as keyof typeof TIER_CONFIG]?.color || 'text-orange-400'
}

// =============================================================================
// STATUS HELPERS
// =============================================================================

/**
 * Get account status display name
 */
export function getStatusName(status: AccountStatus | number): string {
  return STATUS_CONFIG[status as keyof typeof STATUS_CONFIG]?.name || 'None'
}

/**
 * Get status color class
 */
export function getStatusColor(status: AccountStatus | number): string {
  return STATUS_CONFIG[status as keyof typeof STATUS_CONFIG]?.color || 'text-gray-500'
}

// =============================================================================
// TIME FORMATTING
// =============================================================================

/**
 * Format Unix timestamp to readable date
 */
export function formatTimestamp(timestamp: number): string {
  if (!timestamp || timestamp === 0) return 'No lock'
  return new Date(timestamp * 1000).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

/**
 * Get time remaining until unlock
 */
export function timeUntil(timestamp: number): string {
  if (!timestamp || timestamp === 0) return 'Unlocked'
  
  const now = Math.floor(Date.now() / 1000)
  const diff = timestamp - now
  
  if (diff <= 0) return 'Unlocked'
  
  const days = Math.floor(diff / 86400)
  const hours = Math.floor((diff % 86400) / 3600)
  
  if (days > 0) return `${days}d ${hours}h`
  if (hours > 0) return `${hours}h`
  return 'Soon'
}
