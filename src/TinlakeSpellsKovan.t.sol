pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./TinlakeSpellsKovan.sol";

contract TinlakeSpellsKovanTest is DSTest {
    TinlakeSpellsKovan kovan;

    function setUp() public {
        kovan = new TinlakeSpellsKovan();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
