pragma solidity >=0.6.12;

import "./addresses_htc2.sol";

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

interface DependLike {
    function depend(bytes32, address) external;
}

interface MigrationLike {
        function migrate(address) external;
}

interface SpellMemberlistLike {
    function updateMember(address, uint) external;
}

interface PoolAdminLike {
    function setAdminLevel(address usr, uint level) external;
}

interface PoolRegistryLike {
    function file(address, bool, string memory, string memory) external;
    function find(address pool) external view returns (bool live, string memory name, string memory data);
}

// spell to swap clerk, coordinator & poolAdmin
contract TinlakeSpell is Addresses {

    bool public done;
    string constant public description = "Tinlake GigPool spell";

    // MAINNET ADDRESSES
    // The contracts in this list should correspond to a tinlake deployment
    // https://github.com/centrifuge/tinlake-pool-config/blob/master/mainnet-production.json

    address public CLERK = 0xb082569c4A1414D3F44EfB60300E87B8a15ec455;
    address public COORDINATOR = 0x7bD6fe3AC16AAE89D639b4C85a02907339c10CC1;
    address public POOL_ADMIN = 0xAa7B2eB291E4Bf01B2457C4ee52428C814ad7Dc3;

    address public MEMBER_ADMIN = 0xB7e70B77f6386Ffa5F55DDCb53D87A0Fb5a2f53b;
    address public LEVEL3_ADMIN1 = 0x7b74bb514A1dEA0Ec3763bBd06084e712c8bce97;
    address public LEVEL1_ADMIN1 = 0x71d9f8CFdcCEF71B59DD81AB387e523E2834F2b8;
    address public LEVEL1_ADMIN2 = 0x46a71eEf8DbcFcbAC7A0e8D5d6B634A649e61fb8;
    address public LEVEL1_ADMIN3 = 0x9eDec77dd2651Ce062ab17e941347018AD4eAEA9;
    address public LEVEL1_ADMIN4 = 0xEf270f8877Aa1875fc13e78dcA31f3235210368f;
    address public LEVEL1_ADMIN5 = 0xddEa1De10E93c15037E83b8Ab937A46cc76f7009;
    address public AO_POOL_ADMIN = 0xbAc249271918db4261fF60354cc97Bb4cE9A08A1;

    address public POOL_REGISTRY = 0xddf1C516Cf87126c6c610B52FD8d609E67Fb6033;

    string constant public IPFS_HASH = "Qmbb8UAtouEHUkZXwUWH1GLJnDPBqxccF43rjrWpjiTkRo";

    uint256 constant ONE = 10**27;
    address self;
    
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
       TinlakeRootLike root = TinlakeRootLike(address(ROOT));
       self = address(this);
       // permissions 
       root.relyContract(CLERK, self); // required to file riskGroups & change discountRate
       root.relyContract(CLERK_OLD, self); // required to change the interestRates for loans according to new riskGroups
       root.relyContract(SENIOR_TRANCHE, self);
       root.relyContract(SENIOR_TOKEN, self);
       root.relyContract(SENIOR_TRANCHE, self);
       root.relyContract(JUNIOR_TRANCHE, self);
       root.relyContract(SENIOR_MEMBERLIST, self);
       root.relyContract(JUNIOR_MEMBERLIST, self);
       root.relyContract(POOL_ADMIN, self);
       root.relyContract(ASSESSOR, self);
       root.relyContract(COORDINATOR, self);
       root.relyContract(COORDINATOR_OLD, self);
       root.relyContract(RESERVE, self);
       root.relyContract(MGR, self);
       root.relyContract(FEED, self);
       
       migrateClerk();
       migrateCoordinator();
       migratePoolAdmin();
       updateRegistry();
     }  

    function migrateCoordinator() internal {
        // migrate state
        MigrationLike(COORDINATOR).migrate(COORDINATOR_OLD);

        // migrate dependencies
        DependLike(COORDINATOR).depend("assessor", ASSESSOR);
        DependLike(COORDINATOR).depend("juniorTranche", JUNIOR_TRANCHE);
        DependLike(COORDINATOR).depend("seniorTranche", SENIOR_TRANCHE);

        DependLike(CLERK).depend("coordinator", COORDINATOR);

        DependLike(SENIOR_TRANCHE).depend("coordinator", COORDINATOR);
        DependLike(JUNIOR_TRANCHE).depend("coordinator", COORDINATOR);

        // migrate permissions
        AuthLike(ASSESSOR).rely(COORDINATOR); 
        AuthLike(ASSESSOR).deny(COORDINATOR_OLD);
        AuthLike(JUNIOR_TRANCHE).rely(COORDINATOR); 
        AuthLike(JUNIOR_TRANCHE).deny(COORDINATOR_OLD); 
        AuthLike(SENIOR_TRANCHE).rely(COORDINATOR);
        AuthLike(SENIOR_TRANCHE).deny(COORDINATOR_OLD);
     }

    function migratePoolAdmin() internal {
        // setup dependencies 
        DependLike(POOL_ADMIN).depend("assessor", ASSESSOR);
        // DependLike(POOL_ADMIN).depend("lending", CLERK); // set in clerk migration
        DependLike(POOL_ADMIN).depend("seniorMemberlist", SENIOR_MEMBERLIST);
        DependLike(POOL_ADMIN).depend("juniorMemberlist", JUNIOR_MEMBERLIST);
        DependLike(POOL_ADMIN).depend("navFeed", FEED);
        DependLike(POOL_ADMIN).depend("coordinator", COORDINATOR);

        // setup permissions
        AuthLike(ASSESSOR).rely(POOL_ADMIN);
        AuthLike(ASSESSOR).deny(POOL_ADMIN_OLD);
        // AuthLike(CLERK).rely(POOL_ADMIN); // set in clerk migration
        // AuthLike(CLERK).deny(POOL_ADMIN_OLD);
        AuthLike(JUNIOR_MEMBERLIST).rely(POOL_ADMIN);
        AuthLike(JUNIOR_MEMBERLIST).deny(POOL_ADMIN_OLD);
        AuthLike(SENIOR_MEMBERLIST).rely(POOL_ADMIN);
        AuthLike(SENIOR_MEMBERLIST).deny(POOL_ADMIN_OLD);
        AuthLike(FEED).rely(POOL_ADMIN);
        AuthLike(FEED).deny(POOL_ADMIN_OLD);
        AuthLike(COORDINATOR).rely(POOL_ADMIN);
        AuthLike(COORDINATOR).deny(POOL_ADMIN_OLD);

        // set lvl3 admins
        AuthLike(POOL_ADMIN).rely(LEVEL3_ADMIN1);
        // set lvl1 admins
        PoolAdminLike(POOL_ADMIN).setAdminLevel(LEVEL1_ADMIN1, 1);
        PoolAdminLike(POOL_ADMIN).setAdminLevel(LEVEL1_ADMIN2, 1);
        PoolAdminLike(POOL_ADMIN).setAdminLevel(LEVEL1_ADMIN3, 1);
        PoolAdminLike(POOL_ADMIN).setAdminLevel(LEVEL1_ADMIN4, 1);
        PoolAdminLike(POOL_ADMIN).setAdminLevel(LEVEL1_ADMIN5, 1);
        PoolAdminLike(POOL_ADMIN).setAdminLevel(AO_POOL_ADMIN, 1);
        AuthLike(JUNIOR_MEMBERLIST).rely(MEMBER_ADMIN);
        AuthLike(SENIOR_MEMBERLIST).rely(MEMBER_ADMIN);
    }

    function migrateClerk() internal {
        // migrate state
        MigrationLike(CLERK).migrate(CLERK_OLD);
    
        // dependencies
        DependLike(CLERK).depend("assessor", ASSESSOR);
        DependLike(CLERK).depend("mgr", MGR);
        DependLike(CLERK).depend("coordinator", COORDINATOR);
        DependLike(CLERK).depend("reserve", RESERVE); 
        DependLike(CLERK).depend("tranche", SENIOR_TRANCHE);
        DependLike(CLERK).depend("collateral", SENIOR_TOKEN);
        DependLike(CLERK).depend("spotter", SPOTTER);
        DependLike(CLERK).depend("vat", VAT);
        DependLike(CLERK).depend("jug", JUG);

        // permissions
        AuthLike(CLERK).rely(RESERVE);
        AuthLike(CLERK).rely(POOL_ADMIN);
        AuthLike(SENIOR_TRANCHE).rely(CLERK);
        AuthLike(RESERVE).rely(CLERK);
        AuthLike(ASSESSOR).rely(CLERK);
        AuthLike(MGR).rely(CLERK);

        // adjust autohealing tolerance to unblock epoch exec
        FileLike(CLERK).file("autoHealMax", 3000 ether);

        FileLike(MGR).file("owner", CLERK);

        DependLike(ASSESSOR).depend("lending", CLERK);
        DependLike(RESERVE).depend("lending", CLERK);
        DependLike(POOL_ADMIN).depend("lending", CLERK);
       
        // restricted token setup
        SpellMemberlistLike(SENIOR_MEMBERLIST).updateMember(CLERK, uint(-1));

        // remove old clerk
        AuthLike(SENIOR_TRANCHE).deny(CLERK_OLD);
        AuthLike(RESERVE).deny(CLERK_OLD);
        AuthLike(ASSESSOR).deny(CLERK_OLD);
        AuthLike(MGR).deny(CLERK_OLD);
    }

    function updateRegistry() internal {
        // @Adam please add correct hash & name
        // PoolRegistryLike(POOL_REGISTRY).file(ROOT, true, "fortunafi-1", IPFS_HASH);
    }
}
