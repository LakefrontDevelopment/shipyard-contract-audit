// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IWrappedNative is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}
