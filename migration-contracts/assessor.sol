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

import "./../../../lib/tinlake/src/lender/adapters/mkr/assessor.sol";

contract MigratedMKRAssessor is MKRAssessor {
    
    bool public done;
    address public migratedFrom;

    function migrate(address clone_) public auth {
        require(!done, "migration already finished");
        done = true;
        migratedFrom = clone_;

        Assessor clone = Assessor(clone_);
        // creditBufferTime = clone.creditBufferTime();
        seniorRatio = Fixed27(clone.seniorRatio());
        seniorDebt_ = clone.seniorDebt_();
        seniorBalance_ = clone.seniorBalance_();
        seniorInterestRate = Fixed27(clone.seniorInterestRate());
        lastUpdateSeniorInterest = clone.lastUpdateSeniorInterest();
        maxSeniorRatio = Fixed27(clone.maxSeniorRatio());
        minSeniorRatio = Fixed27(clone.minSeniorRatio());
        maxReserve = clone.maxReserve();            
    }
}