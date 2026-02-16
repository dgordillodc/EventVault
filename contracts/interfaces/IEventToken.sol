// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.31;

/**
 * @title IEventToken - Loyalty Token Interface for EventVault
 * @author David Gordillo
 * @notice Interface for querying user discounts and loyalty tiers
 * @dev EventVault uses this interface to:
 *      - Get the applicable fee discount for a depositor
 *      - Query user loyalty tier for interest bonuses
 *
 * Tier and Discount System:
 * ┌──────────┬────────────────┬───────────┬─────────────────┐
 * │   Tier   │  EVTK Staked   │ Fee Disc. │ Interest Bonus  │
 * ├──────────┼────────────────┼───────────┼─────────────────┤
 * │ Bronze   │      0         │    0%     │       0%        │
 * │ Silver   │    100+        │   25%     │       5%        │
 * │ Gold     │    500+        │   50%     │      10%        │
 * │ Platinum │   1000+        │   75%     │      15%        │
 * └──────────┴────────────────┴───────────┴─────────────────┘
 *
 * Integration with EventVault:
 * - Fee discount: reduces the baseFee on withdrawals
 *   uint256 discount = eventToken.getDiscountOf(user);
 *   uint256 effectiveFee = baseFee - (baseFee * discount / 10000);
 *
 * - Tier bonus: increases interest earned on deposits
 *   uint8 tier = eventToken.getTierOf(user);
 *   uint256 bonus = interest * (tier * 500) / 10000;
 *
 * @custom:security Uses try/catch in EventVault for graceful degradation
 * @custom:deployed Arbitrum One - 0x030ae3125a9cdAD35B933D4f92CccdE78934A778
 */
interface IEventToken {

    // =========================================================================
    //                        DISCOUNT FUNCTIONS
    // =========================================================================

    /**
     * @notice Gets the applicable fee discount for a user
     * @dev Returns discount in basis points (1% = 100, 100% = 10000)
     * @param account_ User's address to query
     * @return uint256 Discount in basis points:
     *         - Bronze:   0 (0%)
     *         - Silver:   2500 (25%)
     *         - Gold:     5000 (50%)
     *         - Platinum: 7500 (75%)
     *
     * Usage in EventVault:
     *   uint256 discount = eventToken.getDiscountOf(buyer);
     *   uint256 finalFee = baseFee - (baseFee * discount / 10000);
     */
    function getDiscountOf(address account_) external view returns (uint256);

    // =========================================================================
    //                          TIER FUNCTIONS
    // =========================================================================

    /**
     * @notice Gets the loyalty tier level of a user
     * @dev Tier is determined by staked EVTK tokens in EventToken contract
     * @param account_ User's address to query
     * @return uint8 Current tier level:
     *         - 0: Bronze  (default, no staking required)
     *         - 1: Silver  (100+ EVTK staked)
     *         - 2: Gold    (500+ EVTK staked)
     *         - 3: Platinum (1000+ EVTK staked)
     */
    function getTierOf(address account_) external view returns (uint8);
}
