//+------------------------------------------------------------------+
//|                                              UTM_PersistTest.mq5 |
//|   Verifies: auto-save, input fingerprint, profile rename, backup  |
//+------------------------------------------------------------------+
#property copyright "UTM Manager"
#property version   "1.01"

#include <UTM/UTM_Defines.mqh>
#include <UTM/UTM_Utils.mqh>
#include <UTM/UTM_Settings.mqh>

string SimInit(const string inputProfile, const double inputRisk,
               const bool useProfile, const bool forceInputs)
  {
   UTM_SetDefaults(g_set);
   g_set.riskValue = inputRisk;
   g_set.profile   = inputProfile;
   g_inputSig      = UTM_SettingsSignature(g_set);

   string prof   = inputProfile;
   string active = UTM_ReadActiveProfile();
   if(active != "" &&
      (FileIsExist(UTM_SettingsFileName(active), FILE_COMMON) || FileIsExist(UTM_SettingsFileName(active))))
      prof = active;

   bool loaded = false;
   if(useProfile && !forceInputs)
     {
      g_set.profile = prof;
      string fileSig = UTM_ReadInputSig(prof);
      if(fileSig == "" || fileSig == g_inputSig)
         loaded = UTM_LoadSettings(g_set);
      else
        {
         UTM_BackupProfile(prof);
         Print("   -> inputs changed, backup made");
        }
     }

   g_set.profile = prof;
   UTM_SaveSettings(g_set);

   return (loaded ? "LOADED" : "SAVED ") +
          " profile=" + g_set.profile +
          " risk=" + DoubleToString(g_set.riskValue, 2) +
          " bak=" + IntegerToString(FileIsExist(UTM_SettingsFileName(g_set.profile) + ".bak", FILE_COMMON) ? 1 : 0);
  }

int OnInit()
  {
   g_allowTesterSettings = true;   // this test writes real files on purpose
   FileDelete(UTM_SettingsFileName("A"), FILE_COMMON);
   FileDelete(UTM_SettingsFileName("B"), FILE_COMMON);
   FileDelete(UTM_SettingsFileName("A") + ".bak", FILE_COMMON);
   FileDelete(UTM_SettingsFileName("B") + ".bak", FILE_COMMON);
   FileDelete(UTM_SETTINGS_FOLDER + "\\active_profile.txt", FILE_COMMON);

   Print("PERSIST 1 first run A/1.0 : ", SimInit("A", 1.0, true, false));

   //--- panel edit + auto save
   g_set.riskValue = 2.5;
   g_set.slSize    = 33.0;
   UTM_SaveSettings(g_set);
   Print("PERSIST 2 panel edit 2.5, saved to ", g_set.profile);

   Print("PERSIST 3 restart A/1.0  : ", SimInit("A", 1.0, true, false));

   //--- panel renames the profile and saves
   g_set.profile = "B";
   UTM_SaveSettings(g_set);
   Print("PERSIST 4 panel renamed to B, saved");

   Print("PERSIST 5 restart A/1.0  : ", SimInit("A", 1.0, true, false));

   Print("PERSIST 6 restart A/3.0  : ", SimInit("A", 3.0, true, false));

   Print("PERSIST 7 restart A/3.0  : ", SimInit("A", 3.0, true, false));

   Print("PERSIST 8 force inputs 4.0: ", SimInit("A", 4.0, true, true));
   return INIT_SUCCEEDED;
  }
//+------------------------------------------------------------------+