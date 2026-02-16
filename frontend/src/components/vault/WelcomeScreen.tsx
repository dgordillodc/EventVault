/**
 * Welcome Screen component
 * Displayed when wallet is not connected
 */

import { motion } from 'framer-motion'
import { Vault } from 'lucide-react'
import { appKit } from '../../lib/config'
import { LOCK_PERIOD_OPTIONS } from '../../lib/constants'

export function WelcomeScreen() {
  const handleConnect = () => appKit.open()

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="text-center py-24"
    >
      {/* Icon */}
      <div className="w-20 h-20 mx-auto mb-6 rounded-2xl bg-gradient-to-br from-emerald-500/20 to-teal-600/20 flex items-center justify-center border border-emerald-500/20">
        <Vault className="w-10 h-10 text-emerald-400" />
      </div>

      {/* Title */}
      <h2 className="text-3xl font-bold mb-3">Welcome to EventVault</h2>
      <p className="text-gray-400 mb-8 max-w-md mx-auto">
        Decentralized treasury with time-locked savings, variable interest rates, and
        loyalty-based rewards through EventToken integration.
      </p>

      {/* Connect Button */}
      <button
        onClick={handleConnect}
        className="px-8 py-3 rounded-xl text-base font-semibold transition-all
          bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500
          shadow-lg shadow-emerald-500/25"
      >
        Connect Wallet to Start
      </button>

      {/* Interest Rates Preview */}
      <div className="mt-16 grid grid-cols-2 md:grid-cols-4 gap-4 max-w-2xl mx-auto">
        {LOCK_PERIOD_OPTIONS.map((rate) => (
          <div
            key={rate.value}
            className="p-4 rounded-xl bg-white/[0.05] border border-white/5"
          >
            <p className="text-xs text-gray-500 mb-1">{rate.label}</p>
            <p className="text-xl font-bold text-emerald-400">{rate.apy}</p>
            <p className="text-xs text-gray-500">{rate.days} days lock</p>
          </div>
        ))}
      </div>
    </motion.div>
  )
}
