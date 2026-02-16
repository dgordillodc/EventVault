/**
 * Stats Grid component
 * Displays user account statistics
 */

import { Wallet, TrendingUp, Lock, Unlock, Shield } from 'lucide-react'
import { formatETH, getTierName, getTierColor, timeUntil } from '../../lib/utils'
import { AccountInfo } from '../../types'

interface StatsGridProps {
  account: AccountInfo | null
  pendingInterest: bigint | undefined
  isLocked: boolean | undefined
}

interface StatCardProps {
  icon: React.ReactNode
  label: string
  value: string
  valueClassName?: string
}

function StatCard({ icon, label, value, valueClassName = '' }: StatCardProps) {
  return (
    <div className="p-4 rounded-xl bg-white/[0.05] border border-white/5">
      <div className="flex items-center gap-2 mb-2">
        {icon}
        <span className="text-xs text-gray-500">{label}</span>
      </div>
      <p className={`text-xl font-bold ${valueClassName}`}>{value}</p>
    </div>
  )
}

export function StatsGrid({ account, pendingInterest, isLocked }: StatsGridProps) {
  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
      <StatCard
        icon={<Wallet className="w-4 h-4 text-emerald-400" />}
        label="Your Balance"
        value={`${account ? formatETH(account.balance, 4) : '0.0000'} ETH`}
      />

      <StatCard
        icon={<TrendingUp className="w-4 h-4 text-teal-400" />}
        label="Pending Interest"
        value={`${pendingInterest ? formatETH(pendingInterest, 8) : '0.00000000'} ETH`}
      />

      <StatCard
        icon={
          isLocked ? (
            <Lock className="w-4 h-4 text-amber-400" />
          ) : (
            <Unlock className="w-4 h-4 text-green-400" />
          )
        }
        label="Lock Status"
        value={account ? (isLocked ? timeUntil(account.lockEndTime) : 'Unlocked') : '-'}
      />

      <StatCard
        icon={
          <Shield
            className={`w-4 h-4 ${account ? getTierColor(account.tier) : 'text-gray-500'}`}
          />
        }
        label="Tier"
        value={account ? getTierName(account.tier) : 'Bronze'}
        valueClassName={account ? getTierColor(account.tier) : ''}
      />
    </div>
  )
}
