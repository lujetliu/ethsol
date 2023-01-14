
/*

	Call
	call 是 address 类型的低级成员函数, 用来与其他合约交互; 它的返回值为(bool, 
	data), 分别对应 call 是否成功已经目标函数的返回值;
	- call是solidity官方推荐的通过触发fallback或receive函数发送ETH的方法
	- 不推荐用call来调用另一个合约, 因为当你调用不安全合约的函数时, 
		就把主动权交给了它; 推荐的方法仍是声明合约变量后调用函数(TODO:实践理解)
	- 当知道对方合约的源代码或ABI时, 就没法生成合约变量(TODO:?); 此时仍然可以
		通过 call 调用对方合约的函数(TODO: abi)
	
	call 的使用规则:
	目标合约地址.call(二进制编码); 其中二进制编码利用结构化编码函数
	abi.encodeWithSignature获得:
	abi.encodeWithSignature("函数签名", 逗号分隔的具体参数)

	call 在调用合约时可以指定交易发送的ETH数额和gas:
	目标合约地址.call{value:发送数额, gas:gas数额}(二进制编码);

   
	
	contract OtherContract {
		uint256 private _x = 0; // 状态变量x
		// 收到eth的事件, 记录amount和gas
		event Log(uint amount, uint gas);

		fallback() external payable{}

		// 返回合约ETH余额
		function getBalance() view public returns(uint) {
			return address(this).balance;
		}

		// 可以调整状态变量_x的函数, 并且可以往合约转ETH (payable)
		function setX(uint256 x) external payable{
			_x = x;
			// 如果转入ETH, 则释放Log事件
			if(msg.value > 0){
				emit Log(msg.value, gasleft());
			}
		}

		// 读取x
		function getX() external view returns(uint x){
			x = _x;
		}
	}
	
	利用 call 调用目标合约
	1. Response 事件
		// 定义Response事件，输出call返回的结果success和data
		event Response(bool success, bytes data);
	2. 调用 setX 函数
		定义callSetX函数来调用目标合约的setX(), 转入msg.value数额的ETH, 
		并释放Response事件输出success和data

		function callSetX(address payable _addr, uint256 x) public payable {
			// call setX(), 同时可以发送ETH
			(bool success, bytes memory data) = _addr.call{value: msg.value}(
				abi.encodeWithSignature("setX(uint256)", x)
			);

			emit Response(success, data); //释放事件
		}


	3. 调用 getX 函数
	function callGetX(address _addr) external returns(uint256){
		// call getX()
		(bool success, bytes memory data) = _addr.call(
			abi.encodeWithSignature("getX()")
		);

		emit Response(success, data); //释放事件
		return abi.decode(data, (uint256));
	}


	4. 调用不存在的函数
		如果给 call 输入的函数不存在于目标合约中, 目标合约的 fallback
		函数会触发
		function callNonExist(address _addr) external{
			// call getX()
			(bool success, bytes memory data) = _addr.call(
				abi.encodeWithSignature("foo(uint256)")
			);

			emit Response(success, data); //释放事件
		}

	call了不存在的foo函数, call仍能执行成功, 并返回success, 但其实调用
	的目标合约fallback函数
*/


