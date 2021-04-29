pragma solidity >=0.5.15 <0.6.0;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "tinlake-math/math.sol";
import "./ns-migration.sol";

interface IAuth {
    function wards(address) external returns(uint);
}

interface IAssessor {
    function navFeed() external returns(address);
    function reserve() external returns(address); 
    function seniorRatio() external returns(uint);
    function totalBalance() external returns(uint);
    function seniorDebt() external returns(uint);
    function seniorBalance() external returns(uint);

}

interface INav {
    function currentNAV() external view returns(uint);
}

interface ITranche {
    function epochTicker() external returns(address);
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

contract Hevm {
    function warp(uint256) public;
    function store(address, bytes32, bytes32) public;
}

contract TinlakeSpellsTest is DSTest, Math {

    Hevm public hevm;
    TinlakeSpell spell;

    IAssessor assessor;
    ICoordinator coordinator;
    ITranche seniorTranche;
    ITranche juniorTranche;
   
    address spell_;
    address root_;
    address reserve_;
    address assessor_;
    address coordinator_;
    address coordinatorOld_;
    address juniorTranche_;
    address seniorTranche_;

    function setUp() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);

        root_ = address(spell.ROOT());  
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

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
       
        // cheat: give testContract permissions on root contract by overriding storage 
        // storage slot for permissions => keccak256(key, mapslot) (mapslot = 0)
        hevm.store(root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function testCast() public {
        // give spell permissions on root contract
        AuthLike(root_).rely(spell_);
        spell.cast();
            
        assertMigrationCoordinator();
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
        uint epochSeniorAsset = safeAdd(assessor.seniorDebt(), assessor.seniorBalance());
        uint epochNAV = INAV(assessor.navFeed()).currentNav();
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
        assertEq(coordinator.minChallengePeriodEnd (), coordinatorOld.minChallengePeriodEnd ());
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
}
