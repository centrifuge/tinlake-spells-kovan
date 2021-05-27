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

interface MgrLike {
    function lock(uint) external;
}

interface SpellERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint) external returns (bool);
    function approve(address, uint) external;
}

// spell for: ns2 tranche migration
contract TinlakeSpell {

// {
//   "DEPLOYMENT_NAME": "NewSilver 2 mainnet deployment",
//   "ROOT_CONTRACT": "0x53b2d22d07E069a3b132BfeaaD275b10273d381E",
//   "TINLAKE_CURRENCY": "0x6b175474e89094c44da98b954eedeac495271d0f",
//   "BORROWER_DEPLOYER": "0x9137BFdbB43BDf83DB5B8e691B5D2ceBE6475392",
//   "TITLE": "0x07cdD617c53B07208b0371C93a02deB8d8D49C6e",
//   "PILE": "0x3eC5c16E7f2C6A80E31997C68D8Fa6ACe089807f",
//   "SHELF": "0x7d057A056939bb96D682336683C10EC89b78D7CE",
//   "COLLECTOR": "0x62f290512c690a817f47D2a4a544A5d48D1408BE",
//   "FEED": "0x41fAD1Eb242De19dA0206B0468763333BB6C2B3D",
//   "JUNIOR_OPERATOR": "0x4c4Cc6a0573db5823ECAA1d1d65EB64E5E0E5F01",
//   "SENIOR_OPERATOR": "0x230f2E19D6c2Dc0c441c2150D4dD9d67B563A60C",
//   "JUNIOR_TRANCHE": "0x7cD2a6Be6ca8fEB02aeAF08b7F350d7248dA7707",
//   "SENIOR_TRANCHE": "0x636214f455480D19F17FE1aa45B9989C86041767",
//   "JUNIOR_TOKEN": "0x961e1d4c9A7C0C3e05F17285f5FA34A66b62dBb1",
//   "SENIOR_TOKEN": "0xE4C72b4dE5b0F9ACcEA880Ad0b1F944F85A9dAA0",
//   "JUNIOR_MEMBERLIST": "0x42C2483EEE8c1Fe46C398Ac296C59674F9eb88CD",
//   "SENIOR_MEMBERLIST": "0x5B5CFD6E45F1407ABCb4BFD9947aBea1EA6649dA",
//   "ASSESSOR": "0x83E2369A33104120746B589Cc90180ed776fFb91",
//   "ASSESSOR_ADMIN": "0x46470030e1c732A9C2b541189471E47661311375",
//   "COORDINATOR": "0xcC7AFB5DeED34CF67E72d4C53B142F44c9268ab9",
//   "RESERVE": "0xD9E4391cF31638a8Da718Ff0Bf69249Cdc48fB2B",
//   "GOVERNANCE": "0xf3BceA7494D8f3ac21585CA4b0E52aa175c24C25",
//   "POOL_ADMIN": "0x6A82DdF0DF710fACD0414B37606dC9Db05a4F752",
//   "CLERK": "0xA9eCF012dD36512e5fFCD5585D72386E46135Cdd"
//   "MGR":  "0x2474F297214E5d96Ba4C81986A9F0e5C260f445D";
// }

    bool public done;
    string constant public description = "Tinlake NS2 migration mainnet Spell";

    address constant public ROOT = 0x53b2d22d07E069a3b132BfeaaD275b10273d381E;
    address constant public SENIOR_TOKEN = 0xE4C72b4dE5b0F9ACcEA880Ad0b1F944F85A9dAA0;
    address constant public SENIOR_OPERATOR = 0x230f2E19D6c2Dc0c441c2150D4dD9d67B563A60C;
    address constant public SENIOR_MEMBERLIST = 0x5B5CFD6E45F1407ABCb4BFD9947aBea1EA6649dA;
    address constant public JUNIOR_TOKEN = 0x961e1d4c9A7C0C3e05F17285f5FA34A66b62dBb1;
    address constant public JUNIOR_OPERATOR = 0x4c4Cc6a0573db5823ECAA1d1d65EB64E5E0E5F01;
    address constant public JUNIOR_MEMBERLIST = 0x42C2483EEE8c1Fe46C398Ac296C59674F9eb88CD;

    address constant public ASSESSOR = 0x83E2369A33104120746B589Cc90180ed776fFb91;
    address constant public COORDINATOR =  0xcC7AFB5DeED34CF67E72d4C53B142F44c9268ab9;
    address constant public RESERVE = 0xD9E4391cF31638a8Da718Ff0Bf69249Cdc48fB2B;
    
    address constant public CLERK = 0xA9eCF012dD36512e5fFCD5585D72386E46135Cdd;
    address constant public MGR =  0x2474F297214E5d96Ba4C81986A9F0e5C260f445D;
    
    address constant public SENIOR_TRANCHE_OLD = 0xfB30B47c47E2fAB74ca5b0c1561C2909b280c4E5;
    address constant public JUNIOR_TRANCHE_OLD = 0x7cD2a6Be6ca8fEB02aeAF08b7F350d7248dA7707;
    address constant public TINLAKE_CURRENCY = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI

    // new contracts -> to be migrated
    address constant public SENIOR_TRANCHE_NEW = 0x636214f455480D19F17FE1aa45B9989C86041767;
    address constant public JUNIOR_TRANCHE_NEW = 0x636214f455480D19F17FE1aa45B9989C86041767;

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
        root.relyContract(JUNIOR_TRANCHE_OLD, self);
        root.relyContract(SENIOR_TRANCHE_OLD, self);
        root.relyContract(SENIOR_TRANCHE_NEW, self);
        root.relyContract(JUNIOR_TRANCHE_NEW, self);
        root.relyContract(SENIOR_OPERATOR, self);
        root.relyContract(JUNIOR_OPERATOR, self);
        root.relyContract(SENIOR_TOKEN, self);
        root.relyContract(JUNIOR_TOKEN, self);
        root.relyContract(SENIOR_MEMBERLIST, self);
        root.relyContract(JUNIOR_MEMBERLIST, self);

        root.relyContract(ASSESSOR, self);
        root.relyContract(COORDINATOR, self);
        root.relyContract(RESERVE, self);

        root.relyContract(CLERK, self);
        root.relyContract(MGR, self);
    
        // contract migration --> assumption: root contract is already ward on the new contracts
        migrateTranches();
    }

    function migrateTranches() internal {
    
        // senior
        TrancheLike tranche = TrancheLike(SENIOR_TRANCHE_NEW);
        require((tranche.totalSupply() == 0 && tranche.totalRedeem() == 0), "tranche-has-orders");

        // dependencies
        DependLike(SENIOR_TRANCHE_NEW).depend("reserve", RESERVE);
        DependLike(SENIOR_TRANCHE_NEW).depend("epochTicker", COORDINATOR);
        DependLike(SENIOR_OPERATOR).depend("tranche", SENIOR_TRANCHE_NEW);
        DependLike(ASSESSOR).depend("seniorTranche", SENIOR_TRANCHE_NEW);
        DependLike(COORDINATOR).depend("seniorTranche", SENIOR_TRANCHE_NEW);
        DependLike(CLERK).depend("tranche", SENIOR_TRANCHE_NEW);
        FileLike(MGR).file("tranche", SENIOR_TRANCHE_NEW);

        // permissions
        AuthLike(SENIOR_TRANCHE_NEW).rely(SENIOR_OPERATOR);
        AuthLike(SENIOR_TRANCHE_NEW).rely(COORDINATOR);
        AuthLike(SENIOR_TRANCHE_NEW).rely(CLERK);

        AuthLike(SENIOR_TOKEN).deny(SENIOR_TRANCHE_OLD);
        AuthLike(SENIOR_TOKEN).rely(SENIOR_TRANCHE_NEW);
        AuthLike(RESERVE).deny(SENIOR_TRANCHE_OLD);
        AuthLike(RESERVE).rely(SENIOR_TRANCHE_NEW);

        // junior
        TrancheLike tranche = TrancheLike(SENIOR_TRANCHE_NEW);
        require((tranche.totalSupply() == 0 && tranche.totalRedeem() == 0), "tranche-has-orders");

        // dependencies
        DependLike(JUNIOR_TRANCHE_NEW).depend("reserve", RESERVE);
        DependLike(JUNIOR_TRANCHE_NEW).depend("epochTicker", COORDINATOR);
        DependLike(JUNIOR_OPERATOR).depend("tranche", JUNIOR_TRANCHE_NEW);
        DependLike(ASSESSOR).depend("seniorTranche", JUNIOR_TRANCHE_NEW);
        DependLike(COORDINATOR).depend("seniorTranche", JUNIOR_TRANCHE_NEW);
        
        // permissions
        AuthLike(JUNIOR_TRANCHE_NEW).rely(JUNIOR_OPERATOR);
        AuthLike(JUNIOR_TRANCHE_NEW).rely(COORDINATOR);
        AuthLike(JUNIOR_TRANCHE_NEW).rely(CLERK);

        AuthLike(JUNIOR_TOKEN).deny(JUNIOR_TRANCHE_OLD);
        AuthLike(JUNIOR_TOKEN).rely(JUNIOR_TRANCHE_NEW);
        AuthLike(RESERVE).deny(JUNIOR_TRANCHE_OLD);
        AuthLike(RESERVE).rely(JUNIOR_TRANCHE_NEW);
    }
}