// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;
import "test/forge/utils/Test.sol";
import "src/PolygonZkEVMBridgeInvestable.sol";
import "src/InvestmentManager.sol";
import "src/interface/RocketTokenRETHInterface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "zkevm-contracts/PolygonZkEVMGlobalExitRoot.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InvestmentManagerTest is Test {
    PolygonZkEVMBridgeInvestable bridge;
    InvestmentManager public manager;
    Account deployer;
    Account recipient;
    Account hacker;
    address rollup = 0x5132A183E9F3CB7C848b0AAC5Ae0c4f0491B7aB2;
    address RocketStorageAddress = 0x1d8f8f00cfa6758d7bE78336684788Fb0ee0Fa46;
    PolygonZkEVMGlobalExitRoot globalExitRootManager =
        PolygonZkEVMGlobalExitRoot(0x580bda1e7A0CFAe92Fa7F6c20A3794F169CE3CFb);
    uint256 startTime;

    function setUp() external {
        startTime = block.timestamp;
        deployer = makeAccount("deployer");
        hacker = makeAccount("hacker");
        recipient = makeAccount("recipient");
        manager = new InvestmentManager();
        bridge = new PolygonZkEVMBridgeInvestable(address(manager));
        bridge.initialize(1, globalExitRootManager, rollup);
        manager.initialize(RocketStorageAddress, address(bridge), address(recipient.addr));
        manager.transferOwnership(address(deployer.addr));
    }

// test for setting all the state variables
    // function test_setStateVariables() external {
    //     // calling setReservePercent with manager owner
    //     vm.startPrank(address(deployer.addr));
    //     manager.setReservePercent(10000);
    //     assertEq(manager.reservePercent(), 10000);
    //     // calling setTargetPercent with manager owner
    //     manager.setTargetPercent(20000);
    //     assertEq(manager.targetPercent(), 20000);
    //     // calling setRecipent with manager owner
    //     manager.setRecipient(address(recipient.addr));
    //     assertEq(manager.recipent(), address(hacker.addr));
    // }
    // // test fail for setting all the state variables
    // function testFail_setStateVariables() external {
    //     // calling setReservePercent with another account
    //     vm.startPrank(address(hacker.addr));
    //     manager.setReservePercent(10000);
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     // calling setTargetPercent with another account
    //     manager.setTargetPercent(20000);
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     // calling setRecipent with another account
    //     manager.setRecipient(address(recipient.addr));
    //     vm.expectRevert("Ownable: caller is not the owner");
    // }
    // function test_invest() external {
    //     // calling invest with manager owner
    //     deal(address(bridge), 10 ether);
    //     vm.startPrank(address(deployer.addr));
    //     manager.invest();
    //     assertEq(
    //         address(bridge).balance,
    //         10 ether - manager.initialInvestment()
    //     );
    //     (RocketTokenRETHInterface rocketTokenRETH, ) = manager
    //         .getRocketContractAddress();
    //     // approxEq is used because of the difference in the amount of rEth after depositing into rocketpool
    //     assertApproxEqAbs(
    //         rocketTokenRETH.balanceOf(address(bridge)),
    //         rocketTokenRETH.getRethValue(manager.initialInvestment()),
    //         500000000000000
    //     );
    // }
    // function testFail_invest() external {
    //     // Should fail because balance / total is less than targetPercent
    //     deal(address(bridge), 10 ether);
    //     vm.startPrank(address(deployer.addr));
    //     manager.setTargetPercent(10000);
    //     manager.invest();
    //     vm.expectRevert("InvestmentManager__NotEnoughFundsToInvest()");
    // }

    // function test_redeem() external {
    //     // calling invest with manager owner
    //     deal(address(bridge), 10 ether);
    //     vm.startPrank(address(deployer.addr));
    //     // making deposit into rocketpool
    //     manager.invest();
    //     assertEq(
    //         address(bridge).balance,
    //         10 ether - manager.initialInvestment()
    //     );
    //     (RocketTokenRETHInterface rocketTokenRETH, ) = manager
    //         .getRocketContractAddress();
    //     // approxEq is used because of the difference in the amount of rEth after depositing into rocketpool
    //     assertApproxEqAbs(
    //         rocketTokenRETH.balanceOf(address(bridge)),
    //         rocketTokenRETH.getRethValue(manager.initialInvestment()),
    //         500000000000000
    //     );
    //     uint256 bridgeBalanceBeforeRedeem = address(bridge).balance;
    //     // redeeming 0.005 ether with  (bridgeBalance * 10000) / total < reservePercent and (bridgeBalance * 10000) / (amount + total) < targetPercent
    //     manager.setReservePercent(10000);
    //     manager.setTargetPercent(10000);
    //     // reddeming 0.005 ether
    //     manager.redeem(5000000000000000);
    //     assertApproxEqAbs(
    //         address(bridge).balance,
    //         bridgeBalanceBeforeRedeem + 5000000000000000,
    //         50000000000000
    //     );
    // }
    // function testFail_redeem() external {
    //     // calling invest with manager owner
    //     deal(address(bridge), 10 ether);
    //     // redeeming 0.005 ether without investing
    //     vm.startPrank(address(deployer.addr));
    //     manager.redeem(5000000000000000);
    //     vm.expectRevert("InvestmentManager__NotEnoughFundsToRedeem()");
    //     manager.invest();
    //     // redeeming 0.005 ether with  (bridgeBalance * 10000) / total > reservePercent
    //     manager.redeem(5000000000000000);
    //     vm.expectRevert("InvestmentManager__NotEnoughFundsToRedeem()");
    //     // redeeming 0.005 ether with another account
    //     vm.startPrank(address(hacker.addr));
    //     manager.redeem(5000000000000000);
    //     vm.expectRevert("Ownable: caller is not the owner");
    // }
    function test_sendExcessYield() external {
        // calling invest with manager owner
        deal(address(bridge), 1 ether);
        vm.startPrank(address(deployer.addr));
        // making deposit into rocketpool
        manager.invest();
        assertEq(
            address(bridge).balance,
            1 ether - manager.initialInvestment()
        );
        // vm.warp(startTime + 1 weeks);
        // sending excess yield
        // manager.sendExcessYield();
    }
}
