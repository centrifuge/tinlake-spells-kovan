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

import "./../tinlake/src/lender/adapters/mkr/clerk.sol";

contract MigratedClerk is Clerk {
    
    bool public done;
    address public migratedFrom;
    
    constructor(address dai_, address collateral_) Clerk(dai_, collateral_) public {}

    function migrate(address clone_) public auth {
        require(!done, "migration already finished");
        done = true;
        migratedFrom = clone_;

        Clerk clone = Clerk(clone_);
        creditline = clone.creditline();
        matBuffer = clone.matBuffer();
        collateralTolerance = clone.collateralTolerance();
        wipeThreshold = clone.wipeThreshold();
    }
}
   