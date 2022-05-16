pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "./spell.sol";
import "../lib/tinlake-rpc-tests/src/contracts/rpc-tests.sol";

interface IHevm {
    function warp(uint256) external;
    function store(address, bytes32, bytes32) external;
}
contract SpellRPCTest is TinlakeRPCTests {
    IHevm t_hevm;
    // function setUp() public override {
    //     // cast spell before running the tinlake rpc tests
    //     t_hevm = IHevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    //     TinlakeSpell spell = new TinlakeSpell();
    //     address spell_ = address(spell);
    //     t_hevm.store(spell.ROOT(), keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    //     t_hevm.store(spell.POOL_REGISTRY(), keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
    //     // give spell permissions on root contract
    //     AuthLike(address(spell.ROOT())).rely(spell_);
    //     AuthLike(address(spell.POOL_REGISTRY())).rely(spell_);
    //     spell.cast();

    //     // add new contract addresses here that should override the old contracts
    //     CLERK = spell.CLERK();
    //     COORDINATOR = spell.COORDINATOR();
    //     POOL_ADMIN = spell.POOL_ADMIN();
       
    //     initRPC();

    // }

    // function testFullCycle() public {
    //     // make sure epoch can be closed
    //     t_hevm.warp(block.timestamp + 1 days);
    //     runLoanCycleWithMaker();
    // }

}
