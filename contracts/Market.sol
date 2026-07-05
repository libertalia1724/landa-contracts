// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {Operator} from "./Operator.sol";
import {IOracle} from "./IOracle.sol";
import {ILandaAsset} from "./ILandaAsset.sol";

contract Market is ReentrancyGuard, Operator {
    bool public initialized;

    address public usdl;
    address public landa;
    address public oracle;
    address public treasury;

    uint256 public minSpread;
    uint256 public basePool;
    int256  public usdlPoolDelta;
    uint256 public poolRecoveryPeriod;
    uint256 public lastBlockNumber;

    function initialize(address initUsdlAddress, address initLandaAddress, address initOracle, address initTreasury, uint256 initMinSpread, uint256 initBasePool, uint256 initPoolRecoveryPeriod) external onlyOwner {
        require(!initialized, "already initialized");
        usdl = initUsdlAddress;
        landa = initLandaAddress;
        oracle = initOracle;
        treasury = initTreasury;
        minSpread = initMinSpread;
        basePool = initBasePool;
        usdlPoolDelta = 0;
        poolRecoveryPeriod = initPoolRecoveryPeriod;
        lastBlockNumber = block.number;
        initialized = true;
    }

    function getUsdlPool() public view checkInitialize returns(uint256) {
        return uint256(int256(basePool) + usdlPoolDelta);
    }

    function getLandaPool() public view checkInitialize returns(uint256) {
        return (basePool ** 2) / getUsdlPool();
    }

    function swapForUsdl(uint256 landaAmount) public checkInitialize nonReentrant {
        if (IERC20(landa).balanceOf(msg.sender) < landaAmount) revert InsufficientLandaBalance();

        replenishPools();
        uint256 returnUsdlAmount = computeSwapUsdlForAmount(landaAmount);
        uint256 spread = computeSwapUsdlForSpread(landaAmount);

        uint256 swapFee = (returnUsdlAmount * spread) / 10_000;
        uint256 usdlMintAmount = returnUsdlAmount - swapFee;

        applySwapToPoolForUsdl(returnUsdlAmount);

        ILandaAsset(landa).burnFrom(msg.sender, landaAmount);
        ILandaAsset(usdl).mint(msg.sender, usdlMintAmount);
        ILandaAsset(usdl).mint(treasury, swapFee);

        emit SwapForUsdl(msg.sender, landaAmount, usdlMintAmount, spread);
    }

    function swapForLanda(uint256 usdlAmount) public checkInitialize nonReentrant {
        if (IERC20(usdl).balanceOf(msg.sender) < usdlAmount) revert InsufficientLandaBalance();

        replenishPools();
        uint256 returnLandaAmount = computeSwapLandaForAmount(usdlAmount);
        uint256 spread = computeSwapLandaForSpread(usdlAmount);

        uint256 swapFee = (returnLandaAmount * spread) / 10_000;
        uint256 landaMintAmount = returnLandaAmount - swapFee;

        applySwapToPoolForLanda(usdlAmount);

        ILandaAsset(usdl).burnFrom(msg.sender, usdlAmount);
        ILandaAsset(landa).mint(msg.sender, landaMintAmount);
        ILandaAsset(landa).mint(treasury, swapFee);

        emit SwapForLanda(msg.sender, usdlAmount, landaMintAmount, spread);
    }

    function computeSwapUsdlForAmount(uint256 landaAmount) internal view returns(uint256) {
        return (landaAmount * IOracle(oracle).getExchangeRateForUsdl()) / IOracle(oracle).getExchangeRateForLanda();
    }

    function computeSwapLandaForAmount(uint256 usdlAmount) internal view returns(uint256) {
        return (usdlAmount * IOracle(oracle).getExchangeRateForLanda()) / IOracle(oracle).getExchangeRateForUsdl();
    }

    function computeSwapUsdlForSpread(uint256 landaAmount) internal view returns(uint256) {
        uint256 offerLanda = (landaAmount * 10**18) / IOracle(oracle).getExchangeRateForLanda();
        uint256 usdlPool = getUsdlPool();
        uint256 landaPool = getLandaPool();

        uint256 ratio = (usdlPool * 1e18) / (landaPool + offerLanda);
        uint256 spreadConstantProduct = ratio >= 1e18 ? 0 : 1e18 - ratio;
        uint256 spreadConstantProductBps = (spreadConstantProduct * 10_000) / 1e18;

        return Math.max(minSpread, spreadConstantProductBps);
    }

    function computeSwapLandaForSpread(uint256 usdlAmount) internal view returns(uint256) {
        uint256 offerUsdl = (usdlAmount * 10**18) / IOracle(oracle).getExchangeRateForUsdl();
        uint256 usdlPool = getUsdlPool();
        uint256 landaPool = getLandaPool();

        uint256 ratio = (landaPool * 1e18) / (usdlPool + offerUsdl);
        uint256 spreadConstantProduct = ratio >= 1e18 ? 0 : 1e18 - ratio;
        uint256 spreadConstantProductBps = (spreadConstantProduct * 10_000) / 1e18;

        return Math.max(minSpread, spreadConstantProductBps);
    }

    function applySwapToPoolForUsdl(uint256 usdlAmount) internal {
        uint256 askUsdl = (usdlAmount * 10**18) / IOracle(oracle).getExchangeRateForUsdl();
        usdlPoolDelta -= int256(askUsdl);
    }

    function applySwapToPoolForLanda(uint256 usdlAmount) internal {
        uint256 offerUsdl = (usdlAmount * 10**18) / IOracle(oracle).getExchangeRateForUsdl();
        usdlPoolDelta += int256(offerUsdl);
    }

    function replenishPools() internal {
        uint256 elapsed = Math.min(block.number - lastBlockNumber, poolRecoveryPeriod);
        int256 remaining = int256(poolRecoveryPeriod - elapsed);

        usdlPoolDelta = (usdlPoolDelta * remaining) / int256(poolRecoveryPeriod);
        lastBlockNumber = block.number;
    }

    function getVirtualUsdlPoolDelta() external view checkInitialize returns(int256) {
        uint256 elapsed = Math.min(block.number - lastBlockNumber, poolRecoveryPeriod);
        int256 remaining = int256(poolRecoveryPeriod - elapsed);

        return (usdlPoolDelta * remaining) / int256(poolRecoveryPeriod);
    }

    modifier checkInitialize {
        if (initialized == false) revert ContractHasNotBeenInitiated();
        _;
    }

    event SwapForUsdl(address indexed trader, uint256 landaAmount, uint256 usdlAmount, uint256 swapSpread);

    event SwapForLanda(address indexed trader, uint256 usdlAmount, uint256 landaAmount, uint256 swapSpread);

    error InsufficientLandaBalance();

    error ContractHasNotBeenInitiated();
}