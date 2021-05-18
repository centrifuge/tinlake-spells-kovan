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

import "./../../../lib/tinlake/src/lender/reserve.sol";


contract MigratedReserve is Reserve {
    
    bool public done;
    address public migratedFrom;

    constructor(address currency) Reserve(currency) public {}

    function migrate(address clone_) public auth {
        require(!done, "migration already finished");
        done = true;
        migratedFrom = clone_;

        Reserve clone = Reserve(clone_);
        currencyAvailable = clone.currencyAvailable();
        balance_ = clone.balance_();
    }
}
   