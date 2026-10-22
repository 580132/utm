//+------------------------------------------------------------------+
//|                                                  UTM_Manager.mq5 |
//|   UTM Manager - manual trade execution and management utility     |
//|                                                                  |
//|   Features:                                                       |
//|   - click / drag trade planning with entry, SL and 4 partial TPs  |
//|   - automatic lot calculation from risk % / money / fixed lot     |
//|   - break-even, RR trailing stop, formula management             |
//|   - spread handling: spread factor, ignore spread, invisible mode |
//|   - broker max lot bypass (order splitting)                       |
//|   - settings profiles, trade insights                           |
//+------------------------------------------------------------------+
#property copyright "UTM Manager"
#property version   "1.00"
#property description "UTM 交易管理器 - MT5 手动下单与持仓管理工具"
#property description "拖动入场/止损/止盈线，自动手数计算，分批止盈，"
#property description "忽略点差执行，本地跟单。"

#include <UTM/UTM_Defines.mqh>
#include <UTM/UTM_Utils.mqh>
#include <UTM/UTM_Settings.mqh>
#include <UTM/UTM_Risk.mqh>
#include <UTM/UTM_Engine.mqh>
#include <UTM/UTM_Panel.mqh>
#include <UTM/UTM_Insights.mqh>

//--- globals
CUtmEngine g_engine;
CUtmPanel  g_panel;

//+------------------------------------------------------------------+
//| inputs                                                            |
//+------------------------------------------------------------------+
input group "=== UTM 交易管理器 : 常规 ==="
input int                   InpMagic             = 93171;         // 魔术号（每个图表唯一）
input int                   InpDeviation         = 20;            // 允许滑点（点）
input string                InpTradeSymbol       = "";            // 交易品种（留空 = 当前图表）
input bool                  InpUseProfile        = true;          // 启动时读取已保存的配置
input bool                  InpForceInputs       = false;         // 忽略已保存配置（用当前 EA 参数覆盖）
input string                InpProfile           = "Default";     // 配置文件名
input bool                  InpLoadPanel         = true;          // 启动时显示面板

input group "=== UTM 交易管理器 : 风险 ==="
input ENUM_UTM_RISK_MODE    InpRiskMode          = UTM_RISK_PERCENT; // 风险模式
input double                InpRiskValue         = 1.0;           // 风险数值（% / 金额 / 手数）
input double                InpMaxLot            = 0.0;           // 最大手数（0 = 不限）
input double                InpEquityStop        = 0.0;           // 净值止损线（0 = 关闭）
input double                InpAbnormalSpread    = 2.0;           // 异常点差倍数
input bool                  InpBypassMaxLot      = false;         // 超过经纪商手数上限时拆单
input double                InpOverrideBalance   = 0.0;           // 覆盖账户余额（0 = 实际）

input group "=== UTM 交易管理器 : 止损 ==="
input bool                  InpFixedSL           = false;         // 使用固定止损
input double                InpSLSize            = 20.0;          // 止损大小
input ENUM_UTM_SL_UNIT      InpSLUnit            = UTM_SL_PIPS;   // 止损单位
input double                InpSLMin             = 0.0;           // 最小止损
input double                InpSLMax             = 0.0;           // 最大止损
input int                   InpATRPeriod         = 14;            // ATR 周期
input bool                  InpLockRR            = true;          // 拖动入场线时锁定盈亏比

input group "=== UTM 交易管理器 : 止盈 ==="
input double                InpTP1RR             = 1.0;           // 止盈1 盈亏比
input double                InpTP1Pct            = 100.0;         // 止盈1 平仓%
input double                InpTP2RR             = 2.0;           // 止盈2 盈亏比
input double                InpTP2Pct            = 0.0;           // 止盈2 平仓%
input double                InpTP3RR             = 3.0;           // 止盈3 盈亏比
input double                InpTP3Pct            = 0.0;           // 止盈3 平仓%
input double                InpTP4RR             = 4.0;           // 止盈4 盈亏比
input double                InpTP4Pct            = 0.0;           // 止盈4 平仓%
input bool                  InpTrailingTP        = false;         // 移动止盈
input double                InpTrailTPRR         = 1.0;           // 移动止盈步长（R）
input double                InpTrailTPPct        = 25.0;          // 移动止盈每步平仓%
input double                InpBEPlusRR          = 0.0;           // 保本额外锁定的盈亏比

input group "=== UTM 交易管理器 : 持仓管理 ==="
input string                InpFormula           = "";            // 交易管理公式
input bool                  InpRemovePendingOnSL = true;          // 先触止损时撤销挂单

input group "=== UTM 交易管理器 : 点差 ==="
input ENUM_UTM_SPREAD_MODE  InpSpreadMode        = UTM_SPREAD_OFF; // 点差模式
input double                InpSpreadFactor      = 0.0;           // 点差因子（pip，0 = 自动均值）
input double                InpEMASpread         = 0.01;          // 点差均值平滑系数
input bool                  InpFailsafeSL        = false;         // 兜底止损（2R）
input bool                  InpFormulaOrigEntry  = true;          // 公式按原始入场价计算
input bool                  InpTPOrigEntry       = true;          // 止盈按原始入场价计算


input group "=== UTM 交易管理器 : 线条样式 ==="
input color                 InpEntryColor        = C'180,190,205';    // 入场线颜色（挂单预览）
input ENUM_LINE_STYLE       InpEntryStyle        = STYLE_DASHDOT;     // 入场线类型
input int                   InpEntryWidth        = 2;                 // 入场线粗细
input color                 InpBuyColor          = C'70,160,255';    // 多单入场线颜色
input color                 InpSellColor         = C'240,110,110';   // 空单入场线颜色
input color                 InpSLColor           = C'230,120,90';    // 止损线颜色
input ENUM_LINE_STYLE       InpSLStyle           = STYLE_DASHDOT;     // 止损线类型
input int                   InpSLWidth           = 2;                 // 止损线粗细
input color                 InpTPColor           = C'80,190,140';    // 止盈线颜色
input ENUM_LINE_STYLE       InpTPStyle           = STYLE_DOT;         // 止盈线类型
input int                   InpTPWidth           = 1;                 // 止盈线粗细

input group "=== UTM 交易管理器 : 其它 ==="
input double                InpCommissionPerLot = 0.0;           // 每手佣金（往返）
input bool                  InpCommissionInRisk = false;         // 佣金计入风险（影响手数）
input bool                  InpMemorySave       = false;         // 省内存模式
input bool                  InpSounds           = true;          // 成交提示音
input bool                  InpHudBackground    = true;          // 左下角状态条显示背景框

//+------------------------------------------------------------------+
//| 把输入参数复制到运行时设置                                         |
//+------------------------------------------------------------------+
void LoadInputs()
  {
   g_set.riskMode         = (int)InpRiskMode;
   g_set.riskValue        = InpRiskValue;
   g_set.maxLot           = InpMaxLot;
   g_set.equityStop       = InpEquityStop;
   g_set.abnormalSpread   = InpAbnormalSpread;
   g_set.bypassMaxLot     = InpBypassMaxLot;
   g_set.overrideBalance  = InpOverrideBalance;

   g_set.fixedSL          = InpFixedSL;
   g_set.slSize           = InpSLSize;
   g_set.slUnit           = (int)InpSLUnit;
   g_set.slMin            = InpSLMin;
   g_set.slMax            = InpSLMax;
   g_set.atrPeriod        = InpATRPeriod;
   g_set.lockRR           = InpLockRR;

   g_set.tpRR[0] = InpTP1RR;  g_set.tpPct[0] = InpTP1Pct;
   g_set.tpRR[1] = InpTP2RR;  g_set.tpPct[1] = InpTP2Pct;
   g_set.tpRR[2] = InpTP3RR;  g_set.tpPct[2] = InpTP3Pct;
   g_set.tpRR[3] = InpTP4RR;  g_set.tpPct[3] = InpTP4Pct;
   g_set.trailingTP = InpTrailingTP;
   g_set.trailTPRR  = InpTrailTPRR;
   g_set.trailTPPct = InpTrailTPPct;
   g_set.beOffsetRR = InpBEPlusRR;

   g_set.formula          = InpFormula;
   g_set.removePendingOnSL = InpRemovePendingOnSL;

   g_set.spreadMode       = (int)InpSpreadMode;
   g_set.spreadFactor     = InpSpreadFactor;
   g_set.emaSpread        = InpEMASpread;
   g_set.failsafeSL       = InpFailsafeSL;
   g_set.formulaOrigEntry = InpFormulaOrigEntry;
   g_set.tpOrigEntry      = InpTPOrigEntry;


   g_set.commissionPerLot = InpCommissionPerLot;
   g_set.commissionInRisk = InpCommissionInRisk;
   g_set.memorySave       = InpMemorySave;
   g_set.sounds           = InpSounds;
   g_set.hudBg            = InpHudBackground;
   g_set.tradeSymbol      = InpTradeSymbol;
   g_set.profile          = InpProfile;
   g_set.panelVisible     = InpLoadPanel;

   //--- TP count from the percentages
   int cnt = 0;
   for(int i = 0; i < UTM_MAX_TP; i++)
      if(g_set.tpPct[i] > 0.0)
        {
         cnt = i + 1;
         if(g_set.tpRR[i] <= 0.0)
            g_set.tpRR[i] = 1.0;
        }
   g_set.tpCount = (cnt < 1 ? 1 : cnt);
  }

//+------------------------------------------------------------------+
//| Expert initialization                                             |
//+------------------------------------------------------------------+
int OnInit()
  {
   UTM_SetDefaults(g_set);
   LoadInputs();

   //--- fingerprint of the current EA inputs
   g_inputSig = UTM_SettingsSignature(g_set);

   //--- the profile saved last wins (a rename in the panel survives restarts)
   string prof   = InpProfile;
   string active = UTM_ReadActiveProfile();
   if(active != "" &&
      (FileIsExist(UTM_SettingsFileName(active), FILE_COMMON) || FileIsExist(UTM_SettingsFileName(active))))
      prof = active;

   bool loaded = false;
   if(InpUseProfile && !InpForceInputs)
     {
      g_set.profile = prof;
      string fileSig = UTM_ReadInputSig(prof);
      if(fileSig == "" || fileSig == g_inputSig)
         loaded = UTM_LoadSettings(g_set);
      else
        {
         //--- the EA inputs were changed: keep the old file as a backup
         UTM_BackupProfile(prof);
         Print("[UTM] EA 参数已变更：使用当前参数，旧配置备份为 ", prof, ".ini.bak");
        }
     }

   //--- keep the identity inputs, then persist the effective values
   g_set.tradeSymbol = InpTradeSymbol;
   g_set.profile     = prof;
   UTM_SaveSettings(g_set);

   if(loaded)
      Print("[UTM] 已读取配置：", g_set.profile, " (", g_inputSig, ")");
   else
      Print("[UTM] 已保存当前参数：", g_set.profile, " (", g_inputSig, ")");

   string origin = "";
   string sym = UTM_ResolveSymbol(_Symbol, g_set.tradeSymbol, origin);
   if(!UTM_IsTradableSymbol(sym))
     {
      Print("[UTM] 错误：品种不可交易：", sym, "（图表：", _Symbol, "）");
      Alert("UTM：品种 ", sym, " 不可交易，请在参数中手动指定交易品种。");
      return INIT_FAILED;
     }
   if(origin != "chart")
      Print("[UTM] 交易品种解析为 ", sym, "（", origin, "）");

   //--- avoid MT5 trade levels fighting with the manager lines
   ChartSetInteger(0, CHART_SHOW_TRADE_LEVELS, false);
   ChartSetInteger(0, CHART_SHIFT, true);
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, false);   // enabled in execution mode

   if(!g_engine.Init(sym, _Symbol, InpMagic, InpDeviation))
      return INIT_FAILED;

   g_panel.Init(&g_engine);

   EventSetMillisecondTimer(250);
   g_panel.Refresh();
   ChartRedraw();

   Print("[UTM] 管理器已启动 ", sym, " 魔术号 ", InpMagic,
         "（", (UTM_IsHedging() ? "对冲" : "净额"), "账户）");
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization                                           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   g_engine.Deinit();
   UTM_SaveSettings(g_set);
   g_panel.Destroy();
   ObjectsDeleteAll(0, UTM_OBJ_PREFIX);
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| Expert tick                                                       |
//+------------------------------------------------------------------+
void OnTick()
  {
   g_engine.OnTick();
  }

//+------------------------------------------------------------------+
//| timer                                                             |
//+------------------------------------------------------------------+
void OnTimer()
  {
   g_engine.OnTimer();
   if(UTM_VisualMode())
     {
      g_panel.Refresh();
      ChartRedraw();
     }
  }

//+------------------------------------------------------------------+
//| chart events                                                      |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(id == CHARTEVENT_CHART_CHANGE)
     {
      g_panel.Sync();   // rebuilt once by the timer, not on every drag event
      return;
     }

   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      if(g_panel.IsPanelObject(sparam))
        {
         g_panel.OnClick(sparam);
         UTM_SaveSettings(g_set);
         g_panel.Refresh();
         ChartRedraw();
         return;
        }
      if(StringFind(sparam, UTM_OBJ_PREFIX + "T_") == 0)
        {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         g_engine.OnObjectClick(sparam);
         ChartRedraw();
         return;
        }
      return;
     }

   if(id == CHARTEVENT_OBJECT_ENDEDIT)
     {
      if(g_panel.IsPanelObject(sparam))
        {
         g_panel.OnEndEdit(sparam);
         UTM_SaveSettings(g_set);
         g_panel.Refresh();
         ChartRedraw();
         return;
        }
      return;
     }

   if(id == CHARTEVENT_CLICK)
     {
      //--- ignore clicks that land on the panel
      if(g_panel.HitTest((int)lparam, (int)dparam))
         return;
      g_engine.OnChartEvent(id, lparam, dparam, sparam);
      return;
     }

   if(id == CHARTEVENT_MOUSE_MOVE)
     {
      //--- never drag the execution lines while the cursor is on the panel
      if(g_panel.HitTest((int)lparam, (int)dparam))
         return;
      g_engine.OnChartEvent(id, lparam, dparam, sparam);
      return;
     }

   g_engine.OnChartEvent(id, lparam, dparam, sparam);
  }
//+------------------------------------------------------------------+