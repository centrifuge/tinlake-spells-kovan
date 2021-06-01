pragma solidity >=0.5.15 <0.6.0;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "tinlake-math/math.sol";
import "./spell.sol";

interface IAuth {
    function wards(address) external returns(uint);
}

interface IAssessor {
    function seniorTranche() external returns(address);
    function juniorTranche() external returns(address);
}

interface IOperator {
    function tranche() external returns(address);
}

interface ITranche {
    function reserve() external returns(address);
    function epochTicker() external returns(address);
}

interface ICoordinator  {
    function juniorTranche() external returns(address);
    function seniorTranche() external returns(address);
}

interface IClerk {
    function tranche() external returns(address);
}

interface IREstrictedToken {
    function hasMember(address member) external returns(bool);
}

interface IMgr {
    function tranche() external returns(address);
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
    IOperator seniorOperator;
    IOperator juniorOperator;
    IREstrictedToken seniorToken;
    IREstrictedToken juniorToken;
    IClerk clerk;
    IMgr mgr;
    SpellERC20Like currency;
    SpellERC20Like testCurrency; // kovan only
    
    address spell_;
    address root_;
    address reserve_;
    address assessor_;
    address clerk_;
    address mgr_;
    address coordinator_;
    address juniorTranche_;
    address seniorTranche_;
    address seniorTrancheOld_;
    address juniorTrancheOld_;
    address seniorOperator_;
    address juniorOperator_;
    address currency_;
    address seniorToken_;
    address juniorToken_;

    function setUp() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);

        root_ = address(spell.ROOT());  
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);


        assessor = IAssessor(spell.ASSESSOR());
        coordinator = ICoordinator(spell.COORDINATOR());
        seniorTranche = ITranche(spell.SENIOR_TRANCHE_NEW());
        juniorTranche = ITranche(spell.JUNIOR_TRANCHE_NEW());
        seniorOperator = IOperator(spell.SENIOR_OPERATOR());
        juniorOperator = IOperator(spell.JUNIOR_OPERATOR());
        clerk = IClerk(spell.CLERK());
        mgr = IMgr(spell.MGR());
        currency = SpellERC20Like(spell.TINLAKE_CURRENCY());
        seniorToken = IREstrictedToken(spell.SENIOR_TOKEN());
        juniorToken = IREstrictedToken(spell.JUNIOR_TOKEN());
    
        seniorToken_ = spell.SENIOR_TOKEN();
        juniorToken_ = spell.JUNIOR_TOKEN();
        seniorTrancheOld_ = spell.SENIOR_TRANCHE_OLD();
        juniorTrancheOld_ = spell.JUNIOR_TRANCHE_OLD();
        reserve_ = spell.RESERVE();
        mgr_ = address(mgr);
        assessor_ = address(assessor);
        seniorOperator_ = address(seniorOperator);
        juniorOperator_ = address(juniorOperator);
        coordinator_ = address(coordinator);
        seniorTranche_ = address(seniorTranche);
        juniorTranche_ = address(juniorTranche);
        clerk_ = address(clerk);
        currency_ = address(currency);
        // cheat: give testContract permissions on root contract by overriding storage 
        // storage slot for permissions => keccak256(key, mapslot) (mapslot = 0)
        hevm.store(root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function testCast() public {
        // give spell permissions on root contract
        AuthLike(root_).rely(spell_);
        spell.cast();
    
        assertMigrationTranches();
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

    function assertMigrationTranches() public {

        // senior
        assertEq(seniorTranche.reserve(), reserve_);
        assertEq(seniorTranche.epochTicker(),coordinator_);
        assertEq(seniorOperator.tranche(), seniorTranche_);
        assertEq(assessor.seniorTranche(), seniorTranche_);
        assertEq(coordinator.seniorTranche(), seniorTranche_);

        assertHasPermissions(seniorTranche_, coordinator_);   
        assertHasPermissions(seniorTranche_, seniorOperator_);  
        assertHasPermissions(reserve_, seniorTranche_);
        assertHasPermissions(seniorToken_, seniorTranche_);

        assertHasNoPermissions(reserve_, seniorTrancheOld_);
        assertHasNoPermissions(seniorToken_, seniorTrancheOld_);
   
        // maker contracts
        assertEq(clerk.tranche(), seniorTranche_);
        assertEq(mgr.tranche(), seniorTranche_);

        // junior
        assertEq(juniorTranche.reserve(), reserve_);
        assertEq(juniorTranche.epochTicker(), coordinator_);
        assertEq(juniorOperator.tranche(), juniorTranche_);
        assertEq(assessor.juniorTranche(), juniorTranche_);
        assertEq(coordinator.juniorTranche(), juniorTranche_);
       
        assertHasPermissions(juniorToken_, juniorTranche_);
        assertHasPermissions(juniorTranche_, juniorOperator_);  
        assertHasPermissions(juniorTranche_, coordinator_);  
        assertHasPermissions(reserve_, juniorTranche_);
        
        assertHasNoPermissions(juniorToken_, juniorTrancheOld_);
        assertHasNoPermissions(reserve_, juniorTrancheOld_);
    }
}
