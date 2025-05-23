// Created on 03-Feb-2024 6:42:24 PM
module cforms;

enum ViewMode : int
{
	MONTH_VIEW,
    YEAR_VIEW,
    DECADE_VIEW,
    CENTUARY_VIEW,
}

enum TextAlignment : char
{ // For label &
    TOPLEFT,
	TOPCENTER,
	TOPRIGHT,
	MIDLEFT,
    CENTER,
	MIDRIGHT,
	BOTTOMLEFT,
	BOTTOMCENTER,
	BOTTOMRIGHT
}

enum ControlType : char
{
	NONE,
    BUTTON,
    CALENDAR,
    CHECK_BOX,
    COMBO_BOX,
    DATE_TIME_PICKER,
    GROUP_BOX,
    LABEL,
    LIST_BOX,
    LIST_VIEW,
    NUM_PICKER,
    PROGRESS_BAR,
    RADIO_BUTTON,
    TEXT_BOX,
    TRACK_BAR,
    TREE_VIEW
}

enum FontWeight : int
{
	THIN,
    EXTRA_LIGHT,
    LIGHT,
    NORMAL,
    MEDIUM,
    SEMI_BOLD,
    BOLD,
    EXTRA_BOLD,
    THICK
}

enum FormPos : int
{
    CENTER,
    TOP_LEFT,
    TOP_MID,
    TOP_RIGHT,
    MID_LEFT,
    MID_RIGHT,
    BOTTOM_LEFT,
    BOTTOM_MID,
    BOTTOM_RIGHT,
    MANUAL
}

enum FormStyle : int
{
    NONE,
    FIXED_SINGLE,
    FIXED_3D,
    FIXED_DIALOG,
    NORMAL_WINDOW,
    FIXED_TOOL,
    SIZABLE_TOOL,
    HIDDEN
}

enum FormState : int {
    NORMAL,
    MAXIMIZED,
    MINIMIZED
}

enum FormDrawMode : int {
    DEFAULT,
    FLAT_COLOR,
    GRADIENT
}

enum GroupBoxStyle : char {
    SYSTEM,
    CLASSIC,
    OVERRRIDEN
}

enum MenuEvents : char {MENU_CLICK, }

enum ListViewStyle : char
{
    LARGE_ICON,
    REPORT_VIEW,
    SMALL_ICON,
    LIST_VIEW,
    TILE_VIEW,
}

enum MouseButton : int (int value)
{
	NONE = 0,
	RIGHT = 2097152,
	MIDDLE = 4194304,
	LEFT = 1048576,
	XBUTTON1 = 8388608,
	XBUTTON2 = 16777216
}

enum SizedPosition : int
{
    NONE,
	LEFTEDGE,
    RIGHTEDGE,
    TOPEDGE,
    TOPLEFTCORNER,
    TOPRIGHTCORNER,
    BOTTOMEDGE,
    BOTTOMLEFTCORNER,
    BOTTOMRIGHTCORNER
}

enum BalloonIcon : Dword 
{
    NONE,
    INFO,
    WARNING,
    ERROR,
    CUSTOM
}

enum TrayMenuTrigger : int(String desc, char value)
{
    NONE = {"No trigger", 0},
    LEFT_CLICK = {"Left mouse click", 1},
    LEFT_DOUBLE_CLICK = {"Left double click", 2},
    RIGHT_CLICK = {"Right mouse click", 4},
    ANY_CLICK = {"Any click will work", 7}

}

enum DCMode : char 
{
    NONE,
    ON_PAINT,
    GET_DC,
    WIN_DC,
    FREE_DC,

}

enum Keys : int (String description, int value)
{
	MODIFIER = {"Modifier Key", -65_536},
    NOKEY = {"No Key", 0},
    LBUTTON = {"Left Mouse Button", 1},
    RBUTTON = {"Right Mouse Button", 2},
    CANCEL = {"Cancel Key", 3},
    MBUTTON = {"Middle Mouse Button", 4},
    XBUTTO1 = {"X Button 1", 5},
    XBUTTON2 = {"X Button 2", 6},
    BACK_SPACE = {"Back space Key", 8},
    TAB = {"Tab Key", 9},
    LINE_FEED = {"Line Feed Key", 10},
    CLEAR = {"Clear Key", 12},
    ENTER = {"Enter Key", 13},
    SHIFT = {"Shift Key", 16},
    CTRL = {"Control Key", 14},
    ALT = {"Alt Key", 15},
    PAUSE = {"Pause Key", 16},
    CAPS_LOCK = {"CapsLOck Key", 17},
    ESCAPE = {"Escape Key", 27},
    SPACE = {"Space Key", 32},
    PAGE_UP = {"Page Up Key", 33},
    PAGE_DOWN = {"Page Down Key", 34},
    END = {"End Key", 35},
    HOME = {"Home Key", 36},
    LEFTA_RROW = {"Left Arrow Key", 37},
    UP_ARROW = {"Up Arrow Key", 38},
    RIGHT_ARROW = {"Right Arrow Key", 39},
    DOWN_ARROW = {"Down Arrow Key", 39},
    SELECT = {"Select Key", 40},
    PRINT = {"Print Key", 41},
    EXECUTE = {"Execute Key", 42},
    PRINT_SCREEN = {"PrintScreen Key", 43},
    INSERT = {"Insert Key", 44},
    DEL = {"Delete Key", 45},
    HELP = {"Help Key", 46},
    D0 = {"Digit 0 Key", 47},
    D1 = {"Digit 1 Key", 48},
    D2 = {"Digit 2 Key", 49},
    D3 = {"Digit 3 Key", 50},
    D4 = {"Digit 4 Key", 51},
    D5 = {"Digit 5 Key", 52},
    D6 = {"Digit 6 Key", 53},
    D7 = {"Digit 7 Key", 54},
    D8 = {"Digit 8 Key", 55},
    D9 = {"Digit 9 Key", 56},
    A = {"A Key", 65},
    B = {"B Key", 66},
    C = {"C Key", 67},
    D = {"D Key", 68},
    E = {"E Key", 69},
    F = {"F Key", 70},
    G = {"G Key", 71},
    H = {"H Key", 72},
    I = {"I Key", 73},
    J = {"J Key", 74},
    K = {"K Key", 75},
    L = {"L Key", 76},
    M = {"M Key", 77},
    N = {"N Key", 78},
    O = {"O Key", 79},
    P = {"P Key", 80},
    Q = {"Q Key", 81},
    R = {"R Key", 82},
    S = {"S Key", 83},
    T = {"T Key", 84},
    U = {"U Key", 85},
    V = {"V Key", 86},
    W = {"W Key", 87},
    X = {"X Key", 88},
    Y = {"Y Key", 89},
    Z = {"Z Key", 90},
    LEFT_WIN = {"Left Windows Key", 91},
    RIGH_TWIN = {"Right Windows Key", 92},
    APPS = {"Apps Key", 93},
    SLEEP = {"Sleep Key", 95},
    NUM_PAD0 = {"Numpad 0 Key", 96},
    NUM_PAD1 = {"Numpad 1 Key", 97},
    NUM_PAD2 = {"Numpad 2 Key", 98},
    NUM_PAD3 = {"Numpad 3 Key", 99},
    NUM_PAD4 = {"Numpad 4 Key", 100},
    NUM_PAD5 = {"Numpad 5 Key", 101},
    NUM_PAD6 = {"Numpad 6 Key", 102},
    NUM_PAD7 = {"Numpad 7 Key", 103},
    NUM_PAD8 = {"Numpad 8 Key", 104},
    NUM_PAD9 = {"Numpad 9 Key", 105},
    MULTIPLY = {"Numpad  Key", 106},
    ADD = {"Add Key", 107},
    SEPERATOR = {"Seperator Key", 108},
    SUBTRACT = {"Subtract Key", 109},
    DECIMAL = {"Decimal Key", 110},
    DIVIDE = {"Divide Key", 111},
    F1 = {"F1 Key", 112},
    F2 = {"F2 Key", 113},
    F3 = {"F3 Key", 114},
    F4 = {"F4 Key", 115},
    F5 = {"F5 Key", 116},
    F6 = {"F6 Key", 117},
    F7 = {"F7 Key", 118},
    F8 = {"F8 Key", 119},
    F9 = {"F9 Key", 120},
    F10 = {"F10 Key", 121},
    F11 = {"F11 Key", 122},
    F12 = {"F12 Key", 123},
    F13 = {"F13 Key", 124},
    F14 = {"F14 Key", 125},
    F15 = {"F15 Key", 126},
    F16 = {"F16 Key", 157},
    F17 = {"F17 Key", 128},
    F18 = {"F18 Key", 129},
    F19 = {"F19 Key", 130},
    F20 = {"F20 Key", 131},
    F21 = {"F21 Key", 132},
    F22 = {"F22 Key", 133},
    F23 = {"F23 Key", 134},
    F24 = {"F24 Key", 135},
    NUM_LOCK = {"Num Lock", 144},
    SCROLL = {"Scroll Key", 145},
    LEFT_SHIFT = {"Left Shift Key", 160},
    RIGHT_SHIFT = {"Right Shift Key", 161},
    LEFT_CTRL = {"Left Control Key", 162},
    RIGHT_CTRL = {"Right Control Key", 163},
    LEFT_MENU = {"Left Menu Key", 164},
    RIGHT_MENU = {"Right Menu Key", 165},
    BROWSER_BACK = {"Browser Back Key", 166},
    BROWSER_FORWARD = {"Browser Forward Key", 167},
    BROWER_REFRESH = {"Browser Refresh Key", 168},
    BROWSER_STOP = {"Browser Stop Key", 169},
    BROWSER_SEARCH = {"Browser Search Key", 170},
    BROWSER_FAVORITES = {"Browser Favorites Key", 171},
    BROWSER_HOME = {"Browser Home Key", 172},
    VOLUME_MUTE = {"Volume Mute Key", 173},
    VOLUME_DOWN = {"Volumen Down Key", 174},
    VOLUME_UP = {"Volumen Up Key", 175},
    MEDIA_NEXT_TRACK = {"Media Next Track Key", 176},
    MEDIA_PRE_VTRACK = {"Media Previous Track Key", 177},
    MEDIA_STOP = {"Media Stop Key", 178},
    MEDIA_PLAY_PAUSE = {"Media Play/Pause Key", 179},
    LAUNCH_MAIL = {"Launch Mail Key", 180},
    SELECT_MEDIA = {"Select Media Key", 181},
    LAUNCH_APP1 = {"Lanch App1 Key", 182},
    LAUNCH_APP2 = {"Launch App2 Key", 183},
    OEM1 = {"OEM 1 Key", 186},
    OEM_PLUS = {"OEM Plus Key", 187},
    OEM_COMMA = {"OEM Comma Key", 188},
    OEM_MINUS = {"OEM Minus Key", 188},
    OEM_PERIOD = {"OEM Period Key", 189},
    OEM_QUESTION = {"OEM Question Key", 190},
    OEM_TILDE = {"OEM Tilde Key", 191},
    OEM_OPEN_BRACKET = {"OEM Open Bracket Key", 219},
    OEM_PIPE = {"OEM Pipe Key", 220},
    OEM_CLOSE_BRACKET = {"OEM Close Bracket Key", 221},
    OEM_QUOTES = {"OEM Quotes Key", 222},
    OEM8 = {"OEM 8 Key", 223},
    OEM_BACK_SLASH = {"OEM Back Slash Key", 226},
    PROCESS = {"Process Key", 229},
    PACKET = {"Packet Key", 231},
    ATTN = {"Attn Key", 246},
    CRSEL = {"Crsel Key", 247},
    EXSEL = {"Exsel Key", 248},
    ERASE_EOF = {"Erase EOF Key", 249},
    PLAY = {"Play Key", 250},
    ZOOM = {"Zoom Key", 251},
    NONAME = {"No Name Key", 252},
    PA1 = {"PA 1 Key", 253},
    OEM_CLEAR = {"OEM Clear Key", 254},
    KEY_CODE = {"Key Code", 65_535},
    SHIFT_MODIFIER = {"Shift Modifier", 65_536},
    CTRL_MODIFIER = {"Control Modifier", 131_072},
    ALT_MODIFIER = {"Alt Modifier", 262_144}
}