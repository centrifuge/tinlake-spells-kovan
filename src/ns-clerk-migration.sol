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

interface SpellClerkLike {
    function changeOwnerMgr(address) external;
}

// spell to swap clerk contract in the ns2 koan deployment
contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake NS2 migration kovan Spell";

    address constant public ROOT = 0x25dF507570c8285E9c8E7FFabC87db7836850dCd;

    address constant public SENIOR_TOKEN = 0x352Fee834a14800739DC72B219572d18618D9846;
    address constant public SENIOR_TRANCHE = 0xDF0c780Ae58cD067ce10E0D7cdB49e92EEe716d9;
    address constant public SENIOR_MEMBERLIST = 0xD927F069faf59eD83A1072624Eeb794235bBA652;
    address constant public COORDINATOR = 0xB51D3cbaa5CCeEf896B96091E69be48bCbDE8367;
    address constant public ASSESSOR  = 0x49527a20904aF41d1cbFc0ba77576B9FBd8ec9E5;
    address constant public RESERVE = 0xc264eCc07728d43cdA564154c2638D3da110D4DD;
    address constant public TINLAKE_CURRENCY = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa; // DAI


    // adapter contracts -> to be integrated
    address constant public CLERK_OLD  = 0xE3F80411CD0Dd02Def6AF3041DA4c6f9b87BA1D8;
    address constant public CLERK_NEW  = 0xe9363F8752b7D743426EB6D93F726B528B0a4225;

    address constant public MGR = 0x65242F75e6cCBF973b15d483dD5F555d13955A1e;
    // mkr kovan contracts from release 1.2.2 https://changelog.makerdao.com/releases/kovan/1.2.2/contracts.json
    address constant public SPOTTER = 0x3a042de6413eDB15F2784f2f97cC68C7E9750b2D;
    address constant public VAT = 0xbA987bDB501d131f766fEe8180Da5d81b34b69d9;


    uint constant public CLERK_BUFFER = 0.01 * 10**27;
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

        root.relyContract(SENIOR_TRANCHE, self);
        root.relyContract(SENIOR_MEMBERLIST, self);
        root.relyContract(CLERK_OLD, self);
        root.relyContract(CLERK_NEW, self);
        root.relyContract(ASSESSOR, self);
        root.relyContract(COORDINATOR, self);
        root.relyContract(RESERVE, self);
    
        // contract migration --> assumption: root contract is already ward on the new contracts
        migrateClerk();
    }


    function migrateClerk() internal {
        // dependencies
        DependLike(CLERK_NEW).depend("assessor", ASSESSOR);
        DependLike(CLERK_NEW).depend("mgr", MGR);
        DependLike(CLERK_NEW).depend("coordinator", COORDINATOR);
        DependLike(CLERK_NEW).depend("reserve", RESERVE); 
        DependLike(CLERK_NEW).depend("tranche", SENIOR_TRANCHE);
        DependLike(CLERK_NEW).depend("collateral", SENIOR_TOKEN);
        DependLike(CLERK_NEW).depend("spotter", SPOTTER);
        DependLike(CLERK_NEW).depend("vat",VAT);

        DependLike(ASSESSOR).depend("clerk", CLERK_NEW); 
        DependLike(RESERVE).depend("lending", CLERK_NEW);

        // permissions
        AuthLike(CLERK_NEW).rely(COORDINATOR);
        AuthLike(CLERK_NEW).rely(RESERVE);
        // rely new clerk
        AuthLike(SENIOR_TRANCHE).rely(CLERK_NEW);
        AuthLike(RESERVE).rely(CLERK_NEW);
        AuthLike(ASSESSOR).rely(CLERK_NEW);
        // deny old clerk
        AuthLike(SENIOR_TRANCHE).deny(CLERK_OLD);
        AuthLike(RESERVE).deny(CLERK_OLD);
        AuthLike(ASSESSOR).deny(CLERK_OLD);

        // currency
        SpellMemberlistLike(SENIOR_MEMBERLIST).updateMember(CLERK_NEW, uint(-1));
        
        // state
        FileLike(CLERK_NEW).file("buffer", CLERK_BUFFER);
        // swap mgr ownership
        SpellClerkLike(CLERK_OLD).changeOwnerMgr(CLERK_NEW);
    }
}