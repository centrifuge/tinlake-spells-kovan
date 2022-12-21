pragma solidity >=0.6.12;

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

interface RootLike {
    function relyContract(address, address) external;
    function denyContract(address, address) external;
}

interface AuthLike {
    function wards(address) external returns(uint);
    function rely(address) external;
    function deny(address) external;
}

// spell description
contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake spell";

    // MAINNET ADDRESSES
    // The contracts in this list should correspond to a tinlake deployment
    // https://github.com/centrifuge/tinlake-pool-config/blob/master/mainnet-production.json

	address public ROOT = address(0);
	address public TINLAKE_CURRENCY = address(0);
	address public TITLE = address(0);
	address public PILE = address(0);
	address public FEED = address(0);
	address public SHELF = address(0);
	address public JUNIOR_TRANCHE = address(0);
	address public JUNIOR_TOKEN = address(0);
	address public JUNIOR_OPERATOR = address(0);
	address public JUNIOR_MEMBERLIST = address(0);
	address public SENIOR_TRANCHE = address(0);
	address public SENIOR_TOKEN = address(0);
	address public SENIOR_OPERATOR = address(0);
	address public SENIOR_MEMBERLIST = address(0);
	address public RESERVE = address(0);
	address public ASSESSOR = address(0);
	address public POOL_ADMIN = address(0);
	address public COORDINATOR = address(0);
	address public CLERK = address(0);
	address public MGR = address(0);
	address public VAT = address(0);
	address public JUG = address(0);

    uint256 constant ONE = 10**27;
    address self;
    
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
       RootLike root = RootLike(address(ROOT));
       self = address(this);

     }  
}
