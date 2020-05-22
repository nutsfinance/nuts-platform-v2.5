// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.8;

import "../escrow/InstrumentEscrowInterface.sol";
import "../instrument/InstrumentManagerInterface.sol";

/**
 * @dev A sample application build with two Multi-Swap Issuances.
 */
abstract contract IPOSubscription {

    InstrumentManagerInterface private _swapInstrumentManager;

    constructor(address swapInstrumentManagerAddress) public {
        require(swapInstrumentManagerAddress != address(0x0), "IPOSubscription: Swap instrument not set.");
        _swapInstrumentManager = InstrumentManagerInterface(swapInstrumentManagerAddress);
    }

    function createSubscriptionOffer(uint256 rightsTokenSupply, address targetToken, uint256 targetAmount,
        uint256 duration) public returns (uint256) {
        // Creates rights token

        // Deposits rights token to Instrument Escrow

        // Creates Swap Issuance
    }

    function withdrawFromSubscriptionOffer(uint256 subscriptionOfferId) public virtual;

    function createRedemptionOffer(uint256 subscriptionOfferId) public virtual returns (uint256);

    function withdrawFromRedemptionOffer(uint256 redemptionOfferId) public virtual;
}
