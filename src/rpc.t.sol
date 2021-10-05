pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "./spell.t.sol";
import "../lib/tinlake-rpc-tests/src/contracts/rpc-tests.sol";


contract SpellRPCTest is TinlakeRPCTests, BaseSpellTest {
    function setUp() public override {
        initSpell();
        castSpell();

        // // rpc tests should use the new addresses from the spell
        // RESERVE = spell.RESERVE_NEW();
        // emit log_named_address("reserve", RESERVE);
    
        initRPC();
    }
}
