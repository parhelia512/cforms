

module cforms;

const Wstring WCNFORM         = {'C','f','o','r','m','s','_','W','i','n','d','o','w','_','C','l','a','s','s',0};

const Wstring WCNMSGONLYWIN   = {'W','i','n','f','o','r','m','s','_','M','s','g','F','o','r','m','_','C','l','a','s','s',0};

const Wstring WCNBUTTON       = {'B','u','t','t','o','n',0};

const Wstring WCNCALENDAR     = {'S','y','s','M','o','n','t','h','C','a','l','3','2',0};

const Wstring WCNCOMBO        = {'C','o','m','b','o','B','o','x',0};

const Wstring WCNDTP          = {'S','y','s','D','a','t','e','T','i','m','e','P','i','c','k','3','2',0};

const Wstring WCNSTATIC       = {'S','t','a','t','i','c',0};

const Wstring WCNLISTBOX      = {'L','i','s','t','B','o','x',0};

const Wstring WCNLISTVIEW     = {'S','y','s','L','i','s','t','V','i','e','w','3','2',0};

const Wstring WCNNUMPICK      = {'m','s','c','t','l','s','_','u','p','d','o','w','n','3','2',0};

const Wstring WCNPICTUREBOX   = {'C','f','o','r','m', 's', '_', 'P', 'i', 'c', 't', 'u', 'r', 'e', 'B', 'o', 'x', 0};

const Wstring WCNPROGRESSBAR  = {'m','s','c','t','l','s','_','p','r','o','g','r','e','s','s','3','2',0};

const Wstring WCNEDIT         = {'E','d','i','t',0};

const Wstring WCNTRACKBAR     = {'m','s','c','t','l','s','_','t','r','a','c','k','b','a','r','3','2',0};

const Wstring WCNTREEVIEW     = {'S','y','s','T','r','e','e','V','i','e','w','3','2',0};


const uint COMM_CTRL_STYLES = WS_CHILD | WS_VISIBLE | WS_TABSTOP;

const uint WSTYLE_BUTTON    = COMM_CTRL_STYLES | BS_NOTIFY;
const uint WSTYLE_CALENDAR  = COMM_CTRL_STYLES;

const uint WSTYLE_CHECK_BOX  = COMM_CTRL_STYLES | BS_AUTOCHECKBOX;
const uint WXSTYLE_CHECK_BOX = WS_EX_LTRREADING | WS_EX_LEFT;

const uint WSTYLE_COMBO_BOX  = COMM_CTRL_STYLES | CBS_DROPDOWN;
const uint WXSTYLE_COMBO_BOX = WS_EX_CLIENTEDGE;

const uint WSTYLE_DTP       = 0x52000004;
const uint WXSTYLE_DTP      = WS_EX_LEFT;

const uint WSTYLE_GB        = WS_CHILD 
                                | WS_VISIBLE 
                                | BS_GROUPBOX 
                                | BS_NOTIFY 
                                | BS_TOP 
                                | WS_CLIPCHILDREN 
                                | WS_CLIPSIBLINGS;

const uint WSTYLE_LABEL     = COMM_CTRL_STYLES | SS_NOTIFY;

const uint WSTYLE_LIST_BOX  = COMM_CTRL_STYLES
                            | LBS_HASSTRINGS
                            | WS_VSCROLL
                            | WS_BORDER
                            | LBS_NOTIFY;

const uint WSTYLE_LIST_VIEW = COMM_CTRL_STYLES
                            | LVS_REPORT
                            | WS_BORDER
                            | LVS_ALIGNLEFT
                            | LVS_SINGLESEL;

const uint WSTYLE_NUM_PICK  = COMM_CTRL_STYLES
                            | UDS_ALIGNRIGHT
                            | UDS_ARROWKEYS
                            | UDS_HOTTRACK
                            | WS_CLIPSIBLINGS;

const uint WSTYLE_PGB       = COMM_CTRL_STYLES | PBS_SMOOTH;
const uint WXSTYLE_PGB      = WS_EX_STATICEDGE;

const uint WSTYLE_RADIO     = COMM_CTRL_STYLES | BS_AUTORADIOBUTTON;

const uint WSTYLE_TB        = COMM_CTRL_STYLES 
                            | ES_LEFT 
                            | ES_AUTOHSCROLL 
                            | WS_OVERLAPPED; 
                            

const uint WXSTYLE_TB       = WS_EX_LEFT
                            | WS_EX_LTRREADING
                            | WS_EX_CLIENTEDGE;

const uint WSTYLE_TKBAR     = COMM_CTRL_STYLES | TBS_AUTOTICKS;

const uint WSTYLE_TV        = COMM_CTRL_STYLES
                            | WS_BORDER
                            | TVS_HASLINES
                            | TVS_HASBUTTONS
                            | TVS_LINESATROOT
                            | TVS_DISABLEDRAGDROP;



const bool BLK_FGC   = true;
const bool NO_FGC    = false;

const bool TXTABLE   = true;
const bool NO_TXT    = false;

const bool FONTABLE  = true;
const bool NO_FONT   = false;

bitstruct ControlTypeInfo : char
{
    BackColorMode bcm: 0..1;
    bool blackForeColor: 2..2;
    bool isTextable: 3..3;
    bool hasFont: 4..4;
}

enum ControlType : int ( String prefix, 
                        Wstring clsName, 
                        char value, 
                        ControlTypeInfo info,                     
	                    Dword wstyle,
	                    Dword wexStyle)
{ 
    NONE = {"Form_", WCNFORM, 0, {NONE, NO_FGC, NO_TXT, NO_FONT}, 0, 0},

    BUTTON = {"Button_", WCNBUTTON, 1, 
                {NONE, NO_FGC, TXTABLE, FONTABLE}, WSTYLE_BUTTON, 0},

    CALENDAR = {"Calendar_", WCNCALENDAR, 2, 
                {NONE, NO_FGC, NO_TXT, NO_FONT}, WSTYLE_CALENDAR, 0},

    CHECK_BOX = {"CheckBox_", WCNBUTTON, 3, 
                {INHERIT_BGC, BLK_FGC, TXTABLE, FONTABLE}, 
                WSTYLE_CHECK_BOX, WXSTYLE_CHECK_BOX},

    COMBO_BOX = {"ComboBox_", WCNCOMBO, 4, 
                {WHITE_BGC, BLK_FGC, TXTABLE, FONTABLE},
                WSTYLE_COMBO_BOX, WXSTYLE_COMBO_BOX},

    DATE_TIME_PICKER = {"DateTimePicker_", WCNDTP, 5, 
                        {WHITE_BGC, BLK_FGC, TXTABLE, FONTABLE},
                        WSTYLE_DTP, WXSTYLE_DTP},

    GROUP_BOX = {"GroupBox_", WCNBUTTON, 6, 
                {INHERIT_BGC, BLK_FGC, TXTABLE, FONTABLE},
                WSTYLE_GB, WS_EX_CONTROLPARENT },

    LABEL = {"Label_", WCNSTATIC, 7, 
            {INHERIT_BGC, BLK_FGC, TXTABLE, FONTABLE},
             WSTYLE_LABEL, 0},

    LIST_BOX = {"ListBox_", WCNLISTBOX, 9, 
                {WHITE_BGC, BLK_FGC, NO_TXT, FONTABLE},
                WSTYLE_LIST_BOX, 0},

    LIST_VIEW = {"ListView_", WCNLISTVIEW, 9, 
                {WHITE_BGC, BLK_FGC, NO_TXT, FONTABLE},
                 WSTYLE_LIST_VIEW, 0},

    NUM_PICKER = {"NumberPicker_", 
                    WCNNUMPICK, 10,
                    {WHITE_BGC, BLK_FGC, TXTABLE, FONTABLE},
                    WSTYLE_NUM_PICK, 0},

    PICTURE_BOX = {"PictureBox_", 
                    WCNPICTUREBOX, 11,
                    {NONE, NO_FGC, NO_TXT, NO_FONT}, COMM_CTRL_STYLES, 0},

    PROGRESS_BAR = {"ProgressBar_", 
                     WCNPROGRESSBAR, 12,
                    {NONE, BLK_FGC, TXTABLE, FONTABLE}, WSTYLE_PGB, WS_EX_STATICEDGE},   

    RADIO_BUTTON = {"RadioButton_", WCNBUTTON, 13, 
                    {INHERIT_BGC, BLK_FGC, TXTABLE, FONTABLE}, WSTYLE_RADIO, 0}, 

    TEXT_BOX = {"TextBox_", WCNEDIT, 14, 
                {WHITE_BGC, BLK_FGC, TXTABLE, FONTABLE}, WSTYLE_TB, WXSTYLE_TB},

    TRACK_BAR = {"TrackBar_", 
                    WCNTRACKBAR, 15,
                    {INHERIT_BGC, NO_FGC, NO_TXT, NO_FONT}, WSTYLE_TKBAR, 0},

    TREE_VIEW = {"TreeView_", 
                    WCNTREEVIEW, 16,
                    {WHITE_BGC, BLK_FGC, NO_TXT, FONTABLE}, WSTYLE_TV, 0}
}