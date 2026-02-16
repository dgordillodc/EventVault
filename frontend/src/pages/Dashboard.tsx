/**
 * Dashboard Page
 * Main application view with vault operations
 */

import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { toast, Toaster } from 'sonner'

// Layout
import { Header, Footer } from '../components/layout'

// Vault Components
import {
  StatsGrid,
  DepositCard,
  WithdrawCard,
  InterestCard,
  ContractInfoCard,
  WelcomeScreen,
  AccountDetails,
} from '../components/vault'

// Hooks & Utils
import { useEventVault } from '../hooks/useEventVault'
import { validateDeposit, validateWithdraw } from '../lib/validators'
import { LockPeriod } from '../types'

// =============================================================================
// TOAST CONFIGURATION
// =============================================================================

const toastOptions = {
  style: {
    background: '#1a1f2e',
    border: '1px solid rgba(255,255,255,0.1)',
    padding: '14px 24px',
    fontSize: '15px',
    marginTop: '8px',
    width: 'fit-content',
    margin: '0 auto',
  },
  classNames: {
    error: 'bg-red-900/80 border-red-500/50 text-red-100',
    success: 'bg-emerald-900/80 border-emerald-500/50 text-emerald-100',
  },
}

// =============================================================================
// DASHBOARD COMPONENT
// =============================================================================

export default function Dashboard() {
  const vault = useEventVault()

  // Form state
  const [depositAmount, setDepositAmount] = useState('')
  const [lockPeriod, setLockPeriod] = useState<LockPeriod>(LockPeriod.Flexible)
  const [withdrawAmount, setWithdrawAmount] = useState('')

  // ===========================================================================
  // TRANSACTION SUCCESS EFFECTS
  // ===========================================================================

  useEffect(() => {
    if (vault.isDepositSuccess) {
      toast.success('Deposit confirmed!')
      setDepositAmount('')
      vault.refetch()
    }
  }, [vault.isDepositSuccess])

  useEffect(() => {
    if (vault.isWithdrawSuccess) {
      toast.success('Withdrawal confirmed!')
      setWithdrawAmount('')
      vault.refetch()
    }
  }, [vault.isWithdrawSuccess])

  useEffect(() => {
    if (vault.isClaimSuccess) {
      toast.success('Interest claimed!')
      vault.refetch()
    }
  }, [vault.isClaimSuccess])

  // ===========================================================================
  // HANDLERS WITH VALIDATION
  // ===========================================================================

  const handleDeposit = () => {
    const validation = validateDeposit({
      amount: depositAmount,
      currentBalance: vault.account?.balance,
      maxBalance: vault.config.maxBalance,
    })

    if (!validation.isValid) {
      toast.error(validation.error)
      return
    }

    vault.deposit(depositAmount, lockPeriod)
  }

  const handleWithdraw = () => {
    const validation = validateWithdraw({
      amount: withdrawAmount,
      currentBalance: vault.account?.balance,
      isLocked: vault.isLocked,
      lockEndTime: vault.account?.lockEndTime,
      dailyLimit: vault.config.dailyLimit,
    })

    if (!validation.isValid) {
      toast.error(validation.error)
      return
    }

    vault.withdraw(withdrawAmount)
  }

  const handleClaim = () => {
    vault.claimInterest()
  }

  // ===========================================================================
  // RENDER
  // ===========================================================================

  return (
    <div className="min-h-screen bg-[#0a0f1a] text-white">
      {/* Toast Notifications */}
      <Toaster
        theme="dark"
        position="top-center"
        richColors
        offset={20}
        toastOptions={toastOptions}
      />

      {/* Header */}
      <Header isOwner={vault.isOwner} />

      {/* Main Content */}
      <main className="max-w-6xl mx-auto px-4 py-8">
        {!vault.isConnected ? (
          <WelcomeScreen />
        ) : (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.3 }}
          >
            {/* Stats */}
            <StatsGrid
              account={vault.account}
              pendingInterest={vault.pendingInterest}
              isLocked={vault.isLocked}
            />

            {/* Cards Grid */}
            <div className="grid md:grid-cols-2 gap-6">
              <DepositCard
                depositAmount={depositAmount}
                setDepositAmount={setDepositAmount}
                lockPeriod={lockPeriod}
                setLockPeriod={setLockPeriod}
                onDeposit={handleDeposit}
                isDepositing={vault.isDepositing}
                maxBalance={vault.config.maxBalance}
              />

              <WithdrawCard
                withdrawAmount={withdrawAmount}
                setWithdrawAmount={setWithdrawAmount}
                onWithdraw={handleWithdraw}
                isWithdrawing={vault.isWithdrawing}
                isLocked={vault.isLocked}
                lockEndTime={vault.account?.lockEndTime}
                balance={vault.account?.balance}
                effectiveFee={vault.effectiveFee}
              />

              <InterestCard
                pendingInterest={vault.pendingInterest}
                lockPeriod={vault.account?.lockPeriod}
                tier={vault.account?.tier}
                onClaim={handleClaim}
                isClaiming={vault.isClaiming}
              />

              <ContractInfoCard config={vault.config} txCount={vault.txCount} />
            </div>

            {/* Account Details */}
            {vault.account && (
              <AccountDetails account={vault.account} effectiveFee={vault.effectiveFee} />
            )}
          </motion.div>
        )}
      </main>

      {/* Footer */}
      <Footer />
    </div>
  )
}
