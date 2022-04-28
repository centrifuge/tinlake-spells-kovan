pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "./spell.sol";



interface IFile {
    function file(bytes32, uint) external;
    function file(bytes32, address) external;
}

interface IAuth {
    function wards(address) external returns(uint);
}

interface IHevm {
    function warp(uint256) external;
    function store(address, bytes32, bytes32) external;
}

interface IAssessor {
    function nav() external returns(address);
}

interface ICoordinator {
    function executeEpoch() external;
    function submitSolution(uint seniorRedeem, uint juniorRedeem,
        uint juniorSupply, uint seniorSupply) external returns(int);
        function assessor() external returns(address);
    function juniorTranche() external returns(address);
    function seniorTranche() external returns(address);
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

interface NavLike {
    function discountRate() external returns(uint);
    function approximatedNAV() external returns(uint);
    function currentNav() external returns(uint);
    function pile() external returns(address);
    function nftID(address, uint) external returns(bytes32);
    function futureValue(bytes32) external returns(uint);
    function nftValues(bytes32) external returns(uint);
    function risk(bytes32) external returns(uint);
    function maturityDate(bytes32) external returns(uint);
    function ceiling(uint) external returns(uint);
    function currentCeiling(uint) external returns(uint);
    function threshold(uint) external returns(uint);
    function borrowed(uint) external returns(uint);
}

// interface NAVNewLikeOld {
    
// } 

interface IRoot {
    function relyContract(address, address) external;
}

interface IPoolAdmin {
    function navFeed() external returns(address);
}

contract BaseSpellTest is DSTest {

    IHevm public hevm;
    TinlakeSpell spell;
    IAssessor assessor;
    IPoolAdmin poolAdmin;
    ICoordinator coordinator;
    NavLike nav;
    NavLike navOld;
    IRoot root;
   
   
    address spell_;
    address root_;
    address assessor_;
    address poolAdmin_;
    address coordinator_;
    address currency_;
    address nav_;
    address navOld_;
    address registry_;

    uint256 constant RAD = 10 ** 27;
    function initSpell() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);

        assessor_ = spell.ASSESSOR();
        poolAdmin_ = spell.POOL_ADMIN();
        coordinator_ = spell.COORDINATOR();
        nav_ = spell.NAV();
        navOld_ = spell.NAV_OLD();
        root_ = address(spell.ROOT());  
        registry_ = spell.POOL_REGISTRY();

        nav = NavLike(nav_);
        navOld = NavLike(navOld_);
        assessor = IAssessor(assessor_);
        coordinator = ICoordinator(coordinator_);
        poolAdmin = IPoolAdmin(poolAdmin_);
        root = IRoot(root_);
        hevm = IHevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        hevm.store(root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
        hevm.store(registry_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function castSpell() public {
        // give spell permissions on root contract
        AuthLike(root_).rely(spell_);
        AuthLike(registry_).rely(spell_);
        spell.cast();
    }
}

contract SpellTest is BaseSpellTest {

    uint256 constant ONE = 10**27;

    function setUp() public {
        initSpell();
    }

    function testFailCastTwice() public {
        castSpell();
        castSpell();
    } 

    function testCast() public {
        AuthLike(registry_).rely(spell_);
        castSpell();
        assertNavMigrated();

        // assertEpochExecution(); not required for this pool
        // assertRegistryUpdated();
    }

    function assertNavMigrated() public {
        uint navValue = nav.approximatedNAV();
        uint navValueOld = navOld.approximatedNAV();
        emit log_named_uint("value new", navValue);
        emit log_named_uint("value old", navValueOld);
        assertEq(navValue,  navValueOld);
    }


    // function assertEpochExecution() internal {
    //     coordinator.executeEpoch();
    //     assertEq(clerk.collatDeficit(), 0);
    //     assert(coordinator.submissionPeriod() == false);
    // }

        

    // function assertMigrationNAV() public {

    //     // assert dependencies
    //     assertEq(navNew.pile(), address(pile));
    //     asserEq(navNew.shelf(), address(shelf));
    //     assertEq(shelf.ceiling, navNew_);
    //     assertEq(shelf.subscriber, navNew_);

    //     // assert wards
    //     assertHasPermissions(navNew_, address(shelf));
    //     assertHasPermissions(navNew_, spell.ORACLE);
    //     assertHasPermissions(address(pile), navNew_);
    //     assertHasNoPermissions(address(pile), navOld_);

    //     // assert discountRate
    //     assertEq(navNew.discountRate(), navOld.discountRate());

    //     // assert writeoffs 
    //     // for (uint i = 1000; i <= 1003; i++) {
    //     //     (uint rateGroupNew, uint percentageNew) = navNew.writeOffs(i);
    //     //     (uint rateGroupOld, uint percentageOld) = navOld.writeOffs(i);
    //     //     assertEq(rateGroupNew, rateGroupOld);
    //     //     assertEq(percentageNew, percentageOld);
    //     // }

    //     // assert riskgroups
    //     for (uint i = 0; i <= 40; i++) {
    //         assertEq(navNew.thresholdRatio(i), navOld.thresholdRatio(i));
    //         assertEq(navNew.ceilingRatio(i), navOld.ceilingRatio(i));
    //         assertEq(navNew.recoveryRatePD(i), navOld.recoveryRatePD(i));
    //         (, , uint interestRateNew, ,) = PileLike(navNew.pile()).rates(i);
    //         (, , uint interestRateOld, ,) = PileLike(navOld.pile()).rates(i);
    //         assertEq(interestRateNew, interestRateOld);
    //     }
        
    //     // assert loan migration & assert nft migration
    //     for (uint loanID = 1; loanID < shelf.loanCount(); loanID++) {
    //         bytes32 nftID = clone.nftID(loanID);
    //         assertLoanMigration(loanID)
    //         assertNFTMigration(nftID);
    //     }

    //     // assert nav calculation
    //      assertEq(navOld.currentNAV(), NAVNewLike(navNew_.)latestNAV());
    //     }

    // function assertNFTMigration(bytes32 nftID) public { 
    //     assertEq(navNew.futureValue(nftID), navOld.futureValue(nftID));
    //     assertEq(navNew.nftValues(nftID), navOld.nftValues(nftID));
    //     assertEq(navNew.risk(nftID), navOld.risk(nftID));
    //     assertEq(navNew.maturityDate(nftID), navOld.maturityDate(nftID));
    // }

    // function assertLoanMigration(uint loanId) public { 
    //     assertEq(navNew.ceiling(loanId), navOld.ceiling(loanId));
    //     assertEq(navNew.currentCeiling(loanId), navOld.currentCeiling(loanId));
    //     assertEq(navNew.threshold(loanId), navOld.threshold(loanId));
    //     assertEq(navNew.borrowed(loanId), navOld.borrowed(loanId));
    
    // }

    function assertRegistryUpdated() public {
        assertEq(AuthLike(spell.POOL_REGISTRY()).wards(address(this)), 1);
        (,,string memory data) = PoolRegistryLike(spell.POOL_REGISTRY()).find(spell.ROOT());
        assertEq(data, spell.IPFS_HASH());
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

