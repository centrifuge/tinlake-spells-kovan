pragma solidity >=0.5.15 <0.6.0;

import "ds-test/test.sol";
import "./../src/spell.sol";


interface TinlakeAuthLike {
    function wards(address) external returns(uint);
    function rely(address) external;
}

contract Hevm {
    function warp(uint256) public;
    function store(address, bytes32, bytes32) public;
}

contract TinlakeSpellsTest is DSTest {

    Hevm public hevm;
    TinlakeSpell spell;
    
   
    address root_;
    address spell_;

    function setUp() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);
        root_ = address(spell.ROOT());  
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        
        // cheat: give testContract permissions on root contract by overriding storage 
        // storage slot for permissions => keccak256(key, mapslot) (mapslot = 0)
        hevm.store(root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function testCast() public {
        // tinlake contracts 
        address seniorMemberList_ = spell.SENIOR_MEMBERLIST();

        // addresses for permissions setup
        address seniorMemberListAdmin_ = spell.SENIOR_MEMBERLIST_ADMIN();
        
        // make sure permissions are not set yet
        assertHasNoPermissions(seniorMemberList_, seniorMemberListAdmin_);
        
        // give spell permissions on root contract
        AuthLike(root_).rely(spell_);

        spell.cast();

        // make sure permissions were set
        assertHasPermissions(seniorMemberList_, seniorMemberListAdmin_);

    }

    function testFailCastNoPermissions() public {
        address seniorMemberList_ = spell.SENIOR_MEMBERLIST();

        // addresses for permissions setup
        address seniorMemberListAdmin_ = spell.SENIOR_MEMBERLIST_ADMIN();
        
        // make sure permissions are not set yet
        assertHasNoPermissions(seniorMemberList_, seniorMemberListAdmin_);
        
        // !!! don't give spell permissions on root contract

        spell.cast();
    }

    function assertHasPermissions(address con, address ward) public {
        uint perm = TinlakeAuthLike(con).wards(ward);
        assertEq(perm, 1);
    }

    function assertHasNoPermissions(address con, address ward) public {
        uint perm = TinlakeAuthLike(con).wards(ward);
        assertEq(perm, 0);
    }

    function toBytes(uint256 x) public returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }
    
}
