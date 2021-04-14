// Copyright (C) 2020 Centrifuge
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.5.15 <0.6.0;
pragma experimental ABIEncoderV2;

// TODO: split interfaces between tests and spell. Exclude all the function that afre only used in tests
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

interface TrancheLike {
    function totalSupply() external returns(uint);
    function totalRedeem() external returns(uint);
}

interface PoolAdminLike {
    function relyAdmin(address) external;
}

interface SpellERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint) external returns (bool);
    function approve(address, uint) external;
}

// spell for: ns2 migration to rev pool with maker support
// - migrate state & swap contracts: assessor, reserve, coordinator
// - add & wire mkr adapter contracts: clerk & mgr, spotter, vat
contract TinlakeSpell {


    // "ROOT_CONTRACT": "0xc5BfCcBe24b037459922F70ADA6706638A550338",
    // "TINLAKE_CURRENCY": "0x99E21e1e7D99d06F780666A3BE6Ba178De04B0a9",
    // "TITLE": "0x3C8ECc6Ff39cA4b38e622e70a34A2C4C147939ce",
    // "PILE": "0x44761ed4255B3392C323233ac283c9D92fC7B722",
    // "SHELF": "0x8C8715CfCa29e7f0e767D3945233FfA36b5CE44E",
    // "COLLECTOR": "0xAF0A1a10330aA6239d32f08d38df6b9EA4a35E93",
    // "FEED": "0x34165A6a31Cd745Ff820007821400287A871003e",
    // "JUNIOR_OPERATOR": "0xD8dB19456edAb5DcDFf099C682E578beb674B81b",
    // "SENIOR_OPERATOR": "0x4e4474c61C4A380B3f041B7aDc72848dB36BB667",
    // "JUNIOR_TRANCHE": "0x1467434d7DC058dC0a34A681Cc1A09e78c00f8b0",
    // "SENIOR_TRANCHE": "0x0c26010e359E2645Ba00AAa859384a58D5617De9",
    // "JUNIOR_TOKEN": "0x1526Dce6A9EE563611f03C89961C48C83B113dFc",
    // "SENIOR_TOKEN": "0x28F56bce6Cdd708EB173Fc3763Ee62dEbd3674Fc",
    // "JUNIOR_MEMBERLIST": "0x20104E5E0aD78245cfa258217F857dd00Ab43b65",
    // "SENIOR_MEMBERLIST": "0xBBfBde40aF416e6A112fAAc887eA19e602cE3999",
    // "ASSESSOR": "0x6cC7A93d2B02B3181b048CDCfe2805aCb6e90B37",
    // "ASSESSOR_ADMIN": "0xBFe498D0a0232cE605a04be741791da2aF14E9f3",
    // "COORDINATOR": "0x62704f83C8f307568FD70714C27a630f7aA9bf74",
    // "RESERVE": "0xcaa4473662AA0c93c7F3C25a71aAEc0a48d62A3c",
    // "ACTIONS": "0x60cc4a2868559e513112f0742e6f546d339ea17b",
    // "PROXY_REGISTRY": "0xb0cd959bbbe799ba7d18c7d28008553a7b47a04c",
    // "CLAIM_RAD": "0x297237e17F327f8e5C8dEd78b15761A7D513353b"

    bool public done;
    string constant public description = "Tinlake NS2 migration kovan Spell";

    address constant public ROOT = 0xc5BfCcBe24b037459922F70ADA6706638A550338;
    address constant public SHELF = 0x8C8715CfCa29e7f0e767D3945233FfA36b5CE44E;
    address constant public COLLECTOR = 0xAF0A1a10330aA6239d32f08d38df6b9EA4a35E93;
    address constant public SENIOR_TOKEN = 0x28F56bce6Cdd708EB173Fc3763Ee62dEbd3674Fc;
    address constant public SENIOR_MEMBERLIST = 0xBBfBde40aF416e6A112fAAc887eA19e602cE3999;
    address constant public SENIOR_OPERATOR = 0x4e4474c61C4A380B3f041B7aDc72848dB36BB667;
    address constant public JUNIOR_TRANCHE = 0x1467434d7DC058dC0a34A681Cc1A09e78c00f8b0;
    address constant public JUNIOR_MEMBERLIST = 0x20104E5E0aD78245cfa258217F857dd00Ab43b65;
    address constant public POOL_ADMIN = 0xD8A9fDDF542BF19D5117528055370EE1519DDBF6;
    address constant public NAV = 0x34165A6a31Cd745Ff820007821400287A871003e;
    address constant public SENIOR_TRANCHE_OLD = 0x0c26010e359E2645Ba00AAa859384a58D5617De9;
    address constant public ASSESSOR_OLD = 0x6cC7A93d2B02B3181b048CDCfe2805aCb6e90B37;
    address constant public COORDINATOR_OLD = 0x62704f83C8f307568FD70714C27a630f7aA9bf74;
    address constant public RESERVE_OLD = 0xcaa4473662AA0c93c7F3C25a71aAEc0a48d62A3c;
    
    address constant public TINLAKE_CURRENCY = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa; // DAI

    // new contracts -> to be migrated
    address constant public COORDINATOR_NEW = 0xDDC63365BA58659c62c028426A5fD0eBFA3332ed;
    address constant public ASSESSOR_NEW  = 0x1E5Dca2f19d9546dBb235122cB8f756Ca2B865B7;
    address constant public RESERVE_NEW = 0x0537bac749D428E4c01BceA7102D83C758449AC1;
    address constant public SENIOR_TRANCHE_NEW = 0x67F50a32226e5c9b6f7464A287c3A2644c8F04A3;

    // adapter contracts -> to be integrated
    address constant public CLERK = 0x27677E6Aff3370a91789Da7E2fC1384dBe6cc422;
    address constant public MGR =  0x2CfADbd094a4D650049C53832B15842a3c59Db34;
    // mkr kovan contracts from release 1.2.10 https://changelog.makerdao.com/releases/kovan/1.2.10/contracts.json
    address constant public SPOTTER = 0x3a042de6413eDB15F2784f2f97cC68C7E9750b2D;
    address constant public VAT = 0xbA987bDB501d131f766fEe8180Da5d81b34b69d9;
    address constant public JUG = 0xcbB7718c9F39d05aEEDE1c472ca8Bf804b2f1EaD;
    // rwa contracts
    address constant public URN = 0xdFb4E887D89Ac14b0337C9dC05d8f5e492B9847C;
    address constant public LIQ = 0x2881c5dF65A8D81e38f7636122aFb456514804CC;

    // Todo: add correct addresses
    address constant public ADMIN1 = address(0x0A735602a357802f553113F5831FE2fbf2F0E2e0);

    uint constant public ASSESSOR_MIN_SENIOR_RATIO = 0;
    uint constant public MAT_BUFFER = 1.06 * 10**27;
    address self;

    // permissions to be set
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        SpellTinlakeRootLike root = SpellTinlakeRootLike(ROOT);
        self = address(this);
        // set spell as ward on the core contract to be able to wire the new contracts correctly
        root.relyContract(SHELF, self);
        root.relyContract(COLLECTOR, self);
        root.relyContract(JUNIOR_TRANCHE, self);
        root.relyContract(SENIOR_OPERATOR, self);
        root.relyContract(SENIOR_TRANCHE_OLD, self);
        root.relyContract(SENIOR_TOKEN, self);
        root.relyContract(SENIOR_TRANCHE_NEW, self);
        root.relyContract(SENIOR_MEMBERLIST, self);
        root.relyContract(JUNIOR_MEMBERLIST, self);
        root.relyContract(CLERK, self);
        root.relyContract(POOL_ADMIN, self);
        root.relyContract(ASSESSOR_NEW, self);
        root.relyContract(COORDINATOR_NEW, self);
        root.relyContract(RESERVE_OLD, self);
        root.relyContract(RESERVE_NEW, self);
        root.relyContract(MGR, self);
    
        // todo: remove for mainnet
        DependLike(SHELF).depend("token", TINLAKE_CURRENCY);
        DependLike(JUNIOR_TRANCHE).depend("currency", TINLAKE_CURRENCY);

        // contract migration --> assumption: root contract is already ward on the new contracts
        migrateAssessor();
        migrateCoordinator();
        migrateReserve();
        migrateTranche();
        integrateAdapter();
        setupPoolAdmin();

        // for mkr integration: set minSeniorRatio in Assessor to 0      
        FileLike(ASSESSOR_NEW).file("minSeniorRatio", ASSESSOR_MIN_SENIOR_RATIO);
    }

    function migrateAssessor() internal {
        MigrationLike(ASSESSOR_NEW).migrate(ASSESSOR_OLD);
        // migrate dependencies 
        DependLike(ASSESSOR_NEW).depend("navFeed", NAV);
        DependLike(ASSESSOR_NEW).depend("juniorTranche", JUNIOR_TRANCHE);
        DependLike(ASSESSOR_NEW).depend("seniorTranche", SENIOR_TRANCHE_NEW);
        DependLike(ASSESSOR_NEW).depend("reserve", RESERVE_NEW);
        DependLike(ASSESSOR_NEW).depend("clerk", CLERK); 
        // migrate permissions
        AuthLike(ASSESSOR_NEW).rely(COORDINATOR_NEW); 
        AuthLike(ASSESSOR_NEW).rely(RESERVE_NEW);
    }

    function migrateCoordinator() internal {
        MigrationLike(COORDINATOR_NEW).migrate(COORDINATOR_OLD);
         // migrate dependencies 
        DependLike(COORDINATOR_NEW).depend("assessor", ASSESSOR_NEW);
        DependLike(COORDINATOR_NEW).depend("juniorTranche", JUNIOR_TRANCHE);
        DependLike(COORDINATOR_NEW).depend("seniorTranche", SENIOR_TRANCHE_NEW);
        DependLike(COORDINATOR_NEW).depend("reserve", RESERVE_NEW);
        
        DependLike(JUNIOR_TRANCHE).depend("epochTicker", COORDINATOR_NEW);

        // migrate permissions
        AuthLike(JUNIOR_TRANCHE).rely(COORDINATOR_NEW); 
        AuthLike(JUNIOR_TRANCHE).deny(COORDINATOR_OLD); 
        AuthLike(SENIOR_TRANCHE_NEW).rely(COORDINATOR_NEW);
    }

    function migrateReserve() internal {
        MigrationLike(RESERVE_NEW).migrate(RESERVE_OLD);
        // migrate dependencies 
        DependLike(RESERVE_NEW).depend("assessor", ASSESSOR_NEW);
        DependLike(RESERVE_NEW).depend("currency", TINLAKE_CURRENCY);
        DependLike(RESERVE_NEW).depend("shelf", SHELF);
        DependLike(RESERVE_NEW).depend("lending", CLERK);
        DependLike(RESERVE_NEW).depend("pot", RESERVE_NEW);

        DependLike(SHELF).depend("distributor", RESERVE_NEW);
        DependLike(SHELF).depend("lender", RESERVE_NEW);
        DependLike(COLLECTOR).depend("distributor", RESERVE_NEW);
        DependLike(JUNIOR_TRANCHE).depend("reserve", RESERVE_NEW);
        // migrate permissions
        AuthLike(RESERVE_NEW).rely(JUNIOR_TRANCHE);
        AuthLike(RESERVE_NEW).rely(SENIOR_TRANCHE_NEW);
        AuthLike(RESERVE_NEW).rely(ASSESSOR_NEW);
        
        // migrate reserve balance
        SpellERC20Like currency = SpellERC20Like(TINLAKE_CURRENCY);
        uint balanceReserve = currency.balanceOf(RESERVE_OLD);
        SpellReserveLike(RESERVE_OLD).payout(balanceReserve);
        currency.transferFrom(self, RESERVE_NEW, balanceReserve);
    }

    function migrateTranche() internal {
        TrancheLike tranche = TrancheLike(SENIOR_TRANCHE_NEW);
        require((tranche.totalSupply() == 0 && tranche.totalRedeem() == 0), "tranche-has-orders");
        DependLike(SENIOR_TRANCHE_NEW).depend("reserve", RESERVE_NEW);
        DependLike(SENIOR_TRANCHE_NEW).depend("epochTicker", COORDINATOR_NEW);
        DependLike(SENIOR_OPERATOR).depend("tranche", SENIOR_TRANCHE_NEW);

        AuthLike(SENIOR_TOKEN).deny(SENIOR_TRANCHE_OLD);
        AuthLike(SENIOR_TOKEN).rely(SENIOR_TRANCHE_NEW);
        AuthLike(SENIOR_TRANCHE_NEW).rely(SENIOR_OPERATOR);
    }

    function integrateAdapter() internal {
        // dependencies
        DependLike(CLERK).depend("assessor", ASSESSOR_NEW);
        DependLike(CLERK).depend("mgr", MGR);
        DependLike(CLERK).depend("coordinator", COORDINATOR_NEW);
        DependLike(CLERK).depend("reserve", RESERVE_NEW); 
        DependLike(CLERK).depend("tranche", SENIOR_TRANCHE_NEW);
        DependLike(CLERK).depend("collateral", SENIOR_TOKEN);
        DependLike(CLERK).depend("spotter", SPOTTER);
        DependLike(CLERK).depend("vat", VAT);
        DependLike(CLERK).depend("jug", JUG);

        FileLike(CLERK).file("buffer", MAT_BUFFER);

        // permissions
        AuthLike(CLERK).rely(COORDINATOR_NEW);
        AuthLike(CLERK).rely(RESERVE_NEW);
        AuthLike(SENIOR_TRANCHE_NEW).rely(CLERK);
        AuthLike(RESERVE_NEW).rely(CLERK);
        AuthLike(ASSESSOR_NEW).rely(CLERK);

        // currency
        SpellMemberlistLike(SENIOR_MEMBERLIST).updateMember(CLERK, uint(-1));
        SpellMemberlistLike(SENIOR_MEMBERLIST).updateMember(MGR, uint(-1));

        // setup mgr
        AuthLike(MGR).rely(CLERK);
        FileLike(MGR).file("urn", URN);
        FileLike(MGR).file("liq", LIQ);
        FileLike(MGR).file("owner", CLERK);
        FileLike(MGR).file("pool", SENIOR_OPERATOR);
        FileLike(MGR).file("tranche", SENIOR_TRANCHE_NEW);
        // todo remove mainnet
        FileLike(MGR).file("gem", SENIOR_TOKEN);
    }

    function setupPoolAdmin() public {
        PoolAdminLike poolAdmin = PoolAdminLike(POOL_ADMIN);

        // setup dependencies 
        DependLike(POOL_ADMIN).depend("assessor", ASSESSOR_NEW);
        DependLike(POOL_ADMIN).depend("lending", CLERK);
        DependLike(POOL_ADMIN).depend("seniorMemberlist", SENIOR_MEMBERLIST);
        DependLike(POOL_ADMIN).depend("juniorMemberlist", JUNIOR_MEMBERLIST);

        // setup permissions
        AuthLike(ASSESSOR_NEW).rely(POOL_ADMIN);
        AuthLike(CLERK).rely(POOL_ADMIN);
        AuthLike(JUNIOR_MEMBERLIST).rely(POOL_ADMIN);
        AuthLike(SENIOR_MEMBERLIST).rely(POOL_ADMIN);

        //setup admins
        poolAdmin.relyAdmin(ADMIN1);
    }

}