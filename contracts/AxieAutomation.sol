pragma solidity ^0.6.0;

interface SLP {
	function getCheckpoint(address) external view returns(uint256,uint256);
	function checkpoint(address _owner, uint256 _amount, uint256 _createdAt, bytes calldata _signature) external returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface ClaimAddress {
	function claim(address _owner, uint256 _tokenId, uint256 _checkpoint, uint256 _createdAt, bytes calldata _signature) external;
}

interface IERC20 {
	function balanceOf(address user) external view returns(uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

contract AxieAutomation {

	uint256 public constant TOTAL_SHARE = 10000;
	SLP public constant SLP_CONTRACT = SLP(0xa8754b9Fa15fc18BB59458815510E40a12cD2014);
	ClaimAddress public constant CLAIM_ADDRESS = ClaimAddress(0x1a35E7ED2A2476129A32612644C8426BF8e8730c);
	IERC721 public constant AXIE = IERC721(0x32950db2a7164aE833121501C797D79E7B79d74C);

	address public owner;
	address public treasury;
	address public axieDen;
	bool setup;

	mapping (address => bool) public approvedCallers;

	function init(address _owner, address _treasury, address _den) external {
		require(!setup);
		setup = true;
		owner = _owner;
		treasury = _treasury;
		axieDen = _den;
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "AxieAutomation: Not owner");
		_;
	}

	modifier isCaller() {
		require(msg.sender == owner || approvedCallers[msg.sender], "AxieAutomation: Not caller");
		_;
	}

	function _sum(uint256[] memory _values) pure internal returns(uint256 sum) {
		for(uint256 i = 0 ; i < _values.length; i++)
			sum += _values[i];
	}

	function syncAndShare(
		address[] memory _recipients,
		uint256[] memory _values,
		address _account,
		uint256 _amount,
		uint256 _createdAt,
		bytes memory _signature)
		public onlyOwner {
		require(_recipients.length == _values.length, "!len");
		require(_sum(_values) == 10000, "!sum");
		uint256 syncedAmount = SLP_CONTRACT.checkpoint(_account, _amount, _createdAt, _signature);
		uint256 sentAmount;
		uint256 total = TOTAL_SHARE;
		for (uint256 i = 0 ; i < _values.length; i++) {
			uint256 sharedAmount = syncedAmount * _values[i] / total;
			if (i != _values.length - 1)
				SLP_CONTRACT.transferFrom(_account, _recipients[i], sharedAmount);
			else
				SLP_CONTRACT.transferFrom(_account, _recipients[i], syncedAmount - sentAmount);
			sentAmount += sharedAmount;
		}
	}

	function syncAndShareToken(
		address[] memory _recipients,
		uint256[] memory _values,
		address _account,
		uint256 _checkpoint,
		uint256 _tokenId,
		address _token,
		uint256 _createdAt,
		bytes memory _signature)
		public onlyOwner {
		require(_recipients.length == _values.length, "!len");
		require(_sum(_values) == 10000, "!sum");
		uint256 syncedAmount = IERC20(_token).balanceOf(_account);
		CLAIM_ADDRESS.claim(_account, _tokenId, _checkpoint, _createdAt, _signature);
		syncedAmount = IERC20(_token).balanceOf(_account) - syncedAmount;
		uint256 sentAmount;
		uint256 total = TOTAL_SHARE;
		for (uint256 i = 0 ; i < _values.length; i++) {
			uint256 sharedAmount = syncedAmount * _values[i] / total;
			if (i != _values.length - 1)
				IERC20(_token).transferFrom(_account, _recipients[i], sharedAmount);
			else
				IERC20(_token).transferFrom(_account, _recipients[i], syncedAmount - sentAmount);
			sentAmount += sharedAmount;
		}
	}

	function addAxies(address _account, uint256[] memory _axies) public onlyOwner {
		for (uint256 i = 0; i < _axies.length; i++) {
			AXIE.safeTransferFrom(axieDen, _account, _axies[i]);
		}
	}

	function addAxiesFrom(address _account, uint256[] memory _axies, address _from) public onlyOwner {
		for (uint256 i = 0; i < _axies.length; i++) {
			AXIE.safeTransferFrom(_from, _account, _axies[i]);
		}
	}

	function returnAxies(address _account, uint256[] memory _axies) public onlyOwner {
		for (uint256 i = 0; i < _axies.length; i++) {
			AXIE.safeTransferFrom(_account, axieDen, _axies[i]);
		}
	}

	function returnAxiesTo(address _account, address _to, uint256[] memory _axies) public onlyOwner {
		for (uint256 i = 0; i < _axies.length; i++) {
			AXIE.safeTransferFrom(_account, _to, _axies[i]);
		}
	}

	function updateCallers(address[] calldata _callers, bool[] calldata _values) external onlyOwner {
		for (uint256 i = 0; i < _callers.length; i++) {
			approvedCallers[_callers[i]] = _values[i];
		}
	}

	function setOwnership(address _newOwner) public onlyOwner {
		owner = _newOwner;
	}

	function setTreasury(address _treasury) public onlyOwner {
		treasury = _treasury;
	}

	function setDen(address _den) public onlyOwner {
		axieDen = _den;
	}
}