//+------------------------------------------------------------------+
//|                                             UTM_SymbolProbe.mq5  |
//|   Prints trade settings of a symbol (why a pending order may fail)|
//+------------------------------------------------------------------+
#property script_show_inputs
#property version   "1.00"
input string InpSymbol = "BTCUSD";

string OrderModeText(const long m)
  {
   string s = "";
   if((m & SYMBOL_ORDER_MARKET)     != 0) s += "market ";
   if((m & SYMBOL_ORDER_LIMIT)      != 0) s += "limit ";
   if((m & SYMBOL_ORDER_STOP)       != 0) s += "stop ";
   if((m & SYMBOL_ORDER_STOP_LIMIT) != 0) s += "stoplimit ";
   if((m & SYMBOL_ORDER_SL)         != 0) s += "sl ";
   if((m & SYMBOL_ORDER_TP)         != 0) s += "tp ";
   if((m & SYMBOL_ORDER_CLOSEBY)    != 0) s += "closeby ";
   return s;
  }

string ExpText(const long m)
  {
   string s = "";
   if((m & SYMBOL_EXPIRATION_GTC)   != 0) s += "GTC ";
   if((m & SYMBOL_EXPIRATION_DAY)   != 0) s += "DAY ";
   if((m & SYMBOL_EXPIRATION_SPECIFIED) != 0) s += "SPEC ";
   if((m & SYMBOL_EXPIRATION_SPECIFIED_DAY) != 0) s += "SPECDATE ";
   return s;
  }

void Probe(const string sym)
  {
   if(!SymbolSelect(sym, true))
     {
      Print("PROBE: ", sym, " not selectable, err=", GetLastError());
      return;
     }

   for(int w = 0; w < 60 && !SymbolIsSynchronized(sym); w++)
      Sleep(500);
   for(int w2 = 0; w2 < 40; w2++)
     {
      MqlTick t0;
      if(SymbolInfoTick(sym, t0) && t0.bid > 0.0)
         break;
      Sleep(500);
     }
   MqlTick tk;
   bool hasTick = SymbolInfoTick(sym, tk);

   Print("PROBE: === ", sym, " === connected=", TerminalInfoInteger(TERMINAL_CONNECTED), " sync=", SymbolIsSynchronized(sym));
   Print("PROBE: tradeMode=", (int)SymbolInfoInteger(sym, SYMBOL_TRADE_MODE),
         " orderMode=", OrderModeText(SymbolInfoInteger(sym, SYMBOL_ORDER_MODE)),
         " expiration=", ExpText(SymbolInfoInteger(sym, SYMBOL_EXPIRATION_MODE)));
   Print("PROBE: execMode=", (int)SymbolInfoInteger(sym, SYMBOL_TRADE_EXEMODE),
         " filling=", (int)SymbolInfoInteger(sym, SYMBOL_FILLING_MODE),
         " stopsLevel=", SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL),
         " freezeLevel=", SymbolInfoInteger(sym, SYMBOL_TRADE_FREEZE_LEVEL),
         " spread=", SymbolInfoInteger(sym, SYMBOL_SPREAD));
   Print("PROBE: digits=", SymbolInfoInteger(sym, SYMBOL_DIGITS),
         " point=", DoubleToString(SymbolInfoDouble(sym, SYMBOL_POINT), 8),
         " tickSize=", DoubleToString(SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE), 8),
         " contract=", DoubleToString(SymbolInfoDouble(sym, SYMBOL_TRADE_CONTRACT_SIZE), 2));
   Print("PROBE: vol min=", DoubleToString(SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN), 3),
         " max=", DoubleToString(SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX), 2),
         " step=", DoubleToString(SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP), 3),
         " marginInit=", DoubleToString(SymbolInfoDouble(sym, SYMBOL_MARGIN_INITIAL), 2));
   Print("PROBE: bid=", DoubleToString(tk.bid, (int)SymbolInfoInteger(sym, SYMBOL_DIGITS)),
         " ask=", DoubleToString(tk.ask, (int)SymbolInfoInteger(sym, SYMBOL_DIGITS)),
         " tickTime=", TimeToString(tk.time, TIME_DATE | TIME_SECONDS),
         " age(sec)=", (int)(TimeCurrent() - tk.time));
   Print("PROBE: server time=", TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
         " last=", TimeToString(tk.last, TIME_DATE | TIME_SECONDS),
         " volume=", tk.volume_real);
   Print("PROBE: sessionDeals=", SymbolInfoInteger(sym, SYMBOL_SESSION_DEALS),
         "");

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   datetime from = 0, to = 0;
   for(int i = 0; i < 10; i++)
     {
      if(!SymbolInfoSessionTrade(sym, (ENUM_DAY_OF_WEEK)dt.day_of_week, i, from, to))
         break;
      MqlDateTime a, b;
      TimeToStruct(from, a);
      TimeToStruct(to, b);
      Print("PROBE: trade session ", i, " ", a.hour, ":", a.min, " - ", b.hour, ":", b.min);
     }
  }

void OnStart()
  {
   Probe(InpSymbol);
   if(InpSymbol != "EURUSD")
      Probe("EURUSD");
  }
//+------------------------------------------------------------------+
