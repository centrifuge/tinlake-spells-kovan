/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/spell.sol

pragma solidity >=0.6.12;

////// src/spell.sol
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
/* pragma solidity >=0.6.12; */

interface AuthLike {
    function rely(address) external;
    function deny(address) external;
    function wards(address) external returns(uint);
}

interface TinlakeRootLike {
    function relyContract(address, address) external;
    function denyContract(address, address) external;
}

interface FileLike {
    function file(bytes32, uint) external;
    function file(bytes32, address) external;
}

interface NAVFeedLike {
    function file(bytes32 name, uint value) external;
    function file(bytes32 name, uint risk_, uint thresholdRatio_, uint ceilingRatio_, uint rate_, uint recoveryRatePD_) external;
    function discountRate() external returns(uint);
}

// This spell makes changes to the tinlake mainnet HTC2 deployment:
// adds new risk groups 
contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake CF4 Mainnet Spell - 3";

    // MAINNET ADDRESSES
    // The contracts in this list should correspond to a tinlake deployment
    // https://github.com/centrifuge/tinlake-pool-config/blob/master/mainnet-production.json

    address constant public ROOT = 0x3d167bd08f762FD391694c67B5e6aF0868c45538;
    address constant public NAV_FEED = 0x468eb2408c6F24662a291892550952eb0d70b707;
    address constant public PILE = 0x9E39e0130558cd9A01C1e3c7b2c3803baCb59616;
                                                             
    uint256 constant ONE = 10**27;
    address self;
    
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
       TinlakeRootLike root = TinlakeRootLike(address(ROOT));
       NAVFeedLike navFeed = NAVFeedLike(address(NAV_FEED));
       self = address(this);
        // NavFeed 
        root.relyContract(NAV_FEED, self); // required to file riskGroups & change discountRate


        // risk group: 3 - M, APR: 13.00%
        navFeed.file("riskGroup", 3, ONE, ONE, uint256(1000000004122272957889396245), 99.9*10**25);
        // risk group: 4 - W, APR: 11.00%
        navFeed.file("riskGroup", 4, ONE, ONE, uint256(1000000003488077118214104515), 99.9*10**25);
        // risk group: 5 - PC, APR: 10.00%
        navFeed.file("riskGroup", 5, ONE, ONE, uint256(1000000003170979198376458650), 99.9*10**25);

     }   
}