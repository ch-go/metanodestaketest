MetaNodeStake
背景：去中心化交易所为了增加流动性，用户存入代币对后可以获取lp token，为了鼓励用户存入代币对，提供lp token的质押合约收益，质押token就可以获取收益。
功能层面：
- 支持多种资产质押：ETH 和任意 ERC20 都可以开池。
- 自动发放区块奖励：用户质押后按时间与比例持续获得 MetaNode 奖励。
- 质押与收益解耦：随时领取奖励，不影响本金。
- 解质押需等待：提取本金要先申请、等待锁定区块。
- 管理可配置：管理员可调奖励速率、池权重、最小质押额与锁定期。
用户操作（普通参与者）：
- depositETH / deposit：质押 ETH 或 ERC20。
- unstake：发起解质押请求（进入锁定期）。
- withdraw：判断是否解锁，然后提取已解锁的本金，如果有收益，需要另外调用claim接口领取收益。
- claim：领取奖励代币。
  管理员操作（ADMIN_ROLE）：
- setMetaNode：设置奖励代币地址。
- addPool：新增资金池（代币地址、权重、最小质押、锁定区块）。
- updatePoolInfo：更新池子的最小质押/锁定区块。
- setPoolWeight：调整池权重（影响奖励分配比例）。
- setStartBlock / setEndBlock：调整奖励时间窗口。
- setMetaNodePerBlock：调整每区块奖励数量。
- 允许升级合约实现（UUPS 模式）。
• 合约实现重点
- 多池质押：支持 ETH + ERC20 多池，按 poolWeight 分配区块奖励。
- 奖励累计模型：用 accMetaNodePerST + finishedMetaNode 做快照，确保奖励精确结算、避免重复领取。
 计算用户当前应得奖励：
      pending = user.stAmount * accMetaNodePerST - user.finishedMetaNode
    - 把 pending 加到 user.pendingMetaNode（只是记账，不转账）。
    - 最后更新 user.finishedMetaNode = user.stAmount * accMetaNodePerST
解释：本质上相等于纪录了这个节点的accMetaNodePerST（相当于纪录这个池子这个新增的收益，是一个累加的），等到下个有人操作的节点变化时，需要纪录一下这个人的当时那个ccMetaNodePerST累计到了多少，（其他人的不用记，因为其他人的这段时间内不管accMetaNodePerST如何变化，一直累计就行了accMetaNodePerST会一直变大一直累计，我最后把累计的最终值乘以我一直不变的amount就行了），然后从新开始积累。我需要纪录一下这个人此时的积累的值那个节点，为了方便以后从这个开始从新累积，从新开始累积时，这个人又是一个新的新amount了，下一次计算时也还是这个amout，所以干脆直接纪录新amount和此时这个节点accMetaNodePerST的乘积值，那下一次找到那个累计值，乘以不变的amout，再减掉上次纪录的，直接就是这段区间内获得的收益了。
accMetaNodePerST是一次一次的累加，每一次开始和结束amount都是一样的，如果amout变化了，就一个新的开始累加。
- 解质押延迟：unstake 立即减少份额并记请求，withdraw 仅在解锁后提取本金，claim提取收益。
- 权限与安全：ADMIN_ROLE/UPGRADE_ROLE 管理参数、暂停功能，可升级（UUPS），关键操作可暂停。
执行npx hardhat test solidity --coverage，单元测试报告

| Coverage Report             |        |             |                 |                                                               |
| --------------------------- | ------ | ----------- | --------------- | ------------------------------------------------------------- |
| File Path                   | Line % | Statement % | Uncovered Lines | Partially Covered Lines                                       |
| contracts/MetaNode.sol      | 100.00 | 100.00      | -               | -                                                             |
| contracts/MetaNodeStake.sol | 96.77  | 86.43       | 418, 508-516    | 512-514, 564-566, 571-573, 582-584, 628-643, 676-678, 693-695 |
| --------------------------- | ------ | ----------- | --------------- | ------------------------------------------------------------- |
| Total                       | 96.79  | 86.49       |                 |                                                               |
