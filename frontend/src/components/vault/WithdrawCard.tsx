/**
 * Withdraw Card component
 * Handles ETH withdrawals with lock status awareness
 */

import { ArrowUpFromLine, Lock } from 'lucide-react'
import { Card, CardHeader, Button, AmountInput } from '../ui'
import { bpsToPercent, formatETH, formatTimestamp } from '../../lib/utils'

interface WithdrawCardProps {
  withdrawAmount: string
  setWithdrawAmount: (value: string) => void
  onWithdraw: () => void
  isWithdrawing: boolean
  isLocked: boolean | undefined
  lockEndTime: number | undefined
  balance: bigint | undefined
  effectiveFee: bigint | undefined
}

export function WithdrawCard({
  withdrawAmount,
  setWithdrawAmount,
  onWithdraw,
  isWithdrawing,
  isLocked,
  lockEndTime,
  balance,
  effectiveFee,
}: WithdrawCardProps) {
  const handleSetMax = () => {
    if (balance && balance > 0n) {
      setWithdrawAmount(formatETH(balance, 6))
    }
  }

  return (
    <Card>
      <CardHeader
        icon={<ArrowUpFromLine className="w-5 h-5 text-blue-400" />}
        iconBgColor="bg-blue-500/10"
        title="Withdraw ETH"
        subtitle={`Fee: ${effectiveFee ? bpsToPercent(effectiveFee) : '1.00'}%${isLocked ? ' • Funds locked' : ''}`}
      />

      {/* Locked Warning */}
      {isLocked && lockEndTime && (
        <div className="mb-4 p-3 rounded-lg bg-amber-500/10 border border-amber-500/20 flex items-center gap-2">
          <Lock className="w-4 h-4 text-amber-400 flex-shrink-0" />
          <p className="text-xs text-amber-300">
            Funds locked until {formatTimestamp(lockEndTime)}
          </p>
        </div>
      )}

      {/* Amount Input */}
      <div className="mb-2">
        <AmountInput
          value={withdrawAmount}
          onChange={(e) => setWithdrawAmount(e.target.value)}
          placeholder="0.0"
          focusColor="blue"
        />
      </div>

      {/* Max Button */}
      {balance && balance > 0n && (
        <button
          onClick={handleSetMax}
          className="mb-4 text-xs text-emerald-400 hover:text-emerald-300 transition-colors"
        >
          Max: {formatETH(balance, 6)} ETH
        </button>
      )}

      <Button
        onClick={onWithdraw}
        disabled={!withdrawAmount || isLocked === true}
        isLoading={isWithdrawing}
        variant="blue"
      >
        {isLocked ? 'Funds Locked' : 'Withdraw'}
      </Button>
    </Card>
  )
}
