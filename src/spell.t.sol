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

interface IMgr {
    function owner() external returns(address);
}

interface IReserve {
    function lending() external returns(address);
}

interface IAssessor {
    function clerk() external returns(address);
    function calcJuniorRatio() external returns(uint);
    function maxSeniorRatio() external returns(uint);
}

interface ICoordinator {
    function executeEpoch() external;
    function submissionPeriod() external returns(bool);
    function submitSolution(uint seniorRedeem, uint juniorRedeem,
        uint juniorSupply, uint seniorSupply) external returns(int);
}

interface IRoot {
    function relyContract(address, address) external;
}

interface IPoolAdmin {
    function lending() external returns(address);
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
    function collateralTolerance() external returns(uint);
    function wipeThreshold() external returns(uint);
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
   
    address spell_;
    address root_;
    address clerk_;
    address clerkOld_;
    address reserve_;
    address assessor_;
    address poolAdmin_;
    address seniorMemberList_;
    address coordinator_;
    address seniorTranche_;
    address currency_;
    address mgr_;
    address seniorToken_;
    address spotter_;
    address vat_;
    address jug_;

    uint256 constant RAD = 10 ** 27;
    function initSpell() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);

        assessor_ = spell.ASSESSOR();
        poolAdmin_ = spell.POOL_ADMIN();
        reserve_ = spell.RESERVE();
        coordinator_ = spell.COORDINATOR();
        seniorTranche_ = spell.SENIOR_TRANCHE();
        mgr_ = spell.MGR();
        seniorToken_ = spell.SENIOR_TOKEN();
        seniorMemberList_ = spell.SENIOR_MEMBERLIST();
        seniorTranche_ = spell.SENIOR_TRANCHE();
        clerk_ = spell.CLERK();
        clerkOld_ = spell.CLERK_OLD();
        spotter_ = spell.SPOTTER();
        vat_ = spell.VAT();
        jug_ = spell.JUG();
        root_ = address(spell.ROOT());  
        mgr = IMgr(mgr_);
        clerk = IClerk(clerk_);
        clerkOld = IClerk(clerkOld_);
        seniorToken = IRestrictedToken(seniorToken_);
        reserve = IReserve(reserve_);
        assessor = IAssessor(assessor_);
        coordinator = ICoordinator(coordinator_);
        poolAdmin = IPoolAdmin(poolAdmin_);
        root = IRoot(root_);
        hevm = IHevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        hevm.store(root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function castSpell() public {
        // give spell permissions on root contract
        AuthLike(root_).rely(spell_);
        spell.cast();
    }
}

contract SpellTest is BaseSpellTest {

    uint256 constant ONE = 10**27;

    function setUp() public {
        initSpell();
    }

    // function testFailCastTwice() public {
    //     castSpell();
    //     castSpell();
    // } 

    function testCast() public {
        castSpell();
        assertClerkMigrated();
        assertEpochExecution();
    }

    function assertClerkMigrated() internal {
        // assert state migrated correctly
        assertEq(clerk.creditline(), clerkOld.creditline());
        assertEq(clerk.matBuffer(), clerkOld.matBuffer());
        assertEq(clerk.collateralTolerance(), clerkOld.collateralTolerance());
        assertEq(clerk.wipeThreshold(), clerkOld.wipeThreshold());

        // check clerk dependencies
        assertEq(clerk.assessor(), assessor_);
        assertEq(clerk.mgr(), mgr_);
        assertEq(clerk.coordinator(), coordinator_);
        assertEq(clerk.reserve(), reserve_); 
        assertEq(clerk.tranche(), seniorTranche_);
        assertEq(clerk.collateral(), seniorToken_);
        assertEq(clerk.spotter(), spotter_);
        assertEq(clerk.vat(), vat_);
        assertEq(clerk.jug(), jug_);

        assertEq(reserve.lending(), clerk_);
        assertEq(assessor.clerk(), clerk_);
        assertEq(poolAdmin.lending(), clerk_);

        // check permissions
        assertHasPermissions(clerk_, coordinator_);
        assertHasPermissions(clerk_, reserve_);
        assertHasPermissions(clerk_, poolAdmin_);
        assertHasPermissions(reserve_, clerk_);
        assertHasPermissions(seniorTranche_, clerk_);
        assertHasPermissions(assessor_, clerk_);
        assertHasPermissions(mgr_, clerk_);
        
        // check clerk is owner of the mgr
        assertEq(mgr.owner(), clerk_);

        // assert clerk whitelisted to hold DROP
        assert(seniorToken.hasMember(clerk_));

        // assert old clerk was removed from contracts
        assertHasNoPermissions(reserve_, clerkOld_);
        assertHasNoPermissions(seniorTranche_, clerkOld_);
        assertHasNoPermissions(assessor_, clerkOld_);
        assertHasNoPermissions(mgr_, clerkOld_);
    }

    function assertEpochExecution() internal {
        coordinator.submitSolution(2493785984591851587153,0,0,87272588667380938614430);

        root.relyContract(assessor_, address(this));
        root.relyContract(clerk_, address(this));

        emit log_named_uint("max SeniorRatio", assessor.maxSeniorRatio());
        emit log_named_uint("current SeniorRatio", (RAD - assessor.calcJuniorRatio()));
        // IFile(assessor_).file("maxSeniorRatio", 860000000000000000000000000);
        
        coordinator.executeEpoch();

        assert(coordinator.submissionPeriod() == false);
        // emit log_named_uint("current ratio", (RAD - assessor.calcJuniorRatio()));
        // clerk.sink(500000 ether); 
        // emit log_named_uint("current ratio", (RAD - assessor.calcJuniorRatio()));
        // IFile(assessor_).file("maxSeniorRatio", 850000000000000000000000000);
        // assert(coordinator.submissionPeriod() == true);
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
