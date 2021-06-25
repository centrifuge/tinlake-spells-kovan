// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "./addresses.sol";

interface SpellTinlakeRootLike {
    function relyContract(address, address) external;
}
interface SpellReserveLike {
    function payout(uint currencyAmount) external;
}

interface DependLike {
    function depend(bytes32, address) external;
}

interface AuthLike {
    function rely(address) external;
    function deny(address) external;
    function wards(address) external returns(uint);
}

interface MigrationLike {
    function migrate(address) external;
}

interface SpellERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint) external returns (bool);
    function approve(address, uint) external;
}

contract TinlakeSpell is Addresses {

    bool public done;
    string constant public description = "Tinlake Reserve migration spell";

    // TODO: replace the following address
    address constant public RESERVE_NEW = 0x1f5Fa2E665609CE4953C65CE532Ac8B47EC97cD5;

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        SpellTinlakeRootLike root = SpellTinlakeRootLike(ROOT);

        // set spell as ward on the core contract to be able to wire the new contracts correctly
        root.relyContract(SHELF, address(this));
        root.relyContract(COLLECTOR, address(this));
        root.relyContract(JUNIOR_TRANCHE, address(this));
        root.relyContract(SENIOR_TRANCHE, address(this));
        root.relyContract(CLERK, address(this));
        root.relyContract(ASSESSOR, address(this));
        root.relyContract(COORDINATOR, address(this));
        root.relyContract(RESERVE, address(this));
        root.relyContract(RESERVE_NEW, address(this));
        
        migrateReserve();
    }

    function migrateReserve() internal {
        MigrationLike(RESERVE_NEW).migrate(RESERVE);

        // migrate dependencies 
        DependLike(RESERVE_NEW).depend("assessor", ASSESSOR);
        DependLike(RESERVE_NEW).depend("currency", TINLAKE_CURRENCY);
        DependLike(RESERVE_NEW).depend("shelf", SHELF);
        DependLike(RESERVE_NEW).depend("lending", CLERK);
        DependLike(RESERVE_NEW).depend("pot", RESERVE_NEW);

        DependLike(SHELF).depend("distributor", RESERVE_NEW);
        DependLike(SHELF).depend("lender", RESERVE_NEW);
        DependLike(COLLECTOR).depend("distributor", RESERVE_NEW);
        DependLike(JUNIOR_TRANCHE).depend("reserve", RESERVE_NEW);
        DependLike(SENIOR_TRANCHE).depend("reserve", RESERVE_NEW);
        DependLike(CLERK).depend("reserve", RESERVE_NEW); 
        DependLike(ASSESSOR).depend("reserve", RESERVE_NEW);
        DependLike(COORDINATOR).depend("reserve", RESERVE_NEW);

        // migrate permissions
        AuthLike(RESERVE_NEW).rely(JUNIOR_TRANCHE);
        AuthLike(RESERVE_NEW).rely(SENIOR_TRANCHE);
        AuthLike(RESERVE_NEW).rely(ASSESSOR);
        AuthLike(RESERVE_NEW).rely(CLERK);

        AuthLike(CLERK).rely(RESERVE_NEW);
        AuthLike(CLERK).deny(RESERVE);
        AuthLike(ASSESSOR).rely(RESERVE_NEW);
        AuthLike(ASSESSOR).deny(RESERVE);
        
        // migrate reserve balance
        SpellERC20Like currency = SpellERC20Like(TINLAKE_CURRENCY);
        uint balanceReserve = currency.balanceOf(RESERVE);
        SpellReserveLike(RESERVE).payout(balanceReserve);
        currency.transferFrom(address(this), RESERVE_NEW, balanceReserve);
    }
}
