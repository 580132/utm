//+------------------------------------------------------------------+
//|                                                 UTM_Defines.mqh  |
//|      UTM Manager - shared types, enums and constants             |
//+------------------------------------------------------------------+
#ifndef __UTM_DEFINES_MQH__
#define __UTM_DEFINES_MQH__

#define UTM_NAME            "UTM Manager"
#define UTM_VERSION         "1.25"
#define UTM_BUILD           __DATE__
#define UTM_MAX_TP          4
#define UTM_MAX_SPLIT       10
#define UTM_MAX_TRADES      64
#define UTM_OBJ_PREFIX      "UTM_"

//--- risk model
enum ENUM_UTM_RISK_MODE
  {
   UTM_RISK_PERCENT = 0,   // Risk % of balance
   UTM_RISK_MONEY   = 1,   // Fixed money risk
   UTM_RISK_LOT     = 2    // Fixed lot size
  };

//--- stop loss unit
enum ENUM_UTM_SL_UNIT
  {
   UTM_SL_POINTS = 0,      // Points
   UTM_SL_PIPS   = 1       // Pips
  };

//--- spread handling
enum ENUM_UTM_SPREAD_MODE
  {
   UTM_SPREAD_OFF       = 0,  // Off
   UTM_SPREAD_FACTOR    = 1,  // Spread factor
   UTM_SPREAD_IGNORE    = 2,  // Ignore spread
   UTM_SPREAD_INVISIBLE = 3   // Ignore spread (invisible)
  };

//--- order entry mode
enum ENUM_UTM_ORDER_MODE
  {
   UTM_ORDER_MARKET = 0,   // Market
   UTM_ORDER_LIMIT  = 1,   // Limit
   UTM_ORDER_STOP   = 2    // Stop
  };


//--- trailing mode
enum ENUM_UTM_TRAIL_MODE
  {
   UTM_TRAIL_OFF   = 0,   // Off
   UTM_TRAIL_RR    = 1,   // RR based (formula)
   UTM_TRAIL_MA    = 2    // Moving average
  };

//--- colors / theme
#define UTM_CLR_BG          C'26,30,36'
#define UTM_CLR_BG_ALT      C'34,39,47'
#define UTM_CLR_HEADER      C'40,46,56'
#define UTM_CLR_BORDER      C'60,68,80'
#define UTM_CLR_TEXT        C'220,224,230'
#define UTM_CLR_TEXT_DIM    C'170,178,192'
#define UTM_CLR_ACCENT      C'0,176,156'
#define UTM_CLR_ACCENT_DARK C'0,120,108'
#define UTM_CLR_BUY         C'46,160,110'
#define UTM_CLR_SELL        C'212,86,86'
#define UTM_CLR_WARN        C'224,168,64'
#define UTM_CLR_LINE_BUY    C'70,160,255'
#define UTM_CLR_LINE_SELL   C'240,110,110'
#define UTM_CLR_SL          C'230,120,90'
#define UTM_CLR_TP          C'80,190,140'
#define UTM_CLR_ENTRY       C'180,190,205'

//--- one managed trade (opened or pending, by the manager)
struct STrade
  {
   long              id;              // manager id (1..N)
   ulong             ticket;          // main position / order ticket
   string            symbol;
   int               type;            // POSITION_TYPE_BUY / SELL
   bool              pending;         // true = pending order
   double            lot;             // initial volume
   double            entry;           // candle / original entry price
   double            posEntry;        // real fill price
   double            sl;              // manager stop loss (real or virtual)
   double            riskDist;        // 1R distance in price
   double            riskMoney;       // planned risk in account currency
   double            tp[UTM_MAX_TP];
   double            tpPct[UTM_MAX_TP];
   double            tpRR[UTM_MAX_TP];
   int               tpCount;
   int               tpDone;
   bool              beDone;
   bool              trailingTP;
   bool              serverTP;        // multi-TP opened as one position per level
   bool              virtualSL;       // SL is watched by the manager
   bool              virtualEntry;    // pending entry is watched by the manager
   int               orderMode;       // ENUM_UTM_ORDER_MODE of the pending order
   datetime          opened;
   ulong             splits[UTM_MAX_SPLIT];
   int               splitCount;
   int               magic;
   uint              formulaDone;     // bitmask of applied formula rules
   int               trailStep;       // steps taken by the trailing TP
   bool              adopted;         // trade recovered without full metadata
   string            comment;
  };

//--- line appearance (configurable from the EA inputs)
struct SUtmStyle
  {
   color  entry;          // execution entry line
   color  buy;            // open long entry line
   color  sell;           // open short entry line
   color  sl;             // stop loss line
   color  tp;             // take profit lines
   int    entryStyle;
   int    slStyle;
   int    tpStyle;
   int    entryWidth;
   int    slWidth;
   int    tpWidth;
  };

//--- execution mode state (lines drawn before the order is sent)
struct SExec
  {
   bool              active;
   int               side;            // POSITION_TYPE_BUY / SELL
   int               mode;            // ENUM_UTM_ORDER_MODE
   int               stage;           // 0 = SL only (market), 1 = placing entry, 2 = placing SL with fixed entry
   bool              follow;          // the active line follows the mouse
   double            entry;
   double            sl;
   double            tp[UTM_MAX_TP];
   int               tpCount;
   double            lot;
  };

//--- copy of all user settings, editable at runtime from the panel
struct SUtmSettings
  {
   // risk
   int               riskMode;
   double            riskValue;        // %, money or lot depending on riskMode
   double            maxLot;
   double            equityStop;
   double            abnormalSpread;
   bool              bypassMaxLot;
   double            overrideBalance;
   // stop loss
   bool              fixedSL;
   double            slSize;
   int               slUnit;
   double            slMin;
   double            slMax;
   int               atrPeriod;
   bool              lockRR;
   // take profits
   int               tpCount;
   double            tpRR[UTM_MAX_TP];
   double            tpPct[UTM_MAX_TP];
   bool              trailingTP;
   double            trailTPRR;
   double            trailTPPct;
   // management
   double            beOffsetRR;
   string            formula;
   bool              removePendingOnSL;

   // spread
   int               spreadMode;
   double            spreadFactor;
   double            emaSpread;
   bool              failsafeSL;
   bool              formulaOrigEntry;
   bool              tpOrigEntry;

   // misc
   bool              memorySave;
   bool              sounds;
   string            profile;
   string              tradeSymbol;
   double            commissionPerLot;
   bool              commissionInRisk;
   bool              commissionAuto;
   bool              serverSplitTP;
   int               defaultOrderMode;
   bool              privacyMode;      // hide balance / equity / profit on screen
   bool              showQuickTrade;   // show the quick buy/sell buttons
   int               panelX;
   int               panelY;
   bool              panelVisible;
   bool              hudBg;
  };

#endif // __UTM_DEFINES_MQH__
//+------------------------------------------------------------------+