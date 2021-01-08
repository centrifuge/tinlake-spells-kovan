pragma solidity >=0.5.12;

import "ds-test/test.sol";
import "../mgr.sol";
import {DssSpell} from "../ns-maker-spell.sol";
import "lib/dss-interfaces/src/Interfaces.sol";
import {DSValue} from "ds-value/value.sol";
import {EpochCoordinator} from "tinlake/lender/coordinator.sol";

interface FlipFabLike {
    function newFlip(address vat, address cat, bytes32 ilk) external returns (address flip);
}
interface Hevm {
    function warp(uint) external;
    function store(address,bytes32,bytes32) external;
    function load(address,bytes32) external returns (bytes32);
}

interface Root {
    function relyContract(address, address) external;
}

interface MemberList {
    function updateMember(address, uint) external;
}


contract TinlakeManagerTest is DSTest {
    bytes32 constant ilk = "NS2DRP-A"; // New Collateral Type
    uint constant ONE = 10 ** 27;

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function divup(uint x, uint y) internal pure returns (uint z) {
        z = add(x, sub(y, 1)) / y;
    }

    // MCD
    VatAbstract vat;
    CatAbstract cat;
    VowAbstract vow;
    SpotAbstract spotter;
    DaiAbstract dai;
    JugAbstract jug;
    //  https://changelog.makerdao.com/releases/kovan/1.2.2/contracts.json
    ChainlogAbstract constant CHANGELOG = ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    DSChiefAbstract chief;
    DSTokenAbstract gov;
    address pause_proxy;

    // -- testing --
    Hevm constant hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    DssSpell spell;
    TinlakeManager dropMgr;
    DSValue dropPip;

    // Tinlake
    GemLike constant drop = GemLike(0x352Fee834a14800739DC72B219572d18618D9846);
    Root constant root = Root(0x25dF507570c8285E9c8E7FFabC87db7836850dCd);
    MemberList constant memberlist = MemberList(0xD927F069faf59eD83A1072624Eeb794235bBA652);
    EpochCoordinator constant coordinator = EpochCoordinator(0xD2F4ba3117c6463cB67001538041fBA898bc7a2e);
    address constant seniorOperator_ = 0x6B902D49580320779262505e346E3f9B986e99e8;
    address constant seniorTranche_ = 0xDF0c780Ae58cD067ce10E0D7cdB49e92EEe716d9;

 

    function setUp() public {
        vat = VatAbstract(CHANGELOG.getAddress("MCD_VAT"));
        vow = VowAbstract(CHANGELOG.getAddress("MCD_VOW"));
        cat = CatAbstract(CHANGELOG.getAddress("MCD_CAT"));
        dai = DaiAbstract(CHANGELOG.getAddress("MCD_DAI"));
        jug = JugAbstract(CHANGELOG.getAddress("MCD_JUG"));
        spotter = SpotAbstract(CHANGELOG.getAddress("MCD_SPOT"));
        chief = DSChiefAbstract(CHANGELOG.getAddress("MCD_ADM"));
        gov = DSTokenAbstract(CHANGELOG.getAddress("MCD_GOV"));
        pause_proxy = CHANGELOG.getAddress("MCD_PAUSE_PROXY");


        // deploy unmodified pip
        dropPip = new DSValue();
        dropPip.poke(bytes32(uint(1 ether)));

        // deploy dropMgr
        dropMgr = new TinlakeManager(address(vat),
                                     CHANGELOG.getAddress("MCD_DAI"),
                                     CHANGELOG.getAddress("MCD_JOIN_DAI"),
                                     address(vow),
                                     address(drop),
                                     seniorOperator_,
                                     address(this),
                                     seniorTranche_,
                                     ilk);
        // cast spell
        spell = new DssSpell();
        vote();
        spell.schedule();
        hevm.warp(now + 2 weeks);
        spell.cast();
        jug.drip(ilk);

        // welcome to hevm KYC
        hevm.store(address(root), keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
        root.relyContract(address(memberlist), address(this));
        memberlist.updateMember(address(this), uint(-1));

        memberlist.updateMember(address(dropMgr), uint(-1));

        // give this address 1500 dai and 1000 drop
        hevm.store(address(dai), keccak256(abi.encode(address(this), uint(2))), bytes32(uint(1500 ether)));
        hevm.store(address(drop), keccak256(abi.encode(address(this), uint(8))), bytes32(uint(1000 ether)));
        assertEq(dai.balanceOf(address(this)), 1500 ether);
        assertEq(drop.balanceOf(address(this)), 1000 ether);

        // approve the manager
        drop.approve(address(dropMgr), uint(-1));
        dai.approve(address(dropMgr), uint(-1));

    }

    function testSanity() public {
        assertEq(address(dropMgr.vat()), address(vat));
    }

    function testJoinAndDraw() public {
        assertEq(dai.balanceOf(address(this)), 1500 ether);
        assertEq(drop.balanceOf(address(this)), 1000 ether);
        dropMgr.join(400 ether);
        dropMgr.draw(200 ether);
        assertEq(dai.balanceOf(address(this)), 1700 ether);
        assertEq(drop.balanceOf(address(this)), 600 ether);
        assertEq(drop.balanceOf(address(dropMgr)), 400 ether);
    }

    function testWipeAndExit() public {
        testJoinAndDraw();
        dropMgr.wipe(10 ether);
        dropMgr.exit(10 ether);
        assertEq(dai.balanceOf(address(this)), 1690 ether);
        assertEq(drop.balanceOf(address(this)), 610 ether);
    }

    function testAccrueInterest() public {
        testJoinAndDraw();
        hevm.warp(now + 2 days);
        jug.drip(ilk);
        assertEq(cdptab() / ONE, 200.038762269592882076 ether);
        dropMgr.wipe(10 ether);
        dropMgr.exit(10 ether);
        assertEq(cdptab() / ONE, 190.038762269592882076 ether);
        assertEq(dai.balanceOf(address(this)), 1690 ether);
        assertEq(drop.balanceOf(address(this)), 610 ether);
    }

    function testTellAndUnwind() public {
        testJoinAndDraw();
        assertEq(drop.balanceOf(address(dropMgr)), 400 ether);
        assertEq(divup(cdptab(), ONE), 200 ether);
        assertEq(dai.balanceOf(address(this)), 1700 ether);
        // we are authorized, so can call `tell()`
        // even if tellCondition is not met.
        dropMgr.tell();
        // all of the drop is in the redeemer now
        assertEq(drop.balanceOf(address(dropMgr)), 0);
        coordinator.closeEpoch();
        hevm.warp(now + 2 days);
        dropMgr.unwind(coordinator.currentEpoch());
        // unwinding should unlock the 400 drop in the manager
        // giving 200 to cover the cdp
        assertEq(cdptab(), 0 ether); // the cdp should now be debt free
        // and 200 back to us
        assertEq(dai.balanceOf(address(this)), 1900 ether);
    }

    function testSinkAndRecover() public {
        testJoinAndDraw();
        hevm.warp(now + 1 days);
        jug.drip(ilk);
        uint preSin = vat.sin(address(vow));
        (, uint rate, , ,) = vat.ilks(ilk);
        (uint preink, uint preart) = vat.urns(ilk, address(dropMgr));
        dropMgr.tell();
        dropMgr.sink();

        assertEq(vat.gem(ilk, address(dropMgr)), 0);
        assertEq(preink, 400 ether);
        // the urn is empty
        (uint postink, uint postart) = vat.urns(ilk, address(dropMgr));
        assertEq(postink, 0);
        assertEq(postart, 0);
        // and the vow has accumulated sin
        assertEq(vat.sin(address(vow)) - preSin, preart * rate);
        
        // try to recover some debt
        coordinator.closeEpoch();
        hevm.warp(now + 2 days);
        dropMgr.recover(coordinator.currentEpoch());
    }

    function vote() private {
        if (chief.hat() != address(spell)) {
            hevm.store(
                address(gov),
                keccak256(abi.encode(address(this), uint256(1))),
                bytes32(uint256(999999999999 ether))
            );
            gov.approve(address(chief), uint256(-1));
            chief.lock(999999999998 ether);

            assertTrue(!spell.done());

            address[] memory yays = new address[](1);

            if (chief.live() == 0) {
                yays[0] = address(0);
                chief.vote(yays);
                if (chief.hat() != address(0)) {
                    chief.lift(address(0));
                }
                chief.launch();
            }

            yays[0] = address(spell);

            chief.vote(yays);
            chief.lift(address(spell));
        }
        assertEq(chief.hat(), address(spell));
    }

    function cdptab() public view returns (uint) {
        // Calculate DAI cdp debt
        (, uint art) = vat.urns(ilk, address(dropMgr));
        (, uint rate, , ,) = vat.ilks(ilk);
        return art * rate;
    }
}
