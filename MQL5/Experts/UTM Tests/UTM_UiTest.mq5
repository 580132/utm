//+------------------------------------------------------------------+
//|                                                   UTM_UiTest.mq5 |
//|   Builds the panel inside the tester and validates the geometry   |
//+------------------------------------------------------------------+
#property copyright "UTM Manager"
#property version   "1.00"

#include <UTM/UTM_Defines.mqh>
#include <UTM/UTM_Utils.mqh>
#include <UTM/UTM_Settings.mqh>
#include <UTM/UTM_Engine.mqh>
#include <UTM/UTM_Panel.mqh>

CUtmEngine g_eng;
CUtmPanel  g_pnl;
bool       g_done = false;

int CountPanelObjects()
  {
   int n = 0;
   int total = ObjectsTotal(0, -1, -1);
   for(int i = 0; i < total; i++)
     {
      string nm = ObjectName(0, i, -1, -1);
      if(StringFind(nm, UTM_OBJ_PREFIX + "P_") == 0)
         n++;
     }
   return n;
  }

int OnInit()
  {
   g_utmForceUI = true;
   UTM_SetDefaults(g_set);
   g_set.sounds = false;
   g_set.tpCount = 3;
   g_set.tpPct[0] = 50.0;
   g_set.tpPct[1] = 30.0;
   g_set.tpPct[2] = 20.0;
   g_set.tpRR[0] = 1.0;
   g_set.tpRR[1] = 2.0;
   g_set.tpRR[2] = 3.0;
   g_set.trailingTP = true;

   if(!g_eng.Init(_Symbol, _Symbol, 777777, 20))
      return INIT_FAILED;

   g_pnl.Init(&g_eng);
   g_pnl.Refresh();
   return INIT_SUCCEEDED;
  }

void OnTick()
  {
   g_eng.OnTick();
   if(g_done)
      return;
   g_done = true;

   g_pnl.Refresh();

   int px = g_pnl.X(), py = g_pnl.Y(), pw = g_pnl.Width(), ph = g_pnl.Height();
   int cw = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   int ch = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);

   Print("UITEST: chart ", cw, "x", ch, "  panel ", px, ",", py, " ", pw, "x", ph,
         "  right=", px + pw, " bottom=", py + ph);

   int total = ObjectsTotal(0, -1, -1);
   int bad = 0, edits = 0, buttons = 0, labels = 0, rects = 0;

   for(int i = 0; i < total; i++)
     {
      string nm = ObjectName(0, i, -1, -1);
      if(StringFind(nm, UTM_OBJ_PREFIX + "P_") != 0)
         continue;

      int t = (int)ObjectGetInteger(0, nm, OBJPROP_TYPE);
      int x = (int)ObjectGetInteger(0, nm, OBJPROP_XDISTANCE);
      int y = (int)ObjectGetInteger(0, nm, OBJPROP_YDISTANCE);
      int w = (int)ObjectGetInteger(0, nm, OBJPROP_XSIZE);
      int h = (int)ObjectGetInteger(0, nm, OBJPROP_YSIZE);

      if(t == OBJ_EDIT)   edits++;
      if(t == OBJ_BUTTON) buttons++;
      if(t == OBJ_LABEL)  labels++;
      if(t == OBJ_RECTANGLE_LABEL) rects++;

      bool outside = (x < px - 2 || y < py - 2 || x > px + pw || y > py + ph);
      bool wide = ((t == OBJ_BUTTON || t == OBJ_EDIT || t == OBJ_RECTANGLE_LABEL) &&
                   (w <= 0 || x + w > px + pw + 2));
      bool tall = ((t == OBJ_BUTTON || t == OBJ_EDIT || t == OBJ_RECTANGLE_LABEL) &&
                   (h <= 0 || y + h > py + ph + 2));

      if(outside || wide || tall)
        {
         bad++;
         Print("UITEST: OUTSIDE ", nm, " type=", t, " rect=", x, ",", y, " ", w, "x", h,
               " (panel ", px, ",", py, " ", pw, "x", ph, ")");
        }

      //--- text must be readable
      string txt = ObjectGetString(0, nm, OBJPROP_TEXT);
      if((t == OBJ_BUTTON || t == OBJ_EDIT) && txt == "")
        {
         bad++;
         Print("UITEST: EMPTY TEXT ", nm);
        }
     }

   Print("UITEST: objects=", total, " edits=", edits, " buttons=", buttons,
         " labels=", labels, " rects=", rects, " problems=", bad);
   Print("UITEST: title=[", ObjectGetString(0, "UTM_P_TITLE", OBJPROP_TEXT), "]",
         " buyBtn=[", ObjectGetString(0, "UTM_P_BTN_BUY", OBJPROP_TEXT), "]",
         " riskSec=[", ObjectGetString(0, "UTM_P_SEC_RISK", OBJPROP_TEXT), "]");

   //--- collapse / expand must not leak objects
   g_pnl.OnClick("UTM_P_BTN_MIN");
   g_pnl.Refresh();
   Print("UITEST: collapsed height=", g_pnl.Height(),
         " panelObjects=", CountPanelObjects());

   //--- repeated rebuilds (this is what happens while the chart is dragged)
   int badBg = 0;
   for(int k = 0; k < 25; k++)
     {
      g_pnl.Refresh();
      int bgH = (int)ObjectGetInteger(0, "UTM_P_BG", OBJPROP_YSIZE);
      if(bgH != g_pnl.Height())
         badBg++;
     }
   Print("UITEST: rebuild loop bgMismatch=", badBg,
         " bgH=", (int)ObjectGetInteger(0, "UTM_P_BG", OBJPROP_YSIZE),
         " panelH=", g_pnl.Height());

   g_pnl.OnClick("UTM_P_BTN_MIN");
   g_pnl.Refresh();
   Print("UITEST: expanded height=", g_pnl.Height());

   //--- exercise the edit handler
   ObjectSetString(0, "UTM_P_E_TPPCT2", OBJPROP_TEXT, "25");
   g_pnl.OnEndEdit("UTM_P_E_TPPCT2");
   Print("UITEST: after edit tpCount=", g_set.tpCount, " tpPct2=", DoubleToString(g_set.tpPct[1], 0));

   ObjectSetString(0, "UTM_P_E_SLSIZE", OBJPROP_TEXT, "35");
   g_pnl.OnEndEdit("UTM_P_E_SLSIZE");
   Print("UITEST: after edit slSize=", DoubleToString(g_set.slSize, 1));

   g_set.memorySave = true;
   g_pnl.Refresh();
   Print("UITEST: memorySave -> panelObjects=", CountPanelObjects(),
         " info2=", (ObjectFind(0, "UTM_P_INFO2") >= 0 ? 1 : 0),
         " ins=", (ObjectFind(0, "UTM_P_INS") >= 0 ? 1 : 0));
   g_set.memorySave = false;
   g_pnl.Refresh();
   Print("UITEST: full -> panelObjects=", CountPanelObjects());

   g_pnl.OnClick("UTM_P_BTN_RISKMODE");
   Print("UITEST: risk mode -> ", g_set.riskMode, " value=", DoubleToString(g_set.riskValue, 2));

   g_pnl.OnClick("UTM_P_BTN_SPREAD");
   Print("UITEST: spread mode -> ", g_set.spreadMode);

   g_pnl.OnClick("UTM_P_BTN_HIDE");
   Print("UITEST: after hide visible=", (g_pnl.Visible() ? "1" : "0"),
         " objects=", ObjectsTotal(0, -1, -1));

   g_pnl.OnClick("UTM_P_SHOW");
   g_pnl.Refresh();
   Print("UITEST: after show visible=", (g_pnl.Visible() ? "1" : "0"));
  }

void OnDeinit(const int reason)
  {
   g_pnl.Destroy();
   g_eng.Deinit();
  }
//+------------------------------------------------------------------+