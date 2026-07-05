// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

import {ERC20, ERC20Burnable} from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';

import {Operator} from './Operator.sol';

contract USDL is ERC20Burnable, Operator {
    constructor() ERC20('USDL', 'USDL') {
        _mint(msg.sender, 1 * 10**18);
    }

    function mint(address recipient, uint256 amount) external onlyOperator {
        _mint(recipient, amount);
    }

    function burnFrom(address account, uint256 amount) public override onlyOperator {
        super.burnFrom(account, amount);
    }
}