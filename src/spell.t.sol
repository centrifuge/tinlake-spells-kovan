pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
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

interface IHevm {
    function warp(uint256) external;
    function store(address, bytes32, bytes32) external;
}

contract BaseSpellTest is DSTest {

    IHevm public t_hevm;
    TinlakeSpell spell;

    IShelf t_shelf;
    ICollector t_collector;
    IAssessor t_assessor;
    IReserve t_reserve;
    ICoordinator t_coordinator;
    ITranche t_seniorTranche;
    ITranche t_juniorTranche;
    IClerk t_clerk;
    SpellERC20Like t_currency;
   
    address spell_;
    address t_root_;
    address t_shelf_;
    address t_reserve_;
    address t_reserveOld_;
    address t_assessor_;
    address t_clerk_;
    address t_coordinator_;
    address t_juniorTranche_;
    address t_seniorTranche_;
    address t_currency_;
    address t_pot_;

    uint poolReserveDAI;

    function initSpell() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);

        t_root_ = address(spell.ROOT_CONTRACT());  
        t_hevm = IHevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        t_collector = ICollector(spell.COLLECTOR());
        t_shelf = IShelf(spell.SHELF());
        t_assessor = IAssessor(spell.ASSESSOR());
        t_reserve = IReserve(spell.RESERVE_NEW());
        t_coordinator = ICoordinator(spell.COORDINATOR());
        t_seniorTranche = ITranche(spell.SENIOR_TRANCHE());
        t_juniorTranche = ITranche(spell.JUNIOR_TRANCHE());
        t_clerk = IClerk(spell.CLERK());
        t_currency = SpellERC20Like(spell.TINLAKE_CURRENCY());
        t_reserveOld_ = spell.RESERVE();

        t_shelf_ = address(t_shelf);
        t_assessor_ = address(t_assessor);
        t_reserve_ = address(t_reserve);
        t_pot_ = address(t_reserve);
        t_coordinator_ = address(t_coordinator);
        t_seniorTranche_ = address(t_seniorTranche);
        t_juniorTranche_ = address(t_juniorTranche);
        t_clerk_ = address(t_clerk);
        t_currency_ = address(t_currency);

        poolReserveDAI = t_currency.balanceOf(t_reserveOld_);
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

    IAssessor assessor;
    ICoordinator coordinator;
    ITranche seniorTranche;
    ITranche juniorTranche;
   
    address root_;
    address reserve_;
    address assessor_;
    address coordinator_;
    address coordinatorOld_;
    address juniorTranche_;
    address seniorTranche_;

    function setUp() public {
        initSpell();

        spell = new TinlakeSpell();
        spell_ = address(spell);

        root_ = address(spell.ROOT());  

        assessor = IAssessor(spell.ASSESSOR());
        coordinator = ICoordinator(spell.COORDINATOR_NEW());
        seniorTranche = ITranche(spell.SENIOR_TRANCHE());
        juniorTranche = ITranche(spell.JUNIOR_TRANCHE());
       
        assessor_ = address(assessor);
        reserve_ = spell.RESERVE();
        coordinator_ = address(coordinator);
        coordinatorOld_ = spell.COORDINATOR_OLD();
        seniorTranche_ = address(seniorTranche);
        juniorTranche_ = address(juniorTranche);
    }

    function testCast() public {
        // give spell permissions on root contract
        AuthLike(root_).rely(spell_);

        assertEq(NAVFeedLike(spell.FEED()).discountRate(), 1000000002378234398782343987);

        spell.cast();
            
        assertMigrationCoordinator();
        assertDiscountChange();
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

    function assertMigrationCoordinator() public {
        ICoordinator coordinatorOld = ICoordinator(spell.COORDINATOR_OLD());
    
        // check dependencies
        assertEq(coordinator.assessor(), assessor_);
        assertEq(coordinator.juniorTranche(), juniorTranche_);
        assertEq(coordinator.seniorTranche(), seniorTranche_);
        assertEq(coordinator.reserve(), reserve_);
        assertEq(juniorTranche.epochTicker(),coordinator_);

        // check permissions
        assertHasPermissions(juniorTranche_, coordinator_);
        assertHasPermissions(assessor_, coordinator_);
        assertHasPermissions(seniorTranche_, coordinator_);
        assertHasNoPermissions(assessor_, coordinatorOld_);
        assertHasNoPermissions(juniorTranche_, coordinatorOld_);
        assertHasNoPermissions(seniorTranche_, coordinatorOld_);

        // check state
        assertEq(coordinator.lastEpochClosed(), coordinatorOld.lastEpochClosed());
        assertEq(coordinator.minimumEpochTime(), coordinatorOld.minimumEpochTime());
        assertEq(coordinator.lastEpochExecuted(), coordinatorOld.lastEpochExecuted());
        assertEq(coordinator.currentEpoch(), coordinatorOld.currentEpoch());
        assertEq(coordinator.bestSubScore(), coordinatorOld.bestSubScore());
        assert(coordinator.gotFullValidSolution() == coordinatorOld.gotFullValidSolution());

        // calculate opoch values correctly
        uint epochSeniorAsset = safeAdd(assessor.seniorDebt_(), assessor.seniorBalance_());
        uint epochNAV = INav(assessor.navFeed()).currentNAV();
        uint epochReserve = assessor.totalBalance();
        // calculate current token prices which are used for the execute
        uint epochSeniorTokenPrice = assessor.calcSeniorTokenPrice(epochNAV, epochReserve);
        uint epochJuniorTokenPrice = assessor.calcJuniorTokenPrice(epochNAV, epochReserve);

        assertEq(coordinator.epochSeniorTokenPrice(), epochSeniorTokenPrice);
        assertEq(coordinator.epochJuniorTokenPrice(), epochJuniorTokenPrice);
        assertEq(coordinator.epochNAV(), epochNAV);
        assertEq(coordinator.epochSeniorAsset(), epochSeniorAsset);
        assertEq(coordinator.epochReserve(), epochReserve);

        assert(coordinator.submissionPeriod() == coordinatorOld.submissionPeriod());
        assertEq(coordinator.weightSeniorRedeem(), coordinatorOld.weightSeniorRedeem());
        assertEq(coordinator.weightJuniorRedeem(), coordinatorOld.weightJuniorRedeem());
        assertEq(coordinator.weightJuniorSupply(), coordinatorOld.weightJuniorSupply());
        assertEq(coordinator.weightSeniorSupply(), coordinatorOld.weightSeniorSupply());
        assertEq(coordinator.minChallengePeriodEnd (), block.timestamp + coordinator.challengeTime());
        assertEq(coordinator.challengeTime(), 1800);
        assertEq(coordinator.bestRatioImprovement(), coordinatorOld.bestRatioImprovement());
        assertEq(coordinator.bestReserveImprovement(), coordinatorOld.bestReserveImprovement());
        assert(coordinator.poolClosing() == false);
        assertOrderMigration(); 
    }

    function assertOrderMigration() public {
        (uint seniorRedeemSubmission, uint juniorRedeemSubmission, uint juniorSupplySubmission, uint seniorSupplySubmission) = coordinator.bestSubmission();
        (uint seniorRedeemSubmissionOld, uint juniorRedeemSubmissionOld, uint juniorSupplySubmissionOld, uint seniorSupplySubmissionOld) = ICoordinator(spell.COORDINATOR_OLD()).bestSubmission();
        assertEq(seniorRedeemSubmission, seniorRedeemSubmissionOld);
        assertEq(juniorRedeemSubmission, juniorRedeemSubmissionOld);
        assertEq(juniorSupplySubmission, juniorSupplySubmissionOld);
        assertEq(seniorSupplySubmission, seniorSupplySubmissionOld);

        (uint seniorRedeemOrder, uint juniorRedeemOrder, uint juniorSupplyOrder, uint seniorSupplyOrder) = coordinator.order();
        (uint seniorRedeemOrderOld, uint juniorRedeemOrderOld, uint juniorSupplyOrderOld, uint seniorSupplyOrderOld) = ICoordinator(spell.COORDINATOR_OLD()).order();
        assertEq(seniorRedeemOrder, seniorRedeemOrderOld);
        assertEq(juniorRedeemOrder, juniorRedeemOrderOld);
        assertEq(juniorSupplyOrder, juniorSupplyOrderOld);
        assertEq(seniorSupplyOrder, seniorSupplyOrderOld);
    }

    function assertDiscountChange() public {
        assertEq(NAVFeedLike(spell.FEED()).discountRate(), 1000000002243467782851344495);

        hevm.warp(block.timestamp + 4 days);
        spell.setDiscount(1);
        assertEq(NAVFeedLike(spell.FEED()).discountRate(), 1000000002108701166920345002);

        hevm.warp(block.timestamp + 4 days);
        spell.setDiscount(2);
        assertEq(NAVFeedLike(spell.FEED()).discountRate(), 1000000001973934550989345509);

        hevm.warp(block.timestamp + 4 days);
        spell.setDiscount(3);
        assertEq(NAVFeedLike(spell.FEED()).discountRate(), 1000000001839167935058346017);
    }
}
