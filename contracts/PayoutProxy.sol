pragma solidity ^0.6.0;

import "@openzeppelin/contracts/proxy/Proxy.sol";

contract PayoutProxy is Proxy {

	// This is bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1))
	bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

	constructor(address _implementtion, bytes memory _data) public {
		assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_implementtion, _data);
	}

	function _implementation() internal override view returns (address imp) {
		bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            imp := sload(slot)
        }
	}

	function implementation() external view returns(address) {
		return _implementation();
	}

	function _setImplementation(address _imp, bytes memory _data) internal {
		bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _imp)
        }

        if (_data.length > 0) {
			(bool success, bytes memory returndata) = _imp.delegatecall(_data);
            if (!success) {
				// Look for revert reason and bubble it up if present
				if (returndata.length > 0) {
					// The easiest way to bubble the revert reason is using memory via assembly

					// solhint-disable-next-line no-inline-assembly
					assembly {
						let returndata_size := mload(returndata)
						revert(add(32, returndata), returndata_size)
					}
				} else {
					revert("Address: low-level delegate call failed");
				}
			}
        }
	}
}

