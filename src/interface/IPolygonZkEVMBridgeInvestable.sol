// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;
interface IPolygonZkEVMBridgeInvestable{
    function pullAsset(
        uint256 amount,address token
    ) external;
    function putEth() external payable;
}