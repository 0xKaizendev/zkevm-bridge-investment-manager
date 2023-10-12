// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;
import "src/PolygonZkEVMBridgeInvestable.sol";
import "test/forge/utils/Test.sol";
import "src/InvestmentManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "zkevm-contracts/PolygonZkEVMGlobalExitRoot.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20("Mock", "MOCK") {}

contract PolygonZkEVMBridgeInvestableTest is Test {
    string ETH_RPC_URL = vm.envString("RPC_URL");
    ERC20Mock token;
    PolygonZkEVMBridgeInvestable bridge;
    PolygonZkEVMBridge bridges;
    InvestmentManager public manager;
    Account recipient;
    Account deployer;
    address rollup = 0x5132A183E9F3CB7C848b0AAC5Ae0c4f0491B7aB2;
    address RocketStorageAddress = 0x1d8f8f00cfa6758d7bE78336684788Fb0ee0Fa46;
    PolygonZkEVMGlobalExitRoot globalExitRootManager =
        PolygonZkEVMGlobalExitRoot(0x580bda1e7A0CFAe92Fa7F6c20A3794F169CE3CFb);

    function setUp() external {
        uint256 ethFork = vm.createFork(ETH_RPC_URL);
        vm.selectFork(ethFork);
        deployer = makeAccount("deployer");
        recipient = makeAccount("recipient");
        manager = new InvestmentManager();
        bridge = new PolygonZkEVMBridgeInvestable(address(manager));
        bridge.initialize(1, globalExitRootManager, rollup);
        manager.initialize(
            RocketStorageAddress,
            address(bridge),
            address(recipient.addr)
        );
        manager.transferOwnership(address(deployer.addr));
        token = new ERC20Mock();
    }

    function test_pullAssetEth() external {
        deal(address(bridge), 2 ether);
        // calling pullAsset from manager contract
        vm.startPrank(address(manager));
        bridge.pullAsset(1 ether, address(0));
        assertEq(address(bridge).balance, 1 ether);
        assertEq(address(manager).balance, 1 ether);
    }

    function test_putETh() external {
        deal(address(manager), 2 ether);
        // sending  ether from the manager to the bridge
        vm.startPrank(address(manager));
        bridge.putEth{value: 1 ether}();
        assertEq((address(bridge)).balance, 1 ether);
        assertEq((address(manager)).balance, 1 ether);
    }

    function test_pullErc20() external {
        deal(address(token), address(bridge), 100 ether);
        // calling pullAsset from manager contract
        vm.startPrank(address(manager));
        bridge.pullAsset(100 ether, address(token));
        assertEq(token.balanceOf(address(bridge)), 0);
        assertEq(token.balanceOf(address(manager)), 100 ether);
    }

    function testFail_pullErc20() external {
        deal(address(token), address(bridge), 100 ether);
        // calling pullAsset from manager contract
        vm.startPrank(address(recipient.addr));
        bridge.pullAsset(100 ether, address(token));
        vm.expectRevert(
            "PolygonZkEVMBridgeInvestable__OnlyInvestmentManager()"
        );
    }

    function testFail_pullEth() public {
        deal(address(bridge), 2 ether);
        // calling pullAsset from manager contract
        vm.prank(address(recipient.addr));
        bridge.pullAsset(1 ether, address(0));
        vm.expectRevert(
            "PolygonZkEVMBridgeInvestable__OnlyInvestmentManager()"
        );
    }
}
