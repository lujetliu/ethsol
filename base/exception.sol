// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
	solidity 有三种抛出异常的方法: error, require和assert
	
	Error:
	error是solidity 0.8.4版本新加的内容, 方便且高效(省gas)地向用户解释操作
	失败的原因, 同时还可以在抛出异常的同时携带参数, 帮助开发者更好地调试.
	可以在contract之外定义异常; 

		定义一个 TransferNotOwner 异常, 当用户不是代币 owner 的时候尝试转账, 会
		抛出错误:
		error TransferNotOwner(); // 自定义error

		也可以定义一个携带参数的异常, 提示尝试转账的账户地址:
		error TransferNotOwner(address sender); // 自定义的带参数的error
	
	在执行当中, error必须搭配revert(回退)命令使用; 
		function transferOwner1(uint256 tokenId, address newOwner) public {
			if(_owners[tokenId] != msg.sender){
				revert TransferNotOwner();
				// revert TransferNotOwner(msg.sender);
			}
			_owners[tokenId] = newOwner;
		}
	gas 消耗: 24457gas
	
	Require:
	require命令是solidity 0.8版本之前抛出异常的常用方法, 目前很多主流合约
	仍然还在使用它; 它很好用, 唯一的缺点就是gas随着描述异常的字符串长度增加, 
	比error命令要高; 
	使用方法: require(检查条件，"异常的描述"), 当检查条件不成立的时候,
	就会抛出异常 (TODO: 检查条件的结果是布尔值)
		function transferOwner2(uint256 tokenId, address newOwner) public {
			require(_owners[tokenId] == msg.sender, "Transfer Not Owner");
			_owners[tokenId] = newOwner;
		}
	gas 消耗: 24743gas
￼
	Assert:
	assert命令一般用于程序员写程序debug, 因为它不能解释抛出异常的原因(比
	require少个字符串); assert(检查条件), 当检查条件不成立的时候, 就会抛出异常
	
		function transferOwner3(uint256 tokenId, address newOwner) public {
			assert(_owners[tokenId] == msg.sender);
			_owners[tokenId] = newOwner;
		}
	gas 消耗: 24473gas

	error方法gas最少, 其次是assert, require方法消耗gas最多; error既可以告知
	用户抛出异常的原因, 又能省gas
*/


contract Exception {
    error TransferNotOwner(); // 自定义的error

    mapping(uint256 => address) public _owners;

    function transferOwner1(uint256 tokenId, address newOwner) public {
        if(_owners[tokenId] != msg.sender){
            revert TransferNotOwner();
            // revert TransferNotOwner(msg.sender);
        }
        _owners[tokenId] = newOwner;
    }
    
    function transferOwner2(uint256 tokenId, address newOwner) public {
        require(_owners[tokenId] == msg.sender, "Transfer Not Owner");
        _owners[tokenId] = newOwner;
    }

    function transferOwner3(uint256 tokenId, address newOwner) public {
        assert(_owners[tokenId] == msg.sender);
        _owners[tokenId] = newOwner;
    }
}




