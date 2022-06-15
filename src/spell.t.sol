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
    function navFeed() external returns(address);
}

interface IShelf {
    function ceiling() external returns(address);
    function subscriber() external returns(address);
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
    function shelf() external returns(address);
    function title() external returns(address);
    function nftID(uint) external returns (bytes32);
    function futureValue(bytes32) external returns(uint);
    function nftValues(bytes32) external returns(uint);
    function risk(bytes32) external returns(uint);
    function maturityDate(bytes32) external returns(uint);
    function ceiling(uint) external returns(uint);
    function currentCeiling(uint) external returns(uint);
    function threshold(uint) external returns(uint);
    function borrowed(uint) external returns(uint);
    function thresholdRatio(uint) external returns(uint);
    function ceilingRatio(uint) external returns(uint);
    function recoveryRatePD(uint) external returns(uint);
    function buckets(uint) external returns(uint); 
}
 
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
    IShelf shelf;
   
    address spell_;
    address root_;
    address assessor_;
    address poolAdmin_;
    address coordinator_;
    address currency_;
    address nav_;
    address navOld_;
    address registry_;
    address pile_;
    address shelf_;
    address title_;
    

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
        pile_ = spell.PILE();
        shelf_ = spell.SHELF();
        title_ = spell.TITLE();

        shelf = IShelf(shelf_);
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
        // assertRegistryUpdated();
    }

    function assertNavMigrated() public {
        // assert NAV value correct
        uint navValue = nav.approximatedNAV();
        uint navValueOld = navOld.approximatedNAV();
        assertEq(navValue,  navValueOld);

        // assert params correct
        assertEq(nav.discountRate(), navOld.discountRate());

        // assert dependencies
        assertEq(nav.pile(), pile_);
        assertEq(nav.shelf(), shelf_);
        assertEq(nav.title(), title_);
        assertEq(shelf.ceiling(), nav_);
        assertEq(shelf.subscriber(), nav_);
        assertEq(assessor.navFeed(), nav_);

        // assert wards
        assertHasPermissions(nav_, shelf_);
        assertHasPermissions(nav_, spell.ORACLE());
        assertHasPermissions(pile_, nav_);
        // revoke permissions from old nav
        assertHasNoPermissions(pile_, navOld_);

        // assert risk group migration
        for (uint i = 0; i <= spell.riskGroupCount(); i++) {
            assertEq(nav.thresholdRatio(i), navOld.thresholdRatio(i));
            assertEq(nav.ceilingRatio(i), navOld.ceilingRatio(i));
            assertEq(nav.recoveryRatePD(i), navOld.recoveryRatePD(i));
        }

        // assert loans & nft migrations
        for (uint loanID = 1; loanID < spell.loanCount(); loanID++) {
            bytes32 nftID = nav.nftID(loanID);
            assertLoanMigration(loanID);
            assertNFTMigration(nftID);
        }
    }       

    function assertNFTMigration(bytes32 nftID) public { 
        uint maturityDate = nav.maturityDate(nftID);
        assertEq(nav.futureValue(nftID), navOld.futureValue(nftID));
        assertEq(nav.nftValues(nftID), navOld.nftValues(nftID));
        assertEq(nav.risk(nftID), navOld.risk(nftID));
        assertEq(nav.maturityDate(nftID), navOld.maturityDate(nftID));
        assertEq(nav.buckets(maturityDate), navOld.buckets(maturityDate));
    }

    function assertLoanMigration(uint loanId) public {
        assertEq(nav.ceiling(loanId), navOld.ceiling(loanId));
        assertEq(nav.threshold(loanId), navOld.threshold(loanId));
        assertEq(nav.borrowed(loanId), navOld.borrowed(loanId));
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

