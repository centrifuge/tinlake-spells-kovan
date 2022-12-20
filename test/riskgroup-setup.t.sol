pragma solidity >=0.6.2;

import "forge-std/Test.sol";
import "src/template/riskgroup-setup.sol";

interface AuthLike {
    function wards(address) external returns(uint);
    function rely(address) external;
}

interface Hevm {
    function warp(uint256) external;
    function store(address, bytes32, bytes32) external;
}

interface PileLike {
    function rates(uint rate) external view returns (uint, uint, uint ,uint48, uint);
}

interface AssessorLike {
    function seniorInterestRate() external returns (uint);
}

contract TinlakeSpellsTest is DSTest {

    Hevm public hevm;
    TinlakeSpell spell;
    
   
    address root_;
    address spell_;
    address constant public PILE = 0x3fC72dA5545E2AB6202D81fbEb1C8273Be95068C;

    function setUp() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);
        root_ = address(spell.ROOT());  
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        
        // cheat: give testContract permissions on root contract by overriding storage 
        // storage slot for permissions => keccak256(key, mapslot) (mapslot = 0)
        hevm.store(root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function testCast() public {

        address assessor_ = spell.ASSESSOR();
        address navFeed_ = spell.NAV_FEED();

        AssessorLike assessor = AssessorLike(assessor_);
        PileLike pile = PileLike(PILE);

        // give spell permissions on root contract
        AuthLike(root_).rely(spell_);

        spell.cast();

        // check seniorInterestRate
        assertEq(assessor.seniorInterestRate(), spell.seniorInterestRate());
        
        //check riskGroups
        (,,uint ratePerSecond24,,) = pile.rates(24);
        assertEq(ratePerSecond24, uint(1000000002853881278538812785));
        (,,uint ratePerSecond25,,) = pile.rates(25);
        assertEq(ratePerSecond25, uint(1000000003012430238457635717));
        (,,uint ratePerSecond26,,) = pile.rates(26);
        assertEq(ratePerSecond26, uint(1000000003012430238457635717));
        (,,uint ratePerSecond27,,) = pile.rates(27);
        assertEq(ratePerSecond27, uint(1000000003170979198376458650));
        (,,uint ratePerSecond28,,) = pile.rates(28);
        assertEq(ratePerSecond28, uint(1000000002853881278538812785));
        (,,uint ratePerSecond29,,) = pile.rates(29);
        assertEq(ratePerSecond29, uint(1000000003012430238457635717));
        (,,uint ratePerSecond30,,) = pile.rates(30);
        assertEq(ratePerSecond30, uint(1000000003012430238457635717));
        (,,uint ratePerSecond31,,) = pile.rates(31);
        assertEq(ratePerSecond31, uint(1000000003170979198376458650));
        (,,uint ratePerSecond32,,) = pile.rates(32);
        assertEq(ratePerSecond32, uint(1000000002853881278538812785));
        (,,uint ratePerSecond33,,) = pile.rates(33);
        assertEq(ratePerSecond33, uint(1000000003012430238457635717));
        (,,uint ratePerSecond34,,) = pile.rates(34);
        assertEq(ratePerSecond34, uint(1000000003012430238457635717));
        (,,uint ratePerSecond35,,) = pile.rates(35);
        assertEq(ratePerSecond35, uint(1000000003170979198376458650));
    }

    function assertHasPermissions(address con, address ward) public {
        uint perm = AuthLike(con).wards(ward);
        assertEq(perm, 1);
    }

    function assertHasNoPermissions(address con, address ward) public {
        uint perm = AuthLike(con).wards(ward);
        assertEq(perm, 0);
    }
}
