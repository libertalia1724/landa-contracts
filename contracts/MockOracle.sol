// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

import {IOracle} from "./IOracle.sol";

contract MockOracle is IOracle {
    uint256 private usdlRate;
    uint256 private landaRate;

    function setExchangeRateForUsdl(uint256 rate) external {
        usdlRate = rate;
    }

    function setExchangeRateForLanda(uint256 rate) external {
        landaRate = rate;
    }

    function getExchangeRateForUsdl() external view override returns(uint256) {
        return usdlRate;
    }

    function getExchangeRateForLanda() external view override returns(uint256) {
        return landaRate;
    }
}
