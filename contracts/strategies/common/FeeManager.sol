// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./StratManager.sol";

abstract contract FeeManager is StratManager {
    // Fees are set as a multiple of 0.01%.
    uint constant public FEE_DENOMINATOR = 10000;

    uint constant public MAX_HARVEST_CALL_FEE = 100;
    uint constant public MAX_PERFORMANCE_FEE = 450;
    uint constant public MAX_STRATEGIST_FEE = 450;
    uint constant public MAX_WITHDRAWAL_FEE = 10;

    uint public harvestCallFee = 0;
    uint public performanceFee = 200;
    uint public strategistFee = 0;
    uint public withdrawalFee = 5;

    function setHarvestCallFee(uint256 _fee) public onlyManager {
        require(_fee <= MAX_HARVEST_CALL_FEE, "!cap");

        harvestCallFee = _fee;
    }

    function setPerformanceFee(uint256 _fee) public onlyManager {
        require(_fee <= MAX_PERFORMANCE_FEE, "!cap");

        performanceFee = _fee;
    }

    function setStrategistFee(uint256 _fee) public onlyManager {
        require(_fee <= MAX_STRATEGIST_FEE, "!cap");

        strategistFee = _fee;
    }

    function setWithdrawalFee(uint256 _fee) public onlyManager {
        require(_fee <= MAX_WITHDRAWAL_FEE, "!cap");

        withdrawalFee = _fee;
    }
}