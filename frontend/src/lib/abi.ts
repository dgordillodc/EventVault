/**
 * EventVault Contract ABI
 * Application Binary Interface for smart contract interaction
 */

export const EventVaultABI = [
  // ==========================================================================
  // READ FUNCTIONS - User Account Data
  // ==========================================================================
  {
    name: 'getAccountInfo',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'account_', type: 'address' }],
    outputs: [
      { name: 'balance', type: 'uint256' },
      { name: 'pendingInterest', type: 'uint256' },
      { name: 'lockEndTime', type: 'uint256' },
      { name: 'lockPeriod', type: 'uint8' },
      { name: 'status', type: 'uint8' },
      { name: 'tier', type: 'uint8' },
    ],
  },
  {
    name: 'getPendingInterest',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'account_', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }],
  },
  {
    name: 'getEffectiveFeeRate',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'account_', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }],
  },
  {
    name: 'isLocked',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'account_', type: 'address' }],
    outputs: [{ name: '', type: 'bool' }],
  },
  {
    name: 'getTransactionCount',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'account_', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }],
  },

  // ==========================================================================
  // READ FUNCTIONS - Contract State
  // ==========================================================================
  {
    name: 'owner',
    type: 'function',
    stateMutability: 'view',
    inputs: [],
    outputs: [{ name: '', type: 'address' }],
  },
  {
    name: 'admin',
    type: 'function',
    stateMutability: 'view',
    inputs: [],
    outputs: [{ name: '', type: 'address' }],
  },
  {
    name: 'paused',
    type: 'function',
    stateMutability: 'view',
    inputs: [],
    outputs: [{ name: '', type: 'bool' }],
  },
  {
    name: 'maxBalance',
    type: 'function',
    stateMutability: 'view',
    inputs: [],
    outputs: [{ name: '', type: 'uint256' }],
  },
  {
    name: 'dailyWithdrawLimit',
    type: 'function',
    stateMutability: 'view',
    inputs: [],
    outputs: [{ name: '', type: 'uint256' }],
  },
  {
    name: 'baseFee',
    type: 'function',
    stateMutability: 'view',
    inputs: [],
    outputs: [{ name: '', type: 'uint256' }],
  },
  {
    name: 'baseInterestRate',
    type: 'function',
    stateMutability: 'view',
    inputs: [],
    outputs: [{ name: '', type: 'uint256' }],
  },
  {
    name: 'totalDeposits',
    type: 'function',
    stateMutability: 'view',
    inputs: [],
    outputs: [{ name: '', type: 'uint256' }],
  },

  // ==========================================================================
  // WRITE FUNCTIONS - User Actions
  // ==========================================================================
  {
    name: 'depositETH',
    type: 'function',
    stateMutability: 'payable',
    inputs: [{ name: 'lockPeriod_', type: 'uint8' }],
    outputs: [],
  },
  {
    name: 'withdraw',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [{ name: 'amount_', type: 'uint256' }],
    outputs: [],
  },
  {
    name: 'claimInterest',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [],
    outputs: [],
  },
  {
    name: 'emergencyWithdraw',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [],
    outputs: [],
  },

  // ==========================================================================
  // ADMIN FUNCTIONS
  // ==========================================================================
  {
    name: 'setBaseFee',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [{ name: 'newFee_', type: 'uint256' }],
    outputs: [],
  },
  {
    name: 'setPaused',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [{ name: 'paused_', type: 'bool' }],
    outputs: [],
  },
  {
    name: 'setBlacklist',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [
      { name: 'account_', type: 'address' },
      { name: 'status_', type: 'bool' },
    ],
    outputs: [],
  },
] as const
