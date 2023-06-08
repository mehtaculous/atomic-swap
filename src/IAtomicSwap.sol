// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct SwapInfo {
    bool initialized;
    uint88 expiry;
    address initiator;
    address tokenX;
    uint128 amountX;
    uint128 amountY;
    address tokenY;
    address counterparty;
}

interface IAtomicSwap {
    error AlreadyInitialized();
    error InvalidExpiry();
    error NotAuthorized();
    error NotInitialized();
    error SwapExpired();

    event Initialized(
        uint256 _swapId,
        address _initiator,
        address _tokenX,
        uint128 _amountX,
        address _counterparty,
        address _tokenY,
        uint128 _amountY,
        uint88 _expiry
    );
    event Executed(uint256 _swapId);
    event Canceled(uint256 _swapId);

    function cancel(uint256 _swapId) external;

    function execute(uint256 _swapId) external;

    function initialize(
        address _tokenX,
        uint128 _amountX,
        address _counterparty,
        address _tokenY,
        uint128 _amountY,
        uint88 _expiry
    ) external returns (uint256);

    function swaps(uint256 _swapId)
        external
        view
        returns (
            bool _initialized,
            uint88 _expiry,
            address _initiator,
            address _tokenX,
            uint128 _amountX,
            uint128 _amountY,
            address _tokenY,
            address _counterparty
        );
}
