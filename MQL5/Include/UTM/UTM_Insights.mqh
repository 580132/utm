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
   static bool     lastPriv = false;

   //--- privacy toggled: rebuild immediately instead of waiting for the cache
   if(lastPriv != g_set.privacyMode)
     {
      lastPriv = g_set.privacyMode;
      lastCalc = 0;
     }

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

   //--- 同一笔计划（注释 UTM-<id>）拆出来的多个仓位只算一笔
   ulong  posId[256];
   string posKey[256];
   int    np = 0;

   string keys[256];
   double keyProfit[256];
   int    nk = 0;

   if(HistorySelect(from, TimeCurrent()))
     {
      int total = HistoryDealsTotal();

      //--- 先把每个仓位（position id）对应到计划号：拆仓的多个仓位共用 UTM-<id>
      for(int i = 0; i < total; i++)
        {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket == 0)
            continue;
         if((int)HistoryDealGetInteger(ticket, DEAL_MAGIC) != magic)
            continue;
         ulong pid = (ulong)HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
         if(pid == 0)
            continue;
         int pi = -1;
         for(int k = 0; k < np; k++)
            if(posId[k] == pid)
              {
               pi = k;
               break;
              }
         if(pi < 0 && np < 256)
           {
            pi = np;
            posId[np] = pid;
            posKey[np] = "";
            np++;
           }
         if(pi >= 0)
           {
            string cm = HistoryDealGetString(ticket, DEAL_COMMENT);
            if(StringFind(cm, "UTM-") == 0)
               posKey[pi] = cm;
            else if(posKey[pi] == "")
               posKey[pi] = "P" + IntegerToString((long)pid);
           }
        }

      //--- 再按计划号汇总今天的平仓盈亏
      for(int i = 0; i < total; i++)
        {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket == 0)
            continue;
         if((int)HistoryDealGetInteger(ticket, DEAL_MAGIC) != magic)
            continue;
         ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY);
         if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT && entry != DEAL_ENTRY_OUT_BY)
            continue;
         double p = HistoryDealGetDouble(ticket, DEAL_PROFIT)
                    + HistoryDealGetDouble(ticket, DEAL_COMMISSION)
                    + HistoryDealGetDouble(ticket, DEAL_SWAP);
         profit += p;

         ulong pid = (ulong)HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
         string key = "";
         for(int k = 0; k < np; k++)
            if(posId[k] == pid && posKey[k] != "")
              {
               key = posKey[k];
               break;
              }
         if(key == "")
           {
            string cm = HistoryDealGetString(ticket, DEAL_COMMENT);
            key = (StringFind(cm, "UTM-") == 0 ? cm : "P" + IntegerToString((long)pid));
           }

         int idx = -1;
         for(int k = 0; k < nk; k++)
            if(keys[k] == key)
              {
               idx = k;
               break;
              }
         if(idx < 0 && nk < 256)
           {
            idx = nk;
            keys[nk] = key;
            keyProfit[nk] = 0.0;
            nk++;
           }
         if(idx >= 0)
            keyProfit[idx] += p;
        }
     }

   deals = nk;
   for(int k = 0; k < nk; k++)
      if(keyProfit[k] > 0.0)
         wins++;

   cachedDeals  = deals;
   cachedWins   = wins;
   cachedProfit = profit;

   double wr = (deals > 0 ? (double)wins / (double)deals * 100.0 : 0.0);
   if(g_set.privacyMode)
     {
      cached = "今日 ****";
      clr    = UTM_CLR_TEXT_DIM;   // do not leak the sign through the colour
      txt    = cached;
      return;
     }

   cached = "今日 " + IntegerToString(deals) + " 笔  胜率 " +
            DoubleToString(wr, 0) + "%  " +
            UTM_Priv((profit >= 0.0 ? "+" : "") + UTM_FmtMoney(profit));

   if(cachedProfit > 0.0)      clr = UTM_CLR_BUY;
   else if(cachedProfit < 0.0) clr = UTM_CLR_SELL;

   txt = cached;
  }

#endif // __UTM_INSIGHTS_MQH__