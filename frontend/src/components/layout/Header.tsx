/**
 * Application Header component
 */

import { Vault } from 'lucide-react'
import { useAccount } from 'wagmi'
import { appKit } from '../../lib/config'
import { shortenAddress } from '../../lib/utils'

interface HeaderProps {
  isOwner: boolean
}

export function Header({ isOwner }: HeaderProps) {
  const { isConnected, address } = useAccount()

  const handleConnect = () => appKit.open()

  return (
    <header className="border-b border-white/5 backdrop-blur-xl bg-[#0a0f1a]/80 sticky top-0 z-50">
      <div className="max-w-6xl mx-auto px-4 py-4 flex items-center justify-between">
        {/* Logo */}
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center">
            <Vault className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-lg font-bold tracking-tight">EventVault</h1>
            <p className="text-xs text-gray-500">Arbitrum One</p>
          </div>
        </div>

        {/* Actions */}
        <div className="flex items-center gap-3">
          {isOwner && (
            <span className="px-2 py-1 text-xs bg-amber-500/10 text-amber-400 rounded-lg border border-amber-500/20">
              Admin
            </span>
          )}
          <button
            onClick={handleConnect}
            className="px-4 py-2 rounded-xl text-sm font-medium transition-all
              bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500
              shadow-lg shadow-emerald-500/20"
          >
            {isConnected && address ? shortenAddress(address) : 'Connect Wallet'}
          </button>
        </div>
      </div>
    </header>
  )
}
