// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
	抽象合约
	如果一个智能合约里至少有一个未实现的函数, 即某个函数缺少主体{}中的内容, 
	则必须将该合约标为 abstract, 否则编译会报错; 另外未实现的函数需要加virtual, 
	以便子合约重写; 以插入排序合约为例, 如果还没想好具体怎么实现插入排序函数,
	那么可以把合约标为abstract, 之后让别人补写上;
	abstract contract InsertionSort{
		function insertionSort(uint[] memory a) public pure virtual returns(uint[] memory);
	}

*/

// 抽象合约
abstract contract Base {
    string public name = "base";
    function getAlias() public pure virtual returns (string memory);
}

contract BaseImpl is Base {
    function getAlias() public pure override returns(string memory){
        return "BaseImpl";
    }
}



