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
pragma solidity >=0.6.2;
pragma experimental ABIEncoderV2;

interface SpellTinlakeRootLike {
    function relyContract(address, address) external;
}

interface SpellMemberlistLike {
    function updateMember(address, uint) external;
}

interface SpellReserveLike {
    function payout(uint currencyAmount) external;
}

interface DependLike {
    function depend(bytes32, address) external;
}

interface FileLike {
    function file(bytes32, uint) external;
    function file(bytes32, address) external;
}

interface AuthLike {
    function rely(address) external;
    function deny(address) external;
}

interface MigrationLike {
    function migrate(address) external;
}

interface PoolAdminLike {
    function relyAdmin(address) external;
}

interface MgrLike {
    function lock(uint) external;
}

interface SpellERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint) external returns (bool);
    function approve(address, uint) external;
}

// spell for: htc coordinator migration
contract TinlakeSpell {


// tinlake addresses
//   "DEPLOYMENT_NAME": "HC2 mainnet",
//   "ROOT_CONTRACT": "0x4cA805cE8EcE2E63FfC1F9f8F2731D3F48DF89Df",
//   "TINLAKE_CURRENCY": "0x6b175474e89094c44da98b954eedeac495271d0f",
//   "BORROWER_DEPLOYER": "0xD2e2Bbb8FdA55780532894eeb9F2439bd183069B",
//   "TITLE_FAB": "0xfa151AA0DA51ba3b862848f6ded4a33341F0C977",
//   "SHELF_FAB": "0x4Cb05f2deEDedE35Afc9bc0FEF85875ABab4AA95",
//   "PILE_FAB": "0x0168e7999318a6c2393c2Eb19A5Da4aB9d715173",
//   "COLLECTOR_FAB": "0x618982e6E6E28e1dDa8405E4bC0aD96f5a4082aF",
//   "FEED_FAB": "0xA6C2E8f1f7c31d0340767bDf969Ff31A45bA60D1",
//   "TITLE": "0x669Db70d3A0D7941F468B0d907E9d90BD7ddA8d1",
//   "PILE": "0xE7876f282bdF0f62e5fdb2C63b8b89c10538dF32",
//   "SHELF": "0x5b2b43b3676057e38F332De73A9fCf0F8f6Babf7",
//   "COLLECTOR": "0xDdA9c8631ea904Ef4c0444F2A252eC7B45B8e7e9",
//   "FEED": "0xdB9A84e5214e03a4e5DD14cFB3782e0bcD7567a7",
//   "LENDER_DEPLOYER": "0x1062F023771E15367A9cde84652E62Fdc046f32f",
//   "OPERATOR_FAB": "0x4187E615DB017b004122fFFd165928eb992b1E15",
//   "ASSESSOR_FAB": "0x0ab60483dCCA7DC34C33134cA20DB758c2d47fbb",
//   "ASSESSOR_ADMIN_FAB": "0xE6468EACa0e17F4fa1F80CC3c16C10ae15bA4bA1",
//   "COORDINATOR_FAB": "0x6f20E3cd5F6597D472C82c15429959788e7a17D2",
//   "TRANCHE_FAB": "0x14Da336ffd1d163347dFff9E5972392030Ed1c03",
//   "MEMBERLIST_FAB": "0xEaFD4B3573CEEb0Edb2cFBdDBF94f07a9f749FE0",
//   "RESTRICTEDTOKEN_FAB": "0x0e9A86D770EDa4dea6c1d7C8cd23245318F4327a",
//   "RESERVE_FAB": "0xb89532E0648d5b24e8c6302424C620C726780fbc",
//   "JUNIOR_OPERATOR": "0x6DAecbC801EcA2873599bA3d980c237D9296cF57",
//   "SENIOR_OPERATOR": "0xEDCD9e36017689c6Fc51C65c517f488E3Cb6C381",
//   "JUNIOR_TRANCHE": "0x294309E42e1b3863a316BEb52df91B1CcB15eef9",
//   "SENIOR_TRANCHE": "0x1940E2A20525B103dCC9884902b0186371227393",
//   "JUNIOR_TOKEN": "0xAA67Bb563e14fBd4E92DCc646aAac0c00c7d9526",
//   "SENIOR_TOKEN": "0xd511397f79b112638ee3B6902F7B53A0A23386C4",
//   "JUNIOR_MEMBERLIST": "0x0b635CD35fC3AF8eA29f84155FA03dC9AD0Bab27",
//   "SENIOR_MEMBERLIST": "0x1Bc55bcAf89f514CE5a8336bEC7429a99e804910",
//   "ASSESSOR": "0x6e40A9d1eE2c8eF95322b879CBae35BE6Dd2D143",
//   "ASSESSOR_ADMIN": "0x35e805BA2FB7Ad4C8Ad9D644Ca9Bd34a49f5500d",
//   "COORDINATOR": "0xd2Ee4e2163188Eeeb4F4773CCbb712E8605cDcbb",
//   "RESERVE": "0x573a8a054e0C80F0E9B1e96E8a2198BB46c999D6",
//   "GOVERNANCE": "0xf3BceA7494D8f3ac21585CA4b0E52aa175c24C25",
//   "MAIN_DEPLOYER": "0x1a5a533BcF4ef8A884732056f413114159d03058",
//   "COMMIT_HASH": "b44130a0f95caf170e94afa01bdd4958f6c2ad4b"

    bool public done;
    string constant public description = "Tinlake HTC2 coordinator migration mainnet Spell";

    address constant public ROOT = 0x4cA805cE8EcE2E63FfC1F9f8F2731D3F48DF89Df;
    address constant public JUNIOR_TRANCHE = 0x294309E42e1b3863a316BEb52df91B1CcB15eef9;
    address constant public SENIOR_TRANCHE = 0x1940E2A20525B103dCC9884902b0186371227393;
    address constant public ASSESSOR = 0x6e40A9d1eE2c8eF95322b879CBae35BE6Dd2D143;
    address constant public RESERVE = 0x573a8a054e0C80F0E9B1e96E8a2198BB46c999D6;
    address constant public COORDINATOR_OLD = 0xd2Ee4e2163188Eeeb4F4773CCbb712E8605cDcbb;
    address constant public COORDINATOR_NEW = 0xE2a04a4d4Df350a752ADA79616D7f588C1A195cF;
    
    address self;

    // permissions to be set
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        SpellTinlakeRootLike root = SpellTinlakeRootLike(ROOT);
        self = address(this);
        // set spell as ward on the core contract to be able to wire the new contracts correctly
        root.relyContract(JUNIOR_TRANCHE, self);
        root.relyContract(SENIOR_TRANCHE, self);
        root.relyContract(ASSESSOR, self);
        root.relyContract(RESERVE, self);
        root.relyContract(COORDINATOR_NEW, self);
    
        // contract migration --> assumption: root contract is already ward on the new contracts
        migrateCoordinator();
    }

    function migrateCoordinator() internal {
         // migrate dependencies 
        DependLike(COORDINATOR_NEW).depend("assessor", ASSESSOR);
        DependLike(COORDINATOR_NEW).depend("juniorTranche", JUNIOR_TRANCHE);
        DependLike(COORDINATOR_NEW).depend("seniorTranche", SENIOR_TRANCHE);
        DependLike(COORDINATOR_NEW).depend("reserve", RESERVE);
        
        DependLike(JUNIOR_TRANCHE).depend("epochTicker", COORDINATOR_NEW);
        DependLike(SENIOR_TRANCHE).depend("epochTicker", COORDINATOR_NEW);

        // migrate permissions
        AuthLike(ASSESSOR).rely(COORDINATOR_NEW); 
        AuthLike(ASSESSOR).deny(COORDINATOR_OLD);
        AuthLike(JUNIOR_TRANCHE).rely(COORDINATOR_NEW); 
        AuthLike(JUNIOR_TRANCHE).deny(COORDINATOR_OLD); 
        AuthLike(SENIOR_TRANCHE).rely(COORDINATOR_NEW);
        AuthLike(SENIOR_TRANCHE).deny(COORDINATOR_OLD);

        // migrate state
        MigrationLike(COORDINATOR_NEW).migrate(COORDINATOR_OLD);
    }
}