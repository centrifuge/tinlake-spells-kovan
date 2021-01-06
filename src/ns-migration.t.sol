pragma solidity >=0.5.15 <0.6.0;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "./../src/ns-migration.sol";

interface IAuth {
    function wards(address) external returns(uint);
}
interface IReserve {
    function assessor() external returns(address);
    function currency() external returns(address);
    function shelf() external returns(address);
    function pot() external returns(address);
    function lending() external returns(address);
    function currencyAvailable() external returns(address);
    function balance_() external returns(address);
}

interface IAssessor {
    function seniorTranche() external returns(address);
    function juniorTranche() external returns(address);
    function navFeed() external returns(address);
    function reserve() external returns(address); 
    function clerk() external returns(address);
    function seniorRatio() external returns(uint);
    function seniorDebt_() external returns(uint);
    function seniorBalance_() external returns(uint);
    function seniorInterestRate() external returns(uint);
    function lastUpdateSeniorInterest() external returns(uint);
    function maxSeniorRatio() external returns(uint);
    function minSeniorRatio() external returns(uint);
    function maxReserve() external returns(uint);
}

interface IAssessorWrapperLike {
    function assessor() external returns(address);
}

interface ICoordinator  {
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

interface IClerk {
    function assessor() external returns(address);
    function mgr() external returns(address);
    function coordinator() external returns(address);
    function reserve() external returns(address); 
    function tranche() external returns(address);
    function collateral() external returns(address);
    function spotter() external returns(address);
    function vat() external returns(address);
    function matBuffer() external returns(uint);
}

interface IShelf {
    function distributor() external returns(address);
}

interface ICollector {
    function distributor() external returns(address);
}

interface IREstrictedToken {
    function hasMember(address member) external returns(bool);
}

contract Hevm {
    function warp(uint256) public;
    function store(address, bytes32, bytes32) public;
}

contract TinlakeSpellsTest is DSTest {

    Hevm public hevm;
    TinlakeSpell spell;

    IShelf shelf;
    ICollector collector;
    IAssessor assessor;
    IAssessorWrapperLike assessorWrapper;
    IReserve reserve;
    ICoordinator coordinator;
    IREstrictedToken seniorToken;
    IClerk clerk;
    SpellERC20Like currency;
    SpellERC20Like testCurrency; // kovan only
   
    address spell_;
    address root_;
    address shelf_;
    address reserve_;
    address assessor_;
    address assessorWrapper_;
    address clerk_;
    address coordinator_;
    address juniorTranche_;
    address seniorTranche_;
    address currency_;
    address nav_;
    address pot_;
    address mgr_;
    address seniorToken_;
    address spotter_;
    address vat_;

    uint poolReserveDAI;

    function setUp() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);

        root_ = address(spell.ROOT());  
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        collector = ICollector(spell.COLLECTOR());
        shelf = IShelf(spell.SHELF());
        assessor = IAssessor(spell.ASSESSOR_NEW());
        assessorWrapper = IAssessorWrapperLike(spell.ASSESSOR_WRAPPER());
        reserve = IReserve(spell.RESERVE_NEW());
        coordinator = ICoordinator(spell.COORDINATOR_NEW());
        clerk = IClerk(spell.CLERK());
        currency = SpellERC20Like(spell.TINLAKE_CURRENCY());
        seniorToken = IREstrictedToken(spell.SENIOR_TOKEN());
        seniorToken_ = spell.SENIOR_TOKEN();
        juniorTranche_ = spell.JUNIOR_TRANCHE();
        seniorTranche_ = spell.SENIOR_TRANCHE();

        nav_ = spell.NAV();
        mgr_ = spell.MGR();
        spotter_ = spell.SPOTTER();
        vat_ = spell.VAT();
        shelf_ = address(shelf);
        assessor_ = address(assessor);
        assessorWrapper_ = address(assessorWrapper);
        reserve_ = address(reserve);
        pot_ = address(reserve);
        coordinator_ = address(coordinator);
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
        assertMigrationAssessor();
        assertMigrationCoordinator();
        assertMigrationReserve();
        assertIntegrationAdapter();
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

    function assertMigrationAssessor() public {  
        IAssessor assessorOld = IAssessor(spell.ASSESSOR_OLD());

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
        assertHasPermissions(assessor_, assessorWrapper_);

        // check state
        assertEq(assessor.seniorRatio(), assessorOld.seniorRatio());
        assertEq(assessor.seniorDebt_(), assessorOld.seniorDebt_());
        assertEq(assessor.seniorBalance_(), assessorOld.seniorBalance_());
        assertEq(assessor.seniorInterestRate(), assessorOld.seniorInterestRate());
        assertEq(assessor.lastUpdateSeniorInterest(), assessorOld.lastUpdateSeniorInterest());
        assertEq(assessor.maxSeniorRatio(), assessorOld.maxSeniorRatio());
        assertEq(assessor.minSeniorRatio(), spell.ASSESSOR_MIN_SENIOR_RATIO()); // has to be 0 for mkr integration
        assertEq(assessor.maxReserve(), assessorOld.maxReserve());   
    }

    function assertMigrationReserve() public {
        IReserve reserveOld =IReserve(spell.RESERVE_OLD());
         // check dependencies 
        assertEq(reserve.assessor(), assessor_);
        assertEq(reserve.currency(), currency_);
        assertEq(reserve.shelf(), shelf_);
        assertEq(reserve.lending(), clerk_);
        // assertEq(reserve.pot(), pot_); -> has to be public
        assertEq(shelf.distributor(), reserve_);
        // assertEq(collector.distributor(), reserve_); -> has to be public

        // check permissions
        assertHasPermissions(reserve_, clerk_);
        assertHasPermissions(reserve_, juniorTranche_);
        assertHasPermissions(reserve_, seniorTranche_);

        // check state
        assertEq(reserve.currencyAvailable(), reserveOld.currencyAvailable());   
        assertEq(reserve.balance_(), reserveOld.balance_());
        assertEq(currency.balanceOf(reserve_), poolReserveDAI);
    }

    function assertMigrationCoordinator() public {
        ICoordinator coordinatorOld = ICoordinator(spell.COORDINATOR_OLD());
    
        // check dependencies
        assertEq(coordinator.assessor(), assessor_);
        assertEq(coordinator.juniorTranche(), juniorTranche_);
        assertEq(coordinator.seniorTranche(), seniorTranche_);
        assertEq(coordinator.reserve(), reserve_);
 
        // check permissions
        assertHasPermissions(juniorTranche_, coordinator_);
        assertHasPermissions(seniorTranche_, coordinator_);
        assertHasNoPermissions(juniorTranche_, address(coordinatorOld));
        assertHasNoPermissions(seniorTranche_, address(coordinatorOld));

        // check state
        assertEq(coordinator.lastEpochClosed(), coordinatorOld.lastEpochClosed());
        assertEq(coordinator.minimumEpochTime(), coordinatorOld.minimumEpochTime());
        assertEq(coordinator.lastEpochExecuted(), coordinatorOld.lastEpochExecuted());
        assertEq(coordinator.currentEpoch(), coordinatorOld.currentEpoch());
        assertEq(coordinator.bestSubScore(), coordinatorOld.bestSubScore());
        assert(coordinator.gotFullValidSolution() == coordinatorOld.gotFullValidSolution());
        assertEq(coordinator.epochSeniorTokenPrice(), coordinatorOld.epochSeniorTokenPrice());
        assertEq(coordinator.epochJuniorTokenPrice(), coordinatorOld.epochJuniorTokenPrice());
        assertEq(coordinator.epochNAV(), coordinatorOld.epochNAV());
        assertEq(coordinator.epochSeniorAsset(), coordinatorOld.epochSeniorAsset());
        assertEq(coordinator.epochReserve(), coordinatorOld.epochReserve());
        assert(coordinator.submissionPeriod() == coordinatorOld.submissionPeriod());
        assertEq(coordinator.weightSeniorRedeem(), coordinatorOld.weightSeniorRedeem());
        assertEq(coordinator.weightJuniorRedeem(), coordinatorOld.weightJuniorRedeem());
        assertEq(coordinator.weightJuniorSupply(), coordinatorOld.weightJuniorSupply());
        assertEq(coordinator.weightSeniorSupply(), coordinatorOld.weightSeniorSupply());
        assertEq(coordinator.minChallengePeriodEnd (), coordinatorOld.minChallengePeriodEnd ());
        assertEq(coordinator.challengeTime(), coordinatorOld.challengeTime());
        assertEq(coordinator.bestRatioImprovement(), coordinatorOld.bestRatioImprovement());
        assertEq(coordinator.bestReserveImprovement(), coordinatorOld.bestReserveImprovement());
        assert(coordinator.poolClosing() == coordinatorOld.poolClosing());
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

    function assertIntegrationAdapter() public {
         // check dependencies 
         // vars have to be made public first
        // assertEq(clerk.assessor(), assessor_);
        // assertEq(clerk.mgr(), mgr_);
        // assertEq(clerk.coordinator(), coordinator_);
        // assertEq(clerk.reserve(), reserve_); 
        // assertEq(clerk.tranche(), seniorTranche_);
        // assertEq(clerk.collateral(), seniorToken_);
        // assertEq(clerk.spotter(), spotter_);
        // assertEq(clerk.vat(), vat_);

        // check permissions
        assertHasPermissions(clerk_, coordinator_);
        assertHasPermissions(clerk_, reserve_);
        assertHasPermissions(reserve_, clerk_);
        assertHasPermissions(seniorTranche_, clerk_);
        assertHasPermissions(assessor_, clerk_);
        
        // state
        assert(seniorToken.hasMember(clerk_));
        assert(seniorToken.hasMember(mgr_));
        //assertEq(clerk.matBuffer(), spell.CLERK_BUFFER()); // has to be public
    }
}
