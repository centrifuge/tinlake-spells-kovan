pragma solidity >=0.8.1;
pragma experimental ABIEncoderV2;

import "forge-std/Test.sol";
import "src/spell.sol";

interface ClerkLike {
    function creditline() external returns (uint);
    function raise(uint) external;
}

contract SpellTest is Test {

    TinlakeSpell spell;
    RootLike root;
   
    address BT4_CLERK = 0xe015FF153fa731f0399E65f08736ae71B6fD1a9F;

    function setUp() public {
        spell = new TinlakeSpell();

        vm.store(spell.BT1_ROOT(), keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
        vm.store(spell.BT2_ROOT(), keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
        vm.store(spell.BT3_ROOT(), keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
        vm.store(spell.BT4_ROOT(), keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function testFailCastTwice() public {
        grantPermissions();

        spell.cast();
        spell.cast();
    } 

    function testFailCastWithoutPermission() public {
        spell.cast();
    }

    function testCast() public {
        grantPermissions();

        spell.cast();

        assertEq(PoolAdminLike(spell.BT1_POOL_ADMIN()).lending(), spell.BT1_CLERK());
        assertEq(PoolAdminLike(spell.BT2_POOL_ADMIN()).lending(), spell.BT2_CLERK());
        assertEq(PoolAdminLike(spell.BT3_POOL_ADMIN()).lending(), spell.BT3_CLERK());
        assertEq(PoolAdminLike(spell.BT4_POOL_ADMIN()).lending(), spell.BT4_CLERK());

        assertEq(PoolAdminLike(spell.BT1_POOL_ADMIN()).admin_level(address(spell)), 0);
        assertEq(PoolAdminLike(spell.BT2_POOL_ADMIN()).admin_level(address(spell)), 0);
        assertEq(PoolAdminLike(spell.BT3_POOL_ADMIN()).admin_level(address(spell)), 0);
        assertEq(PoolAdminLike(spell.BT4_POOL_ADMIN()).admin_level(address(spell)), 0);
    }

    function testRaisingCreditline() public {
        grantPermissions();

        spell.cast();

        uint256 raiseAmount = 1 ether;
        raiseCreditLine(spell.BT4_CLERK(), raiseAmount);
    }

    function grantPermissions() public {
        RootLike(spell.BT1_ROOT()).rely(address(spell));
        RootLike(spell.BT2_ROOT()).rely(address(spell));
        RootLike(spell.BT3_ROOT()).rely(address(spell));
        RootLike(spell.BT4_ROOT()).rely(address(spell));
    }

    function raiseCreditLine(address clerk, uint256 raiseAmount) public {
        ClerkLike clerk = ClerkLike(BT4_CLERK);
        uint256 preCreditline = clerk.creditline();
        RootLike(spell.BT4_ROOT()).relyContract(address(clerk), address(this));
        clerk.raise(raiseAmount);
        assertEq(clerk.creditline(), preCreditline + raiseAmount);
    }
}

