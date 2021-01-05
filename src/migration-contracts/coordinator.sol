    // Copyright (C) 2020 Centrifuge
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.5.15 <0.6.0;

import "./../../coordinator.sol";

contract MigratedCoordinator is Coordinator {
    
    bool public done;
    address public clone;
    
    function migrate(address clone_) public auth {
        require(!done, "migration already finished");
        done = true;
        clone = clone_;
        
        Coordinator clone = Coordinator(clone_);
        lastEpochClosed = clone.lastEpochClosed();
        minimumEpochTime = clone.minimumEpochTime();
        lastEpochExecuted = clone.lastEpochExecuted();
        currentEpoch = clone.currentEpoch();

        // (uint  seniorRedeemSubmission, uint juniorRedeemSubmission, uint juniorSupplySubmission, uint seniorSupplySubmission) = clone.bestSubmission;
        // bestSubmission.seniorRedeem = seniorRedeemSubmission;
        // bestSubmission.juniorRedeem = juniorRedeemSubmission;
        // bestSubmission.seniorSupply = seniorSupplySubmission;
        // bestSubmission.juniorSupply = juniorSupplySubmission;

        // (uint  seniorRedeemOrder, uint juniorRedeemOrder, uint juniorSupplyOrder, uint seniorSupplyOrder) = clone.order;
        // order.seniorRedeem = seniorRedeemOrder;
        // order.juniorRedeem = juniorRedeemOrder;
        // order.seniorSupply = seniorSupplyOrder;
        // order.juniorSupply = juniorSupplyOrder;

        bestSubmission = clone.bestSubmission;
        order = clone.order;

        bestSubScore = clone.bestSubScore();
        gotFullValidSolution = clone.gotFullValidSolution();

        epochSeniorTokenPrice = clone.epochSeniorTokenPrice();
        epochJuniorTokenPrice = clone.epochJuniorTokenPrice();
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
   