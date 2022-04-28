pragma solidity >=0.6.12;
import "ds-test/test.sol";
import "./addresses_ff1.sol";
import "./nav.sol";

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
        function migrate(address, uint, address, uint) external;
}

interface SpellMemberlistLike {
    function updateMember(address, uint) external;
}

interface PoolAdminLike {
    function setAdminLevel(address usr, uint level) external;
}

interface SpellTitleLike {
    function count() external returns(uint);
}

interface PoolRegistryLike {
    function file(address, bool, string memory, string memory) external;
    function find(address pool) external view returns (bool live, string memory name, string memory data);
}

interface SpellCoordinatorLike {
     function closeEpoch() external returns (bool);
}

// spell to swap clerk, coordinator & poolAdmin
contract TinlakeSpell is Addresses, DSTest {

    bool public done;
    string constant public description = "Tinlake GigPool spell";

    // MAINNET ADDRESSES
    // The contracts in this list should correspond to a tinlake deployment
    // https://github.com/centrifuge/tinlake-pool-config/blob/master/mainnet-production.json

    address public POOL_REGISTRY = 0xddf1C516Cf87126c6c610B52FD8d609E67Fb6033;
    string constant public IPFS_HASH = "QmR4NMhUEDoHBe5XP3w8kszpRtEHfugoKDDvgFMNNcV2Cm";

    MigratedNAVFeed nav = new MigratedNAVFeed();
    address public NAV = address(nav);

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

       // helper for tests, as long as the contract is not deployed
       nav.rely(address(ROOT));

       // set spell as ward on the core contract to be able to wire the new contracts correctly
       root.relyContract(SHELF, self);
       root.relyContract(PILE, self);
       root.relyContract(ASSESSOR, self);
       root.relyContract(NAV, self);
       

        // contract migration --> assumption: root contract is already ward on the new contracts
        migrateNav();
        updateRegistry();
     }  


    function migrateNav() internal {

        // only migrate NAV after successful epoch execution
        bool executed = SpellCoordinatorLike(COORDINATOR).closeEpoch();
        require(executed == true , "epoch execution failed");


        uint riskGroupCount = 1;
        address ORACLE = 0x1c3C2E90B7D7Ac525f933597Eb228F8c74A28Cd2;
        uint loanCount = SpellTitleLike(TITLE).count();

        // set dependenciesfirst, so that migration works
        DependLike(NAV).depend("shelf", SHELF);
        DependLike(NAV).depend("pile", PILE);
        DependLike(NAV).depend("title", TITLE);
        DependLike(SHELF).depend("ceiling", NAV); // set new nav as ceiling contract on shelf
        DependLike(SHELF).depend("subscriber", NAV); 
        DependLike(ASSESSOR).depend("navFeed", NAV);

        MigrationLike(NAV).migrate(NAV_OLD, riskGroupCount, ORACLE, loanCount);
    
        // permissions
        AuthLike(NAV).rely(SHELF);  // add shelf as ward on new nav
        AuthLike(PILE).deny(NAV_OLD);   // remove old nav as ward on pile
        AuthLike(PILE).rely(NAV);   // add new nav as ward on pile
    }

    function updateRegistry() internal {
       //PoolRegistryLike(POOL_REGISTRY).file(ROOT, true, "gig-pool", IPFS_HASH);
    }
}
