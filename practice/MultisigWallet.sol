// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;  

/*
	多签钱包
	多签钱包是一种电子钱包, 特点是交易被多个私钥持有者(多签人)授权后才能执行:
	例如钱包由3个多签人管理, 每笔交易需要至少2人签名授权; 多签钱包可以防止
	单点故障(私钥丢失, 单人作恶), 更加去中心化, 更加安全, 被很多DAO采用


	Gnosis Safe多签钱包是以太坊最流行的多签钱包, 管理近400亿美元资产, 
	合约经过审计和实战测试, 支持多链(以太坊, BSC, Polygon等), 并提供丰
	富的DAPP支持(TODO)
	https://peopledao.mirror.xyz/nFCBXda8B5ZxQVqSbbDOn2frFDpTxNVtdqVBXGIjj0s

	
	多签钱包合约
	在以太坊上的多签钱包其实是智能合约, 属于合约钱包; 本节实现一个极简版多签
	钱包MultisigWallet合约, 由gnosis safe合约(几千行代码)简化而成
	1. 设置多签人和门槛(链上): 部署多签合约时, 需要初始化多签人列表和执行
		门槛(至少n个多签人签名授权后, 交易才能执行); Gnosis Safe多签钱包
		还支持增加/删除多签人以及改变执行门槛, 但本节不实现

	2. 创建交易(链下): 一笔待授权的交易包含以下内容
		- to: 目标合约
		- value: 交易发送的以太坊数量
		- data: calldata, 包含调用函数的选择器和参数
		- nonce: 初始为0, 随着多签合约每笔成功执行的交易递增的值, 可以防止
			签名重放攻击
	    - chainid: 链id, 防止不同链的签名重放攻击

	3. 收集多签签名(链下): 将上一步的交易ABI编码并计算哈希, 得到交易哈希, 
		然后让多签人签名, 并拼接到一起打包签名
	
	4. 调用多签合约的执行函数, 验证签名并执行交易(链上)
	
*/

contract MultisigWallet {
	// TODO: Remix 实验验证签名与教程不符
	// (https://wtf.academy/solidity-application/MultisigWallet)
	event ExecutionSuccess(bytes32 txHash);    // 交易成功事件
    event ExecutionFailure(bytes32 txHash);    // 交易失败事件

	address[] public owners;                   // 多签持有人数组
    mapping(address => bool) public isOwner;   // 记录一个地址是否为多签
    uint256 public ownerCount;                 // 多签持有人数量
    uint256 public threshold;                  // 多签执行门槛, 交易至少有n个多签人签名才能被执行
    uint256 public nonce;                      // nonce, 防止签名重放攻击 TODO

    receive() external payable {}

	// 构造函数, 初始化owners, isOwner, ownerCount, threshold 
	constructor(        
		address[] memory _owners,
		uint256 _threshold
	) {
		_setupOwners(_owners, _threshold);
	}


	// @dev 初始化owners, isOwner, ownerCount, threshold
	// @param _owners: 多签持有人数组
	// @param _threshold: 多签执行门槛, 至少有几个多签人签署了交易
	function _setupOwners(address[] memory _owners, uint256 _threshold) internal {
		// threshold没被初始化过
		require(threshold == 0, "threshold is zero");
		// 多签执行门槛 小于 多签人数
		require(_threshold <= _owners.length, "owners's length is invliad");
		// 多签执行门槛至少为1
		require(_threshold >= 1, "threshold shoud greater than 1");

		for (uint256 i = 0; i < _owners.length; i++) {
			address owner = _owners[i];
			// 多签人不能为0地址, 本合约地址不能重复
			require(owner != address(0) && owner != address(this) && !isOwner[owner], "WTF5003");
			owners.push(owner);
			isOwner[owner] = true;
		}
		ownerCount = _owners.length;
		threshold = _threshold;
	}

	// @dev 在收集足够的多签签名后执行交易
	// @param to 目标合约地址
	// @param value msg.value, 支付的以太坊
	// @param data calldata
	// @param signatures 打包的签名, 对应的多签地址由小到达, 方便检查
	// ({bytes32 r}{bytes32 s}{uint8 v}) (第一个多签的签名, 第二个多签的签名 ... )
	function execTransaction(
		address to,
		uint256 value,
		bytes memory data,
		bytes memory signatures
	) public payable virtual returns (bool success) {
		// 编码交易数据, 计算哈希
		bytes32 txHash = encodeTransactionData(to, value, data, nonce, block.chainid);
		nonce++;  // 增加nonce
		checkSignatures(txHash, signatures); // 检查签名
		// 利用call执行交易, 并获取交易结果
		(success, ) = to.call{value: value}(data);
		require(success , "not success");
		if (success) emit ExecutionSuccess(txHash);
		else emit ExecutionFailure(txHash);
	}

	/**
	 * @dev 检查签名和交易数据是否对应, 如果是无效签名, 交易会revert
	 * @param dataHash 交易数据哈希
	 * @param signatures 几个多签签名打包在一起
	 */
	function checkSignatures(
		bytes32 dataHash,
		bytes memory signatures
	) public view {
		// 读取多签执行门槛
		uint256 _threshold = threshold;
		require(_threshold > 0, "threshold should greater than 0");

		// 检查签名长度足够长
		require(signatures.length >= _threshold * 65, "signatures' length is
				invalid");

		// 通过一个循环，检查收集的签名是否有效
		// 大概思路：
		// 1. 用ecdsa先验证签名是否有效
		// 2. 利用 currentOwner > lastOwner 确定签名来自不同多签（多签地址递增）
		// 3. 利用 isOwner[currentOwner] 确定签名者为多签持有人
		address lastOwner = address(0);
		address currentOwner;
		uint8 v;
		bytes32 r;
		bytes32 s;
		uint256 i;
		for (i = 0; i < _threshold; i++) {
			(v, r, s) = signatureSplit(signatures, i);
			// 利用ecrecover检查签名是否有效
			currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v, r, s);
			require(currentOwner > lastOwner && isOwner[currentOwner], "WTF5007");
			lastOwner = currentOwner;
		}
	}

	// 将单个签名从打包的签名分离出来
	// @param signatures 打包签名
	// @param pos 要读取的多签index.
	function signatureSplit(bytes memory signatures, uint256 pos)
		internal
		pure
		returns (
			uint8 v,
			bytes32 r,
			bytes32 s
		)
	{
		// 签名的格式: bytes32 r}{bytes32 s}{uint8 v}
		assembly {
			let signaturePos := mul(0x41, pos)
			r := mload(add(signatures, add(signaturePos, 0x20)))
			s := mload(add(signatures, add(signaturePos, 0x40)))
			v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
		}
	}

	// @dev 编码交易数据
	// @param to 目标合约地址
	// @param value msg.value, 支付的以太坊
	// @param data calldata
	// @param _nonce 交易的nonce.
	// @param chainid 链id
	// @return 交易哈希bytes.
	function encodeTransactionData(
		address to,
		uint256 value,
		bytes memory data,
		uint256 _nonce,
		uint256 chainid
	) public pure returns (bytes32) {
		bytes32 safeTxHash =
			keccak256(
				abi.encode(
					to,
					value,
					keccak256(data),
					_nonce,
					chainid
				)
			);
		return safeTxHash;
	}
}


