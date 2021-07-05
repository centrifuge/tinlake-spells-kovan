// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "./../../../../tinlake-internal/src/lender/coordinator.sol";

contract MigratedCoordinator is EpochCoordinator {
    
    bool public done;
    address public migratedFrom;
    
    constructor(uint challengeTime) EpochCoordinator(challengeTime) public {}
                
    function migrate(address clone_) public auth {
        require(!done, "migration already finished");
        done = true;
        migratedFrom = clone_;

        EpochCoordinator clone = EpochCoordinator(clone_);
        lastEpochClosed = clone.lastEpochClosed();
        minimumEpochTime = clone.minimumEpochTime();
        lastEpochExecuted = clone.lastEpochExecuted();
        currentEpoch = clone.currentEpoch();

        (uint seniorRedeemSubmission, uint juniorRedeemSubmission, uint juniorSupplySubmission, uint seniorSupplySubmission) = clone.bestSubmission();
        bestSubmission.seniorRedeem = seniorRedeemSubmission;
        bestSubmission.juniorRedeem = juniorRedeemSubmission;
        bestSubmission.seniorSupply = seniorSupplySubmission;
        bestSubmission.juniorSupply = juniorSupplySubmission;

        (uint  seniorRedeemOrder, uint juniorRedeemOrder, uint juniorSupplyOrder, uint seniorSupplyOrder) = clone.order();
        order.seniorRedeem = seniorRedeemOrder;
        order.juniorRedeem = juniorRedeemOrder;
        order.seniorSupply = seniorSupplyOrder;
        order.juniorSupply = juniorSupplyOrder;

        // bestSubmission = OrderSummary(clone.bestSubmission());
        // order = OrderSummary(clone.order());

        bestSubScore = clone.bestSubScore();
        gotFullValidSolution = clone.gotFullValidSolution();

        epochSeniorTokenPrice = Fixed27(clone.epochSeniorTokenPrice());
        epochJuniorTokenPrice = Fixed27(clone.epochJuniorTokenPrice());
        epochNAV = clone.epochNAV();
        epochSeniorAsset = clone.epochSeniorAsset();
        epochReserve = clone.epochReserve();
        submissionPeriod = clone.submissionPeriod();

        weightSeniorRedeem = clone.weightSeniorRedeem();
        weightJuniorRedeem = clone.weightJuniorRedeem();
        weightJuniorSupply = clone.weightJuniorSupply();
        weightSeniorSupply = clone.weightSeniorSupply();

        minChallengePeriodEnd = clone.minChallengePeriodEnd();
        challengeTime = clone.challengeTime();
        bestRatioImprovement = clone.bestRatioImprovement();
        bestReserveImprovement = clone.bestReserveImprovement();

        poolClosing = clone.poolClosing();           
    }
}
   