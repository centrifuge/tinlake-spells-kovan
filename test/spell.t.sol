pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "forge-std/Test.sol";
import "src/spell.sol";

contract SpellTest is Test {

    TinlakeSpell spell;
    RootLike root;
   
    address spell_;
    address root_;

    uint256 constant ONE = 10**27;

    function setUp() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);
        root_ = address(spell.ROOT());  

        root = RootLike(root_);

        vm.store(root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function testFailCastTwice() public {
        AuthLike(root_).rely(spell_);
        spell.cast();
        spell.cast();
    } 

    function testFailCastWithoutPermission() public {
        spell.cast();
    }

    function testCast() public {
        AuthLike(root_).rely(spell_);
        spell.cast();
        // make assertins here
    }
}

