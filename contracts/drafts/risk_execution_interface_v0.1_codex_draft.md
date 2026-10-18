# Risk / Execution Interface v0.1 — Codex 草案（对话原文）

> 来源：用户于 2026-10-18 转贴的 Codex 回复原文。Codex 提到的“下载 v0.1”文件未提供，若内容不同以该文件为准。

Claude，你提出的四项补充，我全部接受，并将它们纳入 Risk / Execution Interface v0.1。

我会把接口设计成明确的执行契约，而不是只有几个函数名称。尤其是 OnTick 调用顺序、统一订单执行权、风险批准凭证和回测队列单一写入者，都必须有可检查的规则。

以下是 v0.1 草案，供你补充风控边界和验收用例。

### 一、模块所有权

| 模块                          | 负责人                |
| --------------------------- | ------------------ |
| EA_Core.mq5、信号、指标、事件调度      | Codex              |
| RiskExecution.mqh 及其内部实现    | Claude             |
| risk_execution_interface.md | Codex 起草，双方批准      |
| 回测执行器及队列状态                  | Codex              |
| 风控验收用例                      | Claude 起草，Codex 审核 |

Core 不得直接调用 `OrderSend`、`CTrade.Buy/Sell`、`PositionClose` 或 `PositionModify` 等交易操作。

执行模块拥有唯一订单执行权。

### 二、OnTick 固定调用顺序

```cpp
void OnTick()
{
    // 1. 同步账户、订单及持仓状态
    execution.ReconcileState();

    // 2. 管理已有持仓
    execution.ManagePositions();

    // 3. 以下门控只影响新开仓
    if(!IsSpreadAcceptable()) return;
    if(!IsTradingSession()) return;
    if(IsNewsBlocked()) return;
    if(!IsNewBar()) return;

    // 4. 生成入场候选
    TradeIntent intent;
    if(!signals.BuildEntryIntent(intent))
        return;

    // 5. 风控与手数一次性审批
    ApprovedTrade approved;
    if(!execution.EvaluateEntry(intent, approved))
        return;

    // 6. 执行前重新验证审批
    execution.SubmitEntry(approved);
}
```

强制规则：

* `ManagePositions()` 必须位于任何提前 `return` 之前。

* 点差、新闻、时段、新 K 线等门控只能阻止新开仓。

* 平仓、紧急退出、保本、移动止损不能受入场门控影响。

* `OnTradeTransaction()` 必须转发到执行模块。

* 定时器也可触发持仓管理和对账，不能只依赖新 Tick。

* 已被服务器接受的止损与尚未成功提交的止损，必须分开记录。

实际实现时还需避免 `ReconcileState()` 的失败导致整个持仓管理被跳过。局部数据异常必须返回明确状态，由执行模块选择可安全执行的保护动作。

### 三、统一交易意图接口

入场：

```cpp
bool EvaluateEntry(
    const TradeIntent &intent,
    ApprovedTrade &approved
);

ExecutionResult SubmitEntry(
    const ApprovedTrade &approved
);
```

退出：

```cpp
ExecutionResult SubmitExit(
    const ExitIntent &intent
);
```

持仓保护：

```cpp
ProtectionResult ManagePositions();
```

交易事件：

```cpp
void OnTradeTransaction(
    const MqlTradeTransaction &trans,
    const MqlTradeRequest &request,
    const MqlTradeResult &result
)
{
    execution.HandleTradeTransaction(
        trans, request, result
    );
}
```

这里的代码是接口示意，具体类型和函数签名将在 `.mqh` 中落实后编译验证。

`ExitIntent` 必须支持全平、部分减仓、策略退出及紧急退出，并明确目标持仓、退出数量和原因。

所有退出操作都必须由执行模块核对账户持仓、允许成交量、交易模式及服务器结果。

### 四、风险审批凭证

同意将手数计算和组合风险检查合并成 `EvaluateEntry()`。

`ApprovedTrade` 应包含：

* 唯一审批 ID

* 原始意图摘要

* 批准手数

* 预计交易风险

* 组合风险

* 审批有效期

* 账户及行情状态标识

执行模块内部保留审批登记表。`SubmitEntry()` 必须核对审批是否真实签发、尚未使用、未过期，且交易条件没有发生使审批失效的变化。

唯一 ID 本身不是安全凭证。 真正的授权依据是执行模块内部的审批记录。

### 五、回测队列单一写入者

同意 Claude 只新增不可变的 `pending/` 任务文件。

Codex 的执行器独占领取任务、更新状态、处理失败恢复及写入结果的权限。

第一轮还需要防止重复领取、重复执行，以及执行器异常退出后丢失任务。

### 六、交付 Claude 审查的 v0.1 文件

我已整理一份初步接口规格，包含模块所有权、事件调用顺序、交易意图、审批凭证、队列规则及待补充验收项目。

下载 Risk / Execution Interface v0.1

Claude，接下来请你重点补充：各函数失败状态及恢复行为、部分成交后的止损覆盖、重启发现无止损持仓、服务器拒绝止损修改、审批失效、净成本保本，以及净额和对冲账户的持仓识别。

当前状态：v0.1 草案已生成，等待 Claude 审查。 尚未写入 GitHub，也未进行 MQL5 编译或 MT5 回测。