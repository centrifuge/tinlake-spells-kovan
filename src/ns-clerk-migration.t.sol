pragma solidity >=0.5.15 <0.6.0;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "tinlake-math/math.sol";
import "./ns-clerk-migration.sol";

interface IAuth {
    function wards(address) external returns(uint);
}
interface IReserve {
    function lending() external returns(address);
}

interface IAssessor {
    function clerk() external returns(address);
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

interface IREstrictedToken {
    function hasMember(address member) external returns(bool);
}

interface IMgr {
    function owner() external returns(address);
}

contract Hevm {
    function warp(uint256) public;
    function store(address, bytes32, bytes32) public;
}

contract TinlakeSpellsTest is DSTest, Math {

    Hevm public hevm;
    TinlakeSpell spell;

    IAssessor assessor;
    IReserve reserve;
    IREstrictedToken seniorToken;
    IClerk clerk;
   
    address spell_;
    address root_;
    address reserve_;
    address assessor_;
    address clerk_;
    address coordinator_;
    address seniorTranche_;
    address currency_;
    address mgr_;
    address seniorToken_;
    address spotter_;
    address vat_;

    function setUp() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);

        root_ = address(spell.ROOT());  
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        assessor = IAssessor(spell.ASSESSOR());
        reserve = IReserve(spell.RESERVE());
        clerk = IClerk(spell.CLERK_NEW());
        seniorToken = IREstrictedToken(spell.SENIOR_TOKEN());
        seniorToken_ = spell.SENIOR_TOKEN();
        seniorTranche_ = spell.SENIOR_TRANCHE();

        mgr_ = spell.MGR();
        spotter_ = spell.SPOTTER();
        vat_ = spell.VAT();
        assessor_ = address(assessor);
        reserve_ = address(reserve);
        coordinator_ = spell.COORDINATOR();
        clerk_ = address(clerk);

        // cheat: give testContract permissions on root contract by overriding storage 
        // storage slot for permissions => keccak256(key, mapslot) (mapslot = 0)
        hevm.store(root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function testCast() public {
        // give spell permissions on root contract
        AuthLike(root_).rely(spell_);

        spell.cast();
        assertMigrationClerk();
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

    function assertMigrationClerk() public {
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
        assertEq(reserve.lending(), clerk_);
        assertEq(assessor.clerk(), clerk_);


        // check permissions
        IClerk clerkOld = IClerk(spell.CLERK_OLD());
        address clerkOld_ = address(clerkOld);
       
        assertHasPermissions(clerk_, coordinator_);
        assertHasPermissions(clerk_, reserve_);
        assertHasPermissions(reserve_, clerk_);
        assertHasPermissions(seniorTranche_, clerk_);
        assertHasPermissions(assessor_, clerk_);
        assertHasNoPermissions(reserve_, clerkOld_);
        assertHasNoPermissions(seniorTranche_, clerkOld_);
        assertHasNoPermissions(assessor_, clerkOld_);

        
        // state
        assert(seniorToken.hasMember(clerk_));
        assertEq(IMgr(mgr_).owner(), clerk_); // assert clerk owner of mgr
        //assertEq(clerk.matBuffer(), spell.CLERK_BUFFER()); // has to be public
    }
}
