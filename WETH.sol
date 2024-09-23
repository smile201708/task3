// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WETH is ERC20 {
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);

    constructor() ERC20("WETH", "Wrapped Ether") {
        // 设置名字和符号
    }

    // 存款函数，用户存入ETH，获得WETH
    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    // 取款函数，用户销毁WETH，取出ETH
    function withdraw(uint wad) public {
        require(balanceOf(msg.sender) >= wad, "ERC20: transfer amount exceeds balance");
        _burn(msg.sender, wad);
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    // 接收ETH的回调函数
    receive() external payable {
        deposit();
    }

    // 兼容旧合约的fallback函数
    fallback() external payable {
        deposit();
    }
}


