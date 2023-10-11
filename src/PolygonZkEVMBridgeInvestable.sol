// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;
import "zkevm-contracts/PolygonZkEVMBridge.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PolygonZkEVMBridgeInvestable is
    PolygonZkEVMBridge,
    AccessControlUpgradeable
{
    using SafeERC20 for IERC20;
    bytes32 public constant INVESTMENT_MANAGER =
        keccak256("INVESTMENT_MANAGER");
    event PullAssetEvent(address manager, uint256 amount, address token);
    error PolygonZkEVMBridgeInvestable__OnlyInvestmentManager();
    error PolygonZkEVMBridgeInvestable__ZeroAddress();
    constructor(address _investmentManager) {
        _setupRole(INVESTMENT_MANAGER, _investmentManager);
    }

    modifier onlyInvestmentManager() {
        if (!hasRole(INVESTMENT_MANAGER, msg.sender))
            revert PolygonZkEVMBridgeInvestable__OnlyInvestmentManager();
        _;
    }

    function pullAsset(
        uint256 amount,
        address token
    ) external onlyInvestmentManager {
        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(token).safeTransfer(msg.sender, amount);
        }
        emit PullAssetEvent(msg.sender, amount, token);
    }
    function putEth() external payable onlyInvestmentManager {
        require(msg.value > 0, "PolygonZkEVMBridgeInvestable__ZeroAddress");
    }
}
