pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "./spell.sol";

interface IAuth {
    function wards(address) external returns(uint);
}

interface INavFeed {
    function file(bytes32, uint256, uint256, uint256, uint256, uint256) external;
    function recoveryRatePD(uint) external returns (uint);
}

interface IHevm {
    function warp(uint256) external;
    function store(address, bytes32, bytes32) external;
}

contract BaseSpellTest is DSTest {

    IHevm public t_hevm;
    TinlakeSpell spell;

    INavFeed navFeed;
    INavFeed t_navFeed;
   
    address spell_;
    address t_root_;

    function initSpell() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);

        t_root_ = address(spell.ROOT());  
        t_hevm = IHevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        t_navFeed = INavFeed(spell.NAV_FEED());
        t_hevm.store(t_root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function castSpell() public {
        // give spell permissions on root contract
        AuthLike(t_root_).rely(spell_);
        spell.cast();
    }
}

contract SpellTest is BaseSpellTest {

    uint256 constant ONE = 10**27;

    function setUp() public {
        initSpell();
    }

    function testCast() public {
        // give spell permissions on root contract
        AuthLike(t_root_).rely(spell_);

        spell.cast();
            
        assertNewRiskGroups();
    }

    function testFailCastNoPermissions() public {
        // !!! don't give spell permissions on root contract
        spell.cast();
    }

    function testFailCastTwice() public {
        // give spell permissions on root contract
        AuthLike(t_root_).rely(spell_);
        spell.cast();
        spell.cast();
    }

    function assertNewRiskGroups() public {
        // check state
        for (uint i; i < 3; i++) {
            uint256 recoveryRatePDs = t_navFeed.recoveryRatePD(i + 3);
            assertEq(recoveryRatePDs, 99.9*10**25);
        }
    }
}
