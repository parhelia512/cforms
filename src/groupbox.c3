// groupbox module - Created on 16-Feb-2023 06:55
/*=======================================================GroupBox Docs====================================
	GroupBox type:
		Constructor: newGroupBox()	: GroupBox*
		Properties:
			Inherits all properties from Control struct
			lineColor : Color - Set the border line color
			style : GroupBoxStyle enum - Check enums.c3
			inheritStyle : bool - If true, child controls can inherit colors and font from GroupBox.
		Methods:
			createHandle()	: Creates the handle of GroupBox
		Events:
			Inherits all the events from Control struct
========================================================================================================*/

module cforms;
// import std::io;

int gbNumber = 1;
const Dword PEN_WIDTH = 4;
Dword gbStyleFlag = WS_CHILD | WS_VISIBLE | BS_GROUPBOX | BS_NOTIFY | BS_TOP | WS_CLIPCHILDREN | WS_CLIPSIBLINGS;
Char16[1] ewsa = {0};
const Char16* EMP_WSTR_PTR = &ewsa[0];
const GBDrawFlags DIRTY_ALL = {.measureText, .fetchBorder, .recreateBmp, .fillBkg, .drawBorder, .drawText };

bitstruct GBDrawFlags : char {
	bool measureText 	: 0;
	bool fetchBorder 	: 1;
	bool recreateBmp 	: 2;
	bool fillBkg 		: 3;
	bool drawBorder		: 4;
	bool drawText		: 5;
}

// GroupBox control struct
struct GroupBox
{
	inline Control control;
	GroupBoxStyle style;
	Color lineColor;
	Hpen _pen;
	Rect _rct;
	Hdc _hdc;
	Hbitmap _hbmp;
	Hdc _memDC;
	int _txtWidth;
	bool _drawDisabled;
	bool _normalText;
	bool inheritStyle;
	bool _getWidth;
	bool _themeOff;
	bool _createMDC;
	GBDrawFlags _dFlags;
	Size _txtSize;
	
	Point[6] _borderPts;
	
	ControlList controls;
}

// Public functions
	// GroupBox constructor - Create and returns a New GroupBox struct
	fn GroupBox* newGroupBox(Control* parent, String text = "", int x = 10, 
							int y = 10, int width = 230, int height = 250, 
							GroupBoxStyle style = GroupBoxStyle.SYSTEM)
	{
		GroupBox* this = alloc::new(mem, GroupBox);
		this.kind = ControlType.GROUP_BOX;		
		String gbtext = text == "" ? this.name.str_view() : text;
		this.initBase(parent, x, y, width, height, &gbNumber, gbtext);	
		// this._normalText = true;
		// this._dbFill = true;
		// this._getWidth = true;
		this.style = style;
		this.lineColor = newColor(0xadb5bd);
		// this.backColor = newColor(0x23b5bd); //this._ownerForm.backColor;
		this.controls.init(mem, 8); 
		this._createHandleFunc = &_gbCreateHandle;
		if (this._ownerForm._enablePrintPoint) this.onMouseDown = &printPoint;
		return this;
	}

	// Create the handle of GroupBox
	fn void _gbCreateHandle(Control* ctl) // @private
	{
		GroupBox* this = (GroupBox*)ctl;
		this._bkBrush = api_CreateSolidBrush(this.backColor.ref);
		if (this.style == GroupBoxStyle.OVERRIDEN) {
			this._pen = api_CreatePen(PS_SOLID, 1, this.lineColor.ref);
			this._dFlags = DIRTY_ALL;
		}
		// this._rct = {0, 0, this.width, this.height};
		// this._drawMode = 2;
		this._createInternal(this.width, this.height);
		if (this.handle) {
			this.setSubClass(&gbWndProc);
			// if (this.style == GroupBoxStyle.CLASSIC) {
			// 	api_SetWindowTheme(this.handle, EMP_WSTR_PTR, EMP_WSTR_PTR);
            // 	this._themeOff = true;
			// }
			
			if (this._ownerForm._enablePrintPoint) {
				this.onMouseDown = &printPoint;
			}
		}
		
	}

	// Set GroupBox's fore color. Fore color changing is tricky.
	// Either we need to turn off the theme drawing by windows or...
	// we need to over-write the text. So you can choose one among...
	// two styles. Classic is default, which turning off theme drawing.
	// Overriden style tricks winodws by returning 0 in wm_gettextlength...
	// message so windows won't draw the text. Then we draw our text.
	fn void GroupBox.setForeColor(&this, uint clr, GroupBoxStyle style = GroupBoxStyle.CLASSIC)
	{
		this.foreColor.updateColor(clr);
		if (this.style == GroupBoxStyle.SYSTEM) this.style = style;
		if (this.style == GroupBoxStyle.CLASSIC) {
			if (!this._themeOff) {
				api_SetWindowTheme(this.handle, EMP_WSTR_PTR, EMP_WSTR_PTR);
            	this._themeOff = true;
			}			
		}
		if (this.style == GroupBoxStyle.OVERRIDEN) this._dFlags.drawText = true;
		this._checkRedraw();
	}

	// Set GroupBox's back color.
	fn void GroupBox.setBackColor(&this, uint clr)
	{
		this.backColor.updateColor(clr);
		
		this._checkRedraw();
	}

	fn void GroupBox.setLineColor(&this, uint clr)
	{    
		this.lineColor = newColor(clr);
		if (!this._pen) api_DeleteObject((Hgdiobj)this._pen);
		this._pen = api_CreatePen(PS_SOLID, 1, this.lineColor.ref);
		if (this.style != GroupBoxStyle.OVERRIDEN) {
			this.style = GroupBoxStyle.OVERRIDEN;
			this._dFlags = DIRTY_ALL;
			if (!this._memDC) this._createMDC = true;    
		} else {
			this._dFlags.drawBorder = true;
		}    
	}

	// Set width and/or height of Groupbox.
	fn void GroupBox.setSize(&this, int w, int h) {
		this.width = w;
		this.height = h;
		// this.resetGDIObjects(false);
		if(this._isCreated) this._setPos(SWP_NOZORDER);
	}

	fn void GroupBox.setText(&this, String txt) {
		this.text = txt;
		if (this._wsText) {
			this._wsText.updateBuffer(txt);
		} else {
			this._wsText = newWideString(txt);
		}
		if (this.style == GroupBoxStyle.OVERRIDEN) {
			this._dFlags = {.measureText, .fetchBorder, .fillBkg, .drawBorder, .drawText};
		}
		if (this._isCreated) {
			api_SetWindowText(this.handle, this._wsText.ptr());
			this._checkRedraw();
		}
	}

	// Either pass a Font object or 3 parameters.
	// (1) Font name, (2) Font size, (3) Font Weight enum
	macro void GroupBox.setFont(&this, ... ) {
		$if $vaarg.len == 1 && $Typeof($vaarg[0]) == Font: 
			this.font.cloneFrom($vaarg[0]);
			this.sendMsg(WM_SETFONT, this.font.handle, 1);
			this._getWidth = true;
			this._checkRedraw();
		$else 
			$if $vaarg.len == 3 && $Typeof($vaarg[0]) == String:
				this._fontSetter(...$vaarg);
			$endif
		$endif
	}

	fn void GroupBox.enablePrintPoint(&this)
	{
		// this.onMouseDown = &printPoint;
	}


// End of Public functions

// Private functions

	/* fn void GroupBox.resetGDIObjects(&this, bool brpn) // @private
	{
		if (brpn) {
			if (this._bkBrush) api_DeleteObject((Hgdiobj)this._bkBrush);   
			this._bkBrush = api_CreateSolidBrush(this.backColor.ref);
			if (this.style == GroupBoxStyle.OVERRIDEN) {
				if (this._pen) api_DeleteObject((Hgdiobj)this._pen);
				this._pen = api_CreatePen(PS_SOLID, PEN_WIDTH, this.backColor.ref);
			}
		}
		if (this._hdc) api_DeleteDC(this._hdc);
		if (this._hbmp) api_DeleteObject((Hgdiobj)this._hbmp);    
		this._dbFill = true;
	} */

	fn void GroupBox.fetchBorderPts(&this) 
	{
		int startX = this._myRect.left + 10;
		int startY = this._txtSize.cy / 2;
		this._borderPts[0] = {startX + this._txtSize.cx, startY};
		this._borderPts[1] = {this._myRect.right - 1, startY};
		this._borderPts[2] = {this._myRect.right - 1, this._myRect.bottom - 1};
		this._borderPts[3] = {this._myRect.left, this._myRect.bottom - 1};
		this._borderPts[4] = {this._myRect.left, startY};
		this._borderPts[5] = {startX - 1, startY};
	}

	fn void GroupBox._fontSetter(&this, String fname, int fsize, FontWeight fweight) // @private 
	{
		this.font.name = fname;
		this.font.size = fsize;
		this.font.weight = fweight;
		this.font.createHandle();
		this.sendMsg(WM_SETFONT, this.font.handle, 1);
		this._getWidth = true;
		this._checkRedraw();
	}
	


	fn void GroupBox.textSetter(GroupBox* this, String value) // @private
	{
		if (this._wsText) this._wsText.updateBuffer(value);
		api_SetWindowText(this.handle, this._wsText.ptr());
		api_InvalidateRect(this.handle, null, false);
	}

	// Freeing resources used for this GroupBox.
	fn void GroupBox.dtor(GroupBox* this) // @private
	{
		if (this._pen) api_DeleteObject((Hgdiobj)this._pen);  
		if (this._hbmp) api_DeleteObject((Hgdiobj)this._hbmp); 
		if (this._memDC) api_DeleteDC(this._memDC);
		this.controls.free();
		this.baseDestroy(); 
		alloc::free(mem, this);
	}
// End of Private functions


fn Lresult gbWndProc(Hwnd hw, uint msg, Wparam wp, Lparam lp, Uintptr scID, Dwordptr refData) // @private
{	
	// ptf("message %s", msg);
	GroupBox* this = bitcast(refData, GroupBox*);
	MsgHandlerResult res = this.baseWndProc(hw, msg, wp, lp);	
	if (res == MsgHandlerResult.CALL_DEF_PROC) {
		return api_DefSubclassProc(hw, msg, wp, lp);
	} else if (res == MsgHandlerResult.RET_IMMEDIATE) {
		return 1;
	} 
	switch (msg) {
		case WM_DESTROY:
			api_RemoveWindowSubclass(hw, &gbWndProc, scID);
			this.dtor();		
			
		case WM_PAINT:
			if (this.style == GroupBoxStyle.OVERRIDEN) {				
				@using(newGraphics(DCMode.ON_PAINT, hw); Graphics gfx) {
					if (this._createMDC) {
						this._memDC = api_CreateCompatibleDC(gfx.hdc);
						this._createMDC = false;
					}
					if (this._dFlags.measureText) {
						gfx.getTextSize(this, &this._txtSize);
						this._dFlags.measureText = false;
					}
					if (this._dFlags.fetchBorder) {
						this.fetchBorderPts();
						this._dFlags.fetchBorder = false;
					}
					
					if (this._dFlags.recreateBmp) {
						if (!this._hbmp) api_DeleteObject((Hgdiobj)this._hbmp);
						this._hbmp = api_CreateCompatibleBitmap(gfx.hdc, this.width, this.height);
						api_SelectObject(this._memDC, (Hgdiobj)this._hbmp);
						this._dFlags.recreateBmp = false;
						// needDraw = true
					}
					
					if (this._dFlags.fillBkg) {
						api_FillRect(this._memDC, &this._myRect, this._bkBrush);
						this._dFlags.fillBkg = false;
						// needDraw = true
					} 
					if (this._dFlags.drawBorder) {
						api_SelectObject(this._memDC, (Hgdiobj)this._pen);
						api_Polyline(this._memDC, &this._borderPts[0], 6);
						this._dFlags.drawBorder = false;
						// needDraw = true
					}
					if (this._dFlags.drawText) {
						api_SetBkMode(this._memDC, TRANSPARENT);
						api_SelectObject(this._memDC, (Hgdiobj)this.font.handle);
						api_SetTextColor(this._memDC, this.foreColor.ref);
						api_TextOut(this._memDC, 10, 0, this._wsText.ptr(), this._wsText.wlen());
						this._dFlags.drawText = false;
						// needDraw = true
					}
					// if needDraw  {
					api_BitBlt(gfx.hdc, 0, 0, this.width, this.height, this._memDC, 0, 0, SRCCOPY);
					// } 
				};
				return 1;
			} 

		case WM_GETTEXTLENGTH:
			if (this.style == GroupBoxStyle.OVERRIDEN) return 0;

		case WM_NCHITTEST:
			Lresult hit = api_DefSubclassProc(hw, msg, wp, lp);
			if (hit == HTTRANSPARENT) return HTCLIENT;
			return hit;

		 case MM_COLOR_STATIC:
			if (this.style == GroupBoxStyle.CLASSIC) {
				Hdc hdc = (Hdc)wp;
				api_SetBkMode(hdc, 1);
				api_SetTextColor(hdc, this.foreColor.ref);  
				api_SetBkMode(hdc, TRANSPARENT);
				api_SetBkColor(hdc, this.backColor.ref);  
			}
        	return (Lresult) this._bkBrush; //api_CreateSolidBrush(this);

		case WM_ERASEBKGND:
			if (this.style == GroupBoxStyle.OVERRIDEN) {
				return 1;
			} else {
				Hdc hdc = (Hdc)wp;
				api_FillRect(hdc, &this._myRect, this._bkBrush);
				return 1;
			}        	

		case WM_NOTIFY:			
			NMHdr* nmh = (NMHdr*)lp;
			return api_SendMessage(nmh.hwndFrom, MM_NOTIFY_REFLECT, wp, lp);

		case WM_CTLCOLORSTATIC:
			Hwnd hc = (Hwnd)lp;
			return api_SendMessage(hc, MM_COLOR_STATIC, wp, lp);

		case WM_CTLCOLOREDIT:
            Hwnd hc = (Hwnd)lp;
			return api_SendMessage(hc, MM_COLOR_EDIT, wp, lp);

		case WM_CTLCOLORLISTBOX:
			Hwnd hc = (Hwnd)lp;
			if (this._ownerForm._comboList.size) {
				foreach (ci: this._ownerForm._comboList) {
					if (ci.listHwnd == hc) {
						hc = ci.cmbHwnd;
						// ptf("hc: %d, ci.cmbHwnd: %d", hc, ci.cmbHwnd);
						break;
					}
				}
			}
			return api_SendMessage(hc, MM_COLOR_LBOX, wp, lp);
		
		default:
			return api_DefSubclassProc(hw, msg, wp, lp);
		// case MM_RUNDTOR: this.dtor(); return 0;
	}
	return api_DefSubclassProc(hw, msg, wp, lp);
}



// Constants
	// const UDS_ALIGNRIGHT const UDS_ARROWKEYS const UDS_AUTOBUDDY const UDS_HOTTRACK;
	const BS_GROUPBOX = 7;
	const BS_TEXT = 0;
	const BS_TOP = 1024;
	const WS_EX_TRANSPARENT = 32;
	const WS_EX_CONTROLPARENT = 65536;
	const HTTRANSPARENT = -1;
	const HTCLIENT = 1;

// End Constants

