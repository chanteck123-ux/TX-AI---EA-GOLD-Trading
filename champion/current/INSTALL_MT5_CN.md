# GSM GOLD 3-SOP EA MT5 安装说明

## 为什么会出现 Trade.mqh not found

`Trade.mqh` 是 MT5 自带的标准交易库。EA 中的写法：

```mql5
#include <Trade/Trade.mqh>
```

是正确写法。报错表示源码是在不完整或错误的 MetaEditor 数据目录中编译，并不表示策略代码缺少文件。

本机截图对应的错误目录是旧研究目录：

`work/backtest-v220/tradona-terminal`

这个目录不是正式安装入口，里面没有完整的 `MQL5/Include/Trade` 标准库。

## 正确安装

1. 打开准备使用的 FxPro 或 Tradona MT5。
2. 在 MT5 菜单选择“文件 -> 打开数据文件夹”。
3. 确认数据文件夹内存在 `MQL5/Include/Trade/Trade.mqh`。
4. 把 ZIP 内 `MQL5/Experts/` 下的 `.mq5` 和 `.ex5` 文件复制到该终端的 `MQL5/Experts/`。
5. 回到 MT5，在导航器的“EA 交易”上右键刷新。

如果只运行已经验证的 Champion，可以直接使用 `.ex5`，不需要重新编译。

如果需要查看或编译源码，必须从正确终端的数据文件夹打开 `.mq5`，然后按 `F7`。不要直接从 ZIP、下载目录或旧 `work/backtest-*` 目录编译。

## 已验证结果

- FxPro MetaEditor：`0 errors, 0 warnings`。
- Tradona MetaEditor：`0 errors, 0 warnings`。
- 策略源码 SHA256：`AC9826E6EF4959562B9079A1FF9B8CBB35E5E8C2A913E431488CA5C900D1FF60`。
- 回测 Champion EX5 SHA256：`CBBB0FF7EC33DE8E31ACD7711F584A01A7E027A19EB446F593BFF0DA7F1B3269`。

本次只修正安装与交付结构，没有改变任何入场、出场、风控或三策略 OR 执行逻辑。
