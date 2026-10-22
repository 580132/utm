//+------------------------------------------------------------------+
//|                                              UTM_VisualTest.mq5  |
//|   Visual smoke test: creates a far-away virtual pending order     |
//|   so the trade lines and their labels can be inspected.           |
//|   No broker order is sent (ignore-spread virtual pending).        |
//+------------------------------------------------------------------+
#property copyright "UTM Manager"
#property version   "1.00"

#include <UTM/UTM_Defines.mqh>
#include <UTM/UTM_Utils.mqh>
#include <UTM/UTM_Settings.mqh>
#include <UTM/UTM_Engine.mqh>
#include <UTM/UTM_Panel.mqh>

CUtmEngine g_v;
CUtmPanel  g_panel;

int OnInit()
  {
   UTM_SetDefaults(g_set);
   g_set.riskMode   = UTM_RISK_LOT;
   g_set.riskValue  = 0.10;
   g_set.slSize     = 20.0;
   g_set.slUnit     = UTM_SL_PIPS;
   g_set.tpCount    = 2;
   g_set.tpRR[0]    = 1.0;
   g_set.tpPct[0]   = 50.0;
   g_set.tpRR[1]    = 2.0;
   g_set.tpPct[1]   = 100.0;
   g_set.spreadMode = UTM_SPREAD_IGNORE;   // virtual pending, nothing is sent
   g_set.sounds     = false;

   if(!g_v.Init(_Symbol, _Symbol, 555555, 20))
      return INIT_FAILED;

   g_panel.Init(&g_v);
   g_panel.Refresh();

   double pip = UTM_PipSize(_Symbol);
   double far = UTM_Ask(_Symbol) - 25.0 * pip;   // close enough to be visible

   g_v.ActivateExec(POSITION_TYPE_BUY);
   g_v.ExecSetMode(UTM_ORDER_LIMIT);
   g_v.ExecClickAt(far);              // entry
   g_v.ExecClickAt(far - 20.0 * pip); // stop loss -> sends the virtual pending
   g_v.OnTimer();
   g_panel.Refresh();

   Print("VISUAL: pending count=", g_v.Count(), " entry=", DoubleToString(far, _Digits));
   Print("VISUAL: lblSL=", (ObjectFind(0, UTM_OBJ_PREFIX + "T_1_LBL_SL") >= 0 ? 1 : 0),
         " lblTP1=", (ObjectFind(0, UTM_OBJ_PREFIX + "T_1_LBL_TP_0") >= 0 ? 1 : 0),
         " lblTP2=", (ObjectFind(0, UTM_OBJ_PREFIX + "T_1_LBL_TP_1") >= 0 ? 1 : 0),
         " lblL=", (ObjectFind(0, UTM_OBJ_PREFIX + "T_1_LBL_L") >= 0 ? 1 : 0));
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   g_panel.Destroy();
   g_v.Deinit();
  }

void OnTick()
  {
   g_v.OnTick();
  }

void OnTimer()
  {
   g_v.OnTimer();
   g_panel.Refresh();
  }

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   g_v.OnChartEvent(id, lparam, dparam, sparam);
  }
//+------------------------------------------------------------------+
