// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4

/*
	时间锁(TimeLock)
	在区块链中, 时间锁被DeFi和DAO大量采用; 是一段代码, 可以将智能合约的某些
	功能锁定一段时间; 可以大大改善智能合约的安全性; 假如一个黑客黑了Uniswap
	的多签, 准备提走金库的钱, 但金库合约加了2天锁定期的时间锁, 那么黑客从
	创建提钱的交易到实际把钱提走, 需要2天的等待期, 在这一段时间, 项目方可
	以找应对办法, 投资者可以提前抛售代币减少损失


	时间锁合约
	- 在创建Timelock合约时, 项目方可以设定锁定期, 并把合约的管理员设为自己
	- 时间锁主要有三个功能:
		- 创建交易，并加入到时间锁队列
		- 在交易的锁定期满后，执行交易
		- 后悔了, 取消时间锁队列中的某些交易

	- 项目方一般会把时间锁合约设为重要合约的管理员, 例如金库合约, 再通过时间锁
		操作他们 (TODO: 可借鉴的设计经验）
	- 时间锁合约的管理员一般为项目的多签钱包, 保证去中心化
*/

contract TimeLock is ERC20 {
	// 状态变量
    address public admin; // 管理员地址
    uint public constant GRACE_PERIOD = 7 days (?); // 交易有效期, 过期的交易作废
    uint public delay; // 交易锁定时间(秒）
    mapping (bytes32 => bool) public queuedTransactions; // txHash到bool, 记录所有在时间锁队列中的交易

	// 事件
    // 交易取消事件
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint executeTime);
    // 交易执行事件
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint executeTime);
    // 交易创建并进入队列事件
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint executeTime);
    // 修改管理员地址的事件
    event NewAdmin(address indexed newAdmin);

	// 修饰器
	// onlyOwner modifier
    modifier onlyOwner() { // 只能被管理员执行
        require(msg.sender == admin, "Timelock: Caller not admin");
        _;
    }

    // onlyTimelock modifier 
    modifier onlyTimelock() { // 只能被时间锁合约执行
        require(msg.sender == address(this), "Timelock: Caller not Timelock");
        _;
    }


	/**
     * @dev 构造函数, 初始化交易锁定时间(秒)和管理员地址
     */
    constructor(uint delay_) {
        delay = delay_;
        admin = msg.sender;
    }


    /**
     * @dev 改变管理员地址, 调用者必须是Timelock合约
     */
    function changeAdmin(address newAdmin) public onlyTimelock {
        admin = newAdmin;

        emit NewAdmin(newAdmin);
    }

    /**
     * @dev 创建交易并添加到时间锁队列中。
     * @param target: 目标合约地址
     * @param value: 发送eth数额
     * @param signature: 要调用的函数签名(function signature)
     * @param data: call data, 里面是一些参数
     * @param executeTime: 交易执行的区块链时间戳
     *
     * 要求: executeTime 大于当前区块链时间戳+delay
     */
    function queueTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime) public onlyOwner returns (bytes32) {
        // 检查: 交易执行时间满足锁定时间
        require(executeTime >= getBlockTimestamp() + delay, "Timelock::queueTransaction: Estimated execution block must satisfy delay.");
        // 计算交易的唯一识别符: 一堆东西的hash
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        // 将交易添加到队列
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, executeTime);
        return txHash;
    }

    /**
     * @dev 取消特定交易。
     *
     * 要求: 交易在时间锁队列中
     */
    function cancelTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime) public onlyOwner{
        // 计算交易的唯一识别符: 一堆东西的hash
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        // 检查: 交易在时间锁队列中
        require(queuedTransactions[txHash], "Timelock::cancelTransaction: Transaction hasn't been queued.");
        // 将交易移出队列
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, executeTime);
    }

    /**
     * @dev 执行特定交易
     *
     * 要求:
     * 1. 交易在时间锁队列中
     * 2. 达到交易的执行时间
     * 3. 交易没过期
     */
    function executeTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 executeTime) public payable onlyOwner returns (bytes memory) {
        bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
        // 检查: 交易是否在时间锁队列中
        require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        // 检查: 达到交易的执行时间
        require(getBlockTimestamp() >= executeTime, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        // 检查: 交易没过期
       require(getBlockTimestamp() <= executeTime + GRACE_PERIOD, "Timelock::executeTransaction: Transaction is stale.");
        // 将交易移出队列
        queuedTransactions[txHash] = false;

        // 获取call data
        bytes memory callData;
        if (bytes(signature).length == 0) {
			   callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }
        // 利用call执行交易
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, executeTime);

        return returnData;
    }

    /**
     * @dev 获取当前区块链时间戳
     */
    function getBlockTimestamp() public view returns (uint) {
        return block.timestamp;
    }

    /**
     * @dev 将一堆东西拼成交易的标识符
     */
    function getTxHash(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint executeTime
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(target, value, signature, data, executeTime));
    }
}
