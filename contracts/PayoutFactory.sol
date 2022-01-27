pragma solidity ^0.6.0;

import "./PayoutProxy.sol";

contract PayoutFactory {

	address public implementation;
	mapping(address => bool) deployedProxies;

	event PayoutProxyCreated(address Proxy);

	constructor(address _imp) public {
		require(_imp != address(0));
		implementation = _imp;
	}

	function createPayoutProxy(address _treasury, address _den) external returns(address) {
		bytes memory data = abi.encodeWithSignature("init(address,address,address)", msg.sender, _treasury, _den);

		PayoutProxy proxy = new PayoutProxy(implementation, data);
		deployedProxies[address(proxy)] = true;
		emit PayoutProxyCreated(address(proxy));
		return address(proxy);
	}
}