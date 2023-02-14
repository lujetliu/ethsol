// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4

/*
	代币归属条款
	在传统金融领域, 一些公司会向员工和管理层提供股权; 但大量股权同时释放
	会在短期产生抛售压力, 拖累股价; 因此公司通常会引入一个归属期来延迟承
	诺资产的所有权, 同样的在区块链领域, Web3初创公司会给团队分配代币, 同
	时也会将代币低价出售给风投和私募; 如果把这些低成本的代币同时提到交易
	所变现, 币价将被砸穿, 散户直接成为接盘侠; 所以项目方一般会约定代币归
	属条款(token vesting), 在归属期内逐步释放代币, 减缓抛压, 并防止团队
	和资本方过早躺平;

	
	线性释放
	线性释放指的是代币在归属期内匀速释放, 如某私募持有365,000枚ICU代币,
	归属期为1年(365天), 那么每天会释放1,000枚代币

	一个锁仓并线性释放ERC20代币的合约TokenVesting:
	1. 项目方规定线性释放的起始时间、归属期和受益人
	2. 项目方将锁仓的ERC20代币转账给TokenVesting合约
	3. 受益人可以调用release函数, 从合约中取出释放的代币

*/

import "./IERC20.sol"

contract TokenVesting {
	// 状态变量
    mapping(address => uint256) public erc20Released; // 代币地址->释放数量的映射，记录已经释放的代币
    address public immutable beneficiary; // 受益人地址
    uint256 public immutable start; // 起始时间戳
    uint256 public immutable duration; // 归属期

    // 事件
	event ERC20Released(address indexed token, uint256 amount); // 提币事件

	/**
     * @dev 初始化受益人地址, 释放周期(秒), 起始时间戳(当前区块链时间戳)
     */
    constructor(
        address beneficiaryAddress,
        uint256 durationSeconds
    ) {
        require(beneficiaryAddress != address(0), "VestingWallet: beneficiary is zero address");
        beneficiary = beneficiaryAddress;
        start = block.timestamp;
        duration = durationSeconds;
    }

	/**
     * @dev 受益人提取已释放的代币
     * 调用vestedAmount()函数计算可提取的代币数量, 然后transfer给受益人
     * 释放 {ERC20Released} 事件.
     */
    function release(address token) public {
        // 调用vestedAmount()函数计算可提取的代币数量
        uint256 releasable = vestedAmount(token, uint256(block.timestamp)) - erc20Released[token];
        // 更新已释放代币数量   
        erc20Released[token] += releasable; 
        // 转代币给受益人
        emit ERC20Released(token, releasable);
        IERC20(token).transfer(beneficiary, releasable);
    }

    /**
     * @dev 根据线性释放公式, 计算已经释放的数量; 开发者可以通过修改这个函数,
	 * 自定义释放方式
     * @param token: 代币地址
     * @param timestamp: 查询的时间戳
     */
    function vestedAmount(address token, uint256 timestamp) public view returns (uint256) {
        // 合约里总共收到了多少代币(当前余额 + 已经提取)
        uint256 totalAllocation = IERC20(token).balanceOf(address(this)) + erc20Released[token];
        // 根据线性释放公式, 计算已经释放的数量
        if (timestamp < start) {
            return 0;
        } else if (timestamp > start + duration) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start)) / duration;
        }
    }
}




