// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../interfaces/company/IShipyardVault.sol";
import "../interfaces/common/IUniswapRouterETH.sol";
import "../interfaces/curve/ICurveSwap.sol";

import "../utils/GasThrottler.sol";

contract ShipyardOneClickCurve is Ownable, ReentrancyGuard, GasThrottler {

    using SafeERC20 for IERC20;
    using SafeERC20 for IShipyardVault;
    using SafeMath for uint256;

    address usdcAddress;

    constructor(
        address _usdcAddress
    ) public {
        usdcAddress = _usdcAddress;
    }

    function deposit(address _shipyardVaultAddress, address _depositTokenAddress, uint256 _amountInDepositToken) external nonReentrant {

        IShipyardVault shipyardVault = IShipyardVault(_shipyardVaultAddress);
        IStrategy strategy = shipyardVault.strategy();

        address poolTokenAddress = (address)(strategy.want());

        bool isUnderlyingToken = strategy.underlyingToken(_depositTokenAddress);

        require(isUnderlyingToken || _depositTokenAddress == usdcAddress || _depositTokenAddress == poolTokenAddress, 'Invalid deposit token address');

        if (isUnderlyingToken || _depositTokenAddress == poolTokenAddress) {

            IERC20(_depositTokenAddress).safeTransferFrom(msg.sender, address(this), _amountInDepositToken);

        } else if (_depositTokenAddress == usdcAddress) {

            address preferredTokenAddress = strategy.preferredUnderlyingToken();

            IERC20(usdcAddress).safeTransferFrom(msg.sender, address(this), _amountInDepositToken);

            // Swap into preferredToken

            address[] memory paths;
            paths[0] = usdcAddress;
            paths[1] = preferredTokenAddress;

            address unirouterAddress = strategy.unirouter();

            _approveTokenIfNeeded(usdcAddress, unirouterAddress);

            IUniswapRouterETH(unirouterAddress).swapExactTokensForTokens(_amountInDepositToken, 0, paths, address(this), block.timestamp);

            _amountInDepositToken = IERC20(preferredTokenAddress).balanceOf(address(this));
            _depositTokenAddress = preferredTokenAddress;
        }

        address poolAddress = strategy.pool();

        if (_depositTokenAddress != poolTokenAddress) {

            uint256 depositTokenIndex = strategy.underlyingTokenIndex(_depositTokenAddress);
            uint256 poolSize = strategy.poolSize();

            _approveTokenIfNeeded(_depositTokenAddress, poolAddress);

            if (poolSize == 2) {
                uint256[2] memory amounts;
                amounts[depositTokenIndex] = _amountInDepositToken;
                ICurveSwap(poolAddress).add_liquidity(amounts, 0);

            } else if (poolSize == 3) {
                uint256[3] memory amounts;
                amounts[depositTokenIndex] = _amountInDepositToken;
                ICurveSwap(poolAddress).add_liquidity(amounts, 0);

            } else if (poolSize == 4) {
                uint256[4] memory amounts;
                amounts[depositTokenIndex] = _amountInDepositToken;
                ICurveSwap(poolAddress).add_liquidity(amounts, 0);

            } else if (poolSize == 5) {
                uint256[5] memory amounts;
                amounts[depositTokenIndex] = _amountInDepositToken;
                ICurveSwap(poolAddress).add_liquidity(amounts, 0);
            }
        }

        uint256 amountPoolToken = IERC20(poolAddress).balanceOf(address(this));

        // We now have the pool token so let’s call our vault contract

        _approveTokenIfNeeded(poolTokenAddress, _shipyardVaultAddress);

        shipyardVault.deposit(amountPoolToken);

        // After we get back the shipyard LP token we can give to the sender

        uint256 amountShipyardToken = shipyardVault.balanceOf(address(this));

        shipyardVault.safeTransfer(msg.sender, amountShipyardToken);
    }

    function withdraw(address _shipyardVaultAddress, address _requestedTokenAddress, uint256 _withdrawAmountInShipToken) external nonReentrant {

        IShipyardVault shipyardVault = IShipyardVault(_shipyardVaultAddress);
        IStrategy strategy = shipyardVault.strategy();

        bool isUnderlyingToken = strategy.underlyingToken(_requestedTokenAddress);

        address poolTokenAddress = (address)(strategy.want());

        require(isUnderlyingToken || _requestedTokenAddress == poolTokenAddress || _requestedTokenAddress == usdcAddress, 'Invalid withdraw token address');

        shipyardVault.safeTransferFrom(msg.sender, address(this), _withdrawAmountInShipToken);

        shipyardVault.withdraw(_withdrawAmountInShipToken);

        uint256 poolTokenBalance = IERC20(poolTokenAddress).balanceOf(address(this));

        if (_requestedTokenAddress == poolTokenAddress) {

            IERC20(poolTokenAddress).safeTransfer(msg.sender, poolTokenBalance);
            return;
        }

        address poolAddress = strategy.pool();

        _approveTokenIfNeeded(poolTokenAddress, poolAddress);

        if (isUnderlyingToken) {

            ICurveSwap(poolAddress).remove_liquidity_one_coin(
                poolTokenBalance,
                int128(strategy.underlyingTokenIndex(_requestedTokenAddress)),
                0
            );

            uint256 outputTokenBalance = IERC20(_requestedTokenAddress).balanceOf(address(this));

            IERC20(_requestedTokenAddress).safeTransfer(msg.sender, outputTokenBalance);
            return;
        }

        // Withdraw token must be USDC by this point

        address preferredTokenAddress = strategy.preferredUnderlyingToken();

        ICurveSwap(poolAddress).remove_liquidity_one_coin(
            poolTokenBalance,
            int128(strategy.underlyingTokenIndex(preferredTokenAddress)),
            0
        );

        // Swap from preferredToken to USDC

        address[] memory paths;
        paths[0] = preferredTokenAddress;
        paths[1] = usdcAddress;

        address unirouter = strategy.unirouter();

        _approveTokenIfNeeded(preferredTokenAddress, unirouter);

        IUniswapRouterETH(unirouter).swapExactTokensForTokens(_withdrawAmountInShipToken, 0, paths, address(this), block.timestamp);

        uint256 usdcBalance = IERC20(usdcAddress).balanceOf(address(this));

        IERC20(usdcAddress).safeTransfer(msg.sender, usdcBalance);
    }

    function _approveTokenIfNeeded(address token, address spender) internal {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).safeApprove(spender, uint256(~0));
        }
    }
}