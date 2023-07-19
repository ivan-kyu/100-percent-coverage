// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "../src/StakeToken.sol";
import "../src/LimeToken.sol";
import "openzeppelin/token/ERC20/IERC20.sol";

contract StakeTokenTest is Test {
    IERC20 limeToken;
    StakeToken stakeToken;

    address alice = address(1);
    address bob = address(2);

    uint256 stakeAmount = 1000 * 10 ** 18;

    function setUp() public {
        limeToken = new LimeToken();
        stakeToken = new StakeToken(limeToken);

        limeToken.transfer(alice, stakeAmount * 100);
        limeToken.transfer(bob, stakeAmount * 100);

        // the pool needs to have some initial liquidity
        limeToken.transfer(address(stakeToken), stakeAmount * 10);
    }

    function testConstructor() public {
        assertEq(address(stakeToken.limeToken()), address(limeToken));
        assertEq(stakeToken.planDuration(), 2592000);
        assertEq(stakeToken.interestRate(), 32);
        assertEq(stakeToken.totalStakers(), 0);
    }

    function testAllowance() public {
        vm.prank(alice);
        limeToken.approve(address(stakeToken), stakeAmount);

        assertEq(limeToken.allowance(alice, address(stakeToken)), stakeAmount);
    }

    // Test Stake
    function testStake() public {
        vm.startPrank(alice);
        limeToken.approve(address(stakeToken), stakeAmount);

        uint256 balanceBeforeStakeContract = limeToken.balanceOf(address(stakeToken));
        uint256 stakerBalanceBefore = limeToken.balanceOf(alice);

        stakeToken.stakeToken(stakeAmount);

        uint256 balanceAfterStakeContract = limeToken.balanceOf(address(stakeToken));
        uint256 stakerBalanceAfter = limeToken.balanceOf(alice);

        (uint256 startTS, uint256 endTS, uint256 amount, uint256 claimed) = stakeToken.stakeInfos(alice);
        assertEq(startTS, block.timestamp);
        assertEq(endTS, block.timestamp + stakeToken.planDuration());

        assertEq(amount, stakeAmount);
        assertEq(claimed, 0);

        assertEq(balanceBeforeStakeContract + stakeAmount, balanceAfterStakeContract);
        assertEq(stakerBalanceBefore - stakeAmount, stakerBalanceAfter);

        assertEq(stakeToken.totalStakers(), 1);
        assertTrue(stakeToken.addressStaked(alice));
    }

    function testStakeRevert_ZeroStake() public {
        vm.startPrank(alice);
        limeToken.approve(address(stakeToken), stakeAmount);

        vm.expectRevert("Stake amount should be correct");
        stakeToken.stakeToken(0);
    }

    function testStakeRevert_PlanExpired() public {
        vm.startPrank(alice);
        limeToken.approve(address(stakeToken), stakeAmount);

        vm.warp(stakeToken.planExpired()); // Warp past plan expiration time

        vm.expectRevert("Plan Expired");
        stakeToken.stakeToken(stakeAmount);
    }

    function testStakeRevert_YouAlreadyParticipated() public {
        vm.startPrank(alice);
        limeToken.approve(address(stakeToken), stakeAmount);

        stakeToken.stakeToken(stakeAmount);

        vm.expectRevert("You already participated");
        stakeToken.stakeToken(stakeAmount);
    }

    function testStakeRevert_InsufficientBalance() public {
        vm.startPrank(alice);
        uint256 newStakeAmount = stakeAmount * 100 + 100;

        limeToken.approve(address(stakeToken), newStakeAmount);

        vm.expectRevert("Insufficient Balance");
        stakeToken.stakeToken(newStakeAmount);
    }

    // Test Claim
    function testClaim() public {
        vm.startPrank(alice);
        limeToken.approve(address(stakeToken), stakeAmount);

        stakeToken.stakeToken(stakeAmount);
        uint256 stakerBalanceBefore = limeToken.balanceOf(alice);

        vm.warp(stakeToken.planExpired()); // Warp past plan expiration time

        stakeToken.claimReward();

        uint256 stakerBalanceAfter = limeToken.balanceOf(alice);

        assertEq(
            stakerBalanceBefore + stakeAmount + (stakeAmount * stakeToken.interestRate() / 100), stakerBalanceAfter
        );
    }

    function testClaimRevert_NotParticipated() public {
        vm.startPrank(bob);

        vm.expectRevert("You are not participated");
        stakeToken.claimReward();
    }

    function testClaimRevert_TooEarly() public {
        vm.startPrank(alice);
        limeToken.approve(address(stakeToken), stakeAmount);

        stakeToken.stakeToken(stakeAmount);

        vm.expectRevert("Stake Time is not over yet");
        stakeToken.claimReward();
    }

    function testClaimRevert_AlreadyClaimed() public {
        vm.startPrank(alice);
        limeToken.approve(address(stakeToken), stakeAmount);

        stakeToken.stakeToken(stakeAmount);

        vm.warp(stakeToken.planExpired()); // Warp past plan expiration time

        stakeToken.claimReward();

        vm.expectRevert("Already claimed");
        stakeToken.claimReward();
    }

    // Test Pausable
    function testPause() public {
        stakeToken.pause();

        vm.startPrank(alice);
        limeToken.approve(address(stakeToken), stakeAmount);

        vm.expectRevert("Pausable: paused");
        stakeToken.stakeToken(stakeAmount);
    }

    function testUnpause() public {
        stakeToken.pause();

        vm.startPrank(alice);
        limeToken.approve(address(stakeToken), stakeAmount);

        vm.expectRevert("Pausable: paused");
        stakeToken.stakeToken(stakeAmount);

        vm.stopPrank();
        stakeToken.unpause();

        vm.startPrank(alice);
        stakeToken.stakeToken(stakeAmount);
    }

    function testTransferToken() public {
        uint256 bobsBalanceBefore = limeToken.balanceOf(bob);

        uint256 transferAmount = 1000;
        stakeToken.transferToken(bob, transferAmount);

        uint256 bobsBalanceAfter = limeToken.balanceOf(bob);

        assertEq(bobsBalanceAfter, bobsBalanceBefore + transferAmount);
    }

    function testGetTokenExpiry() public {
        vm.startPrank(alice);
        limeToken.approve(address(stakeToken), stakeAmount);

        stakeToken.stakeToken(stakeAmount);

        assertEq(stakeToken.getTokenExpiry(), block.timestamp + stakeToken.planDuration());
    }

    // Test Claim - Fuzzing
    function testFuzzClaim(uint256 _stakeAmount) public {
        vm.assume(_stakeAmount < stakeAmount && _stakeAmount > 0);

        vm.startPrank(alice);
        limeToken.approve(address(stakeToken), _stakeAmount);

        stakeToken.stakeToken(_stakeAmount);
        uint256 stakerBalanceBefore = limeToken.balanceOf(alice);

        vm.warp(stakeToken.planExpired()); // Warp past plan expiration time

        stakeToken.claimReward();

        uint256 stakerBalanceAfter = limeToken.balanceOf(alice);

        assertEq(
            stakerBalanceBefore + _stakeAmount + (_stakeAmount * stakeToken.interestRate() / 100), stakerBalanceAfter
        );
    }
}
