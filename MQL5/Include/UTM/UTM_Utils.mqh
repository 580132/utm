//+------------------------------------------------------------------+
//|                                                   UTM_Utils.mqh  |
//|      Small helpers: prices, pips, lots, formatting, symbols      |
//+------------------------------------------------------------------+
#ifndef __UTM_UTILS_MQH__
#define __UTM_UTILS_MQH__

#include "UTM_Defines.mqh"

//--- -----------------------------------------------------------------
//--- price / point helpers
//--- -----------------------------------------------------------------
int UTM_Digits(const string sym)
  {
   return (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
  }

double UTM_Point(const string sym)
  {
   return SymbolInfoDouble(sym, SYMBOL_POINT);
  }

//--- 1 pip = 10 points on 3/5 digit FX symbols, 1 point otherwise
double UTM_PipSize(const string sym)
  {
   double pt = UTM_Point(sym);
   int    d  = UTM_Digits(sym);
   if(d == 3 || d == 5)
      return pt * 10.0;
   return pt;
  }

double UTM_PriceToPips(const string sym, const double distance)
  {
   double pip = UTM_PipSize(sym);
   if(pip <= 0.0)
      return 0.0;
   return distance / pip;
  }

double UTM_PipsToPrice(const string sym, const double pips)
  {
   return pips * UTM_PipSize(sym);
  }

double UTM_NormPrice(const string sym, const double price)
  {
   int d = UTM_Digits(sym);
   if(d < 0)
      d = 2;
   return NormalizeDouble(price, d);
  }

double UTM_Ask(const string sym)
  {
   return SymbolInfoDouble(sym, SYMBOL_ASK);
  }

double UTM_Bid(const string sym)
  {
   return SymbolInfoDouble(sym, SYMBOL_BID);
  }

double UTM_RawSpread(const string sym)
  {
   double ask = UTM_Ask(sym);
   double bid = UTM_Bid(sym);
   if(ask <= 0.0 || bid <= 0.0)
      return 0.0;
   return MathMax(0.0, ask - bid);
  }

//--- -----------------------------------------------------------------
//--- money / lot helpers
//--- -----------------------------------------------------------------
double UTM_SafeDiv(const double a, const double b)
  {
   if(MathAbs(b) < 1e-12)
      return 0.0;
   return a / b;
  }

//--- loss in account currency for 1 lot over "dist" price distance
double UTM_LossPerLot(const string sym, const double dist)
  {
   double ts = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);
   double tv = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE_LOSS);
   if(tv <= 0.0)
      tv = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE);
   if(ts <= 0.0 || tv <= 0.0)
      return 0.0;
   return (dist / ts) * tv;
  }

//--- profit in account currency for 1 lot over "dist" price distance
double UTM_ProfitPerLot(const string sym, const double dist)
  {
   double ts = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);
   double tv = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE);
   if(ts <= 0.0 || tv <= 0.0)
      return 0.0;
   return (dist / ts) * tv;
  }

double UTM_VolumeMin(const string sym)
  {
   double v = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
   return (v > 0.0 ? v : 0.01);
  }

double UTM_VolumeMax(const string sym)
  {
   double v = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
   return (v > 0.0 ? v : 100.0);
  }

double UTM_VolumeStep(const string sym)
  {
   double v = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
   return (v > 0.0 ? v : 0.01);
  }

double UTM_RoundLotDown(const string sym, const double lot)
  {
   double step = UTM_VolumeStep(sym);
   return MathFloor(lot / step + 1e-9) * step;
  }

double UTM_RoundLotNearest(const string sym, const double lot)
  {
   double step = UTM_VolumeStep(sym);
   return MathRound(lot / step) * step;
  }

double UTM_NormLotEx(const string sym, double lot, const bool capMax)
  {
   double step = UTM_VolumeStep(sym);
   double mn   = UTM_VolumeMin(sym);
   double mx   = UTM_VolumeMax(sym);

   if(step <= 0.0)
      step = 0.01;

   lot = MathRound(lot / step) * step;
   if(lot < mn)
      lot = mn;
   if(capMax && lot > mx)
      lot = mx;

   int decimals = 2;
   if(step >= 1.0)      decimals = 0;
   else if(step >= 0.1) decimals = 1;
   else if(step >= 0.01) decimals = 2;
   else                 decimals = 3;

   return NormalizeDouble(lot, decimals);
  }

double UTM_NormLot(const string sym, double lot)
  {
   return UTM_NormLotEx(sym, lot, true);
  }

//--- can the account afford this volume on this symbol?
bool UTM_CheckMargin(const string sym, const double lot, const int type)
  {
   double price = (type == POSITION_TYPE_BUY ? UTM_Ask(sym) : UTM_Bid(sym));
   if(price <= 0.0)
      return true;
   double margin = 0.0;
   ENUM_ORDER_TYPE ot = (type == POSITION_TYPE_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
   if(!OrderCalcMargin(ot, sym, lot, price, margin))
      return true;
   return (margin <= AccountInfoDouble(ACCOUNT_MARGIN_FREE));
  }

//--- -----------------------------------------------------------------
//--- formatting
//--- -----------------------------------------------------------------
string UTM_Thousands(const string number)
  {
   string s = number;
   int    dot = StringFind(s, ".");
   string frac = "";
   if(dot >= 0)
     {
      frac = StringSubstr(s, dot);
      s    = StringSubstr(s, 0, dot);
     }
   bool neg = false;
   if(StringLen(s) > 0 && StringGetCharacter(s, 0) == '-')
     {
      neg = true;
      s   = StringSubstr(s, 1);
     }

   string out = "";
   int    n   = StringLen(s);
   for(int i = 0; i < n; i++)
     {
      out += StringSubstr(s, i, 1);
      int rest = n - i - 1;
      if(rest > 0 && rest % 3 == 0)
         out += " ";
     }
   return (neg ? "-" : "") + out + frac;
  }

string UTM_FmtMoney(const double value, const int digits = 2)
  {
   return UTM_Thousands(DoubleToString(value, digits));
  }

string UTM_FmtPrice(const string sym, const double price)
  {
   return DoubleToString(price, UTM_Digits(sym));
  }

string UTM_FmtPct(const double value, const int digits = 2)
  {
   return DoubleToString(value, digits) + "%";
  }

string UTM_FmtRR(const double rr)
  {
   if(rr == 0.0)
      return "0";
   return DoubleToString(rr, 2);
  }

//--- -----------------------------------------------------------------
//--- symbol resolution (custom / seconds charts support)
//--- -----------------------------------------------------------------
bool UTM_IsTradableSymbol(const string sym)
  {
   if(sym == "" || StringLen(sym) < 2)
      return false;
   if(!SymbolSelect(sym, true))
      return false;
   long mode = SymbolInfoInteger(sym, SYMBOL_TRADE_MODE);
   if(mode == SYMBOL_TRADE_MODE_DISABLED)
      return false;
   return (SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE) > 0.0);
  }

//--- strip non alpha-numeric tail from a custom symbol name: EURUSD#1s -> EURUSD
string UTM_ExtractAlpha(const string sym)
  {
   string out = "";
   int    n   = StringLen(sym);
   for(int i = 0; i < n; i++)
     {
      ushort c = StringGetCharacter(sym, i);
      if((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9'))
         out += ShortToString(c);
      else
         break;
     }
   return out;
  }

string UTM_ResolveSymbol(const string chartSymbol, const string overrideSymbol, string &origin)
  {
   origin = "chart";
   if(overrideSymbol != "" && UTM_IsTradableSymbol(overrideSymbol))
     {
      origin = "override";
      return overrideSymbol;
     }

   if(UTM_IsTradableSymbol(chartSymbol))
      return chartSymbol;

   //--- custom symbol: try progressive parsing of the name
   string alpha = UTM_ExtractAlpha(chartSymbol);

   //--- candidate 1: the whole alpha prefix
   if(UTM_IsTradableSymbol(alpha))
     {
      origin = "parsed";
      return alpha;
     }

   //--- candidate 2: a 6 letter currency pair inside the name
   int len = StringLen(alpha);
   for(int start = 0; start <= len - 6; start++)
     {
      string cand = StringSubstr(alpha, start, 6);
      if(UTM_IsTradableSymbol(cand))
        {
         origin = "parsed";
         return cand;
        }
     }

   //--- candidate 3: name + known broker suffix found in market watch
   int total = SymbolsTotal(false);
   for(int i = 0; i < total; i++)
     {
      string s = SymbolName(i, false);
      if(StringFind(s, alpha) == 0 && UTM_IsTradableSymbol(s))
        {
         origin = "parsed";
         return s;
        }
     }

   origin = "fallback";
   return chartSymbol;
  }

//--- -----------------------------------------------------------------
//--- misc
//--- -----------------------------------------------------------------
bool UTM_IsHedging()
  {
   return (AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
  }

//--- true in the terminal and in a visual tester run
bool g_utmForceUI = false;

bool UTM_VisualMode()
  {
   if(g_utmForceUI)
      return true;
   if(!(bool)MQLInfoInteger(MQL_TESTER))
      return true;
   return (bool)MQLInfoInteger(MQL_VISUAL_MODE);
  }

double UTM_BalanceForRisk(const double overrideBalance)
  {
   if(overrideBalance > 0.0)
      return overrideBalance;
   return AccountInfoDouble(ACCOUNT_BALANCE);
  }

string UTM_TradeSymbol(const string sym, const int magic)
  {
   return sym + "_" + IntegerToString(magic);
  }

//--- unique object name helper
string UTM_ObjName(const string base, const string tag = "")
  {
   if(tag == "")
      return UTM_OBJ_PREFIX + base;
   return UTM_OBJ_PREFIX + base + "_" + tag;
  }

//--- ensure a directory exists on the common (or local) file system
bool UTM_EnsureFolder(const string folder, const bool common)
  {
   int flags = common ? FILE_COMMON : 0;
   if(FolderCreate(folder, flags))
      return true;

   //--- FolderCreate fails when the folder already exists: probe with a file
   string probe = folder + "\\_utm_probe.tmp";
   int h = FileOpen(probe, FILE_WRITE | FILE_TXT | FILE_ANSI | flags);
   if(h == INVALID_HANDLE)
      return false;
   FileClose(h);
   FileDelete(probe, flags);
   return true;
  }

#endif // __UTM_UTILS_MQH__
//+------------------------------------------------------------------+