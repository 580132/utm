//+------------------------------------------------------------------+
//|                                                   UTM_Panel.mqh  |
//|   On-chart control panel (settings GUI)                           |
//+------------------------------------------------------------------+
#ifndef __UTM_PANEL_MQH__
#define __UTM_PANEL_MQH__

#include "UTM_Defines.mqh"
#include "UTM_Utils.mqh"
#include "UTM_Settings.mqh"
#include "UTM_Engine.mqh"
#include "UTM_Insights.mqh"

class CUtmPanel
  {
private:
   CUtmEngine       *m_eng;
   int               m_x, m_y, m_w, m_h;
   int               m_fullH;   // expanded height in design units
   bool              m_collapsed;
   bool              m_autoCollapsed;
   bool              m_memCollapsed;  // collapsed because of 省内存
   bool              m_memWas;       // previous 省内存 state (edge detect)
   bool              m_fgSaved;      // we turned CHART_FOREGROUND off
   bool              m_visible;
   bool              m_sync;
   double            m_s;      // effective panel scale (DPI, capped to the chart height)
   string            m_status;
   color             m_statusClr;
   int               m_chartW, m_chartH;

   //--- primitive builders
   void              Rect(const string name, const int x, const int y, const int w, const int h,
                          const color bg, const color border);
   void              Label(const string name, const int x, const int y, const string text,
                           const color clr, const int size, const bool bold = false);
   void              Edit(const string name, const int x, const int y, const int w, const string text,
                          const string tip = "");
   void              Button(const string name, const int x, const int y, const int w, const int h,
                            const string text, const color bg, const color clr, const int size = 8,
                            const string tip = "");
   void              Section(const string name, const int x, const int y, const string text);
   void              SetVisibleObj(const string name, const bool show);
   void              DestroyAll();
   void              ClearControls();
   void              Show(bool on);

   //--- content
   void              Build();
   void              ApplyChartForeground();
   void              BuildHeader(int &y);
   void              BuildRisk(int &y);
   void              BuildStopLoss(int &y);
   void              BuildTakeProfit(int &y);
   void              BuildManagement(int &y);
   void              BuildSpread(int &y);
   void              BuildFooter(int &y);
   string            Fmt(const double v, const int d) { return DoubleToString(v, d); }
   int               Px(const int v) const { return (int)MathRound((double)v * m_s); }
   int               Fnt(const int v) const { return (int)MathMax(7, MathRound((double)v * m_s) + 1); }

public:
                     CUtmPanel(): m_eng(NULL), m_x(0), m_y(0), m_w(272), m_h(0),
                                  m_collapsed(false), m_autoCollapsed(false), m_memCollapsed(false), m_memWas(false), m_fgSaved(false), m_visible(true), m_sync(true), m_s(1.0), m_fullH(0),
                                  m_status(""), m_statusClr(UTM_CLR_TEXT_DIM),
                                  m_chartW(0), m_chartH(0) {}

   void              Init(CUtmEngine *eng) { m_eng = eng; }
   void              Destroy();
   void              Refresh();
   void              Sync() { m_sync = true; }
   bool              Visible() const { return m_visible; }
   int               Width()  const { return m_w; }
   int               Height() const { return m_h; }
   int               X()      const { return m_x; }
   int               Y()      const { return m_y; }
   bool              HitTest(const int x, const int y) const
     {
      if(!m_visible)
         return false;
      int rx = Px(m_x);
      int ry = Px(m_y);
      return (x >= rx && x <= rx + Px(m_w) && y >= ry && y <= ry + Px(m_h));
     }
   bool              IsPanelObject(const string name) const { return (StringFind(name, UTM_OBJ_PREFIX + "P_") == 0); }
   void              OnClick(const string name);
   void              OnEndEdit(const string name);
  };

//+------------------------------------------------------------------+
//| low level object helpers                                          |
//+------------------------------------------------------------------+
void CUtmPanel::Rect(const string name, const int x, const int y, const int w, const int h,
                     const color bg, const color border)
  {
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
     }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, Px(x));
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, Px(y));
   ObjectSetInteger(0, name, OBJPROP_XSIZE, Px(w));
   ObjectSetInteger(0, name, OBJPROP_YSIZE, Px(h));
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, border);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, MathMax(1, Px(1)));
  }

void CUtmPanel::Label(const string name, const int x, const int y, const string text,
                      const color clr, const int size, const bool bold)
  {
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
     }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, Px(x));
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, Px(y));
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, bold ? "Microsoft YaHei" : "Microsoft YaHei");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, Fnt(size));
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
  }

void CUtmPanel::Edit(const string name, const int x, const int y, const int w, const string text,
                     const string tip)
  {
   bool isNew = (ObjectFind(0, name) < 0);
   if(isNew)
     {
      ObjectCreate(0, name, OBJ_EDIT, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_ALIGN, ALIGN_CENTER);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, UTM_CLR_BORDER);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, UTM_CLR_BG_ALT);
      ObjectSetInteger(0, name, OBJPROP_COLOR, UTM_CLR_TEXT);
      ObjectSetString(0, name, OBJPROP_FONT, "Microsoft YaHei");
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, Fnt(8));
     }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, Px(x));
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, Px(y));
   ObjectSetInteger(0, name, OBJPROP_XSIZE, Px(w));
   ObjectSetInteger(0, name, OBJPROP_YSIZE, Px(18));
   if(tip != "")
      ObjectSetString(0, name, OBJPROP_TOOLTIP, tip);
   if(isNew || m_sync)
      ObjectSetString(0, name, OBJPROP_TEXT, text);
  }

void CUtmPanel::Button(const string name, const int x, const int y, const int w, const int h,
                       const string text, const color bg, const color clr, const int size, const string tip)
  {
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, UTM_CLR_BORDER);
      ObjectSetString(0, name, OBJPROP_FONT, "Microsoft YaHei");
     }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, Px(x));
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, Px(y));
   ObjectSetInteger(0, name, OBJPROP_XSIZE, Px(w));
   ObjectSetInteger(0, name, OBJPROP_YSIZE, Px(h));
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, Fnt(size));
   if(tip != "")
      ObjectSetString(0, name, OBJPROP_TOOLTIP, tip);
  }

void CUtmPanel::Section(const string name, const int x, const int y, const string text)
  {
   Label(name, x, y, text, UTM_CLR_ACCENT, 8, true);
   Rect(name + "_LN", x, y + 14, m_w - 16, 1, UTM_CLR_BORDER, UTM_CLR_BORDER);
  }

//+------------------------------------------------------------------+
//| lifecycle                                                         |
//+------------------------------------------------------------------+
void CUtmPanel::Destroy()
  {
   DestroyAll();
   if(ObjectFind(0, "UTM_P_SHOW") >= 0)
      ObjectDelete(0, "UTM_P_SHOW");
   m_visible = false;
   ApplyChartForeground();
  }

void CUtmPanel::DestroyAll()
  {
   ObjectsDeleteAll(0, UTM_OBJ_PREFIX + "P_");
  }

//--- delete panel controls while keeping the header objects
void CUtmPanel::ClearControls()
  {
   int total = ObjectsTotal(0, -1, -1);
   for(int i = total - 1; i >= 0; i--)
     {
      string nm = ObjectName(0, i, -1, -1);
      if(StringFind(nm, UTM_OBJ_PREFIX + "P_") != 0)
         continue;
      if(nm == "UTM_P_BG" || nm == "UTM_P_TITLEBG" ||
         nm == "UTM_P_TITLE" || nm == "UTM_P_VER" || nm == "UTM_P_BTN_MIN")
         continue;
      ObjectDelete(0, nm);
     }
  }

void CUtmPanel::Show(const bool on)
  {
   bool was = m_visible;
   m_visible = on;
   g_set.panelVisible = on;
   if(!on)
     {
      if(was)
         DestroyAll();
      m_eng.SetPanelRect(0, 0, 0, 0, false);
      if(ObjectFind(0, "UTM_P_SHOW") < 0)
        {
         int cw = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
         Button("UTM_P_SHOW", 10, 24, 54, 18, "UTM", UTM_CLR_ACCENT_DARK, C'255,255,255', 8,
                "显示 UTM 面板");
        }
     }
   else
     {
      if(ObjectFind(0, "UTM_P_SHOW") >= 0)
         ObjectDelete(0, "UTM_P_SHOW");
     }
   ApplyChartForeground();
  }

//+------------------------------------------------------------------+
//| refresh                                                           |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| 展开时关掉「图表前景」，避免蜡烛盖住面板；折叠/隐藏时恢复原值     |
//+------------------------------------------------------------------+
void CUtmPanel::ApplyChartForeground()
  {
   bool expanded = (m_visible && g_set.panelVisible && !m_collapsed);

   if(expanded)
     {
      //--- 展开期间保持关闭，避免蜡烛盖住面板；记住它本来是开着的
      if((int)ChartGetInteger(0, CHART_FOREGROUND) != 0)
        {
         m_fgSaved = true;
         ChartSetInteger(0, CHART_FOREGROUND, false);
        }
     }
   else if(m_fgSaved)
     {
      ChartSetInteger(0, CHART_FOREGROUND, true);
      m_fgSaved = false;
     }
  }

//+------------------------------------------------------------------+
//| refresh                                                           |
//+------------------------------------------------------------------+
void CUtmPanel::Refresh()
  {
   if(m_eng == NULL)
      return;
   if(!UTM_VisualMode())
      return;

   m_chartW = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   m_chartH = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);

   //--- effective scale: requested DPI scale, but never taller than the chart
   m_s = g_uiScale;
   if(m_s > 1.0)
     {
      double avail = (double)m_chartH - 40.0 * m_s;
      double need  = (m_fullH > 0 ? (double)m_fullH : 610.0) * m_s;
      if(need > avail && avail > 0.0)
        {
         double fit = avail / (m_fullH > 0 ? (double)m_fullH : 610.0);
         if(fit < 1.0)
            fit = 1.0;
         m_s = fit;
        }
     }

   if(!g_set.panelVisible)
     {
      Show(false);
      m_sync = false;
      return;
     }

   if(!m_visible)
      Show(true);

   Build();
   m_sync = false;

   //--- 省内存：打开时面板只保留折叠态的内容（之后仍可点 + 展开）
   if(g_set.memorySave && !m_memWas)
     {
      m_memWas       = true;
      m_memCollapsed = true;
      m_collapsed    = true;
      m_autoCollapsed = true;
      Build();
     }
   else if(!g_set.memorySave && m_memWas)
     {
      m_memWas = false;
      if(m_memCollapsed)
        {
         m_memCollapsed  = false;
         m_collapsed     = false;
         m_autoCollapsed = false;
         Build();
        }
     }


   //--- keep the panel usable on very short charts
   if(!g_utmForceUI && !m_collapsed && !m_autoCollapsed && m_chartH > Px(200) && Px(m_h) > m_chartH - 8)
     {
      m_collapsed = true;
      m_autoCollapsed = true;
      Build();
     }
   ApplyChartForeground();
  }

void CUtmPanel::Build()
  {
   m_w = 272;
   m_x = 10;   // fixed on the left side
   m_y = 24;
   int x0 = m_x + 8;
   int y = m_y;

   if(ObjectFind(0, "UTM_P_SHOW") >= 0)
      ObjectDelete(0, "UTM_P_SHOW");

   //--- create the background once (z-order); its size is set at the end
   if(ObjectFind(0, "UTM_P_BG") < 0)
      Rect("UTM_P_BG", m_x, m_y, m_w, 120, UTM_CLR_BG, UTM_CLR_BORDER);
   if(ObjectFind(0, "UTM_P_TITLEBG") < 0)
      Rect("UTM_P_TITLEBG", m_x, m_y, m_w, 26, UTM_CLR_HEADER, UTM_CLR_BORDER);

   if(m_collapsed)
      ClearControls();

   BuildHeader(y);

   if(m_collapsed)
     {
      m_h = (y - m_y) + 8;
      Rect("UTM_P_BG", m_x, m_y, m_w, m_h, UTM_CLR_BG, UTM_CLR_BORDER);
      Rect("UTM_P_TITLEBG", m_x, m_y, m_w, 26, UTM_CLR_HEADER, UTM_CLR_BORDER);
   m_eng.SetPanelRect(Px(m_x), Px(m_y), Px(m_w), Px(m_h), true);
      return;
     }

   BuildRisk(y);
   BuildStopLoss(y);
   BuildTakeProfit(y);
   BuildManagement(y);
   BuildSpread(y);
   BuildFooter(y);

   m_h = (y - m_y) + 8;
   m_fullH = m_h;
   Rect("UTM_P_BG", m_x, m_y, m_w, m_h, UTM_CLR_BG, UTM_CLR_BORDER);
   Rect("UTM_P_TITLEBG", m_x, m_y, m_w, 26, UTM_CLR_HEADER, UTM_CLR_BORDER);
   m_eng.SetPanelRect(Px(m_x), Px(m_y), Px(m_w), Px(m_h), true);
  }

//+------------------------------------------------------------------+
//| header                                                            |
//+------------------------------------------------------------------+
void CUtmPanel::BuildHeader(int &y)
  {
   int x0 = m_x + 8;

   Label("UTM_P_TITLE", x0, m_y + 5, "UTM  交易管理器", UTM_CLR_TEXT, 10, true);
   Label("UTM_P_VER", x0 + 118, m_y + 8, "v" + UTM_VERSION, UTM_CLR_TEXT_DIM, 7, false);
   ObjectSetString(0, "UTM_P_VER", OBJPROP_TOOLTIP, "编译 " + UTM_BuildStamp());

   Button("UTM_P_BTN_MIN", m_x + m_w - 26, m_y + 5, 18, 16, (m_collapsed ? "+" : "-"),
          UTM_CLR_HEADER, UTM_CLR_TEXT, 9, "折叠 / 展开");

   y = m_y + 32;

   double bal = UTM_BalanceForRisk(g_set.overrideBalance);
   double eq  = AccountInfoDouble(ACCOUNT_EQUITY);
   Label("UTM_P_INFO1", x0, y,
         "余额 " + UTM_Priv(UTM_FmtMoney(bal)) + "   净值 " + UTM_Priv(UTM_FmtMoney(eq)) + "   " + AccountInfoString(ACCOUNT_CURRENCY),
         UTM_CLR_TEXT_DIM, 8, false);
   y += 14;

   Label("UTM_P_INFO2", x0, y,
         "点差 " + DoubleToString(UTM_PriceToPips(m_eng.Symbol(), m_eng.RawSpread()), 1) +
         "   均值 " + DoubleToString(UTM_PriceToPips(m_eng.Symbol(), m_eng.EmaSpread()), 1) +
         "   " + (UTM_IsHedging() ? "对冲" : "净额"),
         UTM_CLR_TEXT_DIM, 8, false);
   y += 16;

   //--- 快捷交易（默认隐藏，可在「设置」里打开）
   if(g_set.showQuickTrade)
     {
      Button("UTM_P_BTN_BUY", x0, y, 124, 22, "买入", UTM_CLR_BUY, C'255,255,255', 9, "市价买入");
      Button("UTM_P_BTN_SELL", x0 + 132, y, 124, 22, "卖出", UTM_CLR_SELL, C'255,255,255', 9, "市价卖出");
      y += 26;
     }
   else
     {
      ObjectDelete(0, "UTM_P_BTN_BUY");
      ObjectDelete(0, "UTM_P_BTN_SELL");
     }

   bool ex = m_eng.ExecActive();
   Button("UTM_P_BTN_EXEC", x0, y, 60, 20, (ex ? "退出" : "执行"),
          (ex ? UTM_CLR_ACCENT : UTM_CLR_BG_ALT), UTM_CLR_TEXT, 8,
          (ex ? "退出执行模式（ESC）" : "进入执行模式后，在图表上左键下单（或按 Enter）"));
   Button("UTM_P_BTN_BE", x0 + 64, y, 60, 20, "保本", UTM_CLR_BG_ALT, UTM_CLR_TEXT, 8, "全部保本（E）");
   Button("UTM_P_BTN_CLOSE", x0 + 128, y, 60, 20, "全平", UTM_CLR_BG_ALT, UTM_CLR_TEXT, 8, "平掉全部仓位（X）");
   Button("UTM_P_BTN_CANCEL", x0 + 192, y, 64, 20, "撤挂", UTM_CLR_BG_ALT, UTM_CLR_TEXT, 8, "取消全部挂单（C）");
   y += 24;

   string st = m_eng.LastError();
   color  sc = UTM_CLR_WARN;
   if(st == "")
     {
      st = m_status;
      sc = UTM_CLR_TEXT_DIM;
     }
   if(st == "")
     {
      st = m_eng.LastInfo();
      sc = UTM_CLR_TEXT_DIM;
     }
   if(st == "")
      st = "就绪 · 按 ESC 开始交易";
   if(StringLen(st) > 30)
      st = StringSubstr(st, 0, 30) + "..";
   Label("UTM_P_STATUS", x0, y, st, sc, 7, false);
   y += 13;

   string ins = "";
   color  iclr = UTM_CLR_TEXT_DIM;
   UTM_InsightsLine(m_eng.Magic(), ins, iclr);
   if(ins != "")
      Label("UTM_P_INS", x0, y, ins, iclr, 7, false);
   else
      ObjectDelete(0, "UTM_P_INS");
   y += 14;
  }

//+------------------------------------------------------------------+
//| 风险                                                              |
//+------------------------------------------------------------------+
void CUtmPanel::BuildRisk(int &y)
  {
   int x0 = m_x + 8;
   Section("UTM_P_SEC_RISK", x0, y, "风险");
   y += 18;

   string modeTxt = "风险 %";
   if(g_set.riskMode == UTM_RISK_MONEY) modeTxt = "金额";
   else if(g_set.riskMode == UTM_RISK_LOT) modeTxt = "手数";

   Button("UTM_P_BTN_RISKMODE", x0, y, 80, 18, modeTxt, UTM_CLR_ACCENT_DARK, C'255,255,255', 8,
          "风险模式：按余额百分比 / 固定金额 / 固定手数");
   Edit("UTM_P_E_RISK", x0 + 84, y, 54, Fmt(g_set.riskValue, 2), "风险数值");
   Label("UTM_P_L_MAX", x0 + 142, y + 3, "上限", UTM_CLR_TEXT_DIM, 7, false);
   Edit("UTM_P_E_MAXLOT", x0 + 168, y, 50, Fmt(g_set.maxLot, 2), "最大手数（0 = 不限）");
   y += 21;

   Label("UTM_P_L_EQ", x0, y + 3, "净值", UTM_CLR_TEXT_DIM, 7, false);
   Edit("UTM_P_E_EQSTOP", x0 + 28, y, 48, Fmt(g_set.equityStop, 0), "净值止损线（0 = 关闭）");
   Label("UTM_P_L_ABN", x0 + 80, y + 3, "点差", UTM_CLR_TEXT_DIM, 7, false);
   Edit("UTM_P_E_ABN", x0 + 110, y, 34, Fmt(g_set.abnormalSpread, 1), "异常点差倍数");
   Button("UTM_P_BTN_SPLIT", x0 + 150, y, 106, 18,
          (g_set.bypassMaxLot ? "拆单：开" : "拆单：关"),
          (g_set.bypassMaxLot ? UTM_CLR_ACCENT_DARK : UTM_CLR_BG_ALT), UTM_CLR_TEXT, 7,
          "超过经纪商最大手数时自动拆成多笔");
   y += 24;
  }

//+------------------------------------------------------------------+
//| 止损                                                              |
//+------------------------------------------------------------------+
void CUtmPanel::BuildStopLoss(int &y)
  {
   int x0 = m_x + 8;
   Section("UTM_P_SEC_SL", x0, y, "止损");
   y += 18;

   Button("UTM_P_BTN_FIXED", x0, y, 68, 18,
          (g_set.fixedSL ? "固定止损" : "拖动止损"),
          (g_set.fixedSL ? UTM_CLR_ACCENT_DARK : UTM_CLR_BG_ALT), UTM_CLR_TEXT, 7,
          "使用固定止损大小");
   Edit("UTM_P_E_SLSIZE", x0 + 72, y, 46, Fmt(g_set.slSize, 1), "止损大小");

   string unitTxt = "pip";
   if(g_set.slUnit == UTM_SL_POINTS)
      unitTxt = "点";
   Button("UTM_P_BTN_UNIT", x0 + 122, y, 60, 18, unitTxt, UTM_CLR_BG_ALT, UTM_CLR_TEXT, 7,
          "止损单位：pip / 点（点一下切换）");
   Button("UTM_P_BTN_LOCKRR", x0 + 186, y, 70, 18,
          (g_set.lockRR ? "锁定盈亏比" : "不锁盈亏比"),
          (g_set.lockRR ? UTM_CLR_ACCENT_DARK : UTM_CLR_BG_ALT), UTM_CLR_TEXT, 7,
          "拖动挂单入场线时锁定盈亏比不变");
   y += 21;

   Label("UTM_P_L_SLMIN", x0, y + 3, "最小", UTM_CLR_TEXT_DIM, 7, false);
   Edit("UTM_P_E_SLMIN", x0 + 28, y, 38, Fmt(g_set.slMin, 1), "最小止损");
   Label("UTM_P_L_SLMAX", x0 + 70, y + 3, "最大", UTM_CLR_TEXT_DIM, 7, false);
   Edit("UTM_P_E_SLMAX", x0 + 98, y, 38, Fmt(g_set.slMax, 1), "最大止损");
   y += 24;
  }

//+------------------------------------------------------------------+
//| 止盈                                                              |
//+------------------------------------------------------------------+
void CUtmPanel::BuildTakeProfit(int &y)
  {
   int x0 = m_x + 8;
   Section("UTM_P_SEC_TP", x0, y, "止盈（盈亏比 / 平仓比例）");
   y += 18;

   for(int i = 0; i < UTM_MAX_TP; i++)
     {
      string tag = IntegerToString(i + 1);
      color  clr = (g_set.tpPct[i] > 0.0 ? UTM_CLR_TEXT : UTM_CLR_TEXT_DIM);

      Label("UTM_P_L_TP" + tag, x0, y + 3, "止盈" + tag, clr, 7, false);
      Edit("UTM_P_E_TPRR" + tag, x0 + 32, y, 46, Fmt(g_set.tpRR[i], 2),
           "止盈" + tag + " 的盈亏比");
      Edit("UTM_P_E_TPPCT" + tag, x0 + 82, y, 46, Fmt(g_set.tpPct[i], 0),
           "止盈" + tag + " 平仓百分比（0 = 关闭该级）");

      string px = "";
      if(m_eng.Count() > 0)
        {
         STrade last;
         if(m_eng.GetTradeInfo(m_eng.Count() - 1, last) && i < last.tpCount)
            px = UTM_FmtPrice(m_eng.Symbol(), last.tp[i]);
        }
      Label("UTM_P_L_TPX" + tag, x0 + 136, y + 3, px, UTM_CLR_TEXT_DIM, 7, false);
      y += 20;
     }

   y += 2;
  }

//+------------------------------------------------------------------+
//| 持仓管理                                                          |
//+------------------------------------------------------------------+
void CUtmPanel::BuildManagement(int &y)
  {
   int x0 = m_x + 8;
   Section("UTM_P_SEC_MGMT", x0, y, "持仓管理");
   y += 18;

   Label("UTM_P_L_BE", x0, y + 3, "保本+", UTM_CLR_TEXT_DIM, 7, false);
   Edit("UTM_P_E_BE", x0 + 30, y, 38, Fmt(g_set.beOffsetRR, 2), "保本时额外锁定的盈亏比");
   Button("UTM_P_BTN_DROPPEND", x0 + 74, y, 88, 18,
          (g_set.removePendingOnSL ? "触发止损撤挂" : "保留挂单"),
          (g_set.removePendingOnSL ? UTM_CLR_ACCENT_DARK : UTM_CLR_BG_ALT), UTM_CLR_TEXT, 7,
          "价格先触及止损位时撤销该挂单");
   Button("UTM_P_BTN_FAILSAFE", x0 + 166, y, 90, 18,
          (g_set.failsafeSL ? "兜底止损：开" : "兜底止损：关"),
          (g_set.failsafeSL ? UTM_CLR_ACCENT_DARK : UTM_CLR_BG_ALT), UTM_CLR_TEXT, 7,
          "虚拟止损时额外在 2R 处挂经纪商止损");
   y += 21;

   Button("UTM_P_BTN_SRVTP", x0, y, 128, 18,
          (g_set.serverSplitTP ? "服务器TP：拆仓" : "服务器TP：关"),
          (g_set.serverSplitTP ? UTM_CLR_ACCENT_DARK : UTM_CLR_BG_ALT), UTM_CLR_TEXT, 7,
          "开：挂单按止盈级别拆成多张订单（各自挂服务器止盈）；市价单不拆，避免滑点造成入场价不一致，改为整仓挂末级止盈");
   Label("UTM_P_L_SRVTP", x0 + 132, y + 3, "拆不了挂末级", UTM_CLR_TEXT_DIM, 7, false);
   y += 21;

   Button("UTM_P_BTN_DEFMODE", x0, y, 128, 18,
          "默认模式：" + (g_set.defaultOrderMode == UTM_ORDER_LIMIT ? "限价" :
                          (g_set.defaultOrderMode == UTM_ORDER_STOP ? "突破" : "市价")),
          (g_set.defaultOrderMode == UTM_ORDER_MARKET ? UTM_CLR_BG_ALT : UTM_CLR_ACCENT_DARK), UTM_CLR_TEXT, 7,
          "按 ESC / 点执行进入执行模式时使用的订单类型；点一下切换 市价 → 限价 → 突破");
   Label("UTM_P_L_DEFMODE", x0 + 132, y + 3, "进入执行时用", UTM_CLR_TEXT_DIM, 7, false);
   y += 21;

   Edit("UTM_P_E_FORMULA", x0, y, 256, g_set.formula,
        "交易管理公式，例如  1.0:BE   1.5:TS 1.0   2.0:CLOSE 50");
   y += 24;
  }

//+------------------------------------------------------------------+
//| 点差                                                              |
//+------------------------------------------------------------------+
void CUtmPanel::BuildSpread(int &y)
  {
   int x0 = m_x + 8;
   Section("UTM_P_SEC_SPREAD", x0, y, "点差");
   y += 18;

   string modeTxt = "点差：关";
   if(g_set.spreadMode == UTM_SPREAD_FACTOR)    modeTxt = "点差因子";
   if(g_set.spreadMode == UTM_SPREAD_IGNORE)    modeTxt = "忽略点差";
   if(g_set.spreadMode == UTM_SPREAD_INVISIBLE) modeTxt = "忽略+隐形";

   Button("UTM_P_BTN_SPREAD", x0, y, 104, 18, modeTxt,
          (g_set.spreadMode == UTM_SPREAD_OFF ? UTM_CLR_BG_ALT : UTM_CLR_ACCENT_DARK),
          UTM_CLR_TEXT, 7, "点差处理模式");
   Edit("UTM_P_E_SPREADF", x0 + 108, y, 44, Fmt(g_set.spreadFactor, 2),
        "点差因子（pip，0 = 自动使用均值）");
   Edit("UTM_P_E_EMA", x0 + 156, y, 44, Fmt(g_set.emaSpread, 3),
        "点差均值平滑系数 0.001 - 1.0");
   Label("UTM_P_L_EMA", x0 + 204, y + 3, "平滑", UTM_CLR_TEXT_DIM, 7, false);
   y += 21;

   Label("UTM_P_L_SPREAD", x0, y,
         "均值 " + DoubleToString(UTM_PriceToPips(m_eng.Symbol(), m_eng.EmaSpread()), 1) +
         " 点  /  实时 " + DoubleToString(UTM_PriceToPips(m_eng.Symbol(), m_eng.RawSpread()), 1) + " 点",
         UTM_CLR_TEXT_DIM, 7, false);
   y += 15;
  }

//+------------------------------------------------------------------+
//| 本地跟单                                                          |
//+------------------------------------------------------------------+
void CUtmPanel::BuildFooter(int &y)
  {
   int x0 = m_x + 8;
   Section("UTM_P_SEC_SET", x0, y, "设置");
   y += 18;

   Edit("UTM_P_E_PROFILE", x0, y, 140, g_set.profile, "配置文件名");
   Button("UTM_P_BTN_SAVE", x0 + 144, y, 52, 18, "保存", UTM_CLR_ACCENT_DARK, C'255,255,255', 7,
          "保存到共享的配置文件");
   Button("UTM_P_BTN_LOAD", x0 + 200, y, 56, 18, "读取", UTM_CLR_BG_ALT, UTM_CLR_TEXT, 7,
          "读取共享的配置文件");
   y += 22;

   Button("UTM_P_BTN_MEM", x0, y, 52, 18,
          (g_set.memorySave ? "省内存" : "标准"),
          (g_set.memorySave ? UTM_CLR_ACCENT_DARK : UTM_CLR_BG_ALT), UTM_CLR_TEXT, 7,
          "省内存：面板收起为折叠态（图表上的文字和按钮不受影响）");
   Button("UTM_P_BTN_SND", x0 + 56, y, 48, 18,
          (g_set.sounds ? "声音开" : "声音关"),
          (g_set.sounds ? UTM_CLR_ACCENT_DARK : UTM_CLR_BG_ALT), UTM_CLR_TEXT, 7,
          "成交 / 止损 / 止盈提示音");
   Button("UTM_P_BTN_PRIV", x0 + 108, y, 48, 18,
          (g_set.privacyMode ? "隐私开" : "隐私关"),
          (g_set.privacyMode ? UTM_CLR_ACCENT_DARK : UTM_CLR_BG_ALT), UTM_CLR_TEXT, 7,
          "隐私模式：余额 / 净值 / 盈亏 / 手数显示为 ****");
   Button("UTM_P_BTN_QUICK", x0 + 160, y, 48, 18,
          (g_set.showQuickTrade ? "买卖开" : "买卖关"),
          (g_set.showQuickTrade ? UTM_CLR_ACCENT_DARK : UTM_CLR_BG_ALT), UTM_CLR_TEXT, 7,
          "面板顶部的「买入 / 卖出」快捷按钮：默认隐藏");
   Button("UTM_P_BTN_HIDE", x0 + 212, y, 44, 18, "隐藏", UTM_CLR_BG_ALT, UTM_CLR_TEXT, 7,
          "隐藏面板");
   y += 22;

   Label("UTM_P_L_COMM", x0, y + 3, "佣金/手", UTM_CLR_TEXT_DIM, 7, false);
   Edit("UTM_P_E_COMM", x0 + 40, y, 46, Fmt(UTM_CommissionPerLot(g_set), 2),
        (g_set.commissionAuto
         ? (g_commDetected
            ? "自动（" + g_commSource + "）：每手往返 " + Fmt(g_commPerLot, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY)
            : "品种规格和成交里都没有佣金，按 0 计")
         : "每手往返佣金（账户货币）"));
   ObjectSetInteger(0, "UTM_P_E_COMM", OBJPROP_READONLY, g_set.commissionAuto);
   ObjectSetInteger(0, "UTM_P_E_COMM", OBJPROP_BGCOLOR,
                    g_set.commissionAuto ? UTM_CLR_BG : UTM_CLR_BG_ALT);
   ObjectSetString(0, "UTM_P_E_COMM", OBJPROP_TEXT, Fmt(UTM_CommissionPerLot(g_set), 2));
   Button("UTM_P_BTN_COMMAUTO", x0 + 90, y, 42, 18,
          (g_set.commissionAuto ? "自动" : "手动"),
          (g_set.commissionAuto ? UTM_CLR_ACCENT_DARK : UTM_CLR_BG_ALT), UTM_CLR_TEXT, 7,
          "自动从历史成交读取佣金；点一下改为手动填写");
   Button("UTM_P_BTN_COMMRISK", x0 + 136, y, 120, 18,
          (g_set.commissionInRisk ? "计入风险：开" : "计入风险：关"),
          (g_set.commissionInRisk ? UTM_CLR_ACCENT_DARK : UTM_CLR_BG_ALT), UTM_CLR_TEXT, 7,
          "打开后把佣金一起算进风险金额和手数");
   y += 22;

   Label("UTM_P_L_FOOT", x0, y, "ESC 执行 | 退格 切模式 | 左键 下单", UTM_CLR_TEXT_DIM, 7, false);
   y += 14;
  }

//+------------------------------------------------------------------+
//| 点击处理                                                          |
//+------------------------------------------------------------------+
void CUtmPanel::OnClick(const string name)
  {
   ObjectSetInteger(0, name, OBJPROP_STATE, false);

   if(name == "UTM_P_SHOW")             { Show(true); m_sync = true; return; }
   if(name == "UTM_P_BTN_MIN")          { m_collapsed = !m_collapsed; m_autoCollapsed = true; m_sync = true; return; }
   if(name == "UTM_P_BTN_HIDE")         { Show(false); return; }

   if(name == "UTM_P_BTN_BUY")          { m_eng.QuickTrade(POSITION_TYPE_BUY);  m_sync = true; return; }
   if(name == "UTM_P_BTN_SELL")         { m_eng.QuickTrade(POSITION_TYPE_SELL); m_sync = true; return; }
   if(name == "UTM_P_BTN_EXEC")         { m_eng.ToggleExec(); m_sync = true; return; }
   if(name == "UTM_P_BTN_BE")           { m_eng.BreakEvenAll();      m_sync = true; return; }
   if(name == "UTM_P_BTN_CLOSE")        { m_eng.CloseAllPositions(); m_sync = true; return; }
   if(name == "UTM_P_BTN_CANCEL")       { m_eng.CancelPending();     m_sync = true; return; }
   if(name == "UTM_P_BTN_RISKMODE")
     {
      g_set.riskMode++;
      if(g_set.riskMode > 2)
         g_set.riskMode = 0;
      if(g_set.riskMode == UTM_RISK_PERCENT)      g_set.riskValue = 1.0;
      else if(g_set.riskMode == UTM_RISK_MONEY)   g_set.riskValue = 100.0;
      else                                        g_set.riskValue = 0.10;
      m_sync = true;
      return;
     }

   if(name == "UTM_P_BTN_SPLIT")        { g_set.bypassMaxLot = !g_set.bypassMaxLot;   m_sync = true; return; }
   if(name == "UTM_P_BTN_FIXED")        { g_set.fixedSL = !g_set.fixedSL;             m_sync = true; return; }
   if(name == "UTM_P_BTN_LOCKRR")       { g_set.lockRR = !g_set.lockRR;               m_sync = true; return; }
   if(name == "UTM_P_BTN_DROPPEND")     { g_set.removePendingOnSL = !g_set.removePendingOnSL; m_sync = true; return; }
   if(name == "UTM_P_BTN_FAILSAFE")     { g_set.failsafeSL = !g_set.failsafeSL;       m_sync = true; return; }
   if(name == "UTM_P_BTN_SRVTP")         { g_set.serverSplitTP = !g_set.serverSplitTP;   m_sync = true; return; }
   if(name == "UTM_P_BTN_DEFMODE")
     {
      if(g_set.defaultOrderMode == UTM_ORDER_MARKET)      g_set.defaultOrderMode = UTM_ORDER_LIMIT;
      else if(g_set.defaultOrderMode == UTM_ORDER_LIMIT)  g_set.defaultOrderMode = UTM_ORDER_STOP;
      else                                                g_set.defaultOrderMode = UTM_ORDER_MARKET;
      m_sync = true;
      return;
     }
   if(name == "UTM_P_BTN_MEM")          { g_set.memorySave = !g_set.memorySave;       m_sync = true; return; }
   if(name == "UTM_P_BTN_PRIV")         { g_set.privacyMode = !g_set.privacyMode;   m_sync = true; return; }
   if(name == "UTM_P_BTN_QUICK")        { g_set.showQuickTrade = !g_set.showQuickTrade; m_sync = true; return; }
   if(name == "UTM_P_BTN_SND")          { g_set.sounds = !g_set.sounds;               m_sync = true; return; }
   if(name == "UTM_P_BTN_COMMRISK")     { g_set.commissionInRisk = !g_set.commissionInRisk; m_sync = true; return; }
   if(name == "UTM_P_BTN_COMMAUTO")
     {
      g_set.commissionAuto = !g_set.commissionAuto;
      if(g_set.commissionAuto)
         UTM_CommissionScan(m_eng.Symbol(), true);
      else if(g_set.commissionPerLot <= 0.0 && g_commDetected)
         g_set.commissionPerLot = g_commPerLot;   // start manual editing from the detected value
      m_sync = true;
      return;
     }

   if(name == "UTM_P_BTN_UNIT")
     {
      g_set.slUnit++;
      g_set.slUnit = (g_set.slUnit == UTM_SL_PIPS ? UTM_SL_POINTS : UTM_SL_PIPS);
      m_sync = true;
      return;
     }


   if(name == "UTM_P_BTN_SPREAD")
     {
      g_set.spreadMode++;
      if(g_set.spreadMode > 3)
         g_set.spreadMode = 0;
      m_sync = true;
      return;
     }


   if(name == "UTM_P_BTN_SAVE")
     {
      if(UTM_SaveSettings(g_set))
         m_status = "设置已保存";
      else
         m_status = "保存失败";
      m_statusClr = UTM_CLR_TEXT_DIM;
      return;
     }

   if(name == "UTM_P_BTN_LOAD")
     {
      if(UTM_LoadSettings(g_set))
         m_status = "设置已读取";
      else
         m_status = "找不到该配置";
      m_statusClr = UTM_CLR_TEXT_DIM;
      m_sync = true;
      return;
     }
  }

//+------------------------------------------------------------------+
//| edit handling                                                     |
//+------------------------------------------------------------------+
void CUtmPanel::OnEndEdit(const string name)
  {
   if(StringFind(name, UTM_OBJ_PREFIX + "P_E_") != 0)
      return;

   string field = StringSubstr(name, StringLen(UTM_OBJ_PREFIX + "P_E_"));
   string raw   = ObjectGetString(0, name, OBJPROP_TEXT);
   StringTrimLeft(raw);
   StringTrimRight(raw);
   double v = StringToDouble(raw);

   if(field == "RISK")
     {
      if(g_set.riskMode == UTM_RISK_LOT)
         g_set.riskValue = MathMax(0.0, v);
      else
         g_set.riskValue = MathMax(0.0, v);
     }
   else if(field == "MAXLOT")     g_set.maxLot = MathMax(0.0, v);
   else if(field == "EQSTOP")     g_set.equityStop = MathMax(0.0, v);
   else if(field == "ABN")        g_set.abnormalSpread = MathMax(0.0, v);
   else if(field == "SLSIZE")     g_set.slSize = MathMax(0.0, v);
   else if(field == "SLMIN")      g_set.slMin = MathMax(0.0, v);
   else if(field == "SLMAX")      g_set.slMax = MathMax(0.0, v);
   else if(field == "BE")         g_set.beOffsetRR = v;
   else if(field == "COMM" && !g_set.commissionAuto) g_set.commissionPerLot = MathMax(0.0, v);
   else if(field == "FORMULA")    g_set.formula = raw;
   else if(field == "SPREADF")    g_set.spreadFactor = MathMax(0.0, v);
   else if(field == "EMA")
     {
      g_set.emaSpread = MathMin(1.0, MathMax(0.001, v));
     }
   else if(field == "PROFILE")    g_set.profile = raw;
   else if(StringFind(field, "TPRR") == 0)
     {
      int idx = (int)StringToInteger(StringSubstr(field, 4)) - 1;
      if(idx >= 0 && idx < UTM_MAX_TP)
         g_set.tpRR[idx] = MathMax(0.0, v);
     }
   else if(StringFind(field, "TPPCT") == 0)
     {
      int idx = (int)StringToInteger(StringSubstr(field, 5)) - 1;
      if(idx >= 0 && idx < UTM_MAX_TP)
         g_set.tpPct[idx] = MathMin(100.0, MathMax(0.0, v));
     }

   //--- TP plan consistency
   int cnt = 0;
   for(int i = 0; i < UTM_MAX_TP; i++)
     {
      if(g_set.tpPct[i] > 0.0)
        {
         cnt = i + 1;
         if(g_set.tpRR[i] <= 0.0)
            g_set.tpRR[i] = 1.0;
        }
     }
   g_set.tpCount = (cnt < 1 ? 1 : cnt);
   if(g_set.tpCount > UTM_MAX_TP)
      g_set.tpCount = UTM_MAX_TP;

   m_sync = true;
   m_status = "已更新：" + field;
   m_statusClr = UTM_CLR_TEXT_DIM;
  }

#endif // __UTM_PANEL_MQH__
//+------------------------------------------------------------------+