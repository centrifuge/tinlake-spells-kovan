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

import "lib/tinlake/src/root.sol";

// Deployed Contract Address: 0xAB98D63F262BDA050777bFaB5d48c76e1a11A84A
// spell adds a new admin to the senior memberlist 
contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake Kovan Spell";

    // KOVAN ADDRESSES
    // The contracts in this list should correspond to a tinlake deployment
    // https://github.com/centrifuge/tinlake-pool-config/blob/master/kovan-staging.json

    // REVPOOL 1 root contracts
    address constant public ROOT = 0xc4084221Fb5D0f28f817c795435C2d17EAb6c389;
    address constant public JUNIOR_MEMBERLIST = 0x3b07CEA6096591B51DB82717D64e882F2f95D445;
    address constant public SENIOR_MEMBERLIST = 0x9fC4856165490b7A3F024b2ADB054B902B42ab7d;
    address constant public COORDINATOR = 0x9C5431A86DEDaDE67e59E0555c9FeA9b6632D8d2;
    address constant public ASSESSOR = 0x8B80927fCa02566C29728C4a620c161F63116953;

    // permissions to be set
    address constant public SENIOR_MEMBERLIST_ADMIN = 0xf76e7ef1DC246Ee3034C37b4B10b744643Fd8375;

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
       TinlakeRoot root = TinlakeRoot(address(ROOT));
      
       // add permissions for SeniorToken MemberList  
       root.relyContract(SENIOR_MEMBERLIST, SENIOR_MEMBERLIST_ADMIN);
    }   
}
