/**
 * Deposit Card component
 * Handles ETH deposits with lock period selection
 */

import { ArrowDownToLine } from 'lucide-react'
import { Card, CardHeader, Button, AmountInput } from '../ui'
import { LOCK_PERIOD_OPTIONS } from '../../lib/constants'
import { formatETH } from '../../lib/utils'
import { LockPeriod } from '../../types'

interface DepositCardProps {
  depositAmount: string
  setDepositAmount: (value: string) => void
  lockPeriod: LockPeriod
  setLockPeriod: (value: LockPeriod) => void
  onDeposit: () => void
  isDepositing: boolean
  maxBalance: bigint | undefined
}

export function DepositCard({
  depositAmount,
  setDepositAmount,
  lockPeriod,
  setLockPeriod,
  onDeposit,
  isDepositing,
  maxBalance,
}: DepositCardProps) {
  return (
    <Card>
      <CardHeader
        icon={<ArrowDownToLine className="w-5 h-5 text-emerald-400" />}
        iconBgColor="bg-emerald-500/10"
        title="Deposit ETH"
        subtitle="Choose lock period for better rates"
      />

      {/* Lock Period Selector */}
      <div className="grid grid-cols-4 gap-2 mb-4">
        {LOCK_PERIOD_OPTIONS.map((opt) => (
          <button
            key={opt.value}
            onClick={() => setLockPeriod(opt.value)}
            className={`p-2 rounded-lg text-center transition-all text-xs
              ${
                lockPeriod === opt.value
                  ? 'bg-emerald-500/20 border-emerald-500/50 text-emerald-400 border'
                  : 'bg-white/[0.05] border border-white/5 text-gray-400 hover:bg-white/[0.06]'
              }`}
          >
            <span className="block font-medium">{opt.label}</span>
            <span className="block text-emerald-400 font-bold">{opt.apy}</span>
          </button>
        ))}
      </div>

      {/* Amount Input */}
      <div className="mb-2">
        <AmountInput
          value={depositAmount}
          onChange={(e) => setDepositAmount(e.target.value)}
          placeholder="0.0"
          focusColor="emerald"
        />
      </div>

      {/* Max hint */}
      <p className="text-xs text-gray-500 mb-4">
        Max: {maxBalance ? formatETH(maxBalance, 0) : '5'} ETH per account
      </p>

      <Button
        onClick={onDeposit}
        disabled={!depositAmount}
        isLoading={isDepositing}
        variant="primary"
      >
        Deposit
      </Button>
    </Card>
  )
}
