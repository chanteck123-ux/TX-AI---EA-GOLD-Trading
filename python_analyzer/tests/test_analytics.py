"""Analytical evidence boundaries, lifecycle accounting and causal-time regressions."""

from copy import deepcopy
from datetime import datetime, timedelta, timezone
import unittest

from gsm_analyzer.analytics import analyze, complete_positions, drawdown, enrich_trades, metrics_for


def dataset(**parts):
    result = {
        "manifest": {"run_id": "unit-run", "symbol": "GOLD", "strategy_scope": "Combined",
                     "data_type": "synthetic", "initial_capital": 1000,
                     "timezone": "UTC", "risk": {"single_pct": 1, "total_pct": 3},
                     "test": {"start": "2026-01-06T00:00:00+00:00", "end": "2026-01-07T00:00:00+00:00"}},
        "issues": [], "trades": [], "deals": [], "bars": [], "ticks": [],
        "equity": [], "events": [], "funnel": [], "reports": [], "provenance": [],
    }
    result.update(parts)
    return result


def trade(pid="1", profit=10, strategy="Intraday", **fields):
    value = {"position_id": pid, "strategy": strategy, "symbol": "GOLD", "side": "BUY",
             "volume": 0.02, "time_open": "2026-01-06T09:00:00+00:00",
             "time_close": "2026-01-06T10:00:00+00:00", "net_profit": profit,
             "commission": 0, "swap": 0, "fee": 0, "run_id": "unit-run"}
    value.update(fields)
    return value


def deal(identifier, entry, volume, time, profit=0, **fields):
    value = {"position_id": "P1", "deal_id": identifier, "entry": entry, "volume": volume,
             "time": f"2026-01-06T{time}:00+00:00", "profit": profit, "commission": 0,
             "swap": 0, "fee": 0, "symbol": "GOLD", "magic": "102",
             "strategy": "Intraday", "side": "BUY" if entry == "in" else "SELL",
             "price": 100 if entry == "in" else 110}
    value.update(fields)
    return value


def metric(result, strategy="Combined"):
    return next(row for row in result["metrics"] if row["strategy"] == strategy)


class PositionAccountingTests(unittest.TestCase):
    def test_partial_exit_fees_counted_once_as_one_position(self):
        records = [deal("D1", "in", .04, "09:00", commission=-.08),
                   deal("D2", "out", .02, "10:00", profit=10, commission=-.04, swap=-.10, fee=-.01),
                   deal("D3", "out", .02, "11:00", profit=-4, commission=-.04, swap=-.20, fee=-.02)]
        result = analyze(dataset(deals=records))
        self.assertEqual(len(result["trades"]), 1)
        row = result["trades"][0]
        self.assertEqual(row["deal_count"], 3)
        self.assertEqual(row["exit_deal_count"], 2)
        self.assertAlmostEqual(row["net_profit"], 5.51)
        self.assertAlmostEqual(row["commission"], -.16)
        self.assertEqual(row["holding_minutes"], 120)
        self.assertEqual(metric(result)["complete_trades"], 1)
        self.assertAlmostEqual(metric(result, "Intraday")["net_profit"], 5.51)

    def test_deal_input_order_does_not_change_complete_position(self):
        rows = [deal("D3", "out", .02, "11:00", 6), deal("D1", "in", .04, "09:00"),
                deal("D2", "out", .02, "10:00", -2)]
        reconstructed = complete_positions(dataset(deals=rows))
        self.assertEqual(len(reconstructed), 1)
        self.assertEqual(reconstructed[0]["net_profit"], 4)
        self.assertEqual(reconstructed[0]["holding_minutes"], 120)

    def test_open_partial_and_inout_positions_are_not_complete_trades(self):
        data = dataset(deals=[deal("D1", "in", .04, "09:00"), deal("D2", "out", .02, "10:00", 9),
                              deal("D3", "inout", .02, "09:01", position_id="P2")])
        self.assertEqual(complete_positions(data), [])
        codes = {row["code"] for row in data["issues"]}
        self.assertIn("OPEN_OR_INCOMPLETE_POSITION", codes)
        self.assertIn("REVERSAL_UNSUPPORTED", codes)

    def test_missing_deal_cost_does_not_become_zero(self):
        data = dataset(deals=[deal("D1", "in", .02, "09:00"),
                              deal("D2", "out", .02, "10:00", 9, commission=None)])
        self.assertEqual(complete_positions(data), [])
        self.assertIn("DEAL_COSTS_UNKNOWN", {r["code"] for r in data["issues"]})

    def test_explicit_open_audit_and_missing_id_are_isolated(self):
        data = dataset(trades=[trade(is_complete=False), trade(pid="", profit=20)])
        self.assertEqual(complete_positions(data), [])
        self.assertIn("TRADE_NOT_COMPLETE", {r["code"] for r in data["issues"]})
        self.assertIn("POSITION_ID_MISSING", {r["code"] for r in data["issues"]})

    def test_audit_plus_deals_never_double_counts_same_position(self):
        data = dataset(trades=[trade(pid="P1", profit=9)],
                       deals=[deal("D1", "in", .02, "09:00"), deal("D2", "out", .02, "10:00", 9)])
        result = analyze(data)
        self.assertEqual(metric(result)["complete_trades"], 1)
        self.assertEqual(metric(result)["net_profit"], 9)

    def test_exit_before_entry_is_not_valid_reconstruction(self):
        data = dataset(deals=[deal("D1", "out", .02, "09:00", 5), deal("D2", "in", .02, "10:00")])
        self.assertEqual(complete_positions(data), [])
        self.assertIn("DEAL_LIFECYCLE_INVALID", {r["code"] for r in data["issues"]})

    def test_same_side_out_deal_cannot_close_buy_position(self):
        data = dataset(deals=[deal("D1", "in", .02, "09:00", side="BUY"),
                              deal("D2", "out", .02, "10:00", 5, side="BUY")])
        self.assertEqual(complete_positions(data), [])
        self.assertTrue(data["issues"])


class MetricDefinitionsTests(unittest.TestCase):
    def test_losses_breakeven_and_profit_factor_have_distinct_meanings(self):
        values = [-10, -5, 0, -2, 20]
        rows = [trade(str(i), value, time_close=f"2026-01-06T10:0{i}:00+00:00") for i, value in enumerate(values)]
        actual = metrics_for(rows)
        self.assertEqual(actual["complete_trades"], 5)
        self.assertEqual(actual["wins"], 1)
        self.assertEqual(actual["losses"], 3)
        self.assertEqual(actual["breakeven_trades"], 1)
        self.assertEqual(actual["win_rate"], 20)
        self.assertAlmostEqual(actual["profit_factor"], 20/17)
        self.assertAlmostEqual(actual["avg_loss"], -17/3)
        self.assertEqual(actual["max_consecutive_losses"], 2)
        self.assertAlmostEqual(actual["expected_payoff"], .6)

    def test_profit_factor_zero_denominator_remains_undefined(self):
        wins = metrics_for([trade(profit=10)])
        self.assertIsNone(wins["profit_factor"])
        self.assertEqual(wins["profit_factor_status"], "no_losses_undefined")
        losses = metrics_for([trade(profit=-10)])
        self.assertEqual(losses["profit_factor"], 0)
        breakeven = metrics_for([trade(profit=0)])
        self.assertIsNone(breakeven["profit_factor"])
        self.assertEqual(breakeven["breakeven_trades"], 1)
        empty = metrics_for([])
        self.assertIsNone(empty["win_rate"])
        self.assertIsNone(empty["expected_payoff"])

    def test_maximum_money_and_maximum_relative_drawdown_are_independent(self):
        value = drawdown([100, 50, 1000, 800])
        self.assertEqual(value["money"], 200)
        self.assertEqual(value["pct"], 50)
        self.assertEqual(value["pct_at_max_money"], 20)
        self.assertIsNone(drawdown([None, "bad"])["money"])

    def test_missing_equity_is_not_invented_from_profitable_trade_history(self):
        result = analyze(dataset(trades=[trade(profit=-10)]))
        value = metric(result)
        self.assertEqual(value["balance_dd_money"], 10)
        self.assertIsNone(value["equity_dd_money"])
        self.assertIsNone(value["equity_dd_pct"])
        self.assertEqual(value["equity_dd_source"], "MISSING")
        self.assertTrue(all(row["equity"] is None for row in result["curves"]["Combined"]))

    def test_balance_only_observation_does_not_claim_equity_source(self):
        result = analyze(dataset(equity=[{"time": "2026-01-06T09:00:00+00:00", "balance": 1000, "equity": None}]))
        self.assertIsNone(metric(result)["equity_dd_money"])
        self.assertEqual(metric(result)["equity_dd_source"], "MISSING")
        self.assertTrue(any(f["strategy"] == "Combined" and f["category"] == "equity" and f["kind"] == "missing"
                            for f in result["findings"]))

    def test_equity_sampling_is_separate_from_balance(self):
        data = dataset(trades=[trade(profit=30)], equity=[
            {"time": "2026-01-06T09:00:00+00:00", "balance": 1000, "equity": 1000},
            {"time": "2026-01-06T09:30:00+00:00", "balance": 1000, "equity": 800},
            {"time": "2026-01-06T10:00:00+00:00", "balance": 1030, "equity": 1030}])
        result = analyze(data)
        self.assertEqual(metric(result)["equity_dd_money"], 200)
        self.assertEqual(metric(result)["equity_dd_pct"], 20)
        self.assertEqual(metric(result)["balance_dd_money"], 0)
        self.assertIsNone(metric(result, "Intraday")["equity_dd_money"])

    def test_native_equity_summary_does_not_create_a_fabricated_curve(self):
        result = analyze(dataset(reports=[{"summary": {"net_profit": 30, "equity_drawdown_money": 70,
                                                        "equity_drawdown_relative_pct": 7}}]))
        self.assertEqual(metric(result)["equity_dd_money"], 70)
        self.assertEqual(metric(result)["equity_dd_pct"], 7)
        self.assertTrue(all(row["equity"] is None for row in result["curves"]["Combined"]))
        self.assertIsNone(metric(result)["complete_trades"])


class CausalAndEvidenceTests(unittest.TestCase):
    def causal_bars(self):
        start = datetime(2026, 1, 6, tzinfo=timezone.utc)
        return [{"time": (start+timedelta(minutes=5*i)).isoformat(), "timeframe": "M5", "symbol": "GOLD",
                 "open": 100+i, "high": 101+i, "low": 99+i, "close": 100+i} for i in range(40)]

    def test_future_bar_changes_cannot_change_previous_entry_regime(self):
        data = dataset(bars=self.causal_bars())
        entry = trade(time_open="2026-01-06T02:00:00+00:00")
        before = enrich_trades([dict(entry)], data)[0]
        self.assertEqual(before["market_regime"], "上涨代理")
        changed = deepcopy(data)
        for bar in changed["bars"]:
            if bar["time"] >= entry["time_open"]:
                bar.update(high=1000000, low=0, close=0)
        after = enrich_trades([dict(entry)], changed)[0]
        for key in ("market_regime", "regime_available_at", "proxy_atr_sma_tr14"):
            self.assertEqual(before[key], after[key])
        self.assertLessEqual(before["regime_available_at"], entry["time_open"])

    def test_missing_bar_availability_keeps_regime_unknown(self):
        data = dataset(bars=[{"time": "2026-01-06T00:00:00+00:00", "high": 120, "low": 80, "close": 100}]*30)
        result = enrich_trades([trade()], data)
        self.assertEqual(result[0]["market_regime"], "UNKNOWN_NO_CAUSAL_BARS")
        self.assertIn("BAR_AVAILABILITY_UNKNOWN", {r["code"] for r in data["issues"]})

    def test_risk_exceedance_confirmed_but_chase_causality_is_hypothesis(self):
        result = analyze(dataset(trades=[trade(profit=-10, risk_pct=1.2, chase_entry="YES", mfe_money=20)]))
        risk = [f for f in result["findings"] if f["category"] == "risk"]
        chase = [f for f in result["findings"] if f["category"] == "entry"]
        self.assertEqual(len(risk), 1)
        self.assertEqual(risk[0]["kind"], "confirmed")
        self.assertEqual(len(chase), 1)
        self.assertEqual(chase[0]["kind"], "hypothesis")
        self.assertLessEqual(len(result["candidates"]), 3)

    def test_no_events_cannot_explain_no_trade_as_a_specific_rejection(self):
        result = analyze(dataset())
        self.assertEqual(result["funnel"], [])
        no_trade = [f for f in result["findings"] if f["category"] == "no_trade"]
        self.assertEqual(no_trade[0]["kind"], "missing")
        self.assertFalse(any(f["category"] == "logged_block" for f in result["findings"]))

    def test_combined_uses_three_engines_from_one_actual_run(self):
        result = analyze(dataset(trades=[trade("S", 10, "Scalping"), trade("I", -20, "Intraday"), trade("W", 5, "Swing")]))
        self.assertEqual(metric(result)["net_profit"], -5)
        self.assertEqual(metric(result)["complete_trades"], 3)
        self.assertEqual(metric(result, "Scalping")["net_profit"], 10)
        self.assertEqual(metric(result, "Intraday")["net_profit"], -20)
        self.assertEqual(metric(result, "Swing")["net_profit"], 5)

    def test_different_actual_runs_cannot_be_pooled_as_combined(self):
        mixed = dataset(trades=[trade("S", 10, "Scalping"), trade("I", 20, "Intraday", run_id="different-run")])
        with self.assertRaises(ValueError):
            analyze(mixed)

    def test_false_early_available_at_does_not_make_unclosed_bar_causal(self):
        baseline = dataset(bars=self.causal_bars()[:24])
        entry = trade(time_open="2026-01-06T02:00:00+00:00")
        before = enrich_trades([dict(entry)], baseline)[0]
        malformed = deepcopy(baseline)
        malformed["bars"].append({"time": "2026-01-06T02:00:00+00:00", "timeframe": "M5",
                                  "available_at": "2026-01-06T01:59:00+00:00", "symbol": "GOLD",
                                  "open": 123, "high": 1000000, "low": 0, "close": 0})
        after = enrich_trades([dict(entry)], malformed)[0]
        self.assertEqual(before["market_regime"], after["market_regime"])
        self.assertEqual(before["proxy_atr_sma_tr14"], after["proxy_atr_sma_tr14"])


if __name__ == "__main__":
    unittest.main()
