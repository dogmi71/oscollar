////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                            OpenCollar - meshlabel                              //
//                              version 160727.1                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

string g_sParentMenu = "Apps";
string g_sSubMenu = "Label";

key g_kWearer;

integer g_iAppLock = FALSE;
string g_sAppLockToken = "Appearance_Lock";

//opencollar MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;

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

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

integer g_iCharLimit = -1;

string UPMENU = "BACK";
string CTYPE = "collar";

string g_sTextMenu = "Set Label";
string g_sFontMenu = "Font";
string g_sColorMenu = "Color";

key g_kDialogID;
key g_kTBoxID;
key g_kFontID;
key g_kColorID;

list g_lColours=[
    "Gray Shade",<0.70588, 0.70588, 0.70588>,
    "Gold Shade",<0.69020, 0.61569, 0.43529>,
    "Baby Pink",<1.00000, 0.52157, 0.76078>,
    "Hot Pink",<1.00000, 0.05490, 0.72157>,
    "Firefighter",<0.88627, 0.08627, 0.00392>,
    "Flame",<0.92941, 0.43529, 0.00000>,
    "Matrix",<0.07843, 1.00000, 0.07843>,
    "Electricity",<0.00000, 0.46667, 0.92941>,
    "Violet Wand",<0.63922, 0.00000, 0.78824>,
    "Black",<0.00000, 0.00000, 0.00000>,
    "White",<1.00000, 1.00000, 1.00000>
];
string g_sCharmap = "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~¡¢£¤¥¦§¨©ª«¬®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿĀāĂăĄąĆćĈĉĊċČčĎďĐđĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħĨĩĪīĬĭĮįİıĲĳĴĵĶķĸĹĺĻļĽľĿŀŁłŃńŅņŇňŉŊŋŌōŎŏŐőŒœŔŕŖŗŘřŚśŜŝŞşŠšŢţŤťŦŧŨũŪūŬŭŮůŰűŲųŴŵŶŷŸŹźŻżŽžſƒƠơƯưǰǺǻǼǽǾǿȘșʼˆˇˉ˘˙˚˛˜˝˳̣̀́̃̉̏΄΅Ά·ΈΉΊΌΎΏΐΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩΪΫάέήίΰαβγδεζηθικλμνξοπρςστυφχψωϊϋόύώϑϒϖЀЁЂЃЄЅІЇЈЉЊЋЌЍЎЏАБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдежзийклмнопрстуфхцчшщъыьэюяѐёђѓєѕіїјљњћќѝўџѠѡѢѣѤѥѦѧѨѩѪѫѬѭѮѯѰѱѲѳѴѵѶѷѸѹѺѻѼѽѾѿҀҁ҂҃҄҅҆҈҉ҊҋҌҍҎҏҐґҒғҔҕҖҗҘҙҚқҜҝҞҟҠҡҢңҤҥҦҧҨҩҪҫҬҭҮүҰұҲҳҴҵҶҷҸҹҺһҼҽҾҿӀӁӂӃӄӅӆӇӈӉӊӋӌӍӎӏӐӑӒӓӔӕӖӗӘәӚӛӜӝӞӟӠӡӢӣӤӥӦӧӨөӪӫӬӭӮӯӰӱӲӳӴӵӶӷӸӹӺӻӼӽӾӿԀԁԂԃԄԅԆԇԈԉԊԋԌԍԎԏԐԑԒԓḀḁḾḿẀẁẂẃẄẅẠạẢảẤấẦầẨẩẪẫẬậẮắẰằẲẳẴẵẶặẸẹẺẻẼẽẾếỀềỂểỄễỆệỈỉỊịỌọỎỏỐốỒồỔổỖỗỘộỚớỜờỞởỠỡỢợỤụỦủỨứỪừỬửỮữỰựỲỳỴỵỶỷỸỹὍ–—―‗‘’‚‛“”„†‡•…‰′″‹›‼⁄ⁿ₣₤₧₫€℅ℓ№™Ω℮⅛⅜⅝⅞∂∆∏∑−√∞∫≈≠≤≥◊ﬁﬂﬃﬄ￼ ";

list g_lFonts = [
    "Solid", "464e8b47-d578-4e24-a671-de7c2f2b7a24",
    "Outlined", "efeb123d-a014-4586-8012-62086272ccaf"
    ];

key g_kFontTexture = "464e8b47-d578-4e24-a671-de7c2f2b7a24";

integer x = 45;
integer y = 19;

integer faces = 6;

float g_fScrollTime = 0.3 ;
integer g_iSctollPos ;
string g_sScrollText;
list g_lLabelLinks ;

integer g_iScroll = FALSE;
integer g_iShow;
vector g_vColor = <1,1,1>;

string g_sLabelText = "";
string g_sSettingToken = "label_";
//string g_sGlobalToken = "global_";

float Ureps;
float Vreps;

string g_sScript = "label_";

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

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|"
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    //Debug("Made menu.");
    return kID;
}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else
    {
        if (llGetAgentSize(kID)!=ZERO_VECTOR) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}


integer GetIndex(string sChar) {
    integer i;
    if (sChar == "") return 854;
    else i = llSubStringIndex(g_sCharmap, sChar);
    if (i>=0) return i;
    else return 854;
}


RenderString(integer iPos, string sChar) {  // iPos - позиция символа на лейбле
    integer frame = GetIndex(sChar);  //номер символа в таблице
    integer i = iPos/faces;
    integer link = llList2Integer(g_lLabelLinks,i);
    integer face = iPos - faces * i;
    integer frameY = frame / x;
    integer frameX = frame - x * frameY;
    float Uoffset = -0.5 + (Ureps/2 + Ureps*(frameX)) ;
    float Voffset = 0.5 - (Vreps/2 + Vreps*(frameY)) ;
    llSetLinkPrimitiveParamsFast(link, [PRIM_TEXTURE, face, g_kFontTexture, <Ureps, Vreps,0>, <Uoffset, Voffset, 0>, 0]);
}

SetColor() {
    integer i=0;
    do {
        integer iLink = llList2Integer(g_lLabelLinks,i);
        float fAlpha = llList2Float(llGetLinkPrimitiveParams( iLink,[PRIM_COLOR,ALL_SIDES]),1);
        llSetLinkPrimitiveParamsFast(iLink, [PRIM_COLOR, ALL_SIDES, g_vColor, fAlpha]);
    } while (++i < llGetListLength(g_lLabelLinks));
}

// find all 'Label' prims, count and store it's link numbers for fast work SetLabel() and timer
integer LabelsCount() {
    integer ok = TRUE ;
    g_lLabelLinks = [] ;

    string sLabel;
    list lTmp;
    integer iLink;
    integer iLinkCount = llGetNumberOfPrims();
    //find all 'Label' prims and count it's
    for(iLink=2; iLink <= iLinkCount; iLink++) {
        lTmp = llParseString2List(llList2String(llGetLinkPrimitiveParams(iLink,[PRIM_NAME]),0), ["~"],[]);
        sLabel = llList2String(lTmp,0);
        if(sLabel == "MeshLabel") {
            g_lLabelLinks += [0]; // fill list witn nulls
            //change prim description
            llSetLinkPrimitiveParamsFast(iLink,[PRIM_DESC,"Label~notexture~nocolor~nohide~noshiny"]);
        }
    }
    g_iCharLimit = llGetListLength(g_lLabelLinks) * 6;
    //find all 'Label' prims and store it's links to list
    for(iLink=2; iLink <= iLinkCount; iLink++) {
        lTmp = llParseString2List(llList2String(llGetLinkPrimitiveParams(iLink,[PRIM_NAME]),0), ["~"],[]);
        sLabel = llList2String(lTmp,0);
        if (sLabel == "MeshLabel") {
            integer iLabel = (integer)llList2String(lTmp,1);
            integer link = llList2Integer(g_lLabelLinks,iLabel);
            if (link == 0)
                g_lLabelLinks = llListReplaceList(g_lLabelLinks,[iLink],iLabel,iLabel);
            else {
                ok = FALSE;
                llOwnerSay("Warning! Found duplicated label prims: "+sLabel+" with link numbers: "+(string)link+" and "+(string)iLink);
            }
        }
    }
    if (!ok) {
        if ((~llSubStringIndex(llGetObjectName(),"Installer")) && (~llSubStringIndex(llGetObjectName(),"Updater"))) 
            return 1;
    }
    return ok;
}

SetLabel() {
    string sText ;
    if (g_iShow) sText = g_sLabelText;

    string sPadding;
    if(g_iScroll==TRUE) {
        while(llStringLength(sPadding) < g_iCharLimit) sPadding += " ";
        g_sScrollText = sPadding + sText;
        llSetTimerEvent(g_fScrollTime);
    } else {
        g_sScrollText = "";
        llSetTimerEvent(0);
        //inlined single use CenterJustify function
        while(llStringLength(sPadding + sText + sPadding) < g_iCharLimit) sPadding += " ";
        sText = sPadding + sText;
        integer iCharPosition;
        for(iCharPosition=0; iCharPosition < g_iCharLimit; iCharPosition++)
            RenderString(iCharPosition, llGetSubString(sText, iCharPosition, iCharPosition));
    }
    //Debug("Label Set");
}


MainMenu(key kID, integer iAuth)
{
    list lButtons= [g_sTextMenu, g_sColorMenu, g_sFontMenu];
    if (g_iShow) lButtons += ["☒ Show"];
    else lButtons += ["☐ Show"];
    
    if (g_iScroll) lButtons += ["☒ Scroll"];
    else lButtons += ["☐ Scroll"];    
        
    string sPrompt = "\nCustomize the " + CTYPE + "'s label!\n\nwww.opencollar.at/label";
    g_kDialogID=Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

TextMenu(key kID, integer iAuth)
{
    string sPrompt="\n- Submit the new label in the field below.\n- Submit a few spaces to clear the label.\n- Submit a blank field to go back to " + g_sSubMenu + ".\n\nwww.opencollar.at/label";
    g_kTBoxID = Dialog(kID, sPrompt, [], [], 0, iAuth);
}

ColorMenu(key kID, integer iAuth)
{
    string sPrompt = "\n\nSelect a colour from the list";
    list lColourNames;
    integer numColours=llGetListLength(g_lColours)/2;
    while (numColours--)
    {
        lColourNames+=llList2String(g_lColours,numColours*2);
    }
    g_kColorID=Dialog(kID, sPrompt, lColourNames, [UPMENU], 0, iAuth);
}

FontMenu(key kID, integer iAuth)
{
    list lButtons=llList2ListStrided(g_lFonts,0,-1,2);
    string sPrompt = "\nSelect the font for the " + CTYPE + "'s label.\n\nNOTE: This feature requires a design with label prims. If the worn design doesn't have any of those, it is recommended to uninstall Label with the updater.\n\nwww.opencollar.at/label";

    g_kFontID=Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}


integer UserCommand(integer iAuth, string sStr, key kAv)
{
    if (iAuth > COMMAND_WEARER || iAuth < COMMAND_OWNER) return FALSE; // sanity check
    
    if (iAuth == COMMAND_OWNER || !g_iAppLock)
    {
        if (sStr == "menu " + g_sSubMenu || llToLower(sStr)=="label") 
        {
            MainMenu(kAv, iAuth);
            return TRUE;
        }        
        
        list lParams = llParseString2List(sStr, [" "], []);
        string sCommand = llToLower(llList2String(lParams, 0));

        if (sCommand == "lockappearance" && iAuth == COMMAND_OWNER) {
            if (llToLower(llList2String(lParams, 1)) == "0") g_iAppLock = FALSE;
            else g_iAppLock = TRUE;
        } else if (sCommand == "labeltext") {
            g_sLabelText = llStringTrim(llDumpList2String(llDeleteSubList(lParams,0,0)," "),STRING_TRIM);
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "text=" + g_sLabelText, "");
            if (llStringLength(g_sLabelText) > g_iCharLimit) {
                string sDisplayText = llGetSubString(g_sLabelText, 0, g_iCharLimit-1);
                Notify(kAv,"Unless you set your label to scroll it will be truncated at "+sDisplayText+".", FALSE);
            }
            SetLabel();
        } else if (sCommand == "labelfont") {
            lParams = llDeleteSubList(lParams, 0, 0);
            string font = llDumpList2String(lParams, " ");
            integer iIndex = llListFindList(g_lFonts, [font]);
            if (iIndex != -1)
            {
                g_kFontTexture = (key)llList2String(g_lFonts, iIndex + 1);
                SetLabel();
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "font=" + (string)g_kFontTexture, "");
            }
            else FontMenu(kAv, iAuth);            
        } else if (sCommand == "labelcolor") {
            string sColour= llDumpList2String(llDeleteSubList(lParams,0,0)," ");
            integer colourIndex=llListFindList(g_lColours,[sColour]);
            if (~colourIndex)
            {
                g_vColor=(vector)llList2String(g_lColours,colourIndex+1);
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"color="+(string)g_vColor, "");
                SetColor();
            }
        } else if (sCommand == "labelshow") {
            g_iShow = llList2Integer(lParams, 1);
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"show="+(string)g_iShow, "");
            SetLabel();
        } else if (sCommand == "labelscroll") {
            g_iScroll = llList2Integer(lParams, 1);
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"scroll="+(string)g_iScroll, "");
            SetLabel();
        }
    }
    else if ((iAuth >= COMMAND_SECOWNER && iAuth <= COMMAND_WEARER) && g_iAppLock)
    {
        string sCommand = llToLower(llList2String(llParseString2List(sStr, [" "], []), 0));        
        if (sStr=="menu "+g_sSubMenu)
        {
            llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
            Notify(kAv,"Only owners can change the label!", FALSE);
        }
        else if (sCommand=="labeltext" || sCommand == "labelfont" || sCommand == "labelcolor" || sCommand == "labelshow")
        {
            Notify(kAv,"Only owners can change the label!", FALSE);
        }
    }
        
    return TRUE;
}

default
{
    state_entry() {
        //llSetMemoryLimit(65536);  //this script needs to be profiled, and its memory limited
        g_sScript = "meshlabel_";
        g_kWearer = llGetOwner();
        Ureps = (float)1 / x;
        Vreps = (float)1 / y;
        LabelsCount();

        if (g_iCharLimit <= 0) {
            llMessageLinked(LINK_SET, MENUNAME_REMOVE, g_sParentMenu + "|" + g_sSubMenu, "");
            llRemoveInventory(llGetScriptName());
        }
        // g_sLabelText = llList2String(llParseString2List(llKey2Name(llGetOwner()), [" "], []), 0);
        //SetLabel();
        //Debug("Starting");
    }

    on_rez(integer iNum) {
        if (g_kWearer != llGetOwner()) {
            g_sLabelText = "";
            SetLabel();
        }
        llResetScript();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if ( UserCommand(iNum, sStr, kID) ) {}
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sScript)
            {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == "text") g_sLabelText = sValue;
                else if (sToken == "font") g_kFontTexture = (key)sValue;
                else if (sToken == "color") g_vColor = (vector)sValue;
                else if (sToken == "show") g_iShow = (integer)sValue;
                else if (sToken == "scroll") g_iScroll = (integer)sValue;                
            }
            else if (sToken == g_sAppLockToken) g_iAppLock = (integer)sValue;
            else if (sToken == "Global_CType") CTYPE = sValue;
            else if (sToken == "settings" && sValue == "sent") {
                SetColor();
                SetLabel();
            }
        }
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            if (kID==g_kDialogID)
            {
                //got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage == UPMENU) llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                else if (sMessage == g_sTextMenu) TextMenu(kAv, iAuth);
                else if (sMessage == g_sColorMenu) ColorMenu(kAv, iAuth);
                else if (sMessage == g_sFontMenu) FontMenu(kAv, iAuth);
                else if (sMessage == "☐ Show") 
                {
                    UserCommand(iAuth, "labelshow 1", kAv);
                    MainMenu(kAv, iAuth);
                }
                else if (sMessage == "☒ Show") 
                {
                    UserCommand(iAuth, "labelshow 0", kAv);
                    MainMenu(kAv, iAuth);
                }
                else if (sMessage == "☐ Scroll") 
                {
                    UserCommand(iAuth, "labelscroll 1", kAv);
                    MainMenu(kAv, iAuth);
                }
                else if (sMessage == "☒ Scroll") 
                {
                    UserCommand(iAuth, "labelscroll 0", kAv);
                    MainMenu(kAv, iAuth);
                }
            }
            else if (kID == g_kColorID)
            {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage == UPMENU) MainMenu(kAv, iAuth);
                else
                {
                    UserCommand(iAuth, "labelcolor "+sMessage, kAv);
                    ColorMenu(kAv, iAuth);
                }
            }
            else if (kID == g_kFontID)
            {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage == UPMENU) MainMenu(kAv, iAuth);
                else
                {
                    UserCommand(iAuth, "labelfont " + sMessage, kAv);
                    FontMenu(kAv, iAuth);
                }
            }
            else if (kID == g_kTBoxID) // TextBox response, extract values
            {
                list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage != "") UserCommand(iAuth, "labeltext " + sMessage, kAv);
                llMessageLinked(LINK_ROOT, iAuth, "menu " + g_sSubMenu, kAv);
            }
        }
    }

    timer()
    {
        string sText = llGetSubString(g_sScrollText, g_iSctollPos, -1);
        integer iCharPosition;
        for(iCharPosition=0; iCharPosition < g_iCharLimit; iCharPosition++)
        {
            RenderString(iCharPosition, llGetSubString(sText, iCharPosition, iCharPosition));
        }
        g_iSctollPos++;
        if(g_iSctollPos > llStringLength(g_sScrollText)) g_iSctollPos = 0 ;
    }

    changed(integer change) {
        if(change & CHANGED_LINK) // if links changed
        {
            if (LabelsCount()==TRUE) SetLabel();
        }
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
