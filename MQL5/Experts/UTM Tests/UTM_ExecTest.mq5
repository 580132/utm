//+------------------------------------------------------------------+
//|                                                  UTM_ExecTest.mq5 |
//|   Verifies the click-driven execution state machine               |
//+------------------------------------------------------------------+
#property copyright "UTM Manager"
#property version   "1.00"

#include <UTM/UTM_Defines.mqh>
#include <UTM/UTM_Utils.mqh>
#include <UTM/UTM_Settings.mqh>
#include <UTM/UTM_Engine.mqh>

input int    InpScenario = 0;    // 0=market click, 1=pending two clicks, 2=mode cycle
input double InpLots     = 0.10;

CUtmEngine g_t;
bool       g_done = false;
int        g_steps = 0;
datetime   g_t0 = 0;

int CountTpLines()
  {
   int n = 0;
   for(int i = 0; i < UTM_MAX_TP; i++)
      if(ObjectFind(0, UTM_OBJ_PREFIX + "X_TP_" + IntegerToString(i)) >= 0)
         n++;
   return n;
  }

string TPList()
  {
   string s = "";
   double tp[];
   if(!g_t.ExecTPs(tp))
      return s;
   for(int i = 0; i < UTM_MAX_TP; i++)
      if(tp[i] > 0.0)
         s += (s == "" ? "" : ",") + DoubleToString(tp[i], _Digits);
   return s;
  }

void Report(const string tag)
  {
   string hud1 = ObjectGetString(0, UTM_OBJ_PREFIX + "HUD_TXT", OBJPROP_TEXT);
   string hud2 = ObjectGetString(0, UTM_OBJ_PREFIX + "HUD_TXT2", OBJPROP_TEXT);
   {
    int bx = (int)ObjectGetInteger(0, UTM_OBJ_PREFIX + "HUD_BG", OBJPROP_XDISTANCE);
    int by = (int)ObjectGetInteger(0, UTM_OBJ_PREFIX + "HUD_BG", OBJPROP_YDISTANCE);
    int bw = (int)ObjectGetInteger(0, UTM_OBJ_PREFIX + "HUD_BG", OBJPROP_XSIZE);
    int bh = (int)ObjectGetInteger(0, UTM_OBJ_PREFIX + "HUD_BG", OBJPROP_YSIZE);
    int ty1 = (int)ObjectGetInteger(0, UTM_OBJ_PREFIX + "HUD_TXT", OBJPROP_YDISTANCE);
    int ty2 = (int)ObjectGetInteger(0, UTM_OBJ_PREFIX + "HUD_TXT2", OBJPROP_YDISTANCE);
    int ty3 = (int)ObjectGetInteger(0, UTM_OBJ_PREFIX + "HUD_TXT", OBJPROP_XDISTANCE);
    int chh = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
    Print("EXECTEST-GEO: chartH=", chh, " rect=", bx, ",", by, " ", bw, "x", bh,
          " t1y=", ty1, " t2y=", ty2, " t1x=", ty3,
          " inside=", ((ty1 >= by - 1 && ty1 + 14 <= by + bh + 1 &&
                        (ty2 <= 0 || (ty2 >= by - 1 && ty2 + 14 <= by + bh + 1))) ? 1 : 0),
          " bottomGap=", (chh - (by + bh)));
   }
   Print("EXECTEST-HUD: [", hud1, "]  [", hud2, "]");
   string extra = "";
   if(g_t.Count() > 0)
     {
      STrade tr;
      if(g_t.GetTradeInfo(0, tr))
         extra = "  trade: pending=" + IntegerToString(tr.pending ? 1 : 0) +
                 " entry=" + DoubleToString(tr.entry, _Digits) +
                 " sl=" + DoubleToString(tr.sl, _Digits) +
                 " lot=" + DoubleToString(tr.lot, 2);
     }
   Print("EXECTEST[", tag, "]: count=", g_t.Count(),
         " mode=", g_t.ExecMode(), " active=", (g_t.ExecActive() ? 1 : 0),
         " hud=", (ObjectFind(0, UTM_OBJ_PREFIX + "HUD_TXT") >= 0 ? 1 : 0),
         " entryLine=", (ObjectFind(0, UTM_OBJ_PREFIX + "X_ENTRY") >= 0 ? 1 : 0),
         " slLine=", (ObjectFind(0, UTM_OBJ_PREFIX + "X_SL") >= 0 ? 1 : 0),
         " tpLines=", CountTpLines(),
         extra);
  }

int OnInit()
  {
   g_utmForceUI = true;
   UTM_SetDefaults(g_set);
   g_set.riskMode  = UTM_RISK_LOT;
   g_set.riskValue = InpLots;
   g_set.slSize    = 20.0;
   g_set.slUnit    = UTM_SL_PIPS;
   g_set.tpCount   = 1;
   g_set.tpRR[0]   = 2.0;
   g_set.tpPct[0]  = 100.0;
   g_set.sounds    = false;

   if(!g_t.Init(_Symbol, _Symbol, 246810, 20))
      return INIT_FAILED;

   Print("EXECTEST: start scenario=", InpScenario);
   return INIT_SUCCEEDED;
  }

void OnTick()
  {
   g_t.OnTick();
   if(g_done)
      return;

   if(g_t0 == 0)
     {
      g_t0 = TimeCurrent();
      return;
     }

   double ask = UTM_Ask(_Symbol);
   double bid = UTM_Bid(_Symbol);
   double pip = UTM_PipSize(_Symbol);

   if(InpScenario == 0)
     {
      if(g_steps == 0)
        {
         g_t.ActivateExec(POSITION_TYPE_BUY);
         Report("market/activate");
         g_steps++;
         return;
        }
      if(g_steps == 1)
        {
         //--- click 25 pips below the current price => SL there, then send
         g_t.ExecClickAt(bid - 25.0 * pip);
         Report("market/click-send");
         g_steps++;
         g_done = true;
         return;
        }
     }

   if(InpScenario == 1)
     {
      if(g_steps == 0)
        {
         g_t.ActivateExec(POSITION_TYPE_BUY);
         g_t.ExecSetMode(UTM_ORDER_LIMIT);
         Report("pending/mode-limit");
         g_steps++;
         return;
        }
      if(g_steps == 1)
        {
         double entry = ask - 40.0 * pip;
         g_t.ExecClickAt(entry);
         Report("pending/click-entry (must have no order yet)");
         g_steps++;
         return;
        }
      if(g_steps == 2)
        {
         double sl = ask - 70.0 * pip;
         g_t.ExecClickAt(sl);
         Report("pending/click-sl (order expected)");
         g_steps++;
         g_done = true;
         return;
        }
     }

   if(InpScenario == 7)
     {
      static int waitTicks = 0;
      if(g_steps == 0)
        {
         g_t.ActivateExec(POSITION_TYPE_BUY);
         g_t.ExecSetSL(UTM_Bid(_Symbol) - 20.0 * UTM_PipSize(_Symbol));
         Print("PIPSTEST: t0 engine=", DoubleToString(g_t.ExecSLPips(), 1),
               " manual=", DoubleToString(UTM_PriceToPips(_Symbol, MathAbs(UTM_Ask(_Symbol) - g_t.ExecSL())), 1),
               " ask=", DoubleToString(UTM_Ask(_Symbol), _Digits),
               " sl=", DoubleToString(g_t.ExecSL(), _Digits));
         g_steps++;
         return;
        }
      waitTicks++;
      if(waitTicks < 60)
         return;
      Print("PIPSTEST: t1 engine=", DoubleToString(g_t.ExecSLPips(), 1),
            " manual=", DoubleToString(UTM_PriceToPips(_Symbol, MathAbs(UTM_Ask(_Symbol) - g_t.ExecSL())), 1),
            " ask=", DoubleToString(UTM_Ask(_Symbol), _Digits),
            " sl=", DoubleToString(g_t.ExecSL(), _Digits),
            " tp1=", DoubleToString(UTM_PriceToPips(_Symbol, MathAbs(g_t.ExecSL() - UTM_Ask(_Symbol))), 1));
      g_done = true;
      return;
     }

   if(InpScenario == 6)
     {
      if(g_steps == 0)
        {
         g_set.riskMode    = UTM_RISK_PERCENT;
         g_set.riskValue   = 1.0;
         g_set.commissionPerLot = 7.0;
         g_set.commissionInRisk = false;
         g_t.ActivateExec(POSITION_TYPE_BUY);
         g_t.ExecSetSL(UTM_Bid(_Symbol) - 20.0 * UTM_PipSize(_Symbol));
         double unitDist = UTM_PipsToPrice(_Symbol, 20.0);
         double rm1 = 0, dd1 = 0, rm2 = 0, dd2 = 0;
         g_set.commissionInRisk = false;
         double lotA = Risk_CalcLot(_Symbol, 1.00000, 1.00000 + unitDist, g_set, 10000.0, rm1, dd1);
         g_set.commissionInRisk = true;
         double lotB = Risk_CalcLot(_Symbol, 1.00000, 1.00000 + unitDist, g_set, 10000.0, rm2, dd2);
         Print("COMMUNIT: dist=", DoubleToString(unitDist, _Digits), " lotOff=", DoubleToString(lotA, 2), " riskOff=", DoubleToString(rm1, 2),
               " lotOn=", DoubleToString(lotB, 2), " riskOn=", DoubleToString(rm2, 2), " comm=", DoubleToString(g_set.commissionPerLot, 2));
         g_set.commissionInRisk = false;
         Print("COMMTEST: off -> lot=", DoubleToString(g_t.ExecLot(), 2),
               " risk=", DoubleToString(g_t.ExecRisk(), 2),
               " lossPerLot=", DoubleToString(UTM_LossPerLot(_Symbol, MathAbs(g_t.ExecEntry() - g_t.ExecSL())), 2),
               " cost=", DoubleToString(Risk_CostPerLot(_Symbol, MathAbs(g_t.ExecEntry() - g_t.ExecSL()), g_set), 2),
               " step=", DoubleToString(UTM_VolumeStep(_Symbol), 3),
               " riskValue=", DoubleToString(g_set.riskValue, 2), " mode=", g_set.riskMode);
         g_steps++;
         return;
        }
      if(g_steps == 1)
        {
         g_set.commissionInRisk = true;
         Print("COMMTEST: on  -> lot=", DoubleToString(g_t.ExecLot(), 2),
               " risk=", DoubleToString(g_t.ExecRisk(), 2),
               " cost=", DoubleToString(Risk_CostPerLot(_Symbol, MathAbs(g_t.ExecEntry() - g_t.ExecSL()), g_set), 2));
         g_steps++;
         g_done = true;
         return;
        }
     }

   if(InpScenario == 5)
     {
      double ask = UTM_Ask(_Symbol);
      double bid = UTM_Bid(_Symbol);
      double pip = UTM_PipSize(_Symbol);

      if(g_steps == 0)
        {
         g_t.ActivateExec(POSITION_TYPE_BUY);
         Print("FLIPTEST: start side=", g_t.ExecSide(), " eventry=", DoubleToString(g_t.ExecEntry(), _Digits),
               " tps=", TPList());
         g_steps++;
         return;
        }
      if(g_steps == 1)
        {
         //--- 止损放到市价上方 => 应自动切换为卖出，止盈镜像到下方
         g_t.ExecSetSL(ask + 25.0 * pip);
         Print("FLIPTEST: sl above price -> side=", g_t.ExecSide(),
               " execsl=", DoubleToString(g_t.ExecSL(), _Digits), " tps=", TPList());
         g_steps++;
         return;
        }
      if(g_steps == 2)
        {
         //--- 再放回下方 => 应切回买入
         g_t.ExecSetSL(bid - 30.0 * pip);
         Print("FLIPTEST: sl below price -> side=", g_t.ExecSide(),
               " execsl=", DoubleToString(g_t.ExecSL(), _Digits), " tps=", TPList());
         g_steps++;
         g_done = true;
         return;
        }
     }


   if(InpScenario == 4)
     {
      g_t.ActivateExec(POSITION_TYPE_BUY);
      g_set.hudBg = false;
      g_t.OnTimer();
      Print("HUDTEST: bg suppressed -> bgObject=",
            (ObjectFind(0, UTM_OBJ_PREFIX + "HUD_BG") >= 0 ? 1 : 0),
            " text1=", (ObjectFind(0, UTM_OBJ_PREFIX + "HUD_TXT") >= 0 ? 1 : 0));
      g_set.hudBg = true;
      g_t.OnTimer();
      Print("HUDTEST: bg restored -> bgObject=",
            (ObjectFind(0, UTM_OBJ_PREFIX + "HUD_BG") >= 0 ? 1 : 0));
      g_done = true;
      return;
     }

   if(InpScenario == 3)
     {
      if(g_steps == 0)
        {
         g_t.ActivateExec(POSITION_TYPE_BUY);
         g_t.OnTimer();
         Print("MEMTEST: before memorySave -> tpLabel=",
               (ObjectFind(0, UTM_OBJ_PREFIX + "X_LBL_TP_0") >= 0 ? 1 : 0),
               " slLabel=", (ObjectFind(0, UTM_OBJ_PREFIX + "X_LBL_SL") >= 0 ? 1 : 0),
               " hud2=", (ObjectFind(0, UTM_OBJ_PREFIX + "HUD_TXT2") >= 0 ? 1 : 0));
         g_steps++;
         return;
        }
      if(g_steps == 1)
        {
         g_set.memorySave = true;
         g_t.OnTimer();
         Print("MEMTEST: after memorySave -> tpLabel=",
               (ObjectFind(0, UTM_OBJ_PREFIX + "X_LBL_TP_0") >= 0 ? 1 : 0),
               " slLabel=", (ObjectFind(0, UTM_OBJ_PREFIX + "X_LBL_SL") >= 0 ? 1 : 0),
               " hud2=", (ObjectFind(0, UTM_OBJ_PREFIX + "HUD_TXT2") >= 0 ? 1 : 0));
         g_steps++;
         g_done = true;
         return;
        }
     }

   if(InpScenario == 2)
     {
      if(g_steps == 0)
        {
         g_t.ActivateExec(POSITION_TYPE_SELL);
         Report("cycle/activate");
         g_steps++;
         return;
        }
      if(g_steps == 1)
        {
         g_t.CycleOrderMode();
         Report("cycle/backspace-1 (expect LIMIT)");
         g_steps++;
         return;
        }
      if(g_steps == 2)
        {
         g_t.CycleOrderMode();
         Report("cycle/backspace-2 (expect STOP)");
         g_steps++;
         return;
        }
      if(g_steps == 3)
        {
         g_t.CycleOrderMode();
         Report("cycle/backspace-3 (expect MARKET)");
         g_t.DeactivateExec();
         Report("cycle/exit");
         g_steps++;
         g_done = true;
         return;
        }
     }
  }

void OnDeinit(const int reason)
  {
   g_t.Deinit();
  }
//+------------------------------------------------------------------+