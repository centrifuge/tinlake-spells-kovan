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
    function assessor() external returns(address);
    function juniorTranche() external returns(address);
    function seniorTranche() external returns(address);
    function reserve() external returns(address);
    function lastEpochClosed() external returns(uint);
    function minimumEpochTime() external returns(uint);
    function lastEpochExecuted() external returns(uint);
    function currentEpoch() external returns(uint);
    function bestSubmission() external returns(uint, uint, uint, uint);
    function order() external returns(uint, uint, uint, uint);
    function bestSubScore() external returns(uint);
    function gotFullValidSolution() external returns(bool);
    function epochSeniorTokenPrice() external returns(uint);
    function epochJuniorTokenPrice() external returns(uint);
    function epochNAV() external returns(uint);
    function epochSeniorAsset() external returns(uint);
    function epochReserve() external returns(uint);
    function submissionPeriod() external returns(bool);
    function weightSeniorRedeem() external returns(uint);
    function weightJuniorRedeem() external returns(uint);
    function weightJuniorSupply() external returns(uint);
    function weightSeniorSupply() external returns(uint);
    function minChallengePeriodEnd() external returns(uint);
    function challengeTime() external returns(uint);
    function bestRatioImprovement() external returns(uint);
    function bestReserveImprovement() external returns(uint);
    function poolClosing() external returns(bool);
}

interface ClerkLike {
    function wards(address) external returns(uint);
    function assessor() public returns(address);
    function mgr() public returns(address);
    function coordintaor() public returns(address);
    function reserve() public returns(address); 
    function tranche() public returns(address);
    function collateral() public returns(address);
    function spotter() public returns(address);
    function vat() public returns(address);
    function buffer() public returns(uint);
}

interface ShelfLike {
    function distributor()  external returns(address);
}

interface CollectorLike {
    function distributor()  external returns(address);
}

interface RestrictedTokenLike {
    function hasMember(address member) external returns(bool);
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
    RestrictedTokenLike seniorToken;
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
    address mgr_;
    address seniorToken_;
    address spotter_;
    address vat_;

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
        pot_ = address(reserve);
        coordinator = CoordinatorLike(spell.COORDINATOR_NEW);
        coordinator_ = address(coordinator);
        clerk = ClerkLike(spell.CLERK);
        clerk_ = address(clerk);
        currency = ERC20Like(spell.TINLAKE_CURRENCY);
        currency_ = address(currency);
        seniorToken = RestrictedTokenLike(spell.SENIOR_TOKEN());
        seniorToken_ = spell.SENIOR_TOKEN();
        juniorTranche_ = spell.JUNIOR_TRANCHE();
        seniorTranche_ = spell.SENIOR_TRANCHE();
        nav_ = spell.NAV();
        mgr_ = spell.MGR();
        spotter_ = spell.SPOTTER();
        vat_ = spell.VAT();

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
        assertEq(assessor.seniorInterestRate(), assessorOld.seniorInterestRate());
        assertEq(assessor.lastUpdateSeniorInterest(), assessorOld.lastUpdateSeniorInterest());
        assertEq(assessor.maxSeniorRatio(), assessorOld.lastUpdateSeniorInterest());
        assertEq(assessor.minSeniorRatio(), spell.ASSESSOR_MIN_SENIOR_RATIO); // has to be 0 for mkr integration
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
        // check dependencies
        assertEq(coordinator.assessor(), assessor_);
        assertEq(coordinator.juniorTranche(), juniorTranche_);
        assertEq(coordinator.seniorTranche(), seniorTranche_);
        assertEq(coordinator.reserve(), reserve_);

        CoordinatorLike coordinatorOld = CoordinatorLike(spell.COORDINATOR_OLD);
        address coordinatorOld_ = address(coordinatorOld);   
        // check permissions
        assertHasPermissions(juniorTranche_, coordinator_);
        assertHasPermissions(seniorTranche_, coordinator_);
        assertHasNoPermissions(juniorTranche_, coordinatorOld_);
        assertHasNoPermissions(seniorTranche_, coordinatorOld_);

        // check state
        assertEq(coordinator.lastEpochClosed(), coordinatorOld.lastEpochClosed());
        assertEq(coordinator.minimumEpochTime(), coordinatorOld.minimumEpochTime());
        assertEq(coordinator.lastEpochExecuted(), coordinatorOld.lastEpochExecuted());
        assertEq(coordinator.currentEpoch(), coordinatorOld.currentEpoch());
        assertEq(coordinator.bestSubmission(), coordinatorOld.bestSubmission());
        assertEq(coordinator.order(), coordinatorOld.order());
        assertEq(coordinator.bestSubScore(), coordinatorOld.bestSubScore());
        assertEq(coordinator.gotFullValidSolution(), coordinatorOld.gotFullValidSolution());
        assertEq(coordinator.epochSeniorTokenPrice(), coordinatorOld.epochSeniorTokenPrice());
        assertEq(coordinator.epochJuniorTokenPrice(), coordinatorOld.epochJuniorTokenPrice());
        assertEq(coordinator.epochNAV(), coordinatorOld.epochNAV());
        assertEq(coordinator.epochSeniorAsset(), coordinatorOld.epochSeniorAsset());
        assertEq(coordinator.epochReserve(), coordinatorOld.epochReserve());
        assertEq(coordinator.submissionPeriod(), coordinatorOld.submissionPeriod());
        assertEq(coordinator.weightSeniorRedeem(), coordinatorOld.weightSeniorRedeem());
        assertEq(coordinator.weightJuniorRedeem(), coordinatorOld.weightJuniorRedeem());
        assertEq(coordinator.weightJuniorSupply(), coordinatorOld.weightJuniorSupply());
        assertEq(coordinator.weightSeniorSupply(), coordinatorOld.weightSeniorSupply());
        assertEq(coordinator.minChallengePeriodEnd (), coordinatorOld.minChallengePeriodEnd ());
        assertEq(coordinator.challengeTime(), coordinatorOld.challengeTime());
        assertEq(coordinator.bestRatioImprovement(), coordinatorOld.bestRatioImprovement());
        assertEq(coordinator.bestReserveImprovement(), coordinatorOld.bestReserveImprovement());
        assertEq(coordinator.poolClosing(), coordinatorOld.poolClosing()); 
    }

    function assertIntegrationAdapter() public {
         // check dependencies
        assertEq(clerk.assessor(), assessor_);
        assertEq(clerk.mgr(), mgr_);
        assertEq(clerk.coordintaor(), coordinator_);
        assertEq(clerk.reserve(), reserve_); 
        assertEq(clerk.tranche(), seniorTranche_);
        assertEq(clerk.collateral(), seniorToken_);
        assertEq(clerk.spotter(), spotter_);
        assertEq(clerk.vat(), vat_);

        // check permissions
        assertHasPermissions(clerk_, coordinator_);
        assertHasPermissions(clerk_, reserve_);
        assertHasPermissions(reserve_, clerk_);
        assertHasPermissions(seniorTranche_, clerk_);
        
        // state
        assertEq(seniorToken.hasMember(clerk_), true);
        assertEq(seniorToken.hasMember(mgr_), true);
        assertEq(clerk.buffer(), spell.CLERK_BUFFER);
    }
}
