////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                              OpenCollar - styles                               //
//                                 version 3.995                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

string g_sSubMenu = "Styles";
string g_sParentMenu = "Appearance";
string CTYPE = "collar";
key g_kWearer;
string UPMENU = "BACK";
string DUMP = "Dump Style";

integer COMMAND_OWNER = 500;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;

integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
//integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

//script specific variables
list g_lMenuIDs;//3-strided list of avkey, dialogid, menuname
integer g_iMenuStride = 3;

string g_sStyle;
list g_lElementsSettings; // [element_name,"key_texture~vector_color~integer_shine"]

list g_lStyles;  // list of style names
list g_lStyleSettings; // list of style settings ["Stylename1", "elementname~keytexture~vectorcolor~integershine", "elementname~keytexture~vectorcolor~integershine", ... "Stylename2",....]

key g_iNotecardId;
key g_kNotecardReadRequest;
string g_sNotecardName=".styles";
integer g_iNotecardLine=0;
string g_sNotecardStyle ;

integer g_iAppLock = FALSE;
string g_sAppLockToken = "Appearance_Lock";

integer g_iHasColorScript = FALSE;
integer g_iHasTextureScript = FALSE;
integer g_iHasShineScript = FALSE;

//standard OC functions
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

Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string menuType) {
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|"
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);

    integer iMenuIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    list lAddMe = [kRCPT, kID, menuType];
    if (iMenuIndex == -1) g_lMenuIDs += lAddMe;
    else g_lMenuIDs = llListReplaceList(g_lMenuIDs, lAddMe, iMenuIndex, iMenuIndex + g_iMenuStride - 1);
}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else {
        if (llGetAgentSize(kID)!=ZERO_VECTOR) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}

//menu generators
StyleMenu(key kAv, integer iAuth)
{
    Dialog(kAv, "\nCurrent Style: "+g_sStyle+"\n\nSelect an style from the list", g_lStyles, [DUMP, UPMENU],0, iAuth, "StyleMenu");
}

SetStyle(string sStyle, integer iAuth, key kAv)
{
    if (llListFindList(g_lStyles,[sStyle]) == -1) return; // unknown style

    g_sStyle = sStyle;
    integer index = llListFindList(g_lStyleSettings,[sStyle]) ;
    if (index == -1) return; // no style settings

    while (index++ >= 0)
    {
        string setting = llList2String(g_lStyleSettings,index);
        if ((~llListFindList(g_lStyles,[setting])) || setting == "") index = -1;
        else
        {
            list lParams = llParseString2List(setting,["~"],[]);
            string sElement = llStringTrim(llList2String(lParams,0),STRING_TRIM);
            if (sElement != "")
            {
                string sTexture = llStringTrim(llList2String(lParams,1),STRING_TRIM);
                if (sTexture != "")
                {
                    llMessageLinked(LINK_SET, iAuth, "settexture " + sElement+" "+sTexture, kAv);
                    if (!g_iHasTextureScript) SetTexture(sElement, sTexture);
                }

                string sColor = llStringTrim(llList2String(lParams,2),STRING_TRIM);
                if (sColor != "")
                {
                    llMessageLinked(LINK_SET, iAuth, "setcolor "+sElement+" "+sColor, kAv);
                    if (!g_iHasColorScript) SetColor(sElement, (vector)sColor);
                }

                string sShine = llStringTrim(llList2String(lParams,3),STRING_TRIM);
                if (sShine != "")
                {
                    llMessageLinked(LINK_SET, iAuth, "setshiny " + sElement+" "+sShine, kAv);
                    if (!g_iHasShineScript) SetShine(sElement, (integer)sShine);
                }
            }
        }
    }
}

SetTexture(string sElement, string sTex)
{
    integer i;
    integer n = llGetNumberOfPrims();
    for (i = 2; i <= n; i++)
    {
        if (ElementType(i,"notexture") == sElement)
        {
            // llSetLinkPrimitiveParamsFast(iLink, [PRIM_TEXTURE,ALL_SIDES,sTex,<1.0,1.0,1.0>,<0.0,0.0,0.0>,0.0] );
            // update prim texture for each face with save texture repeats, offsets and rotations
            integer iSides = llGetLinkNumberOfSides(i);
            integer iFace ;
            for (iFace = 0; iFace < iSides; iFace++)
            {
                list lParams = llGetLinkPrimitiveParams(i, [PRIM_TEXTURE, iFace ]);
                lParams = llDeleteSubList(lParams,0,0); // get texture params
                llSetLinkPrimitiveParamsFast(i, [PRIM_TEXTURE, iFace, sTex]+lParams);
            }
        }
    }
}

SetColor(string sElement, vector vColor)
{
    integer i;
    integer n = llGetNumberOfPrims();
    for (i = 2; i <= n; i++)
    {
        if (ElementType(i,"nocolor") == sElement) llSetLinkColor(i, vColor, ALL_SIDES);
    }
}

SetShine(string sElement, integer iShine)
{
    integer i;
    integer n = llGetNumberOfPrims();
    for (i = 2; i <= n; i++)
    {
        if (ElementType(i,"notexture") == sElement) llSetLinkPrimitiveParamsFast(i,[PRIM_BUMP_SHINY,ALL_SIDES,iShine,0]);
    }
}

string ElementType(integer iLinkNum, string sType)
{
    string sDesc = llList2String(llGetLinkPrimitiveParams(iLinkNum, [PRIM_DESC]),0);
    list lParams = llParseString2List(llStringTrim(sDesc,STRING_TRIM), ["~"], []);
    if ((~llListFindList(lParams,[sType])) || sDesc == "" || sDesc == "(No Description)") return sType;
    else return llList2String(lParams, 0);
}

AddElementSetting(string element, string value, integer n )
{
    if (element =="") return ;
    string params;
    integer i = llListFindList(g_lElementsSettings, [element]);
    if (i==-1)
    {
        if(n==0) params = value+"~ ~ ";
        if(n==1) params = " ~"+value+"~ ";
        if(n==2) params = " ~ ~"+value;
        g_lElementsSettings += [element, params];
    }
    else
    {
        string sParams = llList2String(g_lElementsSettings,i+1);
        list lParams = llParseString2List(sParams,["~"],[]);
        lParams = llListReplaceList(lParams, [value], n, n);
        sParams = llDumpList2String(lParams,"~");
        g_lElementsSettings = llListReplaceList(g_lElementsSettings, [sParams], i+1, i+1);
    }
}

integer UserCommand(integer iAuth, string sStr, key kAv, integer remenu)
{
    if (iAuth > COMMAND_WEARER || iAuth < COMMAND_OWNER) return FALSE; // sanity check

    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llList2String(lParams, 0);
    //string sValue = llList2String(lParams, 1);
    if (sStr == "menu "+ g_sSubMenu || llToLower(sStr) == "styles")
    {
        if (kAv!=g_kWearer && iAuth!=COMMAND_OWNER)
        {
            Notify(kAv,"You are not allowed to change the "+CTYPE+"'s style.", FALSE);
            llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
        }
        else if (g_iAppLock)
        {
            Notify(kAv, "The appearance of the " + CTYPE + " is locked. You cannot access this menu now!", FALSE);
            llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
        }
        else StyleMenu(kAv, iAuth);
    }
    else if (sCommand == "lockappearance" && iAuth == COMMAND_OWNER)
    {
        string sValue = llStringTrim(llDeleteSubString(sStr,0,llStringLength(sCommand)),STRING_TRIM);
        if (sValue == "0") g_iAppLock = FALSE;
        if (sValue == "1") g_iAppLock = TRUE;
    }
    else if (sCommand == "style" && !g_iAppLock)
    {
        string sValue = llStringTrim(llDeleteSubString(sStr,0,llStringLength(sCommand)),STRING_TRIM);
        if (~llListFindList(g_lStyles,[sValue]))
        {
            SetStyle(sValue, iAuth, kAv);
            llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "styles_style=" + sValue, "");
        }
        else Notify(kAv,"Unrecognised style: "+sValue+" not in '"+llDumpList2String(g_lStyles,",")+"'",FALSE);
        if (remenu) StyleMenu(kAv, iAuth);
    }
    else if (sStr == "dumpstyle")
    {
        DumpSettings(kAv,"~");
        if (remenu) StyleMenu(kAv, iAuth);
    }
    return TRUE ;
}

DumpSettings(key kAv, string sep)
{
    g_lElementsSettings = llListSort(g_lElementsSettings, 2, TRUE);

    string out = "\n# Copy all below into '"+g_sNotecardName+"' notecard and change 'New Style' to own style name:\n\n[ New Style ]\n";
    integer i;
    for (i = 0; i < llGetListLength(g_lElementsSettings); i += 2)
    {
        out += llList2String(g_lElementsSettings, i)+sep+llList2String(g_lElementsSettings, i+1)+"\n";
    }
    Notify(kAv,out,FALSE);
}

CheckScripts()
{
    g_iHasTextureScript = g_iHasColorScript = g_iHasShineScript = FALSE;
    if (llGetInventoryType("OpenCollar - color") == INVENTORY_SCRIPT) g_iHasColorScript = TRUE;
    if (llGetInventoryType("OpenCollar - texture") == INVENTORY_SCRIPT) g_iHasTextureScript = TRUE;
    if (llGetInventoryType("OpenCollar - shininess") == INVENTORY_SCRIPT) g_iHasShineScript = TRUE;
    // this is for my own script:
    //if (llGetInventoryType("OpenCollar - customize") == INVENTORY_SCRIPT) g_iHasTextureScript = g_iHasColorScript = g_iHasShineScript = TRUE;
}

default
{
    on_rez(integer param)
    {
        //llResetScript();
        g_lElementsSettings = [] ;
        CheckScripts();
    }

    state_entry()
    {
        CheckScripts();
        g_kWearer = llGetOwner();
        g_iNotecardId = llGetInventoryKey(g_sNotecardName);
        if(g_iNotecardId)
        {
            g_iNotecardLine=0;
            g_kNotecardReadRequest=llGetNotecardLine(g_sNotecardName,0);
        }
        //else llOwnerSay(g_sNotecardName+" notecard absent!");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (UserCommand(iNum, sStr, kID, FALSE)) return;
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sGroupToken = llList2String(lParams, 0);
            string sGroup = llList2String(llParseString2List(sGroupToken,["_"],[]),0);
            string sToken = llList2String(llParseString2List(sGroupToken,["_"],[]),1);
            string sValue = llList2String(lParams, 1);
            if (sToken == "CType") CTYPE = sValue;
            else if (sGroup == "texture") AddElementSetting(sToken, sValue, 0);
            else if (sGroup == "color") AddElementSetting(sToken, sValue, 1);
            else if (sGroup == "shininess") AddElementSetting(sToken, sValue, 2);
            else if (sGroupToken == "styles_style") g_sStyle = sValue; // SetStyle(sValue,COMMAND_WEARER,g_kWearer);
            else if (sGroupToken == g_sAppLockToken) g_iAppLock = (integer)sValue;
        }
        else if (iNum == LM_SETTING_SAVE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sGroupToken = llList2String(lParams, 0);
            string sGroup = llList2String(llParseString2List(sGroupToken,["_"],[]),0);
            string sToken = llList2String(llParseString2List(sGroupToken,["_"],[]),1);
            string sValue = llList2String(lParams, 1);
            if (sToken == "CType") CTYPE = sValue;
            else if (sGroup == "texture") AddElementSetting(sToken, sValue, 0);
            else if (sGroup == "color") AddElementSetting(sToken, sValue, 1);
            else if (sGroup == "shininess") AddElementSetting(sToken, sValue, 2);
            else if (sGroupToken == g_sAppLockToken) g_iAppLock = (integer)sValue;
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex)
            { //got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);

                //remove stride from g_lMenuIDs
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);

                if (sMenuType == "StyleMenu")
                {  //lists all elements in the collar
                    if (sMessage == UPMENU) llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                    else if (sMessage == DUMP) UserCommand(iAuth,"dumpstyle", kAv, TRUE);
                    else UserCommand(iAuth,"style "+sMessage, kAv, TRUE);
                }
            }
        }
        else if (iNum == DIALOG_TIMEOUT)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {  //remove stride from g_lMenuIDs
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
            }
        }
    }

    dataserver(key id, string data){
        if (id == g_kNotecardReadRequest){
            if (data != EOF){
                data = llStringTrim(data,STRING_TRIM);
                if (data != "" && llGetSubString(data,0,0) != "#" )
                {
                    if( llGetSubString(data,0,0) == "[" )
                    {
                        g_sNotecardStyle = llGetSubString(data,llSubStringIndex(data,"[")+1,llSubStringIndex(data,"]")-1);
                        g_sNotecardStyle = llStringTrim(g_sNotecardStyle,STRING_TRIM);
                        g_lStyles += [g_sNotecardStyle];
                        g_lStyleSettings += [g_sNotecardStyle];
                    }
                    else g_lStyleSettings += [data];
                }
                g_kNotecardReadRequest=llGetNotecardLine(g_sNotecardName,++g_iNotecardLine);
            }
        }
    }

    changed (integer change){
        if (change & CHANGED_INVENTORY){
            if (g_iNotecardId != llGetInventoryKey(g_sNotecardName)){
                //Debug("Reading styles card");
                g_iNotecardId = llGetInventoryKey(g_sNotecardName);
                if(g_iNotecardId){
                    g_lStyles=[];
                    g_lStyleSettings=[];
                    g_iNotecardLine=0;
                    g_kNotecardReadRequest=llGetNotecardLine(g_sNotecardName,0);
                }
                //else llOwnerSay(g_sNotecardName+" notecard absent!");
            }
            CheckScripts();
        }
        if (change & CHANGED_OWNER) llResetScript();
/*
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled) {
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
*/
    }
}
