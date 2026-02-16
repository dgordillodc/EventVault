/**
 * Contract Info Card component
 * Displays on-chain contract configuration
 */

import { Info, ExternalLink } from 'lucide-react'
import { Card, CardHeader } from '../ui'
import { EXTERNAL_LINKS } from '../../lib/constants'
import { formatETH, bpsToPercent } from '../../lib/utils'
import { ContractConfig } from '../../types'

interface ContractInfoCardProps {
  config: ContractConfig
  txCount: number
}

interface InfoRowProps {
  label: string
  value: string
  valueColor?: string
}

function InfoRow({ label, value, valueColor = '' }: InfoRowProps) {
  return (
    <div className="flex justify-between">
      <span className="text-gray-500">{label}</span>
      <span className={valueColor}>{value}</span>
    </div>
  )
}

export function ContractInfoCard({ config, txCount }: ContractInfoCardProps) {
  return (
    <Card>
      <CardHeader
        icon={<Info className="w-5 h-5 text-purple-400" />}
        iconBgColor="bg-purple-500/10"
        title="Contract Info"
        subtitle="On-chain details"
      />

      <div className="space-y-3 text-sm">
        <InfoRow
          label="Status"
          value={config.isPaused ? 'Paused' : 'Active'}
          valueColor={config.isPaused ? 'text-red-400' : 'text-green-400'}
        />
        <InfoRow
          label="Max Balance"
          value={`${config.maxBalance ? formatETH(config.maxBalance, 0) : '-'} ETH`}
        />
        <InfoRow
          label="Daily Limit"
          value={`${config.dailyLimit ? formatETH(config.dailyLimit, 0) : '-'} ETH`}
        />
        <InfoRow
          label="Base Fee"
          value={`${config.baseFee ? bpsToPercent(config.baseFee) : '-'}%`}
        />
        <InfoRow
          label="Base Interest"
          value={`${config.baseInterestRate ? bpsToPercent(config.baseInterestRate) : '-'}%`}
        />
        <InfoRow
          label="Total Deposits"
          value={`${config.totalDeposited ? formatETH(config.totalDeposited, 4) : '0'} ETH`}
        />
        <InfoRow label="Your Transactions" value={String(txCount)} />

        {/* Arbiscan Link */}
        <div className="pt-3 border-t border-white/5">
          <a
            href={EXTERNAL_LINKS.contract}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-2 text-emerald-400 hover:text-emerald-300 transition-colors text-xs"
          >
            <ExternalLink className="w-3 h-3" />
            View on Arbiscan
          </a>
        </div>
      </div>
    </Card>
  )
}
