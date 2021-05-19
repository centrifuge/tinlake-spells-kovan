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


interface PoolAdminLike {
    function relyAdmin(address) external;
}

interface SpellERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint) external returns (bool);
    function approve(address, uint) external;
}

// spell for: Pezesha fund migration between reserves & PoolAdmin setup
contract TinlakeSpell {

// {
//   "ROOT_CONTRACT": "0x235893Bf9695F68a922daC055598401D832b538b",
//   "TINLAKE_CURRENCY": "0xad3E3Fc59dff318BecEaAb7D00EB4F68b1EcF195",
//   "BORROWER_DEPLOYER": "0xcE03cbb459A299EDa94cc3bEa0001b41606DacE8",
//   "TITLE": "0x33a764604EA9624B4258d7d6dCc08Ce2b8EDa825",
//   "PILE": "0xAAEaCfcCc3d3249f125Ba0644495560309C266cB",
//   "SHELF": "0x4Ca7049E61629407a7E829564C1Dd2538d70182C",
//   "COLLECTOR": "0x813B7c6692A56ff440eD6C638b7357d040bC8958",
//   "FEED": "0xd9b2471F5c7494254b8d52f4aB3146e747ABc9AB",
//   "LENDER_DEPLOYER": "0xb007d3C729f67Db945C69E2d78ff22A4d9218668",
//   "JUNIOR_OPERATOR": "0x54c2B9AE8D556c74677dA2e286c8198b354E7d27",
//   "SENIOR_OPERATOR": "0x2844b69835F182190eB6F602C6cfA2981E143c20",
//   "JUNIOR_TRANCHE": "0xF53EBEDAe8E3e0C77BA12e26c504ee1B0Eccd147",
//   "SENIOR_TRANCHE": "0xB9c79d0721E378D9CF8D18a1e74CB462D57B571F",
//   "JUNIOR_TOKEN": "0xD7a70741B44F5ddaB371c2D2EB9D030A7c1a4BA0",
//   "SENIOR_TOKEN": "0x419A0B6f55Ff030cC50c6C5178d579D5828D8Db8",
//   "JUNIOR_MEMBERLIST": "0x364B69aFc0101Af31089C5aE234D8444C355e8a0",
//   "SENIOR_MEMBERLIST": "0x3e77f47e5e1Ec71fabE473347400A06d9Af13eE3",
//   "ASSESSOR": "0x76343D8BDACAFbabE2a4476ec004Ac3D5501DdF8",
//   "POOL_ADMIN": "0x68c19d14937e43ACa58538628ac2F99e167F2C9C",
//   "COORDINATOR": "0x3e3f323a95018Ee133D47c4841f5AF235E2aF4f5",
//   "RESERVE": "0x5Aa3F927619d522d21AE9522F018030038aDC0E6",
//   "GOVERNANCE": "0xf3BceA7494D8f3ac21585CA4b0E52aa175c24C25",
//   "MAIN_DEPLOYER": "0x1a5a533BcF4ef8A884732056f413114159d03058",
//   "COMMIT_HASH": "578be0709a9ed32697d96bac145567e528a35ddd"
// }

    bool public done;
    string constant public description = "Tinlake NS2 migration mainnet Spell";

    address constant public ROOT = 0x235893Bf9695F68a922daC055598401D832b538b;
    address constant public SENIOR_MEMBERLIST = 0x3e77f47e5e1Ec71fabE473347400A06d9Af13eE3;
    address constant public JUNIOR_MEMBERLIST = 0x364B69aFc0101Af31089C5aE234D8444C355e8a0;
    address constant public POOL_ADMIN = 0x68c19d14937e43ACa58538628ac2F99e167F2C9C;
    address constant public ASSESSOR = 0x76343D8BDACAFbabE2a4476ec004Ac3D5501DdF8;
    // new contracts -> to be migrated
    address constant public RESERVE_NEW = 0x5Aa3F927619d522d21AE9522F018030038aDC0E6;


    address constant public ROOT_OLD = 0x92332a9831AC04275bC0f22b9140b21c72984EB8;
    address constant public RESERVE_OLD = 0x7f5dEa6c463A7250c53F1347f82B506F40E1b0cB;
    
    address constant public TINLAKE_CURRENCY = 0xad3E3Fc59dff318BecEaAb7D00EB4F68b1EcF195; // wCUSD

    // pool admins add correct addresses
    address constant public ADMIN1 = address(0x24730a9D68008c6Bd8F43e60Ed2C00cbe57Ac829); // AO
    address constant public ADMIN2 = address(0x71d9f8CFdcCEF71B59DD81AB387e523E2834F2b8); // Dennis
    address constant public ADMIN3 = address(0xa7Aa917b502d86CD5A23FFbD9Ee32E013015e069); // Lea
    address constant public ADMIN4 = address(0xfEADaD6b75e6C899132587b7Cb3FEd60c8554821); // Aubry
    address constant public ADMIN5 = address(0xC3997Ef807A24af6Ca5Cb1d22c2fD87C6c3b79E8); // Mike
    address constant public ADMIN6 = address(0xd60f7CFC1E051d77031aC21D9DB2F66fE54AE312); // CF
    address constant public ADMIN7 = address(0x46a71eEf8DbcFcbAC7A0e8D5d6B634A649e61fb8); // Devin

    address constant DEPLOYER = address(0x790c2c860DDC993f3da92B19cB440cF8338C59a6);
    address self;

    // permissions to be set
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        SpellTinlakeRootLike root = SpellTinlakeRootLike(ROOT);
        SpellTinlakeRootLike rootOld = SpellTinlakeRootLike(ROOT_OLD);

        self = address(this);
        // set spell as ward on the core contract to be able to wire the new contracts correctly
        root.relyContract(POOL_ADMIN, self);
        rootOld.relyContract(RESERVE_OLD, self);
        root.relyContract(RESERVE_NEW, self);

        // migrateReserve();
        setupPoolAdmin();
    }

    function migrateReserve() internal {    
        // migrate reserve balance
        SpellERC20Like currency = SpellERC20Like(TINLAKE_CURRENCY);
        uint balanceReserve = currency.balanceOf(RESERVE_OLD);
        SpellReserveLike(RESERVE_OLD).payout(balanceReserve);
        currency.transferFrom(self, RESERVE_NEW, balanceReserve);
    }

    function setupPoolAdmin() public {
        PoolAdminLike poolAdmin = PoolAdminLike(POOL_ADMIN);

        // setup dependencies 
        DependLike(POOL_ADMIN).depend("assessor", ASSESSOR);
        DependLike(POOL_ADMIN).depend("seniorMemberlist", SENIOR_MEMBERLIST);
        DependLike(POOL_ADMIN).depend("juniorMemberlist", JUNIOR_MEMBERLIST);

        //setup admins
        poolAdmin.relyAdmin(ADMIN1);
        poolAdmin.relyAdmin(ADMIN2);
        poolAdmin.relyAdmin(ADMIN3);
        poolAdmin.relyAdmin(ADMIN4);
        poolAdmin.relyAdmin(ADMIN5);
        poolAdmin.relyAdmin(ADMIN6);
        poolAdmin.relyAdmin(ADMIN7);

        AuthLike(POOL_ADMIN).deny(DEPLOYER);
    }

}