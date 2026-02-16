/**
 * Account Details component
 * Displays detailed account information for active accounts
 */

import { motion } from 'framer-motion'
import { Shield } from 'lucide-react'
import {
  getStatusName,
  getStatusColor,
  getLockPeriodName,
  formatTimestamp,
  bpsToPercent,
} from '../../lib/utils'
import { AccountInfo } from '../../types'

interface AccountDetailsProps {
  account: AccountInfo
  effectiveFee: bigint | undefined
}

export function AccountDetails({ account, effectiveFee }: AccountDetailsProps) {
  if (account.status === 0) return null

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      className="mt-6 p-6 rounded-2xl bg-white/[0.05] border border-white/5"
    >
      <h3 className="font-semibold mb-4 flex items-center gap-2">
        <Shield className="w-4 h-4 text-emerald-400" />
        Account Details
      </h3>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
        <div>
          <p className="text-gray-500 text-xs">Status</p>
          <p className={getStatusColor(account.status)}>{getStatusName(account.status)}</p>
        </div>
        <div>
          <p className="text-gray-500 text-xs">Lock Period</p>
          <p>{getLockPeriodName(account.lockPeriod)}</p>
        </div>
        <div>
          <p className="text-gray-500 text-xs">Unlock Time</p>
          <p>{account.lockEndTime > 0 ? formatTimestamp(account.lockEndTime) : 'No lock'}</p>
        </div>
        <div>
          <p className="text-gray-500 text-xs">Effective Fee</p>
          <p>{effectiveFee ? bpsToPercent(effectiveFee) : '1.00'}%</p>
        </div>
      </div>
    </motion.div>
  )
}
