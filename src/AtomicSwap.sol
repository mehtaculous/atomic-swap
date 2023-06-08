// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IAtomicSwap} from "./IAtomicSwap.sol";

/// @title Atomic Swap
/// @author swa.eth
/// @notice Conducts atomic over-the-counter (OTC) swaps of ERC-20 tokens
contract AtomicSwap is IAtomicSwap {
    /// @notice Mapping of swap ID to swap details
    mapping(uint256 => IAtomicSwap.SwapInfo) public swaps;

    /// @notice Initializes a new swap and transfers caller's tokens to contract
    /// @param _tokenX Contract address of initiator's token
    /// @param _amountX Amount of tokens being swapped by initiator
    /// @param _counterparty Address of the counterparty
    /// @param _tokenY Contract address of the counterparty's token
    /// @param _amountX Amount of tokens being swapped by the counterparty
    /// @param _expiry Unix timestamp for when swap is no longer valid
    /// returns swapId ID generated from the hashed swap info
    function initialize(
        address _tokenX,
        uint128 _amountX,
        address _counterparty,
        address _tokenY,
        uint128 _amountY,
        uint88 _expiry
    ) external returns (uint256 swapId) {
        // Generates swap ID from swap info
        swapId = getSwapId(
            msg.sender,
            _tokenX,
            _amountX,
            _counterparty,
            _tokenY,
            _amountY,
            _expiry
        );
        // Reverts if swap already exists
        if (swaps[swapId].initialized) revert AlreadyInitialized();
        // Reverts if swap expiration is not greater than current time
        if (_expiry <= block.timestamp) revert InvalidExpiry();

        // Maps swap ID to newly created swap info
        swaps[swapId] = IAtomicSwap.SwapInfo({
            initialized: true,
            expiry: _expiry,
            initiator: msg.sender,
            tokenX: _tokenX,
            amountX: _amountX,
            counterparty: _counterparty,
            tokenY: _tokenY,
            amountY: _amountY
        });

        // Transfers tokens from caller to contract
        IERC20(_tokenX).transferFrom(msg.sender, address(this), _amountX);

        // Emits initialized event of new swap info
        emit Initialized(
            swapId,
            msg.sender,
            _tokenX,
            _amountX,
            _counterparty,
            _tokenY,
            _amountY,
            _expiry
        );
    }

    /// @notice Executes an initialized swap and escrows specified token amounts to both parties
    /// @param _swapId ID of the swap
    function execute(uint256 _swapId) external {
        IAtomicSwap.SwapInfo memory swap = swaps[_swapId];
        // Reverts if swap does not exist
        if (!swap.initialized) revert NotInitialized();
        // Reverts if caller is not set as counterparty of swap
        if (swap.counterparty != msg.sender) revert NotAuthorized();
        // Reverts if swap has expired
        if (swap.expiry <= block.timestamp) revert SwapExpired();

        // Deletes swap info
        delete swaps[_swapId];

        // Transfers token amounts to respective parties
        IERC20(swap.tokenY).transferFrom(msg.sender, swap.initiator, swap.amountY);
        IERC20(swap.tokenX).transfer(msg.sender, swap.amountX);

        // Emits event for successfully executing swap
        emit Executed(_swapId);
    }

    /// @notice Cancels an initialized swap and transfers token amount back to the initiator
    /// @param _swapId ID of the swap
    function cancel(uint256 _swapId) external {
        IAtomicSwap.SwapInfo memory swap = swaps[_swapId];
        // Reverts if swap does not exist
        if (!swap.initialized) revert NotInitialized();
        // Reverts if caller is not initiator of swap
        if (swap.initiator != msg.sender) revert NotAuthorized();

        // Deletes swap info
        delete swaps[_swapId];

        // Transfers token amount back to caller
        IERC20(swap.tokenX).transfer(msg.sender, swap.amountX);

        // Emits event for canceling swap
        emit Canceled(_swapId);
    }

    /// @notice Returns the unique swap ID generated from a hash of the swap info
    /// @param _counterparty Address of the initiator who is creating the swap
    /// @param _tokenX Contract address of initiator's token
    /// @param _amountX Amount of tokens being swapped by initiator
    /// @param _counterparty Address of the counterparty
    /// @param _tokenY Contract address of the counterparty's token
    /// @param _amountX Amount of tokens being swapped by the counterparty
    /// @param _expiry Unix timestamp for when swap is no longer valid
    function getSwapId(
        address _initiator,
        address _tokenX,
        uint128 _amountX,
        address _counterparty,
        address _tokenY,
        uint128 _amountY,
        uint88 _expiry
    ) public pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        _initiator,
                        _tokenX,
                        _amountX,
                        _counterparty,
                        _tokenY,
                        _amountY,
                        _expiry
                    )
                )
            );
    }
}
