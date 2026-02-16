# EventVault Frontend

React dApp for interacting with the EventVault smart contract.

## Setup

```bash
# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Add your WalletConnect Project ID to .env

# Start development server
npm run dev
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `VITE_WALLETCONNECT_PROJECT_ID` | Get from [cloud.walletconnect.com](https://cloud.walletconnect.com) |

## Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server |
| `npm run build` | Build for production |
| `npm run preview` | Preview production build |
