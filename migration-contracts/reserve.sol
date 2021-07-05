// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;
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
   