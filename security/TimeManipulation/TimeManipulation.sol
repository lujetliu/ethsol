// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

/*
	操纵区块时间
	https://github.com/AmazingAng/WTF-Solidity/blob/main/S14_TimeManipulation/readme.md

	区块时间
	区块时间(block timestamp)是包含在以太坊区块头中的一个 uint64 值, 代表
	此区块创建的 UTC 时间戳(单位:秒), 在合并(The Merge)之前, 以太坊会根据
	算力调整区块难度, 因此出块时间不定, 平均 14.5s 出一个区块, 矿工可以操
	纵区块时间; 合并之后, 改为固定 12s 一个区块, 验证节点不能操纵区块时间;

	在 Solidity 中, 开发者可以通过全局变量 block.timestamp 获取当前区块的时间
	戳, 类型为 uint256

	Foundry 复现攻击
	攻击者只需操纵区块时间, 将它设为能被 170 整除的数字, 就可以成功铸造 NFT;
	使用 Foundry 来复现这个攻击, 因为它提供了修改区块时间的作弊码(cheatcodes);
	Foundry教程(https://github.com/AmazingAng/WTFSolidity/blob/main/Topics/Tools/TOOL07_Foundry/readme.md)

*/

contract TimeManipulation is ERC721 {
    uint256 totalSupply;

    // 构造函数, 初始化NFT合集的名称、代号
    constructor() ERC721("", ""){}

    // 铸造函数: 当区块时间能被7整除时才能mint成功
    function luckyMint() external returns(bool success){
        if(block.timestamp % 170 == 0){
            _mint(msg.sender, totalSupply); // mint
            totalSupply++;
            success = true;
        }else{
            success = false;
        }
    }
}
