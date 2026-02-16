/**
 * Interest Card component
 * Displays and allows claiming of accumulated interest
 */

import { Coins } from 'lucide-react'
import { Card, CardHeader, Button } from '../ui'
import { formatETH, getLockPeriodAPY } from '../../lib/utils'
import { LockPeriod, Tier } from '../../types'

interface InterestCardProps {
  pendingInterest: bigint | undefined
  lockPeriod: LockPeriod | undefined
  tier: Tier | undefined
  onClaim: () => void
  isClaiming: boolean
}

export function InterestCard({
  pendingInterest,
  lockPeriod,
  tier,
  onClaim,
  isClaiming,
}: InterestCardProps) {
  const apyBase = lockPeriod !== undefined ? getLockPeriodAPY(lockPeriod) : '5.00'
  const tierBonus = tier && tier > 0 ? tier * 5 : 0

  return (
    <Card>
      <CardHeader
        icon={<Coins className="w-5 h-5 text-teal-400" />}
        iconBgColor="bg-teal-500/10"
        title="Interest"
        subtitle={`APY: ${apyBase}%${tierBonus > 0 ? ` + ${tierBonus}% tier bonus` : ''}`}
      />

      {/* Interest Display */}
      <div className="mb-4 p-4 rounded-xl bg-gradient-to-br from-teal-500/5 to-emerald-500/5 border border-teal-500/10">
        <p className="text-xs text-gray-500 mb-1">Claimable Interest</p>
        <p className="text-2xl font-bold text-teal-400">
          {pendingInterest ? formatETH(pendingInterest, 10) : '0.0000000000'} ETH
        </p>
      </div>

      <Button
        onClick={onClaim}
        disabled={!pendingInterest || pendingInterest === 0n}
        isLoading={isClaiming}
        variant="teal"
      >
        Claim Interest
      </Button>
    </Card>
  )
}
