// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract StructType{
	// 结构体
    struct Student{
        uint256 id;
        uint256 score; 
   
	}

	Student student; // 初始化一个student结构体


	// 给结构体赋值的两种方法:
    // 1:在函数中创建一个storage的struct引用
    function initStudent1() external{
        Student storage _student = student; // assign a copy of student
        _student.id = 11;
        _student.score = 100;
    }

	// 2:直接引用状态变量的struct
    function initStudent2() external{
        student.id = 1;
        student.score = 80;
    }
}
