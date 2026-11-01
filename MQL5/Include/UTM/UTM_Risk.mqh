//+------------------------------------------------------------------+
//|                                                    UTM_Risk.mqh  |
//|   Stop loss sizing, lot calculation and risk based protections    |
//+------------------------------------------------------------------+
#ifndef __UTM_RISK_MQH__
#define __UTM_RISK_MQH__

#include "UTM_Defines.mqh"
#include "UTM_Utils.mqh"


//+------------------------------------------------------------------+
//| Stop loss distance in price for the current settings              |
//+------------------------------------------------------------------+
double Risk_SLDistance(const string sym, SUtmSettings &s)
  {
   double dist = 0.0;

   if(s.slUnit == UTM_SL_PIPS)
      dist = s.slSize * UTM_PipSize(sym);
   else
      dist = s.slSize * UTM_Point(sym);

   //--- min / max are expressed in the same unit as the SL size
   if(s.slMin > 0.0)
     {
      double mn = (s.slUnit == UTM_SL_PIPS ? s.slMin * UTM_PipSize(sym) : s.slMin * UTM_Point(sym));
      if(dist < mn)
         dist = mn;
     }
   if(s.slMax > 0.0)
     {
      double mx = (s.slUnit == UTM_SL_PIPS ? s.slMax * UTM_PipSize(sym) : s.slMax * UTM_Point(sym));
      if(dist > mx)
         dist = mx;
     }

   return dist;
  }

//+------------------------------------------------------------------+
//| Lot size for a given risk distance                                |
//| riskMoney  - result: money at risk                                |
//| returns normalized volume (0 on failure)                          |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| 每手需要计入风险的成本：止损亏损 + 佣金（可选）                     |
//+------------------------------------------------------------------+
double Risk_CostPerLot(const string sym, const double distance, SUtmSettings &s)
  {
   double cost = UTM_LossPerLot(sym, distance);
   double comm = UTM_CommissionPerLot(s);
   if(s.commissionInRisk && comm != 0.0)
      cost += comm;
   return cost;
  }

//+------------------------------------------------------------------+
//| Lot size for a given risk distance                                |
//| riskMoney  - result: money at risk (incl. commission when on)     |
//| returns normalized volume (0 on failure)                          |
//+------------------------------------------------------------------+
double Risk_CalcLot(const string sym, const double entry, const double sl,
                    SUtmSettings &s, const double balance,
                    double &riskMoney, double &distance)
  {
   riskMoney = 0.0;
   distance  = MathAbs(entry - sl);

   double costPerLot = Risk_CostPerLot(sym, distance, s);
   double lot = 0.0;

   if(s.riskMode == UTM_RISK_LOT)
     {
      lot = s.riskValue;
      if(lot <= 0.0)
         lot = UTM_VolumeMin(sym);
      riskMoney = costPerLot * lot;
     }
   else
     {
      riskMoney = (s.riskMode == UTM_RISK_PERCENT ? balance * s.riskValue / 100.0 : s.riskValue);
      if(riskMoney <= 0.0)
         return 0.0;
      if(costPerLot <= 0.0)
         return 0.0;

      lot = riskMoney / costPerLot;
     }

   //--- hard cap from settings
   if(s.maxLot > 0.0 && lot > s.maxLot)
      lot = s.maxLot;

   //--- broker maximum (unless bypass is enabled - splitting is done later)
   double bmax = UTM_VolumeMax(sym);
   if(!s.bypassMaxLot && lot > bmax)
      lot = bmax;

   lot = UTM_NormLotEx(sym, lot, !s.bypassMaxLot);

   //--- never risk more than the free margin allows
   int guard = 0;
   while(lot > UTM_VolumeMin(sym) && !UTM_CheckMargin(sym, lot, entry > sl ? POSITION_TYPE_BUY : POSITION_TYPE_SELL) && guard < 32)
     {
      lot = UTM_NormLotEx(sym, lot * 0.5, !s.bypassMaxLot);
      guard++;
     }

   //--- report the real amount at risk for the final volume
   riskMoney = costPerLot * lot;
   return lot;
  }

//+------------------------------------------------------------------+
//| Money at risk for a volume and distance                           |
//+------------------------------------------------------------------+
double Risk_MoneyAtRisk(const string sym, const double lot, const double distance)
  {
   return UTM_LossPerLot(sym, distance) * lot;
  }

//+------------------------------------------------------------------+
//| Money at risk including the commission (when enabled)             |
//+------------------------------------------------------------------+
double Risk_TotalAtRisk(const string sym, const double lot, const double distance, SUtmSettings &s)
  {
   double r = UTM_LossPerLot(sym, distance) * lot;
   double comm = UTM_CommissionPerLot(s);
   if(s.commissionInRisk && comm != 0.0)
      r += comm * lot;
   return r;
  }

//| Equity stop protection                                            |
//+------------------------------------------------------------------+
bool Risk_EquityOK(SUtmSettings &s)
  {
   if(s.equityStop <= 0.0)
      return true;
   return (AccountInfoDouble(ACCOUNT_EQUITY) > s.equityStop);
  }

//+------------------------------------------------------------------+
//| Abnormal spread protection (uses the EMA smoothed spread)         |
//+------------------------------------------------------------------+
bool Risk_SpreadOK(const string sym, SUtmSettings &s, const double emaSpread)
  {
   if(s.abnormalSpread <= 0.0 || emaSpread <= 0.0)
      return true;
   double raw = UTM_RawSpread(sym);
   return (raw <= emaSpread * s.abnormalSpread);
  }

#endif // __UTM_RISK_MQH__
//+------------------------------------------------------------------+