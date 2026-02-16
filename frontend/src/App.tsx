/**
 * Application Root Component
 * Sets up providers for wagmi and TanStack Query
 */

import { WagmiProvider } from 'wagmi'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { config } from './lib/config'
import Dashboard from './pages/Dashboard'

// Initialize QueryClient
const queryClient = new QueryClient()

export default function App() {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <Dashboard />
      </QueryClientProvider>
    </WagmiProvider>
  )
}
