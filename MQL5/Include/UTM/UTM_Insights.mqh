//+------------------------------------------------------------------+
//|                                                UTM_Insights.mqh  |
//|   Trade insights: today's statistics from the account history     |
//+------------------------------------------------------------------+
#ifndef __UTM_INSIGHTS_MQH__
#define __UTM_INSIGHTS_MQH__

#include "UTM_Defines.mqh"
#include "UTM_Utils.mqh"

//+------------------------------------------------------------------+
//| Today's trades / win rate / profit for this manager               |
//+------------------------------------------------------------------+
void UTM_InsightsLine(const int magic, string &txt, color &clr)
  {
   static datetime lastCalc = 0;
   static string   cached   = "";
   static int      cachedWins = 0;
   static int      cachedDeals = 0;
   static double   cachedProfit = 0.0;

   txt = cached;
   clr = UTM_CLR_TEXT_DIM;

   if(TimeCurrent() - lastCalc < 5 && cached != "")
     {
      if(cachedProfit > 0.0)      clr = UTM_CLR_BUY;
      else if(cachedProfit < 0.0) clr = UTM_CLR_SELL;
      return;
     }
   lastCalc = TimeCurrent();

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0;
   dt.min  = 0;
   dt.sec  = 0;
   datetime from = StructToTime(dt);

   int deals = 0, wins = 0;
   double profit = 0.0;

   if(HistorySelect(from, TimeCurrent()))
     {
      int total = HistoryDealsTotal();
      for(int i = 0; i < total; i++)
        {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket == 0)
            continue;
         if((int)HistoryDealGetInteger(ticket, DEAL_MAGIC) != magic)
            continue;
         ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY);
         if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT)
            continue;
         double p = HistoryDealGetDouble(ticket, DEAL_PROFIT)
                    + HistoryDealGetDouble(ticket, DEAL_COMMISSION)
                    + HistoryDealGetDouble(ticket, DEAL_SWAP);
         deals++;
         profit += p;
         if(p > 0.0)
            wins++;
        }
     }

   cachedDeals  = deals;
   cachedWins   = wins;
   cachedProfit = profit;

   double wr = (deals > 0 ? (double)wins / (double)deals * 100.0 : 0.0);
   cached = "今日 " + IntegerToString(deals) + " 笔  " +
            DoubleToString(wr, 0) + "%  " +
            (profit >= 0.0 ? "+" : "") + UTM_FmtMoney(profit);

   if(cachedProfit > 0.0)      clr = UTM_CLR_BUY;
   else if(cachedProfit < 0.0) clr = UTM_CLR_SELL;

   txt = cached;
  }

#endif // __UTM_INSIGHTS_MQH__
//+------------------------------------------------------------------+
