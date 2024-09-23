
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AMMPool {
    using SafeERC20 for IERC20;

    IERC20 public weth;
    IERC20 public token;
    uint256 public tokenReserve;
    uint256 public wethReserve;
    uint256 private constant MINIMUM_LIQUIDITY = 1000;

    constructor(address _wethAddress, address _tokenAddress) {
        weth = IERC20(_wethAddress);
        token = IERC20(_tokenAddress);
    }

    // 流动性提供者存入流动性
    function deposit(uint256 _tokenAmount, uint256 _wethAmount) public {
        require(_tokenAmount > 0 && _wethAmount > 0, "Invalid amount");
        require(token.balanceOf(msg.sender) >= _tokenAmount, "Insufficient token balance");
        require(weth.balanceOf(msg.sender) >= _wethAmount, "Insufficient WETH balance");

        token.safeTransferFrom(msg.sender, address(this), _tokenAmount);
        weth.safeTransferFrom(msg.sender, address(this), _wethAmount);

        tokenReserve += _tokenAmount;
        wethReserve += _wethAmount;

        // 确保流动性增加
        uint256 newLiquidity = tokenReserve * wethReserve;
        require(newLiquidity >= MINIMUM_LIQUIDITY, "Liquidity did not increase");
    }

    // 流动性提供者取出流动性
    function withdraw(uint256 _tokenAmount, uint256 _wethAmount) public {
        require(_tokenAmount <= tokenReserve && _wethAmount <= wethReserve, "Insufficient liquidity");

        token.safeTransfer(msg.sender, _tokenAmount);
        weth.safeTransfer(msg.sender, _wethAmount);

        tokenReserve -= _tokenAmount;
        wethReserve -= _wethAmount;
    }

    // 用户交换WETH为Token
    function swapWETHToToken(uint256 _wethAmount) public {
        require(weth.transferFrom(msg.sender, address(this), _wethAmount), "Transfer WETH failed");
        uint256 tokenAmount = getOutput(_wethAmount, wethReserve, tokenReserve);
        require(token.transfer(msg.sender, tokenAmount), "Transfer Token failed");
        wethReserve += _wethAmount;
        tokenReserve -= tokenAmount;
    }

    // 用户交换Token为WETH
    function swapTokenToWETH(uint256 _tokenAmount) public {
        require(token.transferFrom(msg.sender, address(this), _tokenAmount), "Transfer Token failed");
        uint256 wethAmount = getOutput(_tokenAmount, tokenReserve, wethReserve);
        require(weth.transfer(msg.sender, wethAmount), "Transfer WETH failed");
        tokenReserve += _tokenAmount;
        wethReserve -= wethAmount;
    }

    // 计算交换输出
    function getOutput(uint256 _input, uint256 _inputReserve, uint256 _outputReserve) internal pure returns (uint256) {
        require(_input <= _inputReserve, "Input amount exceeds input reserve");
        uint256 outputReserveNext = _inputReserve + _input;
        uint256 numerator = _outputReserve * _input;
        uint256 denominator = _inputReserve + outputReserveNext;
        return numerator / denominator;
    }

    // 获取WETH和Token的余额
    function getReserves() external view returns (uint256, uint256) {
        return (wethReserve, tokenReserve);
    }
}
