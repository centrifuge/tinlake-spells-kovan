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

interface ERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint) external returns (bool);
    function approve(address, uint) external;
}

interface NavLike {
    function discountRate() external returns(uint);
    function approximatedNAV() external returns(uint);
    function currentNav() external returns(uint);
    function pile() external returns(address);
    function nftID(address, uint) external returns(bytes32);
    function futureValue(bytes32) external returns(uint);
    function nftValues(bytes32) external returns(uint);
    function risk(bytes32) external returns(uint);
    function maturityDate(bytes32) external returns(uint);
    function ceiling(uint) external returns(uint);
    function currentCeiling(uint) external returns(uint);
    function threshold(uint) external returns(uint);
    function borrowed(uint) external returns(uint);
}

interface ReserveLike {
    function payout(uint currencyAmount) external;
}


// spell for: ns2 migration to rev pool with maker support
// - swap contracts: nav, assessor, reserve, coordinator
// - add new contracts: clerk & mgr
// - remove old contracts for the pool
// - wire new contracts
// - set permissions on new contracts
// - migrate the contract state from old to new contracts
contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake NS2 migration kovan Spell";

    address constant public ROOT = 0x0000000000000000000000000000000000000000;
    address constant public PILE = 0x0000000000000000000000000000000000000000;
    address constant public SHELF = 0x0000000000000000000000000000000000000000;
    address constant public COLLECTOR = 0x0000000000000000000000000000000000000000;
    address constant public ORACLE = 0x0000000000000000000000000000000000000000;
    address constant public TINLAKE_CURRENCY = 0x0000000000000000000000000000000000000000;
    address constant public ASSESSOR  = 0x0000000000000000000000000000000000000000;

    address constant public NAV_OLD = 0x0000000000000000000000000000000000000000;
    address constant public NAV_NEW = 0x0000000000000000000000000000000000000000;
    
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
       root.relyContract(PILE, self);
       root.relyContract(COLLECTOR, self);
       root.relyContract(NAV_NEW, self);
       root.relyContract(ASSESSOR, self);
       
        // contract migration --> assumption: root contract is already ward on the new contracts
        migrateNav();
    }

    function migrateNav() internal {
        NavLike navOld = NAFLike(NAV_OLD);
        // migrate dependencies 
        DependLike(SHELF).depend("ceiling", NAV_NEW); // set new nav as ceiling contract on shelf
        DependLike(COLLECTOR).depend("threshold", NAV_NEW); // set new nav as threshold contract on collector
        DependLike(SHELF).depend("subscriber", NAV_NEW); 
        DependLike(NAV_NEW).depend("pile", PILE); // add pile as dependecy to new nav
        DependLike(NAV_NEW).depend("shelf", SHELF); // add shelf as dependecy to new nav
        DependLike(ASSESSOR_NEW).depend("navFeed", NAV_NEW);
        // migrate wards
        AuthLike(NAV_NEW).rely(ORACLE); // add oracle as ward to new nav
        AuthLike(NAV_NEW).rely(SHELF); // add shelf as ward on new nav
        AuthLike(PILE).deny(NAV_OLD); // remove old nav as ward on pile
        AuthLike(PILE).rely(NAV_NEW); // add new nav as ward on pile
        // migrate state
        FileLike(NAV_NEW).file("discountRate", navOld.discountRate());
        // set writeoff & riskgroups -> done in init on nav deployment -> check in rpc test of this spell
        // price nfts -> done in init on nav deployment -> check in rpc test of this spell
        // buckets, fv & borrowed amounts migrated correctly -> done in init on nav deployment -> check in rpc test of this spell
        // nav value old = nav value new -> check in rpc test of this spell 
    }
    
}

