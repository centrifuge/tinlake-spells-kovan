pragma solidity >=0.5.15 <0.6.0;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "tinlake-math/math.sol";
import "./pezesha-funds-migration.sol";

interface IAuth {
    function wards(address) external returns(uint);
}

interface IPoolAdminLike {
    function admins(address) external returns(uint);
    function assessor() external returns(address);
    function lending() external returns(address);
    function juniorMemberlist() external returns(address);
    function seniorMemberlist() external returns(address);
}

contract Hevm {
    function warp(uint256) public;
    function store(address, bytes32, bytes32) public;
}

contract TinlakeSpellsTest is DSTest, Math {

    Hevm public hevm;
    TinlakeSpell spell;

    IPoolAdminLike poolAdmin;
    
    address spell_;
    address root_;
    address assessor_;
    address poolAdmin_;
    address seniorMemberList_;
    address juniorMemberList_;

    address admin1;
    address admin2;
    address admin3;
    address admin4;
    address admin5;
    address admin6;
    address admin7;

    function setUp() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);

        root_ = address(spell.ROOT());  
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        poolAdmin = IPoolAdminLike(spell.POOL_ADMIN());
       

        seniorMemberList_ = spell.SENIOR_MEMBERLIST();
        juniorMemberList_ = spell.JUNIOR_MEMBERLIST();
        assessor_ = spell.ASSESSOR();
        poolAdmin_ = address(poolAdmin);

        admin1 = spell.ADMIN1();
        admin2 = spell.ADMIN2();
        admin3 = spell.ADMIN3();
        admin4 = spell.ADMIN4();
        admin5 = spell.ADMIN5();
        admin6 = spell.ADMIN6();
        admin7 = spell.ADMIN7();
    
      
        // cheat: give testContract permissions on root contract by overriding storage 
        // storage slot for permissions => keccak256(key, mapslot) (mapslot = 0)
        hevm.store(root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function testCast() public {
        // give spell permissions on root contract
        AuthLike(root_).rely(spell_);
        spell.cast();
    
        // assertMigrationReserve();
        assertPoolAdminSet();
    }

    function testFailCastNoPermissions() public {
        // !!! don't give spell permissions on root contract
        spell.cast();
    }

    function testFailCastTwice() public {
        // give spell permissions on root contract
        AuthLike(root_).rely(spell_);
        spell.cast();
        spell.cast();
    }

    function assertHasPermissions(address con, address ward) public {
        uint perm = IAuth(con).wards(ward);
        assertEq(perm, 1);
    }

    function assertHasNoPermissions(address con, address ward) public {
        uint perm = IAuth(con).wards(ward);
        assertEq(perm, 0);
    }

    function assertPoolAdminSet() public {
        // setup dependencies 
        assertEq(poolAdmin.assessor(), assessor_);
        assertEq(poolAdmin.seniorMemberlist(), seniorMemberList_);
        assertEq(poolAdmin.juniorMemberlist(), juniorMemberList_);

        assertHasPermissions(assessor_, poolAdmin_);
        assertHasPermissions(seniorMemberList_, poolAdmin_);
        assertHasPermissions(juniorMemberList_, poolAdmin_);

        assertEq(poolAdmin.admins(admin1), 1);
        assertEq(poolAdmin.admins(admin2), 1);
        assertEq(poolAdmin.admins(admin3), 1);
        assertEq(poolAdmin.admins(admin4), 1);
        assertEq(poolAdmin.admins(admin5), 1);
        assertEq(poolAdmin.admins(admin6), 1);
        assertEq(poolAdmin.admins(admin7), 1);
    }
}
