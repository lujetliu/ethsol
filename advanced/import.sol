// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;  

/* 
	solidity支持利用import关键字导入其他源代码中的合约, 让开发更加模块化.

	引用(import)在代码中的位置为: 在声明版本号之后，在其余代码之前
	import 用法:
	- 通过源文件相对位置导入
		文件结构
		├── Import.sol
		└── Yeye.sol

		// 通过文件相对位置import
		import './Yeye.sol';

	- 通过源文件网址导入网上的合约
		// 通过网址引用
		import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol';

	- 通过npm的目录导入
		import '@openzeppelin/contracts/access/Ownable.sol';

	- 通过全局符号导入特定的合约
		import {Yeye} from './Yeye.sol';

*/

import {Yeye} from './baba.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol';

contract Import {
	// 成功导入Address库
    using Address for address;
    // 声明yeye变量
    Yeye yeye = new Yeye();

    // 测试是否能调用yeye的函数
    function test() external{
        yeye.hip();
    }
}

