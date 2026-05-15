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
	bool _isMouseEntered;
	bool _hoverTriggered;
	double minRange;
	double maxRange;
	double value;
	double step ;
	DString fmtStr;
	DString _valStr;
	uint deciPrec;
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
	Rect _myRect;
	Rect _tbwrc;
	Point _lastMpos;
	Timer* _hoverTimer;
	Point[4] _borderPts;
	EventHandler onValueChanged;
}

// Public functions
	// NumberPicker constructor
	fn NumberPicker* newNumberPicker(Control* parent, int x = 10, int y = 10,
										int width = 75, int height = 25,
										EventHandler evtFn = null,
										bool btnLeft = false)
	{
		NumberPicker* this = allocator::new(mem, NumberPicker);
		this.kind = ControlType.NUM_PICKER;
		this.initBase(parent, x, y, width, height, &npNumber);	
		this.maxRange = 100;
		this.minRange = 0;
		this.deciPrec = 0;
		this.buttonLeft = btnLeft;
		this.step = 1;
		this._buddyStyle = NPBUDDYSTYLE;
		this._buddyExStyle = WS_EX_LEFT;
		this._topEdgeFlag = BF_TOPLEFT;
		this._botEdgeFlag = BF_BOTTOM;
		this.textPos = Alignment.LEFT;
		this.fmtStr = dstring::new(mem, "%d");
		this._valStr = dstring::new(mem, "0");
		if (evtFn) this.onValueChanged = evtFn;
		this._createHandleFunc = &_npCreateHandle;
		return this;
	}

	// Create the handle of NumberPicker
	fn void _npCreateHandle(Control* ctl) @private
	{
		NumberPicker* this = (NumberPicker*)ctl;
		this.setNPStyle();
		this._createInternal(0, 0);
		if (this.handle) {
			this.setSubClass(&npWndProc);
			this.createBuddyControl();
			this.setBuddySubclass();			
			this.sendMsg(UDM_SETBUDDY, this._buddyHandle, 0);
			this.sendMsg(UDM_SETRANGE32, this.minRange, this.maxRange);			
			this.setBorderPoints();			
			api_GetClientRect(this.handle, &this._udRect);
			
			api_SetRect(&this._myRect, this.xpos, this.ypos, (this.xpos + this.width), (this.ypos + this.height));
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
			// print("setButtonLeft is working");
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
		this._borderPen = api_CreatePen(PS_SOLID, 2, getClrRef(0xABADB3)); //B4B4B4, ABADB3
	}

	fn void NumberPicker.setBorderPoints(&this)
	{
		api_GetWindowRect(this._buddyHandle, &this._tbwrc);
		api_OffsetRect(&this._tbwrc, -this._tbwrc.left, -this._tbwrc.top);
		if (this.buttonLeft) {  // ⊐
			this._borderPts[1].x = this._tbwrc.right;
			this._borderPts[2].x = this._tbwrc.right;
			this._borderPts[2].y = this._tbwrc.bottom; 			
			this._borderPts[3].y = this._tbwrc.bottom;

		} else {  // ⊏
			this._borderPts[0].x = this._tbwrc.right;
			this._borderPts[2].y = this._tbwrc.bottom; 
			this._borderPts[3].x = this._tbwrc.right;
			this._borderPts[3].y = this._tbwrc.bottom; 
		}
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
                                                app.hins, null);
		
		api_SendMessage(this._buddyHandle, WM_SETFONT, (Wparam)this.font.handle, (Lparam)true);
	}

	fn void NumberPicker.setBuddySubclass(NumberPicker* this) @private @inline
	{
		api_SetWindowSubclass(this._buddyHandle, &buddyWndProc, globalSubClsID, bitcast(this, Dwordptr));
		globalSubClsID += 1;
	}

	fn void NumberPicker.mouseMoveHandler(&this, uint msg, Wparam wpm, Lparam lpm)
	{
		if (this.onMouseMove) {
			MouseEventArgs mea;
			fillMouseEventArgs(&mea, msg, wpm, lpm);
			this.onMouseMove(this, &mea);
		}

		// We need special treatment for mouse hover event. That's why
		// we are overriding base class method
		if (this._mouseEvents.hover && !this._hoverTriggered) {
			this._lastMpos.x = (int)(loWord(lpm));
			this._lastMpos.y = (int)(hiWord(lpm));
			this._hoverTimer.restart();
			this._hoverTriggered = true;
		} 

		if (!this._isMouseEntered) {
			this._isMouseEntered = true;
			if (this.onMouseEnter) this.onMouseEnter(this, &gea); 
		} 
	}

	fn void NumberPicker.mouseLeaveHandler(&this)
	{
		/*-----------------------------------------------------------------------------
        Mouse leave event in NumberPicker control is a bit tricky. It's a combination
        of a text box and button. And if we use UDS_HOTTRACK style, the
        control internally uses TrackMouseEvent function to track the mouse movement
        in the rect of the arrow button only. So we have to create an imaginary rect over 
        the bondaries of these two controls. If mouse is inside that rect, 
        there is no mouse leave. A perfect hack!
    	----------------------------------------------------------------------------------*/
		if (this._tmeFlags.leave || this._tmeFlags.hover) {
			if (this._isMouseTracking || this._isMouseEntered || this._hoverTriggered) {
				Point pt;
				api_GetCursorPos(&pt);
				api_ScreenToClient(this._parent.handle, &pt);        
				Bool inside = api_PtInRect(&this._myRect, pt);
				// printRct(this._myRect, pt, inside);
				if (!inside) {        
					this._isMouseEntered = false;
					this._isMouseTracking = false;
					if (this._hoverTriggered) {
						this._hoverTriggered = false;
						this._hoverTimer.stop();
					}

					if (this.onMouseLeave) this.onMouseLeave(this, &gea);
				}
			}
		}
	}

	fn void NumberPicker.displayValue(&this) @private
	{
		this._valStr.clear();
		this._valStr.appendf(this.fmtStr.str_view(), this.value);
		if (this._wsText) {
			this._wsText.updateBuffer(this._valStr.str_view());
		} else {
			this._wsText = newWideString(this._valStr.str_view());
		}
		api_SetWindowText(this._buddyHandle, this._wsText.ptr());
	}

	fn void NumberPicker.setValueInternal(&this, int delta) @private
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
            // ptf("clamped value, %f", this.value);
		}
		this.displayValue();
	}

	fn void NumberPicker.wmNotifyHandler(&this, Lparam lpm) @private
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
	fn Hbrush NumberPicker.colorMsgHandler(&this, Wparam wpm) @private
	{
		// ptf("np this._bkBrush %d", this._bkBrush);
		Hdc hdc = (Hdc)wpm;
		api_SetBkMode(hdc, TRANSPARENT);
		if (this._drawMode & 1) {
			api_SetTextColor(hdc, this.foreColor.ref);
		}
		api_SetBkColor(hdc, this.backColor.ref);
		// ptf("np bkg in np clr msg %x", this.backColor.value);
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
	fn void NumberPicker.dtor(&this) @private
	{
		this.fmtStr.free();
		this._valStr.free();
		api_DeleteObject((Hgdiobj)this._borderPen);
		if (this._hoverTimer) this._hoverTimer.destroy();
		this.baseDestroy();
		allocator::free(mem, this);
	}
// End of Private functions


fn Lresult npWndProc(Hwnd hw, uint msg, Wparam wp, Lparam lp, Uintptr scID, Dwordptr refData) @private
{
	// io::printfn("message %s", msg);
	NumberPicker* this = bitcast(refData, NumberPicker*);
	MsgHandlerResult res = this.baseWndProc(hw, msg, wp, lp);	
	if (res == MsgHandlerResult.CALL_DEF_PROC) {
		return api_DefSubclassProc(hw, msg, wp, lp);
	} else if (res == MsgHandlerResult.RET_IMMEDIATE) {
		return 1;
	}
	switch (msg) {
		case WM_NCDESTROY:			
			api_RemoveWindowSubclass(hw, &npWndProc, scID);
			this.dtor();

		case WM_TIMER:
			if (this.onMouseHover) {
				this._hoverTimer.stop();
				this.onMouseHover(this, &gea);
			}
			return 0;

		case MM_NOTIFY_REFLECT:
			this.wmNotifyHandler(lp);
		
		default:
			return api_DefSubclassProc(hw, msg, wp, lp);
	}
	return api_DefSubclassProc(hw, msg, wp, lp);
}


fn Lresult buddyWndProc(Hwnd hw, uint msg, Wparam wp, Lparam lp, Uintptr scID, Dwordptr refData) @private
{	
	// io::printfn("message %s", msg);
	NumberPicker* this = bitcast(refData, NumberPicker*);	
	MsgHandlerResult res = this.baseWndProc(hw, msg, wp, lp);	
	if (res == MsgHandlerResult.CALL_DEF_PROC) {
		return api_DefSubclassProc(hw, msg, wp, lp);
	} else if (res == MsgHandlerResult.RET_IMMEDIATE) {
		return 1;
	}
	switch (msg) {
		case WM_NCDESTROY: 
			api_RemoveWindowSubclass(hw, &buddyWndProc, scID);

		case EM_SETSEL: return 1; // To eliminate the selection back color in edit.

		case MM_COLOR_EDIT: 
			return (Lresult)this.colorMsgHandler(wp);

		case WM_NCCALCSIZE:
            /* By default, arrow button has a border on 3 sides.
             * If we use WS_BORDER style for buddy edit control, we need to...
             * cover it with unnecessary drawings. So, it's better to make...
			 * room to draw a border and draw it on the 3 sides of buddy edit...
             * in WM_NCPAINT. So we need to shrink the client area and make room.
			 * ................................................................ */ 
			 if (wp == 1 ) {
                NCCalcSizeParams* pncsp = (NCCalcSizeParams*)lp;
                if (!this.buttonLeft) {
                    pncsp.rgrc[0].left += 1;
                    pncsp.rgrc[0].top += 1;
                    pncsp.rgrc[0].right -= 2;
                    pncsp.rgrc[0].bottom -= 1;
                } else {
                    pncsp.rgrc[0].left += 2;
                    pncsp.rgrc[0].top += 1;
                    pncsp.rgrc[0].right -= 1;
                    pncsp.rgrc[0].bottom -= 1; 
                }                               
                return 0;
            }  

		case WM_NCPAINT:
            // We are drawing border on 3 sides of the edit control.
            // Points are pre-calculated. 
            Hrgn hrgn = (Hrgn)wp;   
            Dword flags = DCX_WINDOW | DCX_CACHE | DCX_INTERSECTRGN;
            if (wp == 1) flags = DCX_WINDOW | DCX_CACHE; 
            Hdc hdc = api_GetDCEx(hw, hrgn, flags);
            defer api_ReleaseDC(hw, hdc);   
            if (hdc) {        
                Hpen hOldPen = (Hpen)api_SelectObject(hdc, (Hgdiobj)(this._borderPen));       
                api_Polyline(hdc, &this._borderPts[0], 4);
				api_SelectObject(hdc, (Hgdiobj)(hOldPen));
            }
            return 0;
		default:
			return api_DefSubclassProc(hw, msg, wp, lp);
	}
	return api_DefSubclassProc(hw, msg, wp, lp);
}




