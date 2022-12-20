pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "./spell.sol";

interface IHevm {
    function warp(uint256) external;
    function store(address,bytes32,bytes32) external;
}

interface IRoot {
    function relyContract(address, address) external;
}

interface IRestrictedToken {
    function hasMember(address member) external returns(bool);
}

interface IFeedLike {
    function riskGroup(uint) external returns (uint128 ceilingRatio , uint128 thresholdRatio , uint128 recoveryRatePD);
}

interface IAuth {
    function wards(address) external returns(uint);
}

contract BaseSpellTest is DSTest {

    IHevm public hevm;
    TinlakeSpell spell;
    IRoot root;

    function setUp() public {
        spell = new TinlakeSpell();
        
        root = IRoot(spell.BT4_ROOT());
        hevm = IHevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        hevm.store(spell.BT4_ROOT(), keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function testFailCastTwice() public {
        AuthLike(spell.BT4_ROOT()).rely(address(spell));
        spell.cast();
        spell.cast();
    } 

    function testCast() public {
        AuthLike(spell.BT4_ROOT()).rely(address(spell));
        spell.cast();
        (uint256 ceil, uint256 thresh, uint256 rate) = IFeedLike(spell.BT1_FEED()).riskGroup(0);
        assertEq(ceil, 1000000031709791983764586504);
        assertEq(thresh, 1000000000000000000000000000);
        assertEq(rate, 0);
        assertHasPermissions(spell.BT1_FEED(), spell.BT1_PROXY());
        assertHasPermissions(spell.BT2_FEED(), spell.BT2_PROXY());
        assertHasPermissions(spell.BT3_FEED(), spell.BT3_PROXY());
        assertHasPermissions(spell.BT4_FEED(), spell.BT4_PROXY());
        assertHasNoPermissions(spell.BT1_FEED(), address(spell));
        assertHasNoPermissions(spell.BT2_FEED(), address(spell));
        assertHasNoPermissions(spell.BT3_FEED(), address(spell));
        assertHasNoPermissions(spell.BT4_FEED(), address(spell));
        assertHasNoPermissions(spell.BT1_ROOT(), address(spell));
        assertHasNoPermissions(spell.BT2_ROOT(), address(spell));
        assertHasNoPermissions(spell.BT3_ROOT(), address(spell));
        assertHasNoPermissions(spell.BT4_ROOT(), address(spell));
    }

    function assertHasPermissions(address con, address ward) public {
        uint perm = IAuth(con).wards(ward);
        assertEq(perm, 1);
    }

    function assertHasNoPermissions(address con, address ward) public {
        uint perm = IAuth(con).wards(ward);
        assertEq(perm, 0);
    }

}

