// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

	IERC721Metadata
	IERC721Metadata是ERC721的拓展接口, 实现了3个查询metadata元数据的常用函数:
		- name(): 返回代币名称
		- symbol(): 返回代币代号
		- tokenURI(): 通过tokenId查询metadata的链接url，ERC721特有的函数
	
		interface IERC721Metadata is IERC721 {
			function name() external view returns (string memory);
			function symbol() external view returns (string memory);
			function tokenURI(uint256 tokenId) external view returns (string memory);
		}
*/

import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./String.sol";

contract ERC721 is IERC721, IERC721Metadata{
    using Address for address; // 使用Address库, 用isContract来判断地址是否为合约
    using Strings for uint256; // 使用String库

    // Token名称
    string public override name;
    // Token代号
    string public override symbol;
    // tokenId 到 owner address 的持有人映射
    mapping(uint => address) private _owners;
    // address 到 持仓数量 的持仓量映射
    mapping(address => uint) private _balances;
    // tokenID 到 授权地址 的授权映射
    mapping(uint => address) private _tokenApprovals;
    //  owner地址, 到operator地址的批量授权映射
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * 构造函数, 初始化`name` 和`symbol` .
     */
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    // 实现IERC165接口supportsInterface, TODO
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
		return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    // 实现IERC721的balanceOf，利用_balances变量查询owner地址的balance
    function balanceOf(address owner) external view override returns (uint) {
        require(owner != address(0), "owner = zero address");
        return _balances[owner];
    }

    // 实现IERC721的ownerOf，利用_owners变量查询tokenId的owner
    function ownerOf(uint tokenId) public view override returns (address owner) {
        owner = _owners[tokenId];
        require(owner != address(0), "token doesn't exist");
    }

    // 实现IERC721的isApprovedForAll, 利用_operatorApprovals变量查询owner地址
	// 是否将所持NFT批量授权给了operator地址
    function isApprovedForAll(address owner, address operator)
        external
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    // 实现IERC721的setApprovalForAll, 将持有代币全部授权给operator地址,
	// 调用_setApprovalForAll函数
	  function setApprovalForAll(address operator, bool approved) external override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // 实现IERC721的getApproved, 利用_tokenApprovals变量查询tokenId的授权地址
    function getApproved(uint tokenId) external view override returns (address) {
        require(_owners[tokenId] != address(0), "token doesn't exist");
        return _tokenApprovals[tokenId];
    }

    // 授权函数, 通过调整_tokenApprovals来, 授权 to 地址操作 tokenId,
	// 同时释放Approval事件
    function _approve(
        address owner,
        address to,
        uint tokenId
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId); // 释放 Approval 事件
    }

    // 实现IERC721的approve, 将tokenId授权给 to 地址; 条件: to不是owner,
	// 且msg.sender是owner或授权地址, 调用_approve函数
    function approve(address to, uint tokenId) external override {
        address owner = _owners[tokenId];
        require(
            msg.sender == owner || _operatorApprovals[owner][msg.sender],
            "not owner nor approved for all"
        );
        _approve(owner, to, tokenId);
    }

    // 查询 spender地址是否可以使用tokenId(需要是owner或被授权地址)
    function _isApprovedOrOwner(
        address owner,
        address spender,
        uint tokenId
    ) private view returns (bool) {
		  return (spender == owner ||
            _tokenApprovals[tokenId] == spender ||
            _operatorApprovals[owner][spender]);
    }

    /*
     * 转账函数, 通过调整_balances和_owner变量将 tokenId 从 from 转账给 to,
	 // 同时释放Transfer事件
     * 条件:
     * 1. tokenId 被 from 拥有
     * 2. to 不是0地址
     */
    function _transfer(
        address owner,
        address from,
        address to,
        uint tokenId
    ) private {
        require(from == owner, "not owner");
        require(to != address(0), "transfer to the zero address");

        _approve(owner, address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
    
    // 实现IERC721的transferFrom, 非安全转账不建议使用, 调用_transfer函数
    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) external override {
        address owner = ownerOf(tokenId);
		 require(
            _isApprovedOrOwner(owner, msg.sender, tokenId),
            "not owner nor approved"
        );
        _transfer(owner, from, to, tokenId);
    }

    /**
     * 安全转账, 安全地将 tokenId 代币从 from 转移到 to, 会检查合约接收者
	 * 是否实现 ERC721 协议, 以防止代币被永久锁定; 调用了_transfer函数和
	 * _checkOnERC721Received函数; 条件:
     * from 不能是0地址
     * to 不能是0地址
     * tokenId 代币必须存在，并且被 from拥有
     * 如果 to 是智能合约, 必须支持 IERC721Receiver-onERC721Received
     */
    function _safeTransfer(
        address owner,
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) private {
		// TODO: 为什么不是先判断条件?
        _transfer(owner, from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "not ERC721Receiver");
    }

    /**
     * 实现IERC721的safeTransferFrom, 安全转账, 调用了_safeTransfer函数
     */
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) public override {
        address owner = ownerOf(tokenId);
        require(
            _isApprovedOrOwner(owner, msg.sender, tokenId),
            "not owner nor approved"
        );
        _safeTransfer(owner, from, to, tokenId, _data);
    }
	   // safeTransferFrom重载函数
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * 铸造函数, 通过调整_balances和_owners变量来铸造tokenId并转账给 to,
	 // 同时释放Transfer事件
     * 这个mint函数所有人都能调用, 实际使用需要开发人员重写, 加上一些条件
     * 条件:
     * 1. tokenId尚不存在
     * 2. to不是0地址
     */
    function _mint(address to, uint tokenId) internal virtual {
        require(to != address(0), "mint to zero address");
        require(_owners[tokenId] == address(0), "token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    // 销毁函数, 通过调整_balances和_owners变量来销毁tokenId, 同时释放
	// Transfer事件; 条件: tokenId存在
    function _burn(uint tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "not owner of token");

        _approve(owner, address(0), tokenId);
		  _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    // _checkOnERC721Received函数, 用于在 to 为合约的时候调用
	// IERC721Receiver-onERC721Received, 以防 tokenId 被不小心转入黑洞
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

    /**
     * 实现IERC721Metadata的tokenURI函数, 查询metadata
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_owners[tokenId] != address(0), "Token Not Exist");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

	 /**
     * 计算{tokenURI}的BaseURI，tokenURI就是把baseURI和tokenId拼接在一起，需要开发重写
     * BAYC的baseURI为ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
}
