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

interface TinlakeRootLike {
    function relyContract(address, address) external;
    function denyContract(address, address) external;
}

interface FileLike {
    function file(bytes32, uint) external;
    function file(bytes32, address) external;
}

interface NAVFeedLike {
    function file(bytes32 name, uint value) external;
    function file(bytes32 name, uint risk_, uint thresholdRatio_, uint ceilingRatio_, uint rate_, uint recoveryRatePD_) external;
    function discountRate() external returns(uint);
}

// This spell makes changes to the tinlake mainnet CF4 deployment:
// set senior interest rate to 6%
// adds new risk groups to nav feed 24-35
contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake CF4 Mainnet Spell - 3";

    // MAINNET ADDRESSES
    // The contracts in this list should correspond to a tinlake deployment
    // https://github.com/centrifuge/tinlake-pool-config/blob/master/mainnet-production.json

    address constant public ROOT = 0xdB3bC9fB1893222d266762e9fF857EB74D75c7D6;
    address constant public ASSESSOR = 0x6aaf2EE5b2B62fb9E29E021a1bF3B381454d900a;
    address constant public NAV_FEED = 0x69504da6B2Cd8320B9a62F3AeD410a298d3E7Ac6;
                                               

    // change dropAPR to 6%               
    uint constant public seniorInterestRate = uint(1000000001902587519025875190);
    uint256 constant ONE = 10**27;
    address self;
    
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
       TinlakeRootLike root = TinlakeRootLike(address(ROOT));
       NAVFeedLike navFeed = NAVFeedLike(address(NAV_FEED));
       self = address(this);
        // add permissions  
        // Assessor
        root.relyContract(ASSESSOR, self);
        // NavFeed 
        root.relyContract(NAV_FEED, self); // required to file riskGroups & change discountRate

        // file drop interest rate
        FileLike(ASSESSOR).file("seniorInterestRate",seniorInterestRate);
       
        // risk group: 24 - ADF3, APR: 9%           
        navFeed.file("riskGroup", 24, ONE, ONE, uint(1000000002853881278538812785), 99.93*10**25);
        // risk group: 25 - BDF3, APR: 9.5%        
        navFeed.file("riskGroup", 25, ONE, ONE, uint(1000000003012430238457635717), 99.9*10**25);
        // risk group: 26 - CDF3, APR: 9.5%
        navFeed.file("riskGroup", 26, ONE, 95*10**25, uint(1000000003012430238457635717), 99.88*10**25);
        // risk group: 27 - DDF3, APR: 10%
        navFeed.file("riskGroup", 27, ONE, 95*10**25, uint(1000000003170979198376458650), 99.86*10**25);
        // risk group: 28 - ARF3, APR: 9%
        navFeed.file("riskGroup", 28, ONE, 95*10**25, uint(1000000002853881278538812785), 99.92*10**25);
        // risk group: 29 - BRF3, APR: 9.5%
        navFeed.file("riskGroup", 29, ONE, 90*10**25, uint(1000000003012430238457635717), 99.9*10**25);
        // risk group: 30 - CRF3, APR: 9.5%
        navFeed.file("riskGroup", 30, ONE, 80*10**25, uint(1000000003012430238457635717), 99.88*10**25);
        // risk group: 31 - DRF3, APR: 10%
        navFeed.file("riskGroup", 31, ONE, 70*10**25, uint(1000000003170979198376458650), 99.87*10**25);
        // risk group: 32 - ATF3, APR: 9%
        navFeed.file("riskGroup", 32, ONE, 80*10**25, uint(1000000002853881278538812785), 99.92*10**25);
        // risk group: 33 - BTF3, APR: 9.5%
        navFeed.file("riskGroup", 33, ONE, 70*10**25, uint(1000000003012430238457635717), 99.9*10**25);
        // risk group: 34 - CTF3, APR: 9.5%
        navFeed.file("riskGroup", 34, ONE, 60*10**25, uint(1000000003012430238457635717), 99.89*10**25);
        // risk group: 35 - DTF3, APR: 10%                                        
        navFeed.file("riskGroup", 35, ONE, 50*10**25, uint(1000000003170979198376458650), 99.88*10**25);
     }   
}
