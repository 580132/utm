//+------------------------------------------------------------------+
//|                                                  UTM_Engine.mqh  |
//|   Trade engine: execution, management, chart lines, persistence   |
//+------------------------------------------------------------------+
#ifndef __UTM_ENGINE_MQH__
#define __UTM_ENGINE_MQH__

#include <Trade\Trade.mqh>
#include "UTM_Defines.mqh"
#include "UTM_Utils.mqh"
#include "UTM_Settings.mqh"
#include "UTM_Risk.mqh"

//+------------------------------------------------------------------+
//| Engine                                                            |
//+------------------------------------------------------------------+
class CUtmEngine
  {
private:
   CTrade            m_trade;
   string            m_symbol;
   string            m_chartSymbol;
   int               m_magic;
   int               m_deviation;
   STrade            m_tr[];
   int               m_count;
   long              m_nextId;
   SExec             m_exec;
   double            m_emaSpread;
   bool              m_emaInit;
   datetime          m_lastBar;
   datetime          m_lastSave;
   string            m_stateFile;
   bool              m_equityAlert;
   int               m_panelX;
   int               m_panelY;
   int               m_panelW;
   int               m_panelH;
   bool              m_panelOnLeft;
   int               m_lastMouseX;
   int               m_lastMouseY;
   uint              m_mouseIgnoreUntil;
   string            m_lastError;
   string            m_lastInfo;

public:
                     CUtmEngine();
   bool              Init(const string tradeSymbol, const string chartSymbol,
                          const int magic, const int deviation);
   void              Deinit();

   //--- lifecycle
   void              OnTick();
   void              OnTimer();
   void              RefreshAll();          // redraw lines/labels now (period / scale change)
   void              OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);

   //--- settings link
   void              SetPanelRect(const int x, const int y, const int w, const int h, const bool onLeft)
     {
      m_panelX = x; m_panelY = y; m_panelW = w; m_panelH = h; m_panelOnLeft = onLeft;
     }
   int               ContentLeftX() const
     {
      if(m_panelOnLeft && m_panelW > 0)
         return (m_panelX + m_panelW + UTM_UI(14));
      return UTM_UI(8);
     }

   //--- info
   string            Symbol()            const { return m_symbol; }
   string            ChartSymbol()       const { return m_chartSymbol; }
   int               Magic()             const { return m_magic; }
   int               Count()             const { return m_count; }
   bool              GetTradeInfo(const int index, STrade &t) const
     {
      if(index < 0 || index >= m_count)
         return false;
      t = m_tr[index];
      return true;
     }
   void              OnObjectClick(const string name);
   double            EmaSpread()         const { return m_emaSpread; }
   double            RawSpread()         const { return UTM_RawSpread(m_symbol); }
   string            LastError()         const { return m_lastError; }
   string            LastInfo()          const { return m_lastInfo; }
   bool              ExecActive()        const { return m_exec.active; }
   bool              ExecFollow()        const { return m_exec.follow; }
   int               ExecSide()          const { return m_exec.side; }
   int               ExecMode()          const { return m_exec.mode; }
   double            ExecEntry()         const { return m_exec.entry; }
   double            ExecSL()            const { return m_exec.sl; }
   double            ExecLot();
   double            ExecRisk();
   double            ExecSLPips();

   //--- actions
   void              ToggleExec();
   void              ActivateExec(const int side);
   void              DeactivateExec();
   void              SwitchSide(const int side);
   void              CycleOrderMode();
   void              ResetExecToMarket();
   bool              ExecuteNow();
   bool              QuickTrade(const int side);
   void              BreakEvenAll();
   void              CloseAllPositions();
   void              CancelPending();
   void              HalveRisk();
   void              SetExecEntry(const double price);
   void              ExecSetSL(const double price);
   void              ExecSetTP(const int idx, const double price);
   void              ExecSetMode(const int mode);
   void              ExecSyncMarket();
   bool              ExecSyncSide();
   bool              ExecTPs(double &out[]);
   void              ExecMouseMove(const int x, const int y);
   void              ExecClickAt(const double price);
   void              ExecConfirm();
   void              DrawHud();
   void              CloseTradeById(const long id, const double pct);
   void              ModifyTradeSL(const long id, const double sl);
   void              ModifyTradeTP(const long id, const int idx, const double price);
   void              RepricePendingTrade(const int index);
   void              CancelByPriceArea(const double price);

   //--- persistence
   void              SaveState(const bool force = false);
   void              LoadState();

private:
   //--- helpers
   void              BlankTrade(STrade &t);
   int               FindById(const long id);
   int               FindByTicket(const ulong ticket);
   void              RemoveAt(const int index);
   int               AddTrade(STrade &t);
   void              SyncTrades();
   void              Reconcile();
   void              ManageTrades();
   void              ManageOne(const int index);
   void              CheckVirtualEntry(const int index);
   bool              CheckVirtualSL(const STrade &t, const double bid, const double ask);
   void              CheckTakeProfits(const int index);
   void              ApplyFormula(const int index);
   bool              ClosePositionAt(const int index, const string reason, const double volume = 0.0);
   bool              PartialClose(const int index, const double volume, const string reason);
   void              SetTradeSL(const int index, const double price, const bool notify = false);
   void              SetTradeTP(const int index, const int tpIdx, const double price);
   bool              SendMarket(const int side, const double volume, const double sl, const double tp,
                                const string comment, ulong &ticket);
   bool              SendPending(const int side, const int omode, const double price, const double volume,
                                 const double sl, const double tp, const string comment, ulong &ticket);
   bool              OpenNewTrade(const int side, const double entry, const double sl,
                                  const double lot, const bool pending, const int omode);
   bool              BuildServerSlices(const STrade &t, double &vols[], int &levels[]);
   int               DeriveOrderMode(const int side, const double price);
   bool              ValidatePendingPrice(const int side, int &omode, double &price, const double sl, string &err);
   double            BaseEntry(const STrade &t);
   void              ComputeTPs(STrade &t);
   void              RegisterSplitTickets(STrade &t, ulong &tickets[], const int n);
   int               CollectTickets(const STrade &t, ulong &tickets[]);
   void              DeleteTradeOrders(const STrade &t);
   double            TradeVolume(const STrade &t);
   double            TradeProfit(const STrade &t);
   double            CurrentPrice(const STrade &t, const bool forSL);
   void              PushError(const string msg);
   void              Notify(const string kind);
   void              UpdateSpread();
   void              SaveSoon() { SaveState(false); }

   //--- visuals
   void              DrawAll();
   void              DrawTrade(const STrade &t);
   void              DrawExec();
   void              DeleteExecObjects();
   void              CleanupOrphans();
   void              CreateLine(const string name, const double price, const color clr,
                                const int style, const int width, const bool selectable, const string text);
   void              CreateLabel(const string name, const int x, const int y, const string text,
                                 const color clr, const int size = 8, const bool bold = false);
   void              CreateButton(const string name, const int x, const int y, const int w, const int h,
                                  const string text, const color bg, const color clr, const int size = 8);
   void              PriceToY(const double price, int &y);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CUtmEngine::CUtmEngine()
  {
   m_symbol      = "";
   m_chartSymbol = "";
   m_magic       = 0;
   m_deviation   = 20;
   m_count       = 0;
   m_nextId      = 1;
   m_emaSpread   = 0.0;
   m_emaInit     = false;
   m_lastBar     = 0;
   m_lastSave    = 0;
   m_stateFile   = "";
   m_equityAlert = false;
   m_lastError   = "";
   m_panelX      = 0;
   m_panelY      = 0;
   m_panelW      = 0;
   m_panelH      = 0;
   m_panelOnLeft = true;
   m_lastMouseX  = -1;
   m_lastMouseY  = -1;
   m_mouseIgnoreUntil = 0;
   m_lastInfo    = "";

   m_exec.active = false;
   m_exec.side   = POSITION_TYPE_BUY;
   m_exec.mode   = UTM_ORDER_MARKET;
   m_exec.stage  = 0;
   m_exec.follow = false;
   m_exec.entry  = 0.0;
   m_exec.sl     = 0.0;
   m_exec.lot    = 0.0;
   m_exec.tpCount = 0;
   for(int i = 0; i < UTM_MAX_TP; i++)
      m_exec.tp[i] = 0.0;
  }

//+------------------------------------------------------------------+
//| Init                                                              |
//+------------------------------------------------------------------+
bool CUtmEngine::Init(const string tradeSymbol, const string chartSymbol, const int magic, const int deviation)
  {
   m_symbol      = tradeSymbol;
   m_chartSymbol = chartSymbol;
   m_magic       = magic;
   m_deviation   = deviation;

   if(!UTM_IsTradableSymbol(m_symbol))
     {
      PushError("品种不可交易：" + m_symbol);
      return false;
     }

   m_trade.SetExpertMagicNumber(m_magic);
   m_trade.SetDeviationInPoints(m_deviation);
   m_trade.SetTypeFillingBySymbol(m_symbol);
   m_trade.SetAsyncMode(false);

   string s = m_symbol;
   StringReplace(s, ".", "_");
   StringReplace(s, "#", "_");
   StringReplace(s, "-", "_");
   StringReplace(s, " ", "");
   m_stateFile = UTM_SETTINGS_FOLDER + "\\state_" + IntegerToString(m_magic) + "_" + s + ".csv";

   UpdateSpread();
   m_emaSpread = MathMax(m_emaSpread, UTM_Point(m_symbol));

   //--- commission rate from real deals (used when the panel is in auto mode)
   UTM_CommissionScan(m_symbol, true);

   LoadState();
   Reconcile();

   m_lastBar = iTime(m_symbol, PERIOD_CURRENT, 0);
   m_lastSave = TimeCurrent();
   return true;
  }

//+------------------------------------------------------------------+
//| Deinit                                                            |
//+------------------------------------------------------------------+
void CUtmEngine::Deinit()
  {
   SaveState(true);
  }

//+------------------------------------------------------------------+
//| Errors / notifications                                            |
//+------------------------------------------------------------------+
void CUtmEngine::PushError(const string msg)
  {
   m_lastError = msg;
   Print("[UTM] ", msg);
  }

void CUtmEngine::Notify(const string kind)
  {
   if(!g_set.sounds)
      return;
   if(kind == "entry")      PlaySound("ok.wav");
   else if(kind == "sl")    PlaySound("timeout.wav");
   else if(kind == "tp")    PlaySound("expert.wav");
   else                     PlaySound("alert.wav");
  }

//+------------------------------------------------------------------+
//| Spread EMA                                                        |
//+------------------------------------------------------------------+
void CUtmEngine::UpdateSpread()
  {
   double raw = UTM_RawSpread(m_symbol);
   if(raw <= 0.0)
      return;

   double alpha = g_set.emaSpread;
   if(alpha < 0.0001) alpha = 0.0001;
   if(alpha > 1.0)    alpha = 1.0;

   if(!m_emaInit)
     {
      m_emaSpread = raw;
      m_emaInit   = true;
     }
   else
      m_emaSpread = alpha * raw + (1.0 - alpha) * m_emaSpread;

   if(m_emaSpread < UTM_Point(m_symbol))
      m_emaSpread = UTM_Point(m_symbol);
  }

//+------------------------------------------------------------------+
//| Main tick                                                         |
//+------------------------------------------------------------------+
void CUtmEngine::OnTick()
  {
   UpdateSpread();
   if(g_set.commissionAuto)
      UTM_CommissionScan(m_symbol);

   ExecSyncMarket();



   //--- equity stop
   if(!Risk_EquityOK(g_set))
     {
      if(!m_equityAlert)
        {
         m_equityAlert = true;
         PushError("已触发净值止损，全部平仓");
         CloseAllPositions();
         CancelPending();
         Notify("missed");
        }
      return;
     }
   m_equityAlert = false;

   SyncTrades();
   ManageTrades();
   SaveState(false);
  }

//+------------------------------------------------------------------+
//| Timer                                                             |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void CUtmEngine::OnTimer()
  {
   if(!UTM_VisualMode())
      return;
   UpdateSpread();
   if(g_set.commissionAuto)
      UTM_CommissionScan(m_symbol);
   DrawAll();
   SaveState(false);
  }

//+------------------------------------------------------------------+
//| 图表周期 / 尺寸变化后立即重绘（标签跟住线条）                      |
//+------------------------------------------------------------------+
void CUtmEngine::RefreshAll()
  {
   if(!UTM_VisualMode())
      return;
   //--- 周期切换时终端会补发一次鼠标移动事件，忽略它，避免止损线跳到新周期的价格
   m_mouseIgnoreUntil = GetTickCount() + 600;
   m_lastMouseX = -1;
   m_lastMouseY = -1;
   DrawAll();
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| Trade array helpers                                               |
//+------------------------------------------------------------------+
void CUtmEngine::BlankTrade(STrade &t)
  {
   t.id = 0;
   t.ticket = 0;
   t.symbol = m_symbol;
   t.type = POSITION_TYPE_BUY;
   t.pending = false;
   t.lot = 0.0;
   t.entry = 0.0;
   t.posEntry = 0.0;
   t.sl = 0.0;
   t.riskDist = 0.0;
   t.riskMoney = 0.0;
   for(int i = 0; i < UTM_MAX_TP; i++)
     {
      t.tp[i] = 0.0;
      t.tpPct[i] = 0.0;
      t.tpRR[i] = 0.0;
     }
   t.tpCount = 0;
   t.tpDone = 0;
   t.beDone = false;
   t.trailingTP = false;
   t.serverTP   = false;
   t.virtualSL = false;
   t.virtualEntry = false;
   t.orderMode = UTM_ORDER_MARKET;
   t.opened = 0;
   for(int i = 0; i < UTM_MAX_SPLIT; i++)
      t.splits[i] = 0;
   t.splitCount = 0;
   t.magic = m_magic;
   t.formulaDone = 0;
   t.trailStep = 0;
   t.adopted = false;
   t.comment = "";
  }

int CUtmEngine::FindById(const long id)
  {
   for(int i = 0; i < m_count; i++)
      if(m_tr[i].id == id)
         return i;
   return -1;
  }

int CUtmEngine::FindByTicket(const ulong ticket)
  {
   for(int i = 0; i < m_count; i++)
     {
      if(m_tr[i].ticket == ticket)
         return i;
      for(int k = 0; k < m_tr[i].splitCount; k++)
         if(m_tr[i].splits[k] == ticket)
            return i;
     }
   return -1;
  }

void CUtmEngine::RemoveAt(const int index)
  {
   if(index < 0 || index >= m_count)
      return;
   for(int i = index; i < m_count - 1; i++)
      m_tr[i] = m_tr[i + 1];
   m_count--;
   if(m_count > 0)
      ArrayResize(m_tr, m_count);
   else
      ArrayResize(m_tr, 0);
   SaveSoon();
  }

int CUtmEngine::AddTrade(STrade &t)
  {
   if(m_count >= UTM_MAX_TRADES)
     {
      PushError("已达到最大管理笔数");
      return -1;
     }
   ArrayResize(m_tr, m_count + 1);
   m_tr[m_count] = t;
   m_count++;
   return m_count - 1;
  }

//+------------------------------------------------------------------+
//| Restore / reconcile                                               |
//+------------------------------------------------------------------+
void CUtmEngine::Reconcile()
  {
   //--- remove stored trades that no longer exist
   for(int i = m_count - 1; i >= 0; i--)
     {
      bool alive = false;
      if(m_tr[i].pending)
        {
         if(m_tr[i].virtualEntry)
            alive = true;
         else
            alive = OrderSelect(m_tr[i].ticket) || PositionSelectByTicket(m_tr[i].ticket);
        }
      else
        {
         alive = PositionSelectByTicket(m_tr[i].ticket);
         //--- the main ticket may have been closed by a server TP: keep the group alive
         if(!alive)
           {
            for(int k = 0; k < m_tr[i].splitCount; k++)
              {
               if(PositionSelectByTicket(m_tr[i].splits[k]))
                 {
                  alive = true;
                  m_tr[i].ticket = m_tr[i].splits[k];
                  m_tr[i].splits[k] = 0;
                  break;
                 }
              }
           }
        }

      if(!alive)
        {
         Print("[UTM] 清理已失效的交易 #", m_tr[i].id);
         RemoveAt(i);
        }
      else
        {
         if(m_tr[i].pending && !m_tr[i].virtualEntry && PositionSelectByTicket(m_tr[i].ticket))
           {
            m_tr[i].pending = false;
            m_tr[i].posEntry = PositionGetDouble(POSITION_PRICE_OPEN);
           }
         if(!m_tr[i].pending)
           {
            m_tr[i].posEntry = PositionGetDouble(POSITION_PRICE_OPEN);
            m_tr[i].symbol = PositionGetString(POSITION_SYMBOL);
           }
        }
     }

   //--- adopt positions opened by this manager but missing in the state file
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong tk = PositionGetTicket(i);
      if(tk == 0)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != m_magic)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != m_symbol)
         continue;
      if(FindByTicket(tk) >= 0)
         continue;

      STrade t;
      BlankTrade(t);
      t.id = m_nextId++;
      t.ticket = tk;
      t.type = (int)PositionGetInteger(POSITION_TYPE);
      t.pending = false;
      t.lot = PositionGetDouble(POSITION_VOLUME);
      t.posEntry = PositionGetDouble(POSITION_PRICE_OPEN);
      t.entry = t.posEntry;
      t.sl = PositionGetDouble(POSITION_SL);
      t.opened = (datetime)PositionGetInteger(POSITION_TIME);
      t.riskDist = (t.sl > 0.0 ? MathAbs(t.entry - t.sl) : 0.0);
      t.adopted = true;
      t.comment = "adopted";
      AddTrade(t);
      Print("[UTM] 接管已有持仓 #", tk);
     }

   //--- adopt pending orders
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong tk = OrderGetTicket(i);
      if(tk == 0)
         continue;
      if(OrderGetInteger(ORDER_MAGIC) != m_magic)
         continue;
      if(OrderGetString(ORDER_SYMBOL) != m_symbol)
         continue;
      if(FindByTicket(tk) >= 0)
         continue;

      STrade t;
      BlankTrade(t);
      t.id = m_nextId++;
      t.ticket = tk;
      long ot = OrderGetInteger(ORDER_TYPE);
      t.type = (ot == ORDER_TYPE_BUY_LIMIT || ot == ORDER_TYPE_BUY_STOP ? POSITION_TYPE_BUY : POSITION_TYPE_SELL);
      t.pending = true;
      t.lot = OrderGetDouble(ORDER_VOLUME_INITIAL);
      t.entry = OrderGetDouble(ORDER_PRICE_OPEN);
      t.sl = OrderGetDouble(ORDER_SL);
      t.opened = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
      t.riskDist = (t.sl > 0.0 ? MathAbs(t.entry - t.sl) : 0.0);
      t.orderMode = (ot == ORDER_TYPE_BUY_LIMIT || ot == ORDER_TYPE_SELL_LIMIT ? UTM_ORDER_LIMIT : UTM_ORDER_STOP);
      t.adopted = true;
      t.comment = "adopted";
      AddTrade(t);
     }

   SaveState(true);
  }

//+------------------------------------------------------------------+
//| Sync with the terminal                                            |
//+------------------------------------------------------------------+
void CUtmEngine::SyncTrades()
  {
   for(int i = m_count - 1; i >= 0; i--)
     {
      if(m_tr[i].pending)
        {
         if(m_tr[i].virtualEntry)
            continue;
         if(OrderSelect(m_tr[i].ticket))
            continue;
         if(PositionSelectByTicket(m_tr[i].ticket))
           {
            //--- pending order was filled
            m_tr[i].pending = false;
            m_tr[i].posEntry = PositionGetDouble(POSITION_PRICE_OPEN);
            m_tr[i].opened = (datetime)PositionGetInteger(POSITION_TIME);
            Notify("entry");
            SaveSoon();
            continue;
           }
         Print("[UTM] 挂单已消失 #", m_tr[i].id);
         RemoveAt(i);
         continue;
        }

      //--- server-side TPs: keep the "next TP" display in step with the price
      if(m_tr[i].serverTP)
        {
         double px = (m_tr[i].type == POSITION_TYPE_BUY ? UTM_Bid(m_symbol) : UTM_Ask(m_symbol));
         int done = 0;
         for(int k = 0; k < m_tr[i].tpCount && k < UTM_MAX_TP; k++)
           {
            double p = m_tr[i].tp[k];
            if(p <= 0.0)
               continue;
            if(m_tr[i].type == POSITION_TYPE_BUY ? px >= p : px <= p)
               done++;
           }
         m_tr[i].tpDone = done;
        }

      //--- open position
      if(PositionSelectByTicket(m_tr[i].ticket))
         continue;

      //--- check the split group
      bool alive = false;
      for(int k = 0; k < m_tr[i].splitCount; k++)
        {
         ulong stk = m_tr[i].splits[k];
         if(stk > 0 && (PositionSelectByTicket(stk) || OrderSelect(stk)))
           {
            alive = true;
            m_tr[i].ticket = stk;
            m_tr[i].splits[k] = 0;
            break;
           }
        }
      if(alive)
         continue;

      Print("[UTM] 交易已平仓 #", m_tr[i].id);
      RemoveAt(i);
     }
  }

//+------------------------------------------------------------------+
//| Volume / profit helpers                                           |
//+------------------------------------------------------------------+
int CUtmEngine::CollectTickets(const STrade &t, ulong &tickets[])
  {
   ArrayResize(tickets, 0);
   if(t.ticket > 0)
     {
      ArrayResize(tickets, 1);
      tickets[0] = t.ticket;
     }
   for(int i = 0; i < t.splitCount; i++)
     {
      if(t.splits[i] == 0 || t.splits[i] == t.ticket)
         continue;
      int n = ArraySize(tickets);
      ArrayResize(tickets, n + 1);
      tickets[n] = t.splits[i];
     }
   return ArraySize(tickets);
  }

//--- delete every pending order of a trade (the main ticket and the splits)
void CUtmEngine::DeleteTradeOrders(const STrade &t)
  {
   if(t.ticket > 0 && OrderSelect(t.ticket))
      m_trade.OrderDelete(t.ticket);
   for(int i = 0; i < t.splitCount; i++)
     {
      if(t.splits[i] > 0 && OrderSelect(t.splits[i]))
         m_trade.OrderDelete(t.splits[i]);
     }
  }

double CUtmEngine::TradeVolume(const STrade &t)
  {
   double v = 0.0;
   ulong tickets[];
   int n = CollectTickets(t, tickets);
   for(int i = 0; i < n; i++)
     {
      if(PositionSelectByTicket(tickets[i]))
         v += PositionGetDouble(POSITION_VOLUME);
     }
   return v;
  }

double CUtmEngine::TradeProfit(const STrade &t)
  {
   double p = 0.0;
   ulong tickets[];
   int n = CollectTickets(t, tickets);
   for(int i = 0; i < n; i++)
     {
      if(PositionSelectByTicket(tickets[i]))
         p += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
     }
   return p;
  }

double CUtmEngine::CurrentPrice(const STrade &t, const bool forSL)
  {
   if(t.type == POSITION_TYPE_BUY)
      return UTM_Bid(m_symbol);
   if(forSL && (g_set.spreadMode == UTM_SPREAD_IGNORE || g_set.spreadMode == UTM_SPREAD_INVISIBLE))
      return UTM_Bid(m_symbol);
   return UTM_Ask(m_symbol);
  }

double CUtmEngine::BaseEntry(const STrade &t)
  {
   if(g_set.tpOrigEntry || t.posEntry <= 0.0)
      return t.entry;
   return t.posEntry;
  }

//+------------------------------------------------------------------+
//| Trade management                                                  |
//+------------------------------------------------------------------+
void CUtmEngine::ManageTrades()
  {
   double bid = UTM_Bid(m_symbol);
   double ask = UTM_Ask(m_symbol);
   if(bid <= 0.0 || ask <= 0.0)
      return;

   for(int i = 0; i < m_count; i++)
     {
      if(m_tr[i].pending)
        {
         if(m_tr[i].virtualEntry)
            CheckVirtualEntry(i);
         else if(m_tr[i].virtualSL && m_tr[i].sl > 0.0)
           {
            //--- stop was crossed before the pending order was filled
            if((m_tr[i].type == POSITION_TYPE_BUY && bid <= m_tr[i].sl) ||
               (m_tr[i].type == POSITION_TYPE_SELL && bid >= m_tr[i].sl))
              {
               m_trade.OrderDelete(m_tr[i].ticket);
               Notify("missed");
               RemoveAt(i);
               i--;
              }
           }
         continue;
        }

      //--- virtual stop loss
      if(m_tr[i].virtualSL && m_tr[i].sl > 0.0 && CheckVirtualSL(m_tr[i], bid, ask))
        {
         ClosePositionAt(i, "止损");
         Notify("sl");
         i--;
         continue;
        }

      CheckTakeProfits(i);
      if(i < 0 || i >= m_count)
         continue;

      ApplyFormula(i);


     }
  }

//+------------------------------------------------------------------+
//| Manage one (kept for clarity / future extensions)                 |
//+------------------------------------------------------------------+
void CUtmEngine::ManageOne(const int index)
  {
   if(index < 0 || index >= m_count)
      return;
  }

//+------------------------------------------------------------------+
//| Virtual pending trigger                                           |
//+------------------------------------------------------------------+
void CUtmEngine::CheckVirtualEntry(const int index)
  {
   if(index < 0 || index >= m_count)
      return;

   double bid    = UTM_Bid(m_symbol);
   double ask    = UTM_Ask(m_symbol);
   double entry  = m_tr[index].entry;
   double sl     = m_tr[index].sl;
   bool   isBuy  = (m_tr[index].type == POSITION_TYPE_BUY);
   bool   ignore = (g_set.spreadMode == UTM_SPREAD_IGNORE || g_set.spreadMode == UTM_SPREAD_INVISIBLE);

   //--- in ignore-spread mode the trigger is the candle (bid) price
   double trigger = (ignore ? bid : ask);

   bool fire = false;
   if(isBuy)
      fire = (m_tr[index].orderMode == UTM_ORDER_STOP ? trigger >= entry : trigger <= entry);
   else
      fire = (m_tr[index].orderMode == UTM_ORDER_STOP ? trigger <= entry : trigger >= entry);

   if(sl > 0.0)
     {
      bool slCrossed = (isBuy ? bid <= sl : bid >= sl);
      if(slCrossed && !fire)
        {
         if(g_set.removePendingOnSL)
           {
            Notify("missed");
            RemoveAt(index);
           }
         return;
        }
     }
   if(!fire)
      return;

   //--- open at market (splitting the volume when required)
   double lot  = m_tr[index].lot;
   double bmax = UTM_VolumeMax(m_symbol);
   int    parts = 1;
   if(g_set.bypassMaxLot && lot > bmax)
     {
      parts = (int)MathCeil(lot / bmax);
      if(parts > UTM_MAX_SPLIT)
         parts = UTM_MAX_SPLIT;
     }

   double brokerSL = (m_tr[index].virtualSL ? 0.0 : sl);
   if(m_tr[index].virtualSL && g_set.failsafeSL && m_tr[index].riskDist > 0.0)
      brokerSL = m_tr[index].entry + (isBuy ? -2.0 : 2.0) * m_tr[index].riskDist;

   double brokerTP = 0.0;
   if(m_tr[index].tpCount == 1 && m_tr[index].tpPct[0] >= 99.9 && g_set.spreadMode != UTM_SPREAD_INVISIBLE)
      brokerTP = m_tr[index].tp[0];

   ulong tickets[];
   ArrayResize(tickets, 0);
   double remaining = lot;

   for(int k = 0; k < parts; k++)
     {
      double vol = (k == parts - 1 ? remaining : UTM_NormLot(m_symbol, lot / parts));
      if(vol < UTM_VolumeMin(m_symbol))
         break;

      ulong tk = 0;
      if(!SendMarket(m_tr[index].type, vol, brokerSL, brokerTP,
                     "UTM-" + IntegerToString(m_tr[index].id), tk))
         return;

      int n = ArraySize(tickets);
      ArrayResize(tickets, n + 1);
      tickets[n] = tk;
      remaining -= vol;
     }

   if(ArraySize(tickets) == 0)
      return;

   RegisterSplitTickets(m_tr[index], tickets, ArraySize(tickets));
   m_tr[index].pending      = false;
   m_tr[index].virtualEntry = false;
   m_tr[index].opened       = TimeCurrent();
   if(PositionSelectByTicket(m_tr[index].ticket))
      m_tr[index].posEntry = PositionGetDouble(POSITION_PRICE_OPEN);

   Notify("entry");
   SaveState(true);
  }
//+------------------------------------------------------------------+
bool CUtmEngine::CheckVirtualSL(const STrade &t, const double bid, const double ask)
  {
   if(t.type == POSITION_TYPE_BUY)
      return (bid <= t.sl);
   if(g_set.spreadMode == UTM_SPREAD_IGNORE || g_set.spreadMode == UTM_SPREAD_INVISIBLE)
      return (bid >= t.sl);
   return (ask >= t.sl);
  }

//+------------------------------------------------------------------+
//| Take profit engine                                                |
//+------------------------------------------------------------------+
void CUtmEngine::CheckTakeProfits(const int index)
  {
   if(index < 0 || index >= m_count)
      return;
   if(m_tr[index].serverTP)
      return;   // server holds one TP per slice, nothing to close here

   double bid = UTM_Bid(m_symbol);
   double ask = UTM_Ask(m_symbol);

   while(m_tr[index].tpDone < m_tr[index].tpCount)
     {
      int level = m_tr[index].tpDone;
      double price = m_tr[index].tp[level];
      if(price <= 0.0)
        {
         m_tr[index].tpDone++;
         continue;
        }

      bool hit = (m_tr[index].type == POSITION_TYPE_BUY ? bid >= price : ask <= price);
      if(!hit)
         break;

      double pct = m_tr[index].tpPct[level];
      if(pct <= 0.0)
        {
         m_tr[index].tpDone++;
         continue;
        }

      double volume = TradeVolume(m_tr[index]);
      if(volume <= 0.0)
         break;

      double closeVol = UTM_NormLot(m_symbol, m_tr[index].lot * pct / 100.0);
      if(closeVol > volume)
         closeVol = volume;

      m_tr[index].tpDone++;
      if(pct >= 99.9 || volume - closeVol < UTM_VolumeMin(m_symbol))
        {
         ClosePositionAt(index, "止盈");
         Notify("tp");
         return;
        }

      PartialClose(index, closeVol, "止盈");
      Notify("tp");


      SaveSoon();
     }
  }

//+------------------------------------------------------------------+
//| Formula based management                                          |
//+------------------------------------------------------------------+
void CUtmEngine::ApplyFormula(const int index)
  {
   if(index < 0 || index >= m_count)
      return;
   if(g_set.formula == "")
      return;
   if(m_tr[index].riskDist <= 0.0)
      return;

   double dir = (m_tr[index].type == POSITION_TYPE_BUY ? 1.0 : -1.0);
   double price = (m_tr[index].type == POSITION_TYPE_BUY ? UTM_Bid(m_symbol) : UTM_Ask(m_symbol));
   double basePrice = ((g_set.formulaOrigEntry || m_tr[index].posEntry <= 0.0)
                       ? m_tr[index].entry : m_tr[index].posEntry);
   double rr = dir * (price - basePrice) / m_tr[index].riskDist;

   string src = g_set.formula;
   StringReplace(src, ";", "\n");
   StringReplace(src, "\r", "");

   string lines[];
   int n = StringSplit(src, '\n', lines);
   if(n <= 0)
      return;

   for(int i = 0; i < n && i < 16; i++)
     {
      string ln = lines[i];
      StringTrimLeft(ln);
      StringTrimRight(ln);
      if(ln == "" || StringGetCharacter(ln, 0) == '#')
         continue;

      int colon = StringFind(ln, ":");
      if(colon <= 0)
         continue;

      double trigger = StringToDouble(StringSubstr(ln, 0, colon));
      string action = StringSubstr(ln, colon + 1);
      StringTrimLeft(action);
      StringTrimRight(action);
      StringToUpper(action);

      if(rr < trigger)
         continue;

      uint bit = (uint)(1 << i);

      if(StringFind(action, "BE") == 0)
        {
         if((m_tr[index].formulaDone & bit) != 0)
            continue;
         m_tr[index].formulaDone |= bit;
         double be = m_tr[index].entry + dir * g_set.beOffsetRR * m_tr[index].riskDist;
         SetTradeSL(index, be, true);
         m_tr[index].beDone = true;
        }
      else if(StringFind(action, "TS") == 0)
        {
         //--- trailing stop: "TS 1.0" = keep 1R distance
         double distRR = 1.0;
         string rest = StringSubstr(action, 2);
         StringTrimLeft(rest);
         if(rest != "")
            distRR = StringToDouble(rest);
         if(distRR <= 0.0)
            distRR = 1.0;

         double target = price - dir * distRR * m_tr[index].riskDist;
         double cur = m_tr[index].sl;
         bool better = (m_tr[index].type == POSITION_TYPE_BUY ? (cur <= 0.0 || target > cur)
                                                              : (cur <= 0.0 || target < cur));
         if(better)
           {
            SetTradeSL(index, target, false);
            m_tr[index].formulaDone |= bit;
           }
        }
      else if(StringFind(action, "CLOSE") == 0)
        {
         if((m_tr[index].formulaDone & bit) != 0)
            continue;
         m_tr[index].formulaDone |= bit;
         string rest = StringSubstr(action, 5);
         StringTrimLeft(rest);
         double pct = (rest == "" ? 100.0 : StringToDouble(rest));
         if(pct >= 99.9)
            ClosePositionAt(index, "公式");
         else
            PartialClose(index, UTM_NormLot(m_symbol, m_tr[index].lot * pct / 100.0), "公式");
         return;
        }
     }
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Close / partial close                                             |
//+------------------------------------------------------------------+
bool CUtmEngine::ClosePositionAt(const int index, const string reason, const double volume)
  {
   if(index < 0 || index >= m_count)
      return false;

   //--- pending orders are cancelled, not closed
   if(m_tr[index].pending)
     {
      if(!m_tr[index].virtualEntry)
         DeleteTradeOrders(m_tr[index]);
      Print("[UTM] 已撤销挂单 #", m_tr[index].id);
      RemoveAt(index);
      SaveState(true);
      return true;
     }

   bool partial = (volume > 0.0);
   bool allGone = true;

   if(!partial)
     {
      DeleteTradeOrders(m_tr[index]);   // cancel any slice still pending
      ulong tickets[];
      int n = CollectTickets(m_tr[index], tickets);
      for(int i = 0; i < n; i++)
        {
         if(PositionSelectByTicket(tickets[i]))
            m_trade.PositionClose(tickets[i]);
        }
     }
   else
     {
      allGone = PartialClose(index, volume, reason);
      return !allGone;
     }

   Print("[UTM] 已平仓 #", m_tr[index].id, " (", reason, ")");
   RemoveAt(index);
   SaveState(true);
   return true;
  }

//+------------------------------------------------------------------+
//| Partial close across the split group                              |
//+------------------------------------------------------------------+
bool CUtmEngine::PartialClose(const int index, const double volume, const string reason)
  {
   if(index < 0 || index >= m_count || volume <= 0.0)
      return false;

   double left = volume;
   ulong tickets[];
   int n = CollectTickets(m_tr[index], tickets);

   for(int i = 0; i < n && left >= UTM_VolumeMin(m_symbol) * 0.5; i++)
     {
      if(!PositionSelectByTicket(tickets[i]))
         continue;
      double vol = PositionGetDouble(POSITION_VOLUME);
      double closeVol = MathMin(vol, left);
      closeVol = UTM_NormLot(m_symbol, closeVol);
      if(closeVol < UTM_VolumeMin(m_symbol))
         continue;
      if(vol - closeVol > 0.0 && vol - closeVol < UTM_VolumeMin(m_symbol))
         closeVol = vol;   // avoid an unclosable remainder
      if(m_trade.PositionClosePartial(tickets[i], closeVol))
         left -= closeVol;
     }

   Print("[UTM] 部分平仓 #", m_tr[index].id, " ", DoubleToString(volume, 2), " (", reason, ")");
   SaveSoon();
   return false;
  }

//+------------------------------------------------------------------+
//| SL / TP modification                                              |
//+------------------------------------------------------------------+
void CUtmEngine::SetTradeSL(const int index, const double price, const bool notify)
  {
   if(index < 0 || index >= m_count)
      return;

   double p = UTM_NormPrice(m_symbol, price);
   m_tr[index].sl = p;
   m_tr[index].riskMoney = Risk_TotalAtRisk(m_symbol, TradeVolume(m_tr[index]),
                                            MathAbs(m_tr[index].entry - p), g_set);
   if(m_tr[index].riskMoney <= 0.0)
      m_tr[index].riskMoney = Risk_TotalAtRisk(m_symbol, m_tr[index].lot,
                                               MathAbs(m_tr[index].entry - p), g_set);

   if(!m_tr[index].virtualSL)
     {
      ulong tickets[];
      int n = CollectTickets(m_tr[index], tickets);
      for(int i = 0; i < n; i++)
        {
         if(!PositionSelectByTicket(tickets[i]))
            continue;
         double tp = PositionGetDouble(POSITION_TP);
         m_trade.PositionModify(tickets[i], p, tp);
        }
     }
   if(notify)
      Notify("entry");
   SaveSoon();
  }

void CUtmEngine::SetTradeTP(const int index, const int tpIdx, const double price)
  {
   if(index < 0 || index >= m_count)
      return;
   if(tpIdx < 0 || tpIdx >= UTM_MAX_TP)
      return;
   m_tr[index].tp[tpIdx] = UTM_NormPrice(m_symbol, price);
   SaveSoon();
  }

//+------------------------------------------------------------------+
//| Compute TP levels from RR                                        |
//+------------------------------------------------------------------+
void CUtmEngine::ComputeTPs(STrade &t)
  {
   double base = BaseEntry(t);
   double dir  = (t.type == POSITION_TYPE_BUY ? 1.0 : -1.0);
   for(int i = 0; i < t.tpCount; i++)
     {
      if(t.riskDist <= 0.0)
        {
         t.tp[i] = 0.0;
         continue;
        }
      t.tp[i] = UTM_NormPrice(m_symbol, base + dir * t.riskDist * t.tpRR[i]);
     }
  }

//+------------------------------------------------------------------+
//| Order sending                                                     |
//+------------------------------------------------------------------+
bool CUtmEngine::SendMarket(const int side, const double volume, const double sl, const double tp,
                            const string comment, ulong &ticket)
  {
   ticket = 0;
   bool ok = false;

   //--- 市价单用 price=0，由终端按最新价成交（指定旧价在慢网络 / macOS 上易被拒）
   ENUM_ORDER_TYPE_FILLING modes[3] = {ORDER_FILLING_FOK, ORDER_FILLING_IOC, ORDER_FILLING_RETURN};
   uint rc = 0;
   for(int i = 0; i < 3 && !ok; i++)
     {
      m_trade.SetTypeFilling(modes[i]);
      if(side == POSITION_TYPE_BUY)
         ok = m_trade.Buy(volume, m_symbol, 0.0, sl, tp, comment);
      else
         ok = m_trade.Sell(volume, m_symbol, 0.0, sl, tp, comment);
      if(ok)
         break;
      rc = m_trade.ResultRetcode();
      //--- 10030 = 不支持的成交方式；其余错误换成交方式也没用
      if(rc != 10030)
         break;
     }

   if(!ok)
     {
      string hint = "";
      if(rc == 10021)      hint = "（券商当前没有可成交报价：休市 / 加密品种周末无流动性 / 价格离现价太远）";
      else if(rc == 10016) hint = "（止损或止盈离入场价太近）";
      else if(rc == 10015) hint = "（价格无效）";
      else if(rc == 10027) hint = "（终端未开启算法交易）";
      else if(rc == 10019) hint = "（资金不足）";
      PushError("下单失败：" + m_trade.ResultRetcodeDescription() + hint +
                " (code " + IntegerToString((int)rc) + ")");
      if(!MQLInfoInteger(MQL_TESTER))
         Alert("UTM 下单失败：", m_trade.ResultRetcodeDescription(), hint, " (", (int)rc, ")");
      return false;
     }
   ticket = m_trade.ResultOrder();
   if(ticket == 0)
      ticket = m_trade.ResultDeal();
   m_trade.SetTypeFillingBySymbol(m_symbol);
   return true;
  }

//+------------------------------------------------------------------+
//| 挂单价校验：吸附到最小变动价位、检查最小距离、按价格纠正限价/突破   |
//+------------------------------------------------------------------+
bool CUtmEngine::ValidatePendingPrice(const int side, int &omode, double &price, const double sl, string &err)
  {
   double ask = UTM_Ask(m_symbol);
   double bid = UTM_Bid(m_symbol);
   if(ask <= 0.0 || bid <= 0.0)
     {
      err = "暂无报价，稍后重试";
      return false;
     }

   double ts = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
   double pt = UTM_Point(m_symbol);
   if(ts <= 0.0)
      ts = pt;
   if(pt <= 0.0)
      pt = ts;
   if(ts <= 0.0)
      ts = 0.00001;

   int    lvl  = (int)SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double mk   = (side == POSITION_TYPE_BUY ? ask : bid);
   double stop = MathMax(lvl * pt, UTM_RawSpread(m_symbol)) + ts;
   if(stop < ts * 2.0)
      stop = ts * 2.0;

   double p = MathRound(price / ts) * ts;
   p = UTM_NormPrice(m_symbol, p);

   if(MathAbs(p - mk) < stop)
     {
      err = "入场价离现价太近（需 ≥ " + DoubleToString(UTM_PriceToPips(m_symbol, stop), 1) + " 点）";
      return false;
     }

   //--- 止损也要离入场价足够远
   if(sl > 0.0 && lvl > 0)
     {
      double minSL = lvl * pt + ts;
      if(MathAbs(p - sl) < minSL)
        {
         err = "止损离入场价太近（需 ≥ " + DoubleToString(UTM_PriceToPips(m_symbol, minSL), 1) + " 点）";
         return false;
        }
     }

   //--- 价格在现价上方/下方决定是突破还是限价
   omode = (side == POSITION_TYPE_BUY
            ? (p < mk ? UTM_ORDER_LIMIT : UTM_ORDER_STOP)
            : (p > mk ? UTM_ORDER_LIMIT : UTM_ORDER_STOP));
   price = p;
   return true;
  }

bool CUtmEngine::SendPending(const int side, const int omode, const double price, const double volume,
                             const double sl, const double tp, const string comment, ulong &ticket)
  {
   ticket = 0;
   double p = UTM_NormPrice(m_symbol, price);
   bool ok = false;

   ENUM_ORDER_TYPE_FILLING modes[3] = {ORDER_FILLING_RETURN, ORDER_FILLING_FOK, ORDER_FILLING_IOC};
   uint rc = 0;
   for(int i = 0; i < 3 && !ok; i++)
     {
      m_trade.SetTypeFilling(modes[i]);
      if(side == POSITION_TYPE_BUY)
        {
         if(omode == UTM_ORDER_LIMIT)
            ok = m_trade.BuyLimit(volume, p, m_symbol, sl, tp, ORDER_TIME_GTC, 0, comment);
         else
            ok = m_trade.BuyStop(volume, p, m_symbol, sl, tp, ORDER_TIME_GTC, 0, comment);
        }
      else
        {
         if(omode == UTM_ORDER_LIMIT)
            ok = m_trade.SellLimit(volume, p, m_symbol, sl, tp, ORDER_TIME_GTC, 0, comment);
         else
            ok = m_trade.SellStop(volume, p, m_symbol, sl, tp, ORDER_TIME_GTC, 0, comment);
        }
      if(ok)
         break;
      rc = m_trade.ResultRetcode();
      if(rc != 10030)
         break;
     }

   if(!ok)
     {
      string hint = "";
      if(rc == 10021)      hint = "（券商当前没有可成交报价：休市 / 加密品种周末无流动性 / 价格离现价太远）";
      else if(rc == 10016) hint = "（止损/止盈离入场价太近）";
      else if(rc == 10015) hint = "（价格无效）";
      else if(rc == 10027) hint = "（终端未开启算法交易）";
      PushError("挂单失败：" + m_trade.ResultRetcodeDescription() + hint +
                " (code " + IntegerToString((int)rc) + ")");
      if(!MQLInfoInteger(MQL_TESTER))
         Alert("UTM 挂单失败：", m_trade.ResultRetcodeDescription(), hint, " (", (int)rc, ")");
      return false;
     }
   ticket = m_trade.ResultOrder();
   m_trade.SetTypeFillingBySymbol(m_symbol);
   return true;
  }

//+------------------------------------------------------------------+
//| Order type from price                                             |
//+------------------------------------------------------------------+
int CUtmEngine::DeriveOrderMode(const int side, const double price)
  {
   double ask = UTM_Ask(m_symbol);
   double bid = UTM_Bid(m_symbol);
   double tol = MathMax(UTM_RawSpread(m_symbol), UTM_Point(m_symbol));

   if(side == POSITION_TYPE_BUY)
     {
      if(price > ask + tol)
         return UTM_ORDER_STOP;
      if(price < ask - tol)
         return UTM_ORDER_LIMIT;
      return UTM_ORDER_MARKET;
     }

   if(price < bid - tol)
      return UTM_ORDER_STOP;
   if(price > bid + tol)
      return UTM_ORDER_LIMIT;
   return UTM_ORDER_MARKET;
  }

//+------------------------------------------------------------------+
//| Register split tickets                                            |
//+------------------------------------------------------------------+
//| 多级止盈：把总手数拆成「每一级止盈一个仓位」，各自挂服务器止盈      |
//| 返回 false = 拆不了（手数低于最小手数 / 只有一级 / 未开启）         |
//+------------------------------------------------------------------+
bool CUtmEngine::BuildServerSlices(const STrade &t, double &vols[], int &levels[])
  {
   ArrayResize(vols, 0);
   ArrayResize(levels, 0);

   if(!g_set.serverSplitTP)
      return false;
   if(!UTM_IsHedging())
      return false;   // netting accounts can only hold one position per symbol
   if(t.tpCount < 2 || t.lot <= 0.0)
      return false;

   double vmin = UTM_VolumeMin(m_symbol);
   double vmax = UTM_VolumeMax(m_symbol);
   if(vmin <= 0.0)
      return false;

   int    idx[UTM_MAX_TP];
   double pct[UTM_MAX_TP];
   int    n = 0;
   double sumPct = 0.0;

   for(int i = 0; i < t.tpCount && i < UTM_MAX_TP; i++)
     {
      if(t.tpPct[i] <= 0.0 || t.tp[i] <= 0.0)
         continue;
      idx[n]  = i;
      pct[n]  = t.tpPct[i];
      sumPct += t.tpPct[i];
      n++;
     }

   if(n < 2)
      return false;

   ArrayResize(vols, n);
   ArrayResize(levels, n);

   double assigned = 0.0;
   for(int k = 0; k < n; k++)
     {
      double v = (k == n - 1
                  ? UTM_NormLot(m_symbol, t.lot - assigned)
                  : UTM_NormLot(m_symbol, t.lot * pct[k] / sumPct));
      if(v < vmin || (vmax > 0.0 && v > vmax))
         return false;
      vols[k]    = v;
      levels[k]  = idx[k];
      assigned  += v;
     }

   //--- the slices must add up to the planned volume (one lot step tolerance)
   if(MathAbs(assigned - t.lot) > UTM_VolumeStep(m_symbol) * 0.51)
      return false;

   return true;
  }

//+------------------------------------------------------------------+
void CUtmEngine::RegisterSplitTickets(STrade &t, ulong &tickets[], const int n)
  {
   t.splitCount = 0;
   for(int i = 0; i < UTM_MAX_SPLIT; i++)
      t.splits[i] = 0;

   if(n <= 0)
      return;

   t.ticket = tickets[0];
   for(int i = 1; i < n && t.splitCount < UTM_MAX_SPLIT; i++)
      t.splits[t.splitCount++] = tickets[i];
  }

//+------------------------------------------------------------------+
//| Open a new trade (market or pending)                              |
//+------------------------------------------------------------------+
bool CUtmEngine::OpenNewTrade(const int side, const double entry, const double sl,
                              const double lot, const bool pending, const int omode)
  {
   if(!MQLInfoInteger(MQL_TESTER) &&
      (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED)))
     {
      PushError("自动交易未开启：请点终端工具栏的“算法交易”按钮后再试");
      Alert("UTM：自动交易未开启，请点终端工具栏的“算法交易”按钮");
      return false;
     }
   if(!Risk_EquityOK(g_set))
     {
      PushError("已触发净值止损，禁止开仓");
      return false;
     }
   if(!Risk_SpreadOK(m_symbol, g_set, m_emaSpread))
     {
      PushError("点差过大，已阻止开仓");
      return false;
     }

   STrade t;
   BlankTrade(t);
   t.id      = m_nextId++;
   t.type    = side;
   t.pending = pending;
   t.orderMode = omode;
   t.entry   = UTM_NormPrice(m_symbol, entry);
   t.sl      = UTM_NormPrice(m_symbol, sl);
   t.lot     = lot;
   t.riskDist = MathAbs(t.entry - t.sl);
   t.riskMoney = Risk_TotalAtRisk(m_symbol, lot, t.riskDist, g_set);
   t.opened  = TimeCurrent();
   t.comment = "UTM";

   if(t.riskDist <= 0.0)
     {
      PushError("止损距离为 0");
      return false;
     }

   //--- freeze the TP plan
   t.tpCount = g_set.tpCount;
   if(t.tpCount > UTM_MAX_TP) t.tpCount = UTM_MAX_TP;
   if(t.tpCount < 1) t.tpCount = 1;
   for(int i = 0; i < UTM_MAX_TP; i++)
     {
      t.tpRR[i]  = (i < t.tpCount ? g_set.tpRR[i] : 0.0);
      t.tpPct[i] = (i < t.tpCount ? g_set.tpPct[i] : 0.0);
     }
   t.trailStep = 0;

   bool ignore = (g_set.spreadMode == UTM_SPREAD_IGNORE || g_set.spreadMode == UTM_SPREAD_INVISIBLE);
   bool invisible = (g_set.spreadMode == UTM_SPREAD_INVISIBLE);

   //--- ignore-spread order flow
   if(pending)
     {
      t.virtualEntry = (ignore && !invisible && side == POSITION_TYPE_BUY) || invisible;
      t.virtualSL    = (ignore && side == POSITION_TYPE_SELL) || invisible;
     }
   else
     {
      t.virtualSL = (ignore && side == POSITION_TYPE_SELL) || invisible;
     }

   //--- take profits: one position per level when possible, else a broker TP
   ComputeTPs(t);

   //--- validate the pending price (snap to tick, check distance, fix limit/stop)
   int pmode = omode;
   if(pending && !t.virtualEntry)
     {
      string perr = "";
      double pprice = t.entry;
      if(!ValidatePendingPrice(side, pmode, pprice, t.sl, perr))
        {
         PushError("挂单失败：" + perr);
         if(!MQLInfoInteger(MQL_TESTER))
            Alert("UTM 挂单失败：", perr);
         return false;
        }
      if(pmode != omode)
        {
         Print("[UTM] 入场价已越过现价，挂单类型自动改为 ",
               (pmode == UTM_ORDER_LIMIT ? "限价" : "突破"));
         m_lastInfo = (pmode == UTM_ORDER_LIMIT ? "按限价挂单" : "按突破挂单");
         t.orderMode = pmode;
        }
      if(MathAbs(pprice - t.entry) > 0.0)
        {
         t.entry = pprice;
         ComputeTPs(t);
        }
     }

   double sVols[];
   int    sLevels[];
   //--- 只有挂单拆仓：市价入场有滑点，多张单的成交价会不一致
   bool   serverTP = (!invisible && !t.virtualEntry && pending &&
                      BuildServerSlices(t, sVols, sLevels));

   double pctSum = 0.0;
   for(int i = 0; i < t.tpCount && i < UTM_MAX_TP; i++)
      pctSum += t.tpPct[i];

   double brokerTP = 0.0;
   if(!serverTP && !invisible && t.tpCount > 0)
     {
      //--- fallback when the volume is too small to split: exit everything at the last TP
      if(g_set.serverSplitTP && pctSum >= 99.9)
         brokerTP = t.tp[t.tpCount - 1];
      else if(t.tpCount == 1 && t.tpPct[0] >= 99.9)
         brokerTP = t.tp[0];
     }

   double brokerSL = (t.virtualSL ? 0.0 : t.sl);
   if(t.virtualSL && g_set.failsafeSL && t.riskDist > 0.0)
      brokerSL = t.entry + (side == POSITION_TYPE_BUY ? -2.0 : 2.0) * t.riskDist;

   //--- build the send plan: one order per TP level, or split by the broker max lot
   double planVol[];
   double planTP[];
   if(serverTP)
     {
      int n = ArraySize(sVols);
      ArrayResize(planVol, n);
      ArrayResize(planTP, n);
      for(int k = 0; k < n; k++)
        {
         planVol[k] = sVols[k];
         planTP[k]  = t.tp[sLevels[k]];
        }
     }
   else
     {
      double bmax = UTM_VolumeMax(m_symbol);
      int parts = 1;
      if(g_set.bypassMaxLot && lot > bmax)
        {
         parts = (int)MathCeil(lot / bmax);
         if(parts > UTM_MAX_SPLIT)
            parts = UTM_MAX_SPLIT;
        }
      ArrayResize(planVol, parts);
      ArrayResize(planTP, parts);
      double remaining = lot;
      for(int k = 0; k < parts; k++)
        {
         double vol = (k == parts - 1 ? UTM_NormLot(m_symbol, remaining)
                                      : UTM_NormLot(m_symbol, lot / parts));
         planVol[k] = vol;
         planTP[k]  = brokerTP;
         remaining -= vol;
        }
     }

   ulong tickets[];
   ArrayResize(tickets, 0);

   for(int k = 0; k < ArraySize(planVol); k++)
     {
      double vol = planVol[k];
      if(vol < UTM_VolumeMin(m_symbol))
         break;

      ulong tk = 0;
      string cmt = "UTM-" + IntegerToString(t.id);
      bool ok = false;

      if(t.virtualEntry)
        {
         tk = 0;
         ok = true;
        }
      else if(pending)
         ok = SendPending(side, pmode, t.entry, vol, brokerSL, planTP[k], cmt, tk);
      else
         ok = SendMarket(side, vol, brokerSL, planTP[k], cmt, tk);

      if(!ok)
        {
         //--- roll back already opened parts
         for(int r = 0; r < ArraySize(tickets); r++)
           {
            if(pending)
               m_trade.OrderDelete(tickets[r]);
            else if(PositionSelectByTicket(tickets[r]))
               m_trade.PositionClose(tickets[r]);
           }
         return false;
        }

      if(tk > 0)
        {
         int n = ArraySize(tickets);
         ArrayResize(tickets, n + 1);
         tickets[n] = tk;
        }
     }

   if(serverTP)
      t.serverTP = true;

   if(ArraySize(tickets) > 0)
      RegisterSplitTickets(t, tickets, ArraySize(tickets));

   if(!pending)
     {
      t.posEntry = (side == POSITION_TYPE_BUY ? UTM_Ask(m_symbol) : UTM_Bid(m_symbol));
      t.opened = TimeCurrent();
     }

   ComputeTPs(t);
   AddTrade(t);

   Notify("entry");
   SaveState(true);
   m_lastError = "";
   m_lastInfo = "已开仓 #" + IntegerToString(t.id);
   return true;
  }

//+------------------------------------------------------------------+
//| Execution mode                                                    |
//+------------------------------------------------------------------+
void CUtmEngine::ActivateExec(const int side)
  {
   m_exec.active = true;
   m_exec.side   = side;
   int dm = g_set.defaultOrderMode;
   if(dm != UTM_ORDER_LIMIT && dm != UTM_ORDER_STOP)
      dm = UTM_ORDER_MARKET;
   m_exec.mode   = dm;
   m_exec.stage  = (dm == UTM_ORDER_MARKET ? 0 : 1);   // pending: pick the entry first
   m_exec.follow = true;

   double slDist = Risk_SLDistance(m_symbol, g_set);
   if(slDist <= 0.0)
      slDist = UTM_PipsToPrice(m_symbol, 20.0);

   double price = (side == POSITION_TYPE_BUY ? UTM_Ask(m_symbol) : UTM_Bid(m_symbol));
   m_exec.entry = UTM_NormPrice(m_symbol, price);
   m_exec.sl    = UTM_NormPrice(m_symbol, price - (side == POSITION_TYPE_BUY ? slDist : -slDist));

   m_exec.tpCount = g_set.tpCount;
   double dir = (side == POSITION_TYPE_BUY ? 1.0 : -1.0);
   for(int i = 0; i < UTM_MAX_TP; i++)
     {
      if(i < m_exec.tpCount && slDist > 0.0)
         m_exec.tp[i] = UTM_NormPrice(m_symbol, m_exec.entry + dir * slDist * g_set.tpRR[i]);
      else
         m_exec.tp[i] = 0.0;
     }

   m_exec.lot = ExecLot();
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
   m_lastInfo = (dm == UTM_ORDER_MARKET
                 ? "移动止损线到目标位置，左键点击下单"
                 : "第一次点击确定入场线，再点一次挂单");
   DrawExec();
   DrawHud();
   ChartRedraw();
  }

void CUtmEngine::DeactivateExec()
  {
   m_exec.active = false;
   m_exec.stage  = 0;
   m_exec.follow = false;
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, false);
   DeleteExecObjects();
   DrawHud();
   ChartRedraw();
  }

void CUtmEngine::ToggleExec()
  {
   if(m_exec.active)
      DeactivateExec();
   else
      ActivateExec(m_exec.side);
  }

void CUtmEngine::SwitchSide(const int side)
  {
   if(side == m_exec.side)
      return;

   double slDist = MathAbs(m_exec.entry - m_exec.sl);
   if(slDist <= 0.0)
      slDist = Risk_SLDistance(m_symbol, g_set);
   if(slDist <= 0.0)
      slDist = UTM_PipsToPrice(m_symbol, 20.0);

   m_exec.side = side;

   double price = (side == POSITION_TYPE_BUY ? UTM_Ask(m_symbol) : UTM_Bid(m_symbol));
   if(m_exec.mode == UTM_ORDER_MARKET || m_exec.stage >= 2)
     {
      m_exec.entry = UTM_NormPrice(m_symbol, price);
      m_exec.sl = UTM_NormPrice(m_symbol, m_exec.entry - (side == POSITION_TYPE_BUY ? slDist : -slDist));
     }
   else
     {
      m_exec.sl = UTM_NormPrice(m_symbol, m_exec.entry - (side == POSITION_TYPE_BUY ? slDist : -slDist));
     }

   double dir = (side == POSITION_TYPE_BUY ? 1.0 : -1.0);
   for(int i = 0; i < m_exec.tpCount; i++)
     {
      if(m_exec.tp[i] <= 0.0)
         continue;
      m_exec.tp[i] = UTM_NormPrice(m_symbol, m_exec.entry + dir * slDist * g_set.tpRR[i]);
     }
   m_exec.follow = true;
   if(m_exec.active)
     {
      DrawExec();
      DrawHud();
     }
  }

//+------------------------------------------------------------------+
//| Select the order mode (M / L / P / Backspace)                     |
//+------------------------------------------------------------------+
void CUtmEngine::ExecSetMode(const int mode)
  {
   m_exec.mode = mode;

   double slDist = Risk_SLDistance(m_symbol, g_set);
   if(slDist <= 0.0)
      slDist = UTM_PipsToPrice(m_symbol, 20.0);

   double price = (m_exec.side == POSITION_TYPE_BUY ? UTM_Ask(m_symbol) : UTM_Bid(m_symbol));
   m_exec.entry = UTM_NormPrice(m_symbol, price);
   m_exec.sl    = UTM_NormPrice(m_symbol, price - (m_exec.side == POSITION_TYPE_BUY ? slDist : -slDist));
   m_exec.follow = true;

   if(mode == UTM_ORDER_MARKET)
     {
      m_exec.stage = 0;
      m_lastInfo = "市价：移动止损线，点击左键下单";
     }
   else
     {
      m_exec.stage = 1;
      m_lastInfo = "挂单：第一次点击定入场，第二次点击定止损";
     }

   double dir = (m_exec.side == POSITION_TYPE_BUY ? 1.0 : -1.0);
   for(int i = 0; i < m_exec.tpCount; i++)
      m_exec.tp[i] = UTM_NormPrice(m_symbol, m_exec.entry + dir * slDist * g_set.tpRR[i]);

   if(m_exec.active)
     {
      DrawExec();
      DrawHud();
      ChartRedraw();
     }
  }

void CUtmEngine::CycleOrderMode()
  {
   int next = m_exec.mode;
   if(next == UTM_ORDER_MARKET)
      next = UTM_ORDER_LIMIT;
   else if(next == UTM_ORDER_LIMIT)
      next = UTM_ORDER_STOP;
   else
      next = UTM_ORDER_MARKET;

   ExecSetMode(next);
  }

void CUtmEngine::ResetExecToMarket()
  {
   ExecSetMode(UTM_ORDER_MARKET);
  }

//+------------------------------------------------------------------+
//| Entry line dragged with the mouse                                 |
//+------------------------------------------------------------------+
void CUtmEngine::SetExecEntry(const double price)
  {
   if(!m_exec.active)
      return;

   double dist = Risk_SLDistance(m_symbol, g_set);
   if(dist <= 0.0)
      dist = MathAbs(m_exec.entry - m_exec.sl);
   if(dist <= 0.0)
      dist = UTM_PipsToPrice(m_symbol, 20.0);

   m_exec.entry  = UTM_NormPrice(m_symbol, price);
   m_exec.sl     = UTM_NormPrice(m_symbol, m_exec.entry - (m_exec.side == POSITION_TYPE_BUY ? dist : -dist));
   m_exec.stage  = 2;        // the entry is fixed, the SL comes next
   m_exec.follow = false;    // manual placement until the next click

   double dir = (m_exec.side == POSITION_TYPE_BUY ? 1.0 : -1.0);
   for(int i = 0; i < m_exec.tpCount; i++)
      m_exec.tp[i] = UTM_NormPrice(m_symbol, m_exec.entry + dir * dist * g_set.tpRR[i]);

   DrawExec();
   DrawHud();
  }

//+------------------------------------------------------------------+
//| Left click inside the execution mode                              |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| A left click: position the active line, then confirm              |
//+------------------------------------------------------------------+
void CUtmEngine::ExecClickAt(const double price)
  {
   if(!m_exec.active)
      return;

   double p = UTM_NormPrice(m_symbol, price);
   if(p <= 0.0)
      return;

   bool slStage = (m_exec.mode == UTM_ORDER_MARKET || m_exec.stage >= 2);
   if(slStage)
      m_exec.sl = p;
   else
     {
      double dist = MathAbs(m_exec.entry - m_exec.sl);
      if(dist <= 0.0)
         dist = Risk_SLDistance(m_symbol, g_set);
      if(dist <= 0.0)
         dist = UTM_PipsToPrice(m_symbol, 20.0);
      m_exec.entry = p;
      m_exec.sl = UTM_NormPrice(m_symbol, p - (m_exec.side == POSITION_TYPE_BUY ? dist : -dist));
     }

   m_exec.follow = false;
   double d2 = MathAbs(m_exec.entry - m_exec.sl);
   double dir = (m_exec.side == POSITION_TYPE_BUY ? 1.0 : -1.0);
   for(int i = 0; i < m_exec.tpCount && i < UTM_MAX_TP; i++)
      if(d2 > 0.0)
         m_exec.tp[i] = UTM_NormPrice(m_symbol, m_exec.entry + dir * d2 * g_set.tpRR[i]);

   ExecSyncSide();
   ExecConfirm();
  }

//+------------------------------------------------------------------+
//| Confirm the current step (click / Enter)                          |
//+------------------------------------------------------------------+
void CUtmEngine::ExecConfirm()
  {
   if(!m_exec.active)
      return;

   ExecSyncSide();

   //--- market order: click = send
   if(m_exec.mode == UTM_ORDER_MARKET || m_exec.stage == 0)
     {
      if(!ExecuteNow())
        {
         //--- 下单失败：让线继续跟随鼠标，方便调整后重试
         m_exec.follow = true;
         DrawExec();
         DrawHud();
         ChartRedraw();
        }
      return;
     }

   //--- pending: first click fixes the entry
   if(m_exec.stage == 1)
     {
      m_exec.stage  = 2;
      m_exec.follow = true;
      m_lastInfo = "入场已确定，移动止损线后点击挂单";
      DrawExec();
      DrawHud();
      ChartRedraw();
      return;
     }

   //--- second click: place the stop loss and send
   if(!ExecuteNow())
     {
      //--- 下单失败：恢复鼠标跟随
      m_exec.follow = true;
      DrawExec();
      DrawHud();
      ChartRedraw();
     }
  }

//+------------------------------------------------------------------+
//| Mouse tracking while a line follows the cursor                    |
//+------------------------------------------------------------------+
void CUtmEngine::ExecMouseMove(const int x, const int y)
  {
   if(!m_exec.active || !m_exec.follow)
      return;

   int      sub = 0;
   datetime tm  = 0;
   double   price = 0.0;
   if(!ChartXYToTimePrice(0, x, y, sub, tm, price))
      return;

   double p = UTM_NormPrice(m_symbol, price);
   if(p <= 0.0)
      return;

   double dir = (m_exec.side == POSITION_TYPE_BUY ? 1.0 : -1.0);
   bool   slStage = (m_exec.mode == UTM_ORDER_MARKET || m_exec.stage >= 2);

   if(slStage)
     {
      if(MathAbs(m_exec.sl - p) < UTM_Point(m_symbol) * 0.5)
         return;
      m_exec.sl = p;
      if(m_exec.mode == UTM_ORDER_MARKET)
         m_exec.entry = (m_exec.side == POSITION_TYPE_BUY ? UTM_Ask(m_symbol) : UTM_Bid(m_symbol));
      if(ExecSyncSide())
        {
         ChartRedraw();
         return;
        }
     }
   else
     {
      if(MathAbs(m_exec.entry - p) < UTM_Point(m_symbol) * 0.5)
         return;
      double dist = MathAbs(m_exec.entry - m_exec.sl);
      if(dist <= 0.0)
         dist = Risk_SLDistance(m_symbol, g_set);
      m_exec.entry = p;
      m_exec.sl = UTM_NormPrice(m_symbol, p - (m_exec.side == POSITION_TYPE_BUY ? dist : -dist));
     }

   double dist2 = MathAbs(m_exec.entry - m_exec.sl);
   for(int i = 0; i < m_exec.tpCount; i++)
     {
      if(i < UTM_MAX_TP && dist2 > 0.0)
         m_exec.tp[i] = UTM_NormPrice(m_symbol, m_exec.entry + dir * dist2 * g_set.tpRR[i]);
     }

   m_exec.lot = ExecLot();
   DrawExec();
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| 止损落在市价另一侧时自动翻转方向，并把止盈镜像到另一侧              |
//+------------------------------------------------------------------+
bool CUtmEngine::ExecSyncSide()
  {
   if(!m_exec.active)
      return false;

   bool   isBuy = (m_exec.side == POSITION_TYPE_BUY);
   double ref   = (m_exec.mode == UTM_ORDER_MARKET
                   ? (isBuy ? UTM_Ask(m_symbol) : UTM_Bid(m_symbol))
                   : m_exec.entry);

   bool flip = (isBuy ? (m_exec.sl > ref) : (m_exec.sl < ref));
   if(!flip)
      return false;

   m_exec.side = (isBuy ? POSITION_TYPE_SELL : POSITION_TYPE_BUY);

   if(m_exec.mode == UTM_ORDER_MARKET)
      m_exec.entry = (m_exec.side == POSITION_TYPE_BUY ? UTM_Ask(m_symbol) : UTM_Bid(m_symbol));

   double dist = MathAbs(m_exec.entry - m_exec.sl);
   double dir  = (m_exec.side == POSITION_TYPE_BUY ? 1.0 : -1.0);
   for(int i = 0; i < m_exec.tpCount && i < UTM_MAX_TP; i++)
      if(dist > 0.0)
         m_exec.tp[i] = UTM_NormPrice(m_symbol, m_exec.entry + dir * dist * g_set.tpRR[i]);

   m_exec.lot = ExecLot();
   m_lastInfo = (m_exec.side == POSITION_TYPE_BUY ? "止损位于市价下方，已切换为买入" : "止损位于市价上方，已切换为卖出");

   DrawExec();
   DrawHud();
   return true;
  }

//+------------------------------------------------------------------+
//| 读取当前执行计划的止盈价（供测试与外部查询）                        |
//+------------------------------------------------------------------+
bool CUtmEngine::ExecTPs(double &out[])
  {
   ArrayResize(out, UTM_MAX_TP);
   for(int i = 0; i < UTM_MAX_TP; i++)
      out[i] = (m_exec.active ? m_exec.tp[i] : 0.0);
   return (m_exec.active);
  }

void CUtmEngine::ExecSetSL(const double price)
  {
   m_exec.sl = UTM_NormPrice(m_symbol, price);
   m_exec.follow = false;
   if(!ExecSyncSide())
     {
      DrawExec();
      DrawHud();
     }
  }

//+------------------------------------------------------------------+
void CUtmEngine::ExecSetTP(const int idx, const double price)
  {
   if(idx < 0 || idx >= UTM_MAX_TP)
      return;
   m_exec.tp[idx] = UTM_NormPrice(m_symbol, price);
   DrawExec();
  }


double CUtmEngine::ExecLot()
  {
   double entry = (m_exec.mode == UTM_ORDER_MARKET
                   ? (m_exec.side == POSITION_TYPE_BUY ? UTM_Ask(m_symbol) : UTM_Bid(m_symbol))
                   : m_exec.entry);
   double riskMoney = 0.0;
   double dist = 0.0;
   double bal = UTM_BalanceForRisk(g_set.overrideBalance);
   double lot = Risk_CalcLot(m_symbol, entry, m_exec.sl, g_set, bal, riskMoney, dist);
   m_exec.lot = lot;
   return lot;
  }

double CUtmEngine::ExecRisk()
  {
   double entry = (m_exec.mode == UTM_ORDER_MARKET
                   ? (m_exec.side == POSITION_TYPE_BUY ? UTM_Ask(m_symbol) : UTM_Bid(m_symbol))
                   : m_exec.entry);
   double lot = ExecLot();
   return Risk_TotalAtRisk(m_symbol, lot, MathAbs(entry - m_exec.sl), g_set);
  }

//+------------------------------------------------------------------+
//| 市价模式下入场价始终等于当前价：止损点数 / 止盈预览随之更新          |
//+------------------------------------------------------------------+
void CUtmEngine::ExecSyncMarket()
  {
   if(!m_exec.active || m_exec.mode != UTM_ORDER_MARKET)
      return;

   double price = (m_exec.side == POSITION_TYPE_BUY ? UTM_Ask(m_symbol) : UTM_Bid(m_symbol));
   if(price <= 0.0)
      return;

   m_exec.entry = UTM_NormPrice(m_symbol, price);

   double dist = MathAbs(m_exec.entry - m_exec.sl);
   double dir  = (m_exec.side == POSITION_TYPE_BUY ? 1.0 : -1.0);
   for(int i = 0; i < m_exec.tpCount && i < UTM_MAX_TP; i++)
      m_exec.tp[i] = (dist > 0.0 ? UTM_NormPrice(m_symbol, m_exec.entry + dir * dist * g_set.tpRR[i]) : 0.0);

   m_exec.lot = ExecLot();
  }

double CUtmEngine::ExecSLPips()
  {
   //--- market orders are executed at the live price, so measure from it
   double entry = (m_exec.mode == UTM_ORDER_MARKET
                   ? (m_exec.side == POSITION_TYPE_BUY ? UTM_Ask(m_symbol) : UTM_Bid(m_symbol))
                   : m_exec.entry);
   if(entry <= 0.0)
      entry = m_exec.entry;
   return UTM_PriceToPips(m_symbol, MathAbs(entry - m_exec.sl));
  }

bool CUtmEngine::ExecuteNow()
  {
   m_lastError = "";
   if(!m_exec.active)
      return false;

   double entry = (m_exec.mode == UTM_ORDER_MARKET
                   ? (m_exec.side == POSITION_TYPE_BUY ? UTM_Ask(m_symbol) : UTM_Bid(m_symbol))
                   : m_exec.entry);
   double sl = m_exec.sl;

   //--- adaptive spread factor
   if(g_set.spreadMode == UTM_SPREAD_FACTOR)
     {
      double factor = (g_set.spreadFactor > 0.0 ? UTM_PipsToPrice(m_symbol, g_set.spreadFactor)
                                                : m_emaSpread);
      if(m_exec.side == POSITION_TYPE_BUY)
         entry += factor;
      else
         sl += factor;
     }

   double dist = MathAbs(entry - sl);
   if(dist < UTM_Point(m_symbol) * 2.0)
     {
      PushError("止损离入场价太近");
      return false;
     }

   if(m_exec.side == POSITION_TYPE_BUY && sl >= entry)
     {
      PushError("买入止损必须低于入场价");
      return false;
     }
   if(m_exec.side == POSITION_TYPE_SELL && sl <= entry)
     {
      PushError("卖出止损必须高于入场价");
      return false;
     }

   double bal = UTM_BalanceForRisk(g_set.overrideBalance);
   double riskMoney = 0.0;
   double realDist = 0.0;
   double lot = Risk_CalcLot(m_symbol, entry, sl, g_set, bal, riskMoney, realDist);
   if(lot <= 0.0)
     {
      PushError("计算手数为 0");
      return false;
     }

   bool pending = (m_exec.mode != UTM_ORDER_MARKET);
   int omode = (pending ? m_exec.mode : UTM_ORDER_MARKET);

   if(!OpenNewTrade(m_exec.side, entry, sl, lot, pending, omode))
      return false;

   DeactivateExec();
   return true;
  }

//+------------------------------------------------------------------+
//| Quick market trade (panel buttons)                                |
//+------------------------------------------------------------------+
bool CUtmEngine::QuickTrade(const int side)
  {
   m_lastError = "";
   double entry = (side == POSITION_TYPE_BUY ? UTM_Ask(m_symbol) : UTM_Bid(m_symbol));
   double slDist = Risk_SLDistance(m_symbol, g_set);
   if(slDist <= 0.0)
     {
      PushError("止损大小为 0");
      return false;
     }
   double sl = entry - (side == POSITION_TYPE_BUY ? slDist : -slDist);

   //--- adaptive spread factor
   if(g_set.spreadMode == UTM_SPREAD_FACTOR)
     {
      double factor = (g_set.spreadFactor > 0.0 ? UTM_PipsToPrice(m_symbol, g_set.spreadFactor)
                                                : m_emaSpread);
      if(side == POSITION_TYPE_BUY)
         entry += factor;
      else
         sl += factor;
     }

   double bal = UTM_BalanceForRisk(g_set.overrideBalance);
   double riskMoney = 0.0;
   double dist = 0.0;
   double lot = Risk_CalcLot(m_symbol, entry, sl, g_set, bal, riskMoney, dist);
   if(lot <= 0.0)
     {
      PushError("计算手数为 0");
      return false;
     }

   return OpenNewTrade(side, entry, sl, lot, false, UTM_ORDER_MARKET);
  }

//+------------------------------------------------------------------+
//| Bulk actions                                                      |
//+------------------------------------------------------------------+
void CUtmEngine::BreakEvenAll()
  {
   for(int i = 0; i < m_count; i++)
     {
      if(m_tr[i].pending)
         continue;
      double dir = (m_tr[i].type == POSITION_TYPE_BUY ? 1.0 : -1.0);
      double be = m_tr[i].entry + dir * g_set.beOffsetRR * m_tr[i].riskDist;
      double cur = m_tr[i].sl;
      bool better = (m_tr[i].type == POSITION_TYPE_BUY ? (cur <= 0.0 || be > cur)
                                                      : (cur <= 0.0 || be < cur));
      if(better)
        {
         SetTradeSL(i, be, true);
         m_tr[i].beDone = true;
        }
     }
   m_lastInfo = "已设置保本";
  }

void CUtmEngine::CloseAllPositions()
  {
   for(int i = m_count - 1; i >= 0; i--)
     {
      if(!m_tr[i].pending)
         ClosePositionAt(i, "全部平仓");
     }
   m_lastInfo = "已平掉全部仓位";
  }

void CUtmEngine::CancelPending()
  {
   for(int i = m_count - 1; i >= 0; i--)
     {
      if(!m_tr[i].pending)
         continue;
      if(!m_tr[i].virtualEntry)
        {
         DeleteTradeOrders(m_tr[i]);
        }
      RemoveAt(i);
     }
   m_lastInfo = "已撤销全部挂单";
  }

void CUtmEngine::HalveRisk()
  {
   if(g_set.riskMode == UTM_RISK_LOT)
      g_set.riskValue = UTM_NormLot(m_symbol, g_set.riskValue * 0.5);
   else
      g_set.riskValue = g_set.riskValue * 0.5;
   m_lastInfo = "风险已减半";
  }


//+------------------------------------------------------------------+
//| Trade modification by id (chart drag / buttons)                   |
//+------------------------------------------------------------------+
void CUtmEngine::CloseTradeById(const long id, const double pct)
  {
   int idx = FindById(id);
   if(idx < 0)
      return;
   if(pct >= 99.9)
     {
      ClosePositionAt(idx, "按钮");
      return;
     }
   double vol = UTM_NormLot(m_symbol, m_tr[idx].lot * pct / 100.0);
   if(vol >= TradeVolume(m_tr[idx]))
     {
      ClosePositionAt(idx, "按钮");
      return;
     }
   PartialClose(idx, vol, "按钮");
  }

void CUtmEngine::ModifyTradeSL(const long id, const double sl)
  {
   int idx = FindById(id);
   if(idx < 0)
      return;

   if(m_tr[idx].pending)
     {
      m_tr[idx].sl = UTM_NormPrice(m_symbol, sl);
      RepricePendingTrade(idx);
      return;
     }

   SetTradeSL(idx, sl, false);
  }

void CUtmEngine::ModifyTradeTP(const long id, const int tpIdx, const double price)
  {
   int idx = FindById(id);
   if(idx < 0)
      return;

   m_tr[idx].tp[tpIdx] = UTM_NormPrice(m_symbol, price);

   //--- a broker TP is only used when the whole position closes at TP1
   bool sendTP = (m_tr[idx].tpCount == 1 && m_tr[idx].tpPct[0] >= 99.9 && tpIdx == 0 &&
                  g_set.spreadMode != UTM_SPREAD_INVISIBLE);

   if(!m_tr[idx].virtualSL)
     {
      ulong tickets[];
      int n = CollectTickets(m_tr[idx], tickets);
      for(int i = 0; i < n; i++)
        {
         if(!PositionSelectByTicket(tickets[i]))
            continue;
         double sl = PositionGetDouble(POSITION_SL);
         double tp = (sendTP ? m_tr[idx].tp[0] : PositionGetDouble(POSITION_TP));
         m_trade.PositionModify(tickets[i], sl, tp);
        }
     }
   SaveSoon();
  }

//+------------------------------------------------------------------+
//| Recalculate the volume of a pending order after a drag            |
//+------------------------------------------------------------------+
void CUtmEngine::RepricePendingTrade(const int index)
  {
   if(index < 0 || index >= m_count || !m_tr[index].pending)
      return;

   double bal = UTM_BalanceForRisk(g_set.overrideBalance);
   double rm = 0.0, dist2 = 0.0;
   double lot = Risk_CalcLot(m_symbol, m_tr[index].entry, m_tr[index].sl, g_set, bal, rm, dist2);
   if(lot <= 0.0)
      lot = m_tr[index].lot;

   bool lotChanged = (MathAbs(lot - m_tr[index].lot) > UTM_VolumeStep(m_symbol) * 0.5);
   m_tr[index].lot = lot;
   m_tr[index].riskDist = MathAbs(m_tr[index].entry - m_tr[index].sl);
   ComputeTPs(m_tr[index]);

   if(m_tr[index].virtualEntry || m_tr[index].ticket == 0)
      return;

   double brokerSL = (m_tr[index].virtualSL ? 0.0 : m_tr[index].sl);
   if(m_tr[index].virtualSL && g_set.failsafeSL && m_tr[index].riskDist > 0.0)
      brokerSL = m_tr[index].entry + (m_tr[index].type == POSITION_TYPE_BUY ? -2.0 : 2.0) * m_tr[index].riskDist;

   double brokerTP = 0.0;
   if(m_tr[index].tpCount == 1 && m_tr[index].tpPct[0] >= 99.9 && g_set.spreadMode != UTM_SPREAD_INVISIBLE)
      brokerTP = m_tr[index].tp[0];

   if(!lotChanged && OrderSelect(m_tr[index].ticket))
     {
      m_trade.OrderModify(m_tr[index].ticket, m_tr[index].entry, brokerSL, brokerTP, ORDER_TIME_GTC, 0);
      return;
     }

   //--- MT5 cannot change the volume of a pending order: replace it
   ulong oldTicket = m_tr[index].ticket;
   m_trade.OrderDelete(oldTicket);

   ulong tk = 0;
   if(SendPending(m_tr[index].type, m_tr[index].orderMode, m_tr[index].entry, m_tr[index].lot,
                  brokerSL, brokerTP, "UTM-" + IntegerToString(m_tr[index].id), tk))
      m_tr[index].ticket = tk;

   SaveSoon();
  }

//+------------------------------------------------------------------+
//| Object clicks (per-trade buttons)                                 |
//+------------------------------------------------------------------+
void CUtmEngine::OnObjectClick(const string name)
  {
   if(StringFind(name, UTM_OBJ_PREFIX + "T_") != 0)
      return;

   string rest = StringSubstr(name, StringLen(UTM_OBJ_PREFIX + "T_"));
   int us = StringFind(rest, "_");
   if(us <= 0)
      return;

   long id = StringToInteger(StringSubstr(rest, 0, us));
   string kind = StringSubstr(rest, us + 1);

   if(kind == "BTN_X")
      CloseTradeById(id, 100.0);
   else if(kind == "BTN_P")
      CloseTradeById(id, 50.0);
  }

//+------------------------------------------------------------------+
//| Cancel the pending order closest to a price                       |
//+------------------------------------------------------------------+
void CUtmEngine::CancelByPriceArea(const double price)
  {
   int idx = -1;
   double best = DBL_MAX;
   for(int i = 0; i < m_count; i++)
     {
      if(!m_tr[i].pending)
         continue;
      double d = MathAbs(m_tr[i].entry - price);
      if(d < best)
        {
         best = d;
         idx = i;
        }
     }
   if(idx < 0)
      return;
   if(!m_tr[idx].virtualEntry && m_tr[idx].ticket > 0)
      m_trade.OrderDelete(m_tr[idx].ticket);
   RemoveAt(idx);
  }

//+------------------------------------------------------------------+
//| Persistence                                                       |
//+------------------------------------------------------------------+
void CUtmEngine::SaveState(const bool force)
  {
   if((bool)MQLInfoInteger(MQL_TESTER))
      return;

   datetime now = TimeCurrent();
   if(!force && (now - m_lastSave) < 5)
      return;
   m_lastSave = now;

   UTM_EnsureFolder(UTM_SETTINGS_FOLDER, true);
   int h = FileOpen(m_stateFile, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
   if(h == INVALID_HANDLE)
      h = FileOpen(m_stateFile, FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return;

   FileWrite(h, "#UTM|" + UTM_VERSION + "|" + m_symbol + "|" + IntegerToString(m_magic));
   for(int i = 0; i < m_count; i++)
     {
      string splits = "";
      for(int k = 0; k < m_tr[i].splitCount; k++)
        {
         if(k > 0)
            splits += ",";
         splits += IntegerToString((long)m_tr[i].splits[k]);
        }

      string rrCsv = "", pctCsv = "", pxCsv = "";
      for(int k = 0; k < UTM_MAX_TP; k++)
        {
         if(k > 0)
           {
            rrCsv  += ",";
            pctCsv += ",";
            pxCsv  += ",";
           }
         rrCsv  += DoubleToString(m_tr[i].tpRR[k], 3);
         pctCsv += DoubleToString(m_tr[i].tpPct[k], 2);
         pxCsv  += DoubleToString(m_tr[i].tp[k], _Digits);
        }

      string line = IntegerToString(m_tr[i].id) + "|"
                    + IntegerToString((long)m_tr[i].ticket) + "|"
                    + IntegerToString(m_tr[i].type) + "|"
                    + (m_tr[i].pending ? "1" : "0") + "|"
                    + (m_tr[i].virtualEntry ? "1" : "0") + "|"
                    + (m_tr[i].virtualSL ? "1" : "0") + "|"
                    + IntegerToString(m_tr[i].orderMode) + "|"
                    + DoubleToString(m_tr[i].lot, 4) + "|"
                    + DoubleToString(m_tr[i].entry, _Digits) + "|"
                    + DoubleToString(m_tr[i].posEntry, _Digits) + "|"
                    + DoubleToString(m_tr[i].sl, _Digits) + "|"
                    + DoubleToString(m_tr[i].riskDist, _Digits) + "|"
                    + DoubleToString(m_tr[i].riskMoney, 2) + "|"
                    + IntegerToString(m_tr[i].tpCount) + "|"
                    + IntegerToString(m_tr[i].tpDone) + "|"
                    + (m_tr[i].beDone ? "1" : "0") + "|"
                    + "0" + "|"
                    + "0" + "|"
                    + (m_tr[i].trailingTP ? "1" : "0") + "|"
                    + IntegerToString(m_tr[i].trailStep) + "|"
                    + IntegerToString((long)m_tr[i].formulaDone) + "|"
                    + IntegerToString((long)m_tr[i].opened) + "|"
                    + splits + "|"
                    + m_tr[i].comment + "|"
                    + rrCsv + "|" + pctCsv + "|" + pxCsv + "|"
                    + (m_tr[i].serverTP ? "1" : "0");

      FileWrite(h, line);
     }
   FileClose(h);
  }

void CUtmEngine::LoadState()
  {
   if((bool)MQLInfoInteger(MQL_TESTER))
      return;

   m_count = 0;
   ArrayResize(m_tr, 0);
   m_nextId = 1;

   if(!FileIsExist(m_stateFile) && !FileIsExist(m_stateFile, FILE_COMMON))
      return;

   int h = FileOpen(m_stateFile, FILE_READ | FILE_TXT | FILE_ANSI | FILE_COMMON);
   if(h == INVALID_HANDLE)
      h = FileOpen(m_stateFile, FILE_READ | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return;

   while(!FileIsEnding(h))
     {
      string line = FileReadString(h);
      if(line == "" || StringGetCharacter(line, 0) == '#')
         continue;

      string p[];
      if(StringSplit(line, '|', p) < 23)
         continue;

      STrade t;
      BlankTrade(t);
      t.id = StringToInteger(p[0]);
      t.ticket = (ulong)StringToInteger(p[1]);
      t.type = (int)StringToInteger(p[2]);
      t.pending = (StringToInteger(p[3]) != 0);
      t.virtualEntry = (StringToInteger(p[4]) != 0);
      t.virtualSL = (StringToInteger(p[5]) != 0);
      t.orderMode = (int)StringToInteger(p[6]);
      t.lot = StringToDouble(p[7]);
      t.entry = StringToDouble(p[8]);
      t.posEntry = StringToDouble(p[9]);
      t.sl = StringToDouble(p[10]);
      t.riskDist = StringToDouble(p[11]);
      t.riskMoney = StringToDouble(p[12]);
      t.tpCount = (int)StringToInteger(p[13]);
      t.tpDone = (int)StringToInteger(p[14]);
      t.beDone = (StringToInteger(p[15]) != 0);
      t.trailingTP = (StringToInteger(p[18]) != 0);
      t.trailStep = (int)StringToInteger(p[19]);
      t.formulaDone = (uint)StringToInteger(p[20]);
      t.opened = (datetime)StringToInteger(p[21]);

      if(p[22] != "")
        {
         string sp[];
         int n = StringSplit(p[22], ',', sp);
         for(int i = 0; i < n && i < UTM_MAX_SPLIT; i++)
           {
            ulong tk = (ulong)StringToInteger(sp[i]);
            if(tk > 0)
               t.splits[t.splitCount++] = tk;
           }
        }
      if(ArraySize(p) > 23)
         t.comment = p[23];

      //--- TP plan saved by this build (RR / % / price lists)
      if(ArraySize(p) > 26)
        {
         string a[];
         if(StringSplit(p[24], ',', a) >= UTM_MAX_TP)
            for(int i = 0; i < UTM_MAX_TP; i++)
               t.tpRR[i] = StringToDouble(a[i]);
         if(StringSplit(p[25], ',', a) >= UTM_MAX_TP)
            for(int i = 0; i < UTM_MAX_TP; i++)
               t.tpPct[i] = StringToDouble(a[i]);
         if(StringSplit(p[26], ',', a) >= UTM_MAX_TP)
            for(int i = 0; i < UTM_MAX_TP; i++)
               t.tp[i] = StringToDouble(a[i]);
        }

      if(ArraySize(p) > 27)
         t.serverTP = (StringToInteger(p[27]) != 0);

      if(t.riskDist <= 0.0)
         t.riskDist = MathAbs(t.entry - t.sl);

      if(t.tpCount > 0 && t.riskDist > 0.0)
        {
         bool hasPct = false;
         bool hasPx  = false;
         for(int i = 0; i < t.tpCount; i++)
           {
            if(t.tpPct[i] > 0.0) hasPct = true;
            if(t.tp[i] > 0.0)    hasPx  = true;
           }
         if(!hasPct)
           {
            t.tpCount = 1;
            t.tpPct[0] = 100.0;
            t.tpRR[0] = 1.0;
           }
         if(t.tpRR[0] <= 0.0)
            t.tpRR[0] = 1.0;
         if(!hasPx)
            ComputeTPs(t);
        }
      else
        {
         //--- adopt: use the levels currently stored at the broker
         double slv = 0.0, tpv = 0.0;
         if(PositionSelectByTicket(t.ticket))
           {
            slv = PositionGetDouble(POSITION_SL);
            tpv = PositionGetDouble(POSITION_TP);
           }
         else if(OrderSelect(t.ticket))
           {
            slv = OrderGetDouble(ORDER_SL);
            tpv = OrderGetDouble(ORDER_TP);
           }
         if(slv > 0.0)
            t.sl = slv;
         if(tpv > 0.0 && t.riskDist > 0.0)
           {
            t.tpCount = 1;
            t.tpRR[0] = MathAbs(tpv - t.entry) / t.riskDist;
            t.tpPct[0] = 100.0;
            t.tp[0] = tpv;
           }
         else
            t.tpCount = 0;
        }

      if(t.id >= m_nextId)
         m_nextId = t.id + 1;

      AddTrade(t);
     }

   FileClose(h);
  }

//+------------------------------------------------------------------+
//| Chart events                                                      |
//+------------------------------------------------------------------+
void CUtmEngine::OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(id == CHARTEVENT_KEYDOWN)
     {
      int key = (int)lparam;
      if(key == 27)
        {
         ToggleExec();
         return;
        }

      //--- 所有功能键都要求先进入执行模式，避免误触（ESC 除外）
      if(!m_exec.active)
         return;

      switch(key)
        {
         case 13:  ExecConfirm();           break;   // Enter
         case 8:   CycleOrderMode();               break; // Backspace
         case 66:  SwitchSide(POSITION_TYPE_BUY);  break; // B
         case 83:  SwitchSide(POSITION_TYPE_SELL); break; // S
         case 77:  ResetExecToMarket();    break;   // M
         case 76:  ExecSetMode(UTM_ORDER_LIMIT);   break; // L
         case 80:  ExecSetMode(UTM_ORDER_STOP);    break; // P
         case 69:  BreakEvenAll();         break;   // E
         case 67:  CancelPending();        break;   // C
         case 82:  HalveRisk();            break;   // R
         case 88:  CloseAllPositions();    break;   // X
         default: break;
        }
      return;
     }

   if(id == CHARTEVENT_MOUSE_MOVE)
     {
      if(!m_exec.active || !m_exec.follow)
         return;
      int mx = (int)lparam;
      int my = (int)dparam;
      //--- 周期 / 缩放切换后终端会补发同一像素位置的移动事件，跳过它
      if(GetTickCount() < m_mouseIgnoreUntil)
        {
         m_lastMouseX = mx;
         m_lastMouseY = my;
         return;
        }
      if(mx == m_lastMouseX && my == m_lastMouseY)
         return;
      m_lastMouseX = mx;
      m_lastMouseY = my;
      ExecMouseMove(mx, my);
      return;
     }

   if(id == CHARTEVENT_CLICK)
     {
      if(!m_exec.active)
         return;
      int      sub = 0;
      datetime tm  = 0;
      double   price = 0.0;
      if(ChartXYToTimePrice(0, (int)lparam, (int)dparam, sub, tm, price))
         ExecClickAt(price);
      else
         ExecConfirm();
      return;
     }

   if(id == CHARTEVENT_OBJECT_DRAG)
     {
      string name = sparam;
      if(StringFind(name, UTM_OBJ_PREFIX + "X_") == 0)
        {
         ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
         double price = ObjectGetDouble(0, name, OBJPROP_PRICE, 0);
         if(StringFind(name, "ENTRY") > 0)
            SetExecEntry(price);
         else if(StringFind(name, "SL") > 0)
            ExecSetSL(price);
         else if(StringFind(name, "TP_") > 0)
           {
            int pos = StringFind(name, "TP_");
            int idx = (int)StringToInteger(StringSubstr(name, pos + 3));
            ExecSetTP(idx, price);
           }
         return;
        }

      //--- trade lines: UTM_T_<id>_ENTRY / _SL / _TP_<i>
      if(StringFind(name, UTM_OBJ_PREFIX + "T_") != 0)
         return;

      ObjectSetInteger(0, name, OBJPROP_SELECTED, false);

      string rest = StringSubstr(name, StringLen(UTM_OBJ_PREFIX + "T_"));
      int us = StringFind(rest, "_");
      if(us <= 0)
         return;
      long tid = StringToInteger(StringSubstr(rest, 0, us));
      string kind = StringSubstr(rest, us + 1);
      double price = ObjectGetDouble(0, name, OBJPROP_PRICE, 0);

      int idx = FindById(tid);
      if(idx < 0)
         return;

      if(StringFind(kind, "TP_") == 0)
        {
         int tpIdx = (int)StringToInteger(StringSubstr(kind, 3));
         ModifyTradeTP(tid, tpIdx, price);
        }
      else if(kind == "SL")
         ModifyTradeSL(tid, price);
      else if(kind == "ENTRY")
        {
         if(m_tr[idx].pending)
           {
            //--- move the pending entry (optionally keeping the RR)
            double dist = MathAbs(m_tr[idx].entry - m_tr[idx].sl);
            m_tr[idx].entry = UTM_NormPrice(m_symbol, price);
            if(g_set.lockRR)
               m_tr[idx].sl = UTM_NormPrice(m_symbol, m_tr[idx].entry - (m_tr[idx].type == POSITION_TYPE_BUY ? dist : -dist));
            else if(MathAbs(m_tr[idx].entry - m_tr[idx].sl) < UTM_Point(m_symbol) * 2.0)
               m_tr[idx].sl = UTM_NormPrice(m_symbol, m_tr[idx].entry - (m_tr[idx].type == POSITION_TYPE_BUY ? dist : -dist));

            m_tr[idx].orderMode = DeriveOrderMode(m_tr[idx].type, m_tr[idx].entry);
            RepricePendingTrade(idx);
           }
         else
           {
            //--- an open position cannot change its entry: snap the line back
            ObjectSetDouble(0, name, OBJPROP_PRICE, 0, m_tr[idx].posEntry);
           }
        }
      return;
     }
  }

//+------------------------------------------------------------------+
//| Drawing helpers                                                   |
//+------------------------------------------------------------------+
void CUtmEngine::CreateLine(const string name, const double price, const color clr,
                            const int style, const int width, const bool selectable, const string text)
  {
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, selectable);
      ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetString(0, name, OBJPROP_TOOLTIP, text);
     }
   if(ObjectGetInteger(0, name, OBJPROP_SELECTED) != 0)
      return;   // do not fight a line that is being dragged

   ObjectSetDouble(0, name, OBJPROP_PRICE, 0, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   if(StringLen(text) > 0)
      ObjectSetString(0, name, OBJPROP_TOOLTIP, text);
  }

void CUtmEngine::CreateLabel(const string name, const int x, const int y, const string text,
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
      ObjectSetString(0, name, OBJPROP_FONT, bold ? "Microsoft YaHei" : "Microsoft YaHei");
     }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, bold ? "Microsoft YaHei" : "Microsoft YaHei");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, UTM_UIFont(size));
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
  }

void CUtmEngine::CreateButton(const string name, const int x, const int y, const int w, const int h,
                              const string text, const color bg, const color clr, const int size)
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
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, UTM_UIFont(size));
  }

void CUtmEngine::PriceToY(const double price, int &y)
  {
   int x = 0;
   y = -1;
   datetime tm = TimeCurrent();
   if(!ChartTimePriceToXY(0, 0, tm, price, x, y))
      y = -1;
  }

//+------------------------------------------------------------------+
//| Draw all trade lines / labels                                     |
//+------------------------------------------------------------------+
void CUtmEngine::DrawAll()
  {
   for(int i = 0; i < m_count; i++)
      DrawTrade(m_tr[i]);

   CleanupOrphans();

   if(m_exec.active)
      DrawExec();
   else
      DeleteExecObjects();

   DrawHud();
  }

void CUtmEngine::DrawTrade(const STrade &t)
  {
   string pfx = UTM_OBJ_PREFIX + "T_" + IntegerToString(t.id) + "_";
   color  sideClr = (t.type == POSITION_TYPE_BUY ? g_style.buy : g_style.sell);

   //--- 入场线
   {
      string nm = pfx + "ENTRY";
      CreateLine(nm, (t.pending ? t.entry : t.posEntry), sideClr,
                 g_style.entryStyle, g_style.entryWidth, t.pending,
                 "入场 " + UTM_FmtPrice(m_symbol, (t.pending ? t.entry : t.posEntry)));
   }

   //--- 止损线
   if(t.sl > 0.0)
     {
      string nm = pfx + "SL";
      CreateLine(nm, t.sl, g_style.sl, g_style.slStyle, g_style.slWidth, true,
                 "止损 " + UTM_FmtPrice(m_symbol, t.sl));
     }

   //--- 止盈线
   for(int i = 0; i < t.tpCount && i < UTM_MAX_TP; i++)
     {
      if(t.tp[i] <= 0.0)
         continue;
      string nm = pfx + "TP_" + IntegerToString(i);
      CreateLine(nm, t.tp[i], g_style.tp, g_style.tpStyle, g_style.tpWidth, true,
                 "止盈" + IntegerToString(i + 1) + " " + UTM_FmtPrice(m_symbol, t.tp[i]));
     }

   //--- 清理多余的止盈线
   for(int i = t.tpCount; i < UTM_MAX_TP; i++)
     {
      string nm = pfx + "TP_" + IntegerToString(i);
      if(ObjectFind(0, nm) >= 0)
         ObjectDelete(0, nm);
     }

   //--- 文字标签
   int chartW = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   int chartH = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);

   int yEntry = -1;
   PriceToY((t.pending ? t.entry : t.posEntry), yEntry);
   if(yEntry < 0 || yEntry > chartH)
     {
      //--- 入场价在当前可视区间之外：把摘要钉在对应的边缘，文字/按钮仍然可用
      double px  = (t.pending ? t.entry : t.posEntry);
      double cur = (t.type == POSITION_TYPE_BUY ? UTM_Bid(m_symbol) : UTM_Ask(m_symbol));
      yEntry = (px > cur ? UTM_UI(30) : chartH - UTM_UI(6));
     }

   int leftX = ContentLeftX();
   int rightX = MathMax(leftX + 260, chartW - 300);

   //--- 止损 / 止盈线自己的文字（持仓与挂单都显示）
      if(t.sl > 0.0)
        {
         int sy = -1;
         PriceToY(t.sl, sy);
         if(sy > 0 && sy < chartH)
            CreateLabel(pfx + "LBL_SL", leftX + UTM_UI(2), (sy > chartH - UTM_UI(60) ? sy - UTM_UI(16) : sy + UTM_UI(3)),
                        "止损 " + DoubleToString(UTM_PriceToPips(m_symbol, MathAbs(t.entry - t.sl)), 1) + " 点",
                        g_style.sl, 7, false);
         else
            ObjectDelete(0, pfx + "LBL_SL");
        }
      else
         ObjectDelete(0, pfx + "LBL_SL");

      for(int i = 0; i < t.tpCount && i < UTM_MAX_TP; i++)
        {
         string nt = pfx + "LBL_TP_" + IntegerToString(i);
         if(t.tp[i] > 0.0)
           {
            int ty = -1;
            PriceToY(t.tp[i], ty);
            if(ty > 0 && ty < chartH)
               CreateLabel(nt, leftX + UTM_UI(2), (ty > chartH - UTM_UI(60) ? ty - UTM_UI(16) : ty + UTM_UI(3)),
                           "止盈" + IntegerToString(i + 1) + "  " +
                           DoubleToString(t.tpRR[i], 2) + "R  " +
                           DoubleToString(t.tpPct[i], 0) + "%",
                           g_style.tp, 7, false);
            else
               ObjectDelete(0, nt);
           }
         else
            ObjectDelete(0, nt);
        }


   string left = "", right = "";

   if(t.pending)
     {
      left = "#" + IntegerToString(t.id) + "  " + UTM_Priv(DoubleToString(t.lot, 2) + " 手") + "  " +
             (t.type == POSITION_TYPE_BUY ? "买入" : "卖出") + " " +
             (t.orderMode == UTM_ORDER_LIMIT ? "限价" : "突破");
      right = "入场 " + UTM_FmtPrice(m_symbol, t.entry);
     }
   else
     {
      double prof = TradeProfit(t);
      double commRate = UTM_CommissionPerLot(g_set);
      if(commRate != 0.0)
         prof -= commRate * TradeVolume(t);
      double bal = UTM_BalanceForRisk(g_set.overrideBalance);
      double pct = (bal > 0.0 ? prof / bal * 100.0 : 0.0);
      double rr = (t.riskMoney > 0.0 ? prof / t.riskMoney : 0.0);
      left = "#" + IntegerToString(t.id) + "  " + UTM_Priv(DoubleToString(t.lot, 2) + " 手") + "  " +
             UTM_Priv((prof >= 0 ? "+" : "") + UTM_FmtMoney(prof) + " (" + DoubleToString(pct, 2) + "%)") +
             "  盈亏比 " + UTM_Priv(UTM_FmtRR(rr));
      right = "止损 " + DoubleToString(UTM_PriceToPips(m_symbol, MathAbs(t.entry - t.sl)), 1) + " 点";
      if(t.tpCount > 0)
        {
         int nxt = (t.tpDone < t.tpCount ? t.tpDone : t.tpCount - 1);
         right += "  |  止盈" + IntegerToString(nxt + 1) + " " +
                  DoubleToString(t.tpRR[nxt], 2) + "R " + DoubleToString(t.tpPct[nxt], 0) + "%";
        }
     }

   if(yEntry > 0 && yEntry < chartH)
     {
      int lx = leftX;
      int ly = yEntry - UTM_UI(26);
      if(ly < 2)
         ly = yEntry + UTM_UI(4);
         CreateLabel(pfx + "LBL_L", lx, ly, left, UTM_CLR_TEXT, 8, false);
      CreateLabel(pfx + "LBL_R", rightX, ly, right, UTM_CLR_TEXT_DIM, 8, false);

      //--- 快捷按钮
      int bx = chartW - UTM_UI(58);
      if(bx < leftX + UTM_UI(20))
         bx = leftX + UTM_UI(20);
      if(!t.pending)
         CreateButton(pfx + "BTN_P", bx, yEntry - UTM_UI(24), UTM_UI(30), UTM_UI(16), "50%", UTM_CLR_BG_ALT, UTM_CLR_TEXT, 7);
      else
         ObjectDelete(0, pfx + "BTN_P");
      CreateButton(pfx + "BTN_X", bx + UTM_UI(32), yEntry - UTM_UI(24), UTM_UI(18), UTM_UI(16), "X",
                   (t.pending ? UTM_CLR_WARN : UTM_CLR_SELL), C'255,255,255', 7);
     }
   else
     {
      ObjectDelete(0, pfx + "LBL_L");
      ObjectDelete(0, pfx + "LBL_R");
      ObjectDelete(0, pfx + "BTN_P");
      ObjectDelete(0, pfx + "BTN_X");
     }
  }

void CUtmEngine::CleanupOrphans()
  {
   int total = ObjectsTotal(0, -1, -1);
   for(int i = total - 1; i >= 0; i--)
     {
      string nm = ObjectName(0, i, -1, -1);
      if(StringFind(nm, UTM_OBJ_PREFIX + "T_") != 0)
         continue;
      string rest = StringSubstr(nm, StringLen(UTM_OBJ_PREFIX + "T_"));
      int us = StringFind(rest, "_");
      if(us <= 0)
         continue;
      long id = StringToInteger(StringSubstr(rest, 0, us));
      if(FindById(id) < 0)
         ObjectDelete(0, nm);
     }
  }

void CUtmEngine::DeleteExecObjects()
  {
   ObjectsDeleteAll(0, UTM_OBJ_PREFIX + "X_");
  }

//+------------------------------------------------------------------+
//| Bottom-left status bar: execution mode + order mode               |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| 左下角状态条：执行模式 + 订单类型                                  |
//+------------------------------------------------------------------+
void CUtmEngine::DrawHud()
  {
   string bg = UTM_OBJ_PREFIX + "HUD_BG";
   string t1 = UTM_OBJ_PREFIX + "HUD_TXT";
   string t2 = UTM_OBJ_PREFIX + "HUD_TXT2";

   bool   active  = m_exec.active;
   string modeTxt = (m_exec.mode == UTM_ORDER_MARKET ? "市价" :
                    (m_exec.mode == UTM_ORDER_LIMIT ? "限价" : "突破"));
   string sideTxt = (m_exec.side == POSITION_TYPE_BUY ? "买入" : "卖出");

   string line1 = "", line2 = "";
   color  bgClr, brClr, txtClr;

   if(active)
     {
      string stageTxt;
      if(m_exec.mode == UTM_ORDER_MARKET)
         stageTxt = "移动止损线，点击左键下单";
      else if(m_exec.stage < 2)
         stageTxt = "第一次左键确定入场价";
      else
         stageTxt = "移动止损线，再次点击挂单";

      line1 = "执行中   " + sideTxt + "   " + modeTxt + "   |   " + stageTxt;
      line2 = "止损 " + DoubleToString(ExecSLPips(), 1) + " 点" +
              "      手数 " + UTM_Priv(DoubleToString(ExecLot(), 2)) +
              "      风险 " + UTM_Priv(UTM_FmtMoney(ExecRisk()));

      bgClr  = C'16,36,32';
      brClr  = UTM_CLR_ACCENT;
      txtClr = UTM_CLR_TEXT;
     }
   else
     {
      line1 = "未执行   " + sideTxt + "   " + modeTxt +
              "   |   按 ESC 开始交易（退格切换订单类型）";
      bgClr  = UTM_CLR_BG;
      brClr  = UTM_CLR_BORDER;
      txtClr = UTM_CLR_TEXT_DIM;
     }

   int cw = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   int ch = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);

   //--- all HUD objects use the upper-left corner so the geometry is predictable
   int h = UTM_UI(active ? 40 : 22);
   int w = UTM_UI(430);
   if(w > cw - UTM_UI(16))
      w = cw - UTM_UI(16);
   if(w < UTM_UI(140))
      w = UTM_UI(140);
   int x = UTM_UI(8);
   //--- when the panel is on the left and reaches the bottom, move the HUD next to it
   int y0 = ch - h - UTM_UI(10);
   if(m_panelOnLeft && m_panelW > 0 && y0 < (m_panelY + m_panelH + UTM_UI(6)))
      x = m_panelX + m_panelW + UTM_UI(14);
   int y = y0;
   if(x + w > cw - UTM_UI(8))
      w = MathMax(UTM_UI(120), cw - UTM_UI(8) - x);
   if(y < 2)
      y = 2;

   if(!g_set.hudBg)
     {
      if(ObjectFind(0, bg) >= 0)
         ObjectDelete(0, bg);
     }
   else
     {
   //--- background behind the text (created first => lowest z-order)
   if(ObjectFind(0, bg) < 0)
     {
      ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bg, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, bg, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, bg, OBJPROP_BACK, false);
      ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
     }
   ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, bg, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, bg, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, bgClr);
   ObjectSetInteger(0, bg, OBJPROP_COLOR, brClr);
   ObjectSetInteger(0, bg, OBJPROP_WIDTH, 1);
     }

   //--- line 1
   if(ObjectFind(0, t1) < 0)
     {
      ObjectCreate(0, t1, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, t1, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, t1, OBJPROP_HIDDEN, true);
      ObjectSetString(0, t1, OBJPROP_FONT, "Microsoft YaHei");
     }
   ObjectSetInteger(0, t1, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, t1, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0, t1, OBJPROP_XDISTANCE, x + UTM_UI(9));
   ObjectSetInteger(0, t1, OBJPROP_YDISTANCE, y + UTM_UI(4));
   ObjectSetString(0, t1, OBJPROP_TEXT, line1);
   ObjectSetInteger(0, t1, OBJPROP_FONTSIZE, UTM_UIFont(10));
   ObjectSetInteger(0, t1, OBJPROP_COLOR, txtClr);

   //--- line 2 (stop loss / lots / risk)
   if(active)
     {
      if(ObjectFind(0, t2) < 0)
        {
         ObjectCreate(0, t2, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, t2, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, t2, OBJPROP_HIDDEN, true);
         ObjectSetString(0, t2, OBJPROP_FONT, "Microsoft YaHei");
        }
      ObjectSetInteger(0, t2, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, t2, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0, t2, OBJPROP_XDISTANCE, x + UTM_UI(9));
      ObjectSetInteger(0, t2, OBJPROP_YDISTANCE, y + UTM_UI(21));
      ObjectSetString(0, t2, OBJPROP_TEXT, line2);
      ObjectSetInteger(0, t2, OBJPROP_FONTSIZE, UTM_UIFont(10));
      ObjectSetInteger(0, t2, OBJPROP_COLOR, UTM_CLR_WARN);
     }
   else if(ObjectFind(0, t2) >= 0)
      ObjectDelete(0, t2);
  }

//+------------------------------------------------------------------+
//| 执行模式的线：入场线（挂单）+ 止损线 + 止盈预览                     |
//+------------------------------------------------------------------+
void CUtmEngine::DrawExec()
  {
   if(!m_exec.active)
      return;

   bool pending    = (m_exec.mode != UTM_ORDER_MARKET);
   bool entryStage = (pending && m_exec.stage < 2);
   bool riskLines  = !entryStage;

   string nmEntry = UTM_OBJ_PREFIX + "X_ENTRY";
   string nmSL    = UTM_OBJ_PREFIX + "X_SL";

   //--- 入场线
   if(pending)
     {
      color ec = (entryStage ? UTM_CLR_ACCENT : g_style.entry);
      CreateLine(nmEntry, m_exec.entry, ec,
                 (entryStage ? STYLE_SOLID : g_style.entryStyle), g_style.entryWidth, false,
                 "入场 " + UTM_FmtPrice(m_symbol, m_exec.entry));
     }
   else if(ObjectFind(0, nmEntry) >= 0)
      ObjectDelete(0, nmEntry);

   //--- 止损线
   if(riskLines)
      CreateLine(nmSL, m_exec.sl, g_style.sl, g_style.slStyle, g_style.slWidth, false,
                 "止损 " + UTM_FmtPrice(m_symbol, m_exec.sl));
   else if(ObjectFind(0, nmSL) >= 0)
      ObjectDelete(0, nmSL);

   //--- 止盈预览
   for(int i = 0; i < UTM_MAX_TP; i++)
     {
      string nm  = UTM_OBJ_PREFIX + "X_TP_" + IntegerToString(i);
      string nml = UTM_OBJ_PREFIX + "X_LBL_TP_" + IntegerToString(i);
      bool   on  = (riskLines && i < m_exec.tpCount && m_exec.tp[i] > 0.0 && g_set.tpPct[i] > 0.0);

      if(on)
        {
         CreateLine(nm, m_exec.tp[i], g_style.tp, g_style.tpStyle, g_style.tpWidth, true,
                    "止盈" + IntegerToString(i + 1) + "  " + DoubleToString(g_set.tpRR[i], 2) + "R  " +
                    DoubleToString(g_set.tpPct[i], 0) + "%");

         int ty = -1;
         PriceToY(m_exec.tp[i], ty);
         if(ty > 0)
      CreateLabel(nml, ContentLeftX(), ty + UTM_UI(3),
                        "止盈" + IntegerToString(i + 1) + "  " + DoubleToString(g_set.tpRR[i], 2) + "R  " +
                        DoubleToString(g_set.tpPct[i], 0) + "%",
                        g_style.tp, 7, false);
         else if(ObjectFind(0, nml) >= 0)
            ObjectDelete(0, nml);
        }
      else
        {
         if(ObjectFind(0, nm) >= 0)
            ObjectDelete(0, nm);
         if(ObjectFind(0, nml) >= 0)
            ObjectDelete(0, nml);
        }
     }

   //--- 文字
   int slY = -1, enY = -1;
   PriceToY(m_exec.sl, slY);
   PriceToY(m_exec.entry, enY);

   string nmLblSL = UTM_OBJ_PREFIX + "X_LBL_SL";
   string nmLblEN = UTM_OBJ_PREFIX + "X_LBL_EN";

   if(riskLines && slY > 0)
     {
      string slInfo = "止损 " + DoubleToString(ExecSLPips(), 1) + " 点   手数 " +
                      UTM_Priv(DoubleToString(ExecLot(), 2)) + "   风险 " + UTM_Priv(UTM_FmtMoney(ExecRisk()));
      if(m_exec.follow)
         slInfo += "   ← 跟随鼠标";
      CreateLabel(nmLblSL, ContentLeftX(), slY + UTM_UI(4), slInfo, g_style.sl, 8, true);
     }
   else if(ObjectFind(0, nmLblSL) >= 0)
      ObjectDelete(0, nmLblSL);

   if(pending && enY > 0)
     {
      string enInfo = (entryStage
                       ? "点击确定入场价   " + UTM_FmtPrice(m_symbol, m_exec.entry)
                       : "入场 " + UTM_FmtPrice(m_symbol, m_exec.entry) +
                         "   手数 " + UTM_Priv(DoubleToString(ExecLot(), 2)));
      CreateLabel(nmLblEN, ContentLeftX(), enY - UTM_UI(18), enInfo,
                  (entryStage ? UTM_CLR_ACCENT : UTM_CLR_TEXT), 8, true);
     }
   else if(ObjectFind(0, nmLblEN) >= 0)
      ObjectDelete(0, nmLblEN);
  }

#endif // __UTM_ENGINE_MQH__
//+------------------------------------------------------------------+