// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

interface IOracle {
    function getExchangeRateForUsdl() external view returns(uint256);

    function getExchangeRateForLanda() external view returns(uint256);
}