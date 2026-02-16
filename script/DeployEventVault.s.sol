// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.31;

import "forge-std/Script.sol";
import "../contracts/EventVault.sol";

/**
 * @title DeployEventVault - Foundry Deployment Script
 * @author David Gordillo
 * @notice Deploys EventVault to Arbitrum One with production configuration
 * @dev Usage:
 *      forge script script/DeployEventVault.s.sol \
 *        --rpc-url $ARBITRUM_RPC_URL \
 *        --broadcast \
 *        --verify
 *
 * Deployment Parameters:
 * ┌─────────────────┬─────────────────────────────────────────────────┐
 * │ Parameter       │ Value                                           │
 * ├─────────────────┼─────────────────────────────────────────────────┤
 * │ MAX_BALANCE     │ 5 ETH (per-user maximum deposit)               │
 * │ DAILY_LIMIT     │ 1 ETH (24-hour withdrawal limit)               │
 * │ EVENT_TOKEN     │ 0x030ae...A778 (EVTK on Arbitrum One)          │
 * │ baseFee         │ 100 bps (1%) — set in constructor              │
 * │ interestRate    │ 500 bps (5% APY) — set in constructor          │
 * │ penalty         │ 1000 bps (10%) — set in constructor            │
 * └─────────────────┴─────────────────────────────────────────────────┘
 *
 * Environment Variables Required:
 *   PRIVATE_KEY — Deployer wallet private key
 *
 * @custom:deployed Arbitrum One - 0x2ED519F7Dc7f8e2761b2aA0B52e0199b713D8863
 */
contract DeployEventVault is Script {

    /// @notice Per-user maximum ETH balance allowed
    uint256 public constant MAX_BALANCE = 5 ether;

    /// @notice Maximum ETH that can be withdrawn per 24-hour period
    uint256 public constant DAILY_LIMIT = 1 ether;

    /// @notice EventToken (EVTK) deployed address on Arbitrum One
    address public constant EVENT_TOKEN = 0x030ae3125a9cdAD35B933D4f92CccdE78934A778;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        EventVault vault = new EventVault(MAX_BALANCE, DAILY_LIMIT, EVENT_TOKEN);

        console.log("EventVault deployed at:", address(vault));
        console.log("Max Balance:", MAX_BALANCE);
        console.log("Daily Limit:", DAILY_LIMIT);
        console.log("EventToken:", EVENT_TOKEN);

        vm.stopBroadcast();
    }
}
