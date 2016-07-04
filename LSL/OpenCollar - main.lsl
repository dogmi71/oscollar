////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                               OpenCollar - main                                //
//                                 version 3.990                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

//on start, send request for submenu names
//on getting submenu name, add to list if not already present
//on menu request, give dialog, with alphabetized list of submenus
//on listen, send submenu link message

string g_sCollarVersion="3.990";
integer g_iLatestVersion=TRUE;

list g_lOwners;
key g_kWearer;
//string g_sOldRegionName;
//list g_lMenuPrompts;
    

list g_lMenuIDs;//3-strided list of avatars given menus, their dialog ids, and the name of the menu they were given
integer g_iMenuStride = 3;

integer g_iScriptCount;//when the scriptcount changes, rebuild menus

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
                            //str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value in the httpdb

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

//5000 block is reserved for IM slaves

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "BACK";
string CTYPE="collar";
string WEARERNAME;

string GIVECARD = "Quick Guide";
string HELPCARD = "OpenCollar Guide";
string CONTACT = "Contact";
string LICENSE="License";
key g_kWebLookup;
key g_kCurrentUser;

list g_lAppearanceButtons;
list g_lAppsButtons;

integer g_iLocked = FALSE;
integer g_bDetached = FALSE;
integer g_iHide ; // global hide
integer g_iNews=TRUE;

string g_sLockPrimName="Lock"; // Description for lock elements to recognize them //EB //SA: to be removed eventually (kept for compatibility)
string g_sOpenLockPrimName="OpenLock"; // Prim description of elements that should be shown when unlocked
string g_sClosedLockPrimName="ClosedLock"; // Prim description of elements that should be shown when locked
list g_lClosedLockElements; //to store the locks prim to hide or show //EB
list g_lOpenLockElements; //to store the locks prim to hide or show //EB

string g_sDefaultLockSound="73f3f84b-0447-487d-8246-4ab3e5fdbf40";
string g_sDefaultUnlockSound="d64c3566-cf76-44b5-ae76-9aabf60efab8";
string g_sLockSound="73f3f84b-0447-487d-8246-4ab3e5fdbf40";
string g_sUnlockSound="d64c3566-cf76-44b5-ae76-9aabf60efab8";

integer g_iAppLock = FALSE;  //appearance lock flag

integer g_iAnimsMenu=FALSE;
integer g_iRlvMenu=FALSE;
integer g_iAppearanceMenu=FALSE;
integer g_iCustomizeMenu=FALSE;
integer g_iPaintMenu=FALSE;

integer g_iUpdateChan = -7483214;
integer g_iUpdateHandle;

key g_kUpdaterOrb;
integer g_iUpdateFromMenu;

string version_check_url = "https://raw.githubusercontent.com/lickx/opencollar-os/oscollar3/LSL/~version";
key github_version_request;

string news_url = "https://raw.githubusercontent.com/lickx/opencollar-os/oscollar3/LSL/~news";
key news_request;
string g_sLastNewsTime = "0";

integer g_iUpdateAuth;
integer g_iWillingUpdaters = 0;

integer g_iListenChan=1;
string g_sSafeWord="RED";
string g_sPrefix;

integer g_iWaitUpdate = FALSE;
integer g_iWaitRebuild = FALSE;

/*
integer g_iProfiled;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to 
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}
*/

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];

    //Debug("Made "+sName+" menu.");
} 

Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else {
        if (llGetAgentSize(kID)!=ZERO_VECTOR) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}

string AutoPrefix()
{
    list sName = llParseString2List(llKey2Name(llGetOwner()), [" "], []);
    return llToLower(llGetSubString(llList2String(sName, 0), 0, 0)) + llToLower(llGetSubString(llList2String(sName, 1), 0, 0));
}

integer compareVersions(string v1, string v2){ //compares two symantic version strings, true if v1 >= v2
    integer v1Index=llSubStringIndex(v1,".");
    integer v2Index=llSubStringIndex(v2,".");
    
    integer v1a=(integer)llGetSubString(v1,0,v1Index);
    integer v2a=(integer)llGetSubString(v2,0,v2Index);
    
    if (v1a == v2a) {
        if ((~v1Index) || (~v2Index)){
            string v1b;
            if (v1Index == -1 || v1Index==llStringLength(v1)) {
                v1b="0";
            } else {
                v1b=llGetSubString(v1,v1Index+1,-1);
            }

            string v2b;
            if (v2Index == -1 || v2Index==llStringLength(v2)) {
                v2b="0";
            } else {
                v2b=llGetSubString(v2,v2Index+1,-1);
            }

            return compareVersions(v1b,v2b);
        } else {
            return FALSE;
        }
    }
    return v1a > v2a;
}

AppsMenu(key kID, integer iAuth) {
    string sPrompt="\nBrowse apps, extras and custom features.\n\nwww.opencollar.at/apps";
    Dialog(kID, sPrompt, g_lAppsButtons, [UPMENU], 0, iAuth, "Apps");
}
AppearanceMenu(key kID, integer iAuth) {
    string sPrompt;
    string sLooksLockButton;
    if (g_iAppLock){
        sPrompt = "\nThe appearance of the "+CTYPE+" has been locked.\n\nAn owner must unlock it to allow modification.";
        sLooksLockButton="☒ LooksLock";
    } else {
        sPrompt="\nMake changes to the "+CTYPE+"'s appearance.";
        sLooksLockButton="☐ LooksLock";
    }
    sPrompt += "\n\nwww.opencollar.at/appearance";
    Dialog(kID, sPrompt, [sLooksLockButton]+g_lAppearanceButtons, [UPMENU], 0, iAuth, "Appearance");
}
HelpMenu(key kID, integer iAuth) {
    string sPrompt="\nOpenCollar Version "+g_sCollarVersion+"\n";
    if(!g_iLatestVersion) sPrompt+="Update available!";
    sPrompt+="\n\nPrefix: "+g_sPrefix+"\nChannel: "+(string)g_iListenChan+"\nSafeword: "+g_sSafeWord+"\n\nwww.opencollar.at/helpabout";

    string sNewsButton="☐ News";
    if (g_iNews){
        sNewsButton="☒ News";
    }
    list lStaticButtons=[GIVECARD,CONTACT,LICENSE,sNewsButton,"Update"];
    Dialog(kID, sPrompt, lStaticButtons, [UPMENU], 0, iAuth, "Help/About");
}
MainMenu(key kID, integer iAuth) {
    string sPrompt="\nOpenCollar Version "+g_sCollarVersion;
    if(!g_iLatestVersion) sPrompt+="\nUpdate available!";
    sPrompt += "\n\nwww.opencollar.at/main-menu";
    //Debug("max memory used: "+(string)llGetSPMaxMemory());
    list lStaticButtons;
    
    if (g_iLocked) lStaticButtons+="UNLOCK";
    else lStaticButtons+="LOCK";
    
    lStaticButtons+="Apps";
    if (g_iAnimsMenu){
        lStaticButtons+="Animations";
    } else {
        lStaticButtons+=" ";
    }
    if (llGetListLength(g_lAppearanceButtons)>0) {
        lStaticButtons+="Appearance";
    } else {
        lStaticButtons+=" ";
    }
    lStaticButtons+="Leash";
    if (g_iRlvMenu){
        lStaticButtons+="RLV";
    } else {
        lStaticButtons+=" ";
    }
    lStaticButtons+=["Access","Options","Help/About"];
    
    Dialog(kID, sPrompt, lStaticButtons, [], 0, iAuth, "Main");
}

NotifyOwners(string sMsg) {
    integer n;
    integer stop = llGetListLength(g_lOwners);
    for (n = 0; n < stop; n += 2) {
        Notify((key)llList2String(g_lOwners, n), sMsg, FALSE);
    }
}

string GetTimestamp() { // Return a string of the date and time
    string out;
    string DateUTC = llGetDate();
    if (llGetGMTclock() < 28800) { // that's 28800 seconds, a.k.a. 8 hours.
        list DateList = llParseString2List(DateUTC, ["-", "-"], []);
        integer year = llList2Integer(DateList, 0);
        integer month = llList2Integer(DateList, 1);
        integer day = llList2Integer(DateList, 2);
       // day = day - 1; //Remember, remember, the 0th of November!
       if(day==1) {
           if(month==1) return (string)(year-1) + "-01-31";
           else {
                --month;
                if(month==2) day = 28+(year%4==FALSE); //To do: fix before 28th feb 2100.
                else day = 30+ (!~llListFindList([4,6,9,11],[month])); //31 days hath == TRUE
            }
        }
        else --day;
        out=(string)year + "-" + (string)month + "-" + (string)day;
    } else out=llGetDate();
    
    integer t = (integer)llGetWallclock(); // seconds since midnight
    out += " " + (string)(t / 3600) + ":";
    
    integer mins=(t % 3600) / 60;
    if (mins <10){
        out += "0";
    }
    out += (string)mins+":";

    integer secs=t % 60;
    if (secs < 10){
        out += "0";
    }
    out += (string)secs;
    
    return out;
}

BuildLockElementList()//EB
{
    integer n;
    integer iLinkCount = llGetNumberOfPrims();
    list lParams;

    // clear list just in case
    g_lOpenLockElements = [];
    g_lClosedLockElements = [];

    //root prim is 1, so start at 2
    for (n = 2; n <= iLinkCount; n++)
    {
        // read description
        lParams=llParseString2List((string)llGetObjectDetails(llGetLinkKey(n), [OBJECT_DESC]), ["~"], []);
        // check inf name is lock name
        if (llList2String(lParams, 0)==g_sLockPrimName || llList2String(lParams, 0)==g_sClosedLockPrimName)
        {
            // if so store the number of the prim
            g_lClosedLockElements += [n];
        }
        else if (llList2String(lParams, 0)==g_sOpenLockPrimName) 
        {
            // if so store the number of the prim
            g_lOpenLockElements += [n];
        }
    }
}

SetLockElementAlpha() //EB
{
    if (g_iHide) return ; // ***** if collar is hide, don't do anything 
    //loop through stored links, setting alpha if element type is lock
    integer n;
    //float fAlpha;
    //if (g_iLocked) fAlpha = 1.0; else fAlpha = 0.0; //Let's just use g_iLocked!
    integer iLinkElements = llGetListLength(g_lOpenLockElements);
    for (n = 0; n < iLinkElements; n++)
    {
        llSetLinkAlpha(llList2Integer(g_lOpenLockElements,n), !g_iLocked, ALL_SIDES);
    }
    iLinkElements = llGetListLength(g_lClosedLockElements);
    for (n = 0; n < iLinkElements; n++)
    {
        llSetLinkAlpha(llList2Integer(g_lClosedLockElements,n), g_iLocked, ALL_SIDES);
    }
}

RebuildMenu()
{
    //Debug("Rebuild Menu");
    g_iAnimsMenu=FALSE;
    g_iRlvMenu=FALSE;
    g_iAppearanceMenu=FALSE;
    g_lAppsButtons = [] ;
    g_lAppearanceButtons = [];
    llMessageLinked(LINK_SET, MENUNAME_REQUEST, "Main", "");
    llMessageLinked(LINK_SET, MENUNAME_REQUEST, "AddOns", "");
    llMessageLinked(LINK_SET, MENUNAME_REQUEST, "Apps", "");
    llMessageLinked(LINK_SET, MENUNAME_REQUEST, "Appearance", "");
}

init (){
    github_version_request = llHTTPRequest(version_check_url, [HTTP_METHOD, "GET", HTTP_VERBOSE_THROTTLE, FALSE], "");
    
    g_iWaitRebuild = TRUE;
    llSetTimerEvent(1);//delay menu rebuild until other scripts are ready  
}

integer UserCommand(integer iNum, string sStr, key kID, integer fromMenu) {
    if (iNum == COMMAND_EVERYONE) return TRUE;  // No command for people with no privilege in this plugin.
    else if (iNum > COMMAND_EVERYONE || iNum < COMMAND_OWNER) return FALSE; // sanity check
    //Debug("Got message "+sStr);

    list lParams = llParseString2List(sStr, [" "], []);
    string sCmd = llToLower(llList2String(lParams, 0));

    if (sCmd == "menu") {
        string sSubmenu = llToLower(llList2String(lParams, 1));
        if (sSubmenu == "main" || sSubmenu == "") MainMenu(kID, iNum);
        else if (sSubmenu == "apps" || sSubmenu=="addons") AppsMenu(kID, iNum);
        else if (sSubmenu == "help/about") HelpMenu(kID, iNum);
        else if (sSubmenu == "appearance") AppearanceMenu(kID, iNum);
    } else if (sStr == "license") {
        if(llGetInventoryType("OpenCollar License")==INVENTORY_NOTECARD) llGiveInventory(kID,"OpenCollar License");
        else Notify(kID,"License notecard missing from collar, sorry.", FALSE); 
        if (fromMenu) HelpMenu(kID, iNum);
    } else if (sStr == "help") {
        llGiveInventory(kID, HELPCARD);
        if (fromMenu) HelpMenu(kID, iNum);
    } else if (sStr =="about" || sStr=="help/about") HelpMenu(kID,iNum);               
    else if (sStr == "addons" || sStr=="apps") AppsMenu(kID, iNum);
    else if (sStr == "appearance") AppearanceMenu(kID, iNum);
    else if (sCmd == "menuto") {
        key kAv = (key)llList2String(lParams, 1);
        if (llGetAgentSize(kAv) != ZERO_VECTOR) //if kAv is an avatar in this region
        {
            if(llGetOwnerKey(kID)==kAv) MainMenu(kID, iNum);    //if the request was sent by something owned by that agent, send a menu
            else  llMessageLinked(LINK_SET, COMMAND_NOAUTH, "menu", kAv);   //else send an auth request for the menu
        }
    } else if (sCmd == "lock" || (!g_iLocked && sStr == "togglelock")) {    //does anything use togglelock?  If not, it'd be nice to get rid of it
        //Debug("User command:"+sCmd);

        if (iNum == COMMAND_OWNER || kID == g_kWearer ) {   //primary owners and wearer can lock and unlock. no one else
            //inlined old "Lock()" function        
            g_iLocked = TRUE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "Global_locked=1", "");
            llMessageLinked(LINK_SET, RLV_CMD, "detach=n", "main");
            llPlaySound(g_sLockSound, 1.0);
            SetLockElementAlpha();//EB

            Notify(kID,CTYPE + " has been locked.",TRUE);
        }
        else Notify(kID, "Sorry, only primary owners and wearer can lock the " + CTYPE + ".", FALSE);
        if (fromMenu) MainMenu(kID, iNum);
    } else if (sStr=="☒ LooksLock" || llToLower(sStr)=="lookslock off") {
        if (iNum == COMMAND_OWNER) {
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "Appearance_Lock", "");
            llMessageLinked(LINK_SET, iNum, "lockappearance 0", kID);
            g_iAppLock=FALSE;
        } else Notify(kID,"Only owners can change the looks lock.", FALSE);
        if (fromMenu) AppearanceMenu(kID,iNum);
    } else if (sStr=="☐ LooksLock" || llToLower(sStr)=="lookslock on") {
        if (iNum == COMMAND_OWNER) {
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "Appearance_Lock" + "=1", "");
            llMessageLinked(LINK_SET, iNum, "lockappearance 1", kID);
            g_iAppLock=TRUE;
        } else Notify(kID,"Only owners can change the looks lock.", FALSE);
        if (fromMenu) AppearanceMenu(kID,iNum);
    } else if (sStr == "runaway" || sCmd == "unlock" || (g_iLocked && sStr == "togglelock")) {
        if (iNum == COMMAND_OWNER)  {  //primary owners can lock and unlock. no one else
            //inlined old "Unlock()" function
            g_iLocked = FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "Global_locked", "");
            llMessageLinked(LINK_SET, RLV_CMD, "detach=y", "main");
            llPlaySound(g_sUnlockSound, 1.0);
            SetLockElementAlpha(); //EB

            Notify(kID,CTYPE + " has been unlocked.",TRUE);
        }
        else Notify(kID, "Sorry, only primary owners can unlock the " + CTYPE + ".", FALSE);
        if (fromMenu) MainMenu(kID, iNum);
    } else if (sCmd == "fixmenus") {
        if (kID == g_kWearer || iNum==COMMAND_OWNER){
            RebuildMenu();
            Notify(kID, "Rebuilding menus, this may take several seconds.", FALSE);
        } else Notify(kID, "Sorry, only primary owners and wearer can fix menus.", FALSE);
    } else if (sCmd == "news"){
        if (kID == g_kWearer || iNum==COMMAND_OWNER){
            if (sStr=="news off"){
                g_iNews=FALSE;
                Notify(kID,"News items will no longer be downloaded from the OpenCollar web site.",TRUE);  //notify news off
            } else if (sStr=="news on"){
                g_iNews=TRUE;
                Notify(kID,"News items will be downloaded from the OpenCollar web site when they are available.",TRUE);  //notify news on
                g_sLastNewsTime="0";
                news_request = llHTTPRequest(news_url, [HTTP_METHOD, "GET", HTTP_VERBOSE_THROTTLE, FALSE], "");
            } else {
                g_sLastNewsTime="0";
                news_request = llHTTPRequest(news_url, [HTTP_METHOD, "GET", HTTP_VERBOSE_THROTTLE, FALSE], "");
            }
        } else Notify(kID,"Only primary owners and wearer can change news settings.",FALSE);
        if (fromMenu) HelpMenu(kID, iNum);
    } else if (sCmd == "update") {
//        if (llGetOwnerKey(kID) == g_kWearer) {
        if (kID == g_kWearer) {
            string sVersion = llList2String(llParseString2List(llGetObjectDesc(), ["~"], []), 1);
            g_iWillingUpdaters = 0;
            g_kCurrentUser = kID;
            g_iUpdateAuth = iNum;
            Notify(kID,"Searching for nearby updater",FALSE);
            g_iUpdateHandle = llListen(g_iUpdateChan, "", "", "");
            g_iUpdateFromMenu=fromMenu;
            llWhisper(g_iUpdateChan, "UPDATE|" + sVersion);
            g_iWaitUpdate = TRUE;
            llSetTimerEvent(5.0); //set a timer to wait for responses from updaters
        } else {
            Notify(kID,"Only the wearer can update the " + CTYPE + ".",FALSE);
            if (fromMenu) HelpMenu(kID, iNum);
        }
    } else if (sCmd == "version") {
        Notify(kID, "I am running OpenCollar version " + g_sCollarVersion, FALSE);
    } else if (sCmd == "objectversion") {  // ping from an object, we answer to it on the object channel
        integer iChan = (integer)("0x"+llGetSubString((string)g_kWearer,2,7)) + 1111;
        if (iChan>0) iChan=iChan*(-1);
        if (iChan > -10000) iChan -= 30000;

        llSay(iChan,(string)g_kWearer+"\\version="+g_sCollarVersion);
    } else if (sCmd == "attachmentversion") {
        // Reply to version request from "garvin style" attachment
        integer iInterfaceChannel = (integer)("0x" + llGetSubString(g_kWearer,30,-1));
        if (iInterfaceChannel > 0) iInterfaceChannel = -iInterfaceChannel;
        llRegionSayTo(g_kWearer, iInterfaceChannel, "version="+g_sCollarVersion);
    }
    return TRUE;
}

default {
    on_rez(integer iParam) {
        init();
    }
    
    state_entry() {
        //llSetMemoryLimit(65536);  //this script needs to be profiled, and its memory limited
        g_kWearer = llGetOwner(); //updates in change event prompting script restart
        WEARERNAME = llKey2Name(g_kWearer);  //quick and dirty default, will get replaced by value from settings
        BuildLockElementList(); //updates in change event, doesn;t need a reset every time
        g_iScriptCount = llGetInventoryNumber(INVENTORY_SCRIPT);  //updates on change event;
        
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "Global_locked", ""); //settings will send these on_rez, so no need to ask every rez
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "auth_owner", ""); //settings will send these on_rez, so no need to ask every rez
        
        init(); //do stuf needed on_rez AND on script start
        
        g_sPrefix=AutoPrefix();
        //Debug("Starting");
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        // SA: delete this after transition is finished
        if (iNum == COMMAND_NOAUTH) return;
        // /SA
        else if (iNum == MENUNAME_RESPONSE) {
            //sStr will be in form of "parent|menuname"
            //Debug("got menu button "+sStr);
            list lParams = llParseString2List(sStr, ["|"], []);
            string sName = llList2String(lParams, 0);
            string sSubMenu = llList2String(lParams, 1);
            if (sName=="AddOns" || sName=="Apps"){  //we only accept buttons for apps nemu
                //Debug("we handle " + sName);
                if (llListFindList(g_lAppsButtons, [sSubMenu]) == -1) {
                    g_lAppsButtons += [sSubMenu];
                    g_lAppsButtons = llListSort(g_lAppsButtons, 1, TRUE);
                }
            } else if (sName=="Appearance") {  //and appearance
                 if (llListFindList(g_lAppearanceButtons, [sSubMenu]) == -1) {
                    g_lAppearanceButtons += [sSubMenu];
                    g_lAppearanceButtons = llListSort(g_lAppearanceButtons, 1, TRUE);
                }
               
            } else if (sStr=="Main|Animations"){
                g_iAnimsMenu=TRUE;
            } else if (sStr=="Main|RLV"){
                g_iRlvMenu=TRUE;
//            } else if (sStr=="Main|Appearance"){
//                g_iAppearanceMenu=TRUE;
            } else if (sStr=="Main|Customize"){
                g_iCustomizeMenu=TRUE;
            } else if (sStr=="Main|Paint"){
                g_iPaintMenu=TRUE;
            }
        } else if (iNum == MENUNAME_REMOVE) {
            //sStr should be in form of parentmenu|childmenu
            list lParams = llParseString2List(sStr, ["|"], []);
            string parent = llList2String(lParams, 0);
            string child = llList2String(lParams, 1);

            if (parent=="Apps" || parent=="AddOns") {
                integer gutiIndex = llListFindList(g_lAppsButtons, [child]);
                if (gutiIndex != -1) g_lAppsButtons = llDeleteSubList(g_lAppsButtons, gutiIndex, gutiIndex);
            }
            if (parent=="Appearance") {
                integer gutiIndex = llListFindList(g_lAppsButtons, [child]);
                if (gutiIndex != -1) g_lAppearanceButtons = llDeleteSubList(g_lAppearanceButtons, gutiIndex, gutiIndex);
            }
        } else if (iNum == DIALOG_RESPONSE) {
            //Debug("Menu response");
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1) {  //got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);          
                string sMessage = llList2String(lMenuParams, 1);                                         
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                
                //remove stride from g_lMenuIDs.  We have to subtract from the index because the dialog id comes in the middle of the stride
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);                
                
                //process response
                if (sMenu=="Main"){
                    //Debug("Main menu response: '"+sMessage+"'");
                    if (sMessage == "LOCK" || sMessage== "UNLOCK"){
                        //Debug("doing usercommand for lock/unlock");
                        UserCommand(iAuth, sMessage, kAv, TRUE);
                    } else if (sMessage == "Help/About"){
                        HelpMenu(kAv, iAuth);
                    } else if (sMessage == "Apps"){
                        AppsMenu(kAv, iAuth);
                    } else if (sMessage == "Appearance"){
                        AppearanceMenu(kAv, iAuth);
                    } else {
                        llMessageLinked(LINK_SET, iAuth, "menu "+sMessage, kAv);
                    }
                } else if (sMenu=="Apps" || sMenu=="Appearance"){
                    //Debug("Apps menu response:"+sMessage);
                    if (sMessage == UPMENU) {
                        MainMenu(kAv, iAuth);
                    } else if (llSubStringIndex(sMessage,"LooksLock")==2) {
                        UserCommand(iAuth, sMessage, kAv, TRUE);
                    } else {
                        llMessageLinked(LINK_SET, iAuth, "menu "+sMessage, kAv);
                    }
                } else if (sMenu=="Help/About"){
                    //Debug("Help menu response");
                    if (sMessage == UPMENU) MainMenu(kAv, iAuth);
                    else if (sMessage == "Settings") {
                        llMessageLinked(LINK_SET, iAuth, "menu settings", kAv);
                    } else if (sMessage == GIVECARD) {
                        UserCommand(iAuth,"help",kAv, TRUE);
                    } else if (sMessage == LICENSE) {
                        UserCommand(iAuth,"license",kAv, TRUE);
                    } else if (sMessage == CONTACT) {
                        g_kWebLookup = llHTTPRequest("https://raw.githubusercontent.com/OpenCollar/OpenCollarUpdater/main/LSL/~contact", [HTTP_METHOD, "GET", HTTP_VERBOSE_THROTTLE, FALSE], "");
                        g_kCurrentUser = kAv;
                        HelpMenu(kAv, iAuth);
                    } else if (sMessage=="☐ News") {
                        //Debug("News on button");    
                        UserCommand(iAuth, "news on", kAv, TRUE);
                    } else if (sMessage=="☒ News") {
                        //Debug("News off button");    
                        UserCommand(iAuth, "news off", kAv, TRUE);
                    } else if (sMessage == "Update") UserCommand(iAuth,"update",kAv,TRUE);
                }
            }
        }
        else if (UserCommand(iNum, sStr, kID, FALSE)) return;
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == "Global_locked") {
                g_iLocked = (integer)sValue;
                SetLockElementAlpha(); //EB
            } else if (sToken == "Global_CType") CTYPE = sValue;
            else if (sToken == "auth_owner")
            {
                g_lOwners = llParseString2List(sValue, [","], []);
            }
            else if(sToken =="lock_locksound")
            {
                if(sValue=="default") g_sLockSound=g_sDefaultLockSound;
                else if((key)sValue!=NULL_KEY || llGetInventoryType(sValue)==INVENTORY_SOUND) g_sLockSound=sValue;
            }
            else if (sToken == "Appearance_Lock") g_iAppLock = (integer)sValue;
            else if(sToken =="lock_unlocksound")
            {
                if(sValue=="default") g_sUnlockSound=g_sDefaultUnlockSound;
                else if((key)sValue!=NULL_KEY || llGetInventoryType(sValue)==INVENTORY_SOUND) g_sUnlockSound=sValue;
            }
            else if (sToken == "listener_channel") g_iListenChan = llList2Integer(llParseString2List(sValue,[","],[]),0);
            else if (sToken == "listener_safeword") g_sSafeWord = sValue;
            else if (sToken == "Global_prefix") g_sPrefix = sValue;
            else if (sToken == "Global_news") g_iNews = (integer)sValue;
            else if (sStr == "settings=sent") {
                if (g_iNews) news_request = llHTTPRequest(news_url, [HTTP_METHOD, "GET", HTTP_VERBOSE_THROTTLE, FALSE], "");
            } else if (sToken=="Global_WearerName") WEARERNAME=sValue;
        }
        else if (iNum == DIALOG_TIMEOUT)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            //remove stride from g_lMenuIDs
            //we have to subtract from the index because the dialog id comes in the middle of the stride
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);                        
        }
        else if (iNum == LM_SETTING_SAVE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == "auth_owner") g_lOwners = llParseString2List(sValue, [","], []);
            else if (sToken == "listener_channel") g_iListenChan = llList2Integer(llParseString2List(sValue,[","],[]),0);
            else if (sToken == "listener_safeword") g_sSafeWord = sValue;
            else if (sToken == "Global_prefix") g_sPrefix = sValue;
        }
        else if (iNum == RLV_REFRESH || iNum == RLV_CLEAR)
        {
            if (g_iLocked) llMessageLinked(LINK_SET, RLV_CMD, "detach=n", "main");
            else llMessageLinked(LINK_SET, RLV_CMD, "detach=y", "main");
        }
    }

    attach(key kID)
    {
        if (g_iLocked)
        {
            if(kID == NULL_KEY)
            {
                g_bDetached = TRUE;
                NotifyOwners(WEARERNAME + " has detached me while locked at " + GetTimestamp() + "!");
            }
            else if(g_bDetached)
            {
                NotifyOwners(WEARERNAME + " has re-atached me at " + GetTimestamp() + "!");
                g_bDetached = FALSE;
            }
        }
    }
    http_response(key id, integer status, list meta, string body){
        if (status == 200) { // be silent on failures.
            if (id == g_kWebLookup){
                Notify(g_kCurrentUser,body,FALSE);
            } else if (id == github_version_request) {  // strip the newline off the end of the text
                if (compareVersions(llStringTrim(body, STRING_TRIM),g_sCollarVersion)) g_iLatestVersion=FALSE;
                else g_iLatestVersion=TRUE;
            } else if (id == news_request) {  // We got a response back from the news page on Github.  See if it's new enough to report to the user.
                // The first line of a news item should be space delimited list with timestamp in format yyyymmdd.n as the last field, where n is the number of messages on this day
                string firstline = llList2String(llParseString2List(body, ["\n"], []), 0);
                list firstline_parts = llParseString2List(firstline, [" "], []);
                string this_news_time = llList2String(firstline_parts, -1);

                if (compareVersions(this_news_time,g_sLastNewsTime)) {
                    string news = "Newsflash " + body;
                    llOwnerSay(news);
                    g_sLastNewsTime = this_news_time;
                } 
            }
        }
    }
    
    listen(integer channel, string name, key id, string message) {
        if (llGetOwnerKey(id) == g_kWearer) {   //collar and updater have to have the same Owner else do nothing!
            list lTemp = llParseString2List(message, [","],[]);
            string sCommand = llList2String(lTemp, 0);
            if( message == "get ready") {
                g_iWillingUpdaters++;
                g_kUpdaterOrb = id;
            }
        }
    }

    timer() {
        if (g_iWaitUpdate) {
            g_iWaitUpdate = FALSE;            
            llListenRemove(g_iUpdateHandle);

            if (!g_iWillingUpdaters) {   //if no updaters responded, get upgrader info from web and remenu
                g_kWebLookup = llHTTPRequest("https://raw.githubusercontent.com/OpenCollar/OpenCollarUpdater/main/LSL/~update", [HTTP_METHOD, "GET", HTTP_VERBOSE_THROTTLE, FALSE], "");
                if (g_iUpdateFromMenu) HelpMenu(g_kCurrentUser,g_iUpdateAuth);
            } else if (g_iWillingUpdaters > 1) {    //if too many updaters, PANIC!
                Notify(g_kCurrentUser,"Multiple updaters were found within 10m.  Please remove all but one and try again",FALSE);
            } else {    //perform update
                integer pin = (integer)llFrand(99999998.0) + 1; //set a random pin
                llSetRemoteScriptAccessPin(pin);
                llRegionSayTo(g_kUpdaterOrb, g_iUpdateChan, "ready|" + (string)pin );
            }
        }
        
        if (g_iWaitRebuild) {            
            g_iWaitRebuild = FALSE;
            RebuildMenu();
        }
        
        if (!g_iWaitUpdate && !g_iWaitRebuild) llSetTimerEvent(0.0);
    }
    
    changed(integer iChange)
    {
        if (iChange & CHANGED_INVENTORY)
        {
            if (llGetInventoryNumber(INVENTORY_SCRIPT) != g_iScriptCount) { //a script has been added or removed.  Reset to rebuild menu
                RebuildMenu(); //llResetScript();
            }
            g_iScriptCount=llGetInventoryNumber(INVENTORY_SCRIPT);
        }
        if (iChange & CHANGED_OWNER) llResetScript();
        if (iChange & CHANGED_COLOR) // ********************* 
        {
            integer iNewHide=!(integer)llGetAlpha(ALL_SIDES) ; //check alpha
            if (g_iHide != iNewHide){   //check there's a difference to avoid infinite loop
                g_iHide = iNewHide;
                SetLockElementAlpha(); // update hide elements 
            }
        }
        if (iChange & CHANGED_LINK) BuildLockElementList(); // need rebuils lockelements list
/*        
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
*/        
    }
}
