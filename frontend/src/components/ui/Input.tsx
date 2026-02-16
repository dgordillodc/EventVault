/**
 * Reusable Input component for ETH amounts
 */

import { InputHTMLAttributes } from 'react'

interface AmountInputProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'type'> {
  value: string
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void
  suffix?: string
  focusColor?: 'emerald' | 'blue' | 'teal'
}

const focusColors = {
  emerald: 'focus:border-emerald-500/50',
  blue: 'focus:border-blue-500/50',
  teal: 'focus:border-teal-500/50',
}

export function AmountInput({
  value,
  onChange,
  suffix = 'ETH',
  focusColor = 'emerald',
  className = '',
  ...props
}: AmountInputProps) {
  return (
    <div className="relative">
      <input
        type="number"
        value={value}
        onChange={onChange}
        className={`
          w-full p-3 pr-16 rounded-xl 
          bg-white/[0.05] border border-white/10 
          text-white placeholder-gray-600 
          outline-none ${focusColors[focusColor]}
          transition-colors
          ${className}
        `}
        step="0.0001"
        min="0"
        {...props}
      />
      <span className="absolute right-4 top-1/2 -translate-y-1/2 text-sm text-gray-500">
        {suffix}
      </span>
    </div>
  )
}
