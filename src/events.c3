// cforms.events - Created on 27-Jan-2023 01:56
module cforms;

alias EventHandler = fn void(Control* c, EventArgs* e);
alias MouseEventHandler = fn void(Control* c, MouseEventArgs* e);
alias SizeEventHandler = fn void(Control* c, SizeEventArgs* e);
alias KeyEventHandler = fn void(Control* c, KeyEventArgs* e);
alias DateTimeEventHandler = fn void(Control* c, DateTimeEventArgs* e);
alias ThreadMsgHandler = fn void(Wparam wpm, Lparam lpm);
alias TrayIconEventHandler = fn void(TrayIcon* c, EventArgs* e);
alias MenuEventHandler = fn void(MenuItem*, EventArgs*);
alias NodeNotifyHandler = fn void(TreeView* this, TreeNode* node, String prop, void* data);
alias LVItemEventHandler = fn void(ListView* this, LVItemEventArgs* e);
alias LVSelChangeEventHandler = fn void(ListView* this, LVSelChangedEventArgs* e);
alias LVItemCheckEventHandler = fn void(ListView* this, LVItemCheckEventArgs* e);

struct Area
{
	int width;
	int height;
}

struct EventArgs
{
	bool handled;
}

struct MouseEventArgs
{
	inline EventArgs eventArgs;
	MouseButton button;
	bool isShiftPressed;
	bool isCtrlPressed;
	int x;
	int y;
	int delta;
}

struct SizeEventArgs
{
	inline EventArgs eventArgs;
	Rect formRect;
	SizedPosition sizedOn;
	Area clientArea;
}

struct KeyEventArgs
{
	inline EventArgs eventArgs;
	Keys keyCode;
	Keys modifier;
	int keyValue;
	bool altPressed;
	bool ctrlPressed;
	bool shiftPressed;
	bool supressKey;
}

struct DateTimeEventArgs
{
    inline EventArgs eventArgs;
    Lpcwstr dateString;
    SystemTime dateStruct;
}

struct LVItemEventArgs 
{
	inline EventArgs base;
	ListViewItem* item;
	int index;
}


struct LVSelChangedEventArgs
{
	inline LVItemEventArgs base;
	bool isSelected;
}

struct LVItemCheckEventArgs 
{
	inline LVItemEventArgs base;
	bool isChecked;
}

fn MouseEventArgs newMouseEventArgs(uint msg, Wparam wpm, Lparam lpm)
{
	Word fwKeys = getKeyStateWparam(wpm);
	MouseEventArgs m;
	m.delta = (int)(hiWord(wpm));
	switch (fwKeys) {
		case 5: m.isShiftPressed = true;
		case 9: m.isCtrlPressed = true;
	}
	if (fwKeys == 17) m.button = MouseButton.MIDDLE;
	if (fwKeys == 33) m.button = MouseButton.XBUTTON1;

	switch (msg) {
		case WM_MOUSEWHEEL: nextcase WM_NCHITTEST;
		case WM_MOUSEMOVE: nextcase WM_NCHITTEST;
		case WM_MOUSEHOVER: nextcase WM_NCHITTEST;
		case WM_NCHITTEST:
			m.x = (int)(loWord((Dword) lpm));
			m.y = (int)(hiWord((Dword) lpm));
		case WM_LBUTTONDOWN: nextcase WM_LBUTTONUP;
		case WM_LBUTTONUP:
			m.button = MouseButton.LEFT;
			m.x = (int)(loWord((Dword) lpm));
			m.y = (int)(hiWord((Dword) lpm));
		case WM_RBUTTONDOWN: nextcase WM_RBUTTONUP;
		case WM_RBUTTONUP:
			m.button = MouseButton.RIGHT;
			m.x = (int) (loWord((Dword) lpm));
			m.y = (int) (hiWord((Dword) lpm));
	}
	return m;
}

fn SizeEventArgs newSizeEventArgs(uint msg, Wparam wpm, Lparam lpm)
{
	SizeEventArgs sea;
	if (msg == WM_SIZING) {
		sea.sizedOn = SizedPosition.from_ordinal(wpm);
		sea.formRect = *((Rect*) lpm);
	} else {
		sea.clientArea.width = loWord(lpm);
		sea.clientArea.height = hiWord(lpm);
	}
	return sea;
}

fn KeyEventArgs newKeyEventArgs(Wparam wpm)
{
	// log("93");
	KeyEventArgs this;
	this.keyCode = Keys.from_ordinal(wpm);
	switch (this.keyCode) {
		case SHIFT:
			this.shiftPressed = true;
			this.modifier = Keys.SHIFT_MODIFIER;
		case CTRL:
			this.ctrlPressed = true;
			this.modifier = Keys.CTRL_MODIFIER;
		case ALT:
			this.altPressed = true;
			this.modifier = Keys.ALT_MODIFIER;
        default: break;
	}
	this.keyValue = this.keyCode.value;
	return this;
}

fn DateTimeEventArgs newDateTimeEventArgs(Lpcwstr dtpStr)
{
    DateTimeEventArgs this;
    this.dateString = dtpStr;
    return this;
}



macro Word loWord(x) {return (ushort)x;}
macro Word hiWord(x) {return (ushort)(x >> 16);}
fn Word loWordWparam(Wparam wp) @inline {return (Word)(wp & 0xffff);}
fn Word hiWordWparam(Wparam wp) @inline {return (Word)(wp >> 16);}
fn int xFromLparam(Lparam lpm) @inline { return (int)((short)loWord(lpm));}
fn int yFromLparam(Lparam lpm) @inline { return (int)((short)hiWord(lpm));}

fn Word getKeyStateWparam(Wparam wp) {return (Word)loWordWparam(wp);}




interface IMouseEvents
{
    // fn void test() ;
    fn void onleftClick(Control* c, EventArgs* e) @optional;
}