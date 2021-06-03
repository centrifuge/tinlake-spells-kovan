pragma solidity >=0.5.15 <0.6.0;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "tinlake-math/math.sol";
import "./spell.t.sol";
import "../lib/tinlake-rpc-tests/src/contracts/rpc-tests.sol";


contract SpellRPCTest is TinlakeRPCTests, BaseSpellTest  {
    function setUp() public {
        initSpell();
        castSpell();

        // rpc tests should use the new addresses from the spell
        SENIOR_TRANCHE = spell.SENIOR_TRANCHE_NEW();
        emit log_named_address("seniorTranche", SENIOR_TRANCHE);
        JUNIOR_TRANCHE = spell.JUNIOR_TRANCHE_NEW();

        initRPC();
    }
}
