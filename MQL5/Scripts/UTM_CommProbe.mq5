//+------------------------------------------------------------------+
//|                                                UTM_CommProbe.mq5 |
//|   Prints commission enum values and the symbol's commission rules|
//+------------------------------------------------------------------+
#property script_show_inputs
#property version   "1.01"

void OnStart()
  {
   Print("COMMPROBE: modes DISABLED=", (int)SYMBOL_COMMISSION_DISABLED,
         " MONEY_DEPOSIT=", (int)SYMBOL_COMMISSION_MONEY_DEPOSIT,
         " SYMBOL_BASE=", (int)SYMBOL_COMMISSION_MONEY_SYMBOL_BASE,
         " SYMBOL_PROFIT=", (int)SYMBOL_COMMISSION_MONEY_SYMBOL_PROFIT,
         " SYMBOL_MARGIN=", (int)SYMBOL_COMMISSION_MONEY_SYMBOL_MARGIN,
         " PIPS=", (int)SYMBOL_COMMISSION_PIPS,
         " PERCENT=", (int)SYMBOL_COMMISSION_PERCENT,
         " MONEY_SPECIFIED=", (int)SYMBOL_COMMISSION_MONEY_SPECIFIED,
         " PERCENT_PROFIT=", (int)SYMBOL_COMMISSION_PERCENT_PROFIT);

   Print("COMMPROBE: vtype TRADE=", (int)SYMBOL_COMMISSION_VOLUME_TYPE_TRADE,
         " VOLUME=", (int)SYMBOL_COMMISSION_VOLUME_TYPE_VOLUME,
         " TURNOVER=", (int)SYMBOL_COMMISSION_VOLUME_TYPE_TURNOVER);

   Print("COMMPROBE: entry INOUT=", (int)SYMBOL_COMMISSION_ENTRY_INOUT,
         " IN=", (int)SYMBOL_COMMISSION_ENTRY_IN,
         " OUT=", (int)SYMBOL_COMMISSION_ENTRY_OUT);

   Print("COMMPROBE: charge DAILY=", (int)SYMBOL_COMMISSION_CHARGE_DAILY,
         " MONTHLY=", (int)SYMBOL_COMMISSION_CHARGE_MONTHLY,
         " INSTANT=", (int)SYMBOL_COMMISSION_CHARGE_INSTANT);

   Print("COMMPROBE: dir BOTH=", (int)SYMBOL_COMMISSION_DIRECTION_BOTH,
         " BUY=", (int)SYMBOL_COMMISSION_DIRECTION_BUY,
         " SELL=", (int)SYMBOL_COMMISSION_DIRECTION_SELL);

   Print("COMMPROBE: range VOLUME=", (int)SYMBOL_COMMISSION_RANGE_VOLUME,
         " TURNOVER_MONEY=", (int)SYMBOL_COMMISSION_RANGE_TURNOVER_MONEY,
         " TURNOVER_VOLUME=", (int)SYMBOL_COMMISSION_RANGE_TURNOVER_VOLUME,
         " VALUE=", (int)SYMBOL_COMMISSION_RANGE_VALUE,
         " PROFIT=", (int)SYMBOL_COMMISSION_RANGE_PROFIT);

   Print("COMMPROBE: profit ALL=", (int)SYMBOL_COMMISSION_PROFIT_ALL,
         " PROFIT=", (int)SYMBOL_COMMISSION_PROFIT_PROFIT,
         " LOSS=", (int)SYMBOL_COMMISSION_PROFIT_LOSS);

   MqlCommission rules[];
   int n = SymbolInfoCommissions(_Symbol, rules);
   Print("COMMPROBE: symbol=", _Symbol, " rules=", n, " err=", GetLastError(),
         " acctCur=", AccountInfoString(ACCOUNT_CURRENCY),
         " contract=", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE), 2),
         " ask=", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits));
   for(int i = 0; i < n; i++)
     {
      Print("COMMPROBE: rule ", i,
            " cur=", rules[i].currency,
            " range=", (int)rules[i].mode_range,
            " charge=", (int)rules[i].mode_charge,
            " entry=", (int)rules[i].mode_entry,
            " dir=", (int)rules[i].mode_direction,
            " profit=", (int)rules[i].mode_profit,
            " tiers=", ArraySize(rules[i].tiers));
      for(int k = 0; k < ArraySize(rules[i].tiers); k++)
         Print("COMMPROBE:   tier ", k,
               " mode=", (int)rules[i].tiers[k].mode,
               " voltype=", (int)rules[i].tiers[k].volume_type,
               " value=", DoubleToString(rules[i].tiers[k].value, 4),
               " min=", DoubleToString(rules[i].tiers[k].min_value, 4),
               " max=", DoubleToString(rules[i].tiers[k].max_value, 4),
               " from=", DoubleToString(rules[i].tiers[k].range_from, 4),
               " to=", DoubleToString(rules[i].tiers[k].range_to, 4),
               " cur=", rules[i].tiers[k].currency);
     }
  }
//+------------------------------------------------------------------+
