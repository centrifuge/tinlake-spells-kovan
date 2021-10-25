pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "./spell.sol";

interface IAuth {
    function wards(address) external returns(uint);
}

interface INavFeed {
    function file(bytes32, uint256, uint256, uint256, uint256, uint256) external;
    function recoveryRatePD(uint) external returns (uint);
    function ceilingRatio(uint) external returns (uint);
    function thresholdRatio(uint) external returns (uint);
    function risk(bytes32 nftID) external returns (uint);
    function nftID(uint loan) external returns (bytes32);
    function nftValues(bytes32 nftID) external returns(uint);
}

interface IPile {
    function rates(uint) external returns (uint,uint,uint,uint,uint);
    function loanRates(uint)external returns(uint);
}

interface IHevm {
    function warp(uint256) external;
    function store(address, bytes32, bytes32) external;
}

contract BaseSpellTest is DSTest {

    IHevm public t_hevm;
    TinlakeSpell spell;

    INavFeed t_navFeed;
    IPile t_pile;
   
    address spell_;
    address t_root_;

    function initSpell() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);

        t_root_ = address(spell.ROOT());  
        t_hevm = IHevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        t_navFeed = INavFeed(spell.NAV_FEED());
        t_pile = IPile(spell.PILE());

        t_hevm.store(t_root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function castSpell() public {
        // give spell permissions on root contract
        AuthLike(t_root_).rely(spell_);
        spell.cast();
    }
}

contract SpellTest is BaseSpellTest {

    uint256 constant ONE = 10**27;

    function setUp() public {
        initSpell();
    }

    function testCast() public {
        // give spell permissions on root contract
        AuthLike(t_root_).rely(spell_);

        uint riskGroupOld = 0;
        uint riskGroupNew = 3;

        // nft2 value 
        uint loanID2 = 2;
        bytes32 nftIDLoan2 = t_navFeed.nftID(loanID2);
        uint nftValueLoan2 = t_navFeed.nftValues(nftIDLoan2);
        
        // nftt3 value 
        uint loanID3 = 3;
        bytes32 nftIDLoan3 = t_navFeed.nftID(loanID3);
        uint nftValueLoan3 = t_navFeed.nftValues(nftIDLoan3);

        assertEq(t_navFeed.risk(nftIDLoan2), riskGroupOld);
        assertEq(t_navFeed.risk(nftIDLoan3), riskGroupOld);
        assertEq(t_pile.loanRates(loanID2), riskGroupOld);
        assertEq(t_pile.loanRates(loanID3), riskGroupOld);

        spell.cast();
            
        assertNewRiskGroups();
        // assert nftValues did not change
        assertEq(nftValueLoan2, t_navFeed.nftValues(nftIDLoan2));
        assertEq(nftValueLoan3, t_navFeed.nftValues(nftIDLoan3));
        // assert loan 2 & 3 got moved to riskGroup 3
        assertEq(t_navFeed.risk(nftIDLoan2), riskGroupNew);
        assertEq(t_navFeed.risk(nftIDLoan3), riskGroupNew);
        // assert loan 2 & 3 have the correct interestRate
        assertEq(t_pile.loanRates(loanID2), riskGroupNew);
        assertEq(t_pile.loanRates(loanID3), riskGroupNew);
    }

    function testFailCastNoPermissions() public {
        // !!! don't give spell permissions on root contract
        spell.cast();
    }

    function testFailCastTwice() public {
        // give spell permissions on root contract
        AuthLike(t_root_).rely(spell_);
        spell.cast();
        spell.cast();
    }

    function assertNewRiskGroups() public {
        // check state
        uint256[3] memory spellRates = [uint256(1000000004122272957889396245), uint256(1000000003488077118214104515), uint256(1000000003170979198376458650)];
        for (uint i = 3; i < 6; i++) {
            uint256 recoveryRatePDs = t_navFeed.recoveryRatePD(i);
            uint256 ceilingRatio = t_navFeed.ceilingRatio(i);
            uint256 thresholdRatio = t_navFeed.thresholdRatio(i);
            (,,uint ratePerSecond,,) = t_pile.rates(i);
            assertEq(recoveryRatePDs, 99.9*10**25);
            assertEq(ceilingRatio, ONE);
            assertEq(thresholdRatio, ONE);
            assertEq(ratePerSecond, spellRates[i-3]);
        }
    }
}
