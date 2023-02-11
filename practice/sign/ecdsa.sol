/*
	以太坊使用的数字签名算法叫双椭圆曲线数字签名算法(ECDSA), 基于双椭圆曲线
	"私钥-公钥"对的数字签名算法; 主要起到了三个作用:
	身份认证: 证明签名方是私钥的持有人
	不可否认: 发送方不能否认发送过这个消息(TODO:?)
	完整性: 消息在传输过程中无法被修改


	ECDSA合约
	ECDSA标准中包含两个部分：
	1. 签名者利用私钥(隐私的)对消息(公开的)创建签名(公开的)
	2. 其他人使用消息(公开的)和签名(公开的)恢复签名者的公钥(公开的)并验证签名,
		本节所用的私钥, 公钥, 消息, 以太坊签名消息, 签名如下所示:
		私钥: 0x227dbb8586117d55284e26620bc76534dfbd2394be34cf4a09cb775d593b6f2b
		公钥: 0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2
		消息: 0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
		以太坊签名消息: 0xb42ca4636f721c7a331923e764587e98ec577cea1a185f60dfcc14dbb9bd900b
		签名: 0x390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c
*/

/*
	创建签名
	1. 打包消息: 在以太坊的ECDSA标准中, 被签名的消息是一组数据的keccak256哈希,
		为bytes32类型; 可以把任何想要签名的内容利用abi.encodePacked()函数打包,
		然后用keccak256()计算哈希作为消息

    // 将mint地址(address类型)和tokenId(uint256类型)拼成消息msgHash
    // _account: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    // _tokenId: 0
    // 对应的消息msgHash: 0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
	function getMessageHash(address _account, uint256 _tokenId) public pure returns(bytes32){
		return keccak256(abi.encodePacked(_account, _tokenId));
	}


	2. 计算以太坊签名消息
	消息可以是能被执行的交易, 也可以是其他任何形式, 为了避免用户误签了恶意交易, 
	EIP191提倡在消息前加上"\x19Ethereum Signed Message:\n32"字符, 并再做一次
	keccak256哈希作为以太坊签名消息; 经过toEthSignedMessageHash()函数处理后
	的消息, 不能被用于执行交易:

    // @dev 返回 以太坊签名消息
    // `hash`: 消息
    // 遵从以太坊签名标准: https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
    // 以及`EIP191`: https://eips.ethereum.org/EIPS/eip-191`
    // 添加"\x19Ethereum Signed Message:\n32"字段, 防止签名的是可执行交易
    //
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 哈希的长度为32
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

	处理后的消息为: (TODO: 实践)
	以太坊签名消息: 0xb42ca4636f721c7a331923e764587e98ec577cea1a185f60dfcc14dbb9bd900b


	3-1. 利用钱包签名 (TODO)
		日常操作中, 大部分用户都是通过这种方式进行签名; 在获取到需要签名的
		消息之后, 需要使用metamask钱包进行签名, metamask的personal_sign方法
		会自动把消息转换为以太坊签名消息然后发起签名, 所以只需要输入消息和签
		名者钱包account即可, 需要注意的是输入的签名者钱包account需要和metamask
		当前连接的account一致才能使用


	3-2. 利用 web3.py 签名: 批量调用中更倾向于使用代码进行签名, 以下是基于
		web3.py 的实现 
		./sign.py (TODO)

		验证签名: 
		为了验证签名, 验证者需要拥有消息, 签名, 和签名使用的公钥; 能验证签名
		的原因是只有私钥的持有者才能够针对交易生成这样的签名, 而别人不能

	4. 通过签名和消息恢复公钥
		签名是由数学算法生成的, 这里使用的是rsv签名, 签名中包含r, s, v三个
		值的信息; 而后可以通过r, s, v及以太坊签名消息来求得公钥; 下面
		的recoverSigner()函数实现了上述步骤, 它利用以太坊签名消息 _msgHash
		和签名 _signature恢复公钥(使用了简单的内联汇编):

		// @dev 从_msgHash和签名_signature中恢复signer地址
		function recoverSigner(bytes32 _msgHash, bytes memory _signature) internal pure returns (address){
			// 检查签名长度，65是标准r,s,v签名的长度
			require(_signature.length == 65, "invalid signature length");

			bytes32 r;
			bytes32 s;
			uint8 v;
			// 目前只能用assembly(内联汇编)来从签名中获得r,s,v的值
			assembly {
				// 前32 bytes存储签名的长度 (动态数组存储规则)
				// add(sig, 32) = sig的指针 + 32
				// 等效为略过signature的前32 bytes
				// mload(p) 载入从内存地址p起始的接下来32 bytes数据
				// 读取长度数据后的32 bytes
				r := mload(add(_signature, 0x20))
				// 读取之后的32 bytes
				s := mload(add(_signature, 0x40))
				// 读取最后一个byte
				v := byte(0, mload(add(_signature, 0x60)))
			}
			// 使用ecrecover(全局函数): 利用 msgHash 和 r,s,v 恢复 signer 地址
			return ecrecover(_msgHash, v, r, s);
		}



	5. 对比公钥并验证签名
		比对恢复的公钥与签名者公钥_signer是否相等: 若相等则签名有效, 否则签名无效

		// @dev 通过ECDSA, 验证签名地址是否正确, 如果正确则返回true
		// _msgHash为消息的hash
		// _signature为签名
		// _signer为签名地址
		//
		function verify(bytes32 _msgHash, bytes memory _signature, address _signer) internal pure returns (bool) {
			return recoverSigner(_msgHash, _signature) == _signer;
		}

	 

	利用签名发放白名单
	NFT项目方可以利用ECDSA的这个特性发放白名单, 由于签名是链下的, 不需要gas,
	因此这种白名单发放模式比Merkle Tree模式还要经济; 项目方利用项目方账户
	把白名单发放地址签名(可以加上地址可以铸造的tokenId); 然后mint的时候利用
	ECDSA检验签名是否有效, 如果有效, 则给他mint;  SignatureNFT合约实现了利
	用签名发放NFT白名单;  但由于用户要请求中心化接口去获取签名, 不可避免
	的牺牲了一部分去中心化, 额外还有一个好处是白名单可以动态变化, 而不是提前
	写死在合约里面了, 因为项目方的中心化后端接口可以接受任何新地址的请求并给
	予白名单签名.

*/

contract SignatureNFT is ERC721 {
    address immutable public signer; // 签名地址
    mapping(address => bool) public mintedAddress;   // 记录已经mint的地址

    // 构造函数, 初始化NFT合集的名称、代号、签名地址
    constructor(string memory _name, string memory _symbol, address _signer)
    ERC721(_name, _symbol)
    {
        signer = _signer;
    }

    // 利用ECDSA验证签名并mint
    function mint(address _account, uint256 _tokenId, bytes memory _signature)
    external
    {
        bytes32 _msgHash = getMessageHash(_account, _tokenId); // 将_account和_tokenId打包消息
        bytes32 _ethSignedMessageHash = ECDSA.toEthSignedMessageHash(_msgHash); // 计算以太坊签名消息
        require(verify(_ethSignedMessageHash, _signature), "Invalid signature"); // ECDSA检验通过
        require(!mintedAddress[_account], "Already minted!"); // 地址没有mint过
        _mint(_account, _tokenId); // mint
        mintedAddress[_account] = true; // 记录mint过的地址
    }

    /*
     * 将mint地址(address类型)和tokenId(uint256类型)拼成消息msgHash
     * _account: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
     * _tokenId: 0
     * 对应的消息: 0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
     */
    function getMessageHash(address _account, uint256 _tokenId) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_account, _tokenId));
    }

    // ECDSA验证, 调用ECDSA库的verify()函数
    function verify(bytes32 _msgHash, bytes memory _signature)
    public view returns (bool)
    {
        return ECDSA.verify(_msgHash, _signature, signer);
    }
}
￼

