// numberpicker module - Created on 09-Feb-2023 12:37
/*================================NumberPicker Docs==================
	Constructor - newNumberPicker -> NumberPicker*
	Properties:
		All Control struct properties are inherited
		hideSelection	: bool
		hideCaret		: bool
		trackMouseLeave	: bool
		buttonLeft		: bool
		hasSeperator	: bool
		autoRotate		: bool
		minRange		: double
		maxRange		: double
		value			: double
		step			: double
		fmtStr			: Dstring
		deciPrec		: uint	
		textPos			: Alignment
	Methods
		createHandle
		setDeciPrec
		setButtonLeft
		setMinRange
		setMaxRange
		setValue
		setStep

	Events
		All public events inherited from Control struct. (See controls.c3)
		EventHandler type - fn void(Control*, EventArgs*)
			onValueChanged
======================================================================================== */

module cforms;
// import std::io;
import std::math;


int npNumber = 1;
Wstring npClass = {'m', 's', 'c', 't', 'l', 's', '_', 'u', 'p', 'd', 'o', 'w', 'n', '3', '2', 0};


// NumberPicker control struct
struct NumberPicker
{
	inline Control control;
	bool hideSelection;
	bool hideCaret;
	bool trackMouseLeave;
	bool buttonLeft;
	bool hasSeperator;
	bool autoRotate;
	bool _keyPressed;
	double minRange;
	double maxRange;
	double value;
	double step ;
	DString fmtStr;
	DString _valStr;
	uint deciPrec;
	int _linex; // The x coordinate for drawing line over the right/left border.
	Hbrush _borderBrush; // Used to cover the three borders of buddy control.
	Hpen _borderPen;
	Dword _buddyStyle;
	Dword _buddyExStyle;
	Dword _topEdgeFlag;
	Dword _botEdgeFlag;
	Hwnd _buddyHandle;
	uint _buddySubClsID;
	iptr _buddyCid;
	Alignment textPos;
	Rect _udRect;
	Rect _tbRect;
	Rect _myRect;
	EventHandler onValueChanged;
}

// Public functions
	// NumberPicker constructor
	fn NumberPicker* newNumberPicker(Form* parent, int x = 10, int y = 10,
										int width = 75, int height = 25,
										EventHandler evtFn = null,
										bool btnLeft = false)
	{
		NumberPicker* this = allocator::new(mem, NumberPicker);
		this.kind = ControlType.NUM_PICKER;
		this.name = dstring::new(mem, "NumberPicker_");
		this._className = &npClass[0];
		this._parent = parent;
		//this.font = parent.font;
		this._style = NPSTYLE;
		this._exStyle = 0;
		this.xpos = x;
		this.ypos = y;
		this.width = width;
		this.height = height;
		this.maxRange = 100;
		this.minRange = 0;
		this.deciPrec = 0;
		this.buttonLeft = btnLeft;
		this.step = 1;
		this._buddyStyle = NPBUDDYSTYLE;
		this._buddyExStyle = WS_EX_LEFT | WS_EX_LTRREADING;
		this._topEdgeFlag = BF_TOPLEFT;
		this._botEdgeFlag = BF_BOTTOM;
		this.textPos = Alignment.LEFT;
		this.fmtStr = dstring::new(mem, "%d");
		this._valStr = dstring::new(mem, "0");
		this.backColor = newColor(0xffffff);
		this.foreColor = newColor(0x000000);
		this.font.cloneFrom(parent.font);
		this._parent.controls.push(this);
		if (evtFn) this.onValueChanged = evtFn;
		npNumber += 1;
		if (parent.createChilds) this.createHandle();
		return this;
	}

	// Create the handle of NumberPicker
	fn void NumberPicker.createHandle(NumberPicker* this)
	{
		this.setNPStyle();
		this.createUpdown();
		if (this.handle) {
			this.setFontInternal();
			this.setSubClass(&npWndProc);
			this.createBuddyControl();
			this.setBuddySubclass();
			Hwnd oldBuddy = (Hwnd)this.sendMsg(UDM_SETBUDDY, this._buddyHandle, 0);
			this.sendMsg(UDM_SETRANGE32, this.minRange, this.maxRange);
			api_GetClientRect(this._buddyHandle, &this._tbRect);
			api_GetClientRect(this.handle, &this._udRect);
			this.placeBuddy();
			if (oldBuddy) api_SendMessage(oldBuddy, MM_BUDDY_RESIZE, 0, 0);
			this.displayValue();
		}
	}

	fn void NumberPicker.setDeciPrec(&this, uint value)
	{
		this.deciPrec = value;
		this.fmtStr.clear();
		// this._valStr.clear();
		if (value == 0) {
			this.fmtStr.append("%d");
		} else {
			this.fmtStr.appendf("%%.%df", value);
		}
		if (this._isCreated) this.displayValue();
	}

	fn void NumberPicker.setButtonLeft(&this, bool value)
	{
		this.buttonLeft = value;
		if (value) {
			print("setButtonLeft is working");
			this._style ^= UDS_ALIGNRIGHT;
			this._style |= UDS_ALIGNLEFT;
			this._topEdgeFlag = BF_TOP;
			this._botEdgeFlag = BF_BOTTOMRIGHT;
			if (this.textPos == Alignment.LEFT) this.textPos = Alignment.RIGHT;
		} else {
			this._style ^= UDS_ALIGNLEFT;
			this._style |= UDS_ALIGNRIGHT;
			this._topEdgeFlag = BF_TOPLEFT;
			this._botEdgeFlag = BF_BOTTOM;
			if (this.textPos == Alignment.RIGHT) this.textPos = Alignment.LEFT;
		}
		api_SetWindowLongPtr(this.handle, GWL_STYLE, (Longptr)this._style);
		this.placeBuddy();
		api_SetWindowPos(this.handle, null, this.xpos, this.ypos, this.width, this.height, 0x0200 | 0x0001);
	}

	fn void NumberPicker.setMinRange(&this, int mrange)
	{
		this.minRange = mrange;
		if (this._isCreated) this.sendMsg(UDM_SETRANGE32, this.minRange, this.maxRange);
	}

	fn void NumberPicker.setMaxRange(&this, int mrange)
	{
		this.maxRange = mrange;
		if (this._isCreated) this.sendMsg(UDM_SETRANGE32, this.minRange, this.maxRange);
	}

	macro NumberPicker.setValue(&this, nvalue)
	{
		$switch $typeof(nvalue).typeid:
			$case int: this.value = (double)nvalue;
			$case double: this.value = nvalue;
			$default: break;
		$endswitch
		if (this._isCreated) this.displayValue();
	}

	macro NumberPicker.setStep(&this, nstep)
	{
		$switch $typeof(nstep).typeid:
			$case int: this.step = (double)nstep;
			$case double: this.step = nstep;
			$default: break;
		$endswitch
	}

	// fn void NumberPicker.setBackColor(&this, uint clr)
	// {

	// }

// End of Public functions

// Private functions

	// Setting control's style bits.
	fn void NumberPicker.setNPStyle(NumberPicker* this) @private
	{
		if (this.buttonLeft) {
			this._style ^= UDS_ALIGNRIGHT;
			this._style |= UDS_ALIGNLEFT;
			this._topEdgeFlag = BF_TOP;
			this._botEdgeFlag = BF_BOTTOMRIGHT;
			if (this.textPos == Alignment.LEFT) this.textPos = Alignment.RIGHT;
		}
		//if (!this.mHasSep) this._style |= UDS_NOTHOUSANDS;

		switch (this.textPos) {
			case Alignment.LEFT : this._buddyStyle |= ES_LEFT;
			case Alignment.CENTER : this._buddyStyle |= ES_CENTER;
			case Alignment.RIGHT : this._buddyStyle |= ES_RIGHT;
		}
		this._bkBrush = this.backColor.getBrush();
		
		Color clr = newColor(0xABABAB);		
		this._borderBrush = api_CreateSolidBrush(clr.ref);	
		this._borderPen = api_CreatePen(PS_SOLID, 2, this.backColor.ref);
	}

	// When user changes back color, we need to re-create the border pen.
	fn void NumberPicker.changeBackColorHelper(&this)
	{
		if (this._borderPen) api_DeleteObject((Hgdiobj)this._borderPen);
		this._borderPen = api_CreatePen(PS_SOLID, 2, this.backColor.ref);
	}

	fn void NumberPicker.createUpdown(NumberPicker* this) @private
	{
		this.ctlID = globalCtlID;
		globalCtlID += 1;
		static Char16[*] updClassName = {'m', 's', 'c', 't', 'l', 's', '_', 'u', 'p', 'd', 'o', 'w', 'n', '3', '2', 0};
		this.handle = api_CreateWindowEx( this._exStyle,
											&updClassName[0],
											null, this._style,
											0, 0, 0, 0,
											this._parent.handle, (Hmenu)this.ctlID,
											this._parent.hinst, null);
		if (this.handle) this._isCreated = true;
	}

	fn void NumberPicker.createBuddyControl(NumberPicker* this) @private
	{
		// Let's create the buddy control.
		this._buddyCid = globalCtlID;
		globalCtlID += 1;
		static Char16[*] budduClassName = {'E', 'd', 'i', 't', 0};
		this._buddyHandle = api_CreateWindowEx( this._buddyExStyle,
                                                &budduClassName[0],
                                                null, this._buddyStyle,
                                                this.xpos, this.ypos,
                                                this.width, this.height,
                                                this._parent.handle, (Hmenu)this._buddyCid,
                                                this._parent.hinst, null);
		api_SendMessage(this._buddyHandle, WM_SETFONT, (Wparam)this.font.handle, (Lparam)true);
	}

	fn void NumberPicker.placeBuddy(NumberPicker* this) @private
	{
		if (this.buttonLeft) {
			this._linex = this._tbRect.left + 1;
			api_SetWindowPos(this._buddyHandle, this.handle,
							(this.xpos + this._udRect.right), this.ypos,
							this._tbRect.right, this._tbRect.bottom, SWPFLAG);
		} else {
			this._linex = this._tbRect.right - 3;
			api_SetWindowPos(this._buddyHandle, this.handle, this.xpos, this.ypos,
							(this.width - (this._udRect.right - this._udRect.left)), this._tbRect.bottom, SWPFLAG);
		}
	}

	fn void NumberPicker.setBuddySubclass(NumberPicker* this) @private
	{
		api_SetWindowSubclass(this._buddyHandle, &buddyWndProc, globalSubClsID, bitcast(this, Dwordptr));
		globalSubClsID += 1;
	}

	fn void NumberPicker.displayValue(NumberPicker* this) @private
	{
		this._valStr.clear();
		this._valStr.appendf(this.fmtStr.str_view(), this.value);
		if (this._wideText) allocator::free(mem, this._wideText);
		this._wideText = String.to_utf16(this._valStr.str_view(), mem)!!.ptr;
		api_SetWindowText(this._buddyHandle, this._wideText);
	}

	fn void NumberPicker.paintBuddyBorder(&this, Hwnd hwnd)
	{
		/*-------------------------------------------------------------------------
		Edit control needs WS_BORDER style to place the text properly aligned.
		But if we use that style, it will draw a border on 4 sides of the edit.
		That will separate our updown control and edit control into two parts.
		And that's ugly. So we need to erase all the borders. But it is tricky.	
		First, we will draw a frame over the current border with updown's border color.
		Then, we will erase the right/left side border by drawing a line.
		This line has the same back color of edit control. So the border is hidden. 
		And the control will look like the one in .NET.  
		----------------------------------------------------------------------------------*/
		// api_FrameRect(hdc, &this._tbRect, this._borderBrush);
		// Hpen fpen = api_CreatePen(PS_SOLID, 2, this.backColor.ref);
		// defer api_DeleteObject((Hgdiobj)fpen);
		// api_SelectObject(hdc, (Hgdiobj)fpen);
		// api_MoveToEx(hdc, this._linex, 1, null);
		// api_LineTo(hdc, this._linex, this._tbRect.bottom - 2);
		@using(newGraphics(DCMode.WIN_DC, hwnd); Graphics gfx) {
			gfx.drawFrameRect(&this._tbRect, this._borderBrush);
			gfx.drawLine(this._linex, 1, this._tbRect.bottom - 2, this._borderPen);
		};
	}

	fn void NumberPicker.setValueInternal(NumberPicker* this, int delta) @private
	{
		double tvalue = this.value + (delta * this.step);
        if (this.autoRotate) {
            if (tvalue > this.maxRange) {
                this.value = this.minRange;
			} else if (tvalue < this.minRange) {
                this.value = this.maxRange;
			} else {
                this.value = tvalue;
			}
		} else {
            this.value = math::clamp(tvalue, this.minRange, this.maxRange);
		}
		this.displayValue();
	}

	fn void NumberPicker.wmNotifyHandler(NumberPicker* this, Lparam lpm) @private
	{
		NMUpdown* nm = (NMUpdown*) lpm;
		if (nm.hdr.code == UDN_DELTAPOS) {
			String tbstr = this.getTextInternal(this._buddyHandle);
			defer free(tbstr);
			this.value = strToDouble(tbstr);
			this.setValueInternal(nm.iDelta);
			if (this.onValueChanged) this.onValueChanged(this, &gea);
		}
	}

	// Handling back & fore color changing in WndProc function
	fn Hbrush NumberPicker.colorMsgHandler(NumberPicker* this, Wparam wpm) @private
	{
		Hdc hdc = (Hdc)wpm;
		api_SetBkMode(hdc, TRANSPARENT);
		if (this._drawMode & 1) {
			api_SetTextColor(hdc, this.foreColor.ref);
		}
		api_SetBkColor(hdc, this.backColor.ref);
		return this._bkBrush;
	}

	macro setNumberPickerProps(this, String prop, value) @private
	{
		switch (prop) {
			// case "hideselection"
			// case "hidecaret": ;
			case "buttonleft": this.setButtonLeft((bool)value);

			// case "autorotate": ;
			case "minrange": this.setMinRange((int)value);
			case "maxrange": this.setMaxRange((int)value);
			case "value": this.setValue(value);
			case "step": this.setStep(value);
			// case "fmtstr": ;
			case "deciprec":
				$switch $typeof(value).typeid:
					$case int: this.setDeciPrec((uint)value);
					$case uint: this.setDeciPrec(value);
				$endswitch

			// case "textpos": ;
			default: break;
		}
	}

	// Freeing resources used for this NumberPicker.
	fn void NumberPicker.dtor(NumberPicker* this) @private
	{
		this.fmtStr.free();
		this._valStr.free();
		api_DeleteObject((Hgdiobj)this._borderBrush);
		api_DeleteObject((Hgdiobj)this._borderPen);
		this.baseDestroy();
		allocator::free(mem, this);
	}
// End of Private functions


fn Lresult npWndProc(Hwnd hw, uint msg, Wparam wp, Lparam lp, Uintptr scID, Dwordptr refData) @private
{
	
	// io::printfn("message %s", msg);
	switch (msg) {
		case WM_DESTROY:
			NumberPicker* this = bitcast(refData, NumberPicker*);
			api_RemoveWindowSubclass(hw, &npWndProc, scID);
			this.dtor();

		case WM_LBUTTONDOWN:
			NumberPicker* this = bitcast(refData, NumberPicker*);
			this.leftMouseDownHandler(msg, wp, lp);
		case WM_LBUTTONUP:
			NumberPicker* this = bitcast(refData, NumberPicker*);
			this.leftMouseUpHandler(msg, wp, lp);
		case MM_MOUSE_LBCLICK:
			NumberPicker* this = bitcast(refData, NumberPicker*);
			this.leftClickHandler();

		case WM_RBUTTONDOWN:
			NumberPicker* this = bitcast(refData, NumberPicker*);
			this.rightMouseDownHandler(msg, wp, lp);
		case WM_RBUTTONUP:
			NumberPicker* this = bitcast(refData, NumberPicker*);
			this.rightMouseUpHandler(msg, wp, lp);
		case MM_MOUSE_RBCLICK:
			NumberPicker* this = bitcast(refData, NumberPicker*);
			this.rightClickHandler();

		case WM_MOUSEMOVE:
			NumberPicker* this = bitcast(refData, NumberPicker*);
			this.mouseMoveHandler(msg, wp, lp);
		case WM_MOUSELEAVE:
			NumberPicker* this = bitcast(refData, NumberPicker*);
			this.mouseLeaveHandler();
		case WM_MOUSEWHEEL:
			NumberPicker* this = bitcast(refData, NumberPicker*);
			this.mouseWheelHandler(msg, wp, lp);
		case WM_CONTEXTMENU:
			NumberPicker* this = bitcast(refData, NumberPicker*);
			if (this.contextMenu) this.contextMenu.showMenu(lp);
		case WM_KEYDOWN:
			NumberPicker* this = bitcast(refData, NumberPicker*);
			this.keyDownHandler(wp);
		case WM_KEYUP:
			NumberPicker* this = bitcast(refData, NumberPicker*);
			this.keyUpHandler(wp);
		case WM_CHAR:
			NumberPicker* this = bitcast(refData, NumberPicker*);
			this.keyPressHandler(wp);

		case MM_NOTIFY_REFLECT:
			NumberPicker* this = bitcast(refData, NumberPicker*);
			this.wmNotifyHandler(lp);
		// case WM_PAINT:
		// 	Lresult ret = api_DefSubclassProc(hw, msg, wp, lp);
		// 	Hdc hdc = api_GetDC(hw);
		// 	Hpen fpen = api_CreatePen(PS_SOLID, 2, this.backColor.ref);
		// 	defer api_DeleteObject(fpen);
		// 	api_SelectObject(hdc, fpen);
		// 	api_MoveToEx(hdc, this._udRect.left, 1, null);
		// 	api_LineTo(hdc, this._udRect.left, this._udRect.bottom - 2);
		// 	api_ReleaseDC(hw, hdc);
		// 	return ret;

		// case MM_RUNDTOR: this.dtor(); return 0;
		default:
			return api_DefSubclassProc(hw, msg, wp, lp);
	}
	return api_DefSubclassProc(hw, msg, wp, lp);
}


fn Lresult buddyWndProc(Hwnd hw, uint msg, Wparam wp, Lparam lp, Uintptr scID, Dwordptr refData) @private
{
	
	// io::printfn("message %s", msg);
	switch (msg) {
		case WM_DESTROY: 
			api_RemoveWindowSubclass(hw, &buddyWndProc, scID);

		// case WM_ERASEBKGND:
		// 	return api_DefSubclassProc(hw, msg, wp, lp);
		// case WM_PRINTCLIENT:
		// 	nextcase;

		case WM_PAINT:			
			NumberPicker* this = bitcast(refData, NumberPicker*);			
			Lresult rs = api_DefSubclassProc(hw, msg, wp, lp); // Let the control do it's basic painting.			
			// Hdc hdc = api_GetWindowDC(hw);
			// defer api_ReleaseDC(hw, hdc);		
			this.paintBuddyBorder(hw);				
			return rs;

		case EM_SETSEL: return 1; // To eliminate the selection back color in edit.
		case MM_BUDDY_RESIZE: 
			NumberPicker* this = bitcast(refData, NumberPicker*);
			this.placeBuddy(); // Fix for the strange behaviour in UDM_SETBUDDY message.
		case MM_COLOR_EDIT: 
			NumberPicker* this = bitcast(refData, NumberPicker*);
			return (Lresult)this.colorMsgHandler(wp);
		default:
			return api_DefSubclassProc(hw, msg, wp, lp);

	}
	return api_DefSubclassProc(hw, msg, wp, lp);
}




