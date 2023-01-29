/*
	CREATE2
	CREATE2 操作码使我们在智能合约部署在以太坊网络之前就能预测合约的地址;
	Uniswap创建Pair合约用的就是CREATE2而不是CREATE

	CREATE2的用法和Create类似, 同样是new一个合约, 并传入新合约构造函数所需
	的参数, 只不过要多传一个salt参数:
		Contract x = new Contract{salt: _salt, value: _value}(params)

	其中Contract是要创建的合约名, x是合约对象(地址),_salt是指定的盐;
	如果构造函数是payable, 可以创建时转入_value数量的ETH, params是新合约
	构造函数的参数

	极简 Uniswap2
	Pair 合约
	contract Pair{
		address public factory; // 工厂合约地址
		address public token0; // 代币1
		address public token1; // 代币2

		constructor() payable {
			factory = msg.sender;
		}

		// called once by the factory at time of deployment
		function initialize(address _token0, address _token1) external {
			require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
			token0 = _token0;
			token1 = _token1;
		}
	}

	构造函数constructor在部署时将factory赋值为工厂合约地址, initialize函数会在
	Pair合约创建的时候被工厂合约调用一次, 将token0和token1更新为币对中两种代币
	的地址

	PairFactory2 合约
	contract PairFactory2{
        mapping(address => mapping(address => address)) public getPair; // 通过两个代币地址查Pair地址
        address[] public allPairs; // 保存所有Pair地址

        function createPair2(address tokenA, address tokenB) external returns (address pairAddr) {
            require(tokenA != tokenB, 'IDENTICAL_ADDRESSES'); 
			//避免tokenA和tokenB相同产生的冲突

            // 计算用tokenA和tokenB地址计算salt
            (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); 
			//将tokenA和tokenB按大小排序
            bytes32 salt = keccak256(abi.encodePacked(token0, token1));

            // 用create2部署新合约
            Pair pair = new Pair{salt: salt}(); 
            // 调用新合约的initialize方法
            pair.initialize(tokenA, tokenB);
            // 更新地址map
            pairAddr = address(pair);
            allPairs.push(pairAddr);
            getPair[tokenA][tokenB] = pairAddr;
            getPair[tokenB][tokenA] = pairAddr;
        }

		// 提前计算pair合约地址
        function calculateAddr(address tokenA, address tokenB) public view returns(address predictedAddress){
            require(tokenA != tokenB, 'IDENTICAL_ADDRESSES'); //避免tokenA和tokenB相同产生的冲突
            // 计算用tokenA和tokenB地址计算salt
            (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); //将tokenA和tokenB按大小排序
            bytes32 salt = keccak256(abi.encodePacked(token0, token1));
            // 计算合约地址方法 hash()
            predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(type(Pair).creationCode)
            )))));
		}
		// calculateAddr函数来事先计算tokenA和tokenB将会生成的Pair地址, 通过它
		// 可以验证我们事先计算的地址和实际地址是否相同

	}

	工厂合约(PairFactory2)有两个状态变量getPair是两个代币地址到币对地址的map, 
	方便根据代币找到币对地址; allPairs是币对地址的数组, 存储了所有币对地址;

	PairFactory2合约只有一个createPair2函数, 使用CREATE2根据输入的两个代币
	地址tokenA和tokenB来创建新的Pair合约, 其中:


	create2的实际应用场景(TODO:熟悉)
	1. 交易所为新用户预留创建钱包合约地址
	2. 由 CREATE2 驱动的 factory 合约, 在uniswapV2中交易对的创建是在 
		Factory中调用create2完成; 好处是: 
		它可以得到一个确定的pair地址, 使得 Router中就可以通过(tokenA, tokenB)
		计算出pair地址, 不再需要执行一次 Factory.getPair(tokenA, tokenB) 的
		跨合约调用



*/
