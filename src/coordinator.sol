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
pragma experimental ABIEncoderV2;

import "./../../../lib/tinlake/src/lender/coordinator.sol";

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

        bestSubScore = clone.bestSubScore();
        gotFullValidSolution = clone.gotFullValidSolution();

        // calculate opoch values correctly
        epochSeniorAsset = safeAdd(assessor.seniorDebt(), assessor.seniorBalance());
        // create a snapshot of the current lender state
        epochNAV = assessor.calcUpdateNAV();
        epochReserve = assessor.totalBalance();
        // calculate current token prices which are used for the execute
        epochSeniorTokenPrice = assessor.calcSeniorTokenPrice(epochNAV, epochReserve);
        epochJuniorTokenPrice = assessor.calcJuniorTokenPrice(epochNAV, epochReserve);

        submissionPeriod = clone.submissionPeriod();

        weightSeniorRedeem = clone.weightSeniorRedeem();
        weightJuniorRedeem = clone.weightJuniorRedeem();
        weightJuniorSupply = clone.weightJuniorSupply();
        weightSeniorSupply = clone.weightSeniorSupply();

        minChallengePeriodEnd = clone.minChallengePeriodEnd();
        challengeTime = 1800; // set back to half an hour
        bestRatioImprovement = clone.bestRatioImprovement();
        bestReserveImprovement = clone.bestReserveImprovement();

        poolClosing = false;           
    }
}
   