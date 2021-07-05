// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "./addresses.sol";

interface SpellTinlakeRootLike {
    function relyContract(address, address) external;
}

interface SpellMemberlistLike {
    function updateMember(address, uint) external;
}

interface SpellReserveLike {
    function payout(uint currencyAmount) external;
}

interface DependLike {
    function depend(bytes32, address) external;
}

interface FileLike {
    function file(bytes32, uint) external;
    function file(bytes32, address) external;
}

interface AuthLike {
    function rely(address) external;
    function deny(address) external;
}

interface MigrationLike {
    function migrate(address) external;
}

interface PoolAdminLike {
    function relyAdmin(address) external;
}

interface MgrLike {
    function lock(uint) external;
}

interface SpellERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint) external returns (bool);
    function approve(address, uint) external;
}

interface NAVFeedLike {
    function file(bytes32, uint) external;
    function discountRate() external view returns (uint256);
}

// spell for: ns2 coordinator migration
contract TinlakeSpell is Addresses {

    bool public done;
    string constant public description = "Tinlake NS2 coordinator migration mainnet Spell";

    address constant public COORDINATOR_NEW = 0x22a1caca2EE82e9cE7Ef900FD961891b66deB7cA;

    uint[4] discountRates = [1000000002243467782851344495, 1000000002108701166920345002, 1000000001973934550989345509, 1000000001839167935058346017];
    uint[4] timestamps;
    bool[4] rateAlreadySet = [false, false, false, false];
    
    address self;

    // permissions to be set
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        SpellTinlakeRootLike root = SpellTinlakeRootLike(ROOT_CONTRACT);
        self = address(this);

        // set spell as ward on the core contract to be able to wire the new contracts correctly
        root.relyContract(JUNIOR_TRANCHE, self);
        root.relyContract(SENIOR_TRANCHE, self);
        root.relyContract(ASSESSOR, self);
        root.relyContract(RESERVE, self);
        root.relyContract(COORDINATOR_NEW, self);
        root.relyContract(FEED, self);
    
        // contract migration --> assumption: root contract is already ward on the new contracts
        migrateCoordinator();

        timestamps = [
            block.timestamp + 0 days,
            block.timestamp + 4 days,
            block.timestamp + 8 days,
            block.timestamp + 12 days
        ];

        setDiscount(0);
    }

    function migrateCoordinator() internal {
         // migrate dependencies 
        DependLike(COORDINATOR_NEW).depend("assessor", ASSESSOR);
        DependLike(COORDINATOR_NEW).depend("juniorTranche", JUNIOR_TRANCHE);
        DependLike(COORDINATOR_NEW).depend("seniorTranche", SENIOR_TRANCHE);
        DependLike(COORDINATOR_NEW).depend("reserve", RESERVE);
        
        DependLike(JUNIOR_TRANCHE).depend("epochTicker", COORDINATOR_NEW);
        DependLike(SENIOR_TRANCHE).depend("epochTicker", COORDINATOR_NEW);
        DependLike(CLERK).depend("coordinator", COORDINATOR_NEW);

        // migrate permissions
        AuthLike(ASSESSOR).rely(COORDINATOR_NEW); 
        AuthLike(ASSESSOR).deny(COORDINATOR);
        AuthLike(JUNIOR_TRANCHE).rely(COORDINATOR_NEW); 
        AuthLike(JUNIOR_TRANCHE).deny(COORDINATOR); 
        AuthLike(SENIOR_TRANCHE).rely(COORDINATOR_NEW);
        AuthLike(SENIOR_TRANCHE).deny(COORDINATOR);

        // migrate state
        MigrationLike(COORDINATOR_NEW).migrate(COORDINATOR);
    }

    function setDiscount(uint i) public {
        require(block.timestamp >= timestamps[i], "not-yet-executable");
        require(i == 0 || NAVFeedLike(FEED).discountRate() == discountRates[i-1], "incorrect-execution-order");
        require(rateAlreadySet[i] == false, "already-executed");

        rateAlreadySet[i] = true;
        NAVFeedLike(FEED).file("discountRate", discountRates[i]);
    }
}