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
}

interface AuthLike {
    function rely(address) external;
    function deny(address) external;
}

interface MigrationLike {
    function migrate(address) external;
}

interface SpellERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint) external returns (bool);
    function approve(address, uint) external;
}

// spell for: ns2 migration to rev pool with maker support
// - migrate state & swap contracts: assessor, reserve, coordinator
// - add & wire mkr adapter contracts: clerk & mgr, spotter, vat
contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake NS2 migration kovan Spell";

    address constant public ROOT = 0x25dF507570c8285E9c8E7FFabC87db7836850dCd;
    address constant public SHELF = 0xF269590165D1c266B7840a0Bc1B2A267C738F2Db;
    address constant public COLLECTOR = 0x086eA92e6B8DF55Fc7949C7CF9AE7B57f29C96Bb;
    address constant public SENIOR_TOKEN = 0x352Fee834a14800739DC72B219572d18618D9846;
    address constant public SENIOR_TRANCHE = 0xDF0c780Ae58cD067ce10E0D7cdB49e92EEe716d9;
    address constant public SENIOR_MEMBERLIST = 0xD927F069faf59eD83A1072624Eeb794235bBA652;
    address constant public JUNIOR_TRANCHE = 0x4F56924037A6Daa5C0D0F766691a5a00d37e0Be6;
    address constant public ASSESSOR_WRAPPER = 0x105e88eFF33a7d57aa682b6E74E7DA03e2f7582B;
    address constant public NAV = 0x8f90432c37d58aB79802B31e15F59556236123dA;
    address constant public ASSESSOR_OLD = 0x29BB673054b6Fd268d73af5D676f150C91bd63af;
    address constant public COORDINATOR_OLD = 0xD2F4ba3117c6463cB67001538041fBA898bc7a2e;
    address constant public RESERVE_OLD = 0x1207BA4152C54eA742cf0FD153d999422AA60ea5;
    
    address constant public TINLAKE_CURRENCY = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa; // DAI

    // new contracts -> to be migrated
    address constant public COORDINATOR_NEW = 0xB51D3cbaa5CCeEf896B96091E69be48bCbDE8367;
    address constant public ASSESSOR_NEW  = 0x49527a20904aF41d1cbFc0ba77576B9FBd8ec9E5;
    address constant public RESERVE_NEW = 0xc264eCc07728d43cdA564154c2638D3da110D4DD;

    // adapter contracts -> to be integrated
    address constant public CLERK  = 0xE3F80411CD0Dd02Def6AF3041DA4c6f9b87BA1D8;
    address constant public MGR = 0x65242F75e6cCBF973b15d483dD5F555d13955A1e;
    // mkr kovan contracts from release 1.2.2 https://changelog.makerdao.com/releases/kovan/1.2.2/contracts.json
    address constant public SPOTTER = 0x3a042de6413eDB15F2784f2f97cC68C7E9750b2D;
    address constant public VAT = 0xbA987bDB501d131f766fEe8180Da5d81b34b69d9;


    uint constant public CLERK_BUFFER = 0;
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
        root.relyContract(SENIOR_TRANCHE, self);
        root.relyContract(SENIOR_MEMBERLIST, self);
        root.relyContract(CLERK, self);
        root.relyContract(ASSESSOR_WRAPPER, self);
        root.relyContract(ASSESSOR_NEW, self);
        root.relyContract(COORDINATOR_NEW, self);
        root.relyContract(RESERVE_OLD, self);
        root.relyContract(RESERVE_NEW, self);
    
        // contract migration --> assumption: root contract is already ward on the new contracts
        migrateAssessor();
        migrateCoordinator();
        migrateReserve();
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
        DependLike(ASSESSOR_NEW).depend("seniorTranche", SENIOR_TRANCHE);
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
        DependLike(COORDINATOR_NEW).depend("seniorTranche", SENIOR_TRANCHE);
        DependLike(COORDINATOR_NEW).depend("reserve", RESERVE_NEW);
        // migrate permissions
        AuthLike(JUNIOR_TRANCHE).rely(COORDINATOR_NEW); 
        AuthLike(SENIOR_TRANCHE).rely(COORDINATOR_NEW);
        AuthLike(JUNIOR_TRANCHE).deny(COORDINATOR_OLD); 
        AuthLike(SENIOR_TRANCHE).deny(COORDINATOR_OLD); 
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
        AuthLike(RESERVE_NEW).rely(SENIOR_TRANCHE);
        
        // migrate reserve balance
        SpellERC20Like currency = SpellERC20Like(TINLAKE_CURRENCY);
        uint balanceReserve = currency.balanceOf(RESERVE_OLD);
        SpellReserveLike(RESERVE_OLD).payout(balanceReserve);
        currency.transferFrom(self, RESERVE_NEW, balanceReserve);
    }

    function integrateAdapter() internal {
        // dependencies
        DependLike(CLERK).depend("assessor", ASSESSOR_NEW);
        DependLike(CLERK).depend("mgr", MGR);
        DependLike(CLERK).depend("coordinator", COORDINATOR_NEW);
        DependLike(CLERK).depend("reserve", RESERVE_NEW); 
        DependLike(CLERK).depend("tranche", SENIOR_TRANCHE);
        DependLike(CLERK).depend("collateral", SENIOR_TOKEN);
        DependLike(CLERK).depend("spotter", SPOTTER);
        DependLike(CLERK).depend("vat",VAT);

        // permissions
        AuthLike(CLERK).rely(COORDINATOR_NEW);
        AuthLike(CLERK).rely(RESERVE_NEW);
        AuthLike(SENIOR_TRANCHE).rely(CLERK);
        AuthLike(RESERVE_NEW).rely(CLERK);
        AuthLike(ASSESSOR_NEW).rely(CLERK);

        // currency
        SpellMemberlistLike(SENIOR_MEMBERLIST).updateMember(CLERK, uint(-1));
        SpellMemberlistLike(SENIOR_MEMBERLIST).updateMember(MGR, uint(-1));

        // state
        FileLike(CLERK).file("buffer", CLERK_BUFFER);
    }
}
