pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "./spell.sol";

interface IAuth {
    function wards(address) external returns(uint);
}

interface IReserve {
    function assessor() external returns(address);
    function currency() external returns(address);
    function shelf() external returns(address);
    function pot() external returns(address);
    function lending() external returns(address);
    function currencyAvailable() external returns(uint);
    function balance_() external returns(uint);
}

interface IAssessor {
    function reserve() external returns(address); 
}

interface ITranche {
    function reserve() external returns(address);
}

interface ICoordinator  {
    function reserve() external returns(address);
}

interface IClerk {
    function reserve() external returns(address); 
}

interface IShelf {
    function distributor() external returns(address);
    function lender() external returns(address);
}

interface ICollector {
    function distributor() external returns(address);
}

interface IHevm {
    function warp(uint256) external;
    function store(address, bytes32, bytes32) external;
}

contract BaseSpellTest is DSTest {

    IHevm public t_hevm;
    TinlakeSpell spell;
   
    address spell_;
    address t_root_;
    address t_registry_;
    
    uint poolReserveDAI;

    function initSpell() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);

        t_registry_ = address(spell.POOL_REGISTRY());
        t_root_ = address(spell.ROOT());  
        t_hevm = IHevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        // cheat: give testContract permissions on root contract by overriding storage 
        // storage slot for permissions => keccak256(key, mapslot) (mapslot = 0)
        t_hevm.store(t_root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
        t_hevm.store(t_registry_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function castSpell() public {
        // give spell permissions on root contract
        AuthLike(t_root_).rely(spell_);
        AuthLike(t_registry_).rely(spell_);
        spell.cast();
    }
}

contract SpellTest is BaseSpellTest {

    function setUp() public {
        initSpell();
    }

    function testCast() public {
        // give spell permissions on root contract
        AuthLike(t_root_).rely(spell_);
        AuthLike(t_registry_).rely(spell_);
        spell.cast();
            
        assertRegistryUpdated();
    }

    function testFailCastNoPermissions() public {
        // !!! don't give spell permissions on root contract
        spell.cast();
    }

    function testFailCastTwice() public {
        // give spell permissions on root contract
        AuthLike(t_root_).rely(spell_);
        AuthLike(t_registry_).rely(spell_);
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

    function assertRegistryUpdated() public {
        assertEq(AuthLike(spell.POOL_REGISTRY()).wards(address(this)), 1);
        (,,string memory data) = PoolRegistryLike(spell.POOL_REGISTRY()).find(spell.ROOT());
        assertEq(data, spell.IPFS_HASH());
    }
}
