/**
 * Reusable Card component
 * Base component for all card layouts in the application
 */

import { ReactNode } from 'react'
import { motion } from 'framer-motion'

interface CardProps {
  children: ReactNode
  className?: string
  animate?: boolean
}

export function Card({ children, className = '', animate = false }: CardProps) {
  const baseStyles = 'p-6 rounded-2xl bg-white/[0.05] border border-white/5'
  
  if (animate) {
    return (
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        className={`${baseStyles} ${className}`}
      >
        {children}
      </motion.div>
    )
  }

  return <div className={`${baseStyles} ${className}`}>{children}</div>
}

interface CardHeaderProps {
  icon: ReactNode
  iconBgColor?: string
  title: string
  subtitle?: string
}

export function CardHeader({ icon, iconBgColor = 'bg-emerald-500/10', title, subtitle }: CardHeaderProps) {
  return (
    <div className="flex items-center gap-3 mb-6">
      <div className={`w-10 h-10 rounded-xl ${iconBgColor} flex items-center justify-center`}>
        {icon}
      </div>
      <div>
        <h3 className="font-semibold">{title}</h3>
        {subtitle && <p className="text-xs text-gray-500">{subtitle}</p>}
      </div>
    </div>
  )
}
