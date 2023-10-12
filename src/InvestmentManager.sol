// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interface/RocketTokenRETHInterface.sol";
import "./interface/RocketDepositPoolInterface.sol";
import "./interface/RocketStorageInterface.sol";
import "./interface/IPolygonZkEVMBridgeInvestable.sol";
error InvestmentManager__NotEnoughFundsToInvest();
error InvestmentManager__NotEnoughFundsToRedeem();
error InvestmentManager__SendExcessYieldFailed();

/**
 * @title InvestmentManager
 * @author 0xKaizendev
 * @notice InvestmentManager is a contract for managing the investment of funds hosted on the PolygonZkEVMBridge
 */
contract InvestmentManager is OwnableUpgradeable {
    uint256 public reservePercent = 100;
    uint256 public targetPercent = 200;
    uint public initialInvestment;
    address public recipent;
    RocketStorageInterface rocketStorage;
    IPolygonZkEVMBridgeInvestable bridgeContract;
    event InvestEvent(address manager, uint256 amount, address token);
    event RedeemEvent( uint256 amount);
    event SendExcessYieldEvent(address to, uint256 amount);
    event SetReservePercentEvent(uint256 amount);
    event SetTargetPercentEvent(uint256 amount);
    event SetRecipentEvent(address recipent);

    /**
     * @notice initialize a new InvestmentManager contract
     * @param _rocketStorageAddress The address of the RocketStorage contract
     * @param _bridgeAddress The address of the PolygonZkEVMBridge contract
     */
    function initialize(
        address _rocketStorageAddress,
        address _bridgeAddress,
        address _recipent
    ) public initializer {
        rocketStorage = RocketStorageInterface(_rocketStorageAddress);
        bridgeContract = IPolygonZkEVMBridgeInvestable(_bridgeAddress);
        __Ownable_init();
        recipent = _recipent;
    }

    receive() external payable {}

    /**
     * @notice Invest funds on the PolygonZkEVMBridge
     */
    function invest() public  {
        // RocketPoll contracts should be queried each time they are used
        (
            RocketTokenRETHInterface rocketTokenRETH,
            RocketDepositPoolInterface rocketDepositPool
        ) = getContractAddress();
        uint256 investedEth = rocketTokenRETH.getEthValue(
            rocketTokenRETH.balanceOf(address(this))
        );

        uint256 excessYield = 0;
        if (investedEth > initialInvestment) {
            excessYield = investedEth - initialInvestment;
        }
        (uint256 total, uint256 bridgeBalance) = getBalances();
        if ((bridgeBalance * 10000) / total > targetPercent) {
            uint256 amountToInvest = (bridgeBalance * reservePercent) / 10000;
            bridgeContract.pullAsset(amountToInvest, address(0));
            rocketDepositPool.deposit{value: 10000000000000000}();
            initialInvestment = amountToInvest;
            emit InvestEvent(msg.sender, amountToInvest, address(0));
        } else revert InvestmentManager__NotEnoughFundsToInvest();
    }

    function redeem(uint256 amount) public  {
        (RocketTokenRETHInterface rocketTokenRETH, ) = getContractAddress();

        (uint256 total, uint256 bridgeBalance) = getBalances();
        if (
            (bridgeBalance / total) * 10000 < reservePercent &&
            (bridgeBalance / (amount + total)) * 10000 < targetPercent
        ) {
            bridgeContract.pullAsset(amount, address(rocketTokenRETH));
            rocketTokenRETH.burn(amount);
            bridgeContract.putEth{value: amount}();
            emit RedeemEvent( amount);
        } else revert InvestmentManager__NotEnoughFundsToRedeem();
    }

    function sendExcessYield() public onlyOwner {
        (RocketTokenRETHInterface rocketTokenRETH, ) = getContractAddress();
        uint256 investedEth = rocketTokenRETH.getEthValue(
            rocketTokenRETH.balanceOf(address(bridgeContract))
        );

        uint256 excessYield = 0;
        if (investedEth > initialInvestment) {
            excessYield = investedEth - initialInvestment;
            uint256 rEthAmountToPull = rocketTokenRETH.getRethValue(
                excessYield
            );
            bridgeContract.pullAsset(
                rEthAmountToPull,
                address(rocketTokenRETH)
            );

            rocketTokenRETH.burn(rocketTokenRETH.balanceOf(address(this)));
            payable(recipent).transfer(address(this).balance);
            emit SendExcessYieldEvent(recipent, excessYield);
        } else revert InvestmentManager__SendExcessYieldFailed();
    }

    function setReservePercent(uint256 _reservePercent) public onlyOwner {
        reservePercent = _reservePercent;
        emit SetReservePercentEvent(_reservePercent);
    }

    function setTargetPercent(uint256 _targetPercent) public onlyOwner {
        targetPercent = _targetPercent;
        emit SetTargetPercentEvent(_targetPercent);
    }

    function setRecipient(address _recipient) public onlyOwner {
        recipent = _recipient;
        emit SetRecipentEvent(_recipient);
    }

    function getContractAddress()
        public
        view
        returns (RocketTokenRETHInterface, RocketDepositPoolInterface)
    {
        address rocketTokenRETHAddress = rocketStorage.getAddress(
            keccak256(abi.encodePacked("contract.address", "rocketTokenRETH"))
        );
        RocketTokenRETHInterface rocketTokenRETH = RocketTokenRETHInterface(
            rocketTokenRETHAddress
        );
        address rocketDepositPoolAddress = rocketStorage.getAddress(
            keccak256(abi.encodePacked("contract.address", "rocketDepositPool"))
        );
        RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(
                rocketDepositPoolAddress
            );
        return (rocketTokenRETH, rocketDepositPool);
    }

    function getBalances() public view returns (uint256, uint256) {
        (RocketTokenRETHInterface rocketTokenRETH, ) = getContractAddress();
        uint256 investedEth = rocketTokenRETH.getEthValue(
            rocketTokenRETH.balanceOf(address(bridgeContract))
        );
        uint256 bridgeBalance = address(bridgeContract).balance;
        uint256 excessYield = 0;
        if (investedEth > initialInvestment) {
            excessYield = investedEth - initialInvestment;
        }
        uint256 total = bridgeBalance + investedEth - excessYield;
        return (total, bridgeBalance);
    }
}
