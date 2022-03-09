pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "./spell.sol";



interface IFile {
    function file(bytes32, uint) external;
    function file(bytes32, address) external;
}

interface ITranche {
    function coordinator() external returns(address);
}

interface IAuth {
    function wards(address) external returns(uint);
}

interface IHevm {
    function warp(uint256) external;
    function store(address, bytes32, bytes32) external;
}

interface IMgr {
    function owner() external returns(address);
}

interface IReserve {
    function lending() external returns(address);
    function currencyAvailable() external returns(uint);
}

interface IAssessor {
    function lending() external returns(address);
    function calcJuniorRatio() external returns(uint);
    function maxSeniorRatio() external returns(uint);
    function seniorRatio() external returns(uint);
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

interface IRoot {
    function relyContract(address, address) external;
}

interface IPoolAdmin {
    function lending() external returns(address);
    function seniorMemberlist() external returns(address);
    function juniorMemberlist() external returns(address);
    function navFeed() external returns(address);
    function coordinator() external returns(address);
    function assessor() external returns(address);
    function admin_level(address) external returns(uint);
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
    function jug() external returns(address);
    function creditline() external returns(uint);
    function matBuffer() external returns(uint);
    function autoHealMax() external returns(uint);
    function collateralTolerance() external returns(uint);
    function wipeThreshold() external returns(uint);
    function collatDeficit() external view returns (uint);
    function sink(uint amountDAI) external;
}

interface IRestrictedToken {
    function hasMember(address member) external returns(bool);
}

contract BaseSpellTest is DSTest {

    IHevm public hevm;
    TinlakeSpell spell;
    IClerk clerk;
    IClerk clerkOld;
    IMgr mgr;
    IRestrictedToken seniorToken;
    IAssessor assessor;
    IReserve reserve;
    IPoolAdmin poolAdmin;
    ICoordinator coordinator;
    IRoot root;
    ITranche seniorTranche;
    ITranche juniorTranche;
   
    address spell_;
    address root_;
    address clerk_;
    address clerkOld_;
    address reserve_;
    address assessor_;
    address poolAdmin_;
    address poolAdminOld_;
    address seniorMemberList_;
    address juniorMemberList_;
    address coordinator_;
    address coordinatorOld_;
    address seniorTranche_;
    address juniorTranche_;
    address currency_;
    address mgr_;
    address navFeed_;
    address seniorToken_;
    address spotter_;
    address vat_;
    address jug_;
    address registry_;

    uint256 constant RAD = 10 ** 27;
    function initSpell() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);

        assessor_ = spell.ASSESSOR();
        poolAdmin_ = spell.POOL_ADMIN();
        poolAdminOld_ = spell.POOL_ADMIN_OLD();
        reserve_ = spell.RESERVE();
        coordinator_ = spell.COORDINATOR();
        seniorTranche_ = spell.SENIOR_TRANCHE();
        navFeed_ = spell.FEED();
        seniorToken_ = spell.SENIOR_TOKEN();
        seniorMemberList_ = spell.SENIOR_MEMBERLIST();
        juniorMemberList_ = spell.JUNIOR_MEMBERLIST();
        seniorTranche_ = spell.SENIOR_TRANCHE();
        juniorTranche_ = spell.JUNIOR_TRANCHE();
        clerk_ = spell.CLERK();
        root_ = address(spell.ROOT());  
        registry_ = spell.POOL_REGISTRY();

        mgr = IMgr(mgr_);
        clerk = IClerk(clerk_);
        clerkOld = IClerk(clerkOld_);
        seniorToken = IRestrictedToken(seniorToken_);
        seniorTranche = ITranche(seniorTranche_);
        juniorTranche = ITranche(juniorTranche_);
        reserve = IReserve(reserve_);
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
        assertPoolAdminSwapped();
        // assertEpochExecution(); not required for this pool
        // assertRegistryUpdated();
    }


    function assertEpochExecution() internal {
        coordinator.executeEpoch();
        assertEq(clerk.collatDeficit(), 0);
        assert(coordinator.submissionPeriod() == false);
    }

    function assertPoolAdminSwapped() public {

        // setup dependencies 
        assertEq(poolAdmin.assessor(), assessor_);
        assertEq(poolAdmin.lending(), clerk_);
        assertEq(poolAdmin.seniorMemberlist(), seniorMemberList_);
        assertEq(poolAdmin.juniorMemberlist(), juniorMemberList_);
        assertEq(poolAdmin.navFeed(), navFeed_);
        assertEq(poolAdmin.coordinator(), coordinator_);

        assertHasPermissions(assessor_, poolAdmin_);
        assertHasPermissions(clerk_, poolAdmin_);
        assertHasPermissions(seniorMemberList_, poolAdmin_);
        assertHasPermissions(juniorMemberList_, poolAdmin_);
        assertHasPermissions(navFeed_, poolAdmin_);
        assertHasPermissions(coordinator_, poolAdmin_);

        assertHasNoPermissions(assessor_, poolAdminOld_);
        assertHasNoPermissions(clerk_, poolAdminOld_);
        assertHasNoPermissions(seniorMemberList_, poolAdminOld_);
        assertHasNoPermissions(juniorMemberList_, poolAdminOld_);
        assertHasNoPermissions(coordinator_, poolAdminOld_);
        assertHasNoPermissions(navFeed_, poolAdminOld_);

        assertEq(poolAdmin.admin_level(spell.LEVEL3_ADMIN1()), 3);
        assertEq(poolAdmin.admin_level(spell.LEVEL1_ADMIN1()), 1);
        assertEq(poolAdmin.admin_level(spell.LEVEL1_ADMIN2()), 1);
        assertEq(poolAdmin.admin_level(spell.LEVEL1_ADMIN3()), 1);
        assertEq(poolAdmin.admin_level(spell.LEVEL1_ADMIN4()), 1);
        assertEq(poolAdmin.admin_level(spell.LEVEL1_ADMIN5()), 1);
        assertEq(poolAdmin.admin_level(spell.AO_POOL_ADMIN()), 1);
        assertHasPermissions(seniorMemberList_, spell.MEMBER_ADMIN());
        emit log_named_address("junior", juniorMemberList_);
        emit log_named_address("member admin", spell.MEMBER_ADMIN());
        assertHasPermissions(juniorMemberList_, spell.MEMBER_ADMIN());
    }

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

