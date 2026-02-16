// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.31;

import "../../contracts/interfaces/IEventToken.sol";

/**
 * @title MockEventToken - Test Double for EventToken Integration
 * @author David Gordillo
 * @notice Mock contract for testing EventVault's interaction with EventToken
 * @dev Simulates tier-based discounts and loyalty levels for unit and fuzz tests.
 *      Supports a "revert mode" to test EventVault's try/catch graceful degradation.
 *
 * Test Scenarios Covered:
 * ┌──────────────────────────────┬──────────────────────────────────────┐
 * │ Scenario                     │ How to Configure                     │
 * ├──────────────────────────────┼──────────────────────────────────────┤
 * │ Gold tier with 50% discount  │ setTier(user, 2); setDiscount(5000) │
 * │ Silver tier bonus interest   │ setTier(user, 1); setDiscount(2500) │
 * │ EventToken reverts (offline) │ setShouldRevert(true)               │
 * │ No EventToken integration    │ Deploy vault with address(0)        │
 * └──────────────────────────────┴──────────────────────────────────────┘
 */
contract MockEventToken is IEventToken {

    /// @dev Mapping from address to fee discount in basis points
    mapping(address => uint256) private _discounts;

    /// @dev Mapping from address to loyalty tier level (0-3)
    mapping(address => uint8) private _tiers;

    /// @notice When true, all view functions revert (simulates offline EventToken)
    bool public shouldRevert;

    /// @notice Set fee discount for a specific address
    /// @param account_ Address to configure
    /// @param discount_ Discount in basis points (2500=25%, 5000=50%, 7500=75%)
    function setDiscount(address account_, uint256 discount_) external {
        _discounts[account_] = discount_;
    }

    /// @notice Set loyalty tier for a specific address
    /// @param account_ Address to configure
    /// @param tier_ Tier level (0=Bronze, 1=Silver, 2=Gold, 3=Platinum)
    function setTier(address account_, uint8 tier_) external {
        _tiers[account_] = tier_;
    }

    /// @notice Toggle revert mode to test EventVault's try/catch handling
    /// @param shouldRevert_ true to make all calls revert
    function setShouldRevert(bool shouldRevert_) external {
        shouldRevert = shouldRevert_;
    }

    /// @inheritdoc IEventToken
    function getDiscountOf(address account_) external view override returns (uint256) {
        require(!shouldRevert, "MockEventToken: forced revert");
        return _discounts[account_];
    }

    /// @inheritdoc IEventToken
    function getTierOf(address account_) external view override returns (uint8) {
        require(!shouldRevert, "MockEventToken: forced revert");
        return _tiers[account_];
    }
}

/**
 * @title RejectETH - Transfer Failure Test Helper
 * @author David Gordillo
 * @notice Mock contract that rejects all incoming ETH transfers
 * @dev Used to test EventVault's TransferFailed error handling.
 *      Has no receive() or fallback(), so any call{value}() will fail.
 *
 * Test Scenarios:
 * - withdrawFees() when owner is RejectETH → TransferFailed
 * - emergencyWithdraw() from RejectETH account → TransferFailed
 * - withdraw() to RejectETH → TransferFailed
 */
contract RejectETH {
    // Intentionally has no receive() or fallback()
    // Any ETH sent via call{value}() will fail
}
