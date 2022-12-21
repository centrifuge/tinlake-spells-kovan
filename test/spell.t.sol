pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "forge-std/Test.sol";
import "src/spell.sol";

interface PileLike {
    function rates(uint rate) external view returns (uint, uint, uint ,uint48, uint);
}

interface PoolAdminLike {
    function admin_level(address) external view returns (uint256);
}

contract SpellTest is Test {

    TinlakeSpell spell;
    RootLike root;
   
    address spell_;
    address root_;

    address public BT1_PILE = 0x62E6225d9DbFa9C5f09ccB43304F60a0a7dDeb7A;
    address public BT2_PILE = 0x611e36809ad4BB94ae6dE889fd4e830Fc21835f7;
    address public BT3_PILE = 0x6af9dA8dB1925F8ef359274A59eF01e1c6Df7bE0;
    address public BT4_PILE = 0xFE2cC8f110311D9aeB116292687697FD805D9FDB;

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

        assertHasPermissions(spell.BT1_FEED, spell.BT1_PROXY);
        assertHasPermissions(spell.BT2_FEED, spell.BT2_PROXY);
        assertHasPermissions(spell.BT3_FEED, spell.BT3_PROXY);
        assertHasPermissions(spell.BT4_FEED, spell.BT4_PROXY);

        assertEq(PoolAdminLike(spell.BT1_POOL_ADMIN).admin_level(spell.BT1_BORROWER), 1);
        assertEq(PoolAdminLike(spell.BT2_POOL_ADMIN).admin_level(spell.BT2_BORROWER), 1);
        assertEq(PoolAdminLike(spell.BT3_POOL_ADMIN).admin_level(spell.BT3_BORROWER), 1);
        assertEq(PoolAdminLike(spell.BT4_POOL_ADMIN).admin_level(spell.BT4_BORROWER), 1);

        checkRiskGroups(PileLike(BT1_PILE));
        checkRiskGroups(PileLike(BT2_PILE));
        checkRiskGroups(PileLike(BT3_PILE));
        checkRiskGroups(PileLike(BT4_PILE));

        assertHasNoPermissions(spell.BT1_FEED, address(spell));
        assertHasNoPermissions(spell.BT2_FEED, address(spell));
        assertHasNoPermissions(spell.BT3_FEED, address(spell));
        assertHasNoPermissions(spell.BT4_FEED, address(spell));

        assertHasNoPermissions(spell.BT1_ROOT, address(spell));
        assertHasNoPermissions(spell.BT2_ROOT, address(spell));
        assertHasNoPermissions(spell.BT3_ROOT, address(spell));
        assertHasNoPermissions(spell.BT4_ROOT, address(spell));

    }

    function checkRiskGroups(PileLike pile) internal {
        (,,uint ratePerSecond1,,) = pile.rates(0);
        assertEq(ratePerSecond1, uint(1000000001547125824454591578));
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

