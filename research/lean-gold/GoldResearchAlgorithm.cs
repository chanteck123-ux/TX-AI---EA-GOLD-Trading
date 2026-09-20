// Independent research candidate, not the user's MT5 EA or Scalping SOP.
// Copyright 2026. Licensed under the Apache License, Version 2.0.
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;
using QuantConnect;
using QuantConnect.Algorithm;
using QuantConnect.Brokerages;
using QuantConnect.Data;
using QuantConnect.Data.Market;
using QuantConnect.Indicators;
using QuantConnect.Orders;
using QuantConnect.Orders.Fees;
using QuantConnect.Orders.Slippage;
using QuantConnect.Securities;
namespace IndependentLeanGold
{
    // Completed H1 signals; native protective stop, close-triggered market target.
    public class GoldResearchAlgorithm:QCAlgorithm
    {
        private static readonly CultureInfo CI=CultureInfo.InvariantCulture;
        private Symbol _symbol;
        private ExponentialMovingAverage _fast,_slow;
        private AverageTrueRange _atr;
        private OrderTicket _stop;
        private decimal _initialCash,_riskFraction,_targetR,_feePerUnit,_slipPrice;
        private decimal _entryPrice,_entryFee,_entryQuantity,_entryDistance,_multiplier;
        private decimal _pendingDistance,_lotStep,_priceTick;
        private decimal _peakEquity,_maxDdUsd,_maxDdFraction,_commission,_slippageAllowance;
        private DateTime _entryTime,_lastExitTime=DateTime.MinValue,_lastBar=DateTime.MinValue;
        private DateTime _previousDataDate=DateTime.MinValue;
        private int _bars,_signals,_sizeSkips,_rejections,_overnightTransitions;
        private string _output,_runId;
        private readonly List<TradeRecord> _trades=new();
        private readonly List<EquityRecord> _equity=new();
        private decimal Parameter(string key,decimal fallback)
        {
            var text=GetParameter(key);return string.IsNullOrWhiteSpace(text)?fallback:decimal.Parse(text,CI);
        }
        public override void Initialize()
        {
            if(LiveMode)throw new InvalidOperationException("BACKTEST ONLY.");
            _initialCash=Parameter("initial-cash",1000m);_riskFraction=Parameter("risk-fraction",0.005m);
            _targetR=Parameter("target-r",2m);_feePerUnit=Parameter("fee-usd-per-unit-side",0.035m);_slipPrice=Parameter("slippage-price-per-side",0.05m);
            if(_initialCash<=0||_riskFraction<=0||_riskFraction>0.02m||_targetR<=0||_feePerUnit<0||_slipPrice<0)throw new ArgumentException("Invalid research parameters.");
            var start=DateTime.ParseExact(GetParameter("start-date"),"yyyy-MM-dd",CI);
            var endExclusive=DateTime.ParseExact(GetParameter("end-exclusive"),"yyyy-MM-dd",CI);
            if(start>=endExclusive)throw new ArgumentException("Empty period.");
            _output=Path.GetFullPath(GetParameter("evidence-dir"));_runId=GetParameter("run-id");Directory.CreateDirectory(_output);
            SetTimeZone("America/New_York");SetAccountCurrency("USD");SetCash(_initialCash);SetStartDate(start);SetEndDate(endExclusive.AddDays(-1));
            SetBrokerageModel(BrokerageName.OandaBrokerage,AccountType.Margin);Settings.SeedInitialPrices=false;
            var security=AddCfd("XAUUSD",Resolution.Hour,Market.Oanda,false,20m);_symbol=security.Symbol;
            security.SetFeeModel(new UnitFeeModel(_feePerUnit));security.SetSlippageModel(new AbsoluteSlippageModel(_slipPrice));SetBenchmark(_symbol);
            _multiplier=security.SymbolProperties.ContractMultiplier;_lotStep=security.SymbolProperties.LotSize;_priceTick=security.SymbolProperties.MinimumPriceVariation;
            if(_multiplier<=0||_lotStep<=0||_priceTick<=0||security.SymbolProperties.QuoteCurrency!="USD")throw new InvalidOperationException("Unsupported contract properties.");
            _fast=new ExponentialMovingAverage(20);_slow=new ExponentialMovingAverage(50);_atr=new AverageTrueRange(14,MovingAverageType.Wilders);
            _peakEquity=_initialCash;SetWarmUp(100,Resolution.Hour);
            Log($"GOLD_INIT run={_runId} start={start:yyyy-MM-dd} endExclusive={endExclusive:yyyy-MM-dd} cash={_initialCash} risk={_riskFraction} targetR={_targetR} multiplier={_multiplier} unitStep={_lotStep} tick={_priceTick} fee={_feePerUnit} slip={_slipPrice}");
        }
        public override void OnData(Slice data)
        {
            if(!data.QuoteBars.TryGetValue(_symbol,out var bar)||bar.IsFillForward||bar.EndTime==_lastBar)return;
            _lastBar=bar.EndTime;
            if(bar.Bid==null||bar.Ask==null||bar.Bid.Close<=0||bar.Ask.Close<bar.Bid.Close)throw new InvalidDataException("Missing or crossed bid/ask.");
            var oldFast=_fast.Current.Value;_fast.Update(bar.EndTime,bar.Close);_slow.Update(bar.EndTime,bar.Close);
            _atr.Update(new TradeBar(bar.Time,_symbol,bar.Open,bar.High,bar.Low,bar.Close,0,TimeSpan.FromHours(1)));
            if(IsWarmingUp)return;
            _bars++;if(_entryQuantity!=0&&_previousDataDate!=DateTime.MinValue&&Time.Date>_previousDataDate)_overnightTransitions++;
            _previousDataDate=Time.Date;SampleEquity(bar);
            if(!_fast.IsReady||!_slow.IsReady||!_atr.IsReady||_atr.Current.Value<=0)return;
            if(Portfolio[_symbol].Invested)
            {
                var q=Portfolio[_symbol].Quantity;var quote=q>0?bar.Bid.Close:bar.Ask.Close;
                var favorable=(quote-_entryPrice)*Math.Sign(q);
                if(Time.Hour>=16)ExitAtMarket("SESSION_CLOSE");else if(favorable>=_targetR*_entryDistance)ExitAtMarket("TARGET_CLOSE");
                SampleEquity(bar);return;
            }
            if(_lastExitTime==UtcTime||Time.Hour<8||Time.Hour>=15||Transactions.GetOpenOrders(_symbol).Count!=0||Portfolio.TotalPortfolioValue<=0)return;
            var f=_fast.Current.Value;var s=_slow.Current.Value;var direction=0;
            if(f>s&&f>oldFast&&bar.Low<=f&&bar.Close>f&&bar.Close>bar.Open)direction=1;
            if(f<s&&f<oldFast&&bar.High>=f&&bar.Close<f&&bar.Close<bar.Open)direction=-1;
            if(direction==0)return;
            _signals++;_pendingDistance=2m*_atr.Current.Value;
            var budget=Portfolio.TotalPortfolioValue*_riskFraction;
            var lossPerUnit=(_pendingDistance+2m*_slipPrice+_priceTick)*_multiplier+2m*_feePerUnit;
            var quantity=Math.Floor(budget/lossPerUnit/_lotStep)*_lotStep;
            var worstEntry=(direction>0?bar.Ask.Close:bar.Bid.Close)+direction*_slipPrice;
            var marginQuantity=Math.Floor(Math.Max(0m,Portfolio.MarginRemaining)*20m*0.90m/(worstEntry*_multiplier)/_lotStep)*_lotStep;
            quantity=Math.Min(quantity,marginQuantity);if(quantity<_lotStep){_sizeSkips++;return;}
            var ticket=MarketOrder(_symbol,direction*quantity,false,"ENTRY");
            if(ticket.Status!=OrderStatus.Filled){if(ticket.Status!=OrderStatus.Invalid)throw new InvalidOperationException("Non-immediate entry.");return;}
            var stopPrice=ticket.AverageFillPrice-direction*_pendingDistance;
            stopPrice=direction>0?Math.Floor(stopPrice/_priceTick)*_priceTick:Math.Ceiling(stopPrice/_priceTick)*_priceTick;
            _entryDistance=Math.Abs(ticket.AverageFillPrice-stopPrice);
            _stop=StopMarketOrder(_symbol,-direction*quantity,stopPrice,asynchronous:false,tag:"PROTECTIVE_STOP");
            if(_stop.Status==OrderStatus.Invalid)throw new InvalidOperationException("Protective stop rejected.");SampleEquity(bar);
        }
        private void ExitAtMarket(string reason)
        {
            if(_stop!=null&&_stop.Status!=OrderStatus.Filled&&_stop.Status!=OrderStatus.Canceled)
            {
                var response=_stop.Cancel("H1 close exit");if(response.IsError)throw new InvalidOperationException("Stop cancellation failed.");
            }
            _stop=null;var q=Portfolio[_symbol].Quantity;
            if(q!=0){var ticket=MarketOrder(_symbol,-q,false,reason);if(ticket.Status!=OrderStatus.Filled)throw new InvalidOperationException("Exit not filled.");}
        }
        public override void OnOrderEvent(OrderEvent e)
        {
            if(e.Status==OrderStatus.Invalid){_rejections++;Log("ORDER_REJECTED "+e);return;}
            if(e.Status==OrderStatus.PartiallyFilled)throw new InvalidOperationException("Partial fills unsupported in this ledger.");
            if(e.Status!=OrderStatus.Filled||e.FillQuantity==0)return;
            var order=Transactions.GetOrderById(e.OrderId);var fee=e.OrderFee.Value.Amount;
            if(e.OrderFee.Value.Currency!="USD"&&fee!=0)throw new InvalidOperationException("Non-USD fee.");
            _commission+=fee;_slippageAllowance+=Math.Abs(e.FillQuantity)*_slipPrice*_multiplier;
            if(_entryQuantity==0)
            {
                if(order.Tag!="ENTRY")throw new InvalidOperationException("Unexpected opening order.");
                _entryQuantity=e.FillQuantity;_entryPrice=e.FillPrice;_entryTime=e.UtcTime;_entryFee=fee;_entryDistance=_pendingDistance;return;
            }
            if(e.FillQuantity!=-_entryQuantity)throw new InvalidOperationException("Unexpected scaling/reversal.");
            var gross=(e.FillPrice-_entryPrice)*_entryQuantity*_multiplier;
            _trades.Add(new TradeRecord{EntryUtc=_entryTime,ExitUtc=e.UtcTime,Quantity=_entryQuantity,EntryPrice=_entryPrice,ExitPrice=e.FillPrice,
                GrossUsd=gross,CommissionUsd=_entryFee+fee,NetUsd=gross-_entryFee-fee,Reason=order.Tag});
            _entryQuantity=0;_entryFee=0;_stop=null;_lastExitTime=UtcTime;
        }
        private void SampleEquity(QuoteBar bar)
        {
            var security=Securities[_symbol];var q=Portfolio[_symbol].Quantity;
            // Pinned LEAN SecurityPortfolioManager adds CFD UnrealizedProfit, which calls
            // SecurityHolding.TotalCloseProfit with liquidation bid/ask AND estimated exit fee.
            // Adding another quote adjustment or subtracting exit fee again double-counts costs.
            var value=Portfolio.TotalPortfolioValue;
            var cash=Portfolio.CashBook.TotalValueInAccountCurrency+Portfolio.UnsettledCashBook.TotalValueInAccountCurrency;
            var quote=q>=0?security.BidPrice:security.AskPrice;
            if(quote==0)quote=security.Price;
            var expected=cash+q*(quote-security.Holdings.AveragePrice)*_multiplier-Math.Abs(q)*_feePerUnit;
            if(Math.Abs(value-expected)>0.00001m)throw new InvalidOperationException("CFD equity mark does not reconcile to cash/bid-ask/one exit fee.");
            _peakEquity=Math.Max(_peakEquity,value);_maxDdUsd=Math.Max(_maxDdUsd,_peakEquity-value);
            if(_peakEquity>0)_maxDdFraction=Math.Max(_maxDdFraction,(_peakEquity-value)/_peakEquity);
            _equity.Add(new EquityRecord{Utc=UtcTime,EquityUsd=value,CashUsd=cash,Quantity=q,EntryPrice=security.Holdings.AveragePrice,
                LiquidationQuote=quote,EstimatedExitFeeUsd=Math.Abs(q)*_feePerUnit});
        }
        public override void OnEndOfAlgorithm()
        {
            var positive=_trades.Where(t=>t.NetUsd>0).Sum(t=>t.NetUsd);var negative=-_trades.Where(t=>t.NetUsd<0).Sum(t=>t.NetUsd);
            var wins=_trades.Count(t=>t.NetUsd>0);var losses=_trades.Count(t=>t.NetUsd<0);var streak=0;var maxStreak=0;
            foreach(var t in _trades){streak=t.NetUsd<0?streak+1:0;maxStreak=Math.Max(maxStreak,streak);}
            var endEquity=Portfolio.TotalPortfolioValue;
            var reconciled=!Portfolio[_symbol].Invested&&Math.Abs(endEquity-_initialCash-_trades.Sum(t=>t.NetUsd))<0.02m;
            var result=new{
                run_id=_runId,status=reconciled?"BACKTEST_LEDGER_RECONCILED":"INCOMPLETE_LEDGER",
                engine="QuantConnect LEAN CSharp",strategy="H1_EMA20_50_PULLBACK_ATR14_SL2",strategy_origin="NEW_NON_USER_RESEARCH_NOT_MT5_SOP_PORT",
                initial_cash_usd=_initialCash,end_equity_usd=endEquity,net_profit_usd=endEquity-_initialCash,net_profit_percent=100m*(endEquity/_initialCash-1m),
                max_h1_sampled_liquidation_equity_dd_usd=_maxDdUsd,max_h1_sampled_relative_equity_dd_percent=_maxDdFraction*100m,
                equity_valuation="LEAN CFD total portfolio value = cash + liquidation bid/ask PnL - ONE estimated exit commission; each H1 snapshot reconciled.",
                net_profit_factor=negative>0?(decimal?)(positive/negative):null,profit_factor_definition="positive net round-trip PnL / absolute negative net round-trip PnL",
                closed_round_trips=_trades.Count,win_rate_percent=_trades.Count>0?100m*wins/_trades.Count:0m,
                average_net_win_usd=wins>0?positive/wins:0m,average_net_loss_usd=losses>0?negative/losses:0m,max_consecutive_losses=maxStreak,
                commission_usd=_commission,configured_slippage_allowance_usd=_slippageAllowance,
                slippage_accounting="Configured allowance is not measured actual slippage. Native fill prices drive PnL; do not subtract allowance again.",
                spread_cost="Bid/ask in fills, not separately decomposed; do not deduct twice.",target_r=_targetR,risk_fraction=_riskFraction,
                fee_usd_per_unit_side=_feePerUnit,slippage_price_per_side=_slipPrice,contract_multiplier=_multiplier,quantity_step=_lotStep,price_tick=_priceTick,
                traded_data_bars=_bars,qualified_signals=_signals,risk_or_margin_size_skips=_sizeSkips,rejected_orders=_rejections,
                overnight_date_transitions_while_holding=_overnightTransitions,swap_model="Not charged; intended NY16:00 flat. Overnight transitions require cost review.",
                final_open_quantity=Portfolio[_symbol].Quantity,cashflow_reconciliation_pass=reconciled,
                scope="Historical H1 research; no real-tick/OOS/MT5/FxPro/live/withdrawal validation.",score=(decimal?)null,score_status="SCORE_TARGETS_UNSET"
            };
            File.WriteAllText(Path.Combine(_output,"metrics.json"),JsonSerializer.Serialize(result,new JsonSerializerOptions{WriteIndented=true}),new UTF8Encoding(false));
            var lines=new List<string>{"entry_utc,exit_utc,quantity_units,entry_price,exit_price,gross_usd,commission_usd,net_usd,reason"};
            lines.AddRange(_trades.Select(t=>string.Join(",",t.EntryUtc.ToString("O",CI),t.ExitUtc.ToString("O",CI),t.Quantity.ToString(CI),t.EntryPrice.ToString(CI),
                t.ExitPrice.ToString(CI),t.GrossUsd.ToString(CI),t.CommissionUsd.ToString(CI),t.NetUsd.ToString(CI),t.Reason)));
            File.WriteAllLines(Path.Combine(_output,"trades.csv"),lines,new UTF8Encoding(false));
            File.WriteAllLines(Path.Combine(_output,"equity_h1.csv"),new[]{"utc,liquidation_equity_usd,cash_usd,quantity_units,average_entry_price,liquidation_quote,estimated_exit_fee_usd"}.Concat(
                _equity.Select(e=>string.Join(",",e.Utc.ToString("O",CI),e.EquityUsd.ToString(CI),e.CashUsd.ToString(CI),e.Quantity.ToString(CI),
                    e.EntryPrice.ToString(CI),e.LiquidationQuote.ToString(CI),e.EstimatedExitFeeUsd.ToString(CI)))),new UTF8Encoding(false));
            Log("GOLD_RESULT "+JsonSerializer.Serialize(result));if(!reconciled)throw new InvalidOperationException("Unclosed/unreconciled exposure.");
        }
        public class UnitFeeModel:FeeModel
        {
            private readonly decimal _fee;public UnitFeeModel(decimal fee){_fee=fee;}
            public override OrderFee GetOrderFee(OrderFeeParameters p)=>new OrderFee(new CashAmount(Math.Abs(p.Order.Quantity)*_fee,"USD"));
        }
        public class AbsoluteSlippageModel:ISlippageModel
        {
            private readonly decimal _price;public AbsoluteSlippageModel(decimal price){_price=price;}
            public decimal GetSlippageApproximation(Security asset,Order order)=>_price;
        }
        public class TradeRecord
        {
            public DateTime EntryUtc{get;set;}public DateTime ExitUtc{get;set;}public decimal Quantity{get;set;}
            public decimal EntryPrice{get;set;}public decimal ExitPrice{get;set;}public decimal GrossUsd{get;set;}
            public decimal CommissionUsd{get;set;}public decimal NetUsd{get;set;}public string Reason{get;set;}
        }
        public class EquityRecord
        {
            public DateTime Utc{get;set;}public decimal EquityUsd{get;set;}public decimal CashUsd{get;set;}public decimal Quantity{get;set;}
            public decimal EntryPrice{get;set;}public decimal LiquidationQuote{get;set;}public decimal EstimatedExitFeeUsd{get;set;}
        }
    }
}
