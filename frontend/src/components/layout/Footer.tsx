/**
 * Application Footer component
 */

import { EXTERNAL_LINKS } from '../../lib/constants'

export function Footer() {
  return (
    <footer className="border-t border-white/5 mt-16 py-6">
      <div className="max-w-6xl mx-auto px-4 flex flex-col md:flex-row items-center justify-between gap-4 text-xs text-gray-600">
        <div className="flex items-center gap-4">
          <span>EventVault v1.0.0</span>
          <span>•</span>
          <span>Solidity 0.8.31</span>
          <span>•</span>
          <span>Arbitrum One</span>
        </div>
        <div className="flex items-center gap-4">
          <a
            href={EXTERNAL_LINKS.contract}
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-gray-400 transition-colors"
          >
            Contract
          </a>
          <a
            href={EXTERNAL_LINKS.eventToken}
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-gray-400 transition-colors"
          >
            EventToken
          </a>
          <a
            href={EXTERNAL_LINKS.github}
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-gray-400 transition-colors"
          >
            GitHub
          </a>
        </div>
      </div>
    </footer>
  )
}
