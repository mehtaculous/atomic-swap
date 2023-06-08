// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/AtomicSwap.sol";
import "src/Token.sol";

contract AtomicSwapTest is Test {
    // Contracts
    AtomicSwap atomic;
    Token aliceToken;
    Token bobToken;

    // Users
    address alice = address(111);
    address bob = address(222);
    address eve = address(333);

    // SwapInfo
    uint256 swapId;
    address initiator;
    address counterparty;
    address tokenX;
    address tokenY;
    uint128 amountX;
    uint128 amountY;
    uint88 expiry;
    bool initialized;

    // State
    uint88 expiration;
    uint128 aliceAmount = 500 * 10**18;
    uint128 bobAmount = 1000 * 10**18;

    // Constants
    uint256 constant BALANCE = 100 ether;
    uint256 constant SUPPLY = 1000000000;

    // Errors
    bytes INSUFFICIENT_ALLOWANCE_ERROR = bytes("ERC20: insufficient allowance");
    bytes4 ALREADY_INITIALIZED_ERROR = IAtomicSwap.AlreadyInitialized.selector;
    bytes4 INVALID_EXPIRY_ERROR = IAtomicSwap.InvalidExpiry.selector;
    bytes4 NOT_AUTHORIZED_ERROR = IAtomicSwap.NotAuthorized.selector;
    bytes4 NOT_INITIALIZED_ERROR = IAtomicSwap.NotInitialized.selector;
    bytes4 SWAP_EXPIRED_ERROR = IAtomicSwap.SwapExpired.selector;

    /// =====================
    /// ===== MODIFIERS =====
    /// =====================
    modifier prank(address _caller) {
        vm.startPrank(_caller);
        _;
        vm.stopPrank();
    }

    /// =================
    /// ===== SETUP =====
    /// =================
    function setUp() public {
        atomic = new AtomicSwap();
        vm.prank(alice);
        aliceToken = new Token("AliceToken", "ALICE", SUPPLY);
        vm.prank(bob);
        bobToken = new Token("BobToken", "BOB", SUPPLY);

        expiration = uint88(block.timestamp + 7 days);
        
        vm.label(address(atomic), "AtomicSwap");
        vm.label(address(aliceToken), "AliceToken");
        vm.label(address(bobToken), "BobToken");

        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(eve, "Eve");

        vm.deal(alice, BALANCE);
        vm.deal(bob, BALANCE);
        vm.deal(eve, BALANCE);
    }

    /// ======================
    /// ===== INITIALIZE =====
    /// ======================
    function testInitialize() public {
        // setup
        _approve(alice, address(aliceToken), address(atomic), aliceAmount);
        // execute
        _initialize(alice, address(aliceToken), aliceAmount, bob, address(bobToken), bobAmount, expiration);
        // assert
        assertEq(initialized, true);
        assertEq(initiator, alice);
        assertEq(counterparty, bob);
        assertEq(tokenX, address(aliceToken));
        assertEq(amountX, aliceAmount);
        assertEq(tokenY, address(bobToken));
        assertEq(amountY, bobAmount);
        assertEq(expiry, expiration);
        assertEq(aliceToken.balanceOf(address(atomic)), aliceAmount);
        assertEq(aliceToken.balanceOf(alice), SUPPLY * 10**18 - aliceAmount);
    }

    function testInitializeRevertAlreadyInitialized() public {
        // setup
        testInitialize();
        // revert
        vm.expectRevert(ALREADY_INITIALIZED_ERROR);
        // execute
        _initialize(alice, address(aliceToken), aliceAmount, bob, address(bobToken), bobAmount, expiration);
    }

    function testInitializeRevertInvalidExpiry() public {
        // setup
        expiration = uint88(block.timestamp - 1);
        // revert
        vm.expectRevert(INVALID_EXPIRY_ERROR);
        // execute
        _initialize(alice, address(aliceToken), aliceAmount, bob, address(bobToken), bobAmount, expiration);
    }

    function testInitializeRevertInsufficientAllowance() public {
        // revert
        vm.expectRevert(INSUFFICIENT_ALLOWANCE_ERROR);
        // execute
        _initialize(alice, address(aliceToken), aliceAmount, bob, address(bobToken), bobAmount, expiration);
    }

    /// ===================
    /// ===== EXECUTE =====
    /// ===================
    function testExecute() public {
        // setup
        testInitialize();
        _approve(bob, address(bobToken), address(atomic), bobAmount);
        // execute
        _execute(bob, swapId);
        // assert
        assertEq(initialized, false);
        assertEq(aliceToken.balanceOf(address(atomic)), 0);
        assertEq(aliceToken.balanceOf(bob), aliceAmount);
        assertEq(bobToken.balanceOf(alice), bobAmount);
    }

    function testExecuteRevertNotInitialized() public {
        // revert
        vm.expectRevert(NOT_INITIALIZED_ERROR);
        // execute
        _execute(bob, swapId);
    }

    function testExecuteRevertNotAuthorized() public {
        // setup
        testInitialize();
        // revert
        vm.expectRevert(NOT_AUTHORIZED_ERROR);
        // execute
        _execute(eve, swapId);
    }

    function testExecuteRevertSwapExpired() public {
        // setup
        testInitialize();
        vm.warp(expiry);
        // revert
        vm.expectRevert(SWAP_EXPIRED_ERROR);
        // execute
        _execute(bob, swapId);
    }

    function testExecuteRevertInsufficientAllowance() public {
        // setup
        testInitialize();
        // revert
        vm.expectRevert(INSUFFICIENT_ALLOWANCE_ERROR);
        // execute
        _execute(bob, swapId);
    }

    /// ==================
    /// ===== CANCEL =====
    /// ==================
    function testCancel() public {
        // setup
        testInitialize();
        // execute
        _cancel(alice, swapId);
        // assert
        assertEq(initialized, false);
        assertEq(aliceToken.balanceOf(address(atomic)), 0);
        assertEq(aliceToken.balanceOf(alice), SUPPLY * 10**18);
    }

    function testCancelRevertNotInitialized() public {
        // setup
        testInitialize();
        _cancel(alice, swapId);
        // revert
        vm.expectRevert(NOT_INITIALIZED_ERROR);
        // execute
        _cancel(alice, swapId);
    }

    function testCancelRevertNotAuthorized() public {
        // setup
        testInitialize();
        // revert
        vm.expectRevert(NOT_AUTHORIZED_ERROR);
        // execute
        _cancel(eve, swapId);
    }

    /// ===================
    /// ===== HELPERS =====
    /// ===================

    function _approve(address _owner, address _token, address _spender, uint256 _amount) internal prank(_owner) {
        IERC20(_token).approve(_spender, _amount);
    }

    function _initialize(
        address _initiator,
        address _tokenX,
        uint128 _amountX,
        address _counterparty,
        address _tokenY,
        uint128 _amountY,
        uint88 _expiry
    ) internal prank(_initiator) {
        swapId = atomic.initialize(
            _tokenX,
            _amountX,
            _counterparty,
            _tokenY,
            _amountY,
            _expiry
        );
        _setInitInfo(swapId);
        _setSwapInfo(swapId);
    }

    function _execute(address _caller, uint256 _swapId) internal prank(_caller) {
        atomic.execute(_swapId);
        _setInitInfo(_swapId);
        _setSwapInfo(_swapId);
    }

    function _cancel(address _caller, uint256 _swapId) internal prank(_caller) {
        atomic.cancel(_swapId);
        _setInitInfo(_swapId);
        _setSwapInfo(_swapId);
    }

    function _setInitInfo(uint256 _swapId) internal {
        (initialized, expiry,,,,,,) = atomic.swaps(_swapId);
    }

    function _setSwapInfo(uint256 _swapId) internal {
        (
            ,
            ,
            initiator,
            tokenX,
            amountX,
            amountY,
            tokenY,
            counterparty
        ) = atomic.swaps(_swapId);
    }

    function _getSwapId(
        address _initiator,
        address _tokenX,
        uint128 _amountX,
        address _counterparty,
        address _tokenY,
        uint128 _amountY,
        uint88 _expiry
    ) internal {
        swapId = atomic.getSwapId(
            _initiator, 
            _tokenX, 
            _amountX, 
            _counterparty, 
            _tokenY, 
            _amountY, 
            _expiry
        );
    }
}