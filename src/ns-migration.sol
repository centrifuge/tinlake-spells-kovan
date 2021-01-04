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


// TODO: split interfaces between tests and spell. Exclude all the function that afre only used in tests
interface TinlakeRootLike {
    function relyContract(address, address) external;
}

interface MemberlistLike {
    function updateMember(address, uint) external;
}

interface DependLike {
    function depend(bytes, address) external;
}

interface FileLike {
    function file(bytes, address) external;
}

interface AuthLike {
    function rely(address) external;
    function deny(address) external;
}

interface MigrationLike {
    function migrate(address) external;
}

interface ERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint) external returns (bool);
    function approve(address, uint) external;
}

interface ReserveLike {
    function payout(uint currencyAmount) external;
}

// spell for: ns2 migration to rev pool with maker support
// - migrate state & swap contracts: assessor, reserve, coordinator
// - add & wire mkr adapter contracts: clerk & mgr, spotter, vat
contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake NS2 migration kovan Spell";

    address constant public ROOT = 0xB86a5F04F5aE402d8547842A29071309C23b47e1;
    address constant public SHELF = 0xe03A4812E1Ae31567932BDBf3618Ba5F64918bCB;
    address constant public COLLECTOR = 0x751FF4Dd537aE8f1bA226Ae5d667a6406a53754C;
    address constant public SENIOR_TOKEN = 0xa1ff44b597549aE3f79Ab02109DD84B465CD7cCC;
    address constant public SENIOR_TRANCHE = 0xb3A6758FB6F79905692B3D805786B362cACB9f75;
    address constant public SENIOR_MEMBERLIST = 0x71F515E53a9B0831c0Df03bcD33b6e6701F9e278;
    address constant public JUNIOR_TRANCHE = 0xb148DA9cB8F7Ee64290105888D21aa3325681a6f;
    address constant public ASSESSOR_WRAPPER = 0x7048AFBa9aBA4d3CF206e341bD22c2CA47061Fe8;
    address constant public TINLAKE_CURRENCY = 0x99E21e1e7D99d06F780666A3BE6Ba178De04B0a9;
    address constant public NAV = 0x8f90432c37d58aB79802B31e15F59556236123dA;

    // contracts to be swapped
    address constant public ASSESSOR_OLD  = 0x00423Eb98c9CC2F43080A3A3Df3bf2a58Fcf29EB;
    address constant public COORDINATOR_OLD = 0xb0AefE053F73bEd8b922da60451f2eaEC71F4b2f;
    address constant public RESERVE_OLD = 0xbCd87D68A7829A9c6B4C763D2e9F9f345c61E0f6;
    address constant public COORDINATOR_NEW = 0x0000000000000000000000000000000000000000;
    address constant public ASSESSOR_NEW  = 0x0000000000000000000000000000000000000000;
    address constant public RESERVE_NEW = 0x0000000000000000000000000000000000000000;

    // adapter contracts
    address constant public CLERK  = 0x0000000000000000000000000000000000000000;
    address constant public MGR = 0x0000000000000000000000000000000000000000;
    address constant public SPOTTER = 0x0000000000000000000000000000000000000000;
    address constant public VAT = 0x0000000000000000000000000000000000000000;

    uint constant public CLERK_BUFFER = 0;

    // permissions to be set
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        TinlakeRootLike root = TinlakeRootLike(ROOT);
        address self = address(this);
        // set spell as ward on the core contract to be able to wire the new contracts correctly
        root.relyContract(SHELF, self);
        root.relyContract(COLLECTOR, self);
        root.relyContract(ASSESSOR_NEW, self);
        root.relyContract(COORDINATOR_NEW, self);
        root.relyContract(RESERVE_NEW, self);
        root.relyContract(CLERK, self);
        // contract migration --> assumption: root contract is already ward on the new contracts
        migrateAssessor();
        migrateCoordinator();
        migrateReserve();
        integrateAdapter();
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
        AuthLike(ASSESSOR_NEW).rely(CLERK);
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
        DependLike(RESERVE_NEW).depend("lending", CLERK);
        DependLike(SHELF).depend("distributor", RESERVE_NEW);
        DependLike(COLLECTOR).depend("distributor", RESERVE_NEW);
        // migrate permissions
        AuthLike(RESERVE_NEW).rely(JUNIOR_TRANCHE);
        AuthLike(RESERVE_NEW).rely(SENIOR_TRANCHE);
        AuthLike(RESERVE_NEW).rely(CLERK);
        // migrate state
        // following values have to be migrated as part of the consturctor of the new reserve -> check in rpc test of this spell: currencyAvailable, balance_
        // migrate reserve balance
        ERC20Like dai = ERC20Like(TINLAKE_CURRENCY);
        uint balanceReserveDAI = dai.balanceOf(RESERVE_OLD);
        ReserveLike(RESERVE_OLD).payout(balanceReserveDAI);
        dai.approve(RESERVE_NEW, balanceReserveDAI);
        dai.transferFrom(self, RESERVE_NEW, balanceReserveDAI);
    }

    function integrateAdapter() internal {
        // dependencies
        DependLike(CLERK).depend("assessor", ASSESSOR_NEW);
        DependLike(CLERK).depend("mgr", MGR);
        DependLike(CLERK).depend("coordintaor", COORDINATOR_NEW);
        DependLike(CLERK).depend("reserve", RESERVE_NEW); 
        DependLike(CLERK).depend("tranche", SENIOR_TRANCHE);
        DependLike(CLERK).depend("collateral", SENIOR_TOKEN);
        DependLike(CLERK).depend("spotter", SPOTTER);
        DependLike(CLERK).depend("vat",VAT);
        // permissions
        AuthLike(CLERK).rely(COORDINATOR_NEW);
        AuthLike(CLERK).rely(RESERVE_NEW);
        AuthLike(SENIOR_TRANCHE).rely(clerk);
        // currency
        MemberlistLike(SENIOR_MEMBERLIST).updateMember(CLERK, uint(-1));
        MemberlistLike(SENIOR_MEMBERLIST).updateMember(MGR, uint(-1));
        // state
        FileLike(Clerk).file("buffer", CLERK_BUFFER);
    }

    
}

