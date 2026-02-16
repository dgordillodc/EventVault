/**
 * Custom hook for EventVault smart contract interaction
 * Provides read/write functions and state management
 */

import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi'
import { parseEther } from 'viem'
import { CONTRACT_ADDRESS } from '../lib/constants'
import { EventVaultABI } from '../lib/abi'
import { AccountInfo, ContractConfig, LockPeriod } from '../types'

export function useEventVault() {
  const { address, isConnected } = useAccount()

  // ===========================================================================
  // CONTRACT READS - User Account Data
  // ===========================================================================

  const { data: accountInfo, refetch: refetchAccount } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: EventVaultABI,
    functionName: 'getAccountInfo',
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  })

  const { data: pendingInterest, refetch: refetchInterest } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: EventVaultABI,
    functionName: 'getPendingInterest',
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  })

  const { data: effectiveFee } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: EventVaultABI,
    functionName: 'getEffectiveFeeRate',
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  })

  const { data: locked } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: EventVaultABI,
    functionName: 'isLocked',
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  })

  const { data: txCount } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: EventVaultABI,
    functionName: 'getTransactionCount',
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  })

  // ===========================================================================
  // CONTRACT READS - Global Configuration
  // ===========================================================================

  const { data: maxBalance } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: EventVaultABI,
    functionName: 'maxBalance',
  })

  const { data: dailyLimit } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: EventVaultABI,
    functionName: 'dailyWithdrawLimit',
  })

  const { data: baseFee } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: EventVaultABI,
    functionName: 'baseFee',
  })

  const { data: baseInterestRate } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: EventVaultABI,
    functionName: 'baseInterestRate',
  })

  const { data: totalDeposited } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: EventVaultABI,
    functionName: 'totalDeposits',
  })

  const { data: isPaused } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: EventVaultABI,
    functionName: 'paused',
  })

  const { data: contractOwner } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: EventVaultABI,
    functionName: 'owner',
  })

  // ===========================================================================
  // CONTRACT WRITES
  // ===========================================================================

  const { writeContract: writeDeposit, data: depositHash, isPending: isDepositing } = useWriteContract()
  const { writeContract: writeWithdraw, data: withdrawHash, isPending: isWithdrawing } = useWriteContract()
  const { writeContract: writeClaim, data: claimHash, isPending: isClaiming } = useWriteContract()

  // ===========================================================================
  // TRANSACTION RECEIPTS
  // ===========================================================================

  const { isLoading: isDepositConfirming, isSuccess: isDepositSuccess } = useWaitForTransactionReceipt({
    hash: depositHash,
  })

  const { isLoading: isWithdrawConfirming, isSuccess: isWithdrawSuccess } = useWaitForTransactionReceipt({
    hash: withdrawHash,
  })

  const { isLoading: isClaimConfirming, isSuccess: isClaimSuccess } = useWaitForTransactionReceipt({
    hash: claimHash,
  })

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  const deposit = (amount: string, lockPeriod: LockPeriod) => {
    writeDeposit({
      address: CONTRACT_ADDRESS,
      abi: EventVaultABI,
      functionName: 'depositETH',
      args: [lockPeriod],
      value: parseEther(amount),
    })
  }

  const withdraw = (amount: string) => {
    writeWithdraw({
      address: CONTRACT_ADDRESS,
      abi: EventVaultABI,
      functionName: 'withdraw',
      args: [parseEther(amount)],
    })
  }

  const claimInterest = () => {
    writeClaim({
      address: CONTRACT_ADDRESS,
      abi: EventVaultABI,
      functionName: 'claimInterest',
    })
  }

  const refetch = () => {
    refetchAccount()
    refetchInterest()
  }

  // ===========================================================================
  // PARSED DATA
  // ===========================================================================

  const account: AccountInfo | null = accountInfo
    ? {
        balance: (accountInfo as any)[0] as bigint,
        pendingInterest: (accountInfo as any)[1] as bigint,
        lockEndTime: Number((accountInfo as any)[2]),
        lockPeriod: Number((accountInfo as any)[3]) as LockPeriod,
        status: Number((accountInfo as any)[4]),
        tier: Number((accountInfo as any)[5]),
      }
    : null

  const config: ContractConfig = {
    maxBalance: maxBalance as bigint | undefined,
    dailyLimit: dailyLimit as bigint | undefined,
    baseFee: baseFee as bigint | undefined,
    baseInterestRate: baseInterestRate as bigint | undefined,
    totalDeposited: totalDeposited as bigint | undefined,
    isPaused: isPaused as boolean | undefined,
  }

  // ===========================================================================
  // RETURN
  // ===========================================================================

  return {
    // Connection
    address,
    isConnected,
    isOwner: address && contractOwner 
      ? address.toLowerCase() === (contractOwner as string).toLowerCase() 
      : false,

    // Account data
    account,
    pendingInterest: pendingInterest as bigint | undefined,
    effectiveFee: effectiveFee as bigint | undefined,
    isLocked: locked as boolean | undefined,
    txCount: txCount ? Number(txCount) : 0,

    // Contract config
    config,

    // Actions
    deposit,
    withdraw,
    claimInterest,
    refetch,

    // Loading states
    isDepositing: isDepositing || isDepositConfirming,
    isWithdrawing: isWithdrawing || isWithdrawConfirming,
    isClaiming: isClaiming || isClaimConfirming,

    // Success flags
    isDepositSuccess,
    isWithdrawSuccess,
    isClaimSuccess,

    // Transaction hashes
    depositHash,
    withdrawHash,
    claimHash,
  }
}
