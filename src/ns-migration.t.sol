pragma solidity >=0.5.15 <0.6.0;

import "ds-test/test.sol";
import "./../src/ns-migration.sol";

interface AsessorLike {
    function wards(address) external returns(uint);
    function seniorTranche() external returns(address);
    function juniorTranche() external returns(address);
    function navFeed() external returns(address);
    function reserve() external returns(address); 
    function lending() external returns(address);
    function seniorRatio() external returns(uint);
    function seniorDebt_() external returns(uint);
    function seniorBalance_() external returns(uint);
    function seniorInterestRate() external returns(uint);
    function lastUpdateSeniorInterest() returns(uint);
    function maxSeniorRatio() external returns(uint);
    function minSeniorRatio() external returns(uint);
    function maxReserve() external returns(uint);
}

interface AsessorWrapperLike {
    function assessor() external returns(address);
}

interface ReserveLike {
    function wards(address) external returns(uint);
    function assessor() external returns(address);
    function currency() external returns(address);
    function shelf() external returns(address);
    function lending() external returns(address);
    function pot() external returns(address);
    function lending() external returns(address);
    function currencyAvailable() external returns(address);
    function balance_() external returns(address);
}

interface CoordinatorLike  {
    function wards(address) external returns(uint);
}

interface ClerkLike {
    function wards(address) external returns(uint);
}

interface ShelfLike {
    function distributor()  external returns(address);
}

interface CollectorLike {
    function distributor()  external returns(address);
}

contract Hevm {
    function warp(uint256) public;
    function store(address, bytes32, bytes32) public;
}

contract TinlakeSpellsTest is DSTest {

    Hevm public hevm;
    TinlakeSpell spell;

    ShelfLike shelf;
    CollectorLike collector;
    AssessorLike assessor;
    AssessorWrapperLike assessorWrapper;
    ReserveLike reserve;
    CoordinatorLike coordinator;
    ClerkLike clerk;
    ERC20Like currency;
   
    address root_;
    address spell_;
    address reserve_;
    address assessor_;
    address assessorWrapper_;
    address clerk_;
    address coordinator_;
    address juniorTranche_;
    address seniorTranche_;
    address currency_;
    address pot_;

    uint poolReserve;

    function setUp() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);
        root_ = address(spell.ROOT());  
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        collector = CollectorLike(spell.COLLECTOR);
        shelf = ShelfLike(spell.SHELF);
        assessor = AssessorLike(spell.ASSESSOR_NEW);
        assessor_ = address(assessor);
        assessorWrapper = AssessorWrapperLike(spell.ASSESSOR_WRAPPER);
        assessorWrapper_ = address(assessorWrapper);
        reserve = ReserveLike(spell.RESERVE_NEW);
        reserve_ = address(reserve);
        coordinator = CoordinatorLike(spell.COORDINATOR_NEW);
        coordinator_ = address(coordinator);
        clerk = ClerkLike(spell.CLERK);
        clerk_ = address(clerk);
        currency = ERC20Like(spell.TINLAKE_CURRENCY);
        currency_ = address(currency);
        juniorTranche_ = spell.JUNIOR_TRANCHE();
        seniorTranche_ = spell.SENIOR_TRANCHE();
        nav_ = spell.NAV();
        
        poolReserve = currency.balanceOf(spell.RESERVE_OLD);
        // cheat: give testContract permissions on root contract by overriding storage 
        // storage slot for permissions => keccak256(key, mapslot) (mapslot = 0)
        hevm.store(root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function testCast() public {
        assertMigrationAssessor();
        assertMigrationReserveAssessor();
        assertMigrationCoordinator();
        assertIntegrationAdapter();
    }
    function testFailCastNoPermissions() public {
        // !!! don't give spell permissions on root contract
        spell.cast();
    }

    function testFailCastTwice() public {
        spell.cast();
        spell.cast();
    }

    function assertHasPermissions(address con, address ward) public {
        uint perm = AuthLike(con).wards(ward);
        assertEq(perm, 1);
    }

    function assertHasNoPermissions(address con, address ward) public {
        uint perm = AuthLike(con).wards(ward);
        assertEq(perm, 0);
    }

    function assertMigrationAssessor() public {  
        // check dependencies
        assertEq(assessor.clerk(), clerk_);
        assertEq(assessor.seniorTranche(), seniorTranche_);
        assertEq(assessor.juniorTranche(), juniorTranche_);
        assertEq(assessor.reserve(), reserve_);
        assertEq(assessor.navFeed(), nav_);
        assertEq(assessorWrapper.assessor(), assessor_);

        // check permissions
        assertHasPermissions(assessor_, clerk_);
        assertHasPermissions(assessor_, coordinator_);
        assertHasPermissions(assessor_, assessorWrapper);
    
        // check state
        AssessorLike assessorOld = AssessorLike(spell.ASSESSOR_OLD);
        assertEq(assessor.seniorRatio(), assessorOld.seniorRatio());
        assertEq(assessor.seniorDebt_(), assessorOld.seniorDebt_());
        assertEq(assessor.seniorBalance_(), assessorOld.seniorBalance_());
        assertEq(assessor.seniorInterestRate(), Fixed27(assessorOld.seniorInterestRate()));
        assertEq(assessor.lastUpdateSeniorInterest(), assessorOld.lastUpdateSeniorInterest());
        assertEq(assessor.maxSeniorRatio(), assessorOld.lastUpdateSeniorInterest());
        assertEq(assessor.minSeniorRatio(), Fixed27(assessorOld.minSeniorRatio()));
        assertEq(assessor.maxReserve(), assessorOld.maxReserve());   
    }

    function assertMigrationReserve() public {
         // check dependencies 
        assertEq(reserve.assessor(), assessor_);
        assertEq(reserve.currency(), currency_);
        assertEq(reserve.shelf(), shelf_);
        assertEq(reserve.lending(), clerk_);
        assertEq(reserve.pot(), pot_);
        assertEq(shelf.distributor(), reserve_);
        assertEq(collector.distributor(), reserve_);

        // check permissions
        assertHasPermissions(reserve_, clerk_);
        assertHasPermissions(reserve_, juniorTranche_);
        assertHasPermissions(reserve_, seniorTranche_);

        // check state
        ReserveLike reserveOld = ReserveLike(spell.RESERVE_OLD);
        assertEq(reserve.currencyAvailable(), reserveOld.currencyAvailable());   
        assertEq(reserve.balance_(), reserveOld.balance_());
        assertEq(currency.balanceOf(reserve), poolReserve);
    }

    function assertMigrationCoordinator() public {
        // // check dependencies
        // DependLike(COORDINATOR_NEW).depend("assessor", ASSESSOR_NEW);
        // DependLike(COORDINATOR_NEW).depend("juniorTranche", JUNIOR_TRANCHE);
        // DependLike(COORDINATOR_NEW).depend("seniorTranche", SENIOR_TRANCHE);
        // DependLike(COORDINATOR_NEW).depend("reserve", RESERVE_NEW);
        // // migrate permissions
        // AuthLike(JUNIOR_TRANCHE).rely(COORDINATOR_NEW); 
        // AuthLike(SENIOR_TRANCHE).rely(COORDINATOR_NEW);
        // AuthLike(JUNIOR_TRANCHE).deny(COORDINATOR_OLD); 
        // AuthLike(SENIOR_TRANCHE).deny(COORDINATOR_OLD); 

        // Coordinator clone = Coordinator(clone_);
        // lastEpochClosed = clone.lastEpochClosed());
        // minimumEpochTime = clone.minimumEpochTime();
        // lastEpochExecuted = clone.lastEpochExecuted();
        // currentEpoch = clone.currentEpoch();

        // (uint  seniorRedeemSubmission, uint juniorRedeemSubmission, uint juniorSupplySubmission, uint seniorSupplySubmission) = clone.bestSubmission;
        // bestSubmission.seniorRedeem = seniorRedeemSubmission;
        // bestSubmission.juniorRedeem = juniorRedeemSubmission;
        // bestSubmission.seniorSupply = seniorSupplySubmission;
        // bestSubmission.juniorSupply = juniorSupplySubmission;

        // (uint  seniorRedeemOrder, uint juniorRedeemOrder, uint juniorSupplyOrder, uint seniorSupplyOrder) = clone.order;
        // order.seniorRedeem = seniorRedeemOrder;
        // order.juniorRedeem = juniorRedeemOrder;
        // order.seniorSupply = seniorSupplyOrder;
        // order.juniorSupply = juniorSupplyOrder;

        // bestSubScore = clone.bestSubScore();
        // gotFullValidSolution = clone.gotFullValidSolution();

        // epochSeniorTokenPrice = Fixed27(clone.epochSeniorTokenPrice());
        // epochJuniorTokenPrice = Fixed27(clone.epochJuniorTokenPrice());
        // epochNAV = clone.epochNAV();
        // epochSeniorAsset = clone.epochSeniorAsset();
        // epochReserve = clone.epochReserve();
        // submissionPeriod = clone.submissionPeriod();

        // weightSeniorRedeem = clone.weightSeniorRedeem();
        // weightJuniorRedeem = clone.weightJuniorRedeem();
        // weightJuniorSupply = clone.weightJuniorSupply();
        // weightSeniorSupply = clone.weightSeniorSupply();

        // minChallengePeriodEnd = clone.minChallengePeriodEnd();
        // challengeTime = clone.challengeTime();
        // bestRatioImprovement = clone.bestRatioImprovement();
        // bestReserveImprovement = clone.bestReserveImprovement();

        // poolClosing = clone.poolClosing();     
    }

    function assertIntegrationAdapter() public {

    }


}
