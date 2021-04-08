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

import "ds-test/test.sol";

// TODO: split interfaces between tests and spell. Exclude all the function that afre only used in tests
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

interface TrancheLike {
    function totalSupply() external returns(uint);
    function totalRedeem() external returns(uint);
}

interface SpellERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint) external returns (bool);
    function approve(address, uint) external;
}

// spell for: ns2 migration to rev pool with maker support
// - migrate state & swap contracts: assessor, reserve, coordinator
// - add & wire mkr adapter contracts: clerk & mgr, spotter, vat
contract TinlakeSpell is DSTest {

    bool public done;
    string constant public description = "Tinlake NS2 migration kovan Spell";

    address constant public ROOT = 0x25dF507570c8285E9c8E7FFabC87db7836850dCd;
    address constant public SHELF = 0xF269590165D1c266B7840a0Bc1B2A267C738F2Db;
    address constant public COLLECTOR = 0x086eA92e6B8DF55Fc7949C7CF9AE7B57f29C96Bb;
    address constant public SENIOR_TOKEN = 0x352Fee834a14800739DC72B219572d18618D9846;
    address constant public SENIOR_MEMBERLIST = 0xD927F069faf59eD83A1072624Eeb794235bBA652;
    address constant public SENIOR_OPERATOR = 0x6B902D49580320779262505e346E3f9B986e99e8;
    address constant public JUNIOR_TRANCHE = 0x4F56924037A6Daa5C0D0F766691a5a00d37e0Be6;
    address constant public ASSESSOR_WRAPPER = 0x105e88eFF33a7d57aa682b6E74E7DA03e2f7582B;
    address constant public NAV = 0x6056BBd3B79B4C1875CbA6E720Bbf7845B2e1180;
    address constant public SENIOR_TRANCHE_OLD = 0xDF0c780Ae58cD067ce10E0D7cdB49e92EEe716d9;
    address constant public ASSESSOR_OLD = 0x49527a20904aF41d1cbFc0ba77576B9FBd8ec9E5;
    address constant public COORDINATOR_OLD = 0xB51D3cbaa5CCeEf896B96091E69be48bCbDE8367;
    address constant public RESERVE_OLD = 0xc264eCc07728d43cdA564154c2638D3da110D4DD;
    
    address constant public TINLAKE_CURRENCY = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa; // DAI

    // new contracts -> to be migrated
    address constant public COORDINATOR_NEW = 0x2862f673Bd4eFCa828fb30090287B52eB1573aC3;
    address constant public ASSESSOR_NEW  = 0x2B1b54ab4E6F1d0f3349750a5e7b837F9Cb80cEB;
    address constant public RESERVE_NEW = 0xaAf1e5d73Ae4d9Ac2B36fA1ae9898CFeECef1F79;
    address constant public SENIOR_TRANCHE_NEW = 0x41196eA43Fc11858fdf5850C69484b21dd6A1772;

    // adapter contracts -> to be integrated
    address constant public CLERK = 0xeb236f629725b17C98b6CB93558637085bBD93FE;
    address constant public MGR =  0x8905C7066807793bf9c7cd1d236DEF0eE2692B9a;
    // mkr kovan contracts from release 1.2.10 https://changelog.makerdao.com/releases/kovan/1.2.10/contracts.json
    address constant public SPOTTER = 0x3a042de6413eDB15F2784f2f97cC68C7E9750b2D;
    address constant public VAT = 0xbA987bDB501d131f766fEe8180Da5d81b34b69d9;
    address constant public JUG = 0xcbB7718c9F39d05aEEDE1c472ca8Bf804b2f1EaD;
    // rwa contracts
    address constant public URN = 0xdFb4E887D89Ac14b0337C9dC05d8f5e492B9847C;
    address constant public LIQ = 0x2881c5dF65A8D81e38f7636122aFb456514804CC;


    uint constant public CLERK_BUFFER = 0.01 * 10**27;
    uint constant public ASSESSOR_MIN_SENIOR_RATIO = 0;
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
        root.relyContract(SHELF, self);
        root.relyContract(COLLECTOR, self);
        root.relyContract(JUNIOR_TRANCHE, self);
        root.relyContract(SENIOR_OPERATOR, self);
        root.relyContract(SENIOR_TRANCHE_OLD, self);
        root.relyContract(SENIOR_TRANCHE_NEW, self);
        root.relyContract(SENIOR_MEMBERLIST, self);
        root.relyContract(CLERK, self);
        root.relyContract(ASSESSOR_WRAPPER, self);
        root.relyContract(ASSESSOR_NEW, self);
        root.relyContract(COORDINATOR_NEW, self);
        root.relyContract(RESERVE_OLD, self);
        root.relyContract(RESERVE_NEW, self);
        root.relyContract(MGR, self);
    
        // contract migration --> assumption: root contract is already ward on the new contracts
        migrateAssessor();
        migrateCoordinator();
        migrateReserve();
        migrateTranche();
        integrateAdapter();

        // for mkr integration: set minSeniorRatio in Assessor to 0      
        FileLike(ASSESSOR_NEW).file("minSeniorRatio", ASSESSOR_MIN_SENIOR_RATIO);
    }

    function migrateAssessor() internal {
        MigrationLike(ASSESSOR_NEW).migrate(ASSESSOR_OLD);
        // migrate dependencies 
        DependLike(ASSESSOR_WRAPPER).depend("assessor", ASSESSOR_NEW);
        DependLike(ASSESSOR_NEW).depend("navFeed", NAV);
        DependLike(ASSESSOR_NEW).depend("juniorTranche", JUNIOR_TRANCHE);
        DependLike(ASSESSOR_NEW).depend("seniorTranche", SENIOR_TRANCHE_NEW);
        DependLike(ASSESSOR_NEW).depend("reserve", RESERVE_NEW);
        DependLike(ASSESSOR_NEW).depend("clerk", CLERK); 
        // migrate permissions
        AuthLike(ASSESSOR_NEW).rely(ASSESSOR_WRAPPER); 
        AuthLike(ASSESSOR_NEW).rely(COORDINATOR_NEW); 
    }

    function migrateCoordinator() internal {
        MigrationLike(COORDINATOR_NEW).migrate(COORDINATOR_OLD);
         // migrate dependencies 
        DependLike(COORDINATOR_NEW).depend("assessor", ASSESSOR_NEW);
        DependLike(COORDINATOR_NEW).depend("juniorTranche", JUNIOR_TRANCHE);
        DependLike(COORDINATOR_NEW).depend("seniorTranche", SENIOR_TRANCHE_NEW);
        DependLike(COORDINATOR_NEW).depend("reserve", RESERVE_NEW);
        // migrate permissions
        AuthLike(JUNIOR_TRANCHE).rely(COORDINATOR_NEW); 
        AuthLike(JUNIOR_TRANCHE).deny(COORDINATOR_OLD); 
        AuthLike(SENIOR_TRANCHE_NEW).rely(COORDINATOR_NEW);
    }

    function migrateReserve() internal {
        MigrationLike(RESERVE_NEW).migrate(RESERVE_OLD);
        // migrate dependencies 
        DependLike(RESERVE_NEW).depend("assessor", ASSESSOR_NEW);
        DependLike(RESERVE_NEW).depend("currency", TINLAKE_CURRENCY);
        DependLike(RESERVE_NEW).depend("shelf", SHELF);
        DependLike(RESERVE_NEW).depend("lending", CLERK);
        DependLike(RESERVE_NEW).depend("pot", RESERVE_NEW);

        DependLike(SHELF).depend("distributor", RESERVE_NEW);
        DependLike(COLLECTOR).depend("distributor", RESERVE_NEW);
        // migrate permissions
        AuthLike(RESERVE_NEW).rely(JUNIOR_TRANCHE);
        AuthLike(RESERVE_NEW).rely(SENIOR_TRANCHE_NEW);
        
        // migrate reserve balance
        SpellERC20Like currency = SpellERC20Like(TINLAKE_CURRENCY);
        uint balanceReserve = currency.balanceOf(RESERVE_OLD);
        SpellReserveLike(RESERVE_OLD).payout(balanceReserve);
        currency.transferFrom(self, RESERVE_NEW, balanceReserve);
    }

    function migrateTranche() internal {
        TrancheLike tranche = TrancheLike(SENIOR_TRANCHE_NEW);
        require((tranche.totalSupply() == 0 && tranche.totalRedeem() == 0), "tranche-has-orders");
        DependLike(SENIOR_TRANCHE_NEW).depend("reserve", RESERVE_NEW);
        DependLike(SENIOR_TRANCHE_NEW).depend("epochTicker", COORDINATOR_NEW);
        DependLike(SENIOR_OPERATOR).depend("tranche", SENIOR_TRANCHE_NEW);
    }

    function integrateAdapter() internal {

        // dependencies
        DependLike(CLERK).depend("assessor", ASSESSOR_NEW);
        DependLike(CLERK).depend("mgr", MGR);
        DependLike(CLERK).depend("coordinator", COORDINATOR_NEW);
        DependLike(CLERK).depend("reserve", RESERVE_NEW); 
        DependLike(CLERK).depend("tranche", SENIOR_TRANCHE_NEW);
        DependLike(CLERK).depend("collateral", SENIOR_TOKEN);
        DependLike(CLERK).depend("spotter", SPOTTER);
        DependLike(CLERK).depend("vat", VAT);
        DependLike(CLERK).depend("jug", JUG);

        // permissions
        AuthLike(CLERK).rely(COORDINATOR_NEW);
        AuthLike(CLERK).rely(RESERVE_NEW);
        AuthLike(SENIOR_TRANCHE_NEW).rely(CLERK);
        AuthLike(RESERVE_NEW).rely(CLERK);
        AuthLike(ASSESSOR_NEW).rely(CLERK);

        // currency
        SpellMemberlistLike(SENIOR_MEMBERLIST).updateMember(CLERK, uint(-1));
        SpellMemberlistLike(SENIOR_MEMBERLIST).updateMember(MGR, uint(-1));

        // setup mgr
        FileLike(MGR).file("urn", URN);
        FileLike(MGR).file("liq", LIQ);
        FileLike(MGR).file("owner", CLERK);
        FileLike(MGR).file("pool", SENIOR_OPERATOR);
        FileLike(MGR).file("tranche", SENIOR_TRANCHE_NEW);
    }

}