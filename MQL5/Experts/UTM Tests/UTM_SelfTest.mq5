//+------------------------------------------------------------------+
//|                                                  UTM_SelfTest.mq5 |
//|   Internal test harness for the UTM engine (not for live use)     |
//+------------------------------------------------------------------+
#property copyright "UTM Manager"
#property version   "1.01"
#property description "Engine self test: opens one trade and exercises management."

#include <UTM/UTM_Defines.mqh>
#include <UTM/UTM_Utils.mqh>
#include <UTM/UTM_Settings.mqh>
#include <UTM/UTM_Engine.mqh>

input int                   InpScenario   = 0;   // 0=BE+TP 1=TP only 2=sell ignore-spread
input double                InpLots       = 0.10;
input double                InpSLPips     = 20.0;

CUtmEngine g_self;
bool       g_sent      = false;
bool       g_hadTrade  = false;
int        g_lastTp    = -1;
bool       g_lastPend  = false;
double     g_lastSl    = -1.0;
int        g_side      = POSITION_TYPE_BUY;

int OnInit()
  {
   UTM_SetDefaults(g_set);
   g_set.riskMode   = UTM_RISK_LOT;
   g_set.riskValue  = InpLots;
   g_set.maxLot     = 0.0;
   g_set.slSize     = InpSLPips;
   g_set.slUnit     = UTM_SL_PIPS;
   g_set.tpCount    = 2;
   g_set.tpRR[0]    = 1.0;
   g_set.tpPct[0]   = 50.0;
   g_set.tpRR[1]    = 2.0;
   g_set.tpPct[1]   = 100.0;
   g_set.sounds     = false;
   g_set.spreadMode = UTM_SPREAD_OFF;
   g_set.formula    = "";
   g_side           = POSITION_TYPE_BUY;

   if(InpScenario == 0)
      g_set.formula = "0.5:BE";
   else if(InpScenario == 5)
     {
      g_set.formula  = "0.5:TS 1.0";
      g_set.tpCount  = 1;
      g_set.tpRR[0]  = 10.0;
      g_set.tpPct[0] = 100.0;
      g_set.tpPct[1] = 0.0;
     }
   else if(InpScenario == 2 || InpScenario == 3 || InpScenario == 4)
      g_set.spreadMode = UTM_SPREAD_IGNORE;

   if(InpScenario == 2)
      g_side = POSITION_TYPE_SELL;

   if(!g_self.Init(_Symbol, _Symbol, 123456, 20))
     {
      Print("SELFTEST: engine init failed");
      return INIT_FAILED;
     }

   Print("SELFTEST: scenario=", InpScenario, " side=", (g_side == POSITION_TYPE_BUY ? "BUY" : "SELL"),
         " spreadMode=", g_set.spreadMode, " formula='", g_set.formula, "'");
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   g_self.Deinit();
   Print("SELFTEST: finished, trades left=", g_self.Count());
  }

void OnTick()
  {
   g_self.OnTick();

   if(!g_sent && g_self.Count() == 0)
     {
      g_sent = true;
      bool ok = false;
      if(InpScenario == 3 || InpScenario == 4)
        {
         int side = (InpScenario == 3 ? POSITION_TYPE_BUY : POSITION_TYPE_SELL);
         double off = UTM_PipsToPrice(_Symbol, 15.0);
         g_self.ActivateExec(side);
         g_self.SetExecEntry(side == POSITION_TYPE_BUY ? UTM_Ask(_Symbol) - off : UTM_Bid(_Symbol) + off);
         ok = g_self.ExecuteNow();
         Print("SELFTEST: pending plan mode=", g_self.ExecMode(), " -> ", (ok ? "sent" : "FAILED: " + g_self.LastError()));
        }
      else
         ok = g_self.QuickTrade(g_side);

      Print("SELFTEST: QuickTrade(", (g_side == POSITION_TYPE_BUY ? "BUY" : "SELL"), ") -> ",
            (ok ? "ok" : "FAILED: " + g_self.LastError()));
     }

   if(g_self.Count() > 0)
     {
      STrade t;
      if(g_self.GetTradeInfo(0, t))
        {
         g_hadTrade = true;
         double vol = 0.0;
         if(PositionSelectByTicket(t.ticket))
            vol = PositionGetDouble(POSITION_VOLUME);

         if(t.tpDone != g_lastTp || t.pending != g_lastPend ||
            MathAbs(t.sl - g_lastSl) > _Point * 0.5)
           {
            Print("SELFTEST: id=", t.id, " pending=", t.pending, " tpDone=", t.tpDone,
                  " curVol=", DoubleToString(vol, 2),
                  " entry=", DoubleToString(t.entry, _Digits),
                  " sl=", DoubleToString(t.sl, _Digits),
                  " tp1=", DoubleToString(t.tp[0], _Digits),
                  " tp2=", DoubleToString(t.tp[1], _Digits),
                  " risk=", DoubleToString(t.riskMoney, 2),
                  " be=", (t.beDone ? "1" : "0"));
            g_lastTp = t.tpDone;
            g_lastPend = t.pending;
            g_lastSl = t.sl;
           }
        }
     }
   else if(g_hadTrade)
     {
      g_hadTrade = false;
      Print("SELFTEST: position closed, balance=", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
     }
  }

void OnTimer()
  {
   g_self.OnTimer();
  }

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   g_self.OnChartEvent(id, lparam, dparam, sparam);
  }
//+------------------------------------------------------------------+
