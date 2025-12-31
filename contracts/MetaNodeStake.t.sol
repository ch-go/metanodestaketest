// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";

import {MetaNodeStake} from "./MetaNodeStake.sol";
import {MetaNodeToken} from "./MetaNode.sol";

contract MetaNodeStakeTest is Test {
  MetaNodeStake stake;
  MetaNodeToken metaNode;

  address user = address(0x1);
  address admin = address(0x2);

  function setUp() public {
    vm.startPrank(admin);
    metaNode = new MetaNodeToken();
    stake = new MetaNodeStake();

    uint256 startBlock = block.number + 2;
    uint256 endBlock = startBlock + 50;
    uint256 rewardPerBlock = 1 ether;

    stake.initialize(metaNode, startBlock, endBlock, rewardPerBlock);
    stake.addPool(address(0), 100, 1 ether, 3, false);

    metaNode.transfer(address(stake), 1000 ether);
    vm.deal(user, 10 ether);
  }

  function test_StakeClaimWithdraw_ETH() public {
    vm.roll(block.number + 2);

    vm.startPrank(user);
    stake.depositETH{value: 1 ether}();

    vm.roll(block.number + 5);
    uint256 pending = stake.pendingMetaNode(0, user);
    assertTrue(pending > 0, "pending should grow after mining");

    uint256 balanceBefore = metaNode.balanceOf(user);
    vm.startPrank(user);
    stake.claim(0);
    uint256 balanceAfter = metaNode.balanceOf(user);
    assertTrue(balanceAfter > balanceBefore, "claim should transfer MetaNode");

    vm.startPrank(user);
    stake.unstake(0, 0.4 ether);

    (uint256 requestAmount, uint256 pendingWithdraw) = stake.withdrawAmount(0, user);
    assertEq(requestAmount, 0.4 ether, "request amount mismatch");
    assertEq(pendingWithdraw, 0, "should still be locked");

    vm.roll(block.number + 3);
    uint256 contractBalanceBefore = address(stake).balance;
    vm.startPrank(user);
    stake.withdraw(0);
    uint256 contractBalanceAfter = address(stake).balance;
    assertEq(contractBalanceBefore - contractBalanceAfter, 0.4 ether, "withdraw amount mismatch");

    (uint256 requestAmountAfter, uint256 pendingWithdrawAfter) = stake.withdrawAmount(0, user);
    assertEq(requestAmountAfter, 0, "request list should be cleared");
    assertEq(pendingWithdrawAfter, 0, "pending should be cleared");
  }
  function test_setMetaNode() public{
      vm.startPrank(admin);
      stake.setMetaNode(metaNode);
  }
  function test_pauseWithdraw() public{
      vm.startPrank(admin);
      stake.pauseWithdraw();
      assertEq(stake.withdrawPaused(), true);
  }
  function test_unpauseWithdraw() public{
      vm.startPrank(admin);
      stake.pauseWithdraw();
      assertEq(stake.withdrawPaused(), true);
      stake.unpauseWithdraw();
      assertEq(stake.withdrawPaused(), false);
  }
  function test_pauseClaim() public{
      vm.startPrank(admin);
      stake.pauseClaim();
      assertEq(stake.claimPaused(), true);
      stake.unpauseClaim();
      assertEq(stake.claimPaused(), false);
  }
  function test_setMetaNodePerBlock() public{
      vm.startPrank(admin);
      stake.setMetaNodePerBlock(2 ether);
      assertEq(stake.MetaNodePerBlock(), 2 ether);
  }
}
