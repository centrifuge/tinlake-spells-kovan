pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "tinlake-math/math.sol";
import "./spell.sol";

interface IAuth {
    function wards(address) external returns(uint);
}

interface IReserve {
    function assessor() external returns(address);
    function currency() external returns(address);
    function shelf() external returns(address);
    function pot() external returns(address);
    function lending() external returns(address);
    function currencyAvailable() external returns(uint);
    function balance_() external returns(uint);
}

interface IAssessor {
    function reserve() external returns(address); 
}

interface ITranche {
    function reserve() external returns(address);
}

interface ICoordinator  {
    function reserve() external returns(address);
}

interface IClerk {
    function reserve() external returns(address); 
}

interface IShelf {
    function distributor() external returns(address);
    function lender() external returns(address);
}

interface ICollector {
    function distributor() external returns(address);
}

contract Hevm {
    function warp(uint256) public;
    function store(address, bytes32, bytes32) public;
}

contract TinlakeSpellsTest is DSTest, Math {

    Hevm public hevm;
    TinlakeSpell spell;

    IShelf shelf;
    ICollector collector;
    IAssessor assessor;
    IReserve reserve;
    ICoordinator coordinator;
    ITranche seniorTranche;
    ITranche juniorTranche;
    IClerk clerk;
    SpellERC20Like currency;
   
    address spell_;
    address root_;
    address shelf_;
    address reserve_;
    address reserveOld_;
    address assessor_;
    address clerk_;
    address coordinator_;
    address juniorTranche_;
    address seniorTranche_;
    address currency_;
    address pot_;

    uint poolReserveDAI;

    function setUp() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);

        root_ = address(spell.ROOT());  
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        collector = ICollector(spell.COLLECTOR());
        shelf = IShelf(spell.SHELF());
        assessor = IAssessor(spell.ASSESSOR());
        reserve = IReserve(spell.RESERVE_NEW());
        coordinator = ICoordinator(spell.COORDINATOR());
        seniorTranche = ITranche(spell.SENIOR_TRANCHE());
        juniorTranche = ITranche(spell.JUNIOR_TRANCHE());
        clerk = IClerk(spell.CLERK());
        currency = SpellERC20Like(spell.TINLAKE_CURRENCY());
        reserveOld_ = spell.RESERVE();

        shelf_ = address(shelf);
        assessor_ = address(assessor);
        operator_ = address(operator);
        poolAdmin_ = address(poolAdmin);
        reserve_ = address(reserve);
        pot_ = address(reserve);
        coordinator_ = address(coordinator);
        seniorTranche_ = address(seniorTranche);
        juniorTranche_ = address(juniorTranche);
        clerk_ = address(clerk);
        currency_ = address(currency);

        poolReserveDAI = currency.balanceOf(spell.RESERVE_OLD());
        // cheat: give testContract permissions on root contract by overriding storage 
        // storage slot for permissions => keccak256(key, mapslot) (mapslot = 0)
        hevm.store(root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function testCast() public {
        // give spell permissions on root contract
        AuthLike(root_).rely(spell_);
        spell.cast();
            
        assertMigrationReserve();
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

    function assertMigrationReserve() public {
        IReserve reserveOld =IReserve(spell.RESERVE_OLD());
         // check dependencies 
        assertEq(reserve.assessor(), assessor_);
        assertEq(reserve.currency(), currency_);
        assertEq(reserve.shelf(), shelf_);
        assertEq(reserve.lending(), clerk_);
        // assertEq(reserve.pot(), reserve_); -> has to be public
        assertEq(juniorTranche.reserve(), reserve_);
        assertEq(seniorTranche.reserve(), reserve_);
        assertEq(shelf.distributor(), reserve_);
        assertEq(shelf.lender(), reserve_);
        assertEq(clerk.reserve(), reserve_);
        assertEq(assessor.reserve(), reserve_);
        assertEq(coordinator.reserve(), reserve_);
        // assertEq(collector.distributor(), reserve_); -> has to be public

        // check permissions
        assertHasPermissions(reserve_, clerk_);
        assertHasPermissions(clerk_, reserve_);
        assertHasPermissions(assessor_, reserve_);
        assertHasPermissions(reserve_, juniorTranche_);
        assertHasPermissions(reserve_, seniorTranche_);

        assertHasNoPermissions(clerk_, reserveOld_);
        assertHasNoPermissions(assessor_, reserveOld_);

        // check state
        assertEq(reserve.currencyAvailable(), reserveOld.currencyAvailable());   
        assertEq(reserve.balance_(), safeAdd(reserveOld.balance_(), poolReserveDAI));
        assertEq(currency.balanceOf(reserve_), poolReserveDAI);
    }
}
