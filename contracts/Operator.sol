// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

abstract contract Operator is Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    error CallerIsNotOperator();
    error ZeroAddressGivenForNewOperator();

    constructor() Ownable(msg.sender) {
        _operator = msg.sender;
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() external view returns (address) {
        return _operator;
    }

    modifier onlyOperator {
        if (msg.sender != _operator) {
            revert CallerIsNotOperator();
        }
        _;
    }

    function isOperator() public view returns (bool) {
        return msg.sender == _operator;
    }

    function transferOperator(address newOperator_) external onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        if (newOperator_ == address(0)) {
            revert ZeroAddressGivenForNewOperator();
        }
        address previousOperator = _operator;
        _operator = newOperator_;
        emit OperatorTransferred(previousOperator, _operator);
    }
}