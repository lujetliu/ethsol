/*
	BTC和ETH这类代币都属于同质化代币, 矿工挖出的第1枚BTC与第10000枚BTC并
	没有不同, 是等价的; 但世界中很多物品是不同质的, 其中包括房产、古董、
	虚拟艺术品等等, 这类物品无法用同质化代币抽象; 因此以太坊EIP721提出了
	ERC721标准, 来抽象非同质化的物品;

	EIP
	EIP全称 Ethereum Imporvement Proposals(以太坊改进建议), 是以太坊开发
	者社区提出的改进建议, 是一系列以编号排定的文件, 类似互联网上IETF的RFC,
	EIP可以是 Ethereum 生态中任意领域的改进, 比如新特性、ERC、协议改进、
	编程工具等等.

	ERC全称 Ethereum Request For Comment(以太坊意见征求稿), 用以记录以太
	坊上应用级的各种开发标准和协议; 如典型的Token标准(ERC20, ERC721)、
	名字注册(ERC26, ERC13), URI范式(ERC67), Library/Package格式(EIP82), 
	钱包格式(EIP75,EIP85)。

	ERC协议标准是影响以太坊发展的重要因素, 像ERC20, ERC223, ERC721, ERC777等,
	都是对以太坊生态产生了很大影响



	ERC165
	通过ERC165标准, 智能合约可以声明它支持的接口, 供其他合约检查; ERC165检查
	一个智能合约是不是支持了ERC721, ERC1155的接口;

	IERC165接口合约只声明了一个supportsInterface函数, 输入要查询的interfaceId
	接口id, 若合约实现了该接口id, 则返回true:
	interface IERC165 {
		// @dev 如果合约实现了查询的`interfaceId`, 则返回true
		// 规则详见：https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     
		function supportsInterface(bytes4 interfaceId) external view returns (bool);
	}


	ERC721实现supportsInterface()函数:
	function supportsInterface(bytes4 interfaceId) external pure override returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

	当查询的是IERC721或IERC165的接口id时, 返回true, 反之返回false.


	IERC721
	IERC721是ERC721标准的接口合约, 规定了ERC721要实现的基本函数; 它利用
	tokenId来表示特定的非同质化代币, 授权或转账都要明确tokenId; 而ERC20只
	需要明确转账的数额即可

	// @dev ERC721标准接口.
	interface IERC721 is IERC165 {
		event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
		event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
		event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

		function balanceOf(address owner) external view returns (uint256 balance);

		function ownerOf(uint256 tokenId) external view returns (address owner);

		function safeTransferFrom(
			address from,
			address to,
			uint256 tokenId,
			bytes calldata data
		) external;

		function safeTransferFrom(
			address from,
			address to,
			uint256 tokenId
		) external;

		function transferFrom(
			address from,
			address to,
			uint256 tokenId
		) external;

		function approve(address to, uint256 tokenId) external;
		function setApprovalForAll(address operator, bool _approved) external;
		function getApproved(uint256 tokenId) external view returns (address operator);
		function isApprovedForAll(address owner, address operator) external view returns (bool);
	}


	IERC721事件
	IERC721包含3个事件, 其中Transfer和Approval事件在ERC20中也有

	Transfer事件: 在转账时被释放, 记录代币的发出地址from, 接收地址to和tokenid
	Approval事件: 在授权时释放, 记录授权地址owner, 被授权地址approved和tokenid
	ApprovalForAll事件: 在批量授权时释放, 记录批量授权的发出地址owner, 被授
		权地址operator和授权与否的approved

	IERC721函数
		balanceOf: 返回某地址的NFT持有量balance
		ownerOf: 返回某tokenId的主人owner
		transferFrom: 普通转账, 参数为转出地址from, 接收地址to和tokenId
		safeTransferFrom: 安全转账(如果接收方是合约地址, 会要求实现
				ERC721Receiver接口), 参数为转出地址from, 接收地址to和tokenId
		approve: 授权另一个地址使用你的NFT, 参数为被授权地址approve和tokenId
		getApproved: 查询tokenId被批准给了哪个地址
		setApprovalForAll: 将自己持有的该系列NFT批量授权给某个地址operator
		isApprovedForAll: 查询某地址的NFT是否批量授权给了另一个operator地址
		safeTransferFrom: 安全转账的重载函数, 参数里面包含了data

	IERC721Receiver
	如果一个合约没有实现ERC721的相关函数, 转入的NFT就进了黑洞, 永远转不出来了;
	为了防止误转账, ERC721实现了safeTransferFrom()安全转账函数, 目标合约必须
	实现了IERC721Receiver接口才能接收ERC721代币, 不然会revert; IERC721Receiver
	接口只包含一个onERC721Received()函数:
		// ERC721接收者接口: 合约必须实现这个接口来通过安全转账接收ERC721
		interface IERC721Receiver {
			function onERC721Received(
				address operator,
				address from,
				uint tokenId,
				bytes calldata data
			) external returns (bytes4);
		}

	ERC721利用_checkOnERC721Received来确保目标合约实现了onERC721Received()
	函数(返回onERC721Received的selector)
		function _checkOnERC721Received(
			address from,
			address to,
			uint tokenId,
			bytes memory _data
		) private returns (bool) {
			if (to.isContract()) {
				return
					IERC721Receiver(to).onERC721Received(
						msg.sender,
						from,
						tokenId,
						_data
					) == IERC721Receiver.onERC721Received.selector;
			} else {
				return true;
			}
		}

	

