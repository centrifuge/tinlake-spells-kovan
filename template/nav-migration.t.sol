pragma solidity >=0.5.15 <0.6.0;

import "ds-test/test.sol";
import "./../src/ns-migration.sol";


interface AuthLike {
    function wards(address) external returns(uint);
    function rely(address) external;
}

interface ShelfLike {
    function ceiling(address) external returns(address);
    function subscriber(address) external returns(address);
}

interface PileLike {
   function rates(uint rate) public view returns (uint, uint, uint ,uint48, uint);
}

interface CollectorLike {
    function threshold(address) external returns(address);
}

contract Hevm {
    function warp(uint256) public;
    function store(address, bytes32, bytes32) public;
}

contract TinlakeSpellsTest is DSTest {

    Hevm public hevm;
    TinlakeSpell spell;

    ShelfLike shelf;
    CollectorLike collector;
    PileLike pile;
    NavLike navNew;
    NavLike navOld;

   
    address root_;
    address spell_;
    address navNew_;
    address navOld_;

    function setUp() public {
        spell = new TinlakeSpell();
        spell_ = address(spell);
        root_ = address(spell.ROOT());  
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        navNew_ = spell.NAV_NEW();
        navOld_ = spell.NAV_OLD();
        
        collector = CollectorLike(spell.COLLECTOR);
        shelf = ShelfLike(spell.SHELF);
        pile = PileLike(spell.PILE);
        navNew = NavLike(navNew_);
        navOld = NavLike(navOld_);


        // cheat: give testContract permissions on root contract by overriding storage 
        // storage slot for permissions => keccak256(key, mapslot) (mapslot = 0)
        hevm.store(root_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    }

    function testCast() public {
        assertMigrationNAV();
    }
    
    function testFailCastNoPermissions() public {
        // !!! don't give spell permissions on root contract
        spell.cast();
    }

    function testFailCastTwice() public {
        spell.cast();
        spell.cast();
    }

    function assertHasPermissions(address con, address ward) public {
        uint perm = AuthLike(con).wards(ward);
        assertEq(perm, 1);
    }

    function assertHasNoPermissions(address con, address ward) public {
        uint perm = AuthLike(con).wards(ward);
        assertEq(perm, 0);
    }

    function assertMigrationNAV() public {
        // nfts
        address nft1Registry = 0xaC0c1EF395290288028A0a9FDFc8FDebEbE54a24;
        uint nft1ID = 6773114111684061460499912671089081531599;

        // assert dependencies
        assertEq(navNew.pile(), address(pile));
        asserEq(navNew.shelf(), address(shelf));
        assertEq(shelf.ceiling, navNew_);
        assertEq(shelf.subscriber, navNew_);
        assertEq(collector.threshold, navNew_);

        // assert wards
        assertHasPermissions(navNew_, address(shelf));
        assertHasPermissions(navNew_, spell.ORACLE);
        assertHasPermissions(address(pile), navNew_);
        assertHasNoPermissions(address(pile), navOld_);

        // assert discountRate
        assertEq(navNew.discountRate(), navOld.discountRate());

        // assert writeoffs
        for (uint i = 1000; i <= 1003; i++) {
            (uint rateGroupNew, uint percentageNew) = navNew.writeOffs(i);
            (uint rateGroupOld, uint percentageOld) = navOld.writeOffs(i);
            assertEq(rateGroupNew, rateGroupOld);
            assertEq(percentageNew, percentageOld);
        }

        // assert riskgroups
        for (uint i = 0; i <= 40; i++) {
            assertEq(navNew.thresholdRatio(i), navOld.thresholdRatio(i));
            assertEq(navNew.ceilingRatio(i), navOld.ceilingRatio(i));
            assertEq(navNew.recoveryRatePD(i), navOld.recoveryRatePD(i));
            (, , uint interestRateNew, ,) = PileLike(navNew.pile()).rates(i);
            (, , uint interestRateOld, ,) = PileLike(navOld.pile()).rates(i);
            assertEq(interestRateNew, interestRateOld);
        }

        // assert nft migration
        assertNFTMigration(nft1Registry, nft1ID);

        // assert loan migration
        for (uint i = 0; i <= 1; i++) {
            assertLoanMigration(i);
        }

        // assert nav calculation
         assertEq(navNew.approximatedNAV(), navOld.approximatedNAV());
         assertEq(navNew.currentNAV(), navOld.currentNAV());
    }

    function assertNFTMigration(address registry, address id) public { 
        bytes32 nftID_ = navNew.nftID(registry, tokenId);
        assertEq(navNew.futureValue(nftID_), navOld.futureValue(nftID_));
        assertEq(navNew.nftValues(nftID_), navOld.nftValues(nftID_));
        assertEq(navNew.risk(nftID_), navOld.risk(nftID_));
        assertEq(navNew.maturityDate(nftID_), navOld.maturityDate(nftID_));
    }

    function assertLoanMigration(uint loanId) public { 
        assertEq(navNew.ceiling(loanId), navOld.ceiling(loanId));
        assertEq(navNew.currentCeiling(loanId), navOld.currentCeiling(loanId));
        assertEq(navNew.threshold(loanId), navOld.threshold(loanId));
        assertEq(navNew.borrowed(loanId), navOld.borrowed(loanId));
    
    }

}
