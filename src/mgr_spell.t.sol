pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "./mgr_spell.sol";


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
    function end() external returns(address);
}

contract BaseSpellTest is DSTest {
    IHevm public hevm;
    TinlakeSpell spell;

    IMgr ns_mgr;
    IMgr htc_mgr;
    IMgr ff_mgr;
    IMgr cf_mgr;

    address ns_root_;
    address htc_root_;
    address ff_root_;
    address cf_root_;

    address spell_;

    
    function initSpell() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);
        ns_mgr = IMgr(spell.NS2_MGR());
        htc_mgr = IMgr(spell.HTC2_MGR());
        ff_mgr = IMgr(spell.FF1_MGR());
        cf_mgr = IMgr(spell.CF4_MGR());
        
        ns_root_ = spell.NS2_ROOT();
        htc_root_ = spell.HTC2_ROOT();
        ff_root_ = spell.FF1_ROOT();
        cf_root_ = spell.CF4_ROOT();

        hevm = IHevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        hevm.store(ns_root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
        hevm.store(htc_root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
        hevm.store(ff_root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
        hevm.store(cf_root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function castSpell() public {  
        spell.cast();
    }
}

contract SpellTest is BaseSpellTest {

    uint256 constant ONE = 10**27;

    function setUp() public {
        initSpell();
        // check spell permissions
        assertHasNoPermissions(address(spell), address(this)); // assert deployer no permissions
        assertHasPermissions(address(spell), spell.ADMIN()); // assert deployer no permissions
    }

    function testFailCastDeactivated() public {
        // set test contract as admin on spell
        hevm.store(address(spell), keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
        spell.file("active", false);
        castSpell();
    } 

    function testFailCastNoPermissions() public {
        castSpell();
        address END = LogLike(spell.CHAINLOG()).getAddress("MCD_END");
        assertEq(ns_mgr.end(), END);
        assertEq(htc_mgr.end(), END);
        assertEq(ff_mgr.end(), END);
        assertEq(cf_mgr.end(), END);
    }

    function testCast() public {
        AuthLike(ns_root_).rely(spell_);
        AuthLike(htc_root_).rely(spell_);
        AuthLike(ff_root_).rely(spell_);
        AuthLike(cf_root_).rely(spell_);

        castSpell();
        address END = LogLike(spell.CHAINLOG()).getAddress("MCD_END");
        assertEq(ns_mgr.end(), END);
        assertEq(htc_mgr.end(), END);
        assertEq(ff_mgr.end(), END);
        assertEq(cf_mgr.end(), END);
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

