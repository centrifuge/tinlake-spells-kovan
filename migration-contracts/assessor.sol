// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "./../../../lib/tinlake/src/lender/assessor.sol";

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