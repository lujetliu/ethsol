/*
	try-catch
	在solidity中, try-catch只能被用于external函数或创建合约时constructor(被视
	为external函数)的调用; 基本语法如下:
		try externalContract.f() {
            // call成功的情况下运行一些代码
        } catch {
            // call失败的情况下运行一些代码
        }

	其中externalContract.f()是某个外部合约的函数调用, try模块在调用成功的
	情况下运行, 而catch模块则在调用失败时运行

	同样可以使用this.f()来替代externalContract.f(), this.f()也被视作为外部调用,
	但不可在构造函数中使用, 因为此时合约还未创建


	如果调用的函数有返回值, 那么必须在try之后声明returns(returnType val),
	并且在try模块中可以使用返回的变量; 如果是创建合约, 那么返回值是新创建
	的合约变量
		try externalContract.f() returns(returnType val){
            // call成功的情况下运行一些代码
        } catch {
            // call失败的情况下运行一些代码
        }

	try代码块内的revert是不会被catch本身捕获

	catch模块支持捕获特殊的异常原因:
		try externalContract.f() returns(returnType val){
            // call成功的情况下运行一些代码
        } catch Error(string memory reason) {
            // 捕获失败的 revert() 和 require()
        } catch (bytes memory reason) {
            // 捕获失败的 assert()
        }
	
	wtf测试题中 revert, require 和 assert 异常的返回值类型都为 bytes (TODO:?)

*/
	

