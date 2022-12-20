pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "forge-std/Test.sol";
import "src/spell.sol";
import "tinlake-rpc-tests/src/contracts/rpc-tests.sol";

contract SpellRPCTest is TinlakeRPCTests, Test {
    function setUp() public override {
        // cast spell before running the tinlake rpc tests
        TinlakeSpell spell = new TinlakeSpell();
        address spell_ = address(spell);
        vm.store(spell.ROOT(), keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
        // give spell permissions on root contract
        AuthLike(address(spell.ROOT())).rely(spell_);
        spell.cast();
       
        initRPC();
    }

    function testFullCycle() public {
        // make sure epoch can be closed
        vm.warp(block.timestamp + 1 days);
        runLoanCycleWithMaker();
    }

}
