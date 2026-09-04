//+------------------------------------------------------------------+
//|                                                GSM_Gold_3SOP_EA  |
//|  Gold Secret Mastery inspired GOLD EA for MT5                    |
//|  Strategies: M5 Scalping, M30 Intraday, D1/H4/M30 Swing          |
//+------------------------------------------------------------------+
#property strict
#property version   "4.00"
#property description "GSM GOLD 3SOP EA v4.00 research baseline: independent GSM strategy lanes, frozen historical references, auditable funnels, and optional one-module Candidates."

#include <Trade/Trade.mqh>

CTrade trade;

enum EntryConfirmMode
{
   CONFIRM_REACTION_CANDLE = 0,
   CONFIRM_TOUCH_ONLY      = 1
};

enum SDFormationType
{
   SD_FORMATION_NONE       = 0,
   SD_FORMATION_LONG_WICK  = 1,
   SD_FORMATION_BASE_BREAK = 2,
   SD_FORMATION_IMPULSIVE  = 3
};

enum StrategyId
{
   STRATEGY_SCALPING = 0,
   STRATEGY_INTRADAY = 1,
   STRATEGY_SWING    = 2
};

enum ZoneLifecycle
{
   ZONE_FORMING      = 0,
   ZONE_FRESH        = 1,
   ZONE_DEPARTED     = 2,
   ZONE_FIRST_TOUCH  = 3,
   ZONE_ENTRY_PENDING= 4,
   ZONE_USED         = 5,
   ZONE_BROKEN       = 6,
   ZONE_EXPIRED      = 7
};

enum CandleStrength
{
   CANDLE_STRENGTH_NONE     = 0,
   CANDLE_STRENGTH_NEUTRAL  = 1,
   CANDLE_STRENGTH_WEAK     = 2,
   CANDLE_STRENGTH_MODERATE = 3,
   CANDLE_STRENGTH_STRONG   = 4
};

enum CandlePatternType
{
   CANDLE_NONE = 0,
   CANDLE_HAMMER,
   CANDLE_INVERTED_HAMMER,
   CANDLE_BULLISH_MARUBOZU,
   CANDLE_BULLISH_ENGULFING,
   CANDLE_BULLISH_HARAMI,
   CANDLE_PIERCING_LINE,
   CANDLE_TWEEZER_BOTTOM,
   CANDLE_BULLISH_KICKER,
   CANDLE_MORNING_STAR,
   CANDLE_MORNING_DOJI_STAR,
   CANDLE_BULLISH_ABANDONED_BABY,
   CANDLE_THREE_WHITE_SOLDIERS,
   CANDLE_THREE_INSIDE_UP,
   CANDLE_THREE_OUTSIDE_UP,
   CANDLE_BULLISH_SPINNING_TOP,
   CANDLE_HANGING_MAN,
   CANDLE_SHOOTING_STAR,
   CANDLE_BEARISH_MARUBOZU,
   CANDLE_BEARISH_ENGULFING,
   CANDLE_BEARISH_HARAMI,
   CANDLE_DARK_CLOUD_COVER,
   CANDLE_TWEEZER_TOP,
   CANDLE_BEARISH_KICKER,
   CANDLE_EVENING_STAR,
   CANDLE_EVENING_DOJI_STAR,
   CANDLE_BEARISH_ABANDONED_BABY,
   CANDLE_THREE_BLACK_CROWS,
   CANDLE_THREE_INSIDE_DOWN,
   CANDLE_THREE_OUTSIDE_DOWN,
   CANDLE_BEARISH_SPINNING_TOP,
   CANDLE_DOJI,
   CANDLE_LONG_LEGGED_DOJI,
   CANDLE_DRAGONFLY_DOJI,
   CANDLE_GRAVESTONE_DOJI,
   CANDLE_SPINNING_TOP,
   CANDLE_FOUR_PRICE_DOJI
};

enum ChartPatternType
{
   CHART_PATTERN_NONE = 0,
   CHART_HEAD_SHOULDERS,
   CHART_INVERSE_HEAD_SHOULDERS,
   CHART_DOUBLE_TOP,
   CHART_DOUBLE_BOTTOM,
   CHART_RISING_WEDGE,
   CHART_FALLING_WEDGE,
   CHART_BULLISH_FLAG,
   CHART_BEARISH_FLAG
};

enum ChartPatternState
{
   PATTERN_FORMING = 0,
   PATTERN_BREAKOUT_CONFIRMED,
   PATTERN_WAITING_RETEST,
   PATTERN_ENTRY_READY,
   PATTERN_INVALID,
   PATTERN_EXPIRED,
   PATTERN_USED
};

enum SwingTrailAnchorMode
{
   SWING_TRAIL_ENTRY_EXTREME = 0,
   SWING_TRAIL_CLOSED_H4     = 1,
   SWING_TRAIL_H4_STRUCTURE  = 2
};

enum ConfidenceMode
{
   CONFIDENCE_OFF        = 0,
   CONFIDENCE_SCORE_ONLY = 1,
   CONFIDENCE_FILTER     = 2
};

enum MACDMode
{
   MACD_MODE_OFF     = 0,
   MACD_MODE_OBSERVE = 1,
   MACD_MODE_SCORE   = 2,
   MACD_MODE_HARD    = 3
};

enum BollingerMode
{
   BOLLINGER_MODE_OFF     = 0,
   BOLLINGER_MODE_OBSERVE = 1,
   BOLLINGER_MODE_SCORE   = 2,
   BOLLINGER_MODE_HARD    = 3
};

enum MoneyManagementMode
{
   MONEY_MANUAL_FIXED_LOT = 0,
   MONEY_AUTO_RISK        = 1
};

enum CapitalLadderMode
{
   CAPITAL_LADDER_OFF     = 0,
   CAPITAL_LADDER_MONITOR = 1,
   CAPITAL_LADDER_ENFORCE = 2
};

enum GoldSymbolScanMode
{
   GOLD_SCAN_OFF         = 0,
   GOLD_SCAN_REPORT_ONLY = 1,
   GOLD_SCAN_AUTO_SELECT = 2
};

enum SmallAccountProfile
{
   SMALL_ACCOUNT_OFF    = 0,
   SMALL_ACCOUNT_USD100 = 1,
   SMALL_ACCOUNT_USD500 = 2
};

struct Zone
{
   string   id;
   string   symbol;
   ENUM_TIMEFRAMES timeframe;
   bool     valid;
   int      dir;          // 1 demand/support, -1 supply/resistance
   double   top;
   double   bottom;
   double   proximal;
   double   distal;
   double   width;
   int      createdIndex;
   datetime createdTime;
   datetime departureTime;
   datetime firstTouchTime;
   datetime firstTouchBarTime;
   double   firstTouchPrice;
   int      touches;
   double   score;
   double   qualityScore;
   SDFormationType formation;
   ZoneLifecycle state;
   bool     broken;
   bool     used;
   bool     expired;
};

struct SRZone
{
   bool     valid;
   int      dir;          // 1 support, -1 resistance
   double   top;
   double   bottom;
   int      touches;
   double   score;
   bool     roleReversal;
   datetime firstTouchTime;
   datetime lastTouchTime;
};

struct CandleMetrics
{
   double range;
   double body;
   double upperWick;
   double lowerWick;
   double bodyToRange;
   double upperWickToBody;
   double lowerWickToBody;
   double closeLocation;
   double gapSize;
   double tickVolumeRatio;
};

struct CandleSignal
{
   bool valid;
   CandlePatternType type;
   int direction;
   CandleStrength strength;
   string englishName;
   string chineseName;
   ENUM_TIMEFRAMES timeframe;
   datetime candleTime;
   double volumeRatio;
   double quality;
};

struct PivotPoint
{
   bool high;
   int index;
   datetime time;
   double price;
};

struct ChartPatternSignal
{
   bool valid;
   string id;
   ChartPatternType type;
   ENUM_TIMEFRAMES timeframe;
   int direction;
   datetime startTime;
   datetime endTime;
   double keyPrices[6];
   double neckline;
   double breakoutPrice;
   double retestPrice;
   double invalidationPrice;
   double projectedTarget;
   ChartPatternState state;
   double score;
   string englishName;
   string chineseName;
};

struct ScoreBreakdown
{
   double part1;
   double part2;
   double part3;
   double part4;
   double part5;
   double part6;
   double part7;
   double part8;
   double total;
   string explanation;
};

struct IndicatorSnapshot
{
   bool   ready;
   double emaFast;
   double emaSlow;
   double emaFastPrevious;
   double emaSlowPrevious;
   double closeValue;
   double atr;
   double rsi;
   double rsiPrevious;
   double emaStrength;
   double rsiStrength;
   double combinedStrength;
};

struct MACDSnapshot
{
   bool   ready;
   double mainValue;
   double signalValue;
   double histogram;
   double previousMain;
   double previousSignal;
   double previousHistogram;
   double quality;
   bool   directionPassed;
   string state;
};

struct BollingerSnapshot
{
   bool   ready;
   double upper;
   double middle;
   double lower;
   double percentB;
   double bandWidth;
   double previousPercentB;
   double previousBandWidth;
   double bandWidthChange;
   double quality;
   bool   directionPassed;
   string state;
};

struct IndicatorConfig
{
   bool useEMA;
   bool useRSI;
   ENUM_TIMEFRAMES emaTF;
   ENUM_TIMEFRAMES rsiTF;
   int emaFast;
   int emaSlow;
   bool requirePriceSide;
   int rsiPeriod;
   double rsiLongMin;
   double rsiLongMax;
   double rsiShortMin;
   double rsiShortMax;
   bool requireRSITurn;
};

struct TradeAuditTrack
{
   bool     active;
   ulong    positionId;
   int      strategy;
   int      direction;
   string   zoneId;
   string   clusterId;
   datetime entryTime;
   double   entryPrice;
   double   initialSL;
   double   initialTP;
   double   volume;
   long     magic;
   double   calculatedVolume;
   double   actualSLRiskMoney;
   double   actualSLRiskPercent;
   bool     forcedMinimumLot;
   bool     confidence100Boost;
   int      serverHour;
   double   spreadPoints;
   double   atr;
   double   emaFast;
   double   emaSlow;
   double   rsi;
   double   macdMain;
   double   macdSignal;
   double   macdHistogram;
   double   bollingerUpper;
   double   bollingerMiddle;
   double   bollingerLower;
   double   bollingerPercentB;
   double   bollingerBandWidth;
   double   bollingerBandWidthChange;
   double   confidence;
   double   zoneWidth;
   double   touchDepth;
   bool     falseBreak;
   bool     chaseEntry;
   double   mfeMoney;
   double   maeMoney;
};

struct StrategyRuntime
{
   long magic;
   string name;
   string status;
   string rejectReason;
   string zoneId;
   string clusterId;
   string zoneState;
   string candleName;
   string candleStrength;
   string chartPattern;
   string indicatorState;
   string macdState;
   string bollingerState;
   double confidence;
   datetime lastEvaluatedBar;
   datetime lastProcessedCandle;
   int todayTrades;
   int winStreak;
   int lossStreak;
   datetime pauseUntil;
   bool tradeLock;
   ScoreBreakdown score;
   CandleSignal candle;
   ChartPatternSignal pattern;
};

struct SignalFunnel
{
   long zonesDetected;
   long zonesDeparted;
   long firstTouches;
   long candlePatternsDetected;
   long chartPatternsDetected;
   long hardSOPPassed;
   long confidencePassed;
   long globalGatePassed;
   long ordersRequested;
   long ordersFilled;
   long ordersRejected;
   long emaPassed;
   long emaRejected;
   long rsiPassed;
   long rsiRejected;
   long macdEvaluated;
   long macdPassed;
   long macdRejected;
   long confidenceRejected;
   long sessionRejected;
   long spreadRejected;
   long positionLimitRejected;
   long riskRejected;
   long marginRejected;
   long minimumLotRiskRejected;
   long totalRiskRejected;
   long insufficientFundsRejected;
   long indicatorDataWaits;
   long macdDataWaits;
   long bollingerEvaluated;
   long bollingerPassed;
   long bollingerRejected;
   long bollingerDataWaits;
   long duplicateZoneRejected;
   long duplicateClusterRejected;
   long d1DirectionPassed;
   long h4DirectionPassed;
   long h4ZonesFound;
   long srConfluencePassed;
   long m30Touches;
   long m30Confirmations;
   ulong lastFilledOrder;
   datetime lastCandleCounted;
   string lastPatternIdCounted;
   string lastDemandDetectedId;
   string lastSupplyDetectedId;
};

// -------------------------------------------------------------------
// Global / broker inputs
// -------------------------------------------------------------------
input string InpTradeSymbol              = "";       // Empty = chart symbol. FxPro often GOLD, Tradona often XAUUSD.tm
input long   InpIntradayMagic            = 26082102;
input long   InpScalpMagic               = 26082152;
input long   InpSwingMagic               = 26082303;
input bool   InpRequireHedging            = true;
input int    InpDeviationPoints          = 30;
input int    InpMaxSpreadPoints          = 300;      // Common extreme-spread guard; 0 disables
input bool   InpManualNewsLock           = false;    // Turn on manually before high-impact news
input bool   InpDrawZones                = true;
input bool   InpShowPanel                = true;
input bool   InpEnableChartSwitches       = true;
input int    InpPanelXOffset              = 12;
input int    InpPanelYOffset              = 18;
input int    InpPanelFontSize             = 10;
input int    InpMaxQuoteAgeSeconds       = 10;
input double InpMaxAccountOpenRiskPct    = 10.0;
input double InpMinMarginLevelPct        = 150.0;
input MoneyManagementMode InpMoneyManagementMode = MONEY_MANUAL_FIXED_LOT;
input int    InpTotalMaxOpenPositions    = 2;
input bool   InpRecenterFixedStopsAfterFill = true;
input bool   InpEnableFilterAuditLogs    = true;
input string InpAuditRunLabel            = "v4.00_RESEARCH_BASE";
input CapitalLadderMode InpCapitalLadderMode = CAPITAL_LADDER_OFF;
input double InpCapitalUpgradeBufferPct  = 10.0;
input bool   InpCapitalLadderRequireUSD  = true;
input GoldSymbolScanMode InpGoldSymbolScanMode = GOLD_SCAN_REPORT_ONLY;
input double InpSmallGoldMaxRiskPct      = 1.0;
input double InpGoldScanMaxEquity        = 500.0;
input bool   InpEnableTradeReviewCSV     = true;
input string InpTradeReviewFileName      = "GSM_v4.00_TRADE_REVIEW.csv";
input bool   InpEnableSignalAuditCSV     = true;
input string InpSignalAuditFileName      = "GSM_v4.00_SIGNAL_AUDIT.csv";
input string InpSignalFunnelFileName     = "GSM_v4.00_SIGNAL_FUNNEL.csv";
input bool   InpEnableOpportunityClusters= true;
input double InpClusterDistanceATR       = 0.75;
input int    InpScalpClusterCooldownBars = 12;
input int    InpIntradayClusterCooldownBars = 4;
input int    InpSwingClusterCooldownBars = 8;
input SmallAccountProfile InpSmallAccountProfile = SMALL_ACCOUNT_USD500;
input bool   InpForceBrokerMinimumLot    = false;
input bool   InpEnableConfidence100LotBoost = false;
input double InpConfidenceFullScore      = 100.0;
input double InpConfidenceFullTolerance  = 0.0001;
input double InpConfidenceBoostMaxLot    = 0.05;
input double InpUSD100MaxSingleRiskPct   = 15.0;
input double InpUSD500MaxSingleRiskPct   = 5.0;
input double InpUSD500MaxTotalRiskPct    = 10.0;
input double InpZoneDeparturePips        = 10.0;
input double InpZoneBreakBufferPips      = 5.0;
input int    InpZoneExpiryBars           = 500;

// Course unit conversion. The training materials use gold "pip" as price 0.10.
// FxPro GOLD / Tradona XAUUSD.tm normally have 2 digits, so 0.10 equals 10 MT5 points.
input double InpCoursePipInPrice         = 0.10;
input double InpIntradayPointInPrice     = 0.10;

// Common detection inputs
input int    InpATRPeriod                = 14;
input int    InpSwingDepth               = 3;
input double InpMinImpulseATR            = 1.20;
input double InpMinImpulseBodyRatio      = 0.45;
input int    InpZoneIgnoreBarsAfterMove  = 2;
input bool   InpUseFixedLot              = true;      // USD500 best-of-versions profile uses broker minimum 0.01 lot

// Non-repainting chart-pattern settings. Every pivot is confirmed on both sides.
input int    InpPatternPivotDepth        = 3;
input int    InpPatternLookbackBars      = 180;
input double InpPatternShoulderTolerance = 0.20;
input double InpPatternDoubleTolerancePips= 20.0;
input int    InpPatternMinPivotDistance  = 3;
input int    InpPatternMaxFormationBars  = 120;
input double InpPatternBreakoutBufferPips= 5.0;
input double InpPatternRetestTolerancePips=10.0;
input int    InpPatternMinWedgePivots    = 3;
input double InpPatternFlagPoleATR       = 2.0;
input double InpPatternFlagMaxRetrace    = 0.50;

// Unified 36-candlestick detector. XAUUSD volume is MT5 tick volume, not exchange volume.
input double InpDojiMaxBodyRatio         = 0.10;
input double InpHammerMinWickBody        = 2.00;
input double InpEngulfingMinRatio        = 1.00;
input double InpMarubozuMaxWickRatio     = 0.10;
input double InpTweezerTolerancePips     = 5.0;
input double InpStarMaxBodyRatio         = 0.30;
input double InpGapMinPips               = 2.0;
input double InpSpinningMaxBodyRatio     = 0.35;
input double InpSpinningMinWickBody      = 0.80;
input int    InpCandleTrendBars          = 5;
input int    InpVolumeAveragePeriod      = 20;
input double InpVolumeConfirmMultiple    = 1.50;
input bool   InpUseVolumeInScore         = true;

// -------------------------------------------------------------------
// M5 scalping SOP
// -------------------------------------------------------------------
input bool   InpEnableScalpingM5         = true;
input bool   InpScalpManualNewsLock      = false;
input int    InpScalpStartHour           = 1;
input int    InpScalpEndHour             = 24;
input int    InpScalpMaxSpreadPoints     = 80;
input int    InpScalpLookbackBars        = 180;
input double InpScalpZonePips            = 30.0;
input double InpScalpSLPips              = 80.0;
input double InpScalpTPPips              = 70.0;
input bool   InpScalpUseBreakEven        = false;
input double InpScalpBreakEvenAtR        = 0.50;
input double InpScalpBreakEvenOffsetPips = 0.0;
input double InpScalpBreakEvenStepPips   = 1.0;
input int    InpScalpMaxTradesPerDay     = 0;         // Unlimited scanning; risk, cluster and position gates still apply
input int    InpScalpPauseAfterStreak    = 6;
input int    InpScalpPauseHours          = 24;
input int    InpScalpMaxOpenPositions    = 2;
input double InpScalpFixedLot            = 0.01;
input double InpScalpRiskPercent         = 1.0;
input bool   InpScalpFreshTouchOnly      = true;
input bool   InpScalpShowScore           = true;
input bool   InpScalpUseScoreFilter      = false;    // First release: score/display only
input ConfidenceMode InpScalpConfidenceMode = CONFIDENCE_SCORE_ONLY;
input double InpScalpMinConfidence       = 70.0;
input double InpScalpWeightZone          = 30.0;
input double InpScalpWeightFirstTouch    = 25.0;     // Legacy v2.30 input; ignored by v2.40 scoring
input double InpScalpWeightCandle        = 35.0;
input double InpScalpWeightConfluence    = 15.0;
input double InpScalpWeightMomentum      = 20.0;
input bool   InpScalpUseEMAFilter        = true;
input ENUM_TIMEFRAMES InpScalpEMATF      = PERIOD_M5;
input int    InpScalpEMAFast             = 30;
input int    InpScalpEMASlow             = 100;
input bool   InpScalpRequirePriceEMA     = false;
input bool   InpScalpUseRSIFilter        = true;
input ENUM_TIMEFRAMES InpScalpRSITF      = PERIOD_M5;
input int    InpScalpRSIPeriod           = 14;
input double InpScalpRSILongMin          = 20.0;
input double InpScalpRSILongMax          = 60.0;
input double InpScalpRSIShortMin         = 40.0;
input double InpScalpRSIShortMax         = 80.0;
input bool   InpScalpRequireRSITurn      = true;
input bool   InpScalpUseStochasticFilter = false;
input ENUM_TIMEFRAMES InpScalpStochasticTF = PERIOD_M5;
input int    InpScalpStochasticKPeriod   = 3;
input int    InpScalpStochasticDPeriod   = 3;
input int    InpScalpStochasticSlowing   = 3;
input double InpScalpStochasticLongMin   = 0.0;
input double InpScalpStochasticLongMax   = 60.0;
input double InpScalpStochasticShortMin  = 40.0;
input double InpScalpStochasticShortMax  = 100.0;
input bool   InpScalpStochasticRequireTurn = true;
input bool   InpScalpStochasticRequireCross = false;
input bool   InpScalpUseHTFRegimeFilter   = false;
input ENUM_TIMEFRAMES InpScalpRegimeTF    = PERIOD_H4;
input int    InpScalpRegimeEMAFast        = 50;
input int    InpScalpRegimeEMASlow        = 200;
input bool   InpScalpRegimeLongAlwaysAllowed = false;
input BollingerMode InpScalpBollingerMode = BOLLINGER_MODE_OBSERVE;
input ENUM_TIMEFRAMES InpScalpBollingerTF = PERIOD_M5;
input int    InpScalpBollingerPeriod     = 20;
input double InpScalpBollingerDeviation  = 2.0;
input double InpScalpWeightBollinger     = 10.0;

// -------------------------------------------------------------------
// M30 intraday SOP
// -------------------------------------------------------------------
input bool             InpEnableIntradayM30       = true;
input bool             InpIntradayManualNewsLock  = false;
input int              InpIntradayStartHour       = 6;
input int              InpIntradayEndHour         = 24;
input int              InpIntradayMaxSpreadPoints = 100;
input int              InpIntradayMaxPositions    = 1;
input int              InpIntradayMaxOpenPositions= 2;
input int              InpIntradayMaxTradesPerDay = 4;
input int              InpIntradayLookbackBars    = 240;
input double           InpIntradayMidEntryPoints  = 30.0;
input double           InpIntradayLongWickRatio   = 0.50;
input int              InpIntradayBaseBars        = 3;
input double           InpIntradayBaseMaxATR      = 1.00;
input int              InpIntradayImpulseBars     = 2;
input double           InpIntradayImpulseBodyATR = 0.55;
input bool             InpIntradayUseZoneWidthATRFilter = false;
input double           InpIntradayMinZoneWidthATR = 0.35;
input double           InpIntradayMaxZoneWidthATR = 1.25;
input bool             InpIntradayUseMinTouchDepthFilter = false;
input double           InpIntradayMinTouchDepth = 0.01;
input bool             InpIntradayUseClosedCandleConfirmation = false;
input ENUM_TIMEFRAMES  InpIntradayConfirmationTF = PERIOD_M5;
input int              InpIntradayConfirmationMaxBars = 3;
input CandleStrength   InpIntradayConfirmationMinStrength = CANDLE_STRENGTH_WEAK;
input double           InpIntradaySLPoints        = 120.0;
input double           InpIntradayTPPoints        = 240.0;
input bool             InpIntradayUseBreakEven    = false;
input double           InpIntradayBreakEvenAtR    = 0.50;
input double           InpIntradayBreakEvenOffsetPoints = 0.0;
input double           InpIntradayBreakEvenStepPoints = 10.0;
input double           InpIntradayFixedLot        = 0.01;
input double           InpIntradayRiskPercent     = 1.0;
input bool             InpIntradayShowScore       = true;
input bool             InpIntradayUseScoreFilter  = false; // First release: score/display only
input ConfidenceMode   InpIntradayConfidenceMode  = CONFIDENCE_SCORE_ONLY;
input double           InpIntradayMinConfidence   = 65.0;
input double           InpIntradayWeightZone      = 30.0;
input double           InpIntradayWeightFirstTouch= 25.0; // Legacy v2.30 input; ignored by v2.40 scoring
input double           InpIntradayWeightLocation  = 15.0;
input double           InpIntradayWeightPattern   = 10.0;
input double           InpIntradayWeightImpulse   = 10.0; // Legacy v2.30 input; ignored by v2.40 scoring
input double           InpIntradayWeightDeparture = 20.0;
input double           InpIntradayWeightMomentum  = 15.0;
input double           InpIntradayWeightMACD      = 10.0;
input bool             InpIntradayConsumeZoneOnTechnicalReject = false;
input bool             InpIntradayUseEMAFilter    = true;
input ENUM_TIMEFRAMES  InpIntradayEMATF           = PERIOD_M30;
input int              InpIntradayEMAFast         = 50;
input int              InpIntradayEMASlow         = 200;
input bool             InpIntradayRequirePriceEMA = true;
input bool             InpIntradayUseRSIFilter    = true;
input ENUM_TIMEFRAMES  InpIntradayRSITF           = PERIOD_M30;
input int              InpIntradayRSIPeriod       = 14;
input double           InpIntradayRSILongMin      = 50.0;
input double           InpIntradayRSILongMax      = 72.0;
input double           InpIntradayRSIShortMin     = 28.0;
input double           InpIntradayRSIShortMax     = 50.0;
input bool             InpIntradayRequireRSITurn  = false;
input bool             InpIntradayUseMACDScore    = true;
input MACDMode         InpIntradayMACDMode        = MACD_MODE_HARD;
input ENUM_TIMEFRAMES  InpIntradayMACDTF          = PERIOD_M30;
input int              InpIntradayMACDFast        = 12;
input int              InpIntradayMACDSlow        = 26;
input int              InpIntradayMACDSignal      = 9;
input BollingerMode    InpIntradayBollingerMode   = BOLLINGER_MODE_OBSERVE;
input ENUM_TIMEFRAMES  InpIntradayBollingerTF     = PERIOD_M30;
input int              InpIntradayBollingerPeriod = 20;
input double           InpIntradayBollingerDeviation = 2.0;
input double           InpIntradayWeightBollinger = 10.0;

// -------------------------------------------------------------------
// D1/H4/M30 swing SOP
// -------------------------------------------------------------------
input bool             InpEnableSwingD1           = true;
input bool             InpSwingManualNewsLock     = false;
input int              InpSwingStartHour          = 1;
input int              InpSwingEndHour            = 24;
input int              InpSwingMaxSpreadPoints    = 140;
input int              InpSwingMaxTradesPerDay    = 2;
input int              InpSwingMaxOpenPositions   = 2;
input ENUM_TIMEFRAMES  InpSwingBiasTF             = PERIOD_D1;
input ENUM_TIMEFRAMES  InpSwingSetupTF            = PERIOD_H4;
input ENUM_TIMEFRAMES  InpSwingEntryTF            = PERIOD_M30;
input int              InpSwingLookbackBars       = 260;
input int              InpSwingZoneExpiryBars     = 120;
input double           InpSwingZonePips           = 80.0;
input double           InpSwingSLBufferPips       = 20.0;
input int              InpSwingSRMinTouches       = 2;
input double           InpSwingSRZoneATR          = 0.20;
input double           InpSwingSRMinBounceATR     = 0.80;
input int              InpSwingSRMaxChopBars      = 4;
input bool             InpSwingAllowRoleReversal  = true;
input bool             InpSwingRequireSRConfluence= false;
input double           InpSwingConfluencePips     = 40.0;
input int              InpSwingConfirmationBars   = 4;
input CandleStrength   InpSwingMinCandleStrength  = CANDLE_STRENGTH_WEAK;
input bool             InpSwingRejectChaseEntry   = false;
input double           InpSwingMaxChaseZoneFraction = 0.15;
input bool             InpSwingConsumeZoneOnTechnicalReject = false;
input bool             InpSwingUseTakeProfit      = false;
input double           InpSwingMinTargetR         = 2.0;
input double           InpSwingRR                 = 4.0;
input bool             InpSwingUseVolatilityTargetR = false;
input double           InpSwingHighVolatilityATRPricePct = 1.0;
input double           InpSwingHighVolatilityRR   = 3.0;
input double           InpSwingFixedLot           = 0.01;
input double           InpSwingRiskPercent        = 1.0;
input bool             InpSwingUseBreakEven       = true;
input double           InpSwingBreakEvenAtR       = 0.5;
input double           InpSwingBreakEvenOffsetPips= 5.0;
input bool             InpSwingUseTrailingStop    = true;
input double           InpSwingTrailStartR        = 2.0;
input ENUM_TIMEFRAMES  InpSwingTrailTF            = PERIOD_H4;
input double           InpSwingTrailATRMultiple   = 2.0;
input double           InpSwingTrailStepPips      = 10.0;
input SwingTrailAnchorMode InpSwingTrailAnchor    = SWING_TRAIL_ENTRY_EXTREME;
input bool             InpSwingShowScore          = true;
input bool             InpSwingUseScoreFilter     = false; // First release: score/display only
input ConfidenceMode   InpSwingConfidenceMode     = CONFIDENCE_SCORE_ONLY;
input double           InpSwingMinConfidence      = 75.0;
input double           InpSwingWeightD1           = 20.0;
input double           InpSwingWeightH4           = 15.0;
input double           InpSwingWeightZoneSR       = 25.0;
input double           InpSwingWeightPattern      = 15.0; // Legacy v2.30 input; ignored by v2.40 scoring
input double           InpSwingWeightM30          = 15.0;
input double           InpSwingWeightMomentum     = 15.0;
input double           InpSwingWeightMACD         = 10.0;
input bool             InpSwingUseEMAFilter       = false;
input ENUM_TIMEFRAMES  InpSwingEMATF              = PERIOD_D1;
input int              InpSwingEMAFast            = 50;
input int              InpSwingEMASlow            = 200;
input bool             InpSwingRequirePriceEMA    = true;
input bool             InpSwingUseRSIFilter       = false;
input ENUM_TIMEFRAMES  InpSwingRSITF              = PERIOD_M30;
input int              InpSwingRSIPeriod          = 14;
input double           InpSwingRSILongMin         = 45.0;
input double           InpSwingRSILongMax         = 70.0;
input double           InpSwingRSIShortMin        = 30.0;
input double           InpSwingRSIShortMax        = 55.0;
input bool             InpSwingRequireRSITurn     = true;
input MACDMode         InpSwingMACDMode           = MACD_MODE_SCORE;
input ENUM_TIMEFRAMES  InpSwingMACDTF             = PERIOD_H4;
input int              InpSwingMACDFast           = 12;
input int              InpSwingMACDSlow           = 26;
input int              InpSwingMACDSignal         = 9;
input BollingerMode    InpSwingBollingerMode      = BOLLINGER_MODE_OBSERVE;
input ENUM_TIMEFRAMES  InpSwingBollingerTF        = PERIOD_M30;
input int              InpSwingBollingerPeriod    = 20;
input double           InpSwingBollingerDeviation = 2.0;
input double           InpSwingWeightBollinger    = 10.0;

// -------------------------------------------------------------------
// Runtime state
// -------------------------------------------------------------------
string   g_symbol = "";
int      g_digits = 0;
double   g_point = 0.0;
double   g_tickSize = 0.0;
double   g_tickValue = 0.0;
double   g_volumeMin = 0.0;
double   g_volumeMax = 0.0;
double   g_volumeStep = 0.0;
int      g_stopsLevel = 0;
int      g_freezeLevel = 0;
long     g_fillingMode = 0;
long     g_symbolTradeMode = 0;
datetime g_lastM5Bar = 0;
datetime g_lastM30Bar = 0;
datetime g_lastSwingBar = 0;
datetime g_lastIntradayConfirmationBar = 0;
datetime g_scalpPauseUntil = 0;
ulong    g_lastScalpPauseDeal = 0;
MqlTick  g_tick;
bool     g_isHedging = false;
bool     g_accountAllowsTrading = false;
bool     g_strategyEnabled[3];
StrategyRuntime g_runtime[3];
SignalFunnel g_funnel[3];
Zone     g_scalpDemand;
Zone     g_scalpSupply;
Zone     g_intradayDemand;
Zone     g_intradaySupply;
Zone     g_swingZone;
SRZone   g_swingSR;
ulong    g_swingPositionTicket = 0;
double   g_swingInitialRisk = 0.0;
double   g_swingHighestSinceEntry = 0.0;
double   g_swingLowestSinceEntry = 0.0;
int      g_swingManagementStage = 0;
datetime g_lastPanelUpdate = 0;
string   g_panelPrefix = "GSM4_UI_";
uint     g_detectedZoneHashes[];
uint     g_departedZoneHashes[];
uint     g_reportedDuplicateZoneHashes[];
int      g_emaFastHandle[3];
int      g_emaSlowHandle[3];
int      g_rsiHandle[3];
int      g_macdHandle[3];
int      g_bollingerHandle[3];
int      g_scalpStochasticHandle = INVALID_HANDLE;
int      g_scalpRegimeFastHandle = INVALID_HANDLE;
int      g_scalpRegimeSlowHandle = INVALID_HANDLE;
double   g_scalpStochasticK = 0.0;
double   g_scalpStochasticD = 0.0;
double   g_scalpStochasticPreviousK = 0.0;
double   g_scalpStochasticPreviousD = 0.0;
IndicatorSnapshot g_indicatorSnapshot[3];
MACDSnapshot g_macdSnapshot[3];
BollingerSnapshot g_bollingerSnapshot[3];
string   g_pendingZoneId[3];
string   g_pendingClusterId[3];
string   g_filledClusterIds[];
datetime g_filledClusterTimes[];
double   g_pendingRiskPercent[3];
double   g_pendingCalculatedVolume[3];
double   g_pendingFinalVolume[3];
double   g_pendingActualSLRiskMoney[3];
double   g_pendingActualSLRiskPercent[3];
bool     g_pendingForcedMinimumLot[3];
bool     g_pendingConfidence100Boost[3];
double   g_pendingZoneWidth[3];
double   g_pendingTouchDepth[3];
bool     g_pendingFalseBreak[3];
bool     g_pendingChaseEntry[3];
TradeAuditTrack g_tradeAudit[];
int      g_capitalTier = -1;
string   g_capitalTierName = "未初始化";
bool     g_ladderStrategyAllowed[3];
double   g_ladderRiskCap[3];
int      g_ladderMaxPositions[3];
int      g_ladderTotalMaxPositions = 0;
double   g_ladderTotalRiskCap = 0.0;
bool     g_smallGoldContractEligible = false;

double EstimateGoldMinimumLotLoss(string symbol,double stopDistance,double &marginRequired)
{
   marginRequired=0.0;
   if(stopDistance<=0.0 || !SymbolSelect(symbol,true))
      return 0.0;
   MqlTick tick={};
   if(!SymbolInfoTick(symbol,tick) || tick.ask<=0.0)
      return 0.0;
   double minimum=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
   double tickSize=SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE);
   double tickValue=SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE_LOSS);
   if(tickValue<=0.0) tickValue=SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE);
   double result=0.0;
   double loss=0.0;
   if(OrderCalcProfit(ORDER_TYPE_BUY,symbol,minimum,tick.ask,tick.ask-stopDistance,result) && result<0.0)
      loss=MathAbs(result);
   else if(tickSize>0.0 && tickValue>0.0)
      loss=(stopDistance/tickSize)*tickValue*minimum;
   if(!OrderCalcMargin(ORDER_TYPE_BUY,symbol,minimum,tick.ask,marginRequired))
      marginRequired=0.0;
   return loss;
}

bool LooksLikeGoldSymbol(string symbol)
{
   // Filtering by symbol name first avoids synchronizing thousands of unrelated contracts in the tester.
   string value=symbol;
   StringToUpper(value);
   return (StringFind(value,"GOLD")==0 || StringFind(value,"XAU")==0);
}

string ResolveGoldTradeSymbol(string requestedSymbol)
{
   g_smallGoldContractEligible=false;
   if(InpGoldSymbolScanMode==GOLD_SCAN_OFF)
      return requestedSymbol;

   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   double stopDistance=InpScalpSLPips*InpCoursePipInPrice;
   int total=SymbolsTotal(false);
   string bestSymbol="";
   double bestLoss=DBL_MAX;
   double requestedLoss=0.0;
   for(int i=0;i<total;i++)
   {
      string symbol=SymbolName(i,false);
      if(symbol=="" || !LooksLikeGoldSymbol(symbol))
         continue;
      if(MQLInfoInteger(MQL_TESTER) && symbol!=requestedSymbol)
      {
         PrintFormat("GOLD_SYMBOL_SCAN|Symbol=%s|Status=TESTER_SKIPPED|Reason=策略测试器必须直接选择候选品种，禁止OnInit动态切换历史",symbol);
         continue;
      }
      long tradeMode=SymbolInfoInteger(symbol,SYMBOL_TRADE_MODE);
      if(tradeMode==SYMBOL_TRADE_MODE_DISABLED)
         continue;
      double margin=0.0;
      double minimumLoss=EstimateGoldMinimumLotLoss(symbol,stopDistance,margin);
      double minimum=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
      double contract=SymbolInfoDouble(symbol,SYMBOL_TRADE_CONTRACT_SIZE);
      double tickSize=SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE);
      double tickValue=SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE);
      double riskPct=(equity>0.0 && minimumLoss>0.0 ? minimumLoss/equity*100.0 : 0.0);
      PrintFormat("GOLD_SYMBOL_SCAN|Symbol=%s|MinLot=%g|Contract=%.4f|TickSize=%g|TickValue=%g|ScalpMinLotSL=%.2f|RiskPct=%.4f|Margin=%.2f|EligibleUSD100Risk=%.2f%%:%s",
                  symbol,minimum,contract,tickSize,tickValue,minimumLoss,riskPct,margin,
                  InpSmallGoldMaxRiskPct,(minimumLoss>0.0 && riskPct<=InpSmallGoldMaxRiskPct ? "YES":"NO"));
      if(symbol==requestedSymbol)
         requestedLoss=minimumLoss;
      if(minimumLoss>0.0 && minimumLoss<bestLoss)
      {
         bestLoss=minimumLoss;
         bestSymbol=symbol;
      }
   }

   string selected=requestedSymbol;
   if(InpGoldSymbolScanMode==GOLD_SCAN_AUTO_SELECT && equity>0.0 && equity<=InpGoldScanMaxEquity &&
      bestSymbol!="" && bestLoss<=equity*InpSmallGoldMaxRiskPct/100.0)
   {
      selected=bestSymbol;
      PrintFormat("GOLD_SYMBOL_AUTO_SELECT|Requested=%s|Selected=%s|Equity=%.2f|MinLotScalpLoss=%.2f|RiskPct=%.4f",
                  requestedSymbol,selected,equity,bestLoss,bestLoss/equity*100.0);
   }
   double selectedMargin=0.0;
   double selectedLoss=(selected==requestedSymbol && requestedLoss>0.0 ? requestedLoss :
                        EstimateGoldMinimumLotLoss(selected,stopDistance,selectedMargin));
   g_smallGoldContractEligible=(equity>0.0 && selectedLoss>0.0 &&
                                selectedLoss<=equity*InpSmallGoldMaxRiskPct/100.0);
   if(InpGoldSymbolScanMode==GOLD_SCAN_AUTO_SELECT && equity<=InpGoldScanMaxEquity && !g_smallGoldContractEligible)
      PrintFormat("GOLD_SYMBOL_AUTO_SELECT|Result=NO_RISK_COMPLIANT_GOLD|Requested=%s|Best=%s|BestLoss=%.2f|RiskBudget=%.2f",
                  requestedSymbol,bestSymbol,(bestLoss==DBL_MAX?0.0:bestLoss),equity*InpSmallGoldMaxRiskPct/100.0);
   return selected;
}

double CapitalTierThreshold(int tier)
{
   if(tier<=0) return 0.0;
   if(tier==1) return 300.0;
   if(tier==2) return 500.0;
   if(tier==3) return 800.0;
   if(tier==4) return 1000.0;
   if(tier==5) return 1500.0;
   if(tier==6) return 2000.0;
   if(tier==7) return 3000.0;
   if(tier==8) return 5000.0;
   if(tier==9) return 10000.0;
   if(tier==10) return 15000.0;
   if(tier==11) return 20000.0;
   return 30000.0;
}

int CapitalTierForEquity(double equity)
{
   int tier=0;
   for(int candidate=1;candidate<=12;candidate++)
      if(equity>=CapitalTierThreshold(candidate)) tier=candidate;
   return tier;
}

void ConfigureCapitalTier(int tier)
{
   for(int s=0;s<3;s++)
   {
      g_ladderStrategyAllowed[s]=false;
      g_ladderRiskCap[s]=0.0;
      g_ladderMaxPositions[s]=0;
   }
   g_ladderTotalMaxPositions=0;
   g_ladderTotalRiskCap=0.0;
   double threshold=CapitalTierThreshold(tier);
   g_capitalTierName=(tier<=0 ? "USD100/200 信号记录" : "USD"+DoubleToString(threshold,0)+"+");

   if(tier<=0)
   {
      if(g_smallGoldContractEligible)
      {
         g_capitalTierName="USD100/200 微型黄金合格，仅Scalping";
         g_ladderStrategyAllowed[0]=true;
         g_ladderRiskCap[0]=InpSmallGoldMaxRiskPct;
         g_ladderMaxPositions[0]=1;
         g_ladderTotalMaxPositions=1;
         g_ladderTotalRiskCap=InpSmallGoldMaxRiskPct;
      }
      return;
   }

   g_ladderStrategyAllowed[0]=true;
   g_ladderMaxPositions[0]=1;
   if(tier==1)
   {
      g_ladderRiskCap[0]=2.0;
      g_ladderTotalRiskCap=2.0;
      g_ladderTotalMaxPositions=1;
      return;
   }
   if(tier==2)
   {
      g_ladderRiskCap[0]=1.0;
      g_ladderTotalRiskCap=1.0;
      g_ladderTotalMaxPositions=1;
      return;
   }

   for(int s=0;s<3;s++)
   {
      g_ladderStrategyAllowed[s]=true;
      g_ladderMaxPositions[s]=1;
   }
   if(tier==3)
   {
      for(int s=0;s<3;s++) g_ladderRiskCap[s]=2.0;
      g_ladderTotalRiskCap=4.0;
      g_ladderTotalMaxPositions=2;
   }
   else if(tier==4)
   {
      for(int s=0;s<3;s++) g_ladderRiskCap[s]=1.5;
      g_ladderTotalRiskCap=3.0;
      g_ladderTotalMaxPositions=2;
   }
   else if(tier==5 || tier==6)
   {
      for(int s=0;s<3;s++) g_ladderRiskCap[s]=1.0;
      g_ladderTotalRiskCap=2.5;
      g_ladderTotalMaxPositions=3;
   }
   else if(tier==7)
   {
      for(int s=0;s<3;s++) g_ladderRiskCap[s]=0.5;
      g_ladderTotalRiskCap=1.5;
      g_ladderTotalMaxPositions=3;
   }
   else
   {
      for(int s=0;s<3;s++) g_ladderRiskCap[s]=0.25;
      g_ladderTotalRiskCap=1.0;
      g_ladderTotalMaxPositions=(tier>=9 ? 5 : 3);
      if(tier>=9)
         for(int s=0;s<3;s++) g_ladderMaxPositions[s]=2;
   }
}

void UpdateCapitalLadder(bool startup)
{
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   if(InpCapitalLadderRequireUSD && AccountInfoString(ACCOUNT_CURRENCY)!="USD")
   {
      if(g_capitalTier!=-2)
         PrintFormat("CAPITAL_LADDER_BLOCK|AccountCurrency=%s|Required=USD|Equity=%.2f",AccountInfoString(ACCOUNT_CURRENCY),equity);
      g_capitalTier=-2;
      g_smallGoldContractEligible=false;
      ConfigureCapitalTier(0);
      g_capitalTierName="非USD账户：阶梯禁止新仓";
      return;
   }

   int previous=g_capitalTier;
   if(startup || g_capitalTier<0)
      g_capitalTier=CapitalTierForEquity(equity);
   else
   {
      while(g_capitalTier>0 && equity<CapitalTierThreshold(g_capitalTier))
         g_capitalTier--;
      while(g_capitalTier<12 && equity>=CapitalTierThreshold(g_capitalTier+1)*(1.0+InpCapitalUpgradeBufferPct/100.0))
         g_capitalTier++;
   }
   ConfigureCapitalTier(g_capitalTier);
   if(startup || previous!=g_capitalTier)
      PrintFormat("CAPITAL_LADDER|Equity=%.2f|Tier=%d|Name=%s|Allowed=%s/%s/%s|RiskCap=%.2f/%.2f/%.2f|TotalRisk=%.2f|MaxPos=%d/%d/%d Total=%d|UpgradeBuffer=%.2f%%",
                  equity,g_capitalTier,g_capitalTierName,
                  (g_ladderStrategyAllowed[0]?"YES":"NO"),(g_ladderStrategyAllowed[1]?"YES":"NO"),(g_ladderStrategyAllowed[2]?"YES":"NO"),
                  g_ladderRiskCap[0],g_ladderRiskCap[1],g_ladderRiskCap[2],g_ladderTotalRiskCap,
                  g_ladderMaxPositions[0],g_ladderMaxPositions[1],g_ladderMaxPositions[2],g_ladderTotalMaxPositions,
                  InpCapitalUpgradeBufferPct);
}

bool CapitalLadderAllows(StrategyId strategy)
{
   if(InpCapitalLadderMode!=CAPITAL_LADDER_ENFORCE)
      return true;
   return g_ladderStrategyAllowed[(int)strategy];
}

double EffectiveStrategyRiskPercent(StrategyId strategy,double configuredRisk)
{
   if(InpCapitalLadderMode!=CAPITAL_LADDER_ENFORCE)
      return configuredRisk;
   if(!g_ladderStrategyAllowed[(int)strategy] || g_ladderRiskCap[(int)strategy]<=0.0)
      return 0.0;
   return MathMin(configuredRisk,g_ladderRiskCap[(int)strategy]);
}

double EffectiveTotalRiskCap()
{
   if(InpSmallAccountProfile==SMALL_ACCOUNT_USD100)
      return InpUSD100MaxSingleRiskPct;
   if(InpSmallAccountProfile==SMALL_ACCOUNT_USD500)
      return InpUSD500MaxTotalRiskPct;
   if(InpCapitalLadderMode!=CAPITAL_LADDER_ENFORCE)
      return InpMaxAccountOpenRiskPct;
   if(g_ladderTotalRiskCap<=0.0)
      return 0.0;
   return MathMin(InpMaxAccountOpenRiskPct,g_ladderTotalRiskCap);
}

int EffectiveStrategyMaxPositions(StrategyId strategy,int configuredMaximum)
{
   if(InpCapitalLadderMode!=CAPITAL_LADDER_ENFORCE || g_ladderMaxPositions[(int)strategy]<=0)
      return configuredMaximum;
   return MathMin(configuredMaximum,g_ladderMaxPositions[(int)strategy]);
}

int EffectiveTotalMaxPositions()
{
   if(InpSmallAccountProfile==SMALL_ACCOUNT_USD100)
      return 1;
   if(InpSmallAccountProfile==SMALL_ACCOUNT_USD500)
      return MathMin(InpTotalMaxOpenPositions,2);
   if(InpCapitalLadderMode!=CAPITAL_LADDER_ENFORCE || g_ladderTotalMaxPositions<=0)
      return InpTotalMaxOpenPositions;
   return MathMin(InpTotalMaxOpenPositions,g_ladderTotalMaxPositions);
}

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   if(!ValidateInputs())
      return INIT_PARAMETERS_INCORRECT;

   string requestedSymbol=(InpTradeSymbol == "" ? _Symbol : InpTradeSymbol);
   g_symbol = ResolveGoldTradeSymbol(requestedSymbol);

   if(!SymbolSelect(g_symbol, true))
   {
      Print("Cannot select symbol: ", g_symbol);
      return INIT_FAILED;
   }

   if(!RefreshSymbolSpec())
      return INIT_FAILED;
   if(!ValidateRuntimeConfiguration())
      return INIT_PARAMETERS_INCORRECT;
   UpdateCapitalLadder(true);

   ENUM_ACCOUNT_MARGIN_MODE marginMode = (ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);
   g_isHedging = (marginMode == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
   if(!g_isHedging)
   {
      Print("警告：当前账户是Netting/Exchange模式，同一黄金品种只能保留一个净持仓，无法保证三策略隔离。");
      if(InpRequireHedging)
      {
         Print("EA已停止初始化。请使用MT5 Hedging账户，或明确关闭 InpRequireHedging（不建议）。");
         return INIT_FAILED;
      }
   }

   InitializeRuntime(STRATEGY_SCALPING, InpScalpMagic, "Scalping M5");
   InitializeRuntime(STRATEGY_INTRADAY, InpIntradayMagic, "Intraday M30");
   InitializeRuntime(STRATEGY_SWING, InpSwingMagic, "Swing D1/H4/M30");
   g_strategyEnabled[(int)STRATEGY_SCALPING]=InpEnableScalpingM5;
   g_strategyEnabled[(int)STRATEGY_INTRADAY]=InpEnableIntradayM30;
   g_strategyEnabled[(int)STRATEGY_SWING]=InpEnableSwingD1;
   if(!InitializeIndicatorHandles())
      return INIT_FAILED;
   ArrayResize(g_detectedZoneHashes,0);
   ArrayResize(g_departedZoneHashes,0);
   ArrayResize(g_reportedDuplicateZoneHashes,0);
   ArrayResize(g_tradeAudit,0);
   ArrayResize(g_filledClusterIds,0);
   ArrayResize(g_filledClusterTimes,0);

   trade.SetDeviationInPoints(InpDeviationPoints);
   trade.SetTypeFillingBySymbol(g_symbol);

   if(!MQLInfoInteger(MQL_TESTER))
      LoadPersistentState();
   else
      Print("策略测试器模式：本次漏斗和区域状态从零开始，不载入其他回测的Terminal Global Variables。");
   RebuildRuntimeStatistics();
   RecoverOpenPositions();
   PrintStartupDiagnostics();
   PrintAccountAndSymbolDiagnostics();
   if(InpShowPanel)
   {
      CreateDashboardObjects();
      UpdateChinesePanel(true);
   }

   PrintFormat("GSM黄金三策略EA v4.00研究基线已启动：%s，Hedging=%s，Digits=%d Point=%g TickSize=%g MinLot=%g MaxLot=%g Step=%g Stops=%d Freeze=%d",
               g_symbol, (g_isHedging ? "是" : "否"),
               g_digits, g_point, g_tickSize, g_volumeMin, g_volumeMax, g_volumeStep, g_stopsLevel, g_freezeLevel);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   PrintAllFunnels("EA停止/回测结束");
   WriteSignalFunnelCSV();
   SavePersistentState();
   ReleaseIndicatorHandles();
   if(InpShowPanel)
      DeleteDashboardObjects();
   Comment("");
}

string FunnelZeroTradeDiagnosis(int strategy)
{
   if(g_funnel[strategy].zonesDetected==0) return "全部停在ZonesDetected：没有识别到合格区域";
   if(g_funnel[strategy].zonesDeparted==0) return "全部停在ZonesDeparted：区域未完成明确离开";
   if(g_funnel[strategy].firstTouches==0) return "全部停在FirstTouches：价格没有首次回踩";
   if(g_funnel[strategy].hardSOPPassed==0)
   {
      if(strategy==(int)STRATEGY_SCALPING && g_funnel[strategy].candlePatternsDetected==0)
         return "全部停在Scalping反转K白名单：First Touch K线没有合格形态";
      if(strategy==(int)STRATEGY_SWING)
         return "全部停在Swing硬确认：没有M30反转K或假突破收回";
      return "全部停在HardSOPPassed：核心SOP未通过";
   }
   if(g_funnel[strategy].confidencePassed==0)
   {
      if(g_funnel[strategy].bollingerRejected>0)
         return StringFormat("全部停在技术/Confidence层：Bollinger HARD拒绝=%I64d，EMA拒绝=%I64d，RSI拒绝=%I64d，MACD HARD拒绝=%I64d；最后原因=%s",
                             g_funnel[strategy].bollingerRejected,g_funnel[strategy].emaRejected,
                             g_funnel[strategy].rsiRejected,g_funnel[strategy].macdRejected,g_runtime[strategy].rejectReason);
      if(g_funnel[strategy].macdRejected>0)
         return StringFormat("全部停在技术/Confidence层：MACD HARD拒绝=%I64d，EMA拒绝=%I64d，RSI拒绝=%I64d；最后原因=%s",
                             g_funnel[strategy].macdRejected,g_funnel[strategy].emaRejected,
                             g_funnel[strategy].rsiRejected,g_runtime[strategy].rejectReason);
      if(StrategyIndicatorFiltersEnabled((StrategyId)strategy))
         return "全部停在EMA+RSI/Confidence层；最后原因="+g_runtime[strategy].rejectReason;
      return "全部停在ConfidencePassed：评分过滤已开启且分数不足";
   }
   if(g_funnel[strategy].globalGatePassed==0)
   {
      if(g_funnel[strategy].minimumLotRiskRejected>0)
         return StringFormat("全部停在GlobalGatePassed：资金阶梯拒绝；其中最小手数超风险=%I64d",g_funnel[strategy].minimumLotRiskRejected);
      if(InpCapitalLadderMode==CAPITAL_LADDER_ENFORCE && !g_ladderStrategyAllowed[strategy])
         return "全部停在GlobalGatePassed：资金阶梯禁止本策略新仓；信号仍已记录";
      return "全部停在GlobalGatePassed："+(g_runtime[strategy].rejectReason=="" ? "时段/新闻/点差/风控/权限门控拒绝" : g_runtime[strategy].rejectReason);
   }
   if(g_funnel[strategy].ordersRequested==0) return "已通过门控但没有请求订单：检查执行路径日志";
   if(g_funnel[strategy].ordersFilled==0 && g_funnel[strategy].ordersRejected>0) return "订单已发送但全部被交易服务器拒绝";
   if(g_funnel[strategy].ordersFilled==0) return "订单已请求但尚未收到成交Deal确认";
   return "已有成交";
}

void PrintStrategyFunnel(int strategy, string context)
{
   PrintFormat("[%s][%s] ZonesDetected=%I64d ZonesDeparted=%I64d FirstTouches=%I64d CandlePatternsDetected=%I64d ChartPatternsDetected=%I64d HardSOPPassed=%I64d ConfidencePassed=%I64d GlobalGatePassed=%I64d OrdersRequested=%I64d OrdersFilled=%I64d OrdersRejected=%I64d",
               context,g_runtime[strategy].name,
               g_funnel[strategy].zonesDetected,g_funnel[strategy].zonesDeparted,g_funnel[strategy].firstTouches,
               g_funnel[strategy].candlePatternsDetected,g_funnel[strategy].chartPatternsDetected,
               g_funnel[strategy].hardSOPPassed,g_funnel[strategy].confidencePassed,g_funnel[strategy].globalGatePassed,
                g_funnel[strategy].ordersRequested,g_funnel[strategy].ordersFilled,g_funnel[strategy].ordersRejected);
   PrintFormat("[%s][%s][技术与门控] EMA通过=%I64d EMA拒绝=%I64d RSI通过=%I64d RSI拒绝=%I64d MACD评估=%I64d MACD通过=%I64d MACD硬拒绝=%I64d Bollinger评估=%I64d Bollinger通过=%I64d Bollinger硬拒绝=%I64d Confidence拒绝=%I64d 时段拒绝=%I64d 点差拒绝=%I64d 持仓限制拒绝=%I64d 风险拒绝=%I64d 保证金拒绝=%I64d 最小手数超风险=%I64d 总风险拒绝=%I64d 资金不足=%I64d 指标等待=%I64d MACD等待=%I64d Bollinger等待=%I64d 重复Zone拒绝=%I64d 重复Cluster拒绝=%I64d",
               context,g_runtime[strategy].name,
               g_funnel[strategy].emaPassed,g_funnel[strategy].emaRejected,
               g_funnel[strategy].rsiPassed,g_funnel[strategy].rsiRejected,
               g_funnel[strategy].macdEvaluated,g_funnel[strategy].macdPassed,g_funnel[strategy].macdRejected,
               g_funnel[strategy].bollingerEvaluated,g_funnel[strategy].bollingerPassed,g_funnel[strategy].bollingerRejected,
               g_funnel[strategy].confidenceRejected,g_funnel[strategy].sessionRejected,
               g_funnel[strategy].spreadRejected,g_funnel[strategy].positionLimitRejected,
               g_funnel[strategy].riskRejected,g_funnel[strategy].marginRejected,
               g_funnel[strategy].minimumLotRiskRejected,g_funnel[strategy].totalRiskRejected,
               g_funnel[strategy].insufficientFundsRejected,g_funnel[strategy].indicatorDataWaits,
               g_funnel[strategy].macdDataWaits,g_funnel[strategy].bollingerDataWaits,
               g_funnel[strategy].duplicateZoneRejected,g_funnel[strategy].duplicateClusterRejected);
   if(strategy==(int)STRATEGY_SWING)
      PrintFormat("[%s][Swing完整漏斗] D1方向成立=%I64d H4方向一致=%I64d H4区域=%I64d SR共振=%I64d M30触及=%I64d M30反转或假突破=%I64d EMA通过=%I64d RSI通过=%I64d MACD评分=%I64d 资金点差持仓拒绝=%I64d 最终开仓=%I64d",
                  context,g_funnel[strategy].d1DirectionPassed,g_funnel[strategy].h4DirectionPassed,
                  g_funnel[strategy].h4ZonesFound,g_funnel[strategy].srConfluencePassed,
                  g_funnel[strategy].m30Touches,g_funnel[strategy].m30Confirmations,
                  g_funnel[strategy].emaPassed,g_funnel[strategy].rsiPassed,
                  g_funnel[strategy].macdEvaluated,
                  g_funnel[strategy].sessionRejected+g_funnel[strategy].spreadRejected+
                  g_funnel[strategy].positionLimitRejected+g_funnel[strategy].riskRejected+g_funnel[strategy].marginRejected,
                  g_funnel[strategy].ordersFilled);
   PrintFormat("[%s][%s] 零交易诊断：%s",context,g_runtime[strategy].name,FunnelZeroTradeDiagnosis(strategy));
}

void PrintAllFunnels(string context)
{
   for(int s=0;s<3;s++)
      PrintStrategyFunnel(s,context);
}

void WriteSignalFunnelCSV()
{
   if(StringLen(InpSignalFunnelFileName)<5)
      return;
   int handle=FileOpen(InpSignalFunnelFileName,FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_SHARE_READ|FILE_COMMON,',');
   if(handle==INVALID_HANDLE)
   {
      PrintFormat("SIGNAL_FUNNEL_CSV_ERROR|File=%s|Error=%d",InpSignalFunnelFileName,GetLastError());
      return;
   }
   bool empty=(FileSize(handle)==0);
   FileSeek(handle,0,SEEK_END);
   if(empty)
      FileWrite(handle,"Run","EndTime","SOP","Magic","ZonesDetected","ZonesDeparted","FirstTouches",
                "CandlePatternsDetected","ChartPatternsDetected","HardSOPPassed","ConfidencePassed","GlobalGatePassed",
                "OrdersRequested","OrdersFilled","OrdersRejected","EMAPassed","EMARejected","RSIPassed","RSIRejected",
                "MACDEvaluated","MACDPassed","MACDRejected","BollingerEvaluated","BollingerPassed","BollingerRejected","ConfidenceRejected","SessionRejected",
                "SpreadRejected","PositionLimitRejected","RiskRejected","MarginRejected","MinimumLotRiskRejected",
                "TotalRiskRejected","InsufficientFundsRejected","IndicatorDataWaits","MACDDataWaits","BollingerDataWaits",
                "DuplicateZoneRejected","DuplicateClusterRejected","ZeroTradeDiagnosis");
   for(int s=0;s<3;s++)
      FileWrite(handle,InpAuditRunLabel,TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),g_runtime[s].name,StrategyMagic((StrategyId)s),
                g_funnel[s].zonesDetected,g_funnel[s].zonesDeparted,g_funnel[s].firstTouches,
                g_funnel[s].candlePatternsDetected,g_funnel[s].chartPatternsDetected,g_funnel[s].hardSOPPassed,
                g_funnel[s].confidencePassed,g_funnel[s].globalGatePassed,g_funnel[s].ordersRequested,g_funnel[s].ordersFilled,
                g_funnel[s].ordersRejected,g_funnel[s].emaPassed,g_funnel[s].emaRejected,g_funnel[s].rsiPassed,g_funnel[s].rsiRejected,
                g_funnel[s].macdEvaluated,g_funnel[s].macdPassed,g_funnel[s].macdRejected,
                g_funnel[s].bollingerEvaluated,g_funnel[s].bollingerPassed,g_funnel[s].bollingerRejected,
                g_funnel[s].confidenceRejected,g_funnel[s].sessionRejected,g_funnel[s].spreadRejected,g_funnel[s].positionLimitRejected,
                g_funnel[s].riskRejected,g_funnel[s].marginRejected,g_funnel[s].minimumLotRiskRejected,g_funnel[s].totalRiskRejected,
                g_funnel[s].insufficientFundsRejected,g_funnel[s].indicatorDataWaits,g_funnel[s].macdDataWaits,
                g_funnel[s].bollingerDataWaits,g_funnel[s].duplicateZoneRejected,g_funnel[s].duplicateClusterRejected,
                FunnelZeroTradeDiagnosis(s));
   FileFlush(handle);
   FileClose(handle);
}

bool ValidateInputs()
{
   if(InpCapitalUpgradeBufferPct<0.0 || InpCapitalUpgradeBufferPct>50.0 ||
      InpSmallGoldMaxRiskPct<=0.0 || InpSmallGoldMaxRiskPct>10.0 || InpGoldScanMaxEquity<0.0)
   {
      Print("参数错误：资金阶梯升级缓冲、微型黄金风险或扫描资金上限无效。");
      return false;
   }
   if(InpEnableTradeReviewCSV && StringLen(InpTradeReviewFileName)<5)
   {
      Print("参数错误：逐笔审计CSV文件名为空或过短。");
      return false;
   }
   if((InpEnableSignalAuditCSV && StringLen(InpSignalAuditFileName)<5) || StringLen(InpSignalFunnelFileName)<5)
   {
      Print("参数错误：v4.00信号审计或漏斗CSV文件名为空/过短。");
      return false;
   }
   if(InpClusterDistanceATR<=0.0 || InpClusterDistanceATR>3.0 ||
      InpScalpClusterCooldownBars<1 || InpIntradayClusterCooldownBars<1 || InpSwingClusterCooldownBars<1)
   {
      Print("参数错误：Cluster距离ATR或冷却K线数量无效。");
      return false;
   }
   if(InpConfidenceFullScore<0.0 || InpConfidenceFullScore>100.0 || InpConfidenceFullTolerance<0.0 ||
      InpConfidenceBoostMaxLot<0.01 || InpConfidenceBoostMaxLot>0.05 ||
      InpUSD100MaxSingleRiskPct<=0.0 || InpUSD100MaxSingleRiskPct>15.0 ||
      InpUSD500MaxSingleRiskPct<=0.0 || InpUSD500MaxSingleRiskPct>5.0 ||
      InpUSD500MaxTotalRiskPct<=0.0 || InpUSD500MaxTotalRiskPct>10.0 ||
      InpUSD500MaxTotalRiskPct<InpUSD500MaxSingleRiskPct)
   {
      Print("参数错误：v4.00小账户风险或Confidence满分研究参数无效。");
      return false;
   }
   if(InpSmallAccountProfile!=SMALL_ACCOUNT_OFF && InpCapitalLadderMode==CAPITAL_LADDER_ENFORCE)
   {
      Print("参数错误：小账户强制0.01手研究不能同时启用旧资金阶梯ENFORCE，否则USD100/USD500策略会在手数选择前被禁止。");
      return false;
   }
   if(InpPanelXOffset<0 || InpPanelYOffset<0 || InpPanelFontSize<8 || InpPanelFontSize>16)
   {
      Print("参数错误：面板X/Y偏移不能为负数，字体大小必须在8到16之间。");
      return false;
   }
   if(InpScalpStochasticKPeriod<1 || InpScalpStochasticDPeriod<1 || InpScalpStochasticSlowing<1 ||
      InpScalpStochasticLongMin<0.0 || InpScalpStochasticLongMax>100.0 ||
      InpScalpStochasticLongMin>InpScalpStochasticLongMax ||
      InpScalpStochasticShortMin<0.0 || InpScalpStochasticShortMax>100.0 ||
      InpScalpStochasticShortMin>InpScalpStochasticShortMax)
   {
      Print("参数错误：Scalping Stochastic周期必须>=1，Long/Short区间必须在0到100内且Min<=Max。");
      return false;
   }
   if(InpIntradayMagic <= 0 || InpScalpMagic <= 0 || InpSwingMagic <= 0 ||
      InpIntradayMagic == InpScalpMagic || InpIntradayMagic == InpSwingMagic || InpScalpMagic == InpSwingMagic)
   {
      Print("参数错误：Scalping、Intraday、Swing三个Magic Number必须为不同的正整数。EA停止初始化。");
      return false;
   }
   if(!WeightsEqual100(InpScalpWeightZone + InpScalpWeightCandle + InpScalpWeightConfluence + InpScalpWeightMomentum) ||
      !WeightsEqual100(InpIntradayWeightZone + InpIntradayWeightDeparture + InpIntradayWeightLocation + InpIntradayWeightPattern + InpIntradayWeightMomentum + InpIntradayWeightMACD) ||
      !WeightsEqual100(InpSwingWeightD1 + InpSwingWeightH4 + InpSwingWeightZoneSR + InpSwingWeightM30 + InpSwingWeightMomentum + InpSwingWeightMACD))
   {
      Print("参数错误：每套策略的评分权重总和必须等于100。EA停止初始化，避免静默产生错误评分。");
      return false;
   }
   if(InpScalpWeightZone<0.0 || InpScalpWeightCandle<0.0 || InpScalpWeightConfluence<0.0 || InpScalpWeightMomentum<0.0 || InpScalpWeightBollinger<0.0 ||
      InpIntradayWeightZone<0.0 || InpIntradayWeightDeparture<0.0 || InpIntradayWeightLocation<0.0 || InpIntradayWeightPattern<0.0 || InpIntradayWeightMomentum<0.0 || InpIntradayWeightMACD<0.0 || InpIntradayWeightBollinger<0.0 ||
      InpSwingWeightD1<0.0 || InpSwingWeightH4<0.0 || InpSwingWeightZoneSR<0.0 || InpSwingWeightM30<0.0 || InpSwingWeightMomentum<0.0 || InpSwingWeightMACD<0.0 || InpSwingWeightBollinger<0.0)
   {
      Print("参数错误：评分权重不能为负数。");
      return false;
   }
   double scalpMax=100.0;
   double intradayMax=100.0;
   double swingMax=100.0;
   if(InpScalpMinConfidence<0.0 || InpIntradayMinConfidence<0.0 || InpSwingMinConfidence<0.0 ||
      InpScalpMinConfidence>scalpMax || InpIntradayMinConfidence>intradayMax || InpSwingMinConfidence>swingMax)
   {
      PrintFormat("参数错误：最低评分超过理论最高分。Scalp %.1f/%.1f Intraday %.1f/%.1f Swing %.1f/%.1f",
                  InpScalpMinConfidence,scalpMax,InpIntradayMinConfidence,intradayMax,InpSwingMinConfidence,swingMax);
      return false;
   }
   if(InpScalpMaxOpenPositions<1 || InpIntradayMaxOpenPositions<1 || InpSwingMaxOpenPositions<1 || InpTotalMaxOpenPositions<1)
   {
      Print("参数错误：各策略和总持仓上限必须至少为1。");
      return false;
   }
   if(InpScalpFixedLot<=0.0 || InpIntradayFixedLot<=0.0 || InpSwingFixedLot<=0.0 ||
      InpScalpRiskPercent<=0.0 || InpIntradayRiskPercent<=0.0 || InpSwingRiskPercent<=0.0 || InpMaxAccountOpenRiskPct<=0.0)
   {
      Print("参数错误：固定手数、策略风险百分比和账户总风险上限必须为正数。");
      return false;
   }
   if(InpSwingConfirmationBars<1 || InpSwingConfirmationBars>12)
   {
      Print("参数错误：Swing M30确认窗口必须在1到12根已收盘K线之间。");
      return false;
   }
   if(InpSwingMaxChaseZoneFraction<0.0 || InpSwingMaxChaseZoneFraction>3.0)
   {
      Print("参数错误：Swing追价距离必须在0到3倍Zone宽度之间。");
      return false;
   }
   if(InpIntradayMACDFast<2 || InpIntradayMACDSlow<=InpIntradayMACDFast || InpIntradayMACDSignal<2 ||
      InpSwingMACDFast<2 || InpSwingMACDSlow<=InpSwingMACDFast || InpSwingMACDSignal<2)
   {
      Print("参数错误：MACD必须满足Fast>=2、Slow>Fast、Signal>=2。");
      return false;
   }
   if(InpScalpBollingerPeriod<2 || InpIntradayBollingerPeriod<2 || InpSwingBollingerPeriod<2 ||
      InpScalpBollingerDeviation<=0.0 || InpIntradayBollingerDeviation<=0.0 || InpSwingBollingerDeviation<=0.0)
   {
      Print("参数错误：Bollinger Period必须>=2且Deviation必须>0。");
      return false;
   }
   if(!ValidSessionHours(InpScalpStartHour,InpScalpEndHour) ||
      !ValidSessionHours(InpIntradayStartHour,InpIntradayEndHour) ||
      !ValidSessionHours(InpSwingStartHour,InpSwingEndHour))
   {
      Print("参数错误：交易时段为空或小时范围无效。Start必须0-23，End必须0-24，Start不能等于End。");
      return false;
   }
   if(InpMaxSpreadPoints<0 || InpScalpMaxSpreadPoints<0 || InpIntradayMaxSpreadPoints<0 || InpSwingMaxSpreadPoints<0)
   {
      Print("参数错误：点差限制必须使用非负MT5 points；0表示关闭该点差过滤。");
      return false;
   }
   if(InpATRPeriod < 2 || InpIntradayLookbackBars < 20)
   {
      Print("Invalid ATR period or Intraday lookback.");
      return false;
   }
   if(InpIntradayPointInPrice <= 0.0 || InpIntradayMidEntryPoints <= 0.0)
   {
      Print("Intraday point conversion and midpoint threshold must be positive.");
      return false;
   }
   if(InpIntradayLongWickRatio <= 0.0 || InpIntradayLongWickRatio >= 1.0)
   {
      Print("Intraday long-wick ratio must be between 0 and 1.");
      return false;
   }
   if(InpIntradayBaseBars < 2 || InpIntradayBaseMaxATR <= 0.0)
   {
      Print("Intraday base settings are invalid.");
      return false;
   }
   if(InpIntradayImpulseBars < 2 || InpIntradayImpulseBodyATR <= 0.0)
   {
      Print("Intraday impulse settings are invalid.");
      return false;
   }
   if(InpIntradayMinZoneWidthATR<=0.0 || InpIntradayMaxZoneWidthATR<=InpIntradayMinZoneWidthATR)
   {
      Print("Intraday zone-width ATR filter settings are invalid.");
      return false;
   }
   if(InpIntradayMinTouchDepth<0.0 || InpIntradayMinTouchDepth>1.0)
   {
      Print("Intraday minimum touch-depth setting must be between 0 and 1.");
      return false;
   }
   if(InpIntradayConfirmationMaxBars < 1 ||
      InpIntradayConfirmationMinStrength < CANDLE_STRENGTH_WEAK ||
      InpIntradayConfirmationMinStrength > CANDLE_STRENGTH_STRONG)
   {
      Print("Intraday closed-candle confirmation settings are invalid.");
      return false;
   }
   if(InpIntradaySLPoints <= 0.0 || InpIntradayTPPoints <= 0.0)
   {
      Print("Intraday SL and TP must be positive.");
      return false;
   }
   if(InpIntradayBreakEvenAtR<=0.0 || InpIntradayBreakEvenOffsetPoints<0.0 || InpIntradayBreakEvenStepPoints<=0.0)
   {
      Print("Intraday break-even settings are invalid.");
      return false;
   }
   if(InpSwingSRMinTouches < 2 || InpSwingSRZoneATR <= 0.0 ||
      InpSwingSRMinBounceATR <= 0.0 || InpSwingSRMaxChopBars < 1)
   {
      Print("Swing support/resistance settings are invalid.");
      return false;
   }
   if(InpSwingSLBufferPips <= 0.0 || InpSwingConfluencePips < 0.0 ||
      InpSwingMinTargetR <= 0.0 || InpSwingRR <= 0.0 ||
      InpSwingHighVolatilityATRPricePct<=0.0 || InpSwingHighVolatilityRR<InpSwingMinTargetR)
   {
      Print("Swing zone, stop, or target settings are invalid.");
      return false;
   }
   if(InpSwingBreakEvenAtR <= 0.0 || InpSwingBreakEvenOffsetPips < 0.0 ||
      InpSwingTrailStartR <= 0.0 || InpSwingTrailATRMultiple <= 0.0 ||
      InpSwingTrailStepPips < 0.0)
   {
      Print("Swing protection settings are invalid.");
      return false;
   }
   if(InpScalpBreakEvenAtR <= 0.0 || InpScalpBreakEvenOffsetPips < 0.0 ||
      InpScalpBreakEvenStepPips < 0.0)
   {
      Print("Scalping protection settings are invalid.");
      return false;
   }
   if(InpScalpRegimeEMAFast < 1 || InpScalpRegimeEMASlow < 2 ||
      InpScalpRegimeEMAFast >= InpScalpRegimeEMASlow)
   {
      Print("Scalping HTF regime EMA settings are invalid.");
      return false;
   }
   if(InpCoursePipInPrice <= 0.0 || InpIntradayPointInPrice <= 0.0 ||
      InpPatternPivotDepth < 1 || InpPatternMinPivotDistance < 1 || InpZoneExpiryBars < 10 || InpSwingZoneExpiryBars < 10 ||
      InpVolumeAveragePeriod < 2 || InpCandleTrendBars < 2)
   {
      Print("参数错误：价格换算、结构、区域或成交量参数无效。");
      return false;
   }
   if(InpScalpZonePips<=0.0 || InpScalpSLPips<=0.0 || InpScalpTPPips<=0.0 ||
      InpIntradaySLPoints<=0.0 || InpIntradayTPPoints<=0.0 || InpSwingZonePips<=0.0 || InpSwingSLBufferPips<=0.0)
   {
      Print("参数错误：Course Pips/PT换算相关Zone、SL或TP参数必须为正数。");
      return false;
   }
   if(!ValidIndicatorInputs(InpScalpEMAFast,InpScalpEMASlow,InpScalpRSIPeriod,
                            InpScalpRSILongMin,InpScalpRSILongMax,InpScalpRSIShortMin,InpScalpRSIShortMax) ||
      !ValidIndicatorInputs(InpIntradayEMAFast,InpIntradayEMASlow,InpIntradayRSIPeriod,
                            InpIntradayRSILongMin,InpIntradayRSILongMax,InpIntradayRSIShortMin,InpIntradayRSIShortMax) ||
      !ValidIndicatorInputs(InpSwingEMAFast,InpSwingEMASlow,InpSwingRSIPeriod,
                            InpSwingRSILongMin,InpSwingRSILongMax,InpSwingRSIShortMin,InpSwingRSIShortMax))
   {
      Print("参数错误：EMA必须满足Fast>=2且Slow>Fast；RSI周期>=2，方向区间必须在0到100内且Min<=Max。");
      return false;
   }
   return true;
}

bool ValidIndicatorInputs(int emaFast,int emaSlow,int rsiPeriod,
                          double longMin,double longMax,double shortMin,double shortMax)
{
   return (emaFast>=2 && emaSlow>emaFast && rsiPeriod>=2 &&
           longMin>=0.0 && longMax<=100.0 && longMin<=longMax &&
           shortMin>=0.0 && shortMax<=100.0 && shortMin<=shortMax);
}

bool ValidSessionHours(int startHour,int endHour)
{
   return (startHour>=0 && startHour<=23 && endHour>=0 && endHour<=24 && startHour!=endHour);
}

bool ValidateRuntimeConfiguration()
{
   string upperSymbol=g_symbol;
   StringToUpper(upperSymbol);
   if(StringFind(upperSymbol,"GOLD")<0 && StringFind(upperSymbol,"XAU")<0)
   {
      PrintFormat("参数错误：交易品种%s不像黄金品种。FxPro应使用GOLD，Tradona应使用XAUUSD.tm。",g_symbol);
      return false;
   }
   if(g_symbolTradeMode==SYMBOL_TRADE_MODE_DISABLED)
   {
      PrintFormat("参数错误：经纪商已禁用%s交易。",g_symbol);
      return false;
   }

   MqlTick startupTick;
   if(!SymbolInfoTick(g_symbol,startupTick) || startupTick.bid<=0.0 || startupTick.ask<=0.0)
   {
      PrintFormat("参数错误：%s没有有效报价，无法验证点差与Course Pips/PT。",g_symbol);
      return false;
   }
   double scalpZone=CoursePipsToPrice(InpScalpZonePips);
   double scalpSL=CoursePipsToPrice(InpScalpSLPips);
   double scalpTP=CoursePipsToPrice(InpScalpTPPips);
   double intraSL=PTToPrice(InpIntradaySLPoints);
   double intraTP=PTToPrice(InpIntradayTPPoints);
   double swingZone=CoursePipsToPrice(InpSwingZonePips);
   double swingBuffer=CoursePipsToPrice(InpSwingSLBufferPips);
   double marketPrice=(startupTick.bid+startupTick.ask)*0.5;
   if(scalpZone<g_tickSize || scalpSL<g_tickSize || scalpTP<g_tickSize || intraSL<g_tickSize || intraTP<g_tickSize ||
      swingZone<g_tickSize || swingBuffer<g_tickSize || scalpSL>marketPrice*0.25 || intraSL>marketPrice*0.25 || swingZone>marketPrice*0.25)
   {
      PrintFormat("参数错误：Course Pips/PT换算导致Zone或SL异常。ScalpZone=%g SL=%g TP=%g IntradaySL=%g TP=%g SwingZone=%g Buffer=%g",
                  scalpZone,scalpSL,scalpTP,intraSL,intraTP,swingZone,swingBuffer);
      return false;
   }

   double brokerMinStop=(double)(g_stopsLevel+2)*g_point;
   if(scalpSL<brokerMinStop || scalpTP<brokerMinStop || intraSL<brokerMinStop || intraTP<brokerMinStop)
   {
      PrintFormat("参数错误：固定SOP距离小于经纪商Stop Level。Min=%g Scalp=%g/%g Intraday=%g/%g",
                  brokerMinStop,scalpSL,scalpTP,intraSL,intraTP);
      return false;
   }
   double scalpSpreadPrice=InpScalpMaxSpreadPoints*g_point;
   double intraSpreadPrice=InpIntradayMaxSpreadPoints*g_point;
   double commonSpreadPrice=InpMaxSpreadPoints*g_point;
   double swingSpreadPrice=InpSwingMaxSpreadPoints*g_point;
   if((InpMaxSpreadPoints>0 && commonSpreadPrice>=MathMin(scalpSL,intraSL)) ||
      (InpScalpMaxSpreadPoints>0 && scalpSpreadPrice>=scalpSL) ||
      (InpIntradayMaxSpreadPoints>0 && intraSpreadPrice>=intraSL) ||
      (InpSwingMaxSpreadPoints>0 && swingSpreadPrice>=swingZone))
   {
      PrintFormat("参数错误：点差限制疑似把Course Pips误当MT5 points。Common=%g Scalp=%g Intraday=%g Swing=%g",
                  commonSpreadPrice,scalpSpreadPrice,intraSpreadPrice,swingSpreadPrice);
      return false;
   }

   Zone stateProbe;
   InitializeZone(stateProbe,1,1,TimeCurrent(),SD_FORMATION_IMPULSIVE);
   stateProbe.state=ZONE_FRESH;
   if(!TransitionZoneToDeparted(stateProbe,TimeCurrent()) || stateProbe.state!=ZONE_DEPARTED)
   {
      Print("内部错误：First Touch状态机无法由FRESH进入DEPARTED，EA停止初始化。");
      return false;
   }
   if(InpMoneyManagementMode==MONEY_MANUAL_FIXED_LOT || InpUseFixedLot)
   {
      double normalized=0.0;
      string reason="";
      if(!PrepareManualVolume(InpScalpFixedLot,normalized,reason))
      {
         Print("Scalping手动手数错误：",reason);
         return false;
      }
      if(!PrepareManualVolume(InpIntradayFixedLot,normalized,reason))
      {
         Print("Intraday手动手数错误：",reason);
         return false;
      }
      if(!PrepareManualVolume(InpSwingFixedLot,normalized,reason))
      {
         Print("Swing手动手数错误：",reason);
         return false;
      }
   }
   return true;
}

void PrintStartupDiagnostics()
{
   string message=StringFormat("GSM 3SOP v4.00研究基线启动检查通过\nSymbol=%s Hedging=%s\n三策略=独立OR，不互相确认\nStrategy Switch Scalp=%s Intraday=%s Swing=%s\nConfidenceMode Scalp=%d Intraday=%d Swing=%d\nEMA/RSI Scalp=%s/%s Intraday=%s/%s Swing=%s/%s\nMACD Scalp=OFF Intraday=%d Swing=%d\nBollinger Scalp=%d Intraday=%d Swing=%d Cluster=%s\n持仓上限 Scalp=%d Intraday=%d Swing=%d Total=%d\n资金模式=%s 总风险上限=%.2f%%\n资金阶梯 Mode=%d Tier=%s EffectiveRisk=%.2f/%.2f/%.2f%% Total=%.2f%%\n黄金扫描 Mode=%d SmallContract=%s\nNewsLock Master=%s Scalp=%s Intraday=%s Swing=%s\n1 Course Pip=%s；1 PT=%s\nSpread限制均为MT5 points",
                               g_symbol,(g_isHedging?"是":"否"),
                               (g_strategyEnabled[0]?"开启":"关闭"),(g_strategyEnabled[1]?"开启":"关闭"),(g_strategyEnabled[2]?"开启":"关闭"),
                               (int)InpScalpConfidenceMode,(int)InpIntradayConfidenceMode,(int)InpSwingConfidenceMode,
                               (InpScalpUseEMAFilter?"开":"关"),(InpScalpUseRSIFilter?"开":"关"),
                               (InpIntradayUseEMAFilter?"开":"关"),(InpIntradayUseRSIFilter?"开":"关"),
                               (InpSwingUseEMAFilter?"开":"关"),(InpSwingUseRSIFilter?"开":"关"),
                               (int)StrategyMACDMode(STRATEGY_INTRADAY),(int)StrategyMACDMode(STRATEGY_SWING),
                               (int)StrategyBollingerMode(STRATEGY_SCALPING),(int)StrategyBollingerMode(STRATEGY_INTRADAY),
                               (int)StrategyBollingerMode(STRATEGY_SWING),(InpEnableOpportunityClusters?"开启":"关闭"),
                               InpScalpMaxOpenPositions,InpIntradayMaxOpenPositions,InpSwingMaxOpenPositions,InpTotalMaxOpenPositions,
                               ((InpMoneyManagementMode==MONEY_MANUAL_FIXED_LOT || InpUseFixedLot)?"手动固定手数":"自动风险手数"),InpMaxAccountOpenRiskPct,
                               (int)InpCapitalLadderMode,g_capitalTierName,
                               EffectiveStrategyRiskPercent(STRATEGY_SCALPING,InpScalpRiskPercent),
                               EffectiveStrategyRiskPercent(STRATEGY_INTRADAY,InpIntradayRiskPercent),
                               EffectiveStrategyRiskPercent(STRATEGY_SWING,InpSwingRiskPercent),EffectiveTotalRiskCap(),
                               (int)InpGoldSymbolScanMode,(g_smallGoldContractEligible?"合格":"不合格/未启用"),
                               (InpManualNewsLock?"开启":"关闭"),(InpScalpManualNewsLock?"开启":"关闭"),(InpIntradayManualNewsLock?"开启":"关闭"),(InpSwingManualNewsLock?"开启":"关闭"),
                               DoubleToString(CoursePipsToPrice(1.0),g_digits),DoubleToString(PTToPrice(1.0),g_digits));
   Print(message);
   PrintFormat("服务器成交后固定SL/TP重新校准=%s",(InpRecenterFixedStopsAfterFill?"开启":"关闭"));
   PrintFormat("V280_SMALL_ACCOUNT|Profile=%d|ForceMinLot=%s|Confidence100Boost=%s|BoostMaxLot=%s|SingleRiskCap100=%.2f%%|SingleRiskCap500=%.2f%%|TotalRiskCap500=%.2f%%|EffectiveTotalPositions=%d",
               (int)InpSmallAccountProfile,(InpForceBrokerMinimumLot?"开启":"关闭"),
               (InpEnableConfidence100LotBoost?"开启":"关闭"),DoubleToString(InpConfidenceBoostMaxLot,VolumeDigits()),
               InpUSD100MaxSingleRiskPct,InpUSD500MaxSingleRiskPct,InpUSD500MaxTotalRiskPct,EffectiveTotalMaxPositions());
   Print("说明：Confidence 100只表示程序评分达到100分，不代表100%胜率。");
   if(InpManualNewsLock || InpScalpManualNewsLock || InpIntradayManualNewsLock || InpSwingManualNewsLock)
      Print("警告：至少一个Manual News Lock已开启；对应策略会持续零交易，直到手动关闭。此状态不会自动解除。");
   if(!InpShowPanel)
      Print("警告：InpShowPanel=false，图表启动/漏斗消息被隐藏，但日志仍会输出。");
}

double MinimumLotLossForDistance(double entry,double stopDistance)
{
   if(entry<=0.0 || stopDistance<=0.0 || g_volumeMin<=0.0)
      return 0.0;
   double result=0.0;
   if(OrderCalcProfit(ORDER_TYPE_BUY,g_symbol,g_volumeMin,entry,entry-stopDistance,result) && result<0.0)
      return MathAbs(result);
   double tickValue=SymbolInfoDouble(g_symbol,SYMBOL_TRADE_TICK_VALUE_LOSS);
   if(tickValue<=0.0) tickValue=SymbolInfoDouble(g_symbol,SYMBOL_TRADE_TICK_VALUE);
   if(g_tickSize<=0.0 || tickValue<=0.0)
      return 0.0;
   return (stopDistance/g_tickSize)*tickValue*g_volumeMin;
}

bool MinimumLotExceedsStrategyBudget(StrategyId strategy,double &minimumLoss,double &riskBudget)
{
   double entry=(g_tick.ask>0.0 ? g_tick.ask : SymbolInfoDouble(g_symbol,SYMBOL_ASK));
   double distance=CoursePipsToPrice(InpScalpSLPips);
   if(strategy==STRATEGY_INTRADAY)
      distance=PTToPrice(InpIntradaySLPoints);
   else if(strategy==STRATEGY_SWING)
      distance=CoursePipsToPrice(InpSwingZonePips+InpSwingSLBufferPips);
   minimumLoss=MinimumLotLossForDistance(entry,distance);
   double riskPct=EffectiveStrategyRiskPercent(strategy,
                    strategy==STRATEGY_SCALPING ? InpScalpRiskPercent :
                    strategy==STRATEGY_INTRADAY ? InpIntradayRiskPercent : InpSwingRiskPercent);
   if(riskPct<=0.0)
      riskPct=InpSmallGoldMaxRiskPct;
   riskBudget=AccountInfoDouble(ACCOUNT_EQUITY)*riskPct/100.0;
   return (minimumLoss>0.0 && minimumLoss>riskBudget*1.01);
}

double TechnicalMinimumEquity(double minimumLotLoss,double riskPercent)
{
   if(minimumLotLoss<=0.0 || riskPercent<=0.0)
      return 0.0;
   return minimumLotLoss/(riskPercent/100.0);
}

void PrintAccountAndSymbolDiagnostics()
{
   MqlTick startupTick={};
   SymbolInfoTick(g_symbol,startupTick);
   double entry=(startupTick.ask>0.0 ? startupTick.ask : SymbolInfoDouble(g_symbol,SYMBOL_ASK));
   double balance=AccountInfoDouble(ACCOUNT_BALANCE);
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   double freeMargin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double marginLevel=AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   double stopoutCall=AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL);
   double stopoutStop=AccountInfoDouble(ACCOUNT_MARGIN_SO_SO);
   long leverage=AccountInfoInteger(ACCOUNT_LEVERAGE);
   long stopoutMode=AccountInfoInteger(ACCOUNT_MARGIN_SO_MODE);
   double contractSize=SymbolInfoDouble(g_symbol,SYMBOL_TRADE_CONTRACT_SIZE);
   double tickValue=SymbolInfoDouble(g_symbol,SYMBOL_TRADE_TICK_VALUE);
   double marginInitial=SymbolInfoDouble(g_symbol,SYMBOL_MARGIN_INITIAL);
   string marginLevelText=(marginLevel>0.0 ? DoubleToString(marginLevel,2)+"%" : "N/A（无持仓时正常）");

   PrintFormat("ACCOUNT_SPEC|Balance=%.2f|Equity=%.2f|Leverage=1:%I64d|MarginFree=%.2f|MarginLevel=%s|StopOutCall=%.2f|StopOut=%.2f|StopOutMode=%I64d",
               balance,equity,leverage,freeMargin,marginLevelText,stopoutCall,stopoutStop,stopoutMode);
   PrintFormat("SYMBOL_SPEC|Symbol=%s|VolumeMin=%s|VolumeMax=%s|VolumeStep=%s|ContractSize=%.4f|TickSize=%g|TickValue=%g|MarginInitial=%g|StopsLevel=%d",
               g_symbol,DoubleToString(g_volumeMin,VolumeDigits()),DoubleToString(g_volumeMax,VolumeDigits()),
               DoubleToString(g_volumeStep,VolumeDigits()),contractSize,g_tickSize,tickValue,marginInitial,g_stopsLevel);

   double scalpLoss=MinimumLotLossForDistance(entry,CoursePipsToPrice(InpScalpSLPips));
   double intradayLoss=MinimumLotLossForDistance(entry,PTToPrice(InpIntradaySLPoints));
   double swingApproxDistance=CoursePipsToPrice(InpSwingZonePips+InpSwingSLBufferPips);
   double swingLoss=MinimumLotLossForDistance(entry,swingApproxDistance);
   double marginForMinimumLot=0.0;
   bool marginEstimateReady=(entry>0.0 && OrderCalcMargin(ORDER_TYPE_BUY,g_symbol,g_volumeMin,entry,marginForMinimumLot) && marginForMinimumLot>0.0);
   if(!marginEstimateReady)
   {
      marginForMinimumLot=0.0;
      PrintFormat("MIN_CAPITAL_DIAGNOSTIC|OrderCalcMargin在初始化阶段无可用估算|Entry=%g|Error=%d",entry,GetLastError());
   }
   string marginEstimateText=(marginEstimateReady ? DoubleToString(marginForMinimumLot,2) : "N/A（初始化报价未就绪）");
   PrintFormat("MIN_CAPITAL_TECHNICAL_ONLY|MinLot=%s|MarginEstimate=%s|ScalpMinLotLoss=%.2f EquityAtRisk%.3f%%=%.2f|IntradayMinLotLoss=%.2f EquityAtRisk%.3f%%=%.2f|SwingApproxMinLotLoss=%.2f EquityAtRisk%.3f%%=%.2f",
               DoubleToString(g_volumeMin,VolumeDigits()),marginEstimateText,
               scalpLoss,InpScalpRiskPercent,TechnicalMinimumEquity(scalpLoss,InpScalpRiskPercent),
               intradayLoss,InpIntradayRiskPercent,TechnicalMinimumEquity(intradayLoss,InpIntradayRiskPercent),
               swingLoss,InpSwingRiskPercent,TechnicalMinimumEquity(swingLoss,InpSwingRiskPercent));
   Print("提示：以上最低资金只是按当前最小手数、配置SL和风险百分比计算的技术门槛，不代表安全实盘资金，也不构成盈利保证。");
}

bool WeightsEqual100(double total)
{
   return (MathAbs(total - 100.0) <= 0.0001);
}

void LoadIndicatorConfig(StrategyId strategy,IndicatorConfig &cfg)
{
   if(strategy==STRATEGY_SCALPING)
   {
      cfg.useEMA=InpScalpUseEMAFilter;
      cfg.useRSI=InpScalpUseRSIFilter;
      cfg.emaTF=InpScalpEMATF;
      cfg.rsiTF=InpScalpRSITF;
      cfg.emaFast=InpScalpEMAFast;
      cfg.emaSlow=InpScalpEMASlow;
      cfg.requirePriceSide=InpScalpRequirePriceEMA;
      cfg.rsiPeriod=InpScalpRSIPeriod;
      cfg.rsiLongMin=InpScalpRSILongMin;
      cfg.rsiLongMax=InpScalpRSILongMax;
      cfg.rsiShortMin=InpScalpRSIShortMin;
      cfg.rsiShortMax=InpScalpRSIShortMax;
      cfg.requireRSITurn=InpScalpRequireRSITurn;
      return;
   }
   if(strategy==STRATEGY_INTRADAY)
   {
      cfg.useEMA=InpIntradayUseEMAFilter;
      cfg.useRSI=InpIntradayUseRSIFilter;
      cfg.emaTF=InpIntradayEMATF;
      cfg.rsiTF=InpIntradayRSITF;
      cfg.emaFast=InpIntradayEMAFast;
      cfg.emaSlow=InpIntradayEMASlow;
      cfg.requirePriceSide=InpIntradayRequirePriceEMA;
      cfg.rsiPeriod=InpIntradayRSIPeriod;
      cfg.rsiLongMin=InpIntradayRSILongMin;
      cfg.rsiLongMax=InpIntradayRSILongMax;
      cfg.rsiShortMin=InpIntradayRSIShortMin;
      cfg.rsiShortMax=InpIntradayRSIShortMax;
      cfg.requireRSITurn=InpIntradayRequireRSITurn;
      return;
   }
   cfg.useEMA=InpSwingUseEMAFilter;
   cfg.useRSI=InpSwingUseRSIFilter;
   cfg.emaTF=InpSwingEMATF;
   cfg.rsiTF=InpSwingRSITF;
   cfg.emaFast=InpSwingEMAFast;
   cfg.emaSlow=InpSwingEMASlow;
   cfg.requirePriceSide=InpSwingRequirePriceEMA;
   cfg.rsiPeriod=InpSwingRSIPeriod;
   cfg.rsiLongMin=InpSwingRSILongMin;
   cfg.rsiLongMax=InpSwingRSILongMax;
   cfg.rsiShortMin=InpSwingRSIShortMin;
   cfg.rsiShortMax=InpSwingRSIShortMax;
   cfg.requireRSITurn=InpSwingRequireRSITurn;
}

ConfidenceMode StrategyConfidenceMode(StrategyId strategy)
{
   if(strategy==STRATEGY_SCALPING) return InpScalpConfidenceMode;
   if(strategy==STRATEGY_INTRADAY) return InpIntradayConfidenceMode;
   return InpSwingConfidenceMode;
}

bool LegacyScoreFilterEnabled(StrategyId strategy)
{
   if(strategy==STRATEGY_SCALPING) return InpScalpUseScoreFilter;
   if(strategy==STRATEGY_INTRADAY) return InpIntradayUseScoreFilter;
   return InpSwingUseScoreFilter;
}

bool ConfidenceFilterEnabled(StrategyId strategy)
{
   return (StrategyConfidenceMode(strategy)==CONFIDENCE_FILTER || LegacyScoreFilterEnabled(strategy));
}

double StrategyMinimumConfidence(StrategyId strategy)
{
   if(strategy==STRATEGY_SCALPING) return InpScalpMinConfidence;
   if(strategy==STRATEGY_INTRADAY) return InpIntradayMinConfidence;
   return InpSwingMinConfidence;
}

MACDMode StrategyMACDMode(StrategyId strategy)
{
   if(strategy==STRATEGY_INTRADAY)
   {
      if(InpIntradayMACDMode==MACD_MODE_SCORE && !InpIntradayUseMACDScore)
         return MACD_MODE_OBSERVE;
      return InpIntradayMACDMode;
   }
   if(strategy==STRATEGY_SWING) return InpSwingMACDMode;
   return MACD_MODE_OFF;
}

BollingerMode StrategyBollingerMode(StrategyId strategy)
{
   if(strategy==STRATEGY_SCALPING) return InpScalpBollingerMode;
   if(strategy==STRATEGY_INTRADAY) return InpIntradayBollingerMode;
   return InpSwingBollingerMode;
}

void LoadBollingerConfig(StrategyId strategy,ENUM_TIMEFRAMES &tf,int &period,double &deviation)
{
   if(strategy==STRATEGY_SCALPING)
   {
      tf=InpScalpBollingerTF;
      period=InpScalpBollingerPeriod;
      deviation=InpScalpBollingerDeviation;
      return;
   }
   if(strategy==STRATEGY_INTRADAY)
   {
      tf=InpIntradayBollingerTF;
      period=InpIntradayBollingerPeriod;
      deviation=InpIntradayBollingerDeviation;
      return;
   }
   tf=InpSwingBollingerTF;
   period=InpSwingBollingerPeriod;
   deviation=InpSwingBollingerDeviation;
}

double StrategyBollingerWeight(StrategyId strategy)
{
   if(strategy==STRATEGY_SCALPING) return InpScalpWeightBollinger;
   if(strategy==STRATEGY_INTRADAY) return InpIntradayWeightBollinger;
   return InpSwingWeightBollinger;
}

bool ConfidenceAllowsEntry(StrategyId strategy,double score)
{
   return (!ConfidenceFilterEnabled(strategy) || score>=StrategyMinimumConfidence(strategy));
}

bool InitializeIndicatorHandles()
{
   g_scalpStochasticHandle=INVALID_HANDLE;
   g_scalpRegimeFastHandle=INVALID_HANDLE;
   g_scalpRegimeSlowHandle=INVALID_HANDLE;
   for(int index=0;index<3;index++)
   {
      g_emaFastHandle[index]=INVALID_HANDLE;
      g_emaSlowHandle[index]=INVALID_HANDLE;
      g_rsiHandle[index]=INVALID_HANDLE;
      g_macdHandle[index]=INVALID_HANDLE;
      g_bollingerHandle[index]=INVALID_HANDLE;
   }
   for(int s=0;s<3;s++)
   {
      g_emaFastHandle[s]=INVALID_HANDLE;
      g_emaSlowHandle[s]=INVALID_HANDLE;
      g_rsiHandle[s]=INVALID_HANDLE;
      g_macdHandle[s]=INVALID_HANDLE;
      g_bollingerHandle[s]=INVALID_HANDLE;
      IndicatorConfig cfg;
      LoadIndicatorConfig((StrategyId)s,cfg);
      bool needScoreIndicators=(StrategyConfidenceMode((StrategyId)s)!=CONFIDENCE_OFF || LegacyScoreFilterEnabled((StrategyId)s));
      if(cfg.useEMA || needScoreIndicators)
      {
         g_emaFastHandle[s]=iMA(g_symbol,cfg.emaTF,cfg.emaFast,0,MODE_EMA,PRICE_CLOSE);
         g_emaSlowHandle[s]=iMA(g_symbol,cfg.emaTF,cfg.emaSlow,0,MODE_EMA,PRICE_CLOSE);
         if(g_emaFastHandle[s]==INVALID_HANDLE || g_emaSlowHandle[s]==INVALID_HANDLE)
         {
            PrintFormat("%s EMA句柄创建失败。TF=%s Fast=%d Slow=%d Error=%d",
                        g_runtime[s].name,EnumToString(cfg.emaTF),cfg.emaFast,cfg.emaSlow,GetLastError());
            ReleaseIndicatorHandles();
            return false;
         }
      }
      if(cfg.useRSI || needScoreIndicators)
      {
         g_rsiHandle[s]=iRSI(g_symbol,cfg.rsiTF,cfg.rsiPeriod,PRICE_CLOSE);
         if(g_rsiHandle[s]==INVALID_HANDLE)
         {
            PrintFormat("%s RSI句柄创建失败。TF=%s Period=%d Error=%d",
                        g_runtime[s].name,EnumToString(cfg.rsiTF),cfg.rsiPeriod,GetLastError());
            ReleaseIndicatorHandles();
            return false;
         }
      }
      if(s>0 && StrategyMACDMode((StrategyId)s)!=MACD_MODE_OFF)
      {
         ENUM_TIMEFRAMES tf=(s==(int)STRATEGY_INTRADAY ? InpIntradayMACDTF : InpSwingMACDTF);
         int fast=(s==(int)STRATEGY_INTRADAY ? InpIntradayMACDFast : InpSwingMACDFast);
         int slow=(s==(int)STRATEGY_INTRADAY ? InpIntradayMACDSlow : InpSwingMACDSlow);
         int signal=(s==(int)STRATEGY_INTRADAY ? InpIntradayMACDSignal : InpSwingMACDSignal);
         g_macdHandle[s]=iMACD(g_symbol,tf,fast,slow,signal,PRICE_CLOSE);
         if(g_macdHandle[s]==INVALID_HANDLE)
         {
            PrintFormat("%s MACD句柄创建失败。TF=%s Fast=%d Slow=%d Signal=%d Error=%d",
                        g_runtime[s].name,EnumToString(tf),fast,slow,signal,GetLastError());
            ReleaseIndicatorHandles();
            return false;
         }
      }
      if(StrategyBollingerMode((StrategyId)s)!=BOLLINGER_MODE_OFF)
      {
         ENUM_TIMEFRAMES bbTF=PERIOD_CURRENT;
         int bbPeriod=20;
         double bbDeviation=2.0;
         LoadBollingerConfig((StrategyId)s,bbTF,bbPeriod,bbDeviation);
         g_bollingerHandle[s]=iBands(g_symbol,bbTF,bbPeriod,0,bbDeviation,PRICE_CLOSE);
         if(g_bollingerHandle[s]==INVALID_HANDLE)
         {
            PrintFormat("%s Bollinger句柄创建失败。TF=%s Period=%d Deviation=%.2f Error=%d",
                        g_runtime[s].name,EnumToString(bbTF),bbPeriod,bbDeviation,GetLastError());
            ReleaseIndicatorHandles();
            return false;
         }
      }
   }
   if(g_strategyEnabled[(int)STRATEGY_SCALPING] && InpScalpUseStochasticFilter)
   {
      g_scalpStochasticHandle=iStochastic(g_symbol,InpScalpStochasticTF,
                                          InpScalpStochasticKPeriod,InpScalpStochasticDPeriod,
                                          InpScalpStochasticSlowing,MODE_SMA,STO_LOWHIGH);
      if(g_scalpStochasticHandle==INVALID_HANDLE)
      {
         PrintFormat("Scalping Stochastic句柄创建失败。TF=%s K/D/Slowing=%d/%d/%d Error=%d",
                     EnumToString(InpScalpStochasticTF),InpScalpStochasticKPeriod,
                     InpScalpStochasticDPeriod,InpScalpStochasticSlowing,GetLastError());
         ReleaseIndicatorHandles();
         return false;
      }
   }
   if(g_strategyEnabled[(int)STRATEGY_SCALPING] && InpScalpUseHTFRegimeFilter)
   {
      g_scalpRegimeFastHandle=iMA(g_symbol,InpScalpRegimeTF,InpScalpRegimeEMAFast,0,MODE_EMA,PRICE_CLOSE);
      g_scalpRegimeSlowHandle=iMA(g_symbol,InpScalpRegimeTF,InpScalpRegimeEMASlow,0,MODE_EMA,PRICE_CLOSE);
      if(g_scalpRegimeFastHandle==INVALID_HANDLE || g_scalpRegimeSlowHandle==INVALID_HANDLE)
      {
         PrintFormat("Scalping HTF Regime句柄创建失败。TF=%s Fast=%d Slow=%d Error=%d",
                     EnumToString(InpScalpRegimeTF),InpScalpRegimeEMAFast,InpScalpRegimeEMASlow,GetLastError());
         ReleaseIndicatorHandles();
         return false;
      }
   }
   return true;
}

void ReleaseIndicatorHandles()
{
   if(g_scalpStochasticHandle!=INVALID_HANDLE)
      IndicatorRelease(g_scalpStochasticHandle);
   g_scalpStochasticHandle=INVALID_HANDLE;
   if(g_scalpRegimeFastHandle!=INVALID_HANDLE)
      IndicatorRelease(g_scalpRegimeFastHandle);
   if(g_scalpRegimeSlowHandle!=INVALID_HANDLE)
      IndicatorRelease(g_scalpRegimeSlowHandle);
   g_scalpRegimeFastHandle=INVALID_HANDLE;
   g_scalpRegimeSlowHandle=INVALID_HANDLE;
   for(int s=0;s<3;s++)
   {
      if(g_emaFastHandle[s]!=INVALID_HANDLE) IndicatorRelease(g_emaFastHandle[s]);
      if(g_emaSlowHandle[s]!=INVALID_HANDLE) IndicatorRelease(g_emaSlowHandle[s]);
      if(g_rsiHandle[s]!=INVALID_HANDLE) IndicatorRelease(g_rsiHandle[s]);
      if(g_macdHandle[s]!=INVALID_HANDLE) IndicatorRelease(g_macdHandle[s]);
      if(g_bollingerHandle[s]!=INVALID_HANDLE) IndicatorRelease(g_bollingerHandle[s]);
      g_emaFastHandle[s]=INVALID_HANDLE;
      g_emaSlowHandle[s]=INVALID_HANDLE;
      g_rsiHandle[s]=INVALID_HANDLE;
      g_macdHandle[s]=INVALID_HANDLE;
      g_bollingerHandle[s]=INVALID_HANDLE;
   }
}

bool PassScalpStochastic(int direction,string &reason)
{
   reason="";
   g_scalpStochasticK=0.0;
   g_scalpStochasticD=0.0;
   g_scalpStochasticPreviousK=0.0;
   g_scalpStochasticPreviousD=0.0;
   if(!InpScalpUseStochasticFilter)
      return true;

   double kNow[1],dNow[1],kPrevious[1],dPrevious[1];
   if(g_scalpStochasticHandle==INVALID_HANDLE ||
      CopyBuffer(g_scalpStochasticHandle,0,1,1,kNow)!=1 ||
      CopyBuffer(g_scalpStochasticHandle,1,1,1,dNow)!=1 ||
      CopyBuffer(g_scalpStochasticHandle,0,2,1,kPrevious)!=1 ||
      CopyBuffer(g_scalpStochasticHandle,1,2,1,dPrevious)!=1)
   {
      reason="Scalping Stochastic闭合K线数据尚未准备完成";
      return false;
   }

   g_scalpStochasticK=kNow[0];
   g_scalpStochasticD=dNow[0];
   g_scalpStochasticPreviousK=kPrevious[0];
   g_scalpStochasticPreviousD=dPrevious[0];

   bool levelPassed=(direction>0
                     ? kNow[0]>=InpScalpStochasticLongMin && kNow[0]<=InpScalpStochasticLongMax
                     : kNow[0]>=InpScalpStochasticShortMin && kNow[0]<=InpScalpStochasticShortMax);
   bool turnPassed=(!InpScalpStochasticRequireTurn ||
                    (direction>0 ? kNow[0]>kPrevious[0] : kNow[0]<kPrevious[0]));
   bool crossPassed=(!InpScalpStochasticRequireCross ||
                     (direction>0 ? kPrevious[0]<=dPrevious[0] && kNow[0]>dNow[0]
                                  : kPrevious[0]>=dPrevious[0] && kNow[0]<dNow[0]));
   if(levelPassed && turnPassed && crossPassed)
      return true;

   reason=StringFormat("Scalping Stochastic拒绝：K=%.1f D=%.1f PrevK=%.1f PrevD=%.1f Long[%.1f,%.1f] Short[%.1f,%.1f] Turn=%s Cross=%s",
                       kNow[0],dNow[0],kPrevious[0],dPrevious[0],
                       InpScalpStochasticLongMin,InpScalpStochasticLongMax,
                       InpScalpStochasticShortMin,InpScalpStochasticShortMax,
                       (InpScalpStochasticRequireTurn?"ON":"OFF"),(InpScalpStochasticRequireCross?"ON":"OFF"));
   return false;
}

bool PassScalpHTFRegime(int direction,string &reason)
{
   reason="";
   if(!InpScalpUseHTFRegimeFilter)
      return true;
   if(direction>0 && InpScalpRegimeLongAlwaysAllowed)
      return true;

   double fast[1],slow[1];
   if(g_scalpRegimeFastHandle==INVALID_HANDLE || g_scalpRegimeSlowHandle==INVALID_HANDLE ||
      CopyBuffer(g_scalpRegimeFastHandle,0,1,1,fast)!=1 ||
      CopyBuffer(g_scalpRegimeSlowHandle,0,1,1,slow)!=1)
   {
      reason="Scalping HTF Regime闭合K线数据尚未准备完成";
      return false;
   }

   bool passed=(direction>0 ? fast[0]>slow[0] : fast[0]<slow[0]);
   if(!passed)
      reason=StringFormat("Scalping HTF Regime拒绝：TF=%s Direction=%s EMA%d=%.2f EMA%d=%.2f",
                          EnumToString(InpScalpRegimeTF),(direction>0?"BUY":"SELL"),
                          InpScalpRegimeEMAFast,fast[0],InpScalpRegimeEMASlow,slow[0]);
   return passed;
}

bool ReadIndicatorBufferValue(int handle,int shift,double &value)
{
   double buffer[1];
   if(handle==INVALID_HANDLE || CopyBuffer(handle,0,shift,1,buffer)!=1)
      return false;
   value=buffer[0];
   return MathIsValidNumber(value);
}

bool StrategyIndicatorFiltersEnabled(StrategyId strategy)
{
   IndicatorConfig cfg;
   LoadIndicatorConfig(strategy,cfg);
   return (cfg.useEMA || cfg.useRSI);
}

void ResetIndicatorSnapshot(IndicatorSnapshot &snapshot)
{
   snapshot.ready=false;
   snapshot.emaFast=0.0;
   snapshot.emaSlow=0.0;
   snapshot.emaFastPrevious=0.0;
   snapshot.emaSlowPrevious=0.0;
   snapshot.closeValue=0.0;
   snapshot.atr=0.0;
   snapshot.rsi=0.0;
   snapshot.rsiPrevious=0.0;
   snapshot.emaStrength=0.0;
   snapshot.rsiStrength=0.0;
   snapshot.combinedStrength=0.0;
}

void ResetMACDSnapshot(MACDSnapshot &snapshot)
{
   snapshot.ready=false;
   snapshot.mainValue=0.0;
   snapshot.signalValue=0.0;
   snapshot.histogram=0.0;
   snapshot.previousMain=0.0;
   snapshot.previousSignal=0.0;
   snapshot.previousHistogram=0.0;
   snapshot.quality=0.0;
   snapshot.directionPassed=false;
   snapshot.state="MACD OFF";
}

void ResetBollingerSnapshot(BollingerSnapshot &snapshot)
{
   snapshot.ready=false;
   snapshot.upper=0.0;
   snapshot.middle=0.0;
   snapshot.lower=0.0;
   snapshot.percentB=0.0;
   snapshot.bandWidth=0.0;
   snapshot.previousPercentB=0.0;
   snapshot.previousBandWidth=0.0;
   snapshot.bandWidthChange=0.0;
   snapshot.quality=0.0;
   snapshot.directionPassed=false;
   snapshot.state="BOLLINGER OFF";
}

double IndicatorMomentumStrength(IndicatorSnapshot &snapshot,int direction)
{
   if(!snapshot.ready)
      return 0.0;
   double scale=MathMax(g_tickSize,MathAbs(snapshot.closeValue)*0.0025);
   double directionalGap=(direction>0 ? snapshot.emaFast-snapshot.emaSlow : snapshot.emaSlow-snapshot.emaFast);
   double directionalSlope=(direction>0 ? snapshot.emaFast-snapshot.emaFastPrevious : snapshot.emaFastPrevious-snapshot.emaFast);
   double distanceFactor=Clamp01(directionalGap/scale);
   double slopeFactor=Clamp01(directionalSlope/MathMax(g_tickSize,scale*0.20));
   snapshot.emaStrength=0.65*distanceFactor+0.35*slopeFactor;

   double directionalRSITurn=(direction>0 ? snapshot.rsi-snapshot.rsiPrevious : snapshot.rsiPrevious-snapshot.rsi);
   double rsiTurnFactor=Clamp01(0.5+directionalRSITurn/8.0);
   double rsiLocation=(direction>0 ? Clamp01((snapshot.rsi-35.0)/30.0) : Clamp01((65.0-snapshot.rsi)/30.0));
   snapshot.rsiStrength=0.60*rsiTurnFactor+0.40*rsiLocation;
   snapshot.combinedStrength=0.55*snapshot.emaStrength+0.45*snapshot.rsiStrength;
   return snapshot.combinedStrength;
}

bool EvaluateStrategyMACD(StrategyId strategy,int direction,string &reason)
{
   int s=(int)strategy;
   ResetMACDSnapshot(g_macdSnapshot[s]);
   reason="";
   MACDMode mode=StrategyMACDMode(strategy);
   if(mode==MACD_MODE_OFF)
   {
      g_runtime[s].macdState="MACD OFF";
      return true;
   }
   bool dataWaitBlocks=(mode==MACD_MODE_HARD ||
                        (mode==MACD_MODE_SCORE && ConfidenceFilterEnabled(strategy)));
   double mainNow=0.0,signalNow=0.0,mainPrevious=0.0,signalPrevious=0.0;
   double mainBuffer[1],signalBuffer[1];
   if(CopyBuffer(g_macdHandle[s],0,1,1,mainBuffer)!=1 || CopyBuffer(g_macdHandle[s],1,1,1,signalBuffer)!=1)
   {
      reason=(dataWaitBlocks ? "MACD数据尚未准备完成" : "MACD数据尚未准备完成（观察/评分模式仅记录，不阻止核心SOP）");
      g_runtime[s].macdState="MACD DATA WAIT";
      g_funnel[s].macdDataWaits++;
      PrintFormat("INDICATOR_DATA_WAIT|SOP=%s|Indicator=MACD|Mode=%d|Blocking=%s|ClosedShift=1",
                  g_runtime[s].name,(int)mode,(dataWaitBlocks?"YES":"NO"));
      return !dataWaitBlocks;
   }
   mainNow=mainBuffer[0];
   signalNow=signalBuffer[0];
   double mainBufferPrevious[1],signalBufferPrevious[1];
   if(CopyBuffer(g_macdHandle[s],0,2,1,mainBufferPrevious)!=1 ||
      CopyBuffer(g_macdHandle[s],1,2,1,signalBufferPrevious)!=1)
   {
      reason=(dataWaitBlocks ? "MACD前一根收盘数据尚未准备完成" : "MACD前一根收盘数据尚未准备完成（观察/评分模式仅记录，不阻止核心SOP）");
      g_runtime[s].macdState="MACD DATA WAIT";
      g_funnel[s].macdDataWaits++;
      PrintFormat("INDICATOR_DATA_WAIT|SOP=%s|Indicator=MACD|Mode=%d|Blocking=%s|ClosedShift=2",
                  g_runtime[s].name,(int)mode,(dataWaitBlocks?"YES":"NO"));
      return !dataWaitBlocks;
   }
   mainPrevious=mainBufferPrevious[0];
   signalPrevious=signalBufferPrevious[0];
   double histogram=mainNow-signalNow;
   double previousHistogram=mainPrevious-signalPrevious;
   double directionalHistogram=(direction>0 ? histogram : -histogram);
   double directionalPrevious=(direction>0 ? previousHistogram : -previousHistogram);
   bool lineAligned=(direction>0 ? mainNow>signalNow : mainNow<signalNow);
   bool expanding=(directionalHistogram>directionalPrevious);
   bool zeroAligned=(direction>0 ? mainNow>0.0 : mainNow<0.0);
   double quality=0.0;
   if(lineAligned) quality+=0.45;
   if(directionalHistogram>0.0) quality+=0.25;
   if(expanding) quality+=0.20;
   if(zeroAligned) quality+=0.10;
   g_macdSnapshot[s].ready=true;
   g_macdSnapshot[s].mainValue=mainNow;
   g_macdSnapshot[s].signalValue=signalNow;
   g_macdSnapshot[s].histogram=histogram;
   g_macdSnapshot[s].previousMain=mainPrevious;
   g_macdSnapshot[s].previousSignal=signalPrevious;
   g_macdSnapshot[s].previousHistogram=previousHistogram;
   g_macdSnapshot[s].quality=Clamp01(quality);
   g_macdSnapshot[s].directionPassed=(lineAligned && directionalHistogram>0.0);
   g_macdSnapshot[s].state=StringFormat("MACD %s Main=%.5f Signal=%.5f Hist=%.5f %s",
                                       (g_macdSnapshot[s].directionPassed?"PASS":"WEAK"),mainNow,signalNow,histogram,
                                       (expanding?"扩大":"缩小"));
   g_runtime[s].macdState=g_macdSnapshot[s].state;
   g_funnel[s].macdEvaluated++;
   if(g_macdSnapshot[s].directionPassed) g_funnel[s].macdPassed++;
   if(mode==MACD_MODE_HARD && !g_macdSnapshot[s].directionPassed)
   {
      g_funnel[s].macdRejected++;
      reason="MACD HARD未通过："+g_runtime[s].macdState;
      return false;
   }
   return true;
}

bool EvaluateStrategyBollinger(StrategyId strategy,int direction,string &reason)
{
   int s=(int)strategy;
   ResetBollingerSnapshot(g_bollingerSnapshot[s]);
   reason="";
   BollingerMode mode=StrategyBollingerMode(strategy);
   if(mode==BOLLINGER_MODE_OFF)
   {
      g_runtime[s].bollingerState="BOLLINGER OFF";
      return true;
   }
   bool dataWaitBlocks=(mode==BOLLINGER_MODE_HARD ||
                        (mode==BOLLINGER_MODE_SCORE && ConfidenceFilterEnabled(strategy)));
   double middleNow[1],upperNow[1],lowerNow[1],middlePrevious[1],upperPrevious[1],lowerPrevious[1];
   if(CopyBuffer(g_bollingerHandle[s],0,1,1,middleNow)!=1 ||
      CopyBuffer(g_bollingerHandle[s],1,1,1,upperNow)!=1 ||
      CopyBuffer(g_bollingerHandle[s],2,1,1,lowerNow)!=1 ||
      CopyBuffer(g_bollingerHandle[s],0,2,1,middlePrevious)!=1 ||
      CopyBuffer(g_bollingerHandle[s],1,2,1,upperPrevious)!=1 ||
      CopyBuffer(g_bollingerHandle[s],2,2,1,lowerPrevious)!=1)
   {
      reason=(dataWaitBlocks ? "Bollinger已收盘数据尚未准备完成" : "Bollinger数据等待（观察/评分模式不阻止核心SOP）");
      g_runtime[s].bollingerState="BOLLINGER DATA WAIT";
      g_funnel[s].bollingerDataWaits++;
      PrintFormat("INDICATOR_DATA_WAIT|SOP=%s|Indicator=Bollinger|Mode=%d|Blocking=%s|ClosedShifts=1,2",
                  g_runtime[s].name,(int)mode,(dataWaitBlocks?"YES":"NO"));
      return !dataWaitBlocks;
   }
   ENUM_TIMEFRAMES tf=PERIOD_CURRENT;
   int period=20;
   double deviation=2.0;
   LoadBollingerConfig(strategy,tf,period,deviation);
   double closeNow=iClose(g_symbol,tf,1);
   double closePrevious=iClose(g_symbol,tf,2);
   double width=upperNow[0]-lowerNow[0];
   double previousWidth=upperPrevious[0]-lowerPrevious[0];
   if(closeNow<=0.0 || closePrevious<=0.0 || width<=g_tickSize || previousWidth<=g_tickSize)
   {
      reason=(dataWaitBlocks ? "Bollinger价格或通道宽度无效" : "Bollinger价格/宽度无效（不阻止核心SOP）");
      g_runtime[s].bollingerState="BOLLINGER INVALID";
      g_funnel[s].bollingerDataWaits++;
      return !dataWaitBlocks;
   }
   double percentB=(closeNow-lowerNow[0])/width;
   double previousPercentB=(closePrevious-lowerPrevious[0])/previousWidth;
   double widthChange=(width-previousWidth)/previousWidth;
   bool expanding=(widthChange>0.02);
   bool reentered=(direction>0 ? previousPercentB<=0.05 && percentB>previousPercentB && percentB>0.05
                              : previousPercentB>=0.95 && percentB<previousPercentB && percentB<0.95);
   bool middleAligned=(direction>0 ? closeNow>=middleNow[0] : closeNow<=middleNow[0]);
   bool tooLate=(direction>0 ? percentB>0.90 && !expanding : percentB<0.10 && !expanding);
   bool passed=false;
   if(strategy==STRATEGY_SCALPING)
      passed=(reentered || (!tooLate && expanding && percentB>=0.05 && percentB<=0.95));
   else if(strategy==STRATEGY_INTRADAY)
      passed=(reentered || (middleAligned && expanding && !tooLate));
   else
      passed=!tooLate;

   double ideal=(direction>0 ? 0.25 : 0.75);
   double locationQuality=Clamp01(1.0-MathAbs(percentB-ideal)/0.90);
   double expansionQuality=Clamp01(0.50+widthChange/0.20);
   double quality=Clamp01(0.45*locationQuality+0.30*expansionQuality+0.25*(reentered?1.0:(middleAligned?0.65:0.25)));
   if(tooLate) quality*=0.35;

   g_bollingerSnapshot[s].ready=true;
   g_bollingerSnapshot[s].upper=upperNow[0];
   g_bollingerSnapshot[s].middle=middleNow[0];
   g_bollingerSnapshot[s].lower=lowerNow[0];
   g_bollingerSnapshot[s].percentB=percentB;
   g_bollingerSnapshot[s].bandWidth=width;
   g_bollingerSnapshot[s].previousPercentB=previousPercentB;
   g_bollingerSnapshot[s].previousBandWidth=previousWidth;
   g_bollingerSnapshot[s].bandWidthChange=widthChange;
   g_bollingerSnapshot[s].quality=quality;
   g_bollingerSnapshot[s].directionPassed=passed;
   g_bollingerSnapshot[s].state=StringFormat("BB %s %%B=%.3f Width=%.5f Change=%.3f %s%s",
                                             (passed?"PASS":"WEAK"),percentB,width,widthChange,
                                             (expanding?"EXPAND":"CONTRACT"),(tooLate?" ENTRY_TOO_LATE":""));
   g_runtime[s].bollingerState=g_bollingerSnapshot[s].state;
   g_funnel[s].bollingerEvaluated++;
   if(passed) g_funnel[s].bollingerPassed++;
   if(mode==BOLLINGER_MODE_HARD && !passed)
   {
      g_funnel[s].bollingerRejected++;
      reason="Bollinger HARD未通过："+g_runtime[s].bollingerState;
      return false;
   }
   return true;
}

bool PassStrategyEMAAndRSI(StrategyId strategy,int direction,string &reason)
{
   int s=(int)strategy;
   IndicatorConfig cfg;
   LoadIndicatorConfig(strategy,cfg);
   reason="";
   ResetIndicatorSnapshot(g_indicatorSnapshot[s]);
   bool needScore=(StrategyConfidenceMode(strategy)!=CONFIDENCE_OFF || LegacyScoreFilterEnabled(strategy));
   bool confidenceDataRequired=ConfidenceFilterEnabled(strategy);
   if(!cfg.useEMA && !cfg.useRSI && !needScore)
   {
      g_runtime[s].indicatorState="EMA OFF / RSI OFF";
      return true;
   }

   bool emaPassed=true;
   bool rsiPassed=true;
   bool emaDataReady=true;
   bool rsiDataReady=true;
   double fast=0.0,slow=0.0,fastPrevious=0.0,slowPrevious=0.0,closeValue=0.0,rsi=0.0,previousRSI=0.0;
   if(cfg.useEMA || needScore)
   {
      double closeBuffer[1];
      if(!ReadIndicatorBufferValue(g_emaFastHandle[s],1,fast) ||
          !ReadIndicatorBufferValue(g_emaSlowHandle[s],1,slow) ||
          !ReadIndicatorBufferValue(g_emaFastHandle[s],2,fastPrevious) ||
          !ReadIndicatorBufferValue(g_emaSlowHandle[s],2,slowPrevious) ||
         CopyClose(g_symbol,cfg.emaTF,1,1,closeBuffer)!=1)
      {
         emaDataReady=false;
         bool blocking=(cfg.useEMA || confidenceDataRequired);
         reason=(blocking ? "EMA数据尚未准备完成" : "EMA数据尚未准备完成（SCORE_ONLY仅记录，不阻止核心SOP）");
         g_runtime[s].indicatorState="EMA DATA WAIT";
         g_funnel[s].indicatorDataWaits++;
         PrintFormat("INDICATOR_DATA_WAIT|SOP=%s|Indicator=EMA|ConfidenceMode=%d|HardFilter=%s|Blocking=%s|ClosedShift=1/2",
                     g_runtime[s].name,(int)StrategyConfidenceMode(strategy),(cfg.useEMA?"YES":"NO"),(blocking?"YES":"NO"));
         if(blocking)
            return false;
      }
      if(emaDataReady)
      {
         closeValue=closeBuffer[0];
         bool directional=(direction>0 ? fast>slow : fast<slow);
         bool priceSide=(direction>0 ? closeValue>slow : closeValue<slow);
         emaPassed=(directional && (!cfg.requirePriceSide || priceSide));
      }
   }

   if(cfg.useRSI || needScore)
   {
      if(!ReadIndicatorBufferValue(g_rsiHandle[s],1,rsi) ||
         !ReadIndicatorBufferValue(g_rsiHandle[s],2,previousRSI))
      {
         rsiDataReady=false;
         bool blocking=(cfg.useRSI || confidenceDataRequired);
         reason=(blocking ? "RSI数据尚未准备完成" : "RSI数据尚未准备完成（SCORE_ONLY仅记录，不阻止核心SOP）");
         g_runtime[s].indicatorState=(emaDataReady ? "RSI DATA WAIT" : "EMA/RSI DATA WAIT");
         g_funnel[s].indicatorDataWaits++;
         PrintFormat("INDICATOR_DATA_WAIT|SOP=%s|Indicator=RSI|ConfidenceMode=%d|HardFilter=%s|Blocking=%s|ClosedShift=1/2",
                     g_runtime[s].name,(int)StrategyConfidenceMode(strategy),(cfg.useRSI?"YES":"NO"),(blocking?"YES":"NO"));
         if(blocking)
            return false;
      }
      if(rsiDataReady)
      {
         if(direction>0)
            rsiPassed=(rsi>=cfg.rsiLongMin && rsi<=cfg.rsiLongMax &&
                       (!cfg.requireRSITurn || rsi>previousRSI));
         else
            rsiPassed=(rsi>=cfg.rsiShortMin && rsi<=cfg.rsiShortMax &&
                       (!cfg.requireRSITurn || rsi<previousRSI));
      }
   }

   g_indicatorSnapshot[s].ready=(emaDataReady && rsiDataReady);
   g_indicatorSnapshot[s].emaFast=fast;
   g_indicatorSnapshot[s].emaSlow=slow;
   g_indicatorSnapshot[s].emaFastPrevious=fastPrevious;
   g_indicatorSnapshot[s].emaSlowPrevious=slowPrevious;
   g_indicatorSnapshot[s].closeValue=closeValue;
   g_indicatorSnapshot[s].rsi=rsi;
   g_indicatorSnapshot[s].rsiPrevious=previousRSI;
   if(g_indicatorSnapshot[s].ready)
      IndicatorMomentumStrength(g_indicatorSnapshot[s],direction);

   if(g_indicatorSnapshot[s].ready)
      g_runtime[s].indicatorState=StringFormat("EMA %s %.2f/%.2f | RSI %s %.1f<%.1f",
                                               (cfg.useEMA?(emaPassed?"PASS":"FAIL"):"OFF"),fast,slow,
                                               (cfg.useRSI?(rsiPassed?"PASS":"FAIL"):"OFF"),previousRSI,rsi);
   if(cfg.useEMA && emaDataReady)
   {
      if(emaPassed) g_funnel[s].emaPassed++; else g_funnel[s].emaRejected++;
   }
   if(cfg.useRSI && rsiDataReady)
   {
      if(rsiPassed) g_funnel[s].rsiPassed++; else g_funnel[s].rsiRejected++;
   }
   if((cfg.useEMA && !emaPassed) || (cfg.useRSI && !rsiPassed))
   {
      reason=StringFormat("EMA+RSI方向过滤未通过：%s",g_runtime[s].indicatorState);
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| Expert tick                                                      |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!RefreshSymbolSpec() || !SymbolInfoTick(g_symbol, g_tick))
      return;

   UpdateCapitalLadder(false);
   UpdateTradeAuditExcursions();

   // Existing positions are always managed before checking any new-entry lock.
   ManageScalpingPosition();
   ManageIntradayPosition();
   ManageSwingPosition();
   bool newM5 = IsNewBar(PERIOD_M5, g_lastM5Bar);
   bool newM30 = IsNewBar(PERIOD_M30, g_lastM30Bar);
   bool newSwingEntry = IsNewBar(InpSwingEntryTF, g_lastSwingBar);
   bool newIntradayConfirmationBar = IsNewBar(InpIntradayConfirmationTF, g_lastIntradayConfirmationBar);

   UpdateSupplyDemandStates(newM5, newM30, newSwingEntry);
   UpdateFirstTouchStates();
   UpdateClosedBarSignals(newM5, newM30, newSwingEntry);
   UpdateRuntimeStatisticsIfNeeded();

   if(g_strategyEnabled[(int)STRATEGY_SCALPING] && newM5)
      RunScalpingM5();
   if(g_strategyEnabled[(int)STRATEGY_INTRADAY])
      MonitorIntradayM30FirstTouch(PassCommonFilters(),newIntradayConfirmationBar);
   if(g_strategyEnabled[(int)STRATEGY_SWING] && newSwingEntry)
      RunSwingD1();

   UpdateChinesePanel();
   SavePersistentStateThrottled();
}

//+------------------------------------------------------------------+
//| Symbol and filters                                               |
//+------------------------------------------------------------------+
bool RefreshSymbolSpec()
{
   g_digits     = (int)SymbolInfoInteger(g_symbol, SYMBOL_DIGITS);
   g_point      = SymbolInfoDouble(g_symbol, SYMBOL_POINT);
   g_tickSize   = SymbolInfoDouble(g_symbol, SYMBOL_TRADE_TICK_SIZE);
   g_tickValue  = SymbolInfoDouble(g_symbol, SYMBOL_TRADE_TICK_VALUE);
   g_volumeMin  = SymbolInfoDouble(g_symbol, SYMBOL_VOLUME_MIN);
   g_volumeMax  = SymbolInfoDouble(g_symbol, SYMBOL_VOLUME_MAX);
   g_volumeStep = SymbolInfoDouble(g_symbol, SYMBOL_VOLUME_STEP);
   g_stopsLevel = (int)SymbolInfoInteger(g_symbol, SYMBOL_TRADE_STOPS_LEVEL);
   g_freezeLevel= (int)SymbolInfoInteger(g_symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   g_fillingMode= SymbolInfoInteger(g_symbol, SYMBOL_FILLING_MODE);
   g_symbolTradeMode=SymbolInfoInteger(g_symbol, SYMBOL_TRADE_MODE);

   if(g_point <= 0.0 || g_volumeMin <= 0.0 || g_volumeStep <= 0.0)
      return false;
   if(g_tickSize <= 0.0)
      g_tickSize = g_point;
   g_accountAllowsTrading = (bool)AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) &&
                            (bool)MQLInfoInteger(MQL_TRADE_ALLOWED) &&
                            (bool)TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);
   return true;
}

bool PassCommonFilters()
{
   string reason;
   return PassCommonFiltersWithReason(reason);
}

bool IsBrokerTradingSessionOpen(datetime currentTime)
{
   MqlDateTime now;
   TimeToStruct(currentTime,now);
   ENUM_DAY_OF_WEEK day=(ENUM_DAY_OF_WEEK)now.day_of_week;
   int nowSeconds=now.hour*3600+now.min*60+now.sec;
   bool sessionMetadataFound=false;

   for(uint sessionIndex=0;sessionIndex<24;sessionIndex++)
   {
      datetime sessionFrom=0;
      datetime sessionTo=0;
      if(!SymbolInfoSessionTrade(g_symbol,day,sessionIndex,sessionFrom,sessionTo))
         break;
      sessionMetadataFound=true;
      MqlDateTime fromParts,toParts;
      TimeToStruct(sessionFrom,fromParts);
      TimeToStruct(sessionTo,toParts);
      int fromSeconds=fromParts.hour*3600+fromParts.min*60+fromParts.sec;
      int toSeconds=toParts.hour*3600+toParts.min*60+toParts.sec;

      if(fromSeconds==toSeconds)
         return true;
      if(fromSeconds<toSeconds && nowSeconds>=fromSeconds && nowSeconds<toSeconds)
         return true;
      if(fromSeconds>toSeconds && (nowSeconds>=fromSeconds || nowSeconds<toSeconds))
         return true;
   }

   // Some custom symbols do not publish session metadata. Keep the existing
   // permission and quote checks in that case instead of blocking all trading.
   return !sessionMetadataFound;
}

bool PassCommonFiltersWithReason(string &reason)
{
   reason = "";
   long tradeMode = SymbolInfoInteger(g_symbol, SYMBOL_TRADE_MODE);
   if(tradeMode == SYMBOL_TRADE_MODE_DISABLED)
   {
      reason = "经纪商禁止该品种交易";
      return false;
   }

   if(!g_accountAllowsTrading)
   {
      reason = "账户、终端或EA自动交易权限未开启";
      return false;
   }

   if(InpRequireHedging && !g_isHedging)
   {
      reason = "账户不是Hedging模式";
      return false;
   }

   if(InpManualNewsLock)
   {
      reason = "Manual News Lock已开启";
      return false;
   }

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(dt.day_of_week == 0 || dt.day_of_week == 6)
   {
      reason = "周末禁止新开仓";
      return false;
   }

   if(!IsBrokerTradingSessionOpen(TimeCurrent()))
   {
      reason = "经纪商品种交易Session尚未开放";
      return false;
   }

   if(g_tick.bid <= 0.0 || g_tick.ask <= 0.0 || g_tick.time <= 0 ||
      (TimeCurrent() - g_tick.time) > InpMaxQuoteAgeSeconds)
   {
      reason = "报价无效或过期";
      return false;
   }

   if(InpMaxSpreadPoints > 0)
   {
      int spread = CurrentSpreadPoints();
      if(spread > InpMaxSpreadPoints)
      {
         reason = "触发共同极端点差保护";
         return false;
      }
   }

   double marginLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   if(marginLevel > 0.0 && marginLevel < InpMinMarginLevelPct)
   {
      reason = "保证金水平低于限制";
      return false;
   }

   if(CalculateAccountOpenRiskPercent() > EffectiveTotalRiskCap())
   {
      reason = "账户已开仓总风险超过限制";
      return false;
   }

   return true;
}

bool IsTradingHourRange(int startHour, int endHour)
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   if(dt.day_of_week == 0 || dt.day_of_week == 6)
      return false;

   if(endHour >= 24)
      return (dt.hour >= startHour);

   if(startHour <= endHour)
      return (dt.hour >= startHour && dt.hour < endHour);

   return (dt.hour >= startHour || dt.hour < endHour);
}

bool IsNewBar(ENUM_TIMEFRAMES tf, datetime &lastBar)
{
   datetime t[1];
   if(CopyTime(g_symbol, tf, 0, 1, t) < 1)
      return false;

   if(t[0] != lastBar)
   {
      lastBar = t[0];
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Strategy 1: M5 Scalping                                          |
//+------------------------------------------------------------------+
void RunScalpingM5()
{
   int s = (int)STRATEGY_SCALPING;
   g_runtime[s].lastEvaluatedBar = g_lastM5Bar;
   g_runtime[s].rejectReason = "";

   Zone candidate;
   bool hasCandidate = false;
   MqlRates rates[];
   if(!LoadRates(PERIOD_M5, InpVolumeAveragePeriod + InpCandleTrendBars + InpATRPeriod + 20, rates))
      return;

   if(g_scalpDemand.valid && g_scalpDemand.state == ZONE_FIRST_TOUCH && g_scalpDemand.firstTouchBarTime == rates[1].time)
   {
      candidate = g_scalpDemand;
      hasCandidate = true;
   }
   if(g_scalpSupply.valid && g_scalpSupply.state == ZONE_FIRST_TOUCH && g_scalpSupply.firstTouchBarTime == rates[1].time)
   {
      if(!hasCandidate || DistanceToZone((g_tick.bid+g_tick.ask)*0.5, g_scalpSupply) < DistanceToZone((g_tick.bid+g_tick.ask)*0.5, candidate))
         candidate = g_scalpSupply;
      hasCandidate = true;
   }

   if(!hasCandidate)
   {
      g_runtime[s].status = "等待Fresh区域First Touch回踩K线收盘";
      return;
   }

   if(candidate.dir > 0)
      ExecuteScalpFirstTouch(g_scalpDemand, rates);
   else
      ExecuteScalpFirstTouch(g_scalpSupply, rates);
}

void ExecuteScalpFirstTouch(Zone &active, MqlRates &rates[])
{
   int s = (int)STRATEGY_SCALPING;
   active.state = ZONE_ENTRY_PENDING;
   g_runtime[s].zoneId = active.id;
   g_runtime[s].clusterId = BuildOpportunityClusterID(STRATEGY_SCALPING,active);
   g_runtime[s].zoneState = ZoneStateName(active.state);
   if(g_runtime[s].candle.candleTime != rates[1].time || g_runtime[s].candle.direction != active.dir)
      DetectCandlestickSignal(PERIOD_M5, active.dir, true, g_runtime[s].candle);
   DetectBestChartPattern(PERIOD_M5, active.dir, g_runtime[s].pattern);
   RecordDetectedSignals(STRATEGY_SCALPING);
   g_runtime[s].candleName = g_runtime[s].candle.englishName + "/" + g_runtime[s].candle.chineseName;
   g_runtime[s].candleStrength = CandleStrengthName(g_runtime[s].candle.strength);

   bool namedWhitelist = IsScalpingWhitelist(g_runtime[s].candle) && g_runtime[s].candle.direction == active.dir;
   bool whitelist = namedWhitelist || IsClearScalpWickRejection(rates[1],active.dir);
   string regimeReason="";
   bool regimePassed=(whitelist ? PassScalpHTFRegime(active.dir,regimeReason) : false);
   string indicatorReason="";
   bool indicatorPassed=(whitelist && regimePassed ? PassStrategyEMAAndRSI(STRATEGY_SCALPING,active.dir,indicatorReason) : false);
   string stochasticReason="";
   bool stochasticPassed=(whitelist && indicatorPassed ? PassScalpStochastic(active.dir,stochasticReason)
                                                        : !InpScalpUseStochasticFilter);
   string bollingerReason="";
   bool bollingerPassed=(whitelist ? EvaluateStrategyBollinger(STRATEGY_SCALPING,active.dir,bollingerReason) : true);
   if(StrategyConfidenceMode(STRATEGY_SCALPING)!=CONFIDENCE_OFF || LegacyScoreFilterEnabled(STRATEGY_SCALPING))
      ComputeScalpScore(active,g_runtime[s].candle,g_runtime[s].pattern,g_runtime[s].score);
   else
      ResetScore(g_runtime[s].score);
   g_runtime[s].confidence=g_runtime[s].score.total;
   bool scorePassed=ConfidenceAllowsEntry(STRATEGY_SCALPING,g_runtime[s].confidence);
   bool filtersPassed=false;
   string reason="";
   if(!whitelist)
      reason = "First Touch M5收盘K线不在Scalping反转白名单";
   else
   {
      g_funnel[s].hardSOPPassed++;
      if(!regimePassed)
         reason=regimeReason;
      else if(!indicatorPassed)
         reason=indicatorReason;
      else if(!stochasticPassed)
         reason=stochasticReason;
      else if(!bollingerPassed)
         reason=bollingerReason;
      else if(!scorePassed)
      {
         reason = StringFormat("Scalping置信度不足 %.1f < %.1f", g_runtime[s].confidence, InpScalpMinConfidence);
         g_funnel[s].confidenceRejected++;
      }
      else
      {
         g_funnel[s].confidencePassed++;
         filtersPassed=PassStrategyFilters(STRATEGY_SCALPING,reason);
         if(!filtersPassed)
            reason = "Scalping全局/策略门控拒绝：" + reason;
         else
            g_funnel[s].globalGatePassed++;
      }
   }

   // Consume before OrderSend: an execution failure can never retry this ZoneID.
   MarkZoneUsed(active, (reason == "" ? "First Touch已锁定并准备下单" : reason));
   g_runtime[s].zoneState = ZoneStateName(active.state);
   PrintFilterAudit(STRATEGY_SCALPING,active.dir,active.id,whitelist,(regimePassed&&indicatorPassed&&stochasticPassed),true,scorePassed,filtersPassed,(reason==""),reason);
   if(reason != "")
   {
      g_runtime[s].status = "未开仓";
      g_runtime[s].rejectReason = reason;
      PrintFormat("Scalping拒绝：ZoneID=%s %s；%s", active.id, reason, g_runtime[s].score.explanation);
      return;
   }

   double entry = (active.dir > 0 ? g_tick.ask : g_tick.bid);
   double slDistance = CoursePipsToPrice(InpScalpSLPips);
   double tpDistance = CoursePipsToPrice(InpScalpTPPips);
   double sl = (active.dir > 0 ? entry - slDistance : entry + slDistance);
   double tp = (active.dir > 0 ? entry + tpDistance : entry - tpDistance);
   string comment=BuildTradeComment(STRATEGY_SCALPING,active.dir,active.id);
   g_pendingZoneId[s]=active.id;
   g_pendingRiskPercent[s]=InpScalpRiskPercent;
   PreparePendingTradeAudit(STRATEGY_SCALPING,active,false);
   PrintFormat("Scalping准备开仓：ZoneID=%s %s；固定SL=%s 固定TP=%s",
               active.id, g_runtime[s].score.explanation,
               DoubleToString(slDistance,g_digits), DoubleToString(tpDistance,g_digits));
   PlaceStrategyTradeForZone(STRATEGY_SCALPING, active.dir, comment, entry, sl, tp, InpScalpFixedLot, InpScalpRiskPercent);
   DrawZone((active.dir > 0 ? "SCALP_DEMAND" : "SCALP_SUPPLY"), active, (active.dir > 0 ? clrDodgerBlue : clrTomato));
}

//+------------------------------------------------------------------+
//| Strategy 2: M30 Intraday - PDF Supply & Demand SOP              |
//+------------------------------------------------------------------+
void RefreshIntradayM30Zones()
{
   // Kept as a compatibility entry point; the unified state machine owns refreshes.
   UpdateSupplyDemandStates(false, true, false);
}

void MonitorIntradayM30FirstTouch(bool allowEntry,bool newConfirmationBar)
{
   bool confirmationTick=(!InpIntradayUseClosedCandleConfirmation || newConfirmationBar);
   if(!confirmationTick)
      return;
   if(g_intradayDemand.valid &&
      (g_intradayDemand.state == ZONE_FIRST_TOUCH || g_intradayDemand.state == ZONE_ENTRY_PENDING))
      ExecuteIntradayFirstTouch(g_intradayDemand, allowEntry);
   if(g_intradaySupply.valid &&
      (g_intradaySupply.state == ZONE_FIRST_TOUCH || g_intradaySupply.state == ZONE_ENTRY_PENDING))
      ExecuteIntradayFirstTouch(g_intradaySupply, allowEntry);
}

double IntradayRawTouchDepth(Zone &zone)
{
   if(zone.width<=g_tickSize || zone.firstTouchPrice<=0.0)
      return 0.0;
   double depth=(zone.dir>0 ? (zone.top-zone.firstTouchPrice)/zone.width
                            : (zone.firstTouchPrice-zone.bottom)/zone.width);
   return Clamp01(depth);
}

bool IntradayClosedCandleConfirmed(Zone &active,string &reason)
{
   reason="";
   if(!InpIntradayUseClosedCandleConfirmation)
      return true;

   int seconds=PeriodSeconds(InpIntradayConfirmationTF);
   datetime candleOpen=iTime(g_symbol,InpIntradayConfirmationTF,1);
   if(seconds<=0 || candleOpen<=0)
   {
      reason="Waiting for Intraday confirmation timeframe data";
      return false;
   }

   datetime candleClose=candleOpen+seconds;
   if(candleClose<=active.firstTouchTime)
   {
      reason="Waiting for a closed reversal candle after First Touch";
      return false;
   }

   int elapsedBars=(int)MathCeil((double)(candleClose-active.firstTouchTime)/(double)seconds);
   DetectCandlestickSignal(InpIntradayConfirmationTF,active.dir,true,g_runtime[(int)STRATEGY_INTRADAY].candle);
   bool directionMatched=(g_runtime[(int)STRATEGY_INTRADAY].candle.valid &&
                          g_runtime[(int)STRATEGY_INTRADAY].candle.direction==active.dir);
   bool strengthMatched=(directionMatched &&
                         g_runtime[(int)STRATEGY_INTRADAY].candle.strength>=InpIntradayConfirmationMinStrength);
   if(strengthMatched)
      return true;

   if(elapsedBars>=InpIntradayConfirmationMaxBars)
   {
      reason=StringFormat("Intraday closed-candle confirmation timeout: TF=%s Bars=%d Pattern=%s Direction=%d Strength=%d",
                          EnumToString(InpIntradayConfirmationTF),elapsedBars,
                          g_runtime[(int)STRATEGY_INTRADAY].candle.englishName,
                          g_runtime[(int)STRATEGY_INTRADAY].candle.direction,
                          (int)g_runtime[(int)STRATEGY_INTRADAY].candle.strength);
      MarkZoneUsed(active,reason);
      return false;
   }

   reason=StringFormat("Waiting for aligned closed reversal candle: TF=%s Bar=%d/%d Pattern=%s Direction=%d Strength=%d",
                       EnumToString(InpIntradayConfirmationTF),elapsedBars,InpIntradayConfirmationMaxBars,
                       g_runtime[(int)STRATEGY_INTRADAY].candle.englishName,
                       g_runtime[(int)STRATEGY_INTRADAY].candle.direction,
                       (int)g_runtime[(int)STRATEGY_INTRADAY].candle.strength);
   return false;
}

void ExecuteIntradayFirstTouch(Zone &active, bool allowEntry)
{
   int s = (int)STRATEGY_INTRADAY;
   active.state = ZONE_ENTRY_PENDING;
   g_runtime[s].zoneId = active.id;
   g_runtime[s].clusterId = BuildOpportunityClusterID(STRATEGY_INTRADAY,active);
   g_runtime[s].zoneState = ZoneStateName(active.state);
   double touchDepth=IntradayRawTouchDepth(active);
   if(InpIntradayUseMinTouchDepthFilter && touchDepth<InpIntradayMinTouchDepth)
   {
      string depthReason=StringFormat("TOUCH_DEPTH rejected: %.4f < %.4f",touchDepth,InpIntradayMinTouchDepth);
      g_runtime[s].status="Entry quality rejected";
      g_runtime[s].rejectReason=depthReason;
      PrintFilterAudit(STRATEGY_INTRADAY,active.dir,active.id,true,false,true,true,false,false,depthReason);
      MarkZoneUsed(active,depthReason);
      g_runtime[s].zoneState=ZoneStateName(active.state);
      PrintFormat("Intraday entry-quality reject: ZoneID=%s %s",active.id,depthReason);
      return;
   }
   string confirmationReason="";
   if(!IntradayClosedCandleConfirmed(active,confirmationReason))
   {
      g_runtime[s].zoneState=ZoneStateName(active.state);
      g_runtime[s].status=(active.used ? "Confirmation timeout" : "Waiting confirmation");
      g_runtime[s].rejectReason=confirmationReason;
      PrintFormat("Intraday confirmation state: ZoneID=%s %s",active.id,confirmationReason);
      return;
   }
   if(!InpIntradayUseClosedCandleConfirmation)
      DetectCandlestickSignal(PERIOD_M30, active.dir, true, g_runtime[s].candle);
   DetectBestChartPattern(PERIOD_M30, active.dir, g_runtime[s].pattern);
   RecordDetectedSignals(STRATEGY_INTRADAY);
   g_runtime[s].candleName = g_runtime[s].candle.englishName + "/" + g_runtime[s].candle.chineseName;
   g_runtime[s].candleStrength = CandleStrengthName(g_runtime[s].candle.strength);
   g_runtime[s].chartPattern = (g_runtime[s].pattern.valid ? g_runtime[s].pattern.englishName + "/" + g_runtime[s].pattern.chineseName : "-");

   g_funnel[s].hardSOPPassed++;
   string indicatorReason="";
   bool indicatorPassed=PassStrategyEMAAndRSI(STRATEGY_INTRADAY,active.dir,indicatorReason);
   string macdReason="";
   bool macdPassed=EvaluateStrategyMACD(STRATEGY_INTRADAY,active.dir,macdReason);
   string bollingerReason="";
   bool bollingerPassed=EvaluateStrategyBollinger(STRATEGY_INTRADAY,active.dir,bollingerReason);
   if(StrategyConfidenceMode(STRATEGY_INTRADAY)!=CONFIDENCE_OFF || LegacyScoreFilterEnabled(STRATEGY_INTRADAY))
      ComputeIntradayScore(active,g_runtime[s].candle,g_runtime[s].pattern,g_runtime[s].score);
   else
      ResetScore(g_runtime[s].score);
   g_runtime[s].confidence=g_runtime[s].score.total;
   bool scorePassed=ConfidenceAllowsEntry(STRATEGY_INTRADAY,g_runtime[s].confidence);
   bool filtersPassed=false;
   string reason="";
   if(!indicatorPassed)
      reason=indicatorReason;
   else if(!macdPassed)
      reason=macdReason;
   else if(!bollingerPassed)
      reason=bollingerReason;
   else if(!scorePassed)
   {
      reason = StringFormat("Intraday置信度不足 %.1f < %.1f", g_runtime[s].confidence, InpIntradayMinConfidence);
      g_funnel[s].confidenceRejected++;
   }
   else
   {
      g_funnel[s].confidencePassed++;
      filtersPassed=PassStrategyFilters(STRATEGY_INTRADAY,reason);
      if(!allowEntry && filtersPassed)
      {
         filtersPassed=false;
         reason="共同开仓锁阻止交易";
      }
      if(!filtersPassed)
         reason = "Intraday全局/策略门控拒绝：" + reason;
      else
         g_funnel[s].globalGatePassed++;
   }

   if(reason != "")
   {
      PrintFilterAudit(STRATEGY_INTRADAY,active.dir,active.id,true,indicatorPassed,macdPassed,scorePassed,filtersPassed,false,reason);
      if(InpIntradayConsumeZoneOnTechnicalReject)
         MarkZoneUsed(active,reason);
      else
         ReleaseZoneForNextClosedBar(active,reason);
      g_runtime[s].zoneState=ZoneStateName(active.state);
      g_runtime[s].status = "未开仓";
      g_runtime[s].rejectReason = reason;
      PrintFormat("Intraday拒绝：ZoneID=%s %s；%s", active.id, reason, g_runtime[s].score.explanation);
      return;
   }

   double entry = (active.dir > 0 ? g_tick.ask : g_tick.bid);
   double slDistance = PTToPrice(InpIntradaySLPoints);
   double tpDistance = PTToPrice(InpIntradayTPPoints);
   double sl = (active.dir > 0 ? entry - slDistance : entry + slDistance);
   double tp = (active.dir > 0 ? entry + tpDistance : entry - tpDistance);
   string comment=BuildTradeComment(STRATEGY_INTRADAY,active.dir,active.id);
   g_pendingZoneId[s]=active.id;
   g_pendingRiskPercent[s]=InpIntradayRiskPercent;
   PreparePendingTradeAudit(STRATEGY_INTRADAY,active,false);
   PrintFormat("Intraday准备开仓：ZoneID=%s EntryLevel=%s %s；固定SL=%s 固定TP=%s",
               active.id, DoubleToString(IntradayEntryLevel(active),g_digits), g_runtime[s].score.explanation,
               DoubleToString(slDistance,g_digits), DoubleToString(tpDistance,g_digits));
   if(InpIntradayConsumeZoneOnTechnicalReject)
      MarkZoneUsed(active,"First Touch已锁定并准备下单");
   bool opened=PlaceStrategyTradeForZone(STRATEGY_INTRADAY,active.dir,comment,entry,sl,tp,InpIntradayFixedLot,InpIntradayRiskPercent);
   if(opened && !active.used)
      MarkZoneUsed(active,"服务器已接受不同ZoneID订单");
   else if(!opened && !InpIntradayConsumeZoneOnTechnicalReject)
      ReleaseZoneForNextClosedBar(active,g_runtime[s].rejectReason);
   PrintFilterAudit(STRATEGY_INTRADAY,active.dir,active.id,true,indicatorPassed,macdPassed,scorePassed,filtersPassed,opened,(opened?"订单已接受":g_runtime[s].rejectReason));
   g_runtime[s].zoneState=ZoneStateName(active.state);
   DrawZone((active.dir > 0 ? "INTRADAY_DEMAND" : "INTRADAY_SUPPLY"), active, (active.dir > 0 ? clrDeepSkyBlue : clrLightCoral));
}

//+------------------------------------------------------------------+
//| Strategy 3: D1 Swing with H4 S&D + S&R and M30 confirmation      |
//+------------------------------------------------------------------+
void RunSwingD1()
{
   int s = (int)STRATEGY_SWING;
   g_runtime[s].lastEvaluatedBar = g_lastSwingBar;
   g_runtime[s].rejectReason = "";

   int d1Trend = DetectSwingTrend(InpSwingBiasTF, InpSwingLookbackBars, InpSwingDepth);
   if(d1Trend == 0)
   {
      g_runtime[s].status = "等待D1明确方向";
      g_runtime[s].rejectReason = "D1主要方向不明确";
      return;
   }
   g_funnel[s].d1DirectionPassed++;

   int h4Trend = DetectSwingTrend(InpSwingSetupTF, InpSwingLookbackBars, InpSwingDepth);
   if(h4Trend != 0 && h4Trend != d1Trend)
   {
      g_runtime[s].status = "等待H4与D1不冲突";
      g_runtime[s].rejectReason = "H4结构与D1方向冲突";
      return;
   }
   g_funnel[s].h4DirectionPassed++;

   if(!g_swingZone.valid || g_swingZone.used || g_swingZone.broken || g_swingZone.expired || g_swingZone.dir != d1Trend)
   {
      Zone setup;
      string oldZoneId=g_swingZone.id;
      if(FindBestSDZone(InpSwingSetupTF, d1Trend, InpSwingLookbackBars, CoursePipsToPrice(InpSwingZonePips), true, STRATEGY_SWING, setup))
      {
         ArmZoneIfNew(setup, g_swingZone, InpSwingSetupTF, STRATEGY_SWING, "Swing H4 S&D");
         if(g_swingZone.valid && g_swingZone.id!=oldZoneId)
            g_funnel[s].h4ZonesFound++;
      }
   }
   if(!g_swingZone.valid || g_swingZone.dir != d1Trend)
   {
      g_runtime[s].status = "等待H4原始Supply/Demand";
      g_runtime[s].rejectReason = "没有符合D1方向的Fresh H4区域";
      return;
   }

   MqlRates entryRates[];
   if(!LoadRates(InpSwingEntryTF, InpPatternLookbackBars + InpATRPeriod + 30, entryRates))
      return;

   SRZone srZone;
   bool hasSR = FindBestSwingSRZone(d1Trend, g_swingZone, srZone);
   if(hasSR)
      g_swingSR = srZone;
   if(InpSwingRequireSRConfluence && !hasSR)
   {
      g_runtime[s].status = "等待H4主要S&R共振";
      g_runtime[s].rejectReason = "H4 S&R少于两次清晰反应或被多次横穿";
      return;
   }

   bool closedBarTouches = BarTouchesZone(entryRates[1], g_swingZone);
   if(g_swingZone.state == ZONE_DEPARTED && closedBarTouches)
   {
      g_swingZone.state = ZONE_FIRST_TOUCH;
      g_swingZone.firstTouchTime = entryRates[1].time;
      g_swingZone.firstTouchBarTime = entryRates[1].time;
      g_swingZone.firstTouchPrice = entryRates[1].close;
      g_swingZone.touches++;
      g_funnel[s].firstTouches++;
      g_funnel[s].m30Touches++;
      PrintFormat("Swing M30 First Touch收盘确认：ZoneID=%s Bar=%s", g_swingZone.id, TimeToString(entryRates[1].time));
   }
   if(g_swingZone.state != ZONE_FIRST_TOUCH && g_swingZone.state != ZONE_ENTRY_PENDING)
   {
      g_runtime[s].status = "等待M30触及H4原始区域并收盘";
      return;
   }
   int touchShift=iBarShift(g_symbol,InpSwingEntryTF,g_swingZone.firstTouchBarTime,false);
   int barsAfterTouch=(touchShift>0 ? touchShift-1 : 0);
   if(touchShift<0 || barsAfterTouch>=InpSwingConfirmationBars)
   {
      MarkZoneUsed(g_swingZone,"Swing M30确认窗口结束仍无合格反转K或假突破恢复");
      g_runtime[s].status="Swing确认窗口已结束";
      g_runtime[s].rejectReason="M30确认窗口结束";
      return;
   }
   if(barsAfterTouch==0 && hasSR)
      g_funnel[s].srConfluencePassed++;

   bool falseBreak = (d1Trend > 0 ? entryRates[1].low < g_swingZone.bottom && entryRates[1].close > g_swingZone.bottom && CandleBull(entryRates[1])
                                   : entryRates[1].high > g_swingZone.top && entryRates[1].close < g_swingZone.top && CandleBear(entryRates[1]));
   DetectCandlestickSignal(InpSwingEntryTF, d1Trend, true, g_runtime[s].candle);
   bool candleConfirm = (g_runtime[s].candle.valid && g_runtime[s].candle.direction == d1Trend &&
                          g_runtime[s].candle.strength >= InpSwingMinCandleStrength);
   bool confirmation=(candleConfirm || falseBreak);

   ChartPatternSignal d1Pattern, h4Pattern;
   DetectBestChartPattern(InpSwingBiasTF, d1Trend, d1Pattern);
   DetectBestChartPattern(InpSwingSetupTF, d1Trend, h4Pattern);
   if(h4Pattern.valid && (!d1Pattern.valid || h4Pattern.score >= d1Pattern.score))
      g_runtime[s].pattern = h4Pattern;
   else
      g_runtime[s].pattern = d1Pattern;
   RecordDetectedSignals(STRATEGY_SWING);
   g_runtime[s].zoneId = g_swingZone.id;
   g_runtime[s].clusterId = BuildOpportunityClusterID(STRATEGY_SWING,g_swingZone);
   g_runtime[s].candleName = g_runtime[s].candle.englishName + "/" + g_runtime[s].candle.chineseName;
   g_runtime[s].candleStrength = CandleStrengthName(g_runtime[s].candle.strength);
   g_runtime[s].chartPattern = (g_runtime[s].pattern.valid ? g_runtime[s].pattern.englishName + "/" + g_runtime[s].pattern.chineseName : "-");
   if(!confirmation)
   {
      g_swingZone.state=ZONE_FIRST_TOUCH;
      g_runtime[s].zoneState=ZoneStateName(g_swingZone.state);
      g_runtime[s].status=StringFormat("等待M30确认窗口 %d/%d",barsAfterTouch+1,InpSwingConfirmationBars);
      g_runtime[s].rejectReason="M30已收盘但没有反转K或假突破恢复";
      PrintFilterAudit(STRATEGY_SWING,d1Trend,g_swingZone.id,false,false,true,true,false,false,g_runtime[s].rejectReason);
      return;
   }

   g_funnel[s].m30Confirmations++;
   g_funnel[s].hardSOPPassed++;
   g_swingZone.state=ZONE_ENTRY_PENDING;
   g_runtime[s].zoneState=ZoneStateName(g_swingZone.state);
   double swingEntryPrice=(d1Trend>0 ? g_tick.ask : g_tick.bid);
   double chaseDistance=(d1Trend>0 ? swingEntryPrice-g_swingZone.top : g_swingZone.bottom-swingEntryPrice);
   double maxChaseDistance=g_swingZone.width*InpSwingMaxChaseZoneFraction;
   if(InpSwingRejectChaseEntry && chaseDistance>maxChaseDistance)
   {
      string chaseReason=StringFormat("Swing追价拒绝：Distance=%s Max=%s ZoneFraction=%.2f",
                                      DoubleToString(chaseDistance,g_digits),
                                      DoubleToString(maxChaseDistance,g_digits),
                                      InpSwingMaxChaseZoneFraction);
      g_runtime[s].status="Entry quality rejected";
      g_runtime[s].rejectReason=chaseReason;
      PrintFilterAudit(STRATEGY_SWING,d1Trend,g_swingZone.id,true,false,true,true,false,false,chaseReason);
      MarkZoneUsed(g_swingZone,chaseReason);
      g_runtime[s].zoneState=ZoneStateName(g_swingZone.state);
      PrintFormat("Swing entry-quality reject: ZoneID=%s %s",g_swingZone.id,chaseReason);
      return;
   }
   string indicatorReason="";
   bool indicatorPassed=PassStrategyEMAAndRSI(STRATEGY_SWING,d1Trend,indicatorReason);
   string macdReason="";
   bool macdPassed=EvaluateStrategyMACD(STRATEGY_SWING,d1Trend,macdReason);
   string bollingerReason="";
   bool bollingerPassed=EvaluateStrategyBollinger(STRATEGY_SWING,d1Trend,bollingerReason);
   if(StrategyConfidenceMode(STRATEGY_SWING)!=CONFIDENCE_OFF || LegacyScoreFilterEnabled(STRATEGY_SWING))
      ComputeSwingScore(d1Trend,h4Trend,hasSR,g_swingZone,g_runtime[s].candle,g_runtime[s].pattern,falseBreak,g_runtime[s].score);
   else
      ResetScore(g_runtime[s].score);
   g_runtime[s].confidence=g_runtime[s].score.total;
   bool scorePassed=ConfidenceAllowsEntry(STRATEGY_SWING,g_runtime[s].confidence);
   bool filtersPassed=false;
   string reason="";
   if(!indicatorPassed)
      reason=indicatorReason;
   else if(!macdPassed)
      reason=macdReason;
   else if(!bollingerPassed)
      reason=bollingerReason;
   else if(!scorePassed)
   {
      reason=StringFormat("Swing置信度不足 %.1f < %.1f",g_runtime[s].confidence,InpSwingMinConfidence);
      g_funnel[s].confidenceRejected++;
   }
   else
   {
      g_funnel[s].confidencePassed++;
      filtersPassed=PassStrategyFilters(STRATEGY_SWING,reason);
      if(!filtersPassed)
         reason="Swing全局/策略门控拒绝："+reason;
      else
         g_funnel[s].globalGatePassed++;
   }

   if(reason != "")
   {
      PrintFilterAudit(STRATEGY_SWING,d1Trend,g_swingZone.id,true,indicatorPassed,macdPassed,scorePassed,filtersPassed,false,reason);
      if(InpSwingConsumeZoneOnTechnicalReject || barsAfterTouch>=InpSwingConfirmationBars-1)
         MarkZoneUsed(g_swingZone,reason);
      else
         g_swingZone.state=ZONE_FIRST_TOUCH;
      g_runtime[s].zoneState=ZoneStateName(g_swingZone.state);
      g_runtime[s].status = "未开仓";
      g_runtime[s].rejectReason = reason;
      PrintFormat("Swing拒绝：ZoneID=%s %s；%s", g_swingZone.id, reason, g_runtime[s].score.explanation);
      return;
   }

   Zone combinedZone = g_swingZone;
   if(hasSR)
      MergeSwingSetupZones(combinedZone, srZone);
   double entry = (d1Trend > 0 ? g_tick.ask : g_tick.bid);
   double buffer = CoursePipsToPrice(InpSwingSLBufferPips);
   double farEdge = (d1Trend > 0 ? MathMin(combinedZone.bottom, entryRates[1].low)
                                 : MathMax(combinedZone.top, entryRates[1].high));
   if(hasSR)
      farEdge = (d1Trend > 0 ? MathMin(farEdge, srZone.bottom) : MathMax(farEdge, srZone.top));
   double sl = (d1Trend > 0 ? farEdge - buffer : farEdge + buffer);
   double risk = MathAbs(entry - sl);
   if(risk <= g_tickSize)
   {
      g_runtime[s].rejectReason = "Swing初始风险距离无效";
      return;
   }

   double tp = 0.0;
   if(InpSwingUseTakeProfit)
   {
      double fallbackRR=InpSwingRR;
      double minimumTargetR=InpSwingMinTargetR;
      if(InpSwingUseVolatilityTargetR)
      {
         double entryATR=CurrentATR(InpSwingEntryTF);
         double atrPricePct=(entry>0.0 ? entryATR/entry*100.0 : 0.0);
         if(atrPricePct>=InpSwingHighVolatilityATRPricePct)
         {
            fallbackRR=InpSwingHighVolatilityRR;
            minimumTargetR=MathMax(minimumTargetR,fallbackRR);
            PrintFormat("Swing high-volatility target: ATR/Price=%.4f%% Threshold=%.4f%% RR=%.2f",
                        atrPricePct,InpSwingHighVolatilityATRPricePct,fallbackRR);
         }
      }
      tp = FindNextPivotTarget(InpSwingBiasTF, d1Trend, entry);
      if((d1Trend > 0 && (tp <= entry || tp-entry < risk*minimumTargetR)) ||
         (d1Trend < 0 && (tp >= entry || entry-tp < risk*minimumTargetR)))
         tp = (d1Trend > 0 ? entry + risk*fallbackRR : entry - risk*fallbackRR);
   }

   PrintFormat("Swing准备开仓：ZoneID=%s %s；InitialR=%s TrailAnchor=%d ProjectedTarget=%s",
               g_swingZone.id, g_runtime[s].score.explanation, DoubleToString(risk,g_digits),
               (int)InpSwingTrailAnchor,
               (g_runtime[s].pattern.valid ? DoubleToString(g_runtime[s].pattern.projectedTarget,g_digits) : "-"));
   string comment=BuildTradeComment(STRATEGY_SWING,d1Trend,g_swingZone.id);
   g_pendingZoneId[s]=g_swingZone.id;
   g_pendingRiskPercent[s]=InpSwingRiskPercent;
   PreparePendingTradeAudit(STRATEGY_SWING,g_swingZone,falseBreak);
   bool opened=PlaceStrategyTradeForZone(STRATEGY_SWING,d1Trend,comment,entry,sl,tp,InpSwingFixedLot,InpSwingRiskPercent);
   if(opened)
   {
      MarkZoneUsed(g_swingZone,"服务器已接受不同ZoneID订单");
      DrawZone((d1Trend > 0 ? "SWING_DEMAND_SETUP" : "SWING_SUPPLY_SETUP"), combinedZone, (d1Trend > 0 ? clrRoyalBlue : clrIndianRed));
      if(hasSR)
         DrawSRZone((d1Trend > 0 ? "SWING_SUPPORT" : "SWING_RESISTANCE"), srZone, (d1Trend > 0 ? clrSeaGreen : clrDarkOrange));
      SavePersistentState();
   }
   else if(InpSwingConsumeZoneOnTechnicalReject || barsAfterTouch>=InpSwingConfirmationBars-1)
      MarkZoneUsed(g_swingZone,g_runtime[s].rejectReason);
   else
      g_swingZone.state=ZONE_FIRST_TOUCH;
   PrintFilterAudit(STRATEGY_SWING,d1Trend,g_swingZone.id,true,indicatorPassed,macdPassed,scorePassed,filtersPassed,opened,(opened?"订单已接受":g_runtime[s].rejectReason));
   g_runtime[s].zoneState=ZoneStateName(g_swingZone.state);
}

//+------------------------------------------------------------------+
//| Entry and execution helpers                                      |
//+------------------------------------------------------------------+
bool V270SmallAccountSizingEnabled()
{
   return (InpSmallAccountProfile!=SMALL_ACCOUNT_OFF || InpForceBrokerMinimumLot || InpEnableConfidence100LotBoost);
}

double V270SingleRiskCap(StrategyId strategy,double configuredRisk,bool exceptionalSizing)
{
   if(exceptionalSizing && InpSmallAccountProfile==SMALL_ACCOUNT_USD100)
      return InpUSD100MaxSingleRiskPct;
   if(exceptionalSizing && InpSmallAccountProfile==SMALL_ACCOUNT_USD500)
      return InpUSD500MaxSingleRiskPct;
   return EffectiveStrategyRiskPercent(strategy,configuredRisk);
}

bool CalculateExactSLRisk(int dir,double entry,double sl,double volume,double &lossMoney,double &riskPercent,string &reason)
{
   lossMoney=0.0;
   riskPercent=0.0;
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   double tickSize=SymbolInfoDouble(g_symbol,SYMBOL_TRADE_TICK_SIZE);
   double tickValue=SymbolInfoDouble(g_symbol,SYMBOL_TRADE_TICK_VALUE_LOSS);
   if(tickValue<=0.0)
      tickValue=SymbolInfoDouble(g_symbol,SYMBOL_TRADE_TICK_VALUE);
   if(equity<=0.0 || entry<=0.0 || sl<=0.0 || volume<=0.0 || tickSize<=0.0 || tickValue<=0.0)
   {
      reason=StringFormat("真实SL风险资料无效 Equity=%.2f Entry=%g SL=%g Volume=%g TickSize=%g TickValue=%g",
                          equity,entry,sl,volume,tickSize,tickValue);
      return false;
   }
   ENUM_ORDER_TYPE type=(dir>0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
   double result=0.0;
   if(!OrderCalcProfit(type,g_symbol,volume,entry,sl,result) || result>=0.0)
   {
      reason=StringFormat("OrderCalcProfit无法计算真实SL亏损 Error=%d Result=%g",GetLastError(),result);
      return false;
   }
   lossMoney=MathAbs(result);
   riskPercent=lossMoney/equity*100.0;
   return true;
}

bool CandidateVolumePassesV270Safety(StrategyId strategy,int dir,long magic,string comment,double entry,double sl,double tp,
                                     double volume,double configuredRisk,double &lossMoney,double &riskPercent,string &reason)
{
   if(!CalculateExactSLRisk(dir,entry,sl,volume,lossMoney,riskPercent,reason))
      return false;
   double singleCap=V270SingleRiskCap(strategy,configuredRisk,true);
   if(riskPercent>singleCap*1.0001)
   {
      reason=StringFormat("候选手数%s实际SL风险%.4f%%超过单笔上限%.4f%%",
                          DoubleToString(volume,VolumeDigits()),riskPercent,singleCap);
      return false;
   }
   double currentRisk=CalculateAccountOpenRiskPercent();
   double totalCap=EffectiveTotalRiskCap();
   if(currentRisk+riskPercent>totalCap*1.0001)
   {
      reason=StringFormat("候选手数加入后总SL风险%.4f%%超过上限%.4f%%",currentRisk+riskPercent,totalCap);
      return false;
   }
   ENUM_ORDER_TYPE type=(dir>0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
   double margin=0.0;
   if(!OrderCalcMargin(type,g_symbol,volume,entry,margin) || margin<=0.0)
   {
      reason=StringFormat("OrderCalcMargin失败 Volume=%s Error=%d",DoubleToString(volume,VolumeDigits()),GetLastError());
      return false;
   }
   if(margin>AccountInfoDouble(ACCOUNT_MARGIN_FREE))
   {
      reason=StringFormat("候选手数保证金不足 Required=%.2f Free=%.2f",margin,AccountInfoDouble(ACCOUNT_MARGIN_FREE));
      return false;
   }
   MqlTradeRequest request={};
   MqlTradeCheckResult result={};
   request.action=TRADE_ACTION_DEAL;
   request.magic=magic;
   request.symbol=g_symbol;
   request.volume=volume;
   request.type=type;
   request.price=(dir>0 ? g_tick.ask : g_tick.bid);
   request.sl=sl;
   request.tp=tp;
   request.deviation=InpDeviationPoints;
   request.type_filling=PreferredFillingMode();
   request.type_time=ORDER_TIME_GTC;
   request.comment=comment;
   if(!OrderCheck(request,result) || (result.retcode!=0 && result.retcode!=TRADE_RETCODE_DONE))
   {
      reason=StringFormat("OrderCheck拒绝候选手数 retcode=%u %s",result.retcode,result.comment);
      return false;
   }
   double projectedMarginLevel=result.margin_level;
   if(projectedMarginLevel<=0.0 && result.margin>0.0 && result.equity>0.0)
      projectedMarginLevel=result.equity/result.margin*100.0;
   if(projectedMarginLevel>0.0 && projectedMarginLevel<InpMinMarginLevelPct)
   {
      reason=StringFormat("候选手数可能立即触发保证金保护 MarginLevel=%.2f%% Limit=%.2f%%",projectedMarginLevel,InpMinMarginLevelPct);
      return false;
   }
   return true;
}

bool CalculateAutomaticRiskVolumeV270(StrategyId strategy,int dir,double entry,double sl,double riskPercent,
                                       double &lots,double &rawLots,bool &forcedMinimum,string &reason)
{
   lots=0.0;
   rawLots=0.0;
   forcedMinimum=false;
   if(!V270SmallAccountSizingEnabled())
   {
      bool ready=CalculateAutomaticRiskVolume(dir,entry,sl,riskPercent,lots,reason);
      rawLots=lots;
      return ready;
   }
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   double tickSize=SymbolInfoDouble(g_symbol,SYMBOL_TRADE_TICK_SIZE);
   double tickValue=SymbolInfoDouble(g_symbol,SYMBOL_TRADE_TICK_VALUE_LOSS);
   if(tickValue<=0.0)
      tickValue=SymbolInfoDouble(g_symbol,SYMBOL_TRADE_TICK_VALUE);
   double slDistance=MathAbs(entry-sl);
   if(equity<=0.0 || riskPercent<=0.0 || slDistance<=0.0 || tickSize<=0.0 || tickValue<=0.0)
   {
      reason=StringFormat("自动风险资料无效 Equity=%.2f Risk=%.3f SLDistance=%g TickSize=%g TickValue=%g",
                          equity,riskPercent,slDistance,tickSize,tickValue);
      return false;
   }
   ENUM_ORDER_TYPE type=(dir>0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
   double oneLotLoss=0.0;
   if(!OrderCalcProfit(type,g_symbol,1.0,entry,sl,oneLotLoss) || oneLotLoss>=0.0)
   {
      reason=StringFormat("OrderCalcProfit无法计算每手SL风险 Error=%d Result=%g",GetLastError(),oneLotLoss);
      return false;
   }
   double moneyRisk=equity*riskPercent/100.0;
   rawLots=moneyRisk/MathAbs(oneLotLoss);
   if(rawLots<g_volumeMin)
   {
      if(!InpForceBrokerMinimumLot)
      {
         reason=StringFormat("目标风险只允许%.8f手，低于经纪商最小手数%s",
                             rawLots,DoubleToString(g_volumeMin,VolumeDigits()));
         return false;
      }
      lots=NormalizeDouble(g_volumeMin,VolumeDigits());
      forcedMinimum=true;
      reason=StringFormat("目标风险手数%.8f低于最小手数，按v4.00规则强制%s手",
                          rawLots,DoubleToString(lots,VolumeDigits()));
      return true;
   }
   rawLots=MathMin(rawLots,g_volumeMax);
   double steps=MathFloor((rawLots-g_volumeMin)/g_volumeStep+0.0000001);
   lots=NormalizeDouble(g_volumeMin+steps*g_volumeStep,VolumeDigits());
   if(lots<g_volumeMin || lots>g_volumeMax)
   {
      reason="风险手数按步进规范化后越界";
      return false;
   }
   return true;
}

bool SelectConfidence100Volume(StrategyId strategy,int dir,long magic,string comment,double entry,double sl,double tp,
                               double configuredRisk,double baseLots,double &selectedLots,double &lossMoney,double &riskPercent,string &reason)
{
   selectedLots=baseLots;
   if(!InpEnableConfidence100LotBoost || g_runtime[(int)strategy].confidence<InpConfidenceFullScore-InpConfidenceFullTolerance)
      return false;
   int maximumHundredths=(int)MathFloor(MathMin(0.05,InpConfidenceBoostMaxLot)*100.0+0.000001);
   for(int hundredths=maximumHundredths;hundredths>=1;hundredths--)
   {
      double requested=(double)hundredths/100.0;
      if(requested+0.0000001<baseLots || requested<g_volumeMin || requested>g_volumeMax)
         continue;
      double candidate=NormalizeVolume(requested);
      if(MathAbs(candidate-requested)>g_volumeStep*0.001)
         continue;
      string candidateReason="";
      double candidateLoss=0.0,candidateRisk=0.0;
      if(CandidateVolumePassesV270Safety(strategy,dir,magic,comment,entry,sl,tp,candidate,configuredRisk,
                                         candidateLoss,candidateRisk,candidateReason))
      {
         selectedLots=candidate;
         lossMoney=candidateLoss;
         riskPercent=candidateRisk;
         reason=StringFormat("Confidence满分选择最高合规手数%s",DoubleToString(candidate,VolumeDigits()));
         return (candidate>baseLots+g_volumeStep*0.001);
      }
      PrintFormat("CONFIDENCE100_CANDIDATE_REJECT|SOP=%s|Candidate=%s|Reason=%s",
                  g_runtime[(int)strategy].name,DoubleToString(candidate,VolumeDigits()),candidateReason);
   }
   reason="Confidence满分但0.02至0.05均不合规，保留基础手数";
   return false;
}

bool PlaceStrategyTrade(int dir,
                        long magic,
                        string comment,
                        double entry,
                        double sl,
                        double tp,
                        double fixedLot,
                        double riskPercent)
{
   sl = NormalizePrice(sl);
   tp = NormalizePrice(tp);

   if(!AdjustStopsForBroker(dir, entry, sl, tp))
      return false;

   double slDistance = MathAbs(entry - sl);
   if(slDistance <= 0.0)
      return false;

   int strategy=(magic==InpScalpMagic ? (int)STRATEGY_SCALPING : magic==InpIntradayMagic ? (int)STRATEGY_INTRADAY : (int)STRATEGY_SWING);
   ResetPendingVolumeAudit(strategy);
   double lots=0.0;
   double calculatedLots=0.0;
   bool forcedMinimum=false;
   bool confidenceBoost=false;
   string lotReason="";
   bool manualMode=(InpMoneyManagementMode==MONEY_MANUAL_FIXED_LOT || InpUseFixedLot);
   bool lotReady=false;
   if(manualMode)
   {
      lotReady=PrepareManualVolume(fixedLot,lots,lotReason);
      calculatedLots=lots;
   }
   else
      lotReady=CalculateAutomaticRiskVolumeV270((StrategyId)strategy,dir,entry,sl,riskPercent,lots,calculatedLots,forcedMinimum,lotReason);
   if(!lotReady || lots<g_volumeMin || lots>g_volumeMax)
   {
      g_runtime[strategy].rejectReason="手数校验失败："+lotReason;
      PrintFormat("%s拒绝：%s",comment,g_runtime[strategy].rejectReason);
      g_funnel[strategy].riskRejected++;
      if(StringFind(lotReason,"低于经纪商最小手数")>=0)
      {
         g_funnel[strategy].minimumLotRiskRejected++;
         PrintFormat("RISK_REJECT|SOP=%s|Type=MINIMUM_LOT_EXCEEDS_RISK|Equity=%.2f|RiskPct=%.4f|MinLot=%s|Reason=%s",
                     g_runtime[strategy].name,AccountInfoDouble(ACCOUNT_EQUITY),riskPercent,
                     DoubleToString(g_volumeMin,VolumeDigits()),lotReason);
      }
      return false;
   }

   double projectedLoss = 0.0;
   double projectedRiskPct=0.0;
   if(!manualMode && InpEnableConfidence100LotBoost &&
      g_runtime[strategy].confidence>=InpConfidenceFullScore-InpConfidenceFullTolerance)
   {
      double selectedLots=lots;
      string boostReason="";
      confidenceBoost=SelectConfidence100Volume((StrategyId)strategy,dir,magic,comment,entry,sl,tp,riskPercent,lots,
                                                selectedLots,projectedLoss,projectedRiskPct,boostReason);
      lots=selectedLots;
      PrintFormat("CONFIDENCE100_LOT_AUDIT|SOP=%s|Confidence=%.2f|CalculatedLot=%.8f|FinalLot=%s|Boosted=%s|Reason=%s",
                  g_runtime[strategy].name,g_runtime[strategy].confidence,calculatedLots,
                  DoubleToString(lots,VolumeDigits()),(confidenceBoost?"YES":"NO"),boostReason);
   }
   string exactRiskReason="";
   bool exactRiskReady=CalculateExactSLRisk(dir,entry,sl,lots,projectedLoss,projectedRiskPct,exactRiskReason);
   if(!exactRiskReady && V270SmallAccountSizingEnabled())
   {
      g_runtime[strategy].rejectReason="真实SL风险校验失败："+exactRiskReason;
      PrintFormat("%s拒绝：%s",comment,g_runtime[strategy].rejectReason);
      g_funnel[strategy].riskRejected++;
      return false;
   }
   if(exactRiskReady)
   {
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      bool manualBrokerMinimum=(manualMode && lots<=g_volumeMin+g_volumeStep*0.001);
      double strategyRiskCap=V270SingleRiskCap((StrategyId)strategy,riskPercent,
                                               (forcedMinimum || confidenceBoost || manualBrokerMinimum));
      bool enforceStrategyCap=(InpCapitalLadderMode==CAPITAL_LADDER_ENFORCE || forcedMinimum || confidenceBoost || InpSmallAccountProfile!=SMALL_ACCOUNT_OFF);
      if(enforceStrategyCap && projectedRiskPct>strategyRiskCap*1.01)
      {
         PrintFormat("%s拒绝：实际SL风险 %.4f%% 超过本策略单笔上限 %.4f%%",comment,projectedRiskPct,strategyRiskCap);
         g_runtime[strategy].rejectReason="交易手数的实际SL风险超过本策略单笔上限";
         g_funnel[strategy].riskRejected++;
         if(lots<=g_volumeMin+g_volumeStep*0.001)
            g_funnel[strategy].minimumLotRiskRejected++;
         return false;
      }
      projectedLoss=MathAbs(projectedLoss);
      g_pendingCalculatedVolume[strategy]=calculatedLots;
      g_pendingFinalVolume[strategy]=lots;
      g_pendingActualSLRiskMoney[strategy]=projectedLoss;
      g_pendingActualSLRiskPercent[strategy]=projectedRiskPct;
      g_pendingForcedMinimumLot[strategy]=forcedMinimum;
      g_pendingConfidence100Boost[strategy]=confidenceBoost;
      if(forcedMinimum)
         PrintFormat("MINLOT_FORCE_AUDIT|CalculatedLot=%.8f|FinalLot=%s|SLRiskMoney=%.2f|SLRiskPct=%.4f|Equity=%.2f|SOP=%s|Confidence=%.2f",
                     calculatedLots,DoubleToString(lots,VolumeDigits()),projectedLoss,projectedRiskPct,equity,
                     g_runtime[strategy].name,g_runtime[strategy].confidence);
      double totalRiskCap=EffectiveTotalRiskCap();
      if(CalculateAccountOpenRiskPercent()+projectedRiskPct > totalRiskCap)
      {
         PrintFormat("%s拒绝：加入本单后的账户风险 %.2f%% 超过 %.2f%%",comment,
                     CalculateAccountOpenRiskPercent()+projectedRiskPct,totalRiskCap);
         g_runtime[strategy].rejectReason="加入新订单后账户总SL风险超过上限";
         g_funnel[strategy].riskRejected++;
         g_funnel[strategy].totalRiskRejected++;
         PrintFormat("RISK_REJECT|SOP=%s|Type=TOTAL_OPEN_RISK|CurrentPlusNew=%.4f|Limit=%.4f",
                     g_runtime[strategy].name,CalculateAccountOpenRiskPercent()+projectedRiskPct,totalRiskCap);
         return false;
      }
   }

   double requiredMargin = 0.0;
   ENUM_ORDER_TYPE orderType = (dir > 0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
   if(!OrderCalcMargin(orderType, g_symbol, lots, entry, requiredMargin))
   {
      PrintFormat("%s保证金计算失败。Error=%d", comment, GetLastError());
      g_runtime[strategy].rejectReason="OrderCalcMargin保证金计算失败";
      g_funnel[strategy].marginRejected++;
      g_funnel[strategy].insufficientFundsRejected++;
      return false;
   }
   if(requiredMargin > AccountInfoDouble(ACCOUNT_MARGIN_FREE))
   {
      PrintFormat("%s保证金不足。Required=%s Free=%s", comment,
                  DoubleToString(requiredMargin,2), DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE),2));
      g_runtime[strategy].rejectReason="可用保证金不足";
      g_funnel[strategy].marginRejected++;
      g_funnel[strategy].insufficientFundsRejected++;
      return false;
   }

   MqlTradeRequest checkRequest={};
   MqlTradeCheckResult checkResult={};
   checkRequest.action=TRADE_ACTION_DEAL;
   checkRequest.magic=magic;
   checkRequest.symbol=g_symbol;
   checkRequest.volume=lots;
   checkRequest.type=orderType;
   checkRequest.price=(dir>0 ? g_tick.ask : g_tick.bid);
   checkRequest.sl=sl;
   checkRequest.tp=tp;
   checkRequest.deviation=InpDeviationPoints;
   checkRequest.type_filling=PreferredFillingMode();
   checkRequest.type_time=ORDER_TIME_GTC;
   checkRequest.comment=comment;
   if(!OrderCheck(checkRequest,checkResult) || (checkResult.retcode!=0 && checkResult.retcode!=TRADE_RETCODE_DONE))
   {
      g_runtime[strategy].rejectReason=StringFormat("OrderCheck拒绝：retcode=%u %s",checkResult.retcode,checkResult.comment);
      PrintFormat("%s拒绝：%s Margin=%s Free=%s",comment,g_runtime[strategy].rejectReason,
                  DoubleToString(checkResult.margin,2),DoubleToString(checkResult.margin_free,2));
      g_funnel[strategy].marginRejected++;
      if(checkResult.retcode==TRADE_RETCODE_NO_MONEY)
         g_funnel[strategy].insufficientFundsRejected++;
      return false;
   }
   if(V270SmallAccountSizingEnabled())
   {
      double projectedMarginLevel=checkResult.margin_level;
      if(projectedMarginLevel<=0.0 && checkResult.margin>0.0 && checkResult.equity>0.0)
         projectedMarginLevel=checkResult.equity/checkResult.margin*100.0;
      if(projectedMarginLevel>0.0 && projectedMarginLevel<InpMinMarginLevelPct)
      {
         g_runtime[strategy].rejectReason=StringFormat("OrderCheck后预计保证金水平%.2f%%低于%.2f%%，防止立即Margin Call/Stop Out",
                                                       projectedMarginLevel,InpMinMarginLevelPct);
         PrintFormat("%s拒绝：%s",comment,g_runtime[strategy].rejectReason);
         g_funnel[strategy].marginRejected++;
         g_funnel[strategy].insufficientFundsRejected++;
         return false;
      }
   }

   trade.SetExpertMagicNumber(magic);
   trade.SetDeviationInPoints(InpDeviationPoints);
   trade.SetTypeFillingBySymbol(g_symbol);

   // Requested/rejected now describe the broker request layer only.
   // Local strategy, risk, margin, cluster and stop checks keep their own counters.
   g_funnel[strategy].ordersRequested++;
   bool ok = false;
   if(dir > 0)
      ok = trade.Buy(lots, g_symbol, 0.0, sl, tp, comment);
   else
      ok = trade.Sell(lots, g_symbol, 0.0, sl, tp, comment);

   if(!ok)
   {
      g_funnel[strategy].ordersRejected++;
      PrintFormat("%s failed. Retcode=%d %s", comment, trade.ResultRetcode(), trade.ResultRetcodeDescription());
      g_runtime[strategy].rejectReason=trade.ResultRetcodeDescription();
      if(trade.ResultRetcode()==TRADE_RETCODE_NO_MONEY)
      {
         g_funnel[strategy].marginRejected++;
         g_funnel[strategy].insufficientFundsRejected++;
      }
      return false;
   }

   PrintFormat("%s opened. lots=%s sl=%s tp=%s magic=%s Confidence=%.2f ForcedMin=%s ConfidenceBoost=%s SLRisk=%.2f/%.4f%%",
               comment,
               DoubleToString(lots, VolumeDigits()),
               DoubleToString(sl, g_digits),
               DoubleToString(tp, g_digits),
               IntegerToString((int)magic),g_runtime[strategy].confidence,
               (forcedMinimum?"YES":"NO"),(confidenceBoost?"YES":"NO"),
               g_pendingActualSLRiskMoney[strategy],g_pendingActualSLRiskPercent[strategy]);
   return true;
}

ENUM_ORDER_TYPE_FILLING PreferredFillingMode()
{
   long mode=SymbolInfoInteger(g_symbol,SYMBOL_FILLING_MODE);
   if((mode&SYMBOL_FILLING_IOC)==SYMBOL_FILLING_IOC) return ORDER_FILLING_IOC;
   if((mode&SYMBOL_FILLING_FOK)==SYMBOL_FILLING_FOK) return ORDER_FILLING_FOK;
   return ORDER_FILLING_RETURN;
}

bool PrepareManualVolume(double requested,double &normalized,string &reason)
{
   normalized=0.0;
   reason="";
   if(requested<=0.0)
   {
      reason="手动手数必须大于0";
      return false;
   }
   double clipped=MathMax(g_volumeMin,MathMin(g_volumeMax,requested));
   double steps=MathFloor((clipped-g_volumeMin)/g_volumeStep+0.0000001);
   normalized=NormalizeDouble(g_volumeMin+steps*g_volumeStep,VolumeDigits());
   if(normalized<g_volumeMin || normalized>g_volumeMax)
   {
      reason=StringFormat("手数无法符合经纪商范围 Min=%s Max=%s Step=%s",
                          DoubleToString(g_volumeMin,VolumeDigits()),DoubleToString(g_volumeMax,VolumeDigits()),DoubleToString(g_volumeStep,VolumeDigits()));
      return false;
   }
   if(MathAbs(normalized-requested)>g_volumeStep*0.001)
      PrintFormat("手动手数已按经纪商规范化：Requested=%s Normalized=%s Min=%s Max=%s Step=%s",
                  DoubleToString(requested,8),DoubleToString(normalized,VolumeDigits()),
                  DoubleToString(g_volumeMin,VolumeDigits()),DoubleToString(g_volumeMax,VolumeDigits()),DoubleToString(g_volumeStep,VolumeDigits()));
   return true;
}

bool CalculateAutomaticRiskVolume(int dir,double entry,double sl,double riskPercent,double &lots,string &reason)
{
   lots=0.0;
   reason="";
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   double slDistance=MathAbs(entry-sl);
   double tickSize=SymbolInfoDouble(g_symbol,SYMBOL_TRADE_TICK_SIZE);
   double tickValue=SymbolInfoDouble(g_symbol,SYMBOL_TRADE_TICK_VALUE_LOSS);
   if(tickValue<=0.0) tickValue=SymbolInfoDouble(g_symbol,SYMBOL_TRADE_TICK_VALUE);
   if(equity<=0.0 || riskPercent<=0.0 || slDistance<=0.0 || tickSize<=0.0 || tickValue<=0.0)
   {
      reason=StringFormat("自动风险参数无效 Equity=%.2f Risk=%.3f SLDistance=%g TickSize=%g TickValue=%g",
                          equity,riskPercent,slDistance,tickSize,tickValue);
      return false;
   }
   double moneyRisk=equity*riskPercent/100.0;
   double lossPerLot=(slDistance/tickSize)*tickValue;
   double calcLoss=0.0;
   ENUM_ORDER_TYPE type=(dir>0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
   if(OrderCalcProfit(type,g_symbol,1.0,entry,sl,calcLoss) && calcLoss<0.0)
      lossPerLot=MathMax(lossPerLot,MathAbs(calcLoss));
   if(lossPerLot<=0.0)
   {
      reason="每手SL风险金额无法计算";
      return false;
   }
   double rawLots=moneyRisk/lossPerLot;
   if(rawLots<g_volumeMin)
   {
      reason=StringFormat("目标风险只允许%.8f手，低于经纪商最小手数%s，拒绝使用错误最小手数",
                          rawLots,DoubleToString(g_volumeMin,VolumeDigits()));
      return false;
   }
   rawLots=MathMin(rawLots,g_volumeMax);
   double steps=MathFloor((rawLots-g_volumeMin)/g_volumeStep+0.0000001);
   lots=NormalizeDouble(g_volumeMin+steps*g_volumeStep,VolumeDigits());
   if(lots<g_volumeMin || lots>g_volumeMax)
   {
      reason="风险手数按步进规范化后越界";
      return false;
   }
   double normalizedLoss=0.0;
   if(OrderCalcProfit(type,g_symbol,lots,entry,sl,normalizedLoss) && normalizedLoss<0.0 && MathAbs(normalizedLoss)>moneyRisk*1.01)
   {
      reason=StringFormat("规范化手数风险%.2f超过目标%.2f",MathAbs(normalizedLoss),moneyRisk);
      return false;
   }
   return true;
}

double CalculateRiskLotByOrder(int dir, double entry, double sl, double riskPercent)
{
   if(entry <= 0.0 || sl <= 0.0 || riskPercent <= 0.0)
      return NormalizeLotToStep(g_volumeMin);

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double moneyRisk = equity * riskPercent / 100.0;
   double oneLotResult = 0.0;
   ENUM_ORDER_TYPE type = (dir > 0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
   if(OrderCalcProfit(type, g_symbol, 1.0, entry, sl, oneLotResult) && oneLotResult < 0.0)
   {
      double rawLots = moneyRisk / MathAbs(oneLotResult);
      if(rawLots < g_volumeMin)
         return 0.0;
      return NormalizeLotToStep(rawLots);
   }

   // Broker fallback when OrderCalcProfit is unavailable.
   return CalculateRiskLot(MathAbs(entry - sl), riskPercent);
}

bool AdjustStopsForBroker(int dir, double entry, double &sl, double &tp)
{
   double minDist = (double)(g_stopsLevel + 2) * g_point;
   bool hasTakeProfit = (tp > 0.0);

   if(dir > 0)
   {
      if(entry - sl < minDist)
         sl = entry - minDist;
      if(hasTakeProfit && tp - entry < minDist)
         tp = entry + minDist;
   }
   else
   {
      if(sl - entry < minDist)
         sl = entry + minDist;
      if(hasTakeProfit && entry - tp < minDist)
         tp = entry - minDist;
   }

   sl = NormalizePrice(sl);
   if(hasTakeProfit)
      tp = NormalizePrice(tp);
   else
      tp = 0.0;
   return (sl > 0.0 && (!hasTakeProfit || tp > 0.0));
}

double CalculateRiskLot(double slDistance, double riskPercent)
{
   if(slDistance <= 0.0 || riskPercent <= 0.0)
      return NormalizeVolume(g_volumeMin);

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double moneyRisk = equity * riskPercent / 100.0;

   double tickValue = g_tickValue;
   if(tickValue <= 0.0)
      tickValue = SymbolInfoDouble(g_symbol, SYMBOL_TRADE_TICK_VALUE_PROFIT);
   if(tickValue <= 0.0 || g_tickSize <= 0.0)
      return NormalizeVolume(g_volumeMin);

   double moneyPerLot = (slDistance / g_tickSize) * tickValue;
   if(moneyPerLot <= 0.0)
      return NormalizeVolume(g_volumeMin);

   return NormalizeVolume(moneyRisk / moneyPerLot);
}

double NormalizePrice(double price)
{
   if(g_tickSize > 0.0)
      price = MathRound(price / g_tickSize) * g_tickSize;
   return NormalizeDouble(price, g_digits);
}

double NormalizeVolume(double volume)
{
   if(volume <= 0.0)
      volume = g_volumeMin;

   volume = MathMax(g_volumeMin, MathMin(g_volumeMax, volume));

   double steps = MathFloor((volume - g_volumeMin) / g_volumeStep + 0.0000001);
   volume = g_volumeMin + steps * g_volumeStep;
   volume = MathMax(g_volumeMin, MathMin(g_volumeMax, volume));
   return NormalizeDouble(volume, VolumeDigits());
}

int VolumeDigits()
{
   int digits = 0;
   double step = g_volumeStep;
   while(digits < 8 && MathAbs(step - MathRound(step)) > 0.00000001)
   {
      step *= 10.0;
      digits++;
   }
   return digits;
}

bool HasOpenPositionByMagic(long magic)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(!PositionSelectByTicket(ticket))
         continue;

      string sym = PositionGetString(POSITION_SYMBOL);
      long posMagic = (long)PositionGetInteger(POSITION_MAGIC);
      if(sym == g_symbol && posMagic == magic)
         return true;
   }
   return false;
}

bool SelectPositionByMagic(long magic, ulong &ticket)
{
   ticket = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong positionTicket = PositionGetTicket(i);
      if(positionTicket == 0 || !PositionSelectByTicket(positionTicket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) == g_symbol &&
         (long)PositionGetInteger(POSITION_MAGIC) == magic)
      {
         ticket = positionTicket;
         return true;
      }
   }
   return false;
}

string SwingRiskKey(long magic)
{
   long login = AccountInfoInteger(ACCOUNT_LOGIN);
   return "GSM_SW_R_" + IntegerToString(login) + "_" + g_symbol + "_" + IntegerToString(magic);
}

void SaveSwingInitialRisk(long magic, double fallbackRisk)
{
   double risk = fallbackRisk;
   ulong ticket = 0;
   if(SelectPositionByMagic(magic, ticket))
   {
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double stopLoss = PositionGetDouble(POSITION_SL);
      if(openPrice > 0.0 && stopLoss > 0.0)
         risk = MathAbs(openPrice - stopLoss);
   }

   if(risk <= 0.0)
      return;

   g_swingPositionTicket = ticket;
   g_swingInitialRisk = risk;
   GlobalVariableSet(SwingRiskKey(magic), risk);
}

string SwingPositionRiskKey(ulong identifier)
{
   return StringFormat("GSM40_SW_R_%I64d_%u_%I64u",(long)AccountInfoInteger(ACCOUNT_LOGIN),HashText(g_symbol),identifier);
}

void SaveSwingRiskForDeal(ulong deal)
{
   ulong identifier=(ulong)HistoryDealGetInteger(deal,DEAL_POSITION_ID);
   ulong ticket=0;
   if(identifier==0 || !SelectPositionByIdentifier(identifier,InpSwingMagic,ticket) || !PositionSelectByTicket(ticket))
      return;
   double entry=PositionGetDouble(POSITION_PRICE_OPEN);
   double sl=PositionGetDouble(POSITION_SL);
   if(entry<=0.0 || sl<=0.0)
      return;
   double risk=MathAbs(entry-sl);
   if(risk>g_tickSize)
      GlobalVariableSet(SwingPositionRiskKey(identifier),risk);
}

void ManageScalpingPosition()
{
   if(!InpScalpUseBreakEven)
      return;

   double bid=SymbolInfoDouble(g_symbol,SYMBOL_BID);
   double ask=SymbolInfoDouble(g_symbol,SYMBOL_ASK);
   double initialRisk=CoursePipsToPrice(InpScalpSLPips);
   if(bid<=0.0 || ask<=0.0 || initialRisk<=g_tickSize)
      return;

   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=g_symbol ||
         (long)PositionGetInteger(POSITION_MAGIC)!=InpScalpMagic)
         continue;

      double entry=PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL=PositionGetDouble(POSITION_SL);
      double currentTP=PositionGetDouble(POSITION_TP);
      bool isBuy=((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY);
      double marketPrice=(isBuy ? bid : ask);
      double profitDistance=(isBuy ? marketPrice-entry : entry-marketPrice);
      if(entry<=0.0 || profitDistance<initialRisk*InpScalpBreakEvenAtR)
         continue;

      double offset=CoursePipsToPrice(InpScalpBreakEvenOffsetPips);
      double desiredSL=(isBuy ? entry+offset : entry-offset);
      int brokerLevel=(g_stopsLevel>g_freezeLevel ? g_stopsLevel : g_freezeLevel);
      double minDistance=(double)(brokerLevel+2)*g_point;
      desiredSL=(isBuy ? MathMin(desiredSL,bid-minDistance) : MathMax(desiredSL,ask+minDistance));
      desiredSL=NormalizePrice(desiredSL);

      double minImprovement=MathMax(g_tickSize,CoursePipsToPrice(InpScalpBreakEvenStepPips));
      bool enough=(isBuy ? desiredSL>currentSL+minImprovement
                         : currentSL<=0.0 || desiredSL<currentSL-minImprovement);
      if(!enough || desiredSL<=0.0)
         continue;

      trade.SetExpertMagicNumber(InpScalpMagic);
      if(!trade.PositionModify(ticket,desiredSL,currentTP))
      {
         PrintFormat("Scalping保本SL修改失败：Ticket=%I64u Retcode=%d %s",
                     ticket,trade.ResultRetcode(),trade.ResultRetcodeDescription());
         continue;
      }
      PrintFormat("Scalping保本已启用：Ticket=%I64u SL=%s TriggerR=%.2f OffsetPips=%.2f",
                  ticket,DoubleToString(desiredSL,g_digits),InpScalpBreakEvenAtR,InpScalpBreakEvenOffsetPips);
   }
}

void ManageIntradayPosition()
{
   if(!InpIntradayUseBreakEven)
      return;

   double bid=SymbolInfoDouble(g_symbol,SYMBOL_BID);
   double ask=SymbolInfoDouble(g_symbol,SYMBOL_ASK);
   double initialRisk=PTToPrice(InpIntradaySLPoints);
   if(bid<=0.0 || ask<=0.0 || initialRisk<=g_tickSize)
      return;

   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=g_symbol ||
         (long)PositionGetInteger(POSITION_MAGIC)!=InpIntradayMagic)
         continue;

      double entry=PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL=PositionGetDouble(POSITION_SL);
      double currentTP=PositionGetDouble(POSITION_TP);
      bool isBuy=((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY);
      double marketPrice=(isBuy ? bid : ask);
      double profitDistance=(isBuy ? marketPrice-entry : entry-marketPrice);
      if(entry<=0.0 || profitDistance<initialRisk*InpIntradayBreakEvenAtR)
         continue;

      double offset=PTToPrice(InpIntradayBreakEvenOffsetPoints);
      double desiredSL=(isBuy ? entry+offset : entry-offset);
      int brokerLevel=(g_stopsLevel>g_freezeLevel ? g_stopsLevel : g_freezeLevel);
      double minDistance=(double)(brokerLevel+2)*g_point;
      desiredSL=(isBuy ? MathMin(desiredSL,bid-minDistance) : MathMax(desiredSL,ask+minDistance));
      desiredSL=NormalizePrice(desiredSL);

      double minImprovement=MathMax(g_tickSize,PTToPrice(InpIntradayBreakEvenStepPoints));
      bool enough=(isBuy ? desiredSL>currentSL+minImprovement
                         : currentSL<=0.0 || desiredSL<currentSL-minImprovement);
      if(!enough || desiredSL<=0.0)
         continue;

      trade.SetExpertMagicNumber(InpIntradayMagic);
      if(!trade.PositionModify(ticket,desiredSL,currentTP))
      {
         PrintFormat("Intraday break-even modification failed: Ticket=%I64u Retcode=%d %s",
                     ticket,trade.ResultRetcode(),trade.ResultRetcodeDescription());
         continue;
      }
      PrintFormat("Intraday break-even enabled: Ticket=%I64u SL=%s TriggerR=%.2f OffsetPoints=%.1f",
                  ticket,DoubleToString(desiredSL,g_digits),InpIntradayBreakEvenAtR,InpIntradayBreakEvenOffsetPoints);
   }
}

void ManageSwingPosition()
{
   double bid=SymbolInfoDouble(g_symbol,SYMBOL_BID);
   double ask=SymbolInfoDouble(g_symbol,SYMBOL_ASK);
   if(bid<=0.0 || ask<=0.0)
      return;

   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=g_symbol || (long)PositionGetInteger(POSITION_MAGIC)!=InpSwingMagic)
         continue;

      ulong identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
      double entry=PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL=PositionGetDouble(POSITION_SL);
      double currentTP=PositionGetDouble(POSITION_TP);
      bool isBuy=((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY);
      string riskKey=SwingPositionRiskKey(identifier);
      double initialRisk=(GlobalVariableCheck(riskKey) ? GlobalVariableGet(riskKey) : MathAbs(entry-currentSL));
      if(initialRisk<=g_tickSize || entry<=0.0)
         continue;
      if(!GlobalVariableCheck(riskKey))
         GlobalVariableSet(riskKey,initialRisk);

      double marketPrice=(isBuy ? bid : ask);
      double profitDistance=(isBuy ? marketPrice-entry : entry-marketPrice);
      if(profitDistance<=0.0)
         continue;
      double desiredSL=currentSL;
      bool improve=false;

      if(InpSwingUseBreakEven && profitDistance>=initialRisk*InpSwingBreakEvenAtR)
      {
         double offset=InpSwingBreakEvenOffsetPips*InpCoursePipInPrice;
         double breakEvenSL=(isBuy ? entry+offset : entry-offset);
         if((isBuy && breakEvenSL>desiredSL) || (!isBuy && (desiredSL<=0.0 || breakEvenSL<desiredSL)))
         {
            desiredSL=breakEvenSL;
            improve=true;
         }
      }

      if(InpSwingUseTrailingStop && profitDistance>=initialRisk*InpSwingTrailStartR)
      {
         double atr=CurrentATR(InpSwingTrailTF);
         if(atr>0.0)
         {
            double anchor=marketPrice;
            if(InpSwingTrailAnchor==SWING_TRAIL_CLOSED_H4)
            {
               MqlRates h4Rates[];
               if(LoadRates(InpSwingTrailTF,InpATRPeriod+InpPatternPivotDepth+10,h4Rates))
                  anchor=h4Rates[1].close;
            }
            else if(InpSwingTrailAnchor==SWING_TRAIL_H4_STRUCTURE)
            {
               double structure=LatestConfirmedStructureAnchor(InpSwingTrailTF,isBuy);
               if(structure>0.0) anchor=structure;
            }
            double trailSL=(isBuy ? anchor-atr*InpSwingTrailATRMultiple : anchor+atr*InpSwingTrailATRMultiple);
            if(InpSwingUseBreakEven)
            {
               double offset=InpSwingBreakEvenOffsetPips*InpCoursePipInPrice;
               double floorSL=(isBuy ? entry+offset : entry-offset);
               trailSL=(isBuy ? MathMax(trailSL,floorSL) : MathMin(trailSL,floorSL));
            }
            if((isBuy && trailSL>desiredSL) || (!isBuy && (desiredSL<=0.0 || trailSL<desiredSL)))
            {
               desiredSL=trailSL;
               improve=true;
            }
         }
      }
      if(!improve)
         continue;

      int brokerLevel=(g_stopsLevel>g_freezeLevel ? g_stopsLevel : g_freezeLevel);
      double minDistance=(double)(brokerLevel+2)*g_point;
      desiredSL=(isBuy ? MathMin(desiredSL,bid-minDistance) : MathMax(desiredSL,ask+minDistance));
      desiredSL=NormalizePrice(desiredSL);
      double minImprovement=MathMax(g_tickSize,InpSwingTrailStepPips*InpCoursePipInPrice);
      bool enough=(isBuy ? desiredSL>currentSL+minImprovement : currentSL<=0.0 || desiredSL<currentSL-minImprovement);
      if(!enough || desiredSL<=0.0)
         continue;
      trade.SetExpertMagicNumber(InpSwingMagic);
      if(!trade.PositionModify(ticket,desiredSL,currentTP))
      {
         PrintFormat("Swing SL修改失败：Ticket=%I64u Retcode=%d %s",ticket,trade.ResultRetcode(),trade.ResultRetcodeDescription());
         continue;
      }
      PrintFormat("Swing多持仓SL保护：Ticket=%I64u PositionID=%I64u SL=%s InitialRisk=%s",
                  ticket,identifier,DoubleToString(desiredSL,g_digits),DoubleToString(initialRisk,g_digits));
   }
}

double LatestConfirmedStructureAnchor(ENUM_TIMEFRAMES tf, bool forBuy)
{
   MqlRates rates[];
   if(!LoadRates(tf, InpPatternLookbackBars + InpPatternPivotDepth + 10, rates))
      return 0.0;
   int maxIndex = MathMin(InpPatternLookbackBars, ArraySize(rates) - InpPatternPivotDepth - 1);
   for(int i = InpPatternPivotDepth + 1; i <= maxIndex; i++)
   {
      if(forBuy && IsPivotLow(rates, i, InpPatternPivotDepth))
         return rates[i].low;
      if(!forBuy && IsPivotHigh(rates, i, InpPatternPivotDepth))
         return rates[i].high;
   }
   return 0.0;
}

double CurrentATR(ENUM_TIMEFRAMES tf)
{
   MqlRates rates[];
   if(!LoadRates(tf, InpATRPeriod + 5, rates))
      return 0.0;
   return CalcATR(rates, 1, InpATRPeriod);
}

//+------------------------------------------------------------------+
//| Swing support/resistance handbook logic                          |
//+------------------------------------------------------------------+
bool FindBestSwingSRZone(int dir, Zone &setupZone, SRZone &best)
{
   best.valid = false;
   best.score = -1.0e100;

   MqlRates rates[];
   int need = InpSwingLookbackBars + InpATRPeriod + InpSwingDepth + 20;
   if(!LoadRates(InpSwingSetupTF, need, rates))
      return false;

   int bars = ArraySize(rates);
   int maxIndex = MathMin(InpSwingLookbackBars,
                          bars - InpATRPeriod - InpSwingDepth - 3);
   if(maxIndex <= InpSwingDepth + 2)
      return false;

   bool nativeHighPivot = (dir < 0);
   for(int i = InpSwingDepth + 1; i <= maxIndex; i++)
   {
      bool isNativePivot = (nativeHighPivot ? IsPivotHigh(rates, i, InpSwingDepth)
                                            : IsPivotLow(rates, i, InpSwingDepth));
      if(isNativePivot)
      {
         SRZone candidate;
         if(BuildSwingSRCluster(rates, i, nativeHighPivot, dir, false, maxIndex, candidate))
            ConsiderSwingSRZone(candidate, setupZone, best);
      }

      if(InpSwingAllowRoleReversal)
      {
         bool roleHighPivot = !nativeHighPivot;
         bool isRolePivot = (roleHighPivot ? IsPivotHigh(rates, i, InpSwingDepth)
                                           : IsPivotLow(rates, i, InpSwingDepth));
         if(isRolePivot)
         {
            SRZone candidate;
            if(BuildSwingSRCluster(rates, i, roleHighPivot, dir, true, maxIndex, candidate))
               ConsiderSwingSRZone(candidate, setupZone, best);
         }
      }
   }

   return best.valid;
}

bool BuildSwingSRCluster(MqlRates &rates[],
                         int anchorIndex,
                         bool highPivot,
                         int dir,
                         bool roleReversal,
                         int maxIndex,
                         SRZone &z)
{
   double anchorATR = CalcATR(rates, anchorIndex, InpATRPeriod);
   if(anchorATR <= 0.0)
      return false;

   double anchor = (highPivot ? rates[anchorIndex].high : rates[anchorIndex].low);
   double clusterTolerance = MathMax(anchorATR * InpSwingSRZoneATR,
                                     5.0 * g_tickSize);
   double minLevel = DBL_MAX;
   double maxLevel = -DBL_MAX;
   double bounceScore = 0.0;
   int touches = 0;
   int latestIndex = maxIndex;
   int oldestIndex = 0;

   for(int i = InpSwingDepth + 1; i <= maxIndex; i++)
   {
      bool pivot = (highPivot ? IsPivotHigh(rates, i, InpSwingDepth)
                              : IsPivotLow(rates, i, InpSwingDepth));
      if(!pivot)
         continue;

      double level = (highPivot ? rates[i].high : rates[i].low);
      if(MathAbs(level - anchor) > clusterTolerance)
         continue;

      double pivotATR = CalcATR(rates, i, InpATRPeriod);
      double bounce = PivotBounceATR(rates, i, highPivot, pivotATR);
      if(bounce < InpSwingSRMinBounceATR)
         continue;

      touches++;
      minLevel = MathMin(minLevel, level);
      maxLevel = MathMax(maxLevel, level);
      bounceScore += bounce;
      latestIndex = MathMin(latestIndex, i);
      oldestIndex = MathMax(oldestIndex, i);
   }

   if(touches < InpSwingSRMinTouches)
      return false;

   double padding = clusterTolerance * 0.50;
   z.valid = true;
   z.dir = dir;
   z.bottom = minLevel - padding;
   z.top = maxLevel + padding;
   z.touches = touches;
   z.roleReversal = roleReversal;
   z.firstTouchTime = rates[oldestIndex].time;
   z.lastTouchTime = rates[latestIndex].time;

   if(MaxConsecutiveClosesInSRZone(rates, z, 40) > InpSwingSRMaxChopBars)
      return false;

   if(roleReversal && !HasSwingRoleReversalBreak(rates, z, latestIndex))
      return false;

   z.score = touches * 2.0 + bounceScore / touches + (roleReversal ? 1.0 : 0.0);
   return true;
}

double PivotBounceATR(MqlRates &rates[], int pivotIndex, bool highPivot, double atr)
{
   if(atr <= 0.0 || pivotIndex <= 1)
      return 0.0;

   int end = MathMax(1, pivotIndex - 8);
   double pivot = (highPivot ? rates[pivotIndex].high : rates[pivotIndex].low);
   double bestMove = 0.0;

   for(int i = pivotIndex - 1; i >= end; i--)
   {
      double move = (highPivot ? pivot - rates[i].low : rates[i].high - pivot);
      bestMove = MathMax(bestMove, move);
   }
   return bestMove / atr;
}

int MaxConsecutiveClosesInSRZone(MqlRates &rates[], SRZone &z, int recentBars)
{
   int limit = MathMin(recentBars, ArraySize(rates) - 1);
   int current = 0;
   int maximum = 0;

   for(int i = 1; i <= limit; i++)
   {
      if(rates[i].close >= z.bottom && rates[i].close <= z.top)
      {
         current++;
         maximum = MathMax(maximum, current);
      }
      else
      {
         current = 0;
      }
   }
   return maximum;
}

bool HasSwingRoleReversalBreak(MqlRates &rates[], SRZone &z, int latestTouchIndex)
{
   if(latestTouchIndex <= 1)
      return false;

   double breakBuffer = MathMax(g_tickSize, (z.top - z.bottom) * 0.10);
   for(int i = latestTouchIndex - 1; i >= 1; i--)
   {
      if(z.dir > 0 && rates[i].close > z.top + breakBuffer)
         return true;
      if(z.dir < 0 && rates[i].close < z.bottom - breakBuffer)
         return true;
   }
   return false;
}

void ConsiderSwingSRZone(SRZone &candidate, Zone &setupZone, SRZone &best)
{
   if(!candidate.valid)
      return;

   double gap = ZoneGap(setupZone.bottom, setupZone.top,
                        candidate.bottom, candidate.top);
   double maxGap = InpSwingConfluencePips * InpCoursePipInPrice;
   if(gap > maxGap)
      return;

   double normalizedGap = gap / MathMax(g_tickSize, maxGap + g_tickSize);
   candidate.score -= normalizedGap;
   if(!best.valid || candidate.score > best.score)
      best = candidate;
}

double ZoneGap(double bottomA, double topA, double bottomB, double topB)
{
   if(topA < bottomB)
      return bottomB - topA;
   if(topB < bottomA)
      return bottomA - topB;
   return 0.0;
}

void MergeSwingSetupZones(Zone &setupZone, SRZone &srZone)
{
   setupZone.bottom = MathMin(setupZone.bottom, srZone.bottom);
   setupZone.top = MathMax(setupZone.top, srZone.top);
   setupZone.touches = srZone.touches;
}

bool SwingZoneEntryConfirmed(MqlRates &rates[], Zone &zone, int dir)
{
   if(!zone.valid || !BarTouchesZone(rates[1], zone))
      return false;

   if(dir > 0)
   {
      if(rates[1].close < zone.bottom)
         return false;
      bool falseBreak = (rates[1].low < zone.bottom &&
                         rates[1].close > zone.bottom &&
                         rates[1].close > rates[1].open);
      return falseBreak || IsBullishReversal(rates, 1);
   }

   if(rates[1].close > zone.top)
      return false;
   bool falseBreak = (rates[1].high > zone.top &&
                      rates[1].close < zone.top &&
                      rates[1].close < rates[1].open);
   return falseBreak || IsBearishReversal(rates, 1);
}

//+------------------------------------------------------------------+
//| Intraday PDF Supply & Demand detection                           |
//+------------------------------------------------------------------+
bool FindBestIntradaySDZone(int dir, Zone &best)
{
   best.valid = false;
   best.score = -1.0e100;
   Zone rawBest;
   rawBest.valid=false;

   MqlRates rates[];
   int baseBars = (InpIntradayBaseBars < 2 ? 2 : InpIntradayBaseBars);
   int impulseBars = (InpIntradayImpulseBars < 2 ? 2 : InpIntradayImpulseBars);
   int extraBars = (baseBars > impulseBars ? baseBars : impulseBars);
   int need = InpIntradayLookbackBars + InpATRPeriod + extraBars + 20;
   if(!LoadRates(PERIOD_M30, need, rates))
      return false;

   int bars = ArraySize(rates);
   int maxIndex = MathMin(InpIntradayLookbackBars,
                          bars - InpATRPeriod - extraBars - 3);
   if(maxIndex < 5)
      return false;

   double bid = SymbolInfoDouble(g_symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(g_symbol, SYMBOL_ASK);
   double mid = (bid + ask) * 0.5;

   for(int i = 3; i <= maxIndex; i++)
   {
      double atr = CalcATR(rates, i, InpATRPeriod);
      if(atr <= 0.0)
         continue;

      Zone candidate;

      if(BuildLongWickZone(rates, i, dir, atr, candidate))
      {
         RecordRawZoneDetected(STRATEGY_INTRADAY,candidate,PERIOD_M30);
         ConsiderRawDetectedZone(candidate,rawBest);
         ConsiderIntradayZone(rates, candidate, atr, mid, best);
      }

      if(BuildBaseBreakZone(rates, i, dir, atr, baseBars, candidate))
      {
         RecordRawZoneDetected(STRATEGY_INTRADAY,candidate,PERIOD_M30);
         ConsiderRawDetectedZone(candidate,rawBest);
         ConsiderIntradayZone(rates, candidate, atr, mid, best);
      }

      if(BuildImpulsiveZone(rates, i, dir, atr, impulseBars, candidate))
      {
         RecordRawZoneDetected(STRATEGY_INTRADAY,candidate,PERIOD_M30);
         ConsiderRawDetectedZone(candidate,rawBest);
         ConsiderIntradayZone(rates, candidate, atr, mid, best);
      }
   }

   RecordRawZoneDetected(STRATEGY_INTRADAY,rawBest,PERIOD_M30);
   return best.valid;
}

void InitializeZone(Zone &z,
                    int dir,
                    int createdIndex,
                    datetime createdTime,
                    SDFormationType formation)
{
   z.id = "";
   z.symbol = g_symbol;
   z.timeframe = PERIOD_CURRENT;
   z.valid = true;
   z.dir = dir;
   z.top = 0.0;
   z.bottom = 0.0;
   z.proximal = 0.0;
   z.distal = 0.0;
   z.width = 0.0;
   z.createdIndex = createdIndex;
   z.createdTime = createdTime;
   z.departureTime = 0;
   z.firstTouchTime = 0;
   z.firstTouchBarTime = 0;
   z.firstTouchPrice = 0.0;
   z.touches = 0;
   z.score = 0.0;
   z.qualityScore = 0.0;
   z.formation = formation;
   z.state = ZONE_FORMING;
   z.broken = false;
   z.used = false;
   z.expired = false;
}

bool BuildLongWickZone(MqlRates &rates[],
                       int index,
                       int dir,
                       double atr,
                       Zone &z)
{
   double range = rates[index].high - rates[index].low;
   if(range <= g_tickSize || atr <= 0.0)
      return false;

   double bodyTop = MathMax(rates[index].open, rates[index].close);
   double bodyBottom = MathMin(rates[index].open, rates[index].close);
   double wick = (dir > 0 ? bodyBottom - rates[index].low
                          : rates[index].high - bodyTop);

   if(wick <= g_tickSize || wick / range < InpIntradayLongWickRatio)
      return false;

   InitializeZone(z, dir, index, rates[index].time, SD_FORMATION_LONG_WICK);
   if(dir > 0)
   {
      z.bottom = rates[index].low;
      z.top = bodyBottom;
   }
   else
   {
      z.bottom = bodyTop;
      z.top = rates[index].high;
   }

   z.score = wick / atr;
   return (z.top - z.bottom >= g_tickSize);
}

bool BuildBaseBreakZone(MqlRates &rates[],
                        int index,
                        int dir,
                        double atr,
                        int baseBars,
                        Zone &z)
{
   int bars = ArraySize(rates);
   if(index < 2 || index + baseBars - 1 >= bars)
      return false;

   double baseHigh = rates[index].high;
   double baseLow = rates[index].low;
   for(int j = index; j < index + baseBars; j++)
   {
      baseHigh = MathMax(baseHigh, rates[j].high);
      baseLow = MathMin(baseLow, rates[j].low);
   }

   double baseRange = baseHigh - baseLow;
   if(baseRange <= g_tickSize || baseRange > atr * InpIntradayBaseMaxATR)
      return false;

   MqlRates breakout = rates[index - 1];
   double breakoutBody = MathAbs(breakout.close - breakout.open);
   bool bullishBreak = (breakout.close > baseHigh &&
                        breakout.close > breakout.open &&
                        breakoutBody >= atr * 0.50);
   bool bearishBreak = (breakout.close < baseLow &&
                        breakout.close < breakout.open &&
                        breakoutBody >= atr * 0.50);

   if((dir > 0 && !bullishBreak) || (dir < 0 && !bearishBreak))
      return false;

   InitializeZone(z, dir, index, rates[index + baseBars - 1].time,
                  SD_FORMATION_BASE_BREAK);
   z.bottom = baseLow;
   z.top = baseHigh;
   z.score = breakoutBody / atr;
   return true;
}

bool BuildImpulsiveZone(MqlRates &rates[],
                        int index,
                        int dir,
                        double atr,
                        int impulseBars,
                        Zone &z)
{
   int newestIndex = index - impulseBars + 1;
   if(newestIndex < 1 || atr <= 0.0)
      return false;

   double totalBody = 0.0;
   for(int j = index; j >= newestIndex; j--)
   {
      double candleATR = CalcATR(rates, j, InpATRPeriod);
      if(candleATR <= 0.0)
         return false;

      double body = MathAbs(rates[j].close - rates[j].open);
      bool correctDirection = (dir > 0 ? rates[j].close > rates[j].open
                                       : rates[j].close < rates[j].open);
      if(!correctDirection || body < candleATR * InpIntradayImpulseBodyATR)
         return false;
      totalBody += body;
   }

   if(totalBody < atr * InpMinImpulseATR)
      return false;

   InitializeZone(z, dir, index, rates[index].time, SD_FORMATION_IMPULSIVE);
   if(dir > 0)
   {
      z.bottom = rates[index].low;
      z.top = MathMin(rates[index].open, rates[index].close);
   }
   else
   {
      z.bottom = MathMax(rates[index].open, rates[index].close);
      z.top = rates[index].high;
   }

   double minWidth = MathMax(g_tickSize, atr * 0.10);
   if(z.top - z.bottom < minWidth)
   {
      if(dir > 0)
         z.top = z.bottom + minWidth;
      else
         z.bottom = z.top - minWidth;
   }

   z.score = totalBody / atr;
   return true;
}

void ConsiderIntradayZone(MqlRates &rates[],
                          Zone &candidate,
                          double atr,
                          double currentPrice,
                          Zone &best)
{
   if(!candidate.valid || candidate.top <= candidate.bottom)
      return;

   double width = candidate.top - candidate.bottom;
   double widthATR=(atr>0.0 ? width/atr : 0.0);
   if(InpIntradayUseZoneWidthATRFilter &&
      (widthATR<InpIntradayMinZoneWidthATR || widthATR>InpIntradayMaxZoneWidthATR))
      return;
   if(!HasIntradayDeparture(rates, candidate, atr, width))
      return;

   candidate.touches = CountTouchesAfterCreation(rates, candidate, 1);
   if(candidate.touches > 0)
      return;

   // A fresh demand must still be below price; a fresh supply above price.
   if(candidate.dir > 0 && currentPrice <= candidate.top)
      return;
   if(candidate.dir < 0 && currentPrice >= candidate.bottom)
      return;

   double distance = DistanceToZone(currentPrice, candidate);
   double bestDistance = (best.valid ? DistanceToZone(currentPrice, best) : DBL_MAX);
   candidate.score += 1.0 / MathMax(1.0, (double)candidate.createdIndex);

   if(!best.valid ||
      distance < bestDistance - g_tickSize ||
      (MathAbs(distance - bestDistance) <= g_tickSize && candidate.score > best.score))
   {
      best = candidate;
   }
}

bool HasIntradayDeparture(MqlRates &rates[],
                          Zone &z,
                          double atr,
                          double zoneWidth)
{
   int start = z.createdIndex - 1;
   int end = MathMax(1, z.createdIndex - 8);
   if(start < 1)
      return false;

   double requiredMove = MathMax(CoursePipsToPrice(InpZoneDeparturePips),
                                 MathMax(atr * 0.50, zoneWidth * 0.50));
   for(int i = start; i >= end; i--)
   {
      if(z.dir > 0 && rates[i].high >= z.top + requiredMove)
         return true;
      if(z.dir < 0 && rates[i].low <= z.bottom - requiredMove)
         return true;
   }
   return false;
}

double IntradayEntryLevel(Zone &z)
{
   double width = z.top - z.bottom;
   double threshold = InpIntradayMidEntryPoints * InpIntradayPointInPrice;
   if(width > threshold)
      return NormalizePrice((z.top + z.bottom) * 0.5);

   return NormalizePrice(z.dir > 0 ? z.top : z.bottom);
}

string FormationTag(SDFormationType formation)
{
   if(formation == SD_FORMATION_LONG_WICK)
      return "WICK";
   if(formation == SD_FORMATION_BASE_BREAK)
      return "BASE";
   if(formation == SD_FORMATION_IMPULSIVE)
      return "IMPULSE";
   return "SD";
}

void PrintIntradayZone(string side, Zone &z)
{
   PrintFormat("Intraday %s armed. type=%s bottom=%s top=%s entry=%s",
               side,
               FormationTag(z.formation),
               DoubleToString(z.bottom, g_digits),
               DoubleToString(z.top, g_digits),
               DoubleToString(IntradayEntryLevel(z), g_digits));
}

//+------------------------------------------------------------------+
//| General zone detection                                           |
//+------------------------------------------------------------------+
bool LoadRates(ENUM_TIMEFRAMES tf, int barsNeeded, MqlRates &rates[])
{
   ArrayFree(rates);
   int copied = CopyRates(g_symbol, tf, 0, barsNeeded, rates);
   if(copied < barsNeeded)
      return false;

   ArraySetAsSeries(rates, true);
   return true;
}

bool FindBestSDZone(ENUM_TIMEFRAMES tf,
                    int dir,
                    int lookback,
                    double zoneSize,
                    bool freshOnly,
                    StrategyId strategy,
                    Zone &best)
{
   best.valid = false;
   best.score = -1.0e100;
   Zone rawBest;
   rawBest.valid=false;

   MqlRates rates[];
   int need = lookback + InpATRPeriod + 20;
   if(!LoadRates(tf, need, rates))
      return false;

   int bars = ArraySize(rates);
   int maxIndex = MathMin(lookback, bars - InpATRPeriod - 3);
   if(maxIndex < 5)
      return false;

   double bid = SymbolInfoDouble(g_symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(g_symbol, SYMBOL_ASK);
   double mid = (bid + ask) * 0.5;

   for(int i = 3; i <= maxIndex; i++)
   {
      double atr = CalcATR(rates, i, InpATRPeriod);
      if(atr <= 0.0)
         continue;

      double range = rates[i].high - rates[i].low;
      double body = MathAbs(rates[i].close - rates[i].open);

      if(range < atr * InpMinImpulseATR)
         continue;
      if(range <= 0.0 || body / range < InpMinImpulseBodyRatio)
         continue;

      bool bullishImpulse = (rates[i].close > rates[i].open);
      bool bearishImpulse = (rates[i].close < rates[i].open);

      Zone z;
      InitializeZone(z, dir, i, rates[i].time, SD_FORMATION_IMPULSIVE);

      if(dir > 0)
      {
         if(!bullishImpulse)
            continue;
         z.bottom = rates[i].low;
         z.top = z.bottom + zoneSize;
         if(rates[i].close <= z.top)
            continue;
      }
      else
      {
         if(!bearishImpulse)
            continue;
         z.top = rates[i].high;
         z.bottom = z.top - zoneSize;
         if(rates[i].close >= z.bottom)
            continue;
      }

      z.score=range/atr;
      RecordRawZoneDetected(strategy,z,tf);
      ConsiderRawDetectedZone(z,rawBest);

      if(!MovedAwayFromZone(rates, z, zoneSize))
         continue;

      z.touches = CountTouchesAfterCreation(rates, z, 2);
      if(freshOnly && z.touches > 0)
         continue;

      double dist = DistanceToZone(mid, z);
      double freshnessBonus = (z.touches == 0 ? 5.0 : 0.0);
      double impulseScore = range / atr;
      double distancePenalty = dist / MathMax(atr, zoneSize);
      z.score = freshnessBonus + impulseScore - distancePenalty;

      if(z.score > best.score)
         best = z;
   }

   RecordRawZoneDetected(strategy,rawBest,tf);
   return best.valid;
}

bool MovedAwayFromZone(MqlRates &rates[], Zone &z, double zoneSize)
{
   int start = z.createdIndex - 1;
   int end = MathMax(2, z.createdIndex - 8);

   if(start < 2)
      return false;

   if(z.dir > 0)
   {
      for(int i = start; i >= end; i--)
      {
         if(rates[i].high >= z.top + MathMax(zoneSize * 0.5,CoursePipsToPrice(InpZoneDeparturePips)))
            return true;
      }
   }
   else
   {
      for(int i = start; i >= end; i--)
      {
         if(rates[i].low <= z.bottom - MathMax(zoneSize * 0.5,CoursePipsToPrice(InpZoneDeparturePips)))
            return true;
      }
   }

   return false;
}

int CountTouchesAfterCreation(MqlRates &rates[], Zone &z, int minShift)
{
   int touches = 0;
   int start = z.createdIndex - 1 - InpZoneIgnoreBarsAfterMove;
   if(start < minShift)
      return 0;

   for(int i = start; i >= minShift; i--)
   {
      if(BarTouchesZone(rates[i], z))
         touches++;
   }
   return touches;
}

bool BarTouchesZone(MqlRates &bar, Zone &z)
{
   if(!z.valid)
      return false;
   return (bar.high >= z.bottom && bar.low <= z.top);
}

double DistanceToZone(double price, Zone &z)
{
   if(price >= z.bottom && price <= z.top)
      return 0.0;
   if(price < z.bottom)
      return z.bottom - price;
   return price - z.top;
}

bool ZoneEntryConfirmed(MqlRates &rates[], Zone &z, int dir, EntryConfirmMode mode)
{
   if(!z.valid)
      return false;

   if(mode == CONFIRM_TOUCH_ONLY)
   {
      double bid = SymbolInfoDouble(g_symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(g_symbol, SYMBOL_ASK);
      double mid = (bid + ask) * 0.5;
      return (mid >= z.bottom && mid <= z.top) || BarTouchesZone(rates[1], z);
   }

   if(!BarTouchesZone(rates[1], z))
      return false;

   if(dir > 0)
      return IsBullishReversal(rates, 1);
   return IsBearishReversal(rates, 1);
}

//+------------------------------------------------------------------+
//| Candle confirmation                                              |
//+------------------------------------------------------------------+
bool IsBullishReversal(MqlRates &rates[], int shift)
{
   if(ArraySize(rates) <= shift + 2)
      return false;

   double range = rates[shift].high - rates[shift].low;
   if(range <= 0.0)
      return false;

   double body = MathAbs(rates[shift].close - rates[shift].open);
   double lowerWick = MathMin(rates[shift].open, rates[shift].close) - rates[shift].low;
   double upperWick = rates[shift].high - MathMax(rates[shift].open, rates[shift].close);
   bool green = rates[shift].close > rates[shift].open;
   bool closeUpperHalf = rates[shift].close >= rates[shift].low + range * 0.55;

   bool bullishEngulf =
      green &&
      rates[shift + 1].close < rates[shift + 1].open &&
      rates[shift].close > rates[shift + 1].open &&
      rates[shift].open <= rates[shift + 1].close;

   bool hammer =
      lowerWick >= body * 2.0 &&
      upperWick <= MathMax(body * 1.5, range * 0.25) &&
      closeUpperHalf;

   bool strongClose =
      green &&
      body >= range * 0.55 &&
      closeUpperHalf;

   return (bullishEngulf || hammer || strongClose);
}

bool IsBearishReversal(MqlRates &rates[], int shift)
{
   if(ArraySize(rates) <= shift + 2)
      return false;

   double range = rates[shift].high - rates[shift].low;
   if(range <= 0.0)
      return false;

   double body = MathAbs(rates[shift].close - rates[shift].open);
   double upperWick = rates[shift].high - MathMax(rates[shift].open, rates[shift].close);
   double lowerWick = MathMin(rates[shift].open, rates[shift].close) - rates[shift].low;
   bool red = rates[shift].close < rates[shift].open;
   bool closeLowerHalf = rates[shift].close <= rates[shift].low + range * 0.45;

   bool bearishEngulf =
      red &&
      rates[shift + 1].close > rates[shift + 1].open &&
      rates[shift].close < rates[shift + 1].open &&
      rates[shift].open >= rates[shift + 1].close;

   bool shootingStar =
      upperWick >= body * 2.0 &&
      lowerWick <= MathMax(body * 1.5, range * 0.25) &&
      closeLowerHalf;

   bool strongClose =
      red &&
      body >= range * 0.55 &&
      closeLowerHalf;

   return (bearishEngulf || shootingStar || strongClose);
}

//+------------------------------------------------------------------+
//| Structure / BOS helpers                                          |
//+------------------------------------------------------------------+
int DetectSwingTrend(ENUM_TIMEFRAMES tf, int lookback, int depth)
{
   MqlRates rates[];
   if(!LoadRates(tf, lookback + depth + 20, rates))
      return 0;

   double hi1, hi2, lo1, lo2;
   int hiIdx1, hiIdx2, loIdx1, loIdx2;
   bool hasHighs = FindLastTwoPivots(rates, true, depth, hi1, hi2, hiIdx1, hiIdx2);
   bool hasLows = FindLastTwoPivots(rates, false, depth, lo1, lo2, loIdx1, loIdx2);

   if(hasHighs && hasLows)
   {
      bool hh = (hi1 > hi2);
      bool hl = (lo1 > lo2);
      bool lh = (hi1 < hi2);
      bool ll = (lo1 < lo2);

      if(hh && hl)
         return 1;
      if(lh && ll)
         return -1;

      // BOS logic: close beyond latest structure protection.
      if(rates[1].close > hi1 && !hh)
         return 1;
      if(rates[1].close < lo1 && !ll)
         return -1;
   }

   return MovingAverageTrend(rates);
}

bool FindLastTwoPivots(MqlRates &rates[],
                       bool highPivot,
                       int depth,
                       double &latest,
                       double &previous,
                       int &latestIndex,
                       int &previousIndex)
{
   int bars = ArraySize(rates);
   int found = 0;

   for(int i = depth + 1; i < bars - depth; i++)
   {
      bool isPivot = (highPivot ? IsPivotHigh(rates, i, depth) : IsPivotLow(rates, i, depth));
      if(!isPivot)
         continue;

      double price = (highPivot ? rates[i].high : rates[i].low);

      if(found == 0)
      {
         latest = price;
         latestIndex = i;
         found++;
      }
      else
      {
         previous = price;
         previousIndex = i;
         return true;
      }
   }

   return false;
}

bool IsPivotHigh(MqlRates &rates[], int index, int depth)
{
   double h = rates[index].high;
   for(int j = 1; j <= depth; j++)
   {
      if(rates[index - j].high >= h)
         return false;
      if(rates[index + j].high > h)
         return false;
   }
   return true;
}

bool IsPivotLow(MqlRates &rates[], int index, int depth)
{
   double l = rates[index].low;
   for(int j = 1; j <= depth; j++)
   {
      if(rates[index - j].low <= l)
         return false;
      if(rates[index + j].low < l)
         return false;
   }
   return true;
}

int MovingAverageTrend(MqlRates &rates[])
{
   double fast = AverageClose(rates, 1, 20);
   double slow = AverageClose(rates, 1, 50);
   double close = rates[1].close;

   if(fast <= 0.0 || slow <= 0.0)
      return 0;

   if(close > fast && fast > slow)
      return 1;
   if(close < fast && fast < slow)
      return -1;
   return 0;
}

double AverageClose(MqlRates &rates[], int shift, int period)
{
   if(ArraySize(rates) <= shift + period)
      return 0.0;

   double sum = 0.0;
   for(int i = shift; i < shift + period; i++)
      sum += rates[i].close;
   return sum / period;
}

double FindNextPivotTarget(ENUM_TIMEFRAMES tf, int dir, double entry)
{
   MqlRates rates[];
   if(!LoadRates(tf, InpSwingLookbackBars + InpSwingDepth + 20, rates))
      return 0.0;

   int bars = ArraySize(rates);
   double best = 0.0;

   for(int i = InpSwingDepth + 1; i < bars - InpSwingDepth; i++)
   {
      if(dir > 0 && IsPivotHigh(rates, i, InpSwingDepth))
      {
         double level = rates[i].high;
         if(level > entry && (best == 0.0 || level < best))
            best = level;
      }
      else if(dir < 0 && IsPivotLow(rates, i, InpSwingDepth))
      {
         double level = rates[i].low;
         if(level < entry && (best == 0.0 || level > best))
            best = level;
      }
   }

   return best;
}

//+------------------------------------------------------------------+
//| ATR and history helpers                                          |
//+------------------------------------------------------------------+
double CalcATR(MqlRates &rates[], int shift, int period)
{
   if(ArraySize(rates) <= shift + period + 1)
      return 0.0;

   double sum = 0.0;
   for(int i = shift; i < shift + period; i++)
   {
      double highLow = rates[i].high - rates[i].low;
      double highClose = MathAbs(rates[i].high - rates[i + 1].close);
      double lowClose = MathAbs(rates[i].low - rates[i + 1].close);
      sum += MathMax(highLow, MathMax(highClose, lowClose));
   }
   return sum / period;
}

datetime DayStart(datetime t)
{
   MqlDateTime dt;
   TimeToStruct(t, dt);
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   return StructToTime(dt);
}

int CountEntryDealsToday(long magic)
{
   datetime from = DayStart(TimeCurrent());
   datetime to = TimeCurrent();
   if(!HistorySelect(from, to))
      return 0;

   int count = 0;
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong deal = HistoryDealGetTicket(i);
      if(deal == 0)
         continue;

      string sym = HistoryDealGetString(deal, DEAL_SYMBOL);
      long dealMagic = (long)HistoryDealGetInteger(deal, DEAL_MAGIC);
      ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal, DEAL_ENTRY);

      if(sym == g_symbol && dealMagic == magic && (entry == DEAL_ENTRY_IN || entry == DEAL_ENTRY_INOUT))
         count++;
   }

   return count;
}

int CurrentClosedTradeStreak(long magic, ulong &lastDealTicket)
{
   lastDealTicket = 0;

   datetime from = TimeCurrent() - 86400 * 90;
   datetime to = TimeCurrent();
   if(!HistorySelect(from, to))
      return 0;

   int total = HistoryDealsTotal();
   int sign = 0;
   int streak = 0;

   for(int i = total - 1; i >= 0; i--)
   {
      ulong deal = HistoryDealGetTicket(i);
      if(deal == 0)
         continue;

      string sym = HistoryDealGetString(deal, DEAL_SYMBOL);
      long dealMagic = (long)HistoryDealGetInteger(deal, DEAL_MAGIC);
      ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal, DEAL_ENTRY);

      if(sym != g_symbol || dealMagic != magic)
         continue;
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT && entry != DEAL_ENTRY_OUT_BY)
         continue;

      double profit = HistoryDealGetDouble(deal, DEAL_PROFIT)
                    + HistoryDealGetDouble(deal, DEAL_SWAP)
                    + HistoryDealGetDouble(deal, DEAL_COMMISSION);

      if(MathAbs(profit) < 0.000001)
         continue;

      int result = (profit > 0.0 ? 1 : -1);
      if(lastDealTicket == 0)
         lastDealTicket = deal;

      if(sign == 0)
      {
         sign = result;
         streak = result;
      }
      else if(result == sign)
      {
         streak += result;
      }
      else
      {
         break;
      }
   }

   return streak;
}

void UpdateScalpPause(long magic)
{
   if(TimeCurrent() < g_scalpPauseUntil)
      return;

   ulong lastDeal = 0;
   int streak = CurrentClosedTradeStreak(magic, lastDeal);
   if(lastDeal == 0 || lastDeal == g_lastScalpPauseDeal)
      return;

   if(MathAbs(streak) >= InpScalpPauseAfterStreak)
   {
      g_scalpPauseUntil = TimeCurrent() + InpScalpPauseHours * 3600;
      g_lastScalpPauseDeal = lastDeal;
      PrintFormat("Scalping pause activated until %s after streak %d",
                  TimeToString(g_scalpPauseUntil, TIME_DATE | TIME_MINUTES), streak);
   }
}

//+------------------------------------------------------------------+
//| Drawing                                                          |
//+------------------------------------------------------------------+
void DrawZone(string label, Zone &z, color clr)
{
   if(!InpDrawZones || !z.valid)
      return;

   string name = "GSM_" + label + "_" + IntegerToString((int)z.createdTime);
   datetime t1 = z.createdTime;
   datetime t2 = TimeCurrent() + PeriodSeconds(_Period) * 80;

   if(ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);

   if(!ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, z.top, t2, z.bottom))
      return;

   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_FILL, true);
}

void DrawSRZone(string label, SRZone &z, color clr)
{
   if(!InpDrawZones || !z.valid)
      return;

   string suffix = (z.roleReversal ? "_ROLE_" : "_MAJOR_");
   string name = "GSM_" + label + suffix + IntegerToString((int)z.lastTouchTime);
   datetime t1 = z.firstTouchTime;
   datetime t2 = TimeCurrent() + PeriodSeconds(InpSwingSetupTF) * 80;

   if(ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);

   if(!ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, z.top, t2, z.bottom))
      return;

   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_FILL, false);
}

//+------------------------------------------------------------------+
//| Unified broker conversion, runtime, and safety helpers           |
//+------------------------------------------------------------------+
double CoursePipsToPrice(double pips)
{
   return pips * InpCoursePipInPrice;
}

double PTToPrice(double points)
{
   return points * InpIntradayPointInPrice;
}

double NormalizePriceToTickSize(double price)
{
   return NormalizePrice(price);
}

double NormalizeLotToStep(double lots)
{
   return NormalizeVolume(lots);
}

long StrategyMagic(StrategyId strategy)
{
   if(strategy == STRATEGY_SCALPING)
      return InpScalpMagic;
   if(strategy == STRATEGY_INTRADAY)
      return InpIntradayMagic;
   return InpSwingMagic;
}

void ResetPendingVolumeAudit(int strategy)
{
   if(strategy<0 || strategy>2)
      return;
   g_pendingCalculatedVolume[strategy]=0.0;
   g_pendingFinalVolume[strategy]=0.0;
   g_pendingActualSLRiskMoney[strategy]=0.0;
   g_pendingActualSLRiskPercent[strategy]=0.0;
   g_pendingForcedMinimumLot[strategy]=false;
   g_pendingConfidence100Boost[strategy]=false;
}

void InitializeRuntime(StrategyId strategy, long magic, string name)
{
   int s = (int)strategy;
   g_runtime[s].magic = magic;
   g_runtime[s].name = name;
   g_runtime[s].status = "等待信号";
   g_runtime[s].rejectReason = "";
   g_runtime[s].zoneId = "-";
   g_runtime[s].clusterId = "-";
   g_runtime[s].zoneState = "-";
   g_runtime[s].candleName = "-";
   g_runtime[s].candleStrength = "-";
   g_runtime[s].chartPattern = "-";
   g_runtime[s].indicatorState = "EMA OFF / RSI OFF";
   g_runtime[s].macdState = "MACD OFF";
   g_runtime[s].bollingerState = "BOLLINGER OFF";
   g_runtime[s].confidence = 0.0;
   g_runtime[s].lastEvaluatedBar = 0;
   g_runtime[s].lastProcessedCandle = 0;
   g_runtime[s].todayTrades = 0;
   g_runtime[s].winStreak = 0;
   g_runtime[s].lossStreak = 0;
   g_runtime[s].pauseUntil = 0;
   g_runtime[s].tradeLock = false;
   g_pendingZoneId[s]="";
   g_pendingClusterId[s]="";
   g_pendingRiskPercent[s]=0.0;
   ResetPendingVolumeAudit(s);
   ResetScore(g_runtime[s].score);
   ResetCandleSignal(g_runtime[s].candle);
   ResetChartPattern(g_runtime[s].pattern);
   ResetSignalFunnel(g_funnel[s]);
   ResetIndicatorSnapshot(g_indicatorSnapshot[s]);
   ResetMACDSnapshot(g_macdSnapshot[s]);
   ResetBollingerSnapshot(g_bollingerSnapshot[s]);
}

void ResetSignalFunnel(SignalFunnel &funnel)
{
   funnel.zonesDetected=0;
   funnel.zonesDeparted=0;
   funnel.firstTouches=0;
   funnel.candlePatternsDetected=0;
   funnel.chartPatternsDetected=0;
   funnel.hardSOPPassed=0;
   funnel.confidencePassed=0;
   funnel.globalGatePassed=0;
   funnel.ordersRequested=0;
   funnel.ordersFilled=0;
   funnel.ordersRejected=0;
   funnel.emaPassed=0;
   funnel.emaRejected=0;
   funnel.rsiPassed=0;
   funnel.rsiRejected=0;
   funnel.macdEvaluated=0;
   funnel.macdPassed=0;
   funnel.confidenceRejected=0;
   funnel.sessionRejected=0;
   funnel.spreadRejected=0;
   funnel.positionLimitRejected=0;
   funnel.riskRejected=0;
   funnel.marginRejected=0;
   funnel.minimumLotRiskRejected=0;
   funnel.totalRiskRejected=0;
   funnel.insufficientFundsRejected=0;
   funnel.indicatorDataWaits=0;
   funnel.macdDataWaits=0;
   funnel.bollingerEvaluated=0;
   funnel.bollingerPassed=0;
   funnel.bollingerDataWaits=0;
   funnel.duplicateZoneRejected=0;
   funnel.duplicateClusterRejected=0;
   funnel.d1DirectionPassed=0;
   funnel.h4DirectionPassed=0;
   funnel.h4ZonesFound=0;
   funnel.srConfluencePassed=0;
   funnel.m30Touches=0;
   funnel.m30Confirmations=0;
   funnel.lastFilledOrder=0;
   funnel.lastCandleCounted=0;
   funnel.lastPatternIdCounted="";
   funnel.lastDemandDetectedId="";
   funnel.lastSupplyDetectedId="";
}

void ResetScore(ScoreBreakdown &score)
{
   score.part1 = 0.0;
   score.part2 = 0.0;
   score.part3 = 0.0;
   score.part4 = 0.0;
   score.part5 = 0.0;
   score.part6 = 0.0;
   score.part7 = 0.0;
   score.part8 = 0.0;
   score.total = 0.0;
   score.explanation = "";
}

void ResetCandleSignal(CandleSignal &signal)
{
   signal.valid = false;
   signal.type = CANDLE_NONE;
   signal.direction = 0;
   signal.strength = CANDLE_STRENGTH_NONE;
   signal.englishName = "None";
   signal.chineseName = "无";
   signal.timeframe = PERIOD_CURRENT;
   signal.candleTime = 0;
   signal.volumeRatio = 0.0;
   signal.quality = 0.0;
}

void ResetChartPattern(ChartPatternSignal &pattern)
{
   pattern.valid = false;
   pattern.id = "";
   pattern.type = CHART_PATTERN_NONE;
   pattern.timeframe = PERIOD_CURRENT;
   pattern.direction = 0;
   pattern.startTime = 0;
   pattern.endTime = 0;
   for(int i = 0; i < 6; i++)
      pattern.keyPrices[i] = 0.0;
   pattern.neckline = 0.0;
   pattern.breakoutPrice = 0.0;
   pattern.retestPrice = 0.0;
   pattern.invalidationPrice = 0.0;
   pattern.projectedTarget = 0.0;
   pattern.state = PATTERN_FORMING;
   pattern.score = 0.0;
   pattern.englishName = "None";
   pattern.chineseName = "无";
}

int CurrentSpreadPoints()
{
   if(g_point <= 0.0 || g_tick.ask <= 0.0 || g_tick.bid <= 0.0)
      return (int)SymbolInfoInteger(g_symbol, SYMBOL_SPREAD);
   return (int)MathRound((g_tick.ask - g_tick.bid) / g_point);
}

bool PassStrategyFilters(StrategyId strategy, string &reason)
{
   if(!CapitalLadderAllows(strategy))
   {
      reason="资金阶梯禁止本策略新仓；继续记录信号";
      g_funnel[(int)strategy].riskRejected++;
      double minimumLoss=0.0,riskBudget=0.0;
      if(MinimumLotExceedsStrategyBudget(strategy,minimumLoss,riskBudget))
      {
         g_funnel[(int)strategy].minimumLotRiskRejected++;
         PrintFormat("RISK_REJECT|SOP=%s|Type=MINIMUM_LOT_EXCEEDS_RISK|Equity=%.2f|MinLotLoss=%.2f|RiskBudget=%.2f|MinLot=%s",
                     g_runtime[(int)strategy].name,AccountInfoDouble(ACCOUNT_EQUITY),minimumLoss,riskBudget,
                     DoubleToString(g_volumeMin,VolumeDigits()));
      }
      PrintFormat("CAPITAL_LADDER_REJECT|SOP=%s|Equity=%.2f|Tier=%s|Reason=%s",
                  g_runtime[(int)strategy].name,AccountInfoDouble(ACCOUNT_EQUITY),g_capitalTierName,reason);
      return false;
   }
   if(!PassCommonFiltersWithReason(reason))
   {
      int s=(int)strategy;
      if(StringFind(reason,"点差")>=0) g_funnel[s].spreadRejected++;
      else if(StringFind(reason,"风险")>=0) g_funnel[s].riskRejected++;
      else if(StringFind(reason,"保证金")>=0) g_funnel[s].marginRejected++;
      else if(StringFind(reason,"时段")>=0 || StringFind(reason,"Session")>=0 || StringFind(reason,"周末")>=0) g_funnel[s].sessionRejected++;
      return false;
   }

   if((strategy==STRATEGY_SCALPING && InpScalpManualNewsLock) ||
      (strategy==STRATEGY_INTRADAY && InpIntradayManualNewsLock) ||
      (strategy==STRATEGY_SWING && InpSwingManualNewsLock))
   {
      reason="本策略Manual News Lock已开启";
      return false;
   }

   int startHour = InpScalpStartHour;
   int endHour = InpScalpEndHour;
   int maxSpread = InpScalpMaxSpreadPoints;
   int maxTrades = InpScalpMaxTradesPerDay;
   int maxPositions = InpScalpMaxOpenPositions;

   if(strategy == STRATEGY_INTRADAY)
   {
      startHour = InpIntradayStartHour;
      endHour = InpIntradayEndHour;
      maxSpread = InpIntradayMaxSpreadPoints;
      maxTrades = InpIntradayMaxTradesPerDay;
      maxPositions = InpIntradayMaxOpenPositions;
   }
   else if(strategy == STRATEGY_SWING)
   {
      startHour = InpSwingStartHour;
      endHour = InpSwingEndHour;
      maxSpread = InpSwingMaxSpreadPoints;
      maxTrades = InpSwingMaxTradesPerDay;
      maxPositions = InpSwingMaxOpenPositions;
   }

   if(!IsTradingHourRange(startHour, endHour))
   {
      reason = "本策略不在交易时段";
      g_funnel[(int)strategy].sessionRejected++;
      return false;
   }
   if(maxSpread > 0 && CurrentSpreadPoints() > maxSpread)
   {
      reason = "本策略点差超过限制";
      g_funnel[(int)strategy].spreadRejected++;
      return false;
   }
   maxPositions=EffectiveStrategyMaxPositions(strategy,maxPositions);
   int totalMaximum=EffectiveTotalMaxPositions();
   if(CountTotalStrategyOpenPositions()>=totalMaximum)
   {
      reason=StringFormat("三套策略总持仓数量达到资金阶梯上限%d",totalMaximum);
      g_funnel[(int)strategy].positionLimitRejected++;
      return false;
   }
   if(CountOpenPositionsByMagic(StrategyMagic(strategy)) >= maxPositions)
   {
      reason = "本策略持仓数量达到上限";
      g_funnel[(int)strategy].positionLimitRejected++;
      return false;
   }
   if(maxTrades>0 && g_runtime[(int)strategy].todayTrades >= maxTrades)
   {
      reason = "本策略今日交易次数达到上限";
      return false;
   }
   if(g_runtime[(int)strategy].pauseUntil > TimeCurrent())
   {
      reason = "本策略连续胜负暂停中";
      return false;
   }
   return true;
}

int CountTotalStrategyOpenPositions()
{
   int count=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=g_symbol)
         continue;
      long magic=(long)PositionGetInteger(POSITION_MAGIC);
      if(magic==InpScalpMagic || magic==InpIntradayMagic || magic==InpSwingMagic)
         count++;
   }
   return count;
}

int CountOpenPositionsByMagic(long magic)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) == g_symbol &&
         (long)PositionGetInteger(POSITION_MAGIC) == magic)
         count++;
   }
   return count;
}

double CalculateAccountOpenRiskPercent()
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity <= 0.0)
      return 100.0;

   double totalRisk = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;

      string symbol = PositionGetString(POSITION_SYMBOL);
      double sl = PositionGetDouble(POSITION_SL);
      double open = PositionGetDouble(POSITION_PRICE_OPEN);
      double volume = PositionGetDouble(POSITION_VOLUME);
      if(sl <= 0.0 || open <= 0.0 || volume <= 0.0)
         continue;

      ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      ENUM_ORDER_TYPE orderType = (positionType == POSITION_TYPE_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
      double result = 0.0;
      if(OrderCalcProfit(orderType, symbol, volume, open, sl, result) && result < 0.0)
         totalRisk += -result;
   }
   return totalRisk / equity * 100.0;
}

//+------------------------------------------------------------------+
//| Stable Supply/Demand state machine                               |
//+------------------------------------------------------------------+
string TimeframeTag(ENUM_TIMEFRAMES tf)
{
   return EnumToString(tf);
}

string BuildZoneID(Zone &zone, ENUM_TIMEFRAMES tf)
{
   return StringFormat("%s_%s_%s_%s_%I64d",
                       g_symbol,
                       TimeframeTag(tf),
                       (zone.dir > 0 ? "DEMAND" : "SUPPLY"),
                       FormationTag(zone.formation),
                       (long)zone.createdTime);
}

ENUM_TIMEFRAMES StrategyClusterTimeframe(StrategyId strategy)
{
   if(strategy==STRATEGY_SCALPING) return PERIOD_M5;
   if(strategy==STRATEGY_INTRADAY) return PERIOD_M30;
   return InpSwingEntryTF;
}

int StrategyClusterCooldownBars(StrategyId strategy)
{
   if(strategy==STRATEGY_SCALPING) return InpScalpClusterCooldownBars;
   if(strategy==STRATEGY_INTRADAY) return InpIntradayClusterCooldownBars;
   return InpSwingClusterCooldownBars;
}

string BuildOpportunityClusterID(StrategyId strategy,Zone &zone)
{
   if(!InpEnableOpportunityClusters)
      return "CLUSTER_OFF";
   ENUM_TIMEFRAMES tf=StrategyClusterTimeframe(strategy);
   double atr=CurrentATR(tf);
   double bucketSize=MathMax(g_tickSize,atr*MathMax(0.10,InpClusterDistanceATR));
   double center=(zone.top+zone.bottom)*0.5;
   long priceBucket=(long)MathFloor(center/bucketSize+0.5);
   int bars=MathMax(2,StrategyClusterCooldownBars(strategy));
   int tfSeconds=PeriodSeconds(tf);
   if(tfSeconds<1) tfSeconds=1;
   long seconds=(long)tfSeconds*MathMax(2,bars/2);
   long timeBucket=(long)zone.createdTime/seconds;
   return StringFormat("C%d_%s_%d_%I64d_%I64d",(int)strategy,TimeframeTag(tf),zone.dir,priceBucket,timeBucket);
}

string ClusterStateKey(StrategyId strategy,string clusterId)
{
   return StringFormat("GSM280_CL_%I64d_%u_%d_%08X",(long)AccountInfoInteger(ACCOUNT_LOGIN),
                       HashText(g_symbol),(int)strategy,HashText(clusterId));
}

bool ClusterCooldownActive(StrategyId strategy,string clusterId,datetime &lastFill)
{
   lastFill=0;
   if(!InpEnableOpportunityClusters || clusterId=="" || clusterId=="CLUSTER_OFF")
      return false;
   string scopedId=StringFormat("%d|%s",(int)strategy,clusterId);
   for(int i=ArraySize(g_filledClusterIds)-1;i>=0;i--)
   {
      if(g_filledClusterIds[i]==scopedId)
      {
         lastFill=g_filledClusterTimes[i];
         break;
      }
   }
   if(lastFill<=0 && !MQLInfoInteger(MQL_TESTER))
   {
      string key=ClusterStateKey(strategy,clusterId);
      if(GlobalVariableCheck(key))
         lastFill=(datetime)GlobalVariableGet(key);
   }
   if(lastFill<=0)
      return false;
   int tfSeconds=PeriodSeconds(StrategyClusterTimeframe(strategy));
   if(tfSeconds<1) tfSeconds=1;
   long cooldownSeconds=(long)tfSeconds*MathMax(1,StrategyClusterCooldownBars(strategy));
   datetime now=TimeCurrent();
   return (now>=lastFill && now-lastFill<cooldownSeconds);
}

void MarkClusterFilled(StrategyId strategy,string clusterId)
{
   if(!InpEnableOpportunityClusters || clusterId=="" || clusterId=="CLUSTER_OFF")
      return;
   string scopedId=StringFormat("%d|%s",(int)strategy,clusterId);
   datetime now=TimeCurrent();
   int index=-1;
   for(int i=ArraySize(g_filledClusterIds)-1;i>=0;i--)
   {
      if(g_filledClusterIds[i]==scopedId)
      {
         index=i;
         break;
      }
   }
   if(index<0)
   {
      index=ArraySize(g_filledClusterIds);
      ArrayResize(g_filledClusterIds,index+1);
      ArrayResize(g_filledClusterTimes,index+1);
      g_filledClusterIds[index]=scopedId;
   }
   g_filledClusterTimes[index]=now;
   if(!MQLInfoInteger(MQL_TESTER))
      GlobalVariableSet(ClusterStateKey(strategy,clusterId),(double)now);
   PrintFormat("CLUSTER_FILLED|SOP=%s|ClusterID=%s|CooldownBars=%d|Time=%s",
               g_runtime[(int)strategy].name,clusterId,StrategyClusterCooldownBars(strategy),
               TimeToString(now,TIME_DATE|TIME_SECONDS));
}

void ConsiderRawDetectedZone(Zone &candidate,Zone &best)
{
   if(!candidate.valid || candidate.top<=candidate.bottom)
      return;
   if(!best.valid || candidate.createdIndex<best.createdIndex ||
      (candidate.createdIndex==best.createdIndex && candidate.score>best.score))
      best=candidate;
}

void RecordRawZoneDetected(StrategyId strategy,Zone &zone,ENUM_TIMEFRAMES tf)
{
   if(!zone.valid)
      return;
   int s=(int)strategy;
   string id=BuildZoneID(zone,tf);
   if(!RememberUniqueZoneHash(g_detectedZoneHashes,id))
      return;
   if(zone.dir>0) g_funnel[s].lastDemandDetectedId=id;
   else           g_funnel[s].lastSupplyDetectedId=id;
   g_funnel[s].zonesDetected++;
   PrintFormat("漏斗ZonesDetected：Strategy=%s ZoneID=%s State=FORMING",g_runtime[s].name,id);
}

void FinalizeZoneMetadata(Zone &zone, ENUM_TIMEFRAMES tf)
{
   zone.symbol = g_symbol;
   zone.timeframe = tf;
   zone.proximal = (zone.dir > 0 ? zone.top : zone.bottom);
   zone.distal = (zone.dir > 0 ? zone.bottom : zone.top);
   zone.width = zone.top - zone.bottom;
   zone.qualityScore = MathMax(0.0, MathMin(100.0, 45.0 + zone.score * 15.0));
   zone.id = BuildZoneID(zone, tf);
   zone.valid = true;
   zone.state = ZONE_FRESH;
   zone.departureTime = 0;
   zone.broken = false;
   zone.used = false;
   zone.expired = false;
}

bool TransitionZoneToDeparted(Zone &zone, datetime departureTime)
{
   if(!zone.valid || zone.state!=ZONE_FRESH)
      return false;
   zone.state=ZONE_DEPARTED;
   zone.departureTime=departureTime;
   return true;
}

uint HashText(string value)
{
   uint hash = 2166136261;
   int length = StringLen(value);
   for(int i = 0; i < length; i++)
   {
      hash ^= (uint)StringGetCharacter(value, i);
      hash *= 16777619;
   }
   return hash;
}

bool RememberUniqueZoneHash(uint &hashes[],string zoneId)
{
   if(zoneId=="")
      return false;
   uint hash=HashText(zoneId);
   int count=ArraySize(hashes);
   if(count>0)
   {
      int found=ArrayBsearch(hashes,hash);
      if(found>=0 && found<count && hashes[found]==hash)
         return false;
   }
   if(ArrayResize(hashes,count+1)!=count+1)
   {
      PrintFormat("内部错误：无法扩展ZoneID去重表，ZoneID=%s",zoneId);
      return false;
   }
   hashes[count]=hash;
   ArraySort(hashes);
   return true;
}

bool RecordZoneDeparted(StrategyId strategy,Zone &zone)
{
   if(!RememberUniqueZoneHash(g_departedZoneHashes,zone.id))
   {
      if(RememberUniqueZoneHash(g_reportedDuplicateZoneHashes,zone.id))
         PrintFormat("重复ZoneID已阻止重新武装：Strategy=%s ZoneID=%s",g_runtime[(int)strategy].name,zone.id);
      return false;
   }
   g_funnel[(int)strategy].zonesDeparted++;
   return true;
}

string ZoneHistoryKey(string zoneId)
{
   return StringFormat("GSM2_USED_%I64d_%u", (long)AccountInfoInteger(ACCOUNT_LOGIN), HashText(zoneId));
}

bool ZoneWasPermanentlyUsed(string zoneId)
{
   if(MQLInfoInteger(MQL_TESTER))
      return false;
   if(zoneId == "")
      return false;
   return GlobalVariableCheck(ZoneHistoryKey(zoneId));
}

void MarkZoneUsed(Zone &zone, string reason)
{
   if(!zone.valid || zone.used)
      return;
   zone.used = true;
   zone.state = ZONE_USED;
   if(!MQLInfoInteger(MQL_TESTER))
      GlobalVariableSet(ZoneHistoryKey(zone.id), (double)TimeCurrent());
   PrintFormat("区域已USED：ZoneID=%s TouchTime=%s TouchPrice=%s 原因=%s",
               zone.id,
               TimeToString(zone.firstTouchTime, TIME_DATE|TIME_SECONDS),
               DoubleToString(zone.firstTouchPrice, g_digits),
               reason);
}

void ArmZoneIfNew(Zone &candidate, Zone &active, ENUM_TIMEFRAMES tf, StrategyId strategy, string label)
{
   if(!candidate.valid)
      return;
   FinalizeZoneMetadata(candidate, tf);
   if(ZoneWasPermanentlyUsed(candidate.id))
   {
      g_funnel[(int)strategy].duplicateZoneRejected++;
      return;
   }

   if(active.valid && !active.used && !active.broken && !active.expired)
      return;

   if(!TransitionZoneToDeparted(candidate,TimeCurrent()))
   {
      PrintFormat("%s区域状态错误：ZoneID=%s 无法由FRESH进入DEPARTED",label,candidate.id);
      return;
   }
   if(!RecordZoneDeparted(strategy,candidate))
   {
      g_funnel[(int)strategy].duplicateZoneRejected++;
      return;
   }
   active = candidate;
   PrintFormat("%s区域已固定：ZoneID=%s State=DEPARTED Proximal=%s Distal=%s Width=%s Quality=%.1f",
               label, active.id,
               DoubleToString(active.proximal, g_digits),
               DoubleToString(active.distal, g_digits),
               DoubleToString(active.width, g_digits),
               active.qualityScore);
}

void UpdateZoneOnClosedBar(Zone &zone, ENUM_TIMEFRAMES tf)
{
   if(!zone.valid || zone.used || zone.broken || zone.expired)
      return;

   MqlRates rates[];
   if(!LoadRates(tf, 4, rates))
      return;

   double buffer = CoursePipsToPrice(InpZoneBreakBufferPips);
   bool broken = (zone.dir > 0 ? rates[1].close < zone.distal - buffer
                               : rates[1].close > zone.distal + buffer);
   if(broken)
   {
      zone.broken = true;
      zone.valid = false;
      zone.state = ZONE_BROKEN;
      PrintFormat("区域BROKEN：ZoneID=%s Close=%s", zone.id, DoubleToString(rates[1].close, g_digits));
      return;
   }

   int age = iBarShift(g_symbol, tf, zone.createdTime, false);
   int expiryBars=(tf==InpSwingSetupTF ? InpSwingZoneExpiryBars : InpZoneExpiryBars);
   if(age > expiryBars)
   {
      zone.expired = true;
      zone.valid = false;
      zone.state = ZONE_EXPIRED;
      PrintFormat("区域EXPIRED：ZoneID=%s AgeBars=%d", zone.id, age);
   }
}

void UpdateSupplyDemandStates(bool newM5, bool newM30, bool newSwingEntry)
{
   if(newM5)
   {
      UpdateZoneOnClosedBar(g_scalpDemand, PERIOD_M5);
      UpdateZoneOnClosedBar(g_scalpSupply, PERIOD_M5);
      if(!g_scalpDemand.valid || g_scalpDemand.used || g_scalpDemand.broken || g_scalpDemand.expired)
      {
         Zone candidate;
         if(FindBestSDZone(PERIOD_M5, 1, InpScalpLookbackBars, CoursePipsToPrice(InpScalpZonePips), true, STRATEGY_SCALPING, candidate))
            ArmZoneIfNew(candidate, g_scalpDemand, PERIOD_M5, STRATEGY_SCALPING, "Scalping Demand");
      }
      if(!g_scalpSupply.valid || g_scalpSupply.used || g_scalpSupply.broken || g_scalpSupply.expired)
      {
         Zone candidate;
         if(FindBestSDZone(PERIOD_M5, -1, InpScalpLookbackBars, CoursePipsToPrice(InpScalpZonePips), true, STRATEGY_SCALPING, candidate))
            ArmZoneIfNew(candidate, g_scalpSupply, PERIOD_M5, STRATEGY_SCALPING, "Scalping Supply");
      }
   }

   if(newM30)
   {
      UpdateZoneOnClosedBar(g_intradayDemand, PERIOD_M30);
      UpdateZoneOnClosedBar(g_intradaySupply, PERIOD_M30);
      if(!g_intradayDemand.valid || g_intradayDemand.used || g_intradayDemand.broken || g_intradayDemand.expired)
      {
         Zone candidate;
         if(FindBestIntradaySDZone(1, candidate))
            ArmZoneIfNew(candidate, g_intradayDemand, PERIOD_M30, STRATEGY_INTRADAY, "Intraday Demand");
      }
      if(!g_intradaySupply.valid || g_intradaySupply.used || g_intradaySupply.broken || g_intradaySupply.expired)
      {
         Zone candidate;
         if(FindBestIntradaySDZone(-1, candidate))
            ArmZoneIfNew(candidate, g_intradaySupply, PERIOD_M30, STRATEGY_INTRADAY, "Intraday Supply");
      }
   }

   if(newSwingEntry)
      UpdateZoneOnClosedBar(g_swingZone, InpSwingSetupTF);
}

void RegisterFirstTouch(Zone &zone, StrategyId strategy, double chartPrice, ENUM_TIMEFRAMES touchTF)
{
   if(!zone.valid || zone.used || zone.broken || zone.expired || zone.state != ZONE_DEPARTED)
      return;
   if(chartPrice < zone.bottom || chartPrice > zone.top)
      return;

   datetime barTime[1];
   datetime currentBarTime=(CopyTime(g_symbol,touchTF,0,1,barTime)==1 ? barTime[0] : TimeCurrent());
   if(zone.firstTouchBarTime>0 && zone.firstTouchBarTime==currentBarTime)
      return;
   zone.state = ZONE_FIRST_TOUCH;
   zone.firstTouchTime = TimeCurrent();
   zone.firstTouchPrice = chartPrice;
   zone.touches++;
   zone.firstTouchBarTime = currentBarTime;
   g_funnel[(int)strategy].firstTouches++;
   if(strategy==STRATEGY_SWING) g_funnel[(int)strategy].m30Touches++;
   g_runtime[(int)strategy].zoneId = zone.id;
   g_runtime[(int)strategy].zoneState = ZoneStateName(zone.state);
   PrintFormat("First Touch原子锁定：Strategy=%s ZoneID=%s Time=%s Price=%s",
               g_runtime[(int)strategy].name,
               zone.id,
               TimeToString(zone.firstTouchTime, TIME_DATE|TIME_SECONDS),
               DoubleToString(chartPrice, g_digits));
   SavePersistentState();
}

void ReleaseZoneForNextClosedBar(Zone &zone,string reason)
{
   if(!zone.valid || zone.used || zone.broken || zone.expired)
      return;
   zone.state=ZONE_DEPARTED;
   PrintFormat("区域保留等待后续已收盘K线：ZoneID=%s LastTouchBar=%s 原因=%s",
               zone.id,TimeToString(zone.firstTouchBarTime,TIME_DATE|TIME_MINUTES),reason);
}

string DirectionName(int direction)
{
   return (direction>0 ? "BUY" : "SELL");
}

string BuildTradeComment(StrategyId strategy,int direction,string zoneId)
{
   string tag=(strategy==STRATEGY_SCALPING ? "S" : strategy==STRATEGY_INTRADAY ? "I" : "W");
   return StringFormat("GSM50_%s_%s_Z%08X",tag,(direction>0?"B":"S"),HashText(zoneId));
}

void WriteSignalAuditCSV(StrategyId strategy,int direction,string zoneId,bool rawCore,bool indicatorPassed,
                         bool macdPassed,bool confidencePassed,bool gatePassed,bool finalAccepted,string reason)
{
   if(!InpEnableSignalAuditCSV)
      return;
   int s=(int)strategy;
   int handle=FileOpen(InpSignalAuditFileName,FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_SHARE_READ|FILE_COMMON,',');
   if(handle==INVALID_HANDLE)
   {
      PrintFormat("SIGNAL_AUDIT_CSV_ERROR|File=%s|Error=%d",InpSignalAuditFileName,GetLastError());
      return;
   }
   bool empty=(FileSize(handle)==0);
   FileSeek(handle,0,SEEK_END);
   if(empty)
      FileWrite(handle,"Run","Time","SOP","Magic","Direction","ZoneID","ClusterID","RawCore","IndicatorPassed",
                "MACDPassed","BollingerMode","BollingerPassed","ConfidencePassed","GatePassed","Accepted","RejectReason",
                "MarketEntry","PlannedSLDistance","PlannedTPDistance","EMA_Fast","EMA_Slow","RSI","MACD_Main","MACD_Signal",
                "MACD_Histogram","BollingerUpper","BollingerMiddle","BollingerLower","BollingerPercentB","BollingerBandWidth",
                "BollingerBandWidthChange","ATR","SpreadPoints","Confidence","ScoreParts");
   double entry=(direction>0 ? g_tick.ask : g_tick.bid);
   double slDistance=0.0,tpDistance=0.0;
   if(strategy==STRATEGY_SCALPING)
   {
      slDistance=CoursePipsToPrice(InpScalpSLPips);
      tpDistance=CoursePipsToPrice(InpScalpTPPips);
   }
   else if(strategy==STRATEGY_INTRADAY)
   {
      slDistance=PTToPrice(InpIntradaySLPoints);
      tpDistance=PTToPrice(InpIntradayTPPoints);
   }
   string parts=StringFormat("%.2f|%.2f|%.2f|%.2f|%.2f|%.2f|%.2f|%.2f",
                             g_runtime[s].score.part1,g_runtime[s].score.part2,g_runtime[s].score.part3,g_runtime[s].score.part4,
                             g_runtime[s].score.part5,g_runtime[s].score.part6,g_runtime[s].score.part7,g_runtime[s].score.part8);
   FileWrite(handle,InpAuditRunLabel,TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),g_runtime[s].name,StrategyMagic(strategy),
             DirectionName(direction),zoneId,g_runtime[s].clusterId,(rawCore?"YES":"NO"),(indicatorPassed?"YES":"NO"),
             (macdPassed?"YES":"NO"),(int)StrategyBollingerMode(strategy),(g_bollingerSnapshot[s].directionPassed?"YES":"NO"),
             (confidencePassed?"YES":"NO"),(gatePassed?"YES":"NO"),(finalAccepted?"YES":"NO"),reason,
             DoubleToString(entry,g_digits),DoubleToString(slDistance,g_digits),DoubleToString(tpDistance,g_digits),
             DoubleToString(g_indicatorSnapshot[s].emaFast,g_digits),DoubleToString(g_indicatorSnapshot[s].emaSlow,g_digits),
             DoubleToString(g_indicatorSnapshot[s].rsi,2),DoubleToString(g_macdSnapshot[s].mainValue,6),
             DoubleToString(g_macdSnapshot[s].signalValue,6),DoubleToString(g_macdSnapshot[s].histogram,6),
             DoubleToString(g_bollingerSnapshot[s].upper,g_digits),DoubleToString(g_bollingerSnapshot[s].middle,g_digits),
             DoubleToString(g_bollingerSnapshot[s].lower,g_digits),DoubleToString(g_bollingerSnapshot[s].percentB,6),
             DoubleToString(g_bollingerSnapshot[s].bandWidth,6),DoubleToString(g_bollingerSnapshot[s].bandWidthChange,6),
             DoubleToString(g_indicatorSnapshot[s].atr,g_digits),CurrentSpreadPoints(),DoubleToString(g_runtime[s].confidence,2),parts);
   FileFlush(handle);
   FileClose(handle);
}

void PrintFilterAudit(StrategyId strategy,int direction,string zoneId,bool rawCore,bool indicatorPassed,
                      bool macdPassed,bool confidencePassed,bool gatePassed,bool finalAccepted,string reason)
{
   if(!InpEnableFilterAuditLogs)
      return;
   int s=(int)strategy;
   PrintFormat("FILTER_AUDIT|Run=%s|Time=%s|SOP=%s|Side=%s|ZoneID=%s|ClusterID=%s|ZoneHash=%08X|RawCore=%s|Indicator=%s|MACD=%s|BollingerMode=%d|BollingerPassed=%s|Confidence=%s|Gate=%s|Accepted=%s|Reason=%s|EMAfast=%.8f|EMAslow=%.8f|EMAslope=%.8f|RSI=%.4f|RSIprev=%.4f|MACDmain=%.8f|MACDsignal=%.8f|MACDhist=%.8f|BBUpper=%.8f|BBMiddle=%.8f|BBLower=%.8f|BBPercentB=%.6f|BBWidth=%.8f|BBChange=%.6f|Score=%.2f|Parts=%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f",
               InpAuditRunLabel,TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),g_runtime[s].name,
               DirectionName(direction),zoneId,g_runtime[s].clusterId,HashText(zoneId),(rawCore?"1":"0"),(indicatorPassed?"1":"0"),
               (macdPassed?"1":"0"),(int)StrategyBollingerMode(strategy),(g_bollingerSnapshot[s].directionPassed?"1":"0"),
               (confidencePassed?"1":"0"),(gatePassed?"1":"0"),(finalAccepted?"1":"0"),reason,
               g_indicatorSnapshot[s].emaFast,g_indicatorSnapshot[s].emaSlow,
               g_indicatorSnapshot[s].emaFast-g_indicatorSnapshot[s].emaFastPrevious,
               g_indicatorSnapshot[s].rsi,g_indicatorSnapshot[s].rsiPrevious,
               g_macdSnapshot[s].mainValue,g_macdSnapshot[s].signalValue,g_macdSnapshot[s].histogram,
               g_bollingerSnapshot[s].upper,g_bollingerSnapshot[s].middle,g_bollingerSnapshot[s].lower,
               g_bollingerSnapshot[s].percentB,g_bollingerSnapshot[s].bandWidth,g_bollingerSnapshot[s].bandWidthChange,
               g_runtime[s].confidence,g_runtime[s].score.part1,g_runtime[s].score.part2,g_runtime[s].score.part3,
               g_runtime[s].score.part4,g_runtime[s].score.part5,g_runtime[s].score.part6,g_runtime[s].score.part7);
   WriteSignalAuditCSV(strategy,direction,zoneId,rawCore,indicatorPassed,macdPassed,confidencePassed,gatePassed,finalAccepted,reason);
}

void UpdateFirstTouchStates()
{
   double chartPrice = (g_tick.bid + g_tick.ask) * 0.5;
   if(chartPrice <= 0.0)
      return;

   RegisterFirstTouch(g_scalpDemand, STRATEGY_SCALPING, chartPrice, PERIOD_M5);
   RegisterFirstTouch(g_scalpSupply, STRATEGY_SCALPING, chartPrice, PERIOD_M5);
   if(g_intradayDemand.valid && g_intradayDemand.state == ZONE_DEPARTED &&
      g_tick.ask <= IntradayEntryLevel(g_intradayDemand) && g_tick.ask >= g_intradayDemand.bottom)
      RegisterFirstTouch(g_intradayDemand, STRATEGY_INTRADAY, g_tick.ask, PERIOD_M30);
   if(g_intradaySupply.valid && g_intradaySupply.state == ZONE_DEPARTED &&
      g_tick.bid >= IntradayEntryLevel(g_intradaySupply) && g_tick.bid <= g_intradaySupply.top)
      RegisterFirstTouch(g_intradaySupply, STRATEGY_INTRADAY, g_tick.bid, PERIOD_M30);
   RegisterFirstTouch(g_swingZone, STRATEGY_SWING, chartPrice, InpSwingEntryTF);

   if(!g_strategyEnabled[(int)STRATEGY_SCALPING])
   {
      if(g_scalpDemand.state==ZONE_FIRST_TOUCH) MarkZoneUsed(g_scalpDemand,"Scalping策略已关闭");
      if(g_scalpSupply.state==ZONE_FIRST_TOUCH) MarkZoneUsed(g_scalpSupply,"Scalping策略已关闭");
   }
   if(!g_strategyEnabled[(int)STRATEGY_INTRADAY])
   {
      if(g_intradayDemand.state==ZONE_FIRST_TOUCH) MarkZoneUsed(g_intradayDemand,"Intraday策略已关闭");
      if(g_intradaySupply.state==ZONE_FIRST_TOUCH) MarkZoneUsed(g_intradaySupply,"Intraday策略已关闭");
   }
   if(!g_strategyEnabled[(int)STRATEGY_SWING] && g_swingZone.state==ZONE_FIRST_TOUCH)
      MarkZoneUsed(g_swingZone,"Swing策略已关闭");
}

string ZoneStateName(ZoneLifecycle state)
{
   if(state == ZONE_FORMING) return "FORMING";
   if(state == ZONE_FRESH) return "FRESH";
   if(state == ZONE_DEPARTED) return "DEPARTED";
   if(state == ZONE_FIRST_TOUCH) return "FIRST_TOUCH";
   if(state == ZONE_ENTRY_PENDING) return "ENTRY_PENDING";
   if(state == ZONE_USED) return "USED";
   if(state == ZONE_BROKEN) return "BROKEN";
   return "EXPIRED";
}

//+------------------------------------------------------------------+
//| PDF 36-candlestick detector (closed bars only)                   |
//| Volume is MT5 tick volume, used only as a market-activity proxy. |
//+------------------------------------------------------------------+
bool CalculateCandleMetrics(MqlRates &rates[], int shift, CandleMetrics &metrics)
{
   if(shift < 1 || shift >= ArraySize(rates))
      return false;
   MqlRates bar = rates[shift];
   metrics.range = bar.high - bar.low;
   if(metrics.range <= 0.0)
      return false;

   metrics.body = MathAbs(bar.close - bar.open);
   metrics.upperWick = bar.high - MathMax(bar.open, bar.close);
   metrics.lowerWick = MathMin(bar.open, bar.close) - bar.low;
   metrics.bodyToRange = metrics.body / metrics.range;
   double bodyFloor = MathMax(metrics.body, g_tickSize);
   metrics.upperWickToBody = metrics.upperWick / bodyFloor;
   metrics.lowerWickToBody = metrics.lowerWick / bodyFloor;
   metrics.closeLocation = (bar.close - bar.low) / metrics.range;
   metrics.gapSize = 0.0;
   if(shift + 1 < ArraySize(rates))
   {
      double previousTop = MathMax(rates[shift + 1].open, rates[shift + 1].close);
      double previousBottom = MathMin(rates[shift + 1].open, rates[shift + 1].close);
      if(MathMin(bar.open, bar.close) > previousTop)
         metrics.gapSize = MathMin(bar.open, bar.close) - previousTop;
      else if(MathMax(bar.open, bar.close) < previousBottom)
         metrics.gapSize = previousBottom - MathMax(bar.open, bar.close);
   }

   double avgVolume = 0.0;
   int count = 0;
   int last = MathMin(ArraySize(rates) - 1, shift + InpVolumeAveragePeriod);
   for(int i = shift + 1; i <= last; i++)
   {
      avgVolume += (double)rates[i].tick_volume;
      count++;
   }
   metrics.tickVolumeRatio = (count > 0 && avgVolume > 0.0 ?
                              (double)bar.tick_volume / (avgVolume / count) : 0.0);
   return true;
}

int CandlePriorTrend(MqlRates &rates[], int shift)
{
   int oldest = shift + InpCandleTrendBars;
   if(oldest >= ArraySize(rates))
      return 0;
   double recent = 0.0;
   double old = 0.0;
   int half = MathMax(1, InpCandleTrendBars / 2);
   for(int i = shift; i < shift + half; i++)
      recent += rates[i].close;
   for(int i = oldest - half + 1; i <= oldest; i++)
      old += rates[i].close;
   recent /= half;
   old /= half;
   double tolerance = MathMax(g_tickSize, CalcATR(rates, shift, MathMin(InpATRPeriod, ArraySize(rates) - shift - 1)) * 0.05);
   if(recent > old + tolerance)
      return 1;
   if(recent < old - tolerance)
      return -1;
   return 0;
}

bool CandleBull(MqlRates &bar) { return bar.close > bar.open; }
bool CandleBear(MqlRates &bar) { return bar.close < bar.open; }
double CandleBodyTop(MqlRates &bar) { return MathMax(bar.open, bar.close); }
double CandleBodyBottom(MqlRates &bar) { return MathMin(bar.open, bar.close); }

bool CandleIsDoji(CandleMetrics &m)
{
   return m.bodyToRange <= InpDojiMaxBodyRatio;
}

bool CandleIsSpinning(CandleMetrics &m)
{
   return m.bodyToRange <= InpSpinningMaxBodyRatio &&
          m.upperWickToBody >= InpSpinningMinWickBody &&
          m.lowerWickToBody >= InpSpinningMinWickBody;
}

void CandlePatternNames(CandlePatternType type, string &english, string &chinese)
{
   english = "None"; chinese = "无";
   if(type == CANDLE_HAMMER) { english="Hammer"; chinese="锤子线"; }
   else if(type == CANDLE_INVERTED_HAMMER) { english="Inverted Hammer"; chinese="倒锤子线"; }
   else if(type == CANDLE_BULLISH_MARUBOZU) { english="Bullish Marubozu"; chinese="看涨光头光脚"; }
   else if(type == CANDLE_BULLISH_ENGULFING) { english="Bullish Engulfing"; chinese="看涨吞没"; }
   else if(type == CANDLE_BULLISH_HARAMI) { english="Bullish Harami"; chinese="看涨孕线"; }
   else if(type == CANDLE_PIERCING_LINE) { english="Piercing Line"; chinese="刺透形态"; }
   else if(type == CANDLE_TWEEZER_BOTTOM) { english="Tweezer Bottom"; chinese="镊子底"; }
   else if(type == CANDLE_BULLISH_KICKER) { english="Bullish Kicker"; chinese="看涨反冲"; }
   else if(type == CANDLE_MORNING_STAR) { english="Morning Star"; chinese="早晨之星"; }
   else if(type == CANDLE_MORNING_DOJI_STAR) { english="Morning Doji Star"; chinese="早晨十字星"; }
   else if(type == CANDLE_BULLISH_ABANDONED_BABY) { english="Bullish Abandoned Baby"; chinese="看涨弃婴"; }
   else if(type == CANDLE_THREE_WHITE_SOLDIERS) { english="Three White Soldiers"; chinese="红三兵"; }
   else if(type == CANDLE_THREE_INSIDE_UP) { english="Three Inside Up"; chinese="内困三升"; }
   else if(type == CANDLE_THREE_OUTSIDE_UP) { english="Three Outside Up"; chinese="外侧三升"; }
   else if(type == CANDLE_BULLISH_SPINNING_TOP) { english="Bullish Spinning Top"; chinese="看涨纺锤线"; }
   else if(type == CANDLE_HANGING_MAN) { english="Hanging Man"; chinese="上吊线"; }
   else if(type == CANDLE_SHOOTING_STAR) { english="Shooting Star"; chinese="流星线"; }
   else if(type == CANDLE_BEARISH_MARUBOZU) { english="Bearish Marubozu"; chinese="看跌光头光脚"; }
   else if(type == CANDLE_BEARISH_ENGULFING) { english="Bearish Engulfing"; chinese="看跌吞没"; }
   else if(type == CANDLE_BEARISH_HARAMI) { english="Bearish Harami"; chinese="看跌孕线"; }
   else if(type == CANDLE_DARK_CLOUD_COVER) { english="Dark Cloud Cover"; chinese="乌云盖顶"; }
   else if(type == CANDLE_TWEEZER_TOP) { english="Tweezer Top"; chinese="镊子顶"; }
   else if(type == CANDLE_BEARISH_KICKER) { english="Bearish Kicker"; chinese="看跌反冲"; }
   else if(type == CANDLE_EVENING_STAR) { english="Evening Star"; chinese="黄昏之星"; }
   else if(type == CANDLE_EVENING_DOJI_STAR) { english="Evening Doji Star"; chinese="黄昏十字星"; }
   else if(type == CANDLE_BEARISH_ABANDONED_BABY) { english="Bearish Abandoned Baby"; chinese="看跌弃婴"; }
   else if(type == CANDLE_THREE_BLACK_CROWS) { english="Three Black Crows"; chinese="三只乌鸦"; }
   else if(type == CANDLE_THREE_INSIDE_DOWN) { english="Three Inside Down"; chinese="内困三降"; }
   else if(type == CANDLE_THREE_OUTSIDE_DOWN) { english="Three Outside Down"; chinese="外侧三降"; }
   else if(type == CANDLE_BEARISH_SPINNING_TOP) { english="Bearish Spinning Top"; chinese="看跌纺锤线"; }
   else if(type == CANDLE_DOJI) { english="Doji"; chinese="十字线"; }
   else if(type == CANDLE_LONG_LEGGED_DOJI) { english="Long-Legged Doji"; chinese="长脚十字线"; }
   else if(type == CANDLE_DRAGONFLY_DOJI) { english="Dragonfly Doji"; chinese="蜻蜓十字线"; }
   else if(type == CANDLE_GRAVESTONE_DOJI) { english="Gravestone Doji"; chinese="墓碑十字线"; }
   else if(type == CANDLE_SPINNING_TOP) { english="Spinning Top"; chinese="纺锤线"; }
   else if(type == CANDLE_FOUR_PRICE_DOJI) { english="Four-Price Doji"; chinese="四价十字线"; }
}

CandleStrength BaseCandleStrength(CandlePatternType type)
{
   if(type == CANDLE_BULLISH_ENGULFING || type == CANDLE_BEARISH_ENGULFING ||
      type == CANDLE_HAMMER || type == CANDLE_SHOOTING_STAR ||
      type == CANDLE_BULLISH_MARUBOZU || type == CANDLE_BEARISH_MARUBOZU ||
      type == CANDLE_BULLISH_KICKER || type == CANDLE_BEARISH_KICKER ||
      type == CANDLE_MORNING_STAR || type == CANDLE_EVENING_STAR ||
      type == CANDLE_MORNING_DOJI_STAR || type == CANDLE_EVENING_DOJI_STAR ||
      type == CANDLE_THREE_WHITE_SOLDIERS || type == CANDLE_THREE_BLACK_CROWS ||
      type == CANDLE_BULLISH_ABANDONED_BABY || type == CANDLE_BEARISH_ABANDONED_BABY)
      return CANDLE_STRENGTH_STRONG;

   if(type == CANDLE_BULLISH_HARAMI || type == CANDLE_BEARISH_HARAMI ||
      type == CANDLE_INVERTED_HAMMER || type == CANDLE_HANGING_MAN ||
      type == CANDLE_PIERCING_LINE || type == CANDLE_DARK_CLOUD_COVER ||
      type == CANDLE_TWEEZER_BOTTOM || type == CANDLE_TWEEZER_TOP ||
      type == CANDLE_THREE_INSIDE_UP || type == CANDLE_THREE_INSIDE_DOWN ||
      type == CANDLE_THREE_OUTSIDE_UP || type == CANDLE_THREE_OUTSIDE_DOWN ||
      type == CANDLE_DOJI || type == CANDLE_LONG_LEGGED_DOJI ||
      type == CANDLE_DRAGONFLY_DOJI || type == CANDLE_GRAVESTONE_DOJI)
      return CANDLE_STRENGTH_MODERATE;

   if(type == CANDLE_NONE)
      return CANDLE_STRENGTH_NONE;
   if(type == CANDLE_FOUR_PRICE_DOJI)
      return CANDLE_STRENGTH_NEUTRAL;
   return CANDLE_STRENGTH_WEAK;
}

bool DetectCandlestickSignal(ENUM_TIMEFRAMES tf, int expectedDirection, bool atKeyLocation, CandleSignal &signal)
{
   ResetCandleSignal(signal);
   MqlRates rates[];
   int need = InpVolumeAveragePeriod + InpCandleTrendBars + InpATRPeriod + 12;
   if(!LoadRates(tf, need, rates))
      return false;

   CandleMetrics m1, m2, m3;
   if(!CalculateCandleMetrics(rates, 1, m1) || !CalculateCandleMetrics(rates, 2, m2) || !CalculateCandleMetrics(rates, 3, m3))
      return false;

   MqlRates b1 = rates[1], b2 = rates[2], b3 = rates[3];
   int trend = CandlePriorTrend(rates, 2);
   double tolerance = CoursePipsToPrice(InpTweezerTolerancePips);
   double minGap = CoursePipsToPrice(InpGapMinPips);
   bool bull1 = CandleBull(b1), bull2 = CandleBull(b2), bull3 = CandleBull(b3);
   bool bear1 = CandleBear(b1), bear2 = CandleBear(b2), bear3 = CandleBear(b3);
   bool doji2 = CandleIsDoji(m2);
   double mid2 = (b2.open + b2.close) * 0.5;

   bool hammerShape = m1.lowerWickToBody >= InpHammerMinWickBody && m1.upperWick <= m1.range * 0.25 && m1.closeLocation >= 0.55;
   bool upperRejectShape = m1.upperWickToBody >= InpHammerMinWickBody && m1.lowerWick <= m1.range * 0.25 && m1.closeLocation <= 0.45;
   bool bullEngulf = bull1 && bear2 && CandleBodyTop(b1) >= CandleBodyTop(b2) &&
                     CandleBodyBottom(b1) <= CandleBodyBottom(b2) && m1.body >= m2.body * InpEngulfingMinRatio;
   bool bearEngulf = bear1 && bull2 && CandleBodyTop(b1) >= CandleBodyTop(b2) &&
                     CandleBodyBottom(b1) <= CandleBodyBottom(b2) && m1.body >= m2.body * InpEngulfingMinRatio;
   bool bullHarami = bull1 && bear2 && CandleBodyTop(b1) < CandleBodyTop(b2) && CandleBodyBottom(b1) > CandleBodyBottom(b2);
   bool bearHarami = bear1 && bull2 && CandleBodyTop(b1) < CandleBodyTop(b2) && CandleBodyBottom(b1) > CandleBodyBottom(b2);
   bool bullMarubozu = bull1 && m1.upperWick / m1.range <= InpMarubozuMaxWickRatio && m1.lowerWick / m1.range <= InpMarubozuMaxWickRatio;
   bool bearMarubozu = bear1 && m1.upperWick / m1.range <= InpMarubozuMaxWickRatio && m1.lowerWick / m1.range <= InpMarubozuMaxWickRatio;
   bool piercing = bull1 && bear2 && b1.close > mid2 && b1.close < b2.open && b1.open <= b2.close + tolerance;
   bool darkCloud = bear1 && bull2 && b1.close < mid2 && b1.close > b2.open && b1.open >= b2.close - tolerance;
   bool tweezerBottom = bull1 && bear2 && MathAbs(b1.low - b2.low) <= tolerance;
   bool tweezerTop = bear1 && bull2 && MathAbs(b1.high - b2.high) <= tolerance;
   bool bullKicker = bull1 && bear2 && CandleBodyBottom(b1) > CandleBodyTop(b2) + minGap;
   bool bearKicker = bear1 && bull2 && CandleBodyTop(b1) < CandleBodyBottom(b2) - minGap;

   bool middleSmall = m2.bodyToRange <= InpStarMaxBodyRatio;
   bool morning = bear3 && middleSmall && bull1 && b1.close > (b3.open + b3.close) * 0.5;
   bool evening = bull3 && middleSmall && bear1 && b1.close < (b3.open + b3.close) * 0.5;
   bool morningDoji = morning && doji2;
   bool eveningDoji = evening && doji2;
   bool abandonedBull = morningDoji && b2.high < b3.low - minGap && b2.high < b1.low - minGap;
   bool abandonedBear = eveningDoji && b2.low > b3.high + minGap && b2.low > b1.high + minGap;

   bool soldiers = bull1 && bull2 && bull3 && b1.close > b2.close && b2.close > b3.close &&
                   b1.open < b2.close && b1.open > b2.open && b2.open < b3.close && b2.open > b3.open;
   bool crows = bear1 && bear2 && bear3 && b1.close < b2.close && b2.close < b3.close &&
                b1.open > b2.close && b1.open < b2.open && b2.open > b3.close && b2.open < b3.open;
   bool threeInsideUp = bear3 && bull2 && CandleBodyTop(b2) < CandleBodyTop(b3) && CandleBodyBottom(b2) > CandleBodyBottom(b3) && bull1 && b1.close > b3.open;
   bool threeInsideDown = bull3 && bear2 && CandleBodyTop(b2) < CandleBodyTop(b3) && CandleBodyBottom(b2) > CandleBodyBottom(b3) && bear1 && b1.close < b3.open;
   bool threeOutsideUp = bear3 && bull2 && CandleBodyTop(b2) > CandleBodyTop(b3) && CandleBodyBottom(b2) < CandleBodyBottom(b3) && bull1 && b1.close > b2.close;
   bool threeOutsideDown = bull3 && bear2 && CandleBodyTop(b2) > CandleBodyTop(b3) && CandleBodyBottom(b2) < CandleBodyBottom(b3) && bear1 && b1.close < b2.close;

   CandlePatternType detected = CANDLE_NONE;
   int direction = 0;
   if(expectedDirection >= 0)
   {
      if(abandonedBull) detected = CANDLE_BULLISH_ABANDONED_BABY;
      else if(morningDoji) detected = CANDLE_MORNING_DOJI_STAR;
      else if(morning) detected = CANDLE_MORNING_STAR;
      else if(soldiers) detected = CANDLE_THREE_WHITE_SOLDIERS;
      else if(threeOutsideUp) detected = CANDLE_THREE_OUTSIDE_UP;
      else if(threeInsideUp) detected = CANDLE_THREE_INSIDE_UP;
      else if(bullKicker) detected = CANDLE_BULLISH_KICKER;
      else if(bullEngulf) detected = CANDLE_BULLISH_ENGULFING;
      else if(bullMarubozu) detected = CANDLE_BULLISH_MARUBOZU;
      else if(piercing) detected = CANDLE_PIERCING_LINE;
      else if(tweezerBottom) detected = CANDLE_TWEEZER_BOTTOM;
      else if(bullHarami) detected = CANDLE_BULLISH_HARAMI;
      else if(upperRejectShape && trend < 0) detected = CANDLE_INVERTED_HAMMER;
      else if(hammerShape && trend <= 0) detected = CANDLE_HAMMER;
      else if(CandleIsSpinning(m1) && bull1) detected = CANDLE_BULLISH_SPINNING_TOP;
      if(detected != CANDLE_NONE) direction = 1;
   }

   if(detected == CANDLE_NONE && expectedDirection <= 0)
   {
      if(abandonedBear) detected = CANDLE_BEARISH_ABANDONED_BABY;
      else if(eveningDoji) detected = CANDLE_EVENING_DOJI_STAR;
      else if(evening) detected = CANDLE_EVENING_STAR;
      else if(crows) detected = CANDLE_THREE_BLACK_CROWS;
      else if(threeOutsideDown) detected = CANDLE_THREE_OUTSIDE_DOWN;
      else if(threeInsideDown) detected = CANDLE_THREE_INSIDE_DOWN;
      else if(bearKicker) detected = CANDLE_BEARISH_KICKER;
      else if(bearEngulf) detected = CANDLE_BEARISH_ENGULFING;
      else if(bearMarubozu) detected = CANDLE_BEARISH_MARUBOZU;
      else if(darkCloud) detected = CANDLE_DARK_CLOUD_COVER;
      else if(tweezerTop) detected = CANDLE_TWEEZER_TOP;
      else if(bearHarami) detected = CANDLE_BEARISH_HARAMI;
      else if(hammerShape && trend > 0) detected = CANDLE_HANGING_MAN;
      else if(upperRejectShape && trend >= 0) detected = CANDLE_SHOOTING_STAR;
      else if(CandleIsSpinning(m1) && bear1) detected = CANDLE_BEARISH_SPINNING_TOP;
      if(detected != CANDLE_NONE) direction = -1;
   }

   if(detected == CANDLE_NONE)
   {
      if(m1.range <= g_tickSize * 1.5)
         detected = CANDLE_FOUR_PRICE_DOJI;
      else if(CandleIsDoji(m1) && m1.upperWick >= m1.range * 0.40 && m1.lowerWick >= m1.range * 0.40)
         detected = CANDLE_LONG_LEGGED_DOJI;
      else if(CandleIsDoji(m1) && m1.lowerWick >= m1.range * 0.60 && m1.upperWick <= m1.range * 0.10)
         detected = CANDLE_DRAGONFLY_DOJI;
      else if(CandleIsDoji(m1) && m1.upperWick >= m1.range * 0.60 && m1.lowerWick <= m1.range * 0.10)
         detected = CANDLE_GRAVESTONE_DOJI;
      else if(CandleIsDoji(m1))
         detected = CANDLE_DOJI;
      else if(CandleIsSpinning(m1))
         detected = CANDLE_SPINNING_TOP;
   }

   if(detected == CANDLE_NONE)
      return false;

   signal.valid = true;
   signal.type = detected;
   signal.direction = direction;
   signal.strength = BaseCandleStrength(detected);
   CandlePatternNames(detected, signal.englishName, signal.chineseName);
   signal.timeframe = tf;
   signal.candleTime = b1.time;
   signal.volumeRatio = m1.tickVolumeRatio;

   bool trendAligned = (direction == 0 || (direction > 0 && trend <= 0) || (direction < 0 && trend >= 0));
   if(!atKeyLocation || !trendAligned)
   {
      if(signal.strength == CANDLE_STRENGTH_STRONG)
         signal.strength = CANDLE_STRENGTH_MODERATE;
      else if(signal.strength == CANDLE_STRENGTH_MODERATE)
         signal.strength = CANDLE_STRENGTH_WEAK;
   }
   if(InpUseVolumeInScore && m1.tickVolumeRatio > 0.0 && m1.tickVolumeRatio < 1.0 && signal.strength > CANDLE_STRENGTH_WEAK)
      signal.strength = (CandleStrength)((int)signal.strength - 1);

   signal.quality = 20.0 * (int)signal.strength;
   if(m1.tickVolumeRatio >= InpVolumeConfirmMultiple)
      signal.quality = MathMin(100.0, signal.quality + 15.0);
   return true;
}

bool IsScalpingWhitelist(CandleSignal &signal)
{
   return signal.valid &&
          (signal.type == CANDLE_BULLISH_ENGULFING || signal.type == CANDLE_BEARISH_ENGULFING ||
           signal.type == CANDLE_HAMMER || signal.type == CANDLE_INVERTED_HAMMER ||
           signal.type == CANDLE_SHOOTING_STAR);
}

bool IsClearScalpWickRejection(MqlRates &bar,int direction)
{
   double range=bar.high-bar.low;
   if(range<=g_tickSize)
      return false;
   double body=MathMax(MathAbs(bar.close-bar.open),g_tickSize);
   double lower=MathMin(bar.open,bar.close)-bar.low;
   double upper=bar.high-MathMax(bar.open,bar.close);
   if(direction>0)
      return (lower>=body*InpHammerMinWickBody && lower>=range*0.55 && (bar.close-bar.low)/range>=0.55);
   return (upper>=body*InpHammerMinWickBody && upper>=range*0.55 && (bar.close-bar.low)/range<=0.45);
}

string CandleStrengthName(CandleStrength strength)
{
   if(strength == CANDLE_STRENGTH_STRONG) return "STRONG";
   if(strength == CANDLE_STRENGTH_MODERATE) return "MODERATE";
   if(strength == CANDLE_STRENGTH_WEAK) return "WEAK";
   if(strength == CANDLE_STRENGTH_NEUTRAL) return "NEUTRAL";
   return "NONE";
}

//+------------------------------------------------------------------+
//| GSM eight chart patterns using confirmed, non-repainting pivots  |
//+------------------------------------------------------------------+
void ChartPatternNames(ChartPatternType type, string &english, string &chinese)
{
   english = "None"; chinese = "无";
   if(type == CHART_HEAD_SHOULDERS) { english="Head and Shoulders"; chinese="头肩顶"; }
   else if(type == CHART_INVERSE_HEAD_SHOULDERS) { english="Inverse Head and Shoulders"; chinese="逆头肩"; }
   else if(type == CHART_DOUBLE_TOP) { english="Double Top"; chinese="双顶"; }
   else if(type == CHART_DOUBLE_BOTTOM) { english="Double Bottom"; chinese="双底"; }
   else if(type == CHART_RISING_WEDGE) { english="Rising Wedge"; chinese="上升楔形"; }
   else if(type == CHART_FALLING_WEDGE) { english="Falling Wedge"; chinese="下降楔形"; }
   else if(type == CHART_BULLISH_FLAG) { english="Bullish Flag"; chinese="看涨旗形"; }
   else if(type == CHART_BEARISH_FLAG) { english="Bearish Flag"; chinese="看跌旗形"; }
}

int CollectConfirmedPivots(MqlRates &rates[], bool highPivot, PivotPoint &pivots[], int maxCount)
{
   ArrayResize(pivots, 0);
   int depth = InpPatternPivotDepth;
   int maxIndex = MathMin(InpPatternLookbackBars, ArraySize(rates) - depth - 1);
   for(int i = depth + 1; i <= maxIndex && ArraySize(pivots) < maxCount; i++)
   {
      bool pivot = (highPivot ? IsPivotHigh(rates, i, depth) : IsPivotLow(rates, i, depth));
      if(!pivot)
         continue;
      int n = ArraySize(pivots);
      ArrayResize(pivots, n + 1);
      pivots[n].high = highPivot;
      pivots[n].index = i;
      pivots[n].time = rates[i].time;
      pivots[n].price = (highPivot ? rates[i].high : rates[i].low);
   }
   return ArraySize(pivots);
}

double LowestBetween(MqlRates &rates[], int newerIndex, int olderIndex, int &foundIndex)
{
   foundIndex = -1;
   double value = DBL_MAX;
   int first = MathMin(newerIndex, olderIndex) + 1;
   int last = MathMax(newerIndex, olderIndex) - 1;
   for(int i = first; i <= last; i++)
   {
      if(rates[i].low < value)
      {
         value = rates[i].low;
         foundIndex = i;
      }
   }
   return value;
}

double HighestBetween(MqlRates &rates[], int newerIndex, int olderIndex, int &foundIndex)
{
   foundIndex = -1;
   double value = -DBL_MAX;
   int first = MathMin(newerIndex, olderIndex) + 1;
   int last = MathMax(newerIndex, olderIndex) - 1;
   for(int i = first; i <= last; i++)
   {
      if(rates[i].high > value)
      {
         value = rates[i].high;
         foundIndex = i;
      }
   }
   return value;
}

int PriorTrendBeforePattern(MqlRates &rates[], int oldestIndex)
{
   int prior = oldestIndex + MathMax(8, InpCandleTrendBars);
   if(prior >= ArraySize(rates))
      return 0;
   double atr = CalcATR(rates, oldestIndex, MathMin(InpATRPeriod, ArraySize(rates) - oldestIndex - 1));
   double move = rates[oldestIndex].close - rates[prior].close;
   if(move > atr * 0.50) return 1;
   if(move < -atr * 0.50) return -1;
   return 0;
}

void BuildPattern(ChartPatternSignal &pattern,
                  ChartPatternType type,
                  ENUM_TIMEFRAMES tf,
                  int direction,
                  datetime startTime,
                  datetime endTime,
                  double neckline,
                  double breakout,
                  double invalidation,
                  double target,
                  ChartPatternState state,
                  double score)
{
   ResetChartPattern(pattern);
   pattern.valid = true;
   pattern.type = type;
   pattern.timeframe = tf;
   pattern.direction = direction;
   pattern.startTime = startTime;
   pattern.endTime = endTime;
   pattern.neckline = neckline;
   pattern.breakoutPrice = breakout;
   pattern.invalidationPrice = invalidation;
   pattern.projectedTarget = target;
   pattern.state = state;
   pattern.score = MathMax(0.0, MathMin(100.0, score));
   ChartPatternNames(type, pattern.englishName, pattern.chineseName);
   pattern.id = StringFormat("%s_%s_%d_%I64d", g_symbol, TimeframeTag(tf), (int)type, (long)startTime);
}

void ConsiderChartPattern(ChartPatternSignal &candidate, int desiredDirection, ChartPatternSignal &best)
{
   if(!candidate.valid || (desiredDirection != 0 && candidate.direction != desiredDirection))
      return;
   if(!best.valid || candidate.score > best.score)
      best = candidate;
}

int FindBreakoutIndex(MqlRates &rates[], int newestPatternIndex, int direction, double boundary, double buffer)
{
   for(int i = newestPatternIndex - 1; i >= 1; i--)
   {
      if((direction > 0 && rates[i].close > boundary + buffer) ||
         (direction < 0 && rates[i].close < boundary - buffer))
         return i;
   }
   return -1;
}

ChartPatternState BreakoutRetestState(MqlRates &rates[], int breakoutIndex, int direction, double boundary, double tolerance, double &retestPrice)
{
   retestPrice = 0.0;
   if(breakoutIndex < 1)
      return PATTERN_FORMING;
   for(int i = breakoutIndex - 1; i >= 1; i--)
   {
      bool retest = (direction > 0 ? rates[i].low <= boundary + tolerance && rates[i].close > boundary
                                   : rates[i].high >= boundary - tolerance && rates[i].close < boundary);
      if(retest)
      {
         retestPrice = rates[i].close;
         return PATTERN_ENTRY_READY;
      }
   }
   return PATTERN_WAITING_RETEST;
}

bool DetectBestChartPattern(ENUM_TIMEFRAMES tf, int desiredDirection, ChartPatternSignal &best)
{
   ResetChartPattern(best);
   MqlRates rates[];
   int need = InpPatternLookbackBars + InpATRPeriod + InpPatternPivotDepth + 30;
   if(!LoadRates(tf, need, rates))
      return false;

   PivotPoint highs[], lows[];
   int highCount = CollectConfirmedPivots(rates, true, highs, 8);
   int lowCount = CollectConfirmedPivots(rates, false, lows, 8);
   double atr = CalcATR(rates, 1, InpATRPeriod);
   if(atr <= 0.0)
      return false;
   double breakoutBuffer = CoursePipsToPrice(InpPatternBreakoutBufferPips);
   double retestTolerance = CoursePipsToPrice(InpPatternRetestTolerancePips);
   double doubleTolerance = CoursePipsToPrice(InpPatternDoubleTolerancePips);

   // Head and Shoulders: newest highs are right shoulder, head, left shoulder.
   if(highCount >= 3)
   {
      PivotPoint rs = highs[0], head = highs[1], ls = highs[2];
      int neck1Index, neck2Index;
      double neck1 = LowestBetween(rates, head.index, ls.index, neck1Index);
      double neck2 = LowestBetween(rates, rs.index, head.index, neck2Index);
      double shoulderTolerance = MathMax(g_tickSize, atr * InpPatternShoulderTolerance);
      bool spacing = (head.index - rs.index >= InpPatternMinPivotDistance && ls.index - head.index >= InpPatternMinPivotDistance);
      bool sizeOk = (ls.index - rs.index <= InpPatternMaxFormationBars);
      bool shape = head.price > MathMax(ls.price, rs.price) + atr * 0.15 && MathAbs(ls.price - rs.price) <= shoulderTolerance;
      if(neck1Index > 0 && neck2Index > 0 && spacing && sizeOk && shape && PriorTrendBeforePattern(rates, ls.index) > 0)
      {
         double neckline = (neck1 + neck2) * 0.5;
         int breakoutIndex = FindBreakoutIndex(rates, rs.index, -1, neckline, breakoutBuffer);
         double retest = 0.0;
         ChartPatternState state = BreakoutRetestState(rates, breakoutIndex, -1, neckline, retestTolerance, retest);
         ChartPatternSignal p;
         double target = neckline - (head.price - neckline);
         BuildPattern(p, CHART_HEAD_SHOULDERS, tf, -1, ls.time, rates[1].time, neckline,
                      (breakoutIndex > 0 ? rates[breakoutIndex].close : 0.0), head.price, target, state,
                      72.0 + (state == PATTERN_ENTRY_READY ? 18.0 : state == PATTERN_WAITING_RETEST ? 10.0 : 0.0));
         p.retestPrice = retest;
         p.keyPrices[0]=ls.price; p.keyPrices[1]=neck1; p.keyPrices[2]=head.price; p.keyPrices[3]=neck2; p.keyPrices[4]=rs.price;
         ConsiderChartPattern(p, desiredDirection, best);
      }
   }

   // Inverse Head and Shoulders.
   if(lowCount >= 3)
   {
      PivotPoint rs = lows[0], head = lows[1], ls = lows[2];
      int neck1Index, neck2Index;
      double neck1 = HighestBetween(rates, head.index, ls.index, neck1Index);
      double neck2 = HighestBetween(rates, rs.index, head.index, neck2Index);
      double shoulderTolerance = MathMax(g_tickSize, atr * InpPatternShoulderTolerance);
      bool spacing = (head.index - rs.index >= InpPatternMinPivotDistance && ls.index - head.index >= InpPatternMinPivotDistance);
      bool sizeOk = (ls.index - rs.index <= InpPatternMaxFormationBars);
      bool shape = head.price < MathMin(ls.price, rs.price) - atr * 0.15 && MathAbs(ls.price - rs.price) <= shoulderTolerance;
      if(neck1Index > 0 && neck2Index > 0 && spacing && sizeOk && shape && PriorTrendBeforePattern(rates, ls.index) < 0)
      {
         double neckline = (neck1 + neck2) * 0.5;
         int breakoutIndex = FindBreakoutIndex(rates, rs.index, 1, neckline, breakoutBuffer);
         double retest = 0.0;
         ChartPatternState state = BreakoutRetestState(rates, breakoutIndex, 1, neckline, retestTolerance, retest);
         ChartPatternSignal p;
         double target = neckline + (neckline - head.price);
         BuildPattern(p, CHART_INVERSE_HEAD_SHOULDERS, tf, 1, ls.time, rates[1].time, neckline,
                      (breakoutIndex > 0 ? rates[breakoutIndex].close : 0.0), head.price, target, state,
                      72.0 + (state == PATTERN_ENTRY_READY ? 18.0 : state == PATTERN_WAITING_RETEST ? 10.0 : 0.0));
         p.retestPrice = retest;
         p.keyPrices[0]=ls.price; p.keyPrices[1]=neck1; p.keyPrices[2]=head.price; p.keyPrices[3]=neck2; p.keyPrices[4]=rs.price;
         ConsiderChartPattern(p, desiredDirection, best);
      }
   }

   // Double Top.
   if(highCount >= 2)
   {
      PivotPoint right = highs[0], left = highs[1];
      int neckIndex;
      double neck = LowestBetween(rates, right.index, left.index, neckIndex);
      if(neckIndex > 0 && left.index - right.index >= InpPatternMinPivotDistance &&
         left.index - right.index <= InpPatternMaxFormationBars && MathAbs(left.price - right.price) <= doubleTolerance &&
         PriorTrendBeforePattern(rates, left.index) > 0)
      {
         int breakoutIndex = FindBreakoutIndex(rates, right.index, -1, neck, breakoutBuffer);
         ChartPatternSignal p;
         ChartPatternState state = (breakoutIndex > 0 ? PATTERN_BREAKOUT_CONFIRMED : PATTERN_FORMING);
         BuildPattern(p, CHART_DOUBLE_TOP, tf, -1, left.time, rates[1].time, neck,
                      (breakoutIndex > 0 ? rates[breakoutIndex].close : 0.0), MathMax(left.price,right.price), neck-(MathMax(left.price,right.price)-neck), state,
                      65.0 + (breakoutIndex > 0 ? 20.0 : 0.0));
         p.keyPrices[0]=left.price; p.keyPrices[1]=neck; p.keyPrices[2]=right.price;
         ConsiderChartPattern(p, desiredDirection, best);
      }
   }

   // Double Bottom.
   if(lowCount >= 2)
   {
      PivotPoint right = lows[0], left = lows[1];
      int neckIndex;
      double neck = HighestBetween(rates, right.index, left.index, neckIndex);
      if(neckIndex > 0 && left.index - right.index >= InpPatternMinPivotDistance &&
         left.index - right.index <= InpPatternMaxFormationBars && MathAbs(left.price - right.price) <= doubleTolerance &&
         PriorTrendBeforePattern(rates, left.index) < 0)
      {
         int breakoutIndex = FindBreakoutIndex(rates, right.index, 1, neck, breakoutBuffer);
         ChartPatternSignal p;
         ChartPatternState state = (breakoutIndex > 0 ? PATTERN_BREAKOUT_CONFIRMED : PATTERN_FORMING);
         BuildPattern(p, CHART_DOUBLE_BOTTOM, tf, 1, left.time, rates[1].time, neck,
                      (breakoutIndex > 0 ? rates[breakoutIndex].close : 0.0), MathMin(left.price,right.price), neck+(neck-MathMin(left.price,right.price)), state,
                      65.0 + (breakoutIndex > 0 ? 20.0 : 0.0));
         p.keyPrices[0]=left.price; p.keyPrices[1]=neck; p.keyPrices[2]=right.price;
         ConsiderChartPattern(p, desiredDirection, best);
      }
   }

   // Rising/Falling Wedges: three confirmed highs and lows, converging range.
   if(highCount >= InpPatternMinWedgePivots && lowCount >= InpPatternMinWedgePivots)
   {
      double oldGap = highs[2].price - lows[2].price;
      double newGap = highs[0].price - lows[0].price;
      bool converging = oldGap > atr * 0.30 && newGap > 0.0 && newGap < oldGap * 0.85;
      bool rising = highs[0].price > highs[1].price && highs[1].price > highs[2].price &&
                    lows[0].price > lows[1].price && lows[1].price > lows[2].price;
      bool falling = highs[0].price < highs[1].price && highs[1].price < highs[2].price &&
                     lows[0].price < lows[1].price && lows[1].price < lows[2].price;
      if(converging && rising && PriorTrendBeforePattern(rates, MathMax(highs[2].index,lows[2].index)) >= 0)
      {
         double boundary = lows[0].price;
         int breakoutIndex = FindBreakoutIndex(rates, MathMin(highs[0].index,lows[0].index), -1, boundary, breakoutBuffer);
         ChartPatternSignal p;
         BuildPattern(p, CHART_RISING_WEDGE, tf, -1, rates[MathMax(highs[2].index,lows[2].index)].time, rates[1].time,
                      boundary, (breakoutIndex>0?rates[breakoutIndex].close:0.0), highs[0].price, boundary-oldGap,
                      (breakoutIndex>0?PATTERN_BREAKOUT_CONFIRMED:PATTERN_FORMING), 62.0+(breakoutIndex>0?20.0:0.0));
         p.keyPrices[0]=highs[2].price; p.keyPrices[1]=lows[2].price; p.keyPrices[2]=highs[1].price; p.keyPrices[3]=lows[1].price; p.keyPrices[4]=highs[0].price; p.keyPrices[5]=lows[0].price;
         ConsiderChartPattern(p, desiredDirection, best);
      }
      if(converging && falling && PriorTrendBeforePattern(rates, MathMax(highs[2].index,lows[2].index)) <= 0)
      {
         double boundary = highs[0].price;
         int breakoutIndex = FindBreakoutIndex(rates, MathMin(highs[0].index,lows[0].index), 1, boundary, breakoutBuffer);
         ChartPatternSignal p;
         BuildPattern(p, CHART_FALLING_WEDGE, tf, 1, rates[MathMax(highs[2].index,lows[2].index)].time, rates[1].time,
                      boundary, (breakoutIndex>0?rates[breakoutIndex].close:0.0), lows[0].price, boundary+oldGap,
                      (breakoutIndex>0?PATTERN_BREAKOUT_CONFIRMED:PATTERN_FORMING), 62.0+(breakoutIndex>0?20.0:0.0));
         p.keyPrices[0]=highs[2].price; p.keyPrices[1]=lows[2].price; p.keyPrices[2]=highs[1].price; p.keyPrices[3]=lows[1].price; p.keyPrices[4]=highs[0].price; p.keyPrices[5]=lows[0].price;
         ConsiderChartPattern(p, desiredDirection, best);
      }
   }

   // Flags: a large pole followed by a compact, limited counter-trend consolidation.
   int flagBars = 8;
   int poleStart = 20;
   if(ArraySize(rates) > poleStart + InpATRPeriod)
   {
      double flagHigh = -DBL_MAX, flagLow = DBL_MAX;
      for(int i = 2; i <= flagBars; i++)
      {
         flagHigh = MathMax(flagHigh, rates[i].high);
         flagLow = MathMin(flagLow, rates[i].low);
      }
      double bullishPole = rates[flagBars].close - rates[poleStart].close;
      double bearishPole = rates[poleStart].close - rates[flagBars].close;
      double flagRange = flagHigh - flagLow;
      if(bullishPole >= atr * InpPatternFlagPoleATR && flagRange <= bullishPole * InpPatternFlagMaxRetrace &&
         rates[1].close > flagHigh + breakoutBuffer && rates[flagBars].close <= rates[2].close + atr * 0.25)
      {
         ChartPatternSignal p;
         BuildPattern(p, CHART_BULLISH_FLAG, tf, 1, rates[poleStart].time, rates[1].time, flagHigh,
                      rates[1].close, flagLow, rates[1].close+bullishPole, PATTERN_BREAKOUT_CONFIRMED, 84.0);
         p.keyPrices[0]=rates[poleStart].close; p.keyPrices[1]=rates[flagBars].close; p.keyPrices[2]=flagHigh; p.keyPrices[3]=flagLow;
         ConsiderChartPattern(p, desiredDirection, best);
      }
      if(bearishPole >= atr * InpPatternFlagPoleATR && flagRange <= bearishPole * InpPatternFlagMaxRetrace &&
         rates[1].close < flagLow - breakoutBuffer && rates[flagBars].close >= rates[2].close - atr * 0.25)
      {
         ChartPatternSignal p;
         BuildPattern(p, CHART_BEARISH_FLAG, tf, -1, rates[poleStart].time, rates[1].time, flagLow,
                      rates[1].close, flagHigh, rates[1].close-bearishPole, PATTERN_BREAKOUT_CONFIRMED, 84.0);
         p.keyPrices[0]=rates[poleStart].close; p.keyPrices[1]=rates[flagBars].close; p.keyPrices[2]=flagHigh; p.keyPrices[3]=flagLow;
         ConsiderChartPattern(p, desiredDirection, best);
      }
   }

   return best.valid;
}

string PatternStateName(ChartPatternState state)
{
   if(state == PATTERN_FORMING) return "FORMING";
   if(state == PATTERN_BREAKOUT_CONFIRMED) return "BREAKOUT_CONFIRMED";
   if(state == PATTERN_WAITING_RETEST) return "WAITING_RETEST";
   if(state == PATTERN_ENTRY_READY) return "ENTRY_READY";
   if(state == PATTERN_INVALID) return "INVALID";
   if(state == PATTERN_EXPIRED) return "EXPIRED";
   return "USED";
}

//+------------------------------------------------------------------+
//| Transparent rule-based confidence scoring                        |
//+------------------------------------------------------------------+
double Clamp01(double value)
{
   return MathMax(0.0, MathMin(1.0, value));
}

double CandleScoreFactor(CandleSignal &signal, int direction)
{
   if(!signal.valid)
      return 0.0;
   if(signal.direction != 0 && signal.direction != direction)
      return 0.0;
   if(signal.strength == CANDLE_STRENGTH_STRONG) return 1.0;
   if(signal.strength == CANDLE_STRENGTH_MODERATE) return 0.75;
   if(signal.strength == CANDLE_STRENGTH_WEAK) return 0.40;
   return 0.15;
}

double PatternScoreFactor(ChartPatternSignal &pattern, int direction)
{
   if(!pattern.valid || pattern.direction != direction)
      return 0.0;
   double stateFactor = 0.55;
   if(pattern.state == PATTERN_BREAKOUT_CONFIRMED) stateFactor = 0.85;
   if(pattern.state == PATTERN_ENTRY_READY) stateFactor = 1.0;
   if(pattern.state == PATTERN_WAITING_RETEST) stateFactor = 0.70;
   return Clamp01(pattern.score / 100.0) * stateFactor;
}

double ZoneTouchDepthFactor(Zone &zone)
{
   if(zone.width<=g_tickSize || zone.firstTouchPrice<=0.0)
      return 0.50;
   double depth=(zone.dir>0 ? (zone.top-zone.firstTouchPrice)/zone.width
                            : (zone.firstTouchPrice-zone.bottom)/zone.width);
   depth=Clamp01(depth);
   return Clamp01(1.0-MathAbs(depth-0.45)*1.50);
}

double NormalizeEnabledScore(double raw,double enabledWeight)
{
   if(enabledWeight<=0.0)
      return 0.0;
   return MathMax(0.0,MathMin(100.0,raw/enabledWeight*100.0));
}

double ClosedBarTrendStrength(ENUM_TIMEFRAMES tf,int direction)
{
   MqlRates rates[];
   int barsNeeded=InpATRPeriod+12;
   if(!LoadRates(tf,barsNeeded,rates))
      return 0.0;
   int older=MathMin(7,ArraySize(rates)-InpATRPeriod-1);
   if(older<=1)
      return 0.0;
   double atr=CalcATR(rates,1,InpATRPeriod);
   if(atr<=0.0)
      return 0.0;
   double directionalMove=(direction>0 ? rates[1].close-rates[older].close
                                       : rates[older].close-rates[1].close);
   double moveFactor=Clamp01(directionalMove/(atr*3.0));
   int aligned=0;
   int comparisons=0;
   for(int i=1;i<older;i++)
   {
      comparisons++;
      if((direction>0 && rates[i].close>=rates[i+1].close) ||
         (direction<0 && rates[i].close<=rates[i+1].close)) aligned++;
   }
   double consistency=(comparisons>0 ? (double)aligned/comparisons : 0.0);
   return Clamp01(0.65*moveFactor+0.35*consistency);
}

void ComputeScalpScore(Zone &zone, CandleSignal &candle, ChartPatternSignal &pattern, ScoreBreakdown &score)
{
   ResetScore(score);
   double enabledWeight=InpScalpWeightZone+InpScalpWeightCandle+InpScalpWeightConfluence;
   score.part1 = InpScalpWeightZone * Clamp01(zone.qualityScore / 100.0);
   score.part2 = InpScalpWeightCandle * CandleScoreFactor(candle, zone.dir);
   score.part3 = 0.0;
   if(g_indicatorSnapshot[(int)STRATEGY_SCALPING].ready)
   {
      enabledWeight+=InpScalpWeightMomentum;
      score.part3=InpScalpWeightMomentum*g_indicatorSnapshot[(int)STRATEGY_SCALPING].combinedStrength;
   }
   double confluence=MathMax(PatternScoreFactor(pattern,zone.dir),ZoneTouchDepthFactor(zone)*0.75);
   score.part4 = InpScalpWeightConfluence * confluence;
   score.part5=0.0;
   if((StrategyBollingerMode(STRATEGY_SCALPING)==BOLLINGER_MODE_SCORE || StrategyBollingerMode(STRATEGY_SCALPING)==BOLLINGER_MODE_HARD) &&
      g_bollingerSnapshot[(int)STRATEGY_SCALPING].ready)
   {
      enabledWeight+=InpScalpWeightBollinger;
      score.part5=InpScalpWeightBollinger*g_bollingerSnapshot[(int)STRATEGY_SCALPING].quality;
   }
   score.total=NormalizeEnabledScore(score.part1+score.part2+score.part3+score.part4+score.part5,enabledWeight);
   score.explanation = StringFormat("区域强度%.1f + 反转K强度%.1f + EMA/RSI动能%.1f + 结构/触及质量%.1f + Bollinger%.1f => 可用权重%.1f 标准化%.1f",
                                     score.part1,score.part2,score.part3,score.part4,score.part5,enabledWeight,score.total);
}

void ComputeIntradayScore(Zone &zone, CandleSignal &candle, ChartPatternSignal &pattern, ScoreBreakdown &score)
{
   ResetScore(score);
   double enabledWeight=InpIntradayWeightZone+InpIntradayWeightDeparture+InpIntradayWeightLocation+
                         InpIntradayWeightPattern;
   score.part1 = InpIntradayWeightZone * Clamp01(zone.qualityScore / 100.0);
   score.part2 = InpIntradayWeightDeparture * Clamp01(zone.score/2.50);
   score.part3 = InpIntradayWeightLocation * ZoneTouchDepthFactor(zone);
   double signalFactor = MathMax(CandleScoreFactor(candle, zone.dir), PatternScoreFactor(pattern, zone.dir));
   score.part4 = InpIntradayWeightPattern * signalFactor;
   score.part5 = 0.0;
   if(g_indicatorSnapshot[(int)STRATEGY_INTRADAY].ready)
   {
      enabledWeight+=InpIntradayWeightMomentum;
      score.part5=InpIntradayWeightMomentum*g_indicatorSnapshot[(int)STRATEGY_INTRADAY].combinedStrength;
   }
   score.part6 = 0.0;
   if(StrategyMACDMode(STRATEGY_INTRADAY)==MACD_MODE_SCORE && g_macdSnapshot[(int)STRATEGY_INTRADAY].ready)
   {
      enabledWeight+=InpIntradayWeightMACD;
      score.part6=InpIntradayWeightMACD*g_macdSnapshot[(int)STRATEGY_INTRADAY].quality;
   }
   score.part7=0.0;
   if((StrategyBollingerMode(STRATEGY_INTRADAY)==BOLLINGER_MODE_SCORE || StrategyBollingerMode(STRATEGY_INTRADAY)==BOLLINGER_MODE_HARD) &&
      g_bollingerSnapshot[(int)STRATEGY_INTRADAY].ready)
   {
      enabledWeight+=InpIntradayWeightBollinger;
      score.part7=InpIntradayWeightBollinger*g_bollingerSnapshot[(int)STRATEGY_INTRADAY].quality;
   }
   score.total = NormalizeEnabledScore(score.part1+score.part2+score.part3+score.part4+score.part5+score.part6+score.part7,enabledWeight);
   score.explanation = StringFormat("区域%.1f + Departure%.1f + 触及位置%.1f + K线/结构%.1f + EMA/RSI%.1f + MACD%.1f + Bollinger%.1f => 标准化%.1f",
                                    score.part1,score.part2,score.part3,score.part4,score.part5,score.part6,score.part7,score.total);
}

void ComputeSwingScore(int d1Trend, int h4Trend, bool hasSR, Zone &zone,
                       CandleSignal &candle, ChartPatternSignal &pattern, bool falseBreak,
                       ScoreBreakdown &score)
{
   ResetScore(score);
   double enabledWeight=InpSwingWeightD1+InpSwingWeightH4+InpSwingWeightZoneSR+
                         InpSwingWeightM30;
   score.part1 = InpSwingWeightD1 * ClosedBarTrendStrength(InpSwingBiasTF,d1Trend);
   double h4Factor=(h4Trend==d1Trend ? ClosedBarTrendStrength(InpSwingSetupTF,d1Trend) :
                    h4Trend==0 ? 0.35 : 0.0);
   score.part2 = InpSwingWeightH4 * h4Factor;
   double zoneFactor = Clamp01(zone.qualityScore / 100.0);
   if(hasSR) zoneFactor=Clamp01(0.70*zoneFactor+0.30*Clamp01(g_swingSR.score/8.0));
   score.part3 = InpSwingWeightZoneSR * zoneFactor;
   double entryFactor=MathMax(CandleScoreFactor(candle,d1Trend),(falseBreak?1.0:0.0));
   entryFactor=MathMax(entryFactor,PatternScoreFactor(pattern,d1Trend)*0.65);
   score.part4 = InpSwingWeightM30 * entryFactor;
   score.part5 = 0.0;
   if(g_indicatorSnapshot[(int)STRATEGY_SWING].ready)
   {
      enabledWeight+=InpSwingWeightMomentum;
      score.part5=InpSwingWeightMomentum*g_indicatorSnapshot[(int)STRATEGY_SWING].combinedStrength;
   }
   score.part6 = 0.0;
   if(StrategyMACDMode(STRATEGY_SWING)==MACD_MODE_SCORE && g_macdSnapshot[(int)STRATEGY_SWING].ready)
   {
      enabledWeight+=InpSwingWeightMACD;
      score.part6=InpSwingWeightMACD*g_macdSnapshot[(int)STRATEGY_SWING].quality;
   }
   score.part7=0.0;
   if((StrategyBollingerMode(STRATEGY_SWING)==BOLLINGER_MODE_SCORE || StrategyBollingerMode(STRATEGY_SWING)==BOLLINGER_MODE_HARD) &&
      g_bollingerSnapshot[(int)STRATEGY_SWING].ready)
   {
      enabledWeight+=InpSwingWeightBollinger;
      score.part7=InpSwingWeightBollinger*g_bollingerSnapshot[(int)STRATEGY_SWING].quality;
   }
   score.total=NormalizeEnabledScore(score.part1+score.part2+score.part3+score.part4+score.part5+score.part6+score.part7,enabledWeight);
   score.explanation = StringFormat("D1强度%.1f + H4强度%.1f + 区域/SR%.1f + M30确认%.1f + EMA/RSI%.1f + MACD%.1f + Bollinger%.1f => 标准化%.1f",
                                    score.part1,score.part2,score.part3,score.part4,score.part5,score.part6,score.part7,score.total);
}

void RecordDetectedSignals(StrategyId strategy)
{
   int s=(int)strategy;
   if(g_runtime[s].candle.valid && g_runtime[s].candle.candleTime>0 &&
      g_runtime[s].candle.candleTime!=g_funnel[s].lastCandleCounted)
   {
      g_funnel[s].candlePatternsDetected++;
      g_funnel[s].lastCandleCounted=g_runtime[s].candle.candleTime;
   }
   if(g_runtime[s].pattern.valid && g_runtime[s].pattern.id!="" &&
      g_runtime[s].pattern.id!=g_funnel[s].lastPatternIdCounted)
   {
      g_funnel[s].chartPatternsDetected++;
      g_funnel[s].lastPatternIdCounted=g_runtime[s].pattern.id;
   }
}

void UpdateClosedBarSignals(bool newM5, bool newM30, bool newSwingEntry)
{
   if(newM5)
   {
      int dir = 0;
      if(g_scalpDemand.state == ZONE_FIRST_TOUCH) dir = 1;
      if(g_scalpSupply.state == ZONE_FIRST_TOUCH) dir = -1;
      DetectCandlestickSignal(PERIOD_M5, dir, dir != 0, g_runtime[(int)STRATEGY_SCALPING].candle);
      DetectBestChartPattern(PERIOD_M5, dir, g_runtime[(int)STRATEGY_SCALPING].pattern);
      RecordDetectedSignals(STRATEGY_SCALPING);
   }
   if(newM30)
   {
      int dir = 0;
      if(g_intradayDemand.state == ZONE_FIRST_TOUCH) dir = 1;
      if(g_intradaySupply.state == ZONE_FIRST_TOUCH) dir = -1;
      DetectCandlestickSignal(PERIOD_M30, dir, dir != 0, g_runtime[(int)STRATEGY_INTRADAY].candle);
      DetectBestChartPattern(PERIOD_M30, dir, g_runtime[(int)STRATEGY_INTRADAY].pattern);
      RecordDetectedSignals(STRATEGY_INTRADAY);
   }
   if(newSwingEntry)
   {
      int dir = DetectSwingTrend(InpSwingBiasTF, InpSwingLookbackBars, InpSwingDepth);
      DetectCandlestickSignal(InpSwingEntryTF, dir, g_swingZone.valid, g_runtime[(int)STRATEGY_SWING].candle);
      ChartPatternSignal d1Pattern, h4Pattern;
      DetectBestChartPattern(InpSwingBiasTF, dir, d1Pattern);
      DetectBestChartPattern(InpSwingSetupTF, dir, h4Pattern);
      g_runtime[(int)STRATEGY_SWING].pattern = (h4Pattern.valid && (!d1Pattern.valid || h4Pattern.score >= d1Pattern.score) ? h4Pattern : d1Pattern);
      RecordDetectedSignals(STRATEGY_SWING);
   }

   for(int s = 0; s < 3; s++)
   {
      g_runtime[s].candleName = (g_runtime[s].candle.valid ? g_runtime[s].candle.englishName + "/" + g_runtime[s].candle.chineseName : "-");
      g_runtime[s].candleStrength = CandleStrengthName(g_runtime[s].candle.strength);
      g_runtime[s].chartPattern = (g_runtime[s].pattern.valid ? g_runtime[s].pattern.englishName + "/" + g_runtime[s].pattern.chineseName + " " + PatternStateName(g_runtime[s].pattern.state) : "-");
   }
}

bool PlaceStrategyTradeForZone(StrategyId strategy,
                               int direction,
                               string comment,
                               double entry,
                               double sl,
                               double tp,
                               double fixedLot,
                               double riskPercent)
{
   int s = (int)strategy;
   double effectiveRisk=EffectiveStrategyRiskPercent(strategy,riskPercent);
   g_pendingRiskPercent[s]=effectiveRisk;
   g_pendingClusterId[s]=g_runtime[s].clusterId;
   if(!g_strategyEnabled[s])
   {
      g_runtime[s].rejectReason="图表策略开关已关闭，拒绝新订单";
      return false;
   }
   if(g_runtime[s].tradeLock)
   {
      g_runtime[s].rejectReason = "内部交易锁已占用";
      return false;
   }
   datetime lastClusterFill=0;
   if(ClusterCooldownActive(strategy,g_pendingClusterId[s],lastClusterFill))
   {
      g_runtime[s].rejectReason=StringFormat("相同机会簇冷却中 ClusterID=%s LastFill=%s",
                                             g_pendingClusterId[s],TimeToString(lastClusterFill,TIME_DATE|TIME_SECONDS));
      g_funnel[s].duplicateClusterRejected++;
      PrintFormat("CLUSTER_REJECT|SOP=%s|ClusterID=%s|ZoneID=%s|LastFill=%s|CooldownBars=%d",
                  g_runtime[s].name,g_pendingClusterId[s],g_pendingZoneId[s],
                  TimeToString(lastClusterFill,TIME_DATE|TIME_SECONDS),StrategyClusterCooldownBars(strategy));
      return false;
   }

   if(strategy != STRATEGY_SWING)
   {
      double minDistance = (double)(g_stopsLevel + 2) * g_point;
      bool exactStopsValid = (direction > 0 ? entry - sl >= minDistance && tp - entry >= minDistance
                                            : sl - entry >= minDistance && entry - tp >= minDistance);
      if(!exactStopsValid)
      {
         g_runtime[s].rejectReason = "经纪商Stop Level大于固定SOP止损/止盈距离，拒绝开仓而不改变固定RR";
         PrintFormat("%s拒绝：固定SOP距离不符合Stop Level=%d points",g_runtime[s].name,g_stopsLevel);
         return false;
      }
   }
   g_runtime[s].tradeLock = true;
   bool opened = PlaceStrategyTrade(direction, StrategyMagic(strategy), comment, entry, sl, tp, fixedLot, effectiveRisk);
   g_runtime[s].tradeLock = false;
   g_runtime[s].status = (opened ? "订单已发送，等待服务器成交确认" : "下单失败" );
   if(!opened)
   {
      if(g_runtime[s].rejectReason=="")
         g_runtime[s].rejectReason = trade.ResultRetcodeDescription();
      g_pendingZoneId[s]="";
      g_pendingClusterId[s]="";
      g_pendingRiskPercent[s]=0.0;
      ResetPendingVolumeAudit(s);
      g_pendingZoneWidth[s]=0.0;
      g_pendingTouchDepth[s]=0.0;
      g_pendingFalseBreak[s]=false;
      g_pendingChaseEntry[s]=false;
   }
   return opened;
}

//+------------------------------------------------------------------+
//| Restart persistence and server-confirmed transaction statistics  |
//+------------------------------------------------------------------+
string StateKey(string slot, string field)
{
   return StringFormat("GSM2_%I64d_%u_%s_%s", (long)AccountInfoInteger(ACCOUNT_LOGIN), HashText(g_symbol), slot, field);
}

void SetStateValue(string slot, string field, double value)
{
   GlobalVariableSet(StateKey(slot, field), value);
}

double GetStateValue(string slot, string field, double fallback)
{
   string key = StateKey(slot, field);
   return (GlobalVariableCheck(key) ? GlobalVariableGet(key) : fallback);
}

void SaveZoneSlot(string slot, Zone &zone)
{
   SetStateValue(slot,"V",(zone.valid ? 1.0 : 0.0));
   SetStateValue(slot,"D",(double)zone.dir);
   SetStateValue(slot,"T",zone.top);
   SetStateValue(slot,"B",zone.bottom);
   SetStateValue(slot,"CT",(double)zone.createdTime);
   SetStateValue(slot,"DT",(double)zone.departureTime);
   SetStateValue(slot,"FT",(double)zone.firstTouchTime);
   SetStateValue(slot,"FB",(double)zone.firstTouchBarTime);
   SetStateValue(slot,"FP",zone.firstTouchPrice);
   SetStateValue(slot,"N",(double)zone.touches);
   SetStateValue(slot,"F",(double)zone.formation);
   SetStateValue(slot,"S",(double)zone.state);
   SetStateValue(slot,"Q",zone.qualityScore);
   SetStateValue(slot,"SC",zone.score);
   SetStateValue(slot,"BR",(zone.broken ? 1.0 : 0.0));
   SetStateValue(slot,"U",(zone.used ? 1.0 : 0.0));
   SetStateValue(slot,"E",(zone.expired ? 1.0 : 0.0));
   SetStateValue(slot,"TF",(double)zone.timeframe);
}

void LoadZoneSlot(string slot, Zone &zone)
{
   bool exists = GlobalVariableCheck(StateKey(slot,"CT"));
   if(!exists)
   {
      zone.valid = false;
      return;
   }
   int dir = (int)GetStateValue(slot,"D",0.0);
   datetime created = (datetime)GetStateValue(slot,"CT",0.0);
   SDFormationType formation = (SDFormationType)(int)GetStateValue(slot,"F",0.0);
   InitializeZone(zone,dir,0,created,formation);
   zone.valid = (GetStateValue(slot,"V",0.0) > 0.5);
   zone.top = GetStateValue(slot,"T",0.0);
   zone.bottom = GetStateValue(slot,"B",0.0);
   zone.departureTime = (datetime)GetStateValue(slot,"DT",0.0);
   zone.firstTouchTime = (datetime)GetStateValue(slot,"FT",0.0);
   zone.firstTouchBarTime = (datetime)GetStateValue(slot,"FB",0.0);
   zone.firstTouchPrice = GetStateValue(slot,"FP",0.0);
   zone.touches = (int)GetStateValue(slot,"N",0.0);
   zone.state = (ZoneLifecycle)(int)GetStateValue(slot,"S",(double)ZONE_FORMING);
   zone.qualityScore = GetStateValue(slot,"Q",0.0);
   zone.score = GetStateValue(slot,"SC",0.0);
   zone.broken = (GetStateValue(slot,"BR",0.0) > 0.5);
   zone.used = (GetStateValue(slot,"U",0.0) > 0.5);
   zone.expired = (GetStateValue(slot,"E",0.0) > 0.5);
   zone.timeframe = (ENUM_TIMEFRAMES)(int)GetStateValue(slot,"TF",(double)PERIOD_CURRENT);
   zone.symbol = g_symbol;
   zone.proximal = (dir > 0 ? zone.top : zone.bottom);
   zone.distal = (dir > 0 ? zone.bottom : zone.top);
   zone.width = zone.top - zone.bottom;
   zone.id = BuildZoneID(zone,zone.timeframe);
   if(ZoneWasPermanentlyUsed(zone.id))
   {
      zone.used = true;
      zone.state = ZONE_USED;
   }
}

void SaveRuntimeSlot(int strategy)
{
   string slot = "R" + IntegerToString(strategy);
   SetStateValue(slot,"FZD",(double)g_funnel[strategy].zonesDetected);
   SetStateValue(slot,"FZP",(double)g_funnel[strategy].zonesDeparted);
   SetStateValue(slot,"FFT",(double)g_funnel[strategy].firstTouches);
   SetStateValue(slot,"FCD",(double)g_funnel[strategy].candlePatternsDetected);
   SetStateValue(slot,"FCH",(double)g_funnel[strategy].chartPatternsDetected);
   SetStateValue(slot,"FHS",(double)g_funnel[strategy].hardSOPPassed);
   SetStateValue(slot,"FCP",(double)g_funnel[strategy].confidencePassed);
   SetStateValue(slot,"FGP",(double)g_funnel[strategy].globalGatePassed);
   SetStateValue(slot,"FOR",(double)g_funnel[strategy].ordersRequested);
   SetStateValue(slot,"FOF",(double)g_funnel[strategy].ordersFilled);
   SetStateValue(slot,"FOJ",(double)g_funnel[strategy].ordersRejected);
   SetStateValue(slot,"FEP",(double)g_funnel[strategy].emaPassed);
   SetStateValue(slot,"FER",(double)g_funnel[strategy].emaRejected);
   SetStateValue(slot,"FRP",(double)g_funnel[strategy].rsiPassed);
   SetStateValue(slot,"FRR",(double)g_funnel[strategy].rsiRejected);
   SetStateValue(slot,"FME",(double)g_funnel[strategy].macdEvaluated);
   SetStateValue(slot,"FMP",(double)g_funnel[strategy].macdPassed);
   SetStateValue(slot,"FCR",(double)g_funnel[strategy].confidenceRejected);
   SetStateValue(slot,"FSR",(double)g_funnel[strategy].sessionRejected);
   SetStateValue(slot,"FSP",(double)g_funnel[strategy].spreadRejected);
   SetStateValue(slot,"FPR",(double)g_funnel[strategy].positionLimitRejected);
   SetStateValue(slot,"FRK",(double)g_funnel[strategy].riskRejected);
   SetStateValue(slot,"FMR",(double)g_funnel[strategy].marginRejected);
   SetStateValue(slot,"FML",(double)g_funnel[strategy].minimumLotRiskRejected);
   SetStateValue(slot,"FTR",(double)g_funnel[strategy].totalRiskRejected);
   SetStateValue(slot,"FIF",(double)g_funnel[strategy].insufficientFundsRejected);
   SetStateValue(slot,"FIW",(double)g_funnel[strategy].indicatorDataWaits);
   SetStateValue(slot,"FMW",(double)g_funnel[strategy].macdDataWaits);
   SetStateValue(slot,"FDR",(double)g_funnel[strategy].duplicateZoneRejected);
   SetStateValue(slot,"FD1",(double)g_funnel[strategy].d1DirectionPassed);
   SetStateValue(slot,"FH4",(double)g_funnel[strategy].h4DirectionPassed);
   SetStateValue(slot,"FHZ",(double)g_funnel[strategy].h4ZonesFound);
   SetStateValue(slot,"FSC",(double)g_funnel[strategy].srConfluencePassed);
   SetStateValue(slot,"FMT",(double)g_funnel[strategy].m30Touches);
   SetStateValue(slot,"FMC",(double)g_funnel[strategy].m30Confirmations);
   SetStateValue(slot,"FLC",(double)g_funnel[strategy].lastCandleCounted);
   SetStateValue(slot,"LB",(double)g_runtime[strategy].lastEvaluatedBar);
   SetStateValue(slot,"LC",(double)g_runtime[strategy].lastProcessedCandle);
   SetStateValue(slot,"PU",(double)g_runtime[strategy].pauseUntil);
   SetStateValue(slot,"PT",(double)g_runtime[strategy].pattern.type);
   SetStateValue(slot,"PS",(double)g_runtime[strategy].pattern.state);
   SetStateValue(slot,"PB",(double)g_runtime[strategy].pattern.startTime);
   SetStateValue(slot,"PE",(double)g_runtime[strategy].pattern.endTime);
   SetStateValue(slot,"PD",(double)g_runtime[strategy].pattern.direction);
   SetStateValue(slot,"PN",g_runtime[strategy].pattern.neckline);
   SetStateValue(slot,"PX",g_runtime[strategy].pattern.breakoutPrice);
   SetStateValue(slot,"PR",g_runtime[strategy].pattern.retestPrice);
   SetStateValue(slot,"PI",g_runtime[strategy].pattern.invalidationPrice);
   SetStateValue(slot,"PG",g_runtime[strategy].pattern.projectedTarget);
   SetStateValue(slot,"PQ",g_runtime[strategy].pattern.score);
   SetStateValue(slot,"PF",(double)g_runtime[strategy].pattern.timeframe);
   for(int i=0;i<6;i++)
      SetStateValue(slot,"PK"+IntegerToString(i),g_runtime[strategy].pattern.keyPrices[i]);
   SetStateValue(slot,"CB",(double)g_runtime[strategy].candle.candleTime);
   SetStateValue(slot,"CT",(double)g_runtime[strategy].candle.type);
   SetStateValue(slot,"CD",(double)g_runtime[strategy].candle.direction);
   SetStateValue(slot,"CS",(double)g_runtime[strategy].candle.strength);
   SetStateValue(slot,"CF",(double)g_runtime[strategy].candle.timeframe);
   SetStateValue(slot,"CV",g_runtime[strategy].candle.volumeRatio);
   SetStateValue(slot,"CQ",g_runtime[strategy].candle.quality);
}

void LoadRuntimeSlot(int strategy)
{
   string slot = "R" + IntegerToString(strategy);
   g_funnel[strategy].zonesDetected=(long)GetStateValue(slot,"FZD",0.0);
   g_funnel[strategy].zonesDeparted=(long)GetStateValue(slot,"FZP",0.0);
   g_funnel[strategy].firstTouches=(long)GetStateValue(slot,"FFT",0.0);
   g_funnel[strategy].candlePatternsDetected=(long)GetStateValue(slot,"FCD",0.0);
   g_funnel[strategy].chartPatternsDetected=(long)GetStateValue(slot,"FCH",0.0);
   g_funnel[strategy].hardSOPPassed=(long)GetStateValue(slot,"FHS",0.0);
   g_funnel[strategy].confidencePassed=(long)GetStateValue(slot,"FCP",0.0);
   g_funnel[strategy].globalGatePassed=(long)GetStateValue(slot,"FGP",0.0);
   g_funnel[strategy].ordersRequested=(long)GetStateValue(slot,"FOR",0.0);
   g_funnel[strategy].ordersFilled=(long)GetStateValue(slot,"FOF",0.0);
   g_funnel[strategy].ordersRejected=(long)GetStateValue(slot,"FOJ",0.0);
   g_funnel[strategy].emaPassed=(long)GetStateValue(slot,"FEP",0.0);
   g_funnel[strategy].emaRejected=(long)GetStateValue(slot,"FER",0.0);
   g_funnel[strategy].rsiPassed=(long)GetStateValue(slot,"FRP",0.0);
   g_funnel[strategy].rsiRejected=(long)GetStateValue(slot,"FRR",0.0);
   g_funnel[strategy].macdEvaluated=(long)GetStateValue(slot,"FME",0.0);
   g_funnel[strategy].macdPassed=(long)GetStateValue(slot,"FMP",0.0);
   g_funnel[strategy].confidenceRejected=(long)GetStateValue(slot,"FCR",0.0);
   g_funnel[strategy].sessionRejected=(long)GetStateValue(slot,"FSR",0.0);
   g_funnel[strategy].spreadRejected=(long)GetStateValue(slot,"FSP",0.0);
   g_funnel[strategy].positionLimitRejected=(long)GetStateValue(slot,"FPR",0.0);
   g_funnel[strategy].riskRejected=(long)GetStateValue(slot,"FRK",0.0);
   g_funnel[strategy].marginRejected=(long)GetStateValue(slot,"FMR",0.0);
   g_funnel[strategy].minimumLotRiskRejected=(long)GetStateValue(slot,"FML",0.0);
   g_funnel[strategy].totalRiskRejected=(long)GetStateValue(slot,"FTR",0.0);
   g_funnel[strategy].insufficientFundsRejected=(long)GetStateValue(slot,"FIF",0.0);
   g_funnel[strategy].indicatorDataWaits=(long)GetStateValue(slot,"FIW",0.0);
   g_funnel[strategy].macdDataWaits=(long)GetStateValue(slot,"FMW",0.0);
   g_funnel[strategy].duplicateZoneRejected=(long)GetStateValue(slot,"FDR",0.0);
   g_funnel[strategy].d1DirectionPassed=(long)GetStateValue(slot,"FD1",0.0);
   g_funnel[strategy].h4DirectionPassed=(long)GetStateValue(slot,"FH4",0.0);
   g_funnel[strategy].h4ZonesFound=(long)GetStateValue(slot,"FHZ",0.0);
   g_funnel[strategy].srConfluencePassed=(long)GetStateValue(slot,"FSC",0.0);
   g_funnel[strategy].m30Touches=(long)GetStateValue(slot,"FMT",0.0);
   g_funnel[strategy].m30Confirmations=(long)GetStateValue(slot,"FMC",0.0);
   g_funnel[strategy].lastCandleCounted=(datetime)GetStateValue(slot,"FLC",0.0);
   g_runtime[strategy].lastEvaluatedBar = (datetime)GetStateValue(slot,"LB",0.0);
   g_runtime[strategy].lastProcessedCandle = (datetime)GetStateValue(slot,"LC",0.0);
   g_runtime[strategy].pauseUntil = (datetime)GetStateValue(slot,"PU",0.0);
   g_runtime[strategy].pattern.type = (ChartPatternType)(int)GetStateValue(slot,"PT",0.0);
   g_runtime[strategy].pattern.state = (ChartPatternState)(int)GetStateValue(slot,"PS",0.0);
   g_runtime[strategy].pattern.startTime = (datetime)GetStateValue(slot,"PB",0.0);
   g_runtime[strategy].pattern.endTime = (datetime)GetStateValue(slot,"PE",0.0);
   g_runtime[strategy].pattern.direction = (int)GetStateValue(slot,"PD",0.0);
   g_runtime[strategy].pattern.neckline = GetStateValue(slot,"PN",0.0);
   g_runtime[strategy].pattern.breakoutPrice = GetStateValue(slot,"PX",0.0);
   g_runtime[strategy].pattern.retestPrice = GetStateValue(slot,"PR",0.0);
   g_runtime[strategy].pattern.invalidationPrice = GetStateValue(slot,"PI",0.0);
   g_runtime[strategy].pattern.projectedTarget = GetStateValue(slot,"PG",0.0);
   g_runtime[strategy].pattern.score = GetStateValue(slot,"PQ",0.0);
   g_runtime[strategy].pattern.timeframe = (ENUM_TIMEFRAMES)(int)GetStateValue(slot,"PF",0.0);
   for(int i=0;i<6;i++)
      g_runtime[strategy].pattern.keyPrices[i]=GetStateValue(slot,"PK"+IntegerToString(i),0.0);
   g_runtime[strategy].pattern.valid=(g_runtime[strategy].pattern.type!=CHART_PATTERN_NONE);
   if(g_runtime[strategy].pattern.valid)
   {
      ChartPatternNames(g_runtime[strategy].pattern.type,g_runtime[strategy].pattern.englishName,g_runtime[strategy].pattern.chineseName);
      g_runtime[strategy].pattern.id=StringFormat("%s_%s_%d_%I64d",g_symbol,TimeframeTag(g_runtime[strategy].pattern.timeframe),(int)g_runtime[strategy].pattern.type,(long)g_runtime[strategy].pattern.startTime);
      g_funnel[strategy].lastPatternIdCounted=g_runtime[strategy].pattern.id;
   }
   g_runtime[strategy].candle.candleTime = (datetime)GetStateValue(slot,"CB",0.0);
   g_runtime[strategy].candle.type = (CandlePatternType)(int)GetStateValue(slot,"CT",0.0);
   g_runtime[strategy].candle.direction = (int)GetStateValue(slot,"CD",0.0);
   g_runtime[strategy].candle.strength = (CandleStrength)(int)GetStateValue(slot,"CS",0.0);
   g_runtime[strategy].candle.timeframe = (ENUM_TIMEFRAMES)(int)GetStateValue(slot,"CF",0.0);
   g_runtime[strategy].candle.volumeRatio = GetStateValue(slot,"CV",0.0);
   g_runtime[strategy].candle.quality = GetStateValue(slot,"CQ",0.0);
   g_runtime[strategy].candle.valid=(g_runtime[strategy].candle.type!=CANDLE_NONE);
   if(g_runtime[strategy].candle.valid)
      CandlePatternNames(g_runtime[strategy].candle.type,g_runtime[strategy].candle.englishName,g_runtime[strategy].candle.chineseName);
}

void SavePersistentState()
{
   if(g_symbol == "" || MQLInfoInteger(MQL_TESTER))
      return;
   SaveZoneSlot("SD0",g_scalpDemand);
   SaveZoneSlot("SS0",g_scalpSupply);
   SaveZoneSlot("ID1",g_intradayDemand);
   SaveZoneSlot("IS1",g_intradaySupply);
   SaveZoneSlot("SW2",g_swingZone);
   for(int s=0;s<3;s++)
      SaveRuntimeSlot(s);
   SetStateValue("CORE","M5",(double)g_lastM5Bar);
   SetStateValue("CORE","M30",(double)g_lastM30Bar);
   SetStateValue("CORE","SW",(double)g_lastSwingBar);
   SetStateValue("CORE","SP",(double)g_scalpPauseUntil);
   SetStateValue("CORE","SD",(double)g_lastScalpPauseDeal);
   SetStateValue("CORE","IR",g_swingInitialRisk);
   SetStateValue("CORE","HI",g_swingHighestSinceEntry);
   SetStateValue("CORE","LO",g_swingLowestSinceEntry);
   SetStateValue("CORE","MS",(double)g_swingManagementStage);
   GlobalVariablesFlush();
}

void LoadPersistentState()
{
   LoadZoneSlot("SD0",g_scalpDemand);
   LoadZoneSlot("SS0",g_scalpSupply);
   LoadZoneSlot("ID1",g_intradayDemand);
   LoadZoneSlot("IS1",g_intradaySupply);
   LoadZoneSlot("SW2",g_swingZone);
   for(int s=0;s<3;s++)
      LoadRuntimeSlot(s);
   g_lastM5Bar = (datetime)GetStateValue("CORE","M5",0.0);
   g_lastM30Bar = (datetime)GetStateValue("CORE","M30",0.0);
   g_lastSwingBar = (datetime)GetStateValue("CORE","SW",0.0);
   g_scalpPauseUntil = (datetime)GetStateValue("CORE","SP",0.0);
   g_lastScalpPauseDeal = (ulong)GetStateValue("CORE","SD",0.0);
   g_swingInitialRisk = GetStateValue("CORE","IR",0.0);
   g_swingHighestSinceEntry = GetStateValue("CORE","HI",0.0);
   g_swingLowestSinceEntry = GetStateValue("CORE","LO",0.0);
   g_swingManagementStage = (int)GetStateValue("CORE","MS",0.0);
}

void SavePersistentStateThrottled()
{
   static datetime lastSave = 0;
   if(TimeCurrent() - lastSave < 30)
      return;
   lastSave = TimeCurrent();
   SavePersistentState();
}

void RebuildRuntimeStatistics()
{
   for(int s=0;s<3;s++)
   {
      long magic = StrategyMagic((StrategyId)s);
      g_runtime[s].todayTrades = CountEntryDealsToday(magic);
      ulong lastDeal = 0;
      int streak = CurrentClosedTradeStreak(magic,lastDeal);
      g_runtime[s].winStreak = (streak > 0 ? streak : 0);
      g_runtime[s].lossStreak = (streak < 0 ? -streak : 0);
   }
   UpdateScalpPause(InpScalpMagic);
   g_runtime[(int)STRATEGY_SCALPING].pauseUntil = g_scalpPauseUntil;
}

void UpdateRuntimeStatisticsIfNeeded()
{
   static datetime lastUpdate = 0;
   if(TimeCurrent() - lastUpdate < 60)
      return;
   lastUpdate = TimeCurrent();
   RebuildRuntimeStatistics();
}

void RecoverOpenPositions()
{
   for(int s=0;s<3;s++)
   {
      int count = CountOpenPositionsByMagic(StrategyMagic((StrategyId)s));
      if(count > 0)
      {
         g_runtime[s].status = "重启后已恢复持仓管理";
         PrintFormat("恢复策略持仓：%s Magic=%I64d Count=%d",g_runtime[s].name,StrategyMagic((StrategyId)s),count);
      }
   }
   ulong ticket=0;
   if(SelectPositionByMagic(InpSwingMagic,ticket))
   {
      g_swingPositionTicket=ticket;
      double entry=PositionGetDouble(POSITION_PRICE_OPEN);
      double sl=PositionGetDouble(POSITION_SL);
      if(g_swingInitialRisk<=0.0 && entry>0.0 && sl>0.0)
         g_swingInitialRisk=MathAbs(entry-sl);
      if(g_swingHighestSinceEntry<=0.0) g_swingHighestSinceEntry=entry;
      if(g_swingLowestSinceEntry<=0.0) g_swingLowestSinceEntry=entry;
   }
}

bool SelectPositionByIdentifier(ulong identifier,long magic,ulong &ticket)
{
   ticket=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong candidate=PositionGetTicket(i);
      if(candidate==0 || !PositionSelectByTicket(candidate))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=g_symbol ||
         (long)PositionGetInteger(POSITION_MAGIC)!=magic)
         continue;
      ulong positionIdentifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
      if(identifier==0 || positionIdentifier==identifier)
      {
         ticket=candidate;
         return true;
      }
   }
   return false;
}

bool RecenterFixedStopsAfterFill(int strategy,ulong deal)
{
   if(!InpRecenterFixedStopsAfterFill || strategy==(int)STRATEGY_SWING)
      return true;

   ulong identifier=(ulong)HistoryDealGetInteger(deal,DEAL_POSITION_ID);
   ulong ticket=0;
   long magic=StrategyMagic((StrategyId)strategy);
   if(!SelectPositionByIdentifier(identifier,magic,ticket) || !PositionSelectByTicket(ticket))
   {
      PrintFormat("成交后固定SL/TP校准等待：Strategy=%s Deal=%I64u PositionID=%I64u",
                  g_runtime[strategy].name,deal,identifier);
      return false;
   }

   double entry=PositionGetDouble(POSITION_PRICE_OPEN);
   ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   bool isBuy=(type==POSITION_TYPE_BUY);
   double slDistance=(strategy==(int)STRATEGY_SCALPING ? CoursePipsToPrice(InpScalpSLPips)
                                                       : PTToPrice(InpIntradaySLPoints));
   double tpDistance=(strategy==(int)STRATEGY_SCALPING ? CoursePipsToPrice(InpScalpTPPips)
                                                       : PTToPrice(InpIntradayTPPoints));
   double sl=NormalizePrice(isBuy ? entry-slDistance : entry+slDistance);
   double tp=NormalizePrice(isBuy ? entry+tpDistance : entry-tpDistance);
   double currentPrice=(isBuy ? g_tick.bid : g_tick.ask);
   if(currentPrice<=0.0)
   {
      MqlTick currentTick;
      if(!SymbolInfoTick(g_symbol,currentTick))
         return false;
      currentPrice=(isBuy ? currentTick.bid : currentTick.ask);
   }
   double minDistance=(double)(g_stopsLevel+2)*g_point;
   bool valid=(isBuy ? currentPrice-sl>=minDistance && tp-currentPrice>=minDistance
                     : sl-currentPrice>=minDistance && currentPrice-tp>=minDistance);
   if(!valid)
   {
      PrintFormat("成交后固定SL/TP未校准：Strategy=%s Ticket=%I64u 当前价格已进入StopLevel，保留原保护单。Entry=%s SL=%s TP=%s",
                  g_runtime[strategy].name,ticket,DoubleToString(entry,g_digits),
                  DoubleToString(sl,g_digits),DoubleToString(tp,g_digits));
      return false;
   }

   double oldSL=PositionGetDouble(POSITION_SL);
   double oldTP=PositionGetDouble(POSITION_TP);
   if(MathAbs(oldSL-sl)<g_tickSize*0.5 && MathAbs(oldTP-tp)<g_tickSize*0.5)
      return true;
   if(!trade.PositionModify(ticket,sl,tp))
   {
      PrintFormat("成交后固定SL/TP校准失败：Strategy=%s Ticket=%I64u Retcode=%d %s，保留原保护单。",
                  g_runtime[strategy].name,ticket,trade.ResultRetcode(),trade.ResultRetcodeDescription());
      return false;
   }
   PrintFormat("成交后固定SL/TP已按服务器均价校准：Strategy=%s Ticket=%I64u Entry=%s SL=%s TP=%s",
               g_runtime[strategy].name,ticket,DoubleToString(entry,g_digits),
               DoubleToString(sl,g_digits),DoubleToString(tp,g_digits));
   return true;
}

string PositionZoneKey(ulong identifier)
{
   return StringFormat("GSM40_POS_ZONE_%I64d_%u_%I64u",(long)AccountInfoInteger(ACCOUNT_LOGIN),HashText(g_symbol),identifier);
}

double ActualPositionRiskPercent(ulong identifier,long magic)
{
   ulong ticket=0;
   if(!SelectPositionByIdentifier(identifier,magic,ticket) || !PositionSelectByTicket(ticket))
      return 0.0;
   double entry=PositionGetDouble(POSITION_PRICE_OPEN);
   double sl=PositionGetDouble(POSITION_SL);
   double volume=PositionGetDouble(POSITION_VOLUME);
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   if(entry<=0.0 || sl<=0.0 || volume<=0.0 || equity<=0.0)
      return 0.0;
   ENUM_POSITION_TYPE positionType=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   ENUM_ORDER_TYPE orderType=(positionType==POSITION_TYPE_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
   double result=0.0;
   if(!OrderCalcProfit(orderType,g_symbol,volume,entry,sl,result) || result>=0.0)
      return 0.0;
   return -result/equity*100.0;
}

void PreparePendingTradeAudit(StrategyId strategy,Zone &zone,bool falseBreak)
{
   int s=(int)strategy;
   g_pendingClusterId[s]=g_runtime[s].clusterId;
   g_pendingZoneWidth[s]=zone.width;
   g_pendingFalseBreak[s]=falseBreak;
   double touchPrice=(zone.firstTouchPrice>0.0 ? zone.firstTouchPrice : (g_tick.ask+g_tick.bid)*0.5);
   double depth=0.0;
   if(zone.width>0.0)
      depth=(zone.dir>0 ? (zone.top-touchPrice)/zone.width : (touchPrice-zone.bottom)/zone.width);
   g_pendingTouchDepth[s]=MathMax(-2.0,MathMin(3.0,depth));
   double market=(zone.dir>0 ? g_tick.ask : g_tick.bid);
   g_pendingChaseEntry[s]=(zone.dir>0 ? market>zone.top+zone.width*0.15 : market<zone.bottom-zone.width*0.15);
}

int FindTradeAudit(ulong positionId)
{
   for(int i=0;i<ArraySize(g_tradeAudit);i++)
      if(g_tradeAudit[i].active && g_tradeAudit[i].positionId==positionId)
         return i;
   return -1;
}

void StartTradeAuditFromDeal(int strategy,ulong deal,ulong positionId)
{
   if(!InpEnableTradeReviewCSV || positionId==0 || FindTradeAudit(positionId)>=0)
      return;
   int index=ArraySize(g_tradeAudit);
   ArrayResize(g_tradeAudit,index+1);
   g_tradeAudit[index].active=true;
   g_tradeAudit[index].positionId=positionId;
   g_tradeAudit[index].strategy=strategy;
   ENUM_DEAL_TYPE dealType=(ENUM_DEAL_TYPE)HistoryDealGetInteger(deal,DEAL_TYPE);
   g_tradeAudit[index].direction=(dealType==DEAL_TYPE_BUY ? 1 : -1);
   g_tradeAudit[index].zoneId=g_pendingZoneId[strategy];
   g_tradeAudit[index].clusterId=g_pendingClusterId[strategy];
   g_tradeAudit[index].entryTime=(datetime)HistoryDealGetInteger(deal,DEAL_TIME);
   g_tradeAudit[index].entryPrice=HistoryDealGetDouble(deal,DEAL_PRICE);
   g_tradeAudit[index].volume=HistoryDealGetDouble(deal,DEAL_VOLUME);
   g_tradeAudit[index].magic=StrategyMagic((StrategyId)strategy);
   g_tradeAudit[index].calculatedVolume=g_pendingCalculatedVolume[strategy];
   g_tradeAudit[index].actualSLRiskMoney=g_pendingActualSLRiskMoney[strategy];
   g_tradeAudit[index].actualSLRiskPercent=g_pendingActualSLRiskPercent[strategy];
   g_tradeAudit[index].forcedMinimumLot=g_pendingForcedMinimumLot[strategy];
   g_tradeAudit[index].confidence100Boost=g_pendingConfidence100Boost[strategy];
   MqlDateTime entryParts={};
   TimeToStruct(g_tradeAudit[index].entryTime,entryParts);
   g_tradeAudit[index].serverHour=entryParts.hour;
   g_tradeAudit[index].initialSL=0.0;
   g_tradeAudit[index].initialTP=0.0;
   ulong ticket=0;
   if(SelectPositionByIdentifier(positionId,StrategyMagic((StrategyId)strategy),ticket) && PositionSelectByTicket(ticket))
   {
      g_tradeAudit[index].initialSL=PositionGetDouble(POSITION_SL);
      g_tradeAudit[index].initialTP=PositionGetDouble(POSITION_TP);
   }
   g_tradeAudit[index].spreadPoints=(double)CurrentSpreadPoints();
   g_tradeAudit[index].atr=(g_indicatorSnapshot[strategy].atr>0.0 ? g_indicatorSnapshot[strategy].atr :
                            CurrentATR(strategy==0 ? PERIOD_M5 : strategy==1 ? PERIOD_M30 : InpSwingEntryTF));
   g_tradeAudit[index].emaFast=g_indicatorSnapshot[strategy].emaFast;
   g_tradeAudit[index].emaSlow=g_indicatorSnapshot[strategy].emaSlow;
   g_tradeAudit[index].rsi=g_indicatorSnapshot[strategy].rsi;
   g_tradeAudit[index].macdMain=g_macdSnapshot[strategy].mainValue;
   g_tradeAudit[index].macdSignal=g_macdSnapshot[strategy].signalValue;
   g_tradeAudit[index].macdHistogram=g_macdSnapshot[strategy].histogram;
   g_tradeAudit[index].bollingerUpper=g_bollingerSnapshot[strategy].upper;
   g_tradeAudit[index].bollingerMiddle=g_bollingerSnapshot[strategy].middle;
   g_tradeAudit[index].bollingerLower=g_bollingerSnapshot[strategy].lower;
   g_tradeAudit[index].bollingerPercentB=g_bollingerSnapshot[strategy].percentB;
   g_tradeAudit[index].bollingerBandWidth=g_bollingerSnapshot[strategy].bandWidth;
   g_tradeAudit[index].bollingerBandWidthChange=g_bollingerSnapshot[strategy].bandWidthChange;
   g_tradeAudit[index].confidence=g_runtime[strategy].confidence;
   string actualRiskReason="";
   double actualMoney=0.0,actualPct=0.0;
   if(g_tradeAudit[index].initialSL>0.0 &&
      CalculateExactSLRisk(g_tradeAudit[index].direction,g_tradeAudit[index].entryPrice,g_tradeAudit[index].initialSL,
                           g_tradeAudit[index].volume,actualMoney,actualPct,actualRiskReason))
   {
      g_tradeAudit[index].actualSLRiskMoney=actualMoney;
      g_tradeAudit[index].actualSLRiskPercent=actualPct;
   }
   g_tradeAudit[index].zoneWidth=g_pendingZoneWidth[strategy];
   g_tradeAudit[index].touchDepth=g_pendingTouchDepth[strategy];
   g_tradeAudit[index].falseBreak=g_pendingFalseBreak[strategy];
   g_tradeAudit[index].chaseEntry=g_pendingChaseEntry[strategy];
   g_tradeAudit[index].mfeMoney=0.0;
   g_tradeAudit[index].maeMoney=0.0;
   PrintFormat("TRADE_REVIEW_START|SOP=%s|Magic=%I64d|PositionID=%I64u|ZoneID=%s|ClusterID=%s|ATR=%g|Spread=%.1f|EMA=%g/%g|RSI=%.2f|MACD=%g/%g/%g|BBPercentB=%.4f|BBWidth=%.6f|BBChange=%.4f|Confidence=%.2f|CalculatedLot=%.8f|FinalLot=%s|SLRiskMoney=%.2f|SLRiskPct=%.4f|ForcedMin=%s|ConfidenceBoost=%s|ServerHour=%d|TouchDepth=%.3f|FalseBreak=%s|Chase=%s",
               g_runtime[strategy].name,g_tradeAudit[index].magic,positionId,g_tradeAudit[index].zoneId,g_tradeAudit[index].clusterId,g_tradeAudit[index].atr,
               g_tradeAudit[index].spreadPoints,g_tradeAudit[index].emaFast,g_tradeAudit[index].emaSlow,
               g_tradeAudit[index].rsi,g_tradeAudit[index].macdMain,g_tradeAudit[index].macdSignal,
               g_tradeAudit[index].macdHistogram,g_tradeAudit[index].bollingerPercentB,g_tradeAudit[index].bollingerBandWidth,
               g_tradeAudit[index].bollingerBandWidthChange,g_tradeAudit[index].confidence,g_tradeAudit[index].calculatedVolume,
               DoubleToString(g_tradeAudit[index].volume,VolumeDigits()),g_tradeAudit[index].actualSLRiskMoney,
               g_tradeAudit[index].actualSLRiskPercent,(g_tradeAudit[index].forcedMinimumLot?"YES":"NO"),
               (g_tradeAudit[index].confidence100Boost?"YES":"NO"),g_tradeAudit[index].serverHour,g_tradeAudit[index].touchDepth,
               (g_tradeAudit[index].falseBreak?"YES":"NO"),(g_tradeAudit[index].chaseEntry?"YES":"NO"));
}

void UpdateTradeAuditExcursions()
{
   if(!InpEnableTradeReviewCSV)
      return;
   for(int i=0;i<ArraySize(g_tradeAudit);i++)
   {
      if(!g_tradeAudit[i].active)
         continue;
      ulong ticket=0;
      long magic=StrategyMagic((StrategyId)g_tradeAudit[i].strategy);
      if(!SelectPositionByIdentifier(g_tradeAudit[i].positionId,magic,ticket))
         continue;
      MqlTick tick={};
      if(!SymbolInfoTick(g_symbol,tick))
         continue;
      double closePrice=(g_tradeAudit[i].direction>0 ? tick.bid : tick.ask);
      ENUM_ORDER_TYPE orderType=(g_tradeAudit[i].direction>0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
      double floating=0.0;
      if(!OrderCalcProfit(orderType,g_symbol,g_tradeAudit[i].volume,g_tradeAudit[i].entryPrice,closePrice,floating))
         continue;
      if(floating>g_tradeAudit[i].mfeMoney) g_tradeAudit[i].mfeMoney=floating;
      if(floating<0.0 && MathAbs(floating)>g_tradeAudit[i].maeMoney) g_tradeAudit[i].maeMoney=MathAbs(floating);
   }
}

double PositionLifetimeProfit(ulong positionId,double fallback)
{
   if(!HistorySelectByPosition(positionId))
      return fallback;
   double total=0.0;
   int deals=HistoryDealsTotal();
   for(int i=0;i<deals;i++)
   {
      ulong ticket=HistoryDealGetTicket(i);
      if(ticket==0)
         continue;
      total+=HistoryDealGetDouble(ticket,DEAL_PROFIT)+HistoryDealGetDouble(ticket,DEAL_SWAP)+
             HistoryDealGetDouble(ticket,DEAL_COMMISSION)+HistoryDealGetDouble(ticket,DEAL_FEE);
   }
   return total;
}

int StrategySpreadLimit(int strategy)
{
   if(strategy==0) return InpScalpMaxSpreadPoints;
   if(strategy==1) return InpIntradayMaxSpreadPoints;
   return InpSwingMaxSpreadPoints;
}

string StrategySessionText(int strategy)
{
   int startHour=InpScalpStartHour;
   int endHour=InpScalpEndHour;
   if(strategy==(int)STRATEGY_INTRADAY)
   {
      startHour=InpIntradayStartHour;
      endHour=InpIntradayEndHour;
   }
   else if(strategy==(int)STRATEGY_SWING)
   {
      startHour=InpSwingStartHour;
      endHour=InpSwingEndHour;
   }
   return StringFormat("SERVER_%02d-%02d",startHour,endHour);
}

string HeuristicLossClassification(TradeAuditTrack &audit,double profit)
{
   if(profit>=0.0)
      return "PROFIT";
   int spreadLimit=StrategySpreadLimit(audit.strategy);
   if(spreadLimit>0 && audit.spreadPoints>=spreadLimit*0.80)
      return "SPREAD_OR_SLIPPAGE_TOO_HIGH";
   double initialRisk=MathAbs(audit.entryPrice-audit.initialSL);
   if(audit.atr>0.0 && initialRisk>0.0 && initialRisk<audit.atr*0.75)
      return "STOP_TOO_TIGHT";
   if(audit.chaseEntry)
      return "ENTRY_TOO_LATE";
   if((audit.direction>0 && audit.bollingerPercentB>0.90 && audit.bollingerBandWidthChange<=0.02) ||
      (audit.direction<0 && audit.bollingerPercentB<0.10 && audit.bollingerBandWidthChange<=0.02))
      return "ENTRY_TOO_LATE";
   if(audit.falseBreak)
      return "FALSE_BREAKOUT";
   if(audit.emaFast!=0.0 && audit.emaSlow!=0.0 && audit.direction*(audit.emaFast-audit.emaSlow)<=0.0)
      return "TREND_DIRECTION_ERROR";
   if(audit.atr>0.0 && audit.zoneWidth>0.0 && audit.zoneWidth<audit.atr*0.35)
      return "RANGE_MARKET_FALSE_ENTRY";
   if(audit.bollingerBandWidth>0.0 && audit.atr>0.0 && audit.bollingerBandWidth<audit.atr*1.20 && audit.bollingerBandWidthChange<0.0)
      return "RANGE_MARKET_FALSE_ENTRY";
   if((audit.direction>0 && audit.rsi>72.0) || (audit.direction<0 && audit.rsi>0.0 && audit.rsi<28.0))
      return "EMA_RSI_MACD_JUDGMENT_ERROR";
   if(audit.confidence>=90.0)
      return "CONFIDENCE_OVERESTIMATED";
   return "MARKET_REGIME_UNSUITABLE";
}

void WriteTradeAuditCSV(TradeAuditTrack &audit,ulong exitDeal,double profit,string exitReason,string classification)
{
   int handle=FileOpen(InpTradeReviewFileName,FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_SHARE_READ|FILE_COMMON,',');
   if(handle==INVALID_HANDLE)
   {
      PrintFormat("TRADE_REVIEW_CSV_ERROR|File=%s|Error=%d",InpTradeReviewFileName,GetLastError());
      return;
   }
   bool empty=(FileSize(handle)==0);
   FileSeek(handle,0,SEEK_END);
   if(empty)
       FileWrite(handle,"Run","EntryTime","ExitTime","SOP","Magic","Direction","PositionID","ExitDeal","ZoneID","ClusterID",
                 "Entry","InitialSL","InitialTP","CalculatedVolume","Volume","ActualSLRiskMoney","ActualSLRiskPercent",
                 "ForcedMinimumLot","Confidence100Boost","ServerHour","StrategySession","Profit","MFE_Money","MAE_Money","ExitReason","LossClassification",
                 "SpreadPoints","ATR","ZoneWidth","TouchDepth","FalseBreak","ChaseEntry","EMA_Fast","EMA_Slow","RSI",
                 "MACD_Main","MACD_Signal","MACD_Histogram","BollingerUpper","BollingerMiddle","BollingerLower",
                 "BollingerPercentB","BollingerBandWidth","BollingerBandWidthChange","Confidence");
   FileWrite(handle,InpAuditRunLabel,TimeToString(audit.entryTime,TIME_DATE|TIME_SECONDS),TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),
              g_runtime[audit.strategy].name,audit.magic,(audit.direction>0?"BUY":"SELL"),audit.positionId,exitDeal,audit.zoneId,audit.clusterId,
              DoubleToString(audit.entryPrice,g_digits),DoubleToString(audit.initialSL,g_digits),DoubleToString(audit.initialTP,g_digits),
              DoubleToString(audit.calculatedVolume,8),DoubleToString(audit.volume,VolumeDigits()),
              DoubleToString(audit.actualSLRiskMoney,2),DoubleToString(audit.actualSLRiskPercent,4),
              (audit.forcedMinimumLot?"YES":"NO"),(audit.confidence100Boost?"YES":"NO"),audit.serverHour,StrategySessionText(audit.strategy),
              DoubleToString(profit,2),DoubleToString(audit.mfeMoney,2),DoubleToString(audit.maeMoney,2),
             exitReason,classification,DoubleToString(audit.spreadPoints,1),DoubleToString(audit.atr,g_digits),
             DoubleToString(audit.zoneWidth,g_digits),DoubleToString(audit.touchDepth,4),(audit.falseBreak?"YES":"NO"),(audit.chaseEntry?"YES":"NO"),
             DoubleToString(audit.emaFast,g_digits),DoubleToString(audit.emaSlow,g_digits),DoubleToString(audit.rsi,2),
             DoubleToString(audit.macdMain,6),DoubleToString(audit.macdSignal,6),DoubleToString(audit.macdHistogram,6),
             DoubleToString(audit.bollingerUpper,g_digits),DoubleToString(audit.bollingerMiddle,g_digits),DoubleToString(audit.bollingerLower,g_digits),
             DoubleToString(audit.bollingerPercentB,6),DoubleToString(audit.bollingerBandWidth,6),
             DoubleToString(audit.bollingerBandWidthChange,6),DoubleToString(audit.confidence,2));
   FileFlush(handle);
   ulong writtenBytes=FileSize(handle);
   FileClose(handle);
   PrintFormat("TRADE_REVIEW_CSV_WRITE|File=%s|Bytes=%I64u|CommonPath=%s\\Files",
               InpTradeReviewFileName,writtenBytes,TerminalInfoString(TERMINAL_COMMONDATA_PATH));
}

void FinalizeTradeAudit(ulong positionId,ulong exitDeal,double fallbackProfit)
{
   int index=FindTradeAudit(positionId);
   if(index<0)
      return;
   double profit=PositionLifetimeProfit(positionId,fallbackProfit);
   ENUM_DEAL_REASON reason=(ENUM_DEAL_REASON)HistoryDealGetInteger(exitDeal,DEAL_REASON);
   string exitReason=EnumToString(reason);
   string classification=HeuristicLossClassification(g_tradeAudit[index],profit);
   WriteTradeAuditCSV(g_tradeAudit[index],exitDeal,profit,exitReason,classification);
   PrintFormat("TRADE_REVIEW_END|SOP=%s|PositionID=%I64u|Profit=%.2f|MFE=%.2f|MAE=%.2f|Exit=%s|Class=%s",
               g_runtime[g_tradeAudit[index].strategy].name,positionId,profit,g_tradeAudit[index].mfeMoney,
               g_tradeAudit[index].maeMoney,exitReason,classification);
   g_tradeAudit[index].active=false;
}

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD || trans.deal == 0)
      return;
   if(!HistoryDealSelect(trans.deal))
      return;
   string symbol=HistoryDealGetString(trans.deal,DEAL_SYMBOL);
   long magic=(long)HistoryDealGetInteger(trans.deal,DEAL_MAGIC);
   if(symbol!=g_symbol)
      return;

   int strategy=-1;
   for(int s=0;s<3;s++)
      if(magic==StrategyMagic((StrategyId)s)) strategy=s;
   if(strategy<0)
      return;

   ENUM_DEAL_ENTRY entryType=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(trans.deal,DEAL_ENTRY);
   ulong identifier=(ulong)HistoryDealGetInteger(trans.deal,DEAL_POSITION_ID);
   if(entryType==DEAL_ENTRY_IN || entryType==DEAL_ENTRY_INOUT)
   {
      ulong filledOrder=(ulong)HistoryDealGetInteger(trans.deal,DEAL_ORDER);
      if(filledOrder==0 || filledOrder!=g_funnel[strategy].lastFilledOrder)
      {
         g_funnel[strategy].ordersFilled++;
         g_funnel[strategy].lastFilledOrder=filledOrder;
      }
      RecenterFixedStopsAfterFill(strategy,trans.deal);
      if(strategy==(int)STRATEGY_SWING)
         SaveSwingRiskForDeal(trans.deal);
      StartTradeAuditFromDeal(strategy,trans.deal,identifier);
      MarkClusterFilled((StrategyId)strategy,g_pendingClusterId[strategy]);
      if(identifier>0 && g_pendingZoneId[strategy]!="")
      {
         GlobalVariableSet(PositionZoneKey(identifier),(double)HashText(g_pendingZoneId[strategy]));
         PrintFormat("TRADE_ENTRY|Run=%s|Time=%s|SOP=%s|PositionID=%I64u|ZoneID=%s|ClusterID=%s|ZoneHash=%08X|RiskTarget=%.4f|CalculatedLot=%.8f|FinalLot=%s|SLRiskMoney=%.2f|SLRiskPct=%.4f|ForcedMin=%s|ConfidenceBoost=%s|Confidence=%.2f",
                      InpAuditRunLabel,TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),g_runtime[strategy].name,
                      identifier,g_pendingZoneId[strategy],g_pendingClusterId[strategy],HashText(g_pendingZoneId[strategy]),g_pendingRiskPercent[strategy],
                      g_pendingCalculatedVolume[strategy],DoubleToString(g_pendingFinalVolume[strategy],VolumeDigits()),
                      g_pendingActualSLRiskMoney[strategy],g_pendingActualSLRiskPercent[strategy],
                      (g_pendingForcedMinimumLot[strategy]?"YES":"NO"),(g_pendingConfidence100Boost[strategy]?"YES":"NO"),
                      g_runtime[strategy].confidence);
      }
      double actualRisk=ActualPositionRiskPercent(identifier,magic);
      PrintFormat("RISK_AUDIT|SOP=%s|PositionID=%I64u|TargetPct=%.4f|ActualSLRiskPct=%.4f|TotalOpenRiskPct=%.4f",
                  g_runtime[strategy].name,identifier,g_pendingRiskPercent[strategy],actualRisk,CalculateAccountOpenRiskPercent());
      if(g_pendingRiskPercent[strategy]>0.0 && actualRisk>g_pendingRiskPercent[strategy]*1.10)
         PrintFormat("风险警告：%s成交后实际SL风险%.4f%%明显超过目标%.4f%%",g_runtime[strategy].name,actualRisk,g_pendingRiskPercent[strategy]);
      g_pendingZoneId[strategy]="";
      g_pendingClusterId[strategy]="";
      g_pendingRiskPercent[strategy]=0.0;
      ResetPendingVolumeAudit(strategy);
      g_pendingZoneWidth[strategy]=0.0;
      g_pendingTouchDepth[strategy]=0.0;
      g_pendingFalseBreak[strategy]=false;
      g_pendingChaseEntry[strategy]=false;
   }
   double profit=HistoryDealGetDouble(trans.deal,DEAL_PROFIT)+HistoryDealGetDouble(trans.deal,DEAL_SWAP)+HistoryDealGetDouble(trans.deal,DEAL_COMMISSION);
   if(entryType==DEAL_ENTRY_OUT || entryType==DEAL_ENTRY_OUT_BY || entryType==DEAL_ENTRY_INOUT)
   {
      uint zoneHash=0;
      string zoneKey=PositionZoneKey(identifier);
      if(GlobalVariableCheck(zoneKey)) zoneHash=(uint)GlobalVariableGet(zoneKey);
      PrintFormat("TRADE_OUTCOME|Run=%s|Time=%s|SOP=%s|PositionID=%I64u|ZoneHash=%08X|Profit=%.2f|ExitDeal=%I64u",
                  InpAuditRunLabel,TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),g_runtime[strategy].name,
                  identifier,zoneHash,profit,trans.deal);
      ulong remainingTicket=0;
      if(!SelectPositionByIdentifier(identifier,magic,remainingTicket))
      {
         FinalizeTradeAudit(identifier,trans.deal,profit);
         if(GlobalVariableCheck(zoneKey)) GlobalVariableDel(zoneKey);
         string swingKey=SwingPositionRiskKey(identifier);
         if(GlobalVariableCheck(swingKey)) GlobalVariableDel(swingKey);
      }
   }
   PrintFormat("服务器成交确认：Strategy=%s Deal=%I64u Entry=%d Price=%s Volume=%s Profit=%s Retcode=%u %s",
               g_runtime[strategy].name,trans.deal,(int)entryType,
               DoubleToString(HistoryDealGetDouble(trans.deal,DEAL_PRICE),g_digits),
               DoubleToString(HistoryDealGetDouble(trans.deal,DEAL_VOLUME),VolumeDigits()),
               DoubleToString(profit,2),result.retcode,result.comment);
   RebuildRuntimeStatistics();
   SavePersistentState();
}

//+------------------------------------------------------------------+
//| Chinese diagnostics panel                                        |
//+------------------------------------------------------------------+
string DashboardObjectName(string suffix)
{
   return g_panelPrefix+suffix;
}

string StrategyButtonObjectName(int strategy)
{
   return DashboardObjectName("BUTTON_"+IntegerToString(strategy));
}

color StrategyAccentColor(int strategy)
{
   if(strategy==(int)STRATEGY_SCALPING) return C'51,199,190';
   if(strategy==(int)STRATEGY_INTRADAY) return C'238,190,79';
   return C'235,112,91';
}

int DashboardWidth()
{
   long chartWidth=ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0);
   if(chartWidth<=0)
      return 800;
   int available=(int)chartWidth-InpPanelXOffset-12;
   if(available<600)
      return 600;
   return (available>800 ? 800 : available);
}

void ConfigureDashboardRectangle(string name,int x,int y,int width,int height,color background,color border,int zorder)
{
   if(ObjectFind(0,name)<0)
      ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,height);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,background);
   ObjectSetInteger(0,name,OBJPROP_COLOR,border);
   ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_SOLID);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,1);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,zorder);
}

void ConfigureDashboardLabel(string name,int x,int y,int fontSize,color textColor,string text,int zorder)
{
   if(ObjectFind(0,name)<0)
      ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_COLOR,textColor);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,fontSize);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,zorder);
   ObjectSetString(0,name,OBJPROP_FONT,"Microsoft YaHei UI");
   ObjectSetString(0,name,OBJPROP_TEXT,text);
}

void ConfigureStrategyButton(int strategy,int x,int y,int width)
{
   string name=StrategyButtonObjectName(strategy);
   if(ObjectFind(0,name)<0)
      ObjectCreate(0,name,OBJ_BUTTON,0,0,0);
   bool enabled=g_strategyEnabled[strategy];
   string caption=(strategy==0 ? "SCALPING M5" : strategy==1 ? "INTRADAY M30" : "SWING D1/H4/M30");
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,32);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,(enabled ? C'35,125,91' : C'88,50,55'));
   ObjectSetInteger(0,name,OBJPROP_COLOR,C'248,249,250');
   ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,StrategyAccentColor(strategy));
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,MathMax(9,InpPanelFontSize));
   ObjectSetInteger(0,name,OBJPROP_STATE,false);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,30);
   ObjectSetString(0,name,OBJPROP_FONT,"Microsoft YaHei UI");
   ObjectSetString(0,name,OBJPROP_TEXT,caption+(enabled ? "  开启" : "  关闭"));
}

void CreateDashboardObjects()
{
   if(!InpShowPanel)
      return;
   int x=InpPanelXOffset;
   int y=InpPanelYOffset;
   int width=DashboardWidth();
   int buttonWidth=(width-36)/3;
   int cardTop=y+126;
   ConfigureDashboardRectangle(DashboardObjectName("BACKGROUND"),x,y,width,508,C'15,18,24',C'211,166,67',10);
   ConfigureDashboardRectangle(DashboardObjectName("HEADER"),x+1,y+1,width-2,72,C'22,27,35',C'22,27,35',11);
   ConfigureDashboardLabel(DashboardObjectName("TITLE"),x+16,y+10,MathMax(14,InpPanelFontSize+4),C'244,203,111',"GSM GOLD 3SOP  |  CONTROL & SIGNAL MONITOR",20);
   ConfigureDashboardLabel(DashboardObjectName("FLOW"),x+16,y+41,MathMax(9,InpPanelFontSize),C'210,217,225',"独立 OR：Scalping M5  |  Intraday M30  |  Swing D1 > H4 > M30",20);
   ConfigureDashboardLabel(DashboardObjectName("META"),x+16,y+62,MathMax(8,InpPanelFontSize-1),C'145,157,171',"",20);

   for(int s=0;s<3;s++)
   {
      ConfigureStrategyButton(s,x+12+s*(buttonWidth+6),y+84,buttonWidth);
      int cardY=cardTop+s*112;
      ConfigureDashboardRectangle(DashboardObjectName("CARD_"+IntegerToString(s)),x+10,cardY,width-20,104,C'25,30,38',StrategyAccentColor(s),12);
      ConfigureDashboardLabel(DashboardObjectName("TEXT_"+IntegerToString(s)),x+22,cardY+9,MathMax(8,InpPanelFontSize-1),C'242,245,248',"",21);
   }
   ConfigureDashboardLabel(DashboardObjectName("FOOTER"),x+16,y+472,MathMax(8,InpPanelFontSize-1),C'167,178,190',"图表开关仅控制新开仓；已有仓位继续执行止损、保本与移动保护。",20);
}

void DeleteDashboardObjects()
{
   for(int i=ObjectsTotal(0,-1,-1)-1;i>=0;i--)
   {
      string name=ObjectName(0,i,-1,-1);
      if(StringFind(name,g_panelPrefix)==0)
         ObjectDelete(0,name);
   }
   ChartRedraw(0);
}

string CompactPanelText(string text,int maxLength)
{
   if(text=="")
      return "-";
   if(StringLen(text)<=maxLength)
      return text;
   return StringSubstr(text,0,maxLength-3)+"...";
}

void ToggleChartStrategy(int strategy)
{
   if(strategy<0 || strategy>2)
      return;
   g_strategyEnabled[strategy]=!g_strategyEnabled[strategy];
   if(g_strategyEnabled[strategy])
   {
      g_runtime[strategy].status="等待信号";
      g_runtime[strategy].rejectReason="";
   }
   else
   {
      g_runtime[strategy].status="图表开关已关闭";
      g_runtime[strategy].rejectReason="本策略暂停新开仓；已有仓位继续保护";
   }
   PrintFormat("图表策略开关：%s=%s。三策略保持独立OR，其余策略不受影响。",
               g_runtime[strategy].name,(g_strategyEnabled[strategy]?"开启":"关闭"));
   g_lastPanelUpdate=0;
   UpdateChinesePanel(true);
}

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   if(!InpShowPanel)
      return;
   if(id==CHARTEVENT_OBJECT_CLICK && InpEnableChartSwitches)
   {
      for(int s=0;s<3;s++)
      {
         if(sparam==StrategyButtonObjectName(s))
         {
            ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
            ToggleChartStrategy(s);
            return;
         }
      }
   }
   if(id==CHARTEVENT_CHART_CHANGE)
   {
      CreateDashboardObjects();
      UpdateChinesePanel(true);
   }
}

string TrailAnchorName()
{
   if(InpSwingTrailAnchor==SWING_TRAIL_CLOSED_H4) return "最新已收盘H4价格";
   if(InpSwingTrailAnchor==SWING_TRAIL_H4_STRUCTURE) return "最新H4确认结构点";
   return "入场后最高/最低价格（默认）";
}

void RefreshRuntimeZoneDisplay(int strategy, Zone &zone)
{
   if(!zone.valid && zone.id=="")
      return;
   g_runtime[strategy].zoneId=(zone.id==""?"-":zone.id);
   g_runtime[strategy].zoneState=ZoneStateName(zone.state)+" "+(zone.dir>0?"DEMAND":"SUPPLY");
}

string RuntimePanelLine(int strategy)
{
   bool showScore=(strategy==0?InpScalpShowScore:strategy==1?InpIntradayShowScore:InpSwingShowScore);
   bool newsLock=(strategy==0?InpScalpManualNewsLock:strategy==1?InpIntradayManualNewsLock:InpSwingManualNewsLock);
   string score=(showScore ? StringFormat("%.1f",g_runtime[strategy].confidence) : "隐藏");
   return StringFormat("%s  |  状态 %s  |  Magic %I64d  |  News %s\n区域 %s  |  ZoneID %s | Cluster %s\nK线 %s (%s) | EMA/RSI %s | MACD %s | BB %s | 评分 %s\n漏斗 Zone %I64d > Departed %I64d > Touch %I64d  |  Candle %I64d Chart %I64d\n门控 SOP %I64d > Conf %I64d > Gate %I64d  |  Order %I64d Fill %I64d Reject %I64d\n未开仓 %s",
                       g_runtime[strategy].name,CompactPanelText(g_runtime[strategy].status,24),g_runtime[strategy].magic,
                       (newsLock?"锁定":"正常"),
                       CompactPanelText(g_runtime[strategy].zoneState,30),CompactPanelText(g_runtime[strategy].zoneId,32),CompactPanelText(g_runtime[strategy].clusterId,22),
                       CompactPanelText(g_runtime[strategy].candleName,20),g_runtime[strategy].candleStrength,
                        CompactPanelText(g_runtime[strategy].indicatorState,26),CompactPanelText(g_runtime[strategy].macdState,20),
                       CompactPanelText(g_runtime[strategy].bollingerState,20),score,
                       g_funnel[strategy].zonesDetected,g_funnel[strategy].zonesDeparted,g_funnel[strategy].firstTouches,
                       g_funnel[strategy].candlePatternsDetected,g_funnel[strategy].chartPatternsDetected,
                       g_funnel[strategy].hardSOPPassed,g_funnel[strategy].confidencePassed,g_funnel[strategy].globalGatePassed,
                       g_funnel[strategy].ordersRequested,g_funnel[strategy].ordersFilled,g_funnel[strategy].ordersRejected,
                       CompactPanelText(g_runtime[strategy].rejectReason,58));
}

void UpdateChinesePanel(bool force=false)
{
   if(!InpShowPanel)
      return;
   if(!force && TimeCurrent()==g_lastPanelUpdate)
      return;
   g_lastPanelUpdate=TimeCurrent();

   for(int s=0;s<3;s++)
   {
      if(!g_strategyEnabled[s])
         g_runtime[s].status="图表开关已关闭";
   }

   if(g_scalpDemand.state==ZONE_FIRST_TOUCH || g_scalpDemand.state==ZONE_ENTRY_PENDING)
      RefreshRuntimeZoneDisplay((int)STRATEGY_SCALPING,g_scalpDemand);
   else if(g_scalpSupply.state==ZONE_FIRST_TOUCH || g_scalpSupply.state==ZONE_ENTRY_PENDING)
      RefreshRuntimeZoneDisplay((int)STRATEGY_SCALPING,g_scalpSupply);
   else if(g_scalpDemand.valid && !g_scalpDemand.used)
      RefreshRuntimeZoneDisplay((int)STRATEGY_SCALPING,g_scalpDemand);
   else if(g_scalpSupply.valid)
      RefreshRuntimeZoneDisplay((int)STRATEGY_SCALPING,g_scalpSupply);

   if(g_intradayDemand.state==ZONE_FIRST_TOUCH || g_intradayDemand.state==ZONE_ENTRY_PENDING)
      RefreshRuntimeZoneDisplay((int)STRATEGY_INTRADAY,g_intradayDemand);
   else if(g_intradaySupply.state==ZONE_FIRST_TOUCH || g_intradaySupply.state==ZONE_ENTRY_PENDING)
      RefreshRuntimeZoneDisplay((int)STRATEGY_INTRADAY,g_intradaySupply);
   else if(g_intradayDemand.valid && !g_intradayDemand.used)
      RefreshRuntimeZoneDisplay((int)STRATEGY_INTRADAY,g_intradayDemand);
   else if(g_intradaySupply.valid)
      RefreshRuntimeZoneDisplay((int)STRATEGY_INTRADAY,g_intradaySupply);
   RefreshRuntimeZoneDisplay((int)STRATEGY_SWING,g_swingZone);

   CreateDashboardObjects();
   string accountMode=(g_isHedging?"Hedging / 独立持仓":"Netting / 隔离受限");
   string meta=StringFormat("%s | %s | Spread %d | Trade %s | Capital %s | Risk %.2f%% | Score %s/%s/%s | EMA+RSI %s/%s/%s",
                             g_symbol,accountMode,CurrentSpreadPoints(),
                             (g_accountAllowsTrading?"允许":"禁止"),
                             g_capitalTierName,EffectiveTotalRiskCap(),
                             (InpScalpUseScoreFilter?"ON":"OFF"),(InpIntradayUseScoreFilter?"ON":"OFF"),(InpSwingUseScoreFilter?"ON":"OFF"),
                             ((InpScalpUseEMAFilter||InpScalpUseRSIFilter)?"ON":"OFF"),
                             ((InpIntradayUseEMAFilter||InpIntradayUseRSIFilter)?"ON":"OFF"),
                             ((InpSwingUseEMAFilter||InpSwingUseRSIFilter)?"ON":"OFF"));
   ObjectSetString(0,DashboardObjectName("META"),OBJPROP_TEXT,meta);
   for(int s=0;s<3;s++)
   {
      int width=DashboardWidth();
      int buttonWidth=(width-36)/3;
      ConfigureStrategyButton(s,InpPanelXOffset+12+s*(buttonWidth+6),InpPanelYOffset+84,buttonWidth);
      ObjectSetString(0,DashboardObjectName("TEXT_"+IntegerToString(s)),OBJPROP_TEXT,RuntimePanelLine(s));
   }
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
