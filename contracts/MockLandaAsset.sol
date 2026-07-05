// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockLandaAsset is ERC20 {
    address public minter;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        minter = msg.sender;
    }

    function setMinter(address _minter) external {
        minter = _minter;
    }
    
    function mint(address to, uint256 amount) external {
        require(msg.sender == minter, "MockLandaAsset: not minter");
        _mint(to, amount);
    }

    function burnFrom(address account, uint256 amount) external {
        require(msg.sender == minter, "MockLandaAsset: not minter");
        _burn(account, amount);
    }

    function testMint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
