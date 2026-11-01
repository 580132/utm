//+------------------------------------------------------------------+
//|                                                UTM_Settings.mqh   |
//|   Settings container: defaults, save / load, shared profiles      |
//+------------------------------------------------------------------+
#ifndef __UTM_SETTINGS_MQH__
#define __UTM_SETTINGS_MQH__

#include "UTM_Defines.mqh"
#include "UTM_Utils.mqh"

#define UTM_SETTINGS_FOLDER "UTM"

//--- global runtime settings (single source of truth for the panel)
SUtmSettings g_set;
SUtmStyle    g_style;

//--- 隐私模式：把余额 / 净值 / 盈亏等金额换成星号
string UTM_Priv(const string s)
  {
   return (g_set.privacyMode ? "****" : s);
  }

//+------------------------------------------------------------------+
//| Line style defaults                                               |
//+------------------------------------------------------------------+
void UTM_SetStyleDefaults(SUtmStyle &st)
  {
   st.entry      = UTM_CLR_ENTRY;
   st.buy        = UTM_CLR_LINE_BUY;
   st.sell       = UTM_CLR_LINE_SELL;
   st.sl         = UTM_CLR_SL;
   st.tp         = UTM_CLR_TP;
   st.entryStyle = STYLE_SOLID;
   st.slStyle    = STYLE_DASHDOT;
   st.tpStyle    = STYLE_DOT;
   st.entryWidth = 2;
   st.slWidth    = 2;
   st.tpWidth    = 1;
  }

//+------------------------------------------------------------------+
//| Defaults (overwritten from the EA inputs on OnInit)              |
//+------------------------------------------------------------------+
//--- fingerprint of the EA inputs the settings were last saved with
string g_inputSig = "";

//--- tests may enable file access from the strategy tester
bool g_allowTesterSettings = false;

//+------------------------------------------------------------------+
//| 32-bit FNV-1a hash of a string                                    |
//+------------------------------------------------------------------+
uint UTM_Hash(const string text)
  {
   uint h = 2166136261;
   int  n = StringLen(text);
   for(int i = 0; i < n; i++)
     {
      h ^= (uint)StringGetCharacter(text, i);
      h *= 16777619;
     }
   return h;
  }

//+------------------------------------------------------------------+
//| Fingerprint of every value that comes from the EA inputs          |
//+------------------------------------------------------------------+
string UTM_SettingsSignature(SUtmSettings &s)
  {
   string t = "";
   t += IntegerToString(s.riskMode) + "|" + DoubleToString(s.riskValue, 4) + "|";
   t += DoubleToString(s.maxLot, 4) + "|" + DoubleToString(s.equityStop, 2) + "|";
   t += DoubleToString(s.abnormalSpread, 3) + "|" + IntegerToString(s.bypassMaxLot ? 1 : 0) + "|";
   t += DoubleToString(s.overrideBalance, 2) + "|";
   t += IntegerToString(s.fixedSL ? 1 : 0) + "|" + DoubleToString(s.slSize, 2) + "|";
   t += IntegerToString(s.slUnit) + "|" + DoubleToString(s.slMin, 2) + "|";
   t += DoubleToString(s.slMax, 2) + "|" + IntegerToString(s.atrPeriod) + "|";
   t += IntegerToString(s.lockRR ? 1 : 0) + "|" + IntegerToString(s.tpCount) + "|";
   for(int i = 0; i < UTM_MAX_TP; i++)
      t += DoubleToString(s.tpRR[i], 3) + "," + DoubleToString(s.tpPct[i], 2) + ";";
   t += IntegerToString(s.trailingTP ? 1 : 0) + "|" + DoubleToString(s.trailTPRR, 3) + "|";
   t += DoubleToString(s.trailTPPct, 2) + "|" + DoubleToString(s.beOffsetRR, 3) + "|";
   t += s.formula + "|" + IntegerToString(s.removePendingOnSL ? 1 : 0) + "|";
   t += IntegerToString(s.spreadMode) + "|" + DoubleToString(s.spreadFactor, 3) + "|";
   t += DoubleToString(s.emaSpread, 5) + "|" + IntegerToString(s.failsafeSL ? 1 : 0) + "|";
   t += IntegerToString(s.formulaOrigEntry ? 1 : 0) + "|" + IntegerToString(s.tpOrigEntry ? 1 : 0) + "|";
   t += DoubleToString(s.commissionPerLot, 3) + "|" + IntegerToString(s.commissionInRisk ? 1 : 0) + "|";
   t += IntegerToString(s.memorySave ? 1 : 0) + "|" + IntegerToString(s.sounds ? 1 : 0) + "|";
   t += IntegerToString(s.hudBg ? 1 : 0) + "|" + s.tradeSymbol + "|";
   t += IntegerToString((int)g_style.entry) + "|" + IntegerToString(g_style.entryStyle) + "|";
   t += IntegerToString(g_style.entryWidth) + "|" + IntegerToString((int)g_style.buy) + "|";
   t += IntegerToString((int)g_style.sell) + "|" + IntegerToString((int)g_style.sl) + "|";
   t += IntegerToString(g_style.slStyle) + "|" + IntegerToString(g_style.slWidth) + "|";
   t += IntegerToString((int)g_style.tp) + "|" + IntegerToString(g_style.tpStyle) + "|";
   t += IntegerToString(g_style.tpWidth);

   return StringFormat("%08X", UTM_Hash(t));
  }

//+------------------------------------------------------------------+
//| Read the input fingerprint stored in a profile                    |
//+------------------------------------------------------------------+
string UTM_ReadInputSig(const string profile)
  {
   string name = UTM_SettingsFileName(profile);
   int h = UTM_OpenFileForRead(name);
   if(h == INVALID_HANDLE)
      return "";

   string sig = "";
   while(!FileIsEnding(h))
     {
      string line = FileReadString(h);
      if(StringFind(line, "inputSig=") == 0)
        {
         sig = StringSubstr(line, 9);
         break;
        }
     }
   FileClose(h);
   return sig;
  }
//+------------------------------------------------------------------+
//| Remember / read the profile that was saved last (common folder)   |
//+------------------------------------------------------------------+
void UTM_WriteActiveProfile(const string profile)
  {
   UTM_EnsureFolder(UTM_SETTINGS_FOLDER, true);
   string name = UTM_SETTINGS_FOLDER + "\\active_profile.txt";
   int h = UTM_OpenFileForWrite(name);
   if(h == INVALID_HANDLE)
      return;
   FileWrite(h, profile);
   FileClose(h);
  }

string UTM_ReadActiveProfile()
  {
   string name = UTM_SETTINGS_FOLDER + "\\active_profile.txt";
   int h = UTM_OpenFileForRead(name);
   if(h == INVALID_HANDLE)
      return "";
   string profile = "";
   if(!FileIsEnding(h))
      profile = FileReadString(h);
   FileClose(h);
   return profile;
  }

//+------------------------------------------------------------------+
//| Keep a .bak copy of the previous profile before overwriting       |
//+------------------------------------------------------------------+
void UTM_BackupProfile(const string profile)
  {
   string name = UTM_SettingsFileName(profile);
   if(!FileIsExist(name, FILE_COMMON) && !FileIsExist(name))
      return;

   string bak = name + ".bak";
   FileDelete(bak, FILE_COMMON);
   if(!FileCopy(name, FILE_COMMON, bak, FILE_COMMON))
      FileCopy(name, 0, bak, 0);
    }


void UTM_SetDefaults(SUtmSettings &s)
  {
   UTM_SetStyleDefaults(g_style);

   s.riskMode        = UTM_RISK_PERCENT;
   s.riskValue       = 1.0;
   s.maxLot          = 0.0;
   s.equityStop      = 0.0;
   s.abnormalSpread  = 2.0;
   s.bypassMaxLot    = false;
   s.overrideBalance = 0.0;

   s.fixedSL         = false;
   s.slSize          = 20.0;
   s.slUnit          = UTM_SL_PIPS;
   s.slMin           = 0.0;
   s.slMax           = 0.0;
   s.atrPeriod       = 14;
   s.lockRR          = true;

   s.tpCount         = 1;
   for(int i = 0; i < UTM_MAX_TP; i++)
     {
      s.tpRR[i]  = (double)(i + 1);
      s.tpPct[i] = (i == 0 ? 100.0 : 0.0);
     }
   s.trailingTP      = false;
   s.trailTPRR       = 1.0;
   s.trailTPPct      = 25.0;

   s.beOffsetRR      = 0.0;
   s.formula         = "";
   s.removePendingOnSL = true;

   s.spreadMode      = UTM_SPREAD_OFF;
   s.spreadFactor    = 0.0;
   s.emaSpread       = 0.01;
   s.failsafeSL      = false;
   s.formulaOrigEntry = true;
   s.tpOrigEntry      = true;


   s.memorySave      = false;
   s.sounds          = true;
   s.profile         = "Default";
   s.tradeSymbol     = "";
   s.commissionPerLot = 0.0;
   s.commissionInRisk = false;
   s.commissionAuto  = true;
   s.serverSplitTP   = true;
   s.defaultOrderMode = UTM_ORDER_MARKET;
   s.privacyMode      = false;
   s.panelX          = -1;
   s.panelY          = 24;
   s.panelVisible    = true;
   s.hudBg           = true;
  }

//+------------------------------------------------------------------+
//| File name helpers                                                 |
//+------------------------------------------------------------------+
string UTM_SettingsFileName(const string profile)
  {
   string p = profile;
   if(p == "")
      p = "Default";
   StringReplace(p, "\\", "_");
   StringReplace(p, "/", "_");
   StringReplace(p, ":", "_");
   StringReplace(p, "*", "_");
   StringReplace(p, "?", "_");
   StringReplace(p, "\"", "_");
   StringReplace(p, "<", "_");
   StringReplace(p, ">", "_");
   StringReplace(p, "|", "_");
   return UTM_SETTINGS_FOLDER + "\\settings_" + p + ".ini";
  }

int UTM_OpenFileForWrite(const string name)
  {
   int h = FileOpen(name, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
   if(h == INVALID_HANDLE)
      h = FileOpen(name, FILE_WRITE | FILE_TXT | FILE_ANSI);
   return h;
  }

int UTM_OpenFileForRead(const string name)
  {
   int h = FileOpen(name, FILE_READ | FILE_TXT | FILE_ANSI | FILE_COMMON);
   if(h == INVALID_HANDLE)
      h = FileOpen(name, FILE_READ | FILE_TXT | FILE_ANSI);
   return h;
  }

//+------------------------------------------------------------------+
//| Save settings (last save wins - shared between instances)         |
//+------------------------------------------------------------------+
bool UTM_SaveSettings(SUtmSettings &s)
  {
   //--- never touch the live profile files from the strategy tester
   if((bool)MQLInfoInteger(MQL_TESTER) && !g_allowTesterSettings)
      return false;

   UTM_EnsureFolder(UTM_SETTINGS_FOLDER, true);
   int h = UTM_OpenFileForWrite(UTM_SettingsFileName(s.profile));
   if(h == INVALID_HANDLE)
      return false;

   FileWrite(h, "version=" + UTM_VERSION);
   FileWrite(h, "inputSig=" + g_inputSig);
   FileWrite(h, "riskMode=" + IntegerToString(s.riskMode));
   FileWrite(h, "riskValue=" + DoubleToString(s.riskValue, 4));
   FileWrite(h, "maxLot=" + DoubleToString(s.maxLot, 4));
   FileWrite(h, "equityStop=" + DoubleToString(s.equityStop, 2));
   FileWrite(h, "abnormalSpread=" + DoubleToString(s.abnormalSpread, 3));
   FileWrite(h, "bypassMaxLot=" + IntegerToString(s.bypassMaxLot ? 1 : 0));
   FileWrite(h, "overrideBalance=" + DoubleToString(s.overrideBalance, 2));
   FileWrite(h, "fixedSL=" + IntegerToString(s.fixedSL ? 1 : 0));
   FileWrite(h, "slSize=" + DoubleToString(s.slSize, 2));
   FileWrite(h, "slUnit=" + IntegerToString(s.slUnit));
   FileWrite(h, "slMin=" + DoubleToString(s.slMin, 2));
   FileWrite(h, "slMax=" + DoubleToString(s.slMax, 2));
   FileWrite(h, "atrPeriod=" + IntegerToString(s.atrPeriod));
   FileWrite(h, "lockRR=" + IntegerToString(s.lockRR ? 1 : 0));
   FileWrite(h, "tpCount=" + IntegerToString(s.tpCount));
   for(int i = 0; i < UTM_MAX_TP; i++)
     {
      FileWrite(h, "tpRR" + IntegerToString(i) + "=" + DoubleToString(s.tpRR[i], 3));
      FileWrite(h, "tpPct" + IntegerToString(i) + "=" + DoubleToString(s.tpPct[i], 2));
     }
   FileWrite(h, "trailingTP=" + IntegerToString(s.trailingTP ? 1 : 0));
   FileWrite(h, "trailTPRR=" + DoubleToString(s.trailTPRR, 3));
   FileWrite(h, "trailTPPct=" + DoubleToString(s.trailTPPct, 2));
   FileWrite(h, "beOffsetRR=" + DoubleToString(s.beOffsetRR, 3));
   string frm = s.formula;
   StringReplace(frm, "\r", "");
   StringReplace(frm, "\n", "\\n");
   FileWrite(h, "formula=" + frm);
   FileWrite(h, "removePendingOnSL=" + IntegerToString(s.removePendingOnSL ? 1 : 0));
   FileWrite(h, "spreadMode=" + IntegerToString(s.spreadMode));
   FileWrite(h, "spreadFactor=" + DoubleToString(s.spreadFactor, 3));
   FileWrite(h, "emaSpread=" + DoubleToString(s.emaSpread, 5));
   FileWrite(h, "failsafeSL=" + IntegerToString(s.failsafeSL ? 1 : 0));
   FileWrite(h, "formulaOrigEntry=" + IntegerToString(s.formulaOrigEntry ? 1 : 0));
   FileWrite(h, "tpOrigEntry=" + IntegerToString(s.tpOrigEntry ? 1 : 0));
   FileWrite(h, "memorySave=" + IntegerToString(s.memorySave ? 1 : 0));
   FileWrite(h, "sounds=" + IntegerToString(s.sounds ? 1 : 0));
   FileWrite(h, "profile=" + s.profile);
   FileWrite(h, "tradeSymbol=" + s.tradeSymbol);
   FileWrite(h, "commissionPerLot=" + DoubleToString(s.commissionPerLot, 3));
   FileWrite(h, "commissionInRisk=" + IntegerToString(s.commissionInRisk ? 1 : 0));
   FileWrite(h, "commissionAuto=" + IntegerToString(s.commissionAuto ? 1 : 0));
   FileWrite(h, "serverSplitTP=" + IntegerToString(s.serverSplitTP ? 1 : 0));
   FileWrite(h, "defaultOrderMode=" + IntegerToString(s.defaultOrderMode));
   FileWrite(h, "privacyMode=" + IntegerToString(s.privacyMode ? 1 : 0));
   FileWrite(h, "panelX=" + IntegerToString(s.panelX));
   FileWrite(h, "panelY=" + IntegerToString(s.panelY));
   FileWrite(h, "panelVisible=" + IntegerToString(s.panelVisible ? 1 : 0));

   FileClose(h);
   UTM_WriteActiveProfile(s.profile);
   return true;
  }

//+------------------------------------------------------------------+
//| Load settings                                                     |
//+------------------------------------------------------------------+
bool UTM_LoadSettings(SUtmSettings &s)
  {
   if((bool)MQLInfoInteger(MQL_TESTER) && !g_allowTesterSettings)
      return false;

   string name = UTM_SettingsFileName(s.profile);
   if(!FileIsExist(name) && !FileIsExist(name, FILE_COMMON))
      return false;

   int h = UTM_OpenFileForRead(name);
   if(h == INVALID_HANDLE)
      return false;

   while(!FileIsEnding(h))
     {
      string line = FileReadString(h);
      if(line == "")
         continue;
      int eq = StringFind(line, "=");
      if(eq <= 0)
         continue;
      string key = StringSubstr(line, 0, eq);
      string val = StringSubstr(line, eq + 1);

      if(key == "riskMode")            s.riskMode = (int)StringToInteger(val);
      else if(key == "riskValue")      s.riskValue = StringToDouble(val);
      else if(key == "maxLot")         s.maxLot = StringToDouble(val);
      else if(key == "equityStop")     s.equityStop = StringToDouble(val);
      else if(key == "abnormalSpread") s.abnormalSpread = StringToDouble(val);
      else if(key == "bypassMaxLot")   s.bypassMaxLot = (StringToInteger(val) != 0);
      else if(key == "overrideBalance") s.overrideBalance = StringToDouble(val);
      else if(key == "fixedSL")        s.fixedSL = (StringToInteger(val) != 0);
      else if(key == "slSize")         s.slSize = StringToDouble(val);
      else if(key == "slUnit")         s.slUnit = (int)StringToInteger(val);
      else if(key == "slMin")          s.slMin = StringToDouble(val);
      else if(key == "slMax")          s.slMax = StringToDouble(val);
      else if(key == "atrPeriod")      s.atrPeriod = (int)StringToInteger(val);
      else if(key == "lockRR")         s.lockRR = (StringToInteger(val) != 0);
      else if(key == "tpCount")        s.tpCount = (int)StringToInteger(val);
      else if(key == "trailingTP")     s.trailingTP = (StringToInteger(val) != 0);
      else if(key == "trailTPRR")      s.trailTPRR = StringToDouble(val);
      else if(key == "trailTPPct")     s.trailTPPct = StringToDouble(val);
      else if(key == "beOffsetRR")     s.beOffsetRR = StringToDouble(val);
      else if(key == "formula")
        {
         StringReplace(val, "\\n", "\n");
         s.formula = val;
        }
      else if(key == "removePendingOnSL") s.removePendingOnSL = (StringToInteger(val) != 0);
      else if(key == "spreadMode")     s.spreadMode = (int)StringToInteger(val);
      else if(key == "spreadFactor")   s.spreadFactor = StringToDouble(val);
      else if(key == "emaSpread")      s.emaSpread = StringToDouble(val);
      else if(key == "failsafeSL")     s.failsafeSL = (StringToInteger(val) != 0);
      else if(key == "formulaOrigEntry") s.formulaOrigEntry = (StringToInteger(val) != 0);
      else if(key == "tpOrigEntry")    s.tpOrigEntry = (StringToInteger(val) != 0);
      else if(key == "memorySave")     s.memorySave = (StringToInteger(val) != 0);
      else if(key == "sounds")         s.sounds = (StringToInteger(val) != 0);
      else if(key == "profile")        s.profile = val;
      else if(key == "tradeSymbol")    s.tradeSymbol = val;
      else if(key == "commissionPerLot") s.commissionPerLot = StringToDouble(val);
      else if(key == "commissionInRisk") s.commissionInRisk = (StringToInteger(val) != 0);
      else if(key == "commissionAuto")   s.commissionAuto = (StringToInteger(val) != 0);
      else if(key == "serverSplitTP")    s.serverSplitTP = (StringToInteger(val) != 0);
      else if(key == "defaultOrderMode") s.defaultOrderMode = (int)StringToInteger(val);
      else if(key == "privacyMode")      s.privacyMode = (StringToInteger(val) != 0);
      else if(key == "panelX")         s.panelX = (int)StringToInteger(val);
      else if(key == "panelY")         s.panelY = (int)StringToInteger(val);
      else if(key == "panelVisible")   s.panelVisible = (StringToInteger(val) != 0);
      else if(StringFind(key, "tpRR") == 0)
        {
         int idx = (int)StringToInteger(StringSubstr(key, 4));
         if(idx >= 0 && idx < UTM_MAX_TP)
            s.tpRR[idx] = StringToDouble(val);
        }
      else if(StringFind(key, "tpPct") == 0)
        {
         int idx = (int)StringToInteger(StringSubstr(key, 5));
         if(idx >= 0 && idx < UTM_MAX_TP)
            s.tpPct[idx] = StringToDouble(val);
        }
     }

   FileClose(h);

   if(s.tpCount < 1) s.tpCount = 1;
   if(s.tpCount > UTM_MAX_TP) s.tpCount = UTM_MAX_TP;
   if(s.riskMode < 0 || s.riskMode > 2) s.riskMode = UTM_RISK_PERCENT;
   if(s.spreadMode < 0 || s.spreadMode > 3) s.spreadMode = UTM_SPREAD_OFF;
   if(s.slUnit != UTM_SL_PIPS && s.slUnit != UTM_SL_POINTS)
     {
      s.slUnit = UTM_SL_PIPS;   // ATR stop loss was removed
      Print("[UTM] 止损单位已从 ATR 改为 pip");
     }
   s.trailingTP = false;        // trailing take profit was removed
   return true;
  }

//+------------------------------------------------------------------+
//| List saved profiles                                               |
//+------------------------------------------------------------------+
int UTM_ListProfiles(string &names[])
  {
   ArrayResize(names, 0);
   string pattern = UTM_SETTINGS_FOLDER + "\\settings_*.ini";
   string fname;
   long   h = FileFindFirst(pattern, fname, FILE_COMMON);
   if(h == INVALID_HANDLE)
      h = FileFindFirst(pattern, fname);

   if(h == INVALID_HANDLE)
      return 0;

   do
     {
      string base = fname;
      StringReplace(base, UTM_SETTINGS_FOLDER + "\\settings_", "");
      StringReplace(base, ".ini", "");
      int n = ArraySize(names);
      ArrayResize(names, n + 1);
      names[n] = base;
     }
   while(FileFindNext(h, fname));

   FileFindClose(h);
   return ArraySize(names);
  }

#endif // __UTM_SETTINGS_MQH__
//+------------------------------------------------------------------+