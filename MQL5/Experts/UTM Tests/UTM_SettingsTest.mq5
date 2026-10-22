//+------------------------------------------------------------------+
//|                                             UTM_SettingsTest.mq5 |
//|   Verifies settings save / load round-trip and the file location  |
//+------------------------------------------------------------------+
#property copyright "UTM Manager"
#property version   "1.00"

#include <UTM/UTM_Defines.mqh>
#include <UTM/UTM_Utils.mqh>
#include <UTM/UTM_Settings.mqh>

int OnInit()
  {
   string prof = "RoundTrip";
   UTM_SetDefaults(g_set);
   g_set.profile          = prof;
   g_set.riskValue        = 3.75;
   g_set.slSize           = 42.5;
   g_set.slUnit           = UTM_SL_ATR;
   g_set.tpCount          = 3;
   g_set.tpRR[0]          = 1.5;
   g_set.tpPct[0]         = 40.0;
   g_set.tpPct[1]         = 30.0;
   g_set.tpPct[2]         = 30.0;
   g_set.spreadMode       = UTM_SPREAD_IGNORE;
   g_set.commissionPerLot = 5.5;
   g_set.commissionInRisk = true;
   g_set.formula          = "1.0:BE;1.5:TS 1.0";
   g_set.memorySave       = true;

   bool saved = UTM_SaveSettings(g_set);
   string fn = UTM_SettingsFileName(prof);

   Print("SETTEST: save ok=", saved, " file=[", fn, "]");
   Print("SETTEST: exists local=", (FileIsExist(fn) ? 1 : 0),
         " common=", (FileIsExist(fn, FILE_COMMON) ? 1 : 0));

   //--- clobber and load again
   UTM_SetDefaults(g_set);
   g_set.profile = prof;
   bool loaded = UTM_LoadSettings(g_set);

   Print("SETTEST: load ok=", loaded);
   Print("SETTEST: risk=", DoubleToString(g_set.riskValue, 2),
         " sl=", DoubleToString(g_set.slSize, 2),
         " unit=", g_set.slUnit,
         " tpCount=", g_set.tpCount,
         " t1=", DoubleToString(g_set.tpRR[0], 2), "/", DoubleToString(g_set.tpPct[0], 0),
         " t2pct=", DoubleToString(g_set.tpPct[1], 0),
         " spread=", g_set.spreadMode,
         " comm=", DoubleToString(g_set.commissionPerLot, 2),
         " commInRisk=", (g_set.commissionInRisk ? 1 : 0),
         " formula=[", g_set.formula, "]",
         " mem=", (g_set.memorySave ? 1 : 0));

   //--- second scenario: relative path used by the terminal's common folder
   Print("SETTEST: terminal data path=", TerminalInfoString(TERMINAL_DATA_PATH));
   Print("SETTEST: common path=", TerminalInfoString(TERMINAL_COMMONDATA_PATH));
   return INIT_SUCCEEDED;
  }
//+------------------------------------------------------------------+
