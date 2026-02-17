/**
 * Wagmi + Reown AppKit Configuration
 * Blockchain connection and wallet management setup
 */

import { http } from 'wagmi'
import { arbitrum } from 'wagmi/chains'
import { createAppKit } from '@reown/appkit'
import { WagmiAdapter } from '@reown/appkit-adapter-wagmi'
import type { AppKitNetwork } from '@reown/appkit/networks'
import { CONTRACT_ADDRESS } from './constants'

// =============================================================================
// WALLETCONNECT CONFIGURATION
// =============================================================================

const projectId = import.meta.env.VITE_WALLETCONNECT_PROJECT_ID || '93e7d7dedf90d33c3d695e8c3bd7f3b5'

// =============================================================================
// NETWORK CONFIGURATION
// =============================================================================

const chains: [AppKitNetwork, ...AppKitNetwork[]] = [arbitrum]

// =============================================================================
// WAGMI ADAPTER
// =============================================================================

const wagmiAdapter = new WagmiAdapter({
  projectId,
  networks: chains,
  transports: {
    [arbitrum.id]: http('https://arb1.arbitrum.io/rpc'),
  },
})

export const config = wagmiAdapter.wagmiConfig

// =============================================================================
// APPKIT INITIALIZATION
// =============================================================================

export const appKit = createAppKit({
  adapters: [wagmiAdapter],
  projectId,
  metadata: {
    name: 'EventVault',
    description: 'Decentralized Treasury for Event Ecosystem',
    url: typeof window !== 'undefined' ? window.location.origin : 'https://eventvault-dapp.vercel.app',
    icons: ['/vault-icon.svg'],
  },
  networks: chains,
  defaultNetwork: arbitrum,
  themeMode: 'dark',
  themeVariables: {
    '--w3m-color-mix': '#10B981',
    '--w3m-color-mix-strength': 20,
    '--w3m-accent': '#10B981',
    '--w3m-border-radius-master': '12px',
  },
})
