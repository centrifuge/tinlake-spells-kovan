pragma solidity ^0.6.7;

import "ds-test/test.sol";
import "./../src/spell.sol";

contract TinlakeSpellsTest is DSTest {
    TinlakeSpells spells;

    function setUp() public {
        spells = new TinlakeSpells();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
