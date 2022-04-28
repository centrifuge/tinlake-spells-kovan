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

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./../tinlake/src/borrower/feed/navfeed.sol";

contract MigratedNAVFeed is NAVFeed {
    
    bool public done;
    address public migratedFrom;
    
    constructor() NAVFeed() public {}

    function migrate(address clone_, uint riskGroupCount, address oracle, uint loanCount) public auth {
        require(!done, "migration already finished");
        done = true;
        migratedFrom = clone_;

        NAVFeed clone = NAVFeed(clone_);

        // add Oracle permissions
        wards[oracle] = 1;

        // migrate discountRate
        discountRate = clone.discountRate();
       
        // migrate riskGroups
        for (uint group = 0; group <= riskGroupCount; group++) {
            riskGroup[group].recoveryRatePD = uint128(clone.recoveryRatePD(group));
            riskGroup[group].thresholdRatio = uint128(clone.thresholdRatio(group));
            riskGroup[group].ceilingRatio = uint128(clone.ceilingRatio(group)); 
        }

        // note with this migration method only nfts that have underlying loans will be migrated, all the other nfts need to be appraised again for the new nav
        for (uint loanID = 1; loanID <= loanCount; loanID++) { 
            // nft details
            bytes32 nftID_ = clone.nftID(loanID);
            details[nftID_].maturityDate = uint128(clone.maturityDate(nftID_));
            details[nftID_].futureValue = uint128(clone.futureValue(nftID_));
            details[nftID_].risk = uint128(clone.risk(nftID_));
            details[nftID_].nftValues = uint128(clone.nftValues(nftID_));

            // loan details 
            loanDetails[loanID].borrowed = uint128(clone.borrowed(loanID));
            uint128 maturityDate = uint128(clone.maturityDate(nftID_));
            // fill maturityDate bucket, if empty
            if (buckets[maturityDate] == 0) {
                buckets[maturityDate] = clone.buckets(maturityDate);
            }
         }


        // No WriteOff Group migration required
        reCalcNAV();

    }
}
   