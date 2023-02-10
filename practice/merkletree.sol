// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721/ERC721.sol"

/*
	Merkle Tree 也叫默克尔树或哈希树, 是区块链的底层加密技术, 被比特币和
	以太坊广泛采用; Merkle Tree 是一种自下而上构建的加密树, 每个叶子是
	对应数据的哈希, 而每个非叶子为它的2个子节点的哈希

	Merkle Tree允许对大型数据结构的内容进行有效和安全的验证(Merkle Proof),
	对于有N个叶子结点的Merkle Tree, 在已知root根值的情况下, 验证某个数据
	是否有效(属于Merkle Tree叶子结点)只需要log(N)个数据(也叫proof)非常高效;
	如果数据有误或者给的proof错误, 则无法还原出root根植;

	生成 Merkle Tree 
	可以利用网页(https://lab.miguelmota.com/merkletreejs/example/)  和
	Javascript 库 merkletreejs(https://github.com/merkletreejs/merkletreejs)
	生成 Merkle Tree.

	利用Merkle Tree发放NFT白名单(TODO:实践)
	一份拥有800个地址的白名单, 更新一次所需的gas fee很容易超过1个ETH; 而
	由于Merkle Tree验证时, leaf和proof可以存在后端, 链上仅需存储一个root的值, 
	非常节省gas, 项目方经常用它来发放白名单; 很多ERC721标准的NFT和ERC20标准
	代币的白名单/空投都是利用Merkle Tree发出的, 比如optimism的空投

*/

/**
 * @dev 验证Merkle树的合约.
 *
 * proof可以用JavaScript库生成:
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * 注意: hash用keccak256，并且开启pair sorting （排序）.
 * javascript例子见 `https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/utils/cryptography/MerkleProof.test.js`.
 */
library MerkleProof {
    /**
     * @dev 当通过`proof`和`leaf`重建出的`root`与给定的`root`相等时，返回`true`，数据有效。
     * 在重建时，叶子节点对和元素对都是排序过的。
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns 通过Merkle树用`leaf`和`proof`计算出`root`. 当重建出的`root`和给定的`root`相同时，`proof`才是有效的。
     * 在重建时，叶子节点对和元素对都是排序过的。
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    // Sorted Pair Hash
    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
    }
}

contract MerkleTree is ERC721 {
	// MerkleTree合约继承了ERC721标准, 并利用了MerkleProof库
    bytes32 immutable public root; // Merkle树的根
    mapping(address => bool) public mintedAddress;   // 记录已经mint的地址

    // 构造函数m, 初始化NFT合集的名称、代号、Merkle树的根
    constructor(string memory name, string memory symbol, bytes32 merkleroot)
    ERC721(name, symbol)
    {
        root = merkleroot;
    }

    // 利用Merkle树验证地址并完成mint
    function mint(address account, uint256 tokenId, bytes32[] calldata proof)
    external {
        require(_verify(_leaf(account), proof), "Invalid merkle proof"); // Merkle检验通过
        require(!mintedAddress[account], "Already minted!"); // 地址没有mint过
        _mint(account, tokenId); // mint
        mintedAddress[account] = true; // 记录mint过的地址
    }

    // 计算Merkle树叶子的哈希值
    function _leaf(address account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    // Merkle树验证，调用MerkleProof库的verify()函数
    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}
