pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "./spell.sol";

interface IAuth {
    function wards(address) external returns(uint);
}

// interface IReserve {
//     function assessor() external returns(address);
//     function currency() external returns(address);
//     function shelf() external returns(address);
//     function pot() external returns(address);
//     function lending() external returns(address);
//     function currencyAvailable() external returns(uint);
//     function balance_() external returns(uint);
// }

// interface IAssessor {
//     function reserve() external returns(address); 
// }

// interface ITranche {
//     function reserve() external returns(address);
// }

// interface ICoordinator  {
//     function reserve() external returns(address);
// }

// interface IClerk {
//     function reserve() external returns(address); 
// }

// interface IShelf {
//     function distributor() external returns(address);
//     function lender() external returns(address);
// }

// interface ICollector {
//     function distributor() external returns(address);
// }

interface INavFeed {
    function file(bytes32 name, uint256 risk_, uint256 thresholdRatio_, uint256 ceilingRatio_, uint256 rate_, uint256 recoveryRatePD_) external;
    function riskGroup(uint id) external returns (uint, uint, uint);
}

interface IHevm {
    function warp(uint256) external;
    function store(address, bytes32, bytes32) external;
}

contract BaseSpellTest is DSTest {

    IHevm public t_hevm;
    TinlakeSpell spell;

    INavFeed navFeed;
    // IShelf t_shelf;
    // ICollector t_collector;
    // IAssessor t_assessor;
    // IReserve t_reserve;
    // ICoordinator t_coordinator;
    // ITranche t_seniorTranche;
    // ITranche t_juniorTranche;
    // IClerk t_clerk;
    // SpellERC20Like t_currency;
    INavFeed t_navFeed;
   
    address spell_;
    address t_root_;
    address t_navFeed_;
    // address t_shelf_;
    // address t_reserve_;
    // address t_reserveOld_;
    // address t_assessor_;
    // address t_clerk_;
    // address t_coordinator_;
    // address t_juniorTranche_;
    // address t_seniorTranche_;
    // address t_currency_;
    // address t_pot_;

    // uint poolReserveDAI;

    function initSpell() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);

        t_root_ = address(spell.ROOT());  
        t_hevm = IHevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        t_navFeed = INavFeed(spell.NAV_FEED());
        t_navFeed_ = address(spell.NAV_FEED());
        // t_collector = ICollector(spell.COLLECTOR());
        // t_shelf = IShelf(spell.SHELF());
        // t_assessor = IAssessor(spell.ASSESSOR());
        // t_reserve = IReserve(spell.RESERVE_NEW());
        // t_coordinator = ICoordinator(spell.COORDINATOR());
        // t_seniorTranche = ITranche(spell.SENIOR_TRANCHE());
        // t_juniorTranche = ITranche(spell.JUNIOR_TRANCHE());
        // t_clerk = IClerk(spell.CLERK());
        // t_currency = SpellERC20Like(spell.TINLAKE_CURRENCY());
        // t_reserveOld_ = spell.RESERVE();

        // t_shelf_ = address(t_shelf);
        // t_assessor_ = address(t_assessor);
        // t_reserve_ = address(t_reserve);
        // t_pot_ = address(t_reserve);
        // t_coordinator_ = address(t_coordinator);
        // t_seniorTranche_ = address(t_seniorTranche);
        // t_juniorTranche_ = address(t_juniorTranche);
        // t_clerk_ = address(t_clerk);
        // t_currency_ = address(t_currency);

        // poolReserveDAI = t_currency.balanceOf(t_reserveOld_);
        // cheat: give testContract permissions on root contract by overriding storage 
        // storage slot for permissions => keccak256(key, mapslot) (mapslot = 0)
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

    function assertHasPermissions(address con, address ward) public {
        uint perm = IAuth(con).wards(ward);
        assertEq(perm, 1);
    }

    function assertHasNoPermissions(address con, address ward) public {
        uint perm = IAuth(con).wards(ward);
        assertEq(perm, 0);
    }

    function assertNewRiskGroups() public {
        // IReserve t_reserveOld = IReserve(t_reserveOld_);
        //  // check dependencies 
        // assertEq(t_reserve.assessor(), t_assessor_);
        // assertEq(t_reserve.currency(), t_currency_);
        // assertEq(t_reserve.shelf(), t_shelf_);
        // assertEq(t_reserve.lending(), t_clerk_);
        // // assertEq(reserve.pot(), reserve_); -> has to be public
        // assertEq(t_juniorTranche.reserve(), t_reserve_);
        // assertEq(t_seniorTranche.reserve(), t_reserve_);
        // assertEq(t_shelf.distributor(), t_reserve_);
        // assertEq(t_shelf.lender(), t_reserve_);
        // assertEq(t_clerk.reserve(), t_reserve_);
        // assertEq(t_assessor.reserve(), t_reserve_);
        // assertEq(t_coordinator.reserve(), t_reserve_);
        // // assertEq(collector.distributor(), reserve_); -> has to be public

        // // check permissions
        // assertHasPermissions(t_reserve_, t_clerk_);
        // assertHasPermissions(t_clerk_, t_reserve_);
        // assertHasPermissions(t_assessor_, t_reserve_);
        // assertHasPermissions(t_reserve_, t_juniorTranche_);
        // assertHasPermissions(t_reserve_, t_seniorTranche_);

        // assertHasNoPermissions(t_clerk_, t_reserveOld_);
        // assertHasNoPermissions(t_assessor_, t_reserveOld_);

        // check state
        (uint256 ceilingRatio, uint256 thresholdRatios, uint256 recoveryRatePDs) = t_navFeed.riskGroup(3);
        assertEq(ceilingRatio, ONE);
        assertEq(thresholdRatios, ONE);
        assertEq(recoveryRatePDs, 99.9*10**25);
        // assertEq(t_reserve.currencyAvailable(), t_reserveOld.currencyAvailable());   
        // assertEq(t_reserve.balance_(), (t_reserveOld.balance_() + poolReserveDAI));
        // assertEq(t_currency.balanceOf(t_reserve_), poolReserveDAI);
    }
}
