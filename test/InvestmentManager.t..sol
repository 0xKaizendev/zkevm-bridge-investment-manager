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
    string ETH_RPC_URL = vm.envString("RPC_URL");
    PolygonZkEVMBridgeInvestable bridge;
    InvestmentManager public manager;
    Account deployer;
    Account recipient;
    address rollup = 0x5132A183E9F3CB7C848b0AAC5Ae0c4f0491B7aB2;
    address RocketStorageAddress = 0x1d8f8f00cfa6758d7bE78336684788Fb0ee0Fa46;
    PolygonZkEVMGlobalExitRoot globalExitRootManager =
        PolygonZkEVMGlobalExitRoot(0x580bda1e7A0CFAe92Fa7F6c20A3794F169CE3CFb);
    uint256 startTime;

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
    }

    // test for setting all the state variables
    function test_setStateVariables() external {
        vm.startPrank(address(deployer.addr));
        manager.setReservePercent(10000);
        assertEq(manager.reservePercent(), 10000);
        manager.setTargetPercent(20000);
        assertEq(manager.targetPercent(), 20000);
        manager.setRecipient(address(recipient.addr));
        assertEq(manager.recipent(), address(recipient.addr));
    }

    // test fail for setting all the state variables
    function testRequire() public {
        // calling setReservePercent with another account
        vm.startPrank(address(recipient.addr));
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        manager.setReservePercent(10000);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        manager.setTargetPercent(20000);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        manager.setRecipient(address(recipient.addr));
    }

    function test_invest() external {
        // calling invest with manager owner
        deal(address(bridge), 1 ether);
        vm.startPrank(address(deployer.addr));
        manager.invest();
        assertEq(
            address(bridge).balance,
            1 ether - manager.initialInvestment()
        );
        (RocketTokenRETHInterface rocketTokenRETH, ) = manager
            .getContractAddress();
        // approxEq is used because of the difference in the amount of rEth after depositing into rocketpool
        assertApproxEqAbs(
            rocketTokenRETH.balanceOf(address(manager)),
            rocketTokenRETH.getRethValue(manager.initialInvestment()),
            500000000000000
        );
    }

    function testFail_invest() external {
        // investing with bridge eth balance of 0
        vm.startPrank(address(deployer.addr));
        vm.expectRevert("InvestmentManager__NotEnoughFundsToInvest()");
        manager.invest();
        vm.stopPrank();
    }

    function test_redeem() external {
        // calling invest with manager owner
        deal(address(bridge), 1 ether);
        vm.startPrank(address(deployer.addr));
        // making deposit into rocketpool
        manager.invest();
        assertEq(
            address(bridge).balance,
            1 ether - manager.initialInvestment()
        );
        (RocketTokenRETHInterface rocketTokenRETH, ) = manager
            .getContractAddress();
        // approxEq is used because of the difference in the amount of rEth after depositing into rocketpool
        assertApproxEqAbs(
            rocketTokenRETH.balanceOf(address(manager)),
            rocketTokenRETH.getRethValue(manager.initialInvestment()),
            500000000000000
        );
        uint256 bridgeBalanceBeforeRedeem = address(bridge).balance;
        // redeeming 0.005 ether
        manager.redeem(5000000000000000);
        // checking if the amount is sent to the bridge
        assertApproxEqAbs(
            address(bridge).balance,
            bridgeBalanceBeforeRedeem + 5000000000000000,
            50000000000000
        );
    }

    function testFail_redeem() external {
        deal(address(bridge), 1 ether);
        // redeeming 0.005 ether without investing
        vm.startPrank(address(deployer.addr));
        vm.expectRevert("InvestmentManager__NotEnoughFundsToRedeem()");
        manager.redeem(5000000000000000);
        manager.invest();
        // redeeming 0.005 ether with  (bridgeBalance * 10000) / total > reservePercent
        vm.expectRevert("InvestmentManager__NotEnoughFundsToRedeem()");
        manager.redeem(5000000000000000);
    }

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
        (RocketTokenRETHInterface rocketTokenRETH, ) = manager
            .getContractAddress();
        uint256 investedReth = rocketTokenRETH.balanceOf(address(bridge));

        uint256 excpectedExcessYield = rocketTokenRETH.getEthValue(1 ether);

        // Minting 1 more rEth than invested to send excess yield
        uint256 amountToMint = investedReth + 1 ether;
        deal(address(rocketTokenRETH), address(bridge), amountToMint);
        assertEq(
            rocketTokenRETH.balanceOf(address(bridge)),
            investedReth + 1 ether
        );
        // uint256 recipientBalanceBefore = address(recipient.addr).balance;
        manager.sendExcessYield();
        uint256 recipientBalanceAfter = address(recipient.addr).balance;
        // checking if the excess yield is sent to the recipient
        assertApproxEqAbs(
            recipientBalanceAfter,
            excpectedExcessYield,
            500000000000000
        );
    }
}
