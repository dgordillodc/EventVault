/**
 * Reusable Button component
 * Supports multiple variants and states
 */

import { ReactNode, ButtonHTMLAttributes } from 'react'

type ButtonVariant = 'primary' | 'secondary' | 'blue' | 'teal'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  children: ReactNode
  variant?: ButtonVariant
  isLoading?: boolean
  fullWidth?: boolean
}

const variantStyles: Record<ButtonVariant, string> = {
  primary: 'bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 shadow-emerald-500/10',
  secondary: 'bg-white/[0.05] hover:bg-white/[0.1] border border-white/10',
  blue: 'bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 shadow-blue-500/10',
  teal: 'bg-gradient-to-r from-teal-600 to-emerald-600 hover:from-teal-500 hover:to-emerald-500 shadow-teal-500/10',
}

export function Button({
  children,
  variant = 'primary',
  isLoading = false,
  fullWidth = true,
  disabled,
  className = '',
  ...props
}: ButtonProps) {
  return (
    <button
      disabled={disabled || isLoading}
      className={`
        ${fullWidth ? 'w-full' : ''}
        py-3 rounded-xl font-semibold transition-all
        ${variantStyles[variant]}
        disabled:opacity-40 disabled:cursor-not-allowed
        shadow-lg
        ${className}
      `}
      {...props}
    >
      {isLoading ? 'Confirming...' : children}
    </button>
  )
}
