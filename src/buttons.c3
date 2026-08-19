// button module - Created on 26-Jan-2023 01:36

/*=========================================Button Docs==========================================
	Constructor	: newButton()
	Properties:
		All public properties inherited from Control struct. (See controls.c3)
	Methods:
		createHandle()	: Creates the handle of button. (Usually called automatically)
		setForeColor()	: Set foreground color for this button
		setBackColor()	: Set background color for this button
		setGradientColor()	: Set gradient background for this button
	Events:
		All events inherited from Control struct. (See controls.c3)
================================================================================================*/

module cforms;

Dword btnStyle = 1342259200;
const int BTN_CLICKED = 0b1;
const int BTN_FOCUSED = 0b1000000;
const Dword BS_NOTIFY = 16384;
const Dword BS_PUSHBUTTON = 0;
const Dword BI_RGB = 0;
const uint DIB_RGB_COLORS = 0;
// const Dword BSTYLE = WS_CHILD | BS_NOTIFY | WS_TABSTOP | WS_VISIBLE | BS_PUSHBUTTON  ;
const uint TXTFLAG = DT_SINGLELINE | DT_VCENTER | DT_CENTER | DT_NOPREFIX;
int btnNumber = 1;
Wstring btnClass = {'B', 'u', 't', 't', 'o', 'n', 0};

enum DrawMode : char {NONE, FLAT, GRAD}
// Button control struct
struct Button ()
{
	inline Control control;
	union {
		FlatDraw* _fdraw;
		GradDraw* _gdraw;
	}
	DrawMode _dmode;
	bool _setDrawData;

}

// This struct holds infor required for drawing a flat colored button.
struct FlatDraw
{
	RgbColor clr;
	double hoverIntensity;
	bool tintOnHover;
	Hbrush defBrush;
	Hbrush hotBrush;
	Hpen defPen;
	Hpen hotPen;
}

// Setting the required info needed to draw a flat color button.
fn void FlatDraw.setData1(FlatDraw* this, Color c) // @private
{
	RgbColor hotRc = c.makeRgbColor();
	RgbColor frmRc = c.makeRgbColor();
	double hotAdj = hotRc.isDark() ? 1.5 : 1.2;
	double frmAdj = 0.5;
	hotRc.changeShade(hotAdj);
	
	// ptf("hot rc red %d, green %d, blue %d, cref %d", hotRc.red, hotRc.green, hotRc.blue, hotRc.ref);

	this.defBrush = api_CreateSolidBrush(c.ref);
	this.hotBrush = api_CreateSolidBrush(hotRc.ref);
	this.defPen = api_CreatePen(PS_SOLID, 1, frmRc.changeShadeCREF(0.6));
	this.hotPen = api_CreatePen(PS_SOLID, 1, frmRc.changeShadeCREF(0.3));
}

// This struct holds the info for drawing gradient bkg on button.
struct GradDraw // @private
{
	RgbColor stColor;
	RgbColor enColor;
	RgbColor hoverStColor;
	RgbColor hoverEnColor;
	double hoverIntensity;
	bool tintOnHover;
	bool dirty;
	Hbitmap defBmp;
	Hbitmap hotBmp;
	Hpen bPen;
	Hrgn clipRgn;
	Hdc memDC;
}

// Helper struct to hold all colors
struct GradColor // @private
{
	RgbColor c1;
	RgbColor c2;
}

// Setting flat draw color information.
fn bool FlatDraw.setData(FlatDraw* this, uint color, bool tint, double intensity)
{
	this.clr = newRGBColor(color);
	this.defBrush = api_CreateSolidBrush(this.clr.ref);
	RgbColor hover_color = this.clr.changeShadeNew(tint, intensity);
	this.hotBrush = api_CreateSolidBrush(hover_color.ref);
	this.defPen = api_CreatePen(PS_SOLID, 1, this.clr.changeShadeNew(false, 0.25).ref);
	this.hotPen = api_CreatePen(PS_SOLID, 1, this.clr.changeShadeNew(false, 0.5).ref);
	return true;
}

// Setting data for required to create a gradient brush and related stuff.
fn void Button.setGDrawData(&this, uint clr1, uint clr2) // @private
{
	GradDraw* gd = this._gdraw;
	gd.stColor = newRGBColor(clr1);
	gd.enColor = newRGBColor(clr2);
	gd.hoverStColor = gd.stColor.changeShadeNew(gd.tintOnHover, gd.hoverIntensity);
	gd.hoverEnColor = gd.enColor.changeShadeNew(gd.tintOnHover, gd.hoverIntensity);
	gd.defBmp = this.buildGradientBitmap(gd.stColor, gd.enColor);
	gd.hotBmp = this.buildGradientBitmap(gd.hoverStColor, gd.hoverEnColor);
	RgbColor penClr = gd.stColor.changeShadeNew(false, 0.5);
	gd.bPen = api_CreatePen(PS_SOLID, 1, penClr.ref);
	gd.dirty = false;
	this._setDrawData = true;
}

// Destroying resources used for flat color drawing
fn void FlatDraw.dtor(FlatDraw* this) // @private
{
	if (this.defBrush) api_DeleteObject((Hgdiobj) this.defBrush);
	if (this.hotBrush) api_DeleteObject((Hgdiobj) this.hotBrush);
	if (this.defPen) api_DeleteObject((Hgdiobj) this.defPen);
	if (this.hotPen) api_DeleteObject((Hgdiobj) this.hotPen);
	alloc::free(mem, this);
}

// Destroying resources used for gradient drawing
fn void GradDraw.dtor(GradDraw* gd) // @private
{
	if (gd.defBmp != null) deleteGDIObj{Hbitmap}(gd.defBmp);
	if (gd.hotBmp != null) deleteGDIObj{Hbitmap}(gd.hotBmp);
	if (gd.bPen != null) deleteGDIObj{Hpen}(gd.bPen);
	if (gd.clipRgn != null) deleteGDIObj{Hrgn}(gd.clipRgn);
	if (gd.memDC != null) api_DeleteDC(gd.memDC);
	alloc::free(mem, gd);
}

//#region Public functions
	// Button constructor
	fn Button* newButton(Control* parent, String text,
							int x = 10, int y = 10,
							int width = 120, int height = 35,
							EventHandler evtFn = null)
	{
		Button* this = alloc::new(mem, Button);
		this.kind = ControlType.BUTTON;
		this.initBase(parent, x, y, width, height, &btnNumber, text);
		this._createHandleFunc = &_btnCreateHandle;						
		if (evtFn) this.onClick = evtFn;
		return this;
	}

	// Create the handle of button
	fn void _btnCreateHandle(Control* ctl) // @private
	{
		Button* this = (Button*)ctl;
		this._createInternal(this.width, this.height);
		if (this.handle) {
			this.setSubClass(&btnWndProc);
		}
	}

	// Set fore color for button
	fn void Button.setForeColor(Button* b, uint clr)
	{
		b.foreColor.updateColor(clr);
		if (!(b._drawMode & 1)) b._drawMode += 1;
		if (b._isCreated) api_InvalidateRect(b.handle, null, false);
	}

	// Set back color for button
	fn void Button.setBackColor(Button* this, uint clr, bool tintOnHover = false, double hoverIntensity = 0.5)
	{
		this.backColor.updateColor(clr);
		if (this._dmode != DrawMode.FLAT) {
			this._fdraw = alloc::new(mem, FlatDraw);
			this._dmode = DrawMode.FLAT;
		}
		double intens = tintOnHover? hoverIntensity: hoverIntensity / 10;
		this._setDrawData = this._fdraw.setData(clr, tintOnHover, intens);
		if ((this._drawMode & 2) != 2) this._drawMode += 2;
		if (this._isCreated) api_InvalidateRect(this.handle, null, false);
	}

	// Set gradient color for button.
	fn void Button.setGradientColor(Button* this, uint clr1, uint clr2, 
									bool tintOnHover = false, double hoverIntensity = 0.5)
	{
		if (this._dmode != DrawMode.GRAD) {
			this._gdraw = alloc::new(mem, GradDraw);
			this._dmode = DrawMode.GRAD;
		}
		this._gdraw.hoverIntensity = hoverIntensity;
		this._gdraw.tintOnHover = tintOnHover;
		this.setGDrawData(clr1, clr2);
		if ((this._drawMode & 4) != 4) this._drawMode += 4;
		if (this._isCreated) api_InvalidateRect(this.handle, null, false);
	}

//#endregion End of Public functions

// Private functions

	// Handling WM_NOTIFY message in order to change fore color & back color.
	fn Lresult Button.wmNotifyHandler(Button* this, Lparam lpm) // @private
	{
		Lresult ret = CDRF_DODEFAULT;
		if (this._drawMode) {
			NMCustomDraw* nmcd = (NMCustomDraw*)lpm;
			switch (this._drawMode) {
				case 1: ret = this.drawTextColor(nmcd); // ForeColor only
				case 2: ret = this.drawBackColor(nmcd); // BackColor only
				case 3:
					this.drawBackColor(nmcd);
					ret = this.drawTextColor(nmcd);
				case 4: ret = this.drawGradientBackColor(nmcd);
				case 5:
					this.drawGradientBackColor(nmcd);
					ret = this.drawTextColor(nmcd);
			}
		}
		return ret;
	}

	// Drawing button's text with our foreColor.
	fn Lresult Button.drawTextColor(Button* this, NMCustomDraw* ncd) // @private
	{
		int ret = api_SetBkMode(ncd.hdc, TRANSPARENT);
		api_SetTextColor(ncd.hdc, this.foreColor.ref);
		api_SelectObject(ncd.hdc, (Hgdiobj)(this.font.handle));
		// Char16* btext =  String.to_utf16(b.text).ptr!!;
		// defer free(btext);
        api_DrawText(ncd.hdc, this._wsText.ptr(), -1, &ncd.rc, TXTFLAG);
        return CDRF_NOTIFYPOSTPAINT;
	}

	// Drawing flat color bkg on a button.
	fn Lresult Button.drawBackColor(Button* b, NMCustomDraw* nmcd) // @private
	{
		switch (nmcd.dwDrawStage) {
			// case CDDS_PREERASE:	// Note: This return value is critical. Otherwise we don't get below notifications.
			// 	return  CDRF_NOTIFYPOSTERASE;
			case CDDS_PREPAINT:
				if ((nmcd.uItemState & BTN_CLICKED) == BTN_CLICKED) {
					b.paintFlatColor(nmcd, b._fdraw.defBrush, b._fdraw.hotPen);

				} else if ((nmcd.uItemState & BTN_FOCUSED) == BTN_FOCUSED) {
					b.paintFlatColor(nmcd, b._fdraw.hotBrush, b._fdraw.hotPen);

				} else {
					b.paintFlatColor(nmcd, b._fdraw.defBrush, b._fdraw.defPen);
				}
		}
		return CDRF_DODEFAULT;
	}

	// Drawing gradient bkg on a button.
	fn Lresult Button.drawGradientBackColor(Button* this, NMCustomDraw* nmcd) // @private
	{
		switch (nmcd.dwDrawStage) {
			// case CDDS_PREERASE:	// Note: This return value is critical. Otherwise we don't get below notifications.
			// 	return  CDRF_NOTIFYPOSTERASE;
			case CDDS_PREPAINT:
				if ((nmcd.uItemState & BTN_CLICKED) == BTN_CLICKED) {
					this.paintGradientRound(nmcd, this._gdraw.defBmp);

				} else if ((nmcd.uItemState & BTN_FOCUSED) == BTN_FOCUSED) {
					this.paintGradientRound(nmcd, this._gdraw.hotBmp);

				} else {
					this.paintGradientRound(nmcd, this._gdraw.defBmp);
				}
		}
		return CDRF_DODEFAULT;
	}

	// Helper function for flat color button.
	fn void Button.paintFlatColor(Button* b, NMCustomDraw* nmcd, Hbrush hbr, Hpen pen) // @private
	{
		api_SelectObject(nmcd.hdc, (Hgdiobj)hbr);
		api_SelectObject(nmcd.hdc, (Hgdiobj)pen);
		api_RoundRect(nmcd.hdc, nmcd.rc.left, nmcd.rc.top, nmcd.rc.right, nmcd.rc.bottom, 5, 5);
		// api_FillPath(nmcd.hdc);
	}

	// Helper function for gradient color button.
	fn void Button.paintGradientRound(Button* this, NMCustomDraw* nmcd, Hbitmap hbmp) // @private
	{
		GradDraw* grad = this._gdraw;
		int border = 1;
		int rf = 6;
		Rect inset_rc = { 	nmcd.rc.left + border,
							nmcd.rc.top + border,
							nmcd.rc.right - border,
							nmcd.rc.bottom - border,
						};
		int width  = inset_rc.right - inset_rc.left;
		int height = inset_rc.bottom - inset_rc.top;
		if (grad.clipRgn == null) {
			grad.clipRgn = api_CreateRoundRectRgn(inset_rc.left, inset_rc.top, 
													inset_rc.right + 1, inset_rc.bottom + 1,
													3, 3);
	
		}
		api_SelectClipRgn(nmcd.hdc, grad.clipRgn);
    	defer api_SelectClipRgn(nmcd.hdc, (Hrgn)null); // reset clip when done
		if (hbmp != null) {
			if (grad.memDC == null) grad.memDC = api_CreateCompatibleDC(nmcd.hdc);
			Hgdiobj old = api_SelectObject(grad.memDC, (Hgdiobj)hbmp);
			api_BitBlt(nmcd.hdc, inset_rc.left, inset_rc.top, width, height, grad.memDC, 0, 0, SRCCOPY);
			api_SelectObject(grad.memDC, old);
			api_SelectClipRgn(nmcd.hdc, (Hrgn)null);
			Hgdiobj old_pen = api_SelectObject(nmcd.hdc, (Hgdiobj)grad.bPen);
			Hgdiobj old_brush = api_SelectObject(nmcd.hdc, api_GetStockObject(5)); // NULL_BRUSH
			api_RoundRect(nmcd.hdc, nmcd.rc.left, nmcd.rc.top, nmcd.rc.right, nmcd.rc.bottom, rf, rf);
			api_SelectObject(nmcd.hdc, old_brush);
			api_SelectObject(nmcd.hdc, old_pen);
		} else {
			print("hbm is nil");
		}
	}

	// Freeing resources used for this button.
	fn void Button.dtor(Button* this) // @private
	{
		switch (this._drawMode) {
			case 2..3: this._fdraw.dtor();
			case 4..5: this._gdraw.dtor();
		}
		this.baseDestroy();		
		alloc::free(mem, this);
	}

	fn void Button.updateBitmaps(&this) 
	{
		if (this._dmode != DrawMode.GRAD) return;
		GradDraw* grad = this._gdraw;
		int width = this.width;
		int height = this.height;

		if (grad.dirty) {
			if (grad.defBmp != null) api_DeleteObject((Hgdiobj)grad.defBmp);
			if (grad.hotBmp != null) api_DeleteObject((Hgdiobj)grad.hotBmp);

			grad.defBmp = this.buildGradientBitmap(grad.stColor, grad.enColor);
			if (grad.tintOnHover) {
				grad.hotBmp = this.buildGradientBitmap(grad.hoverStColor, grad.hoverEnColor);
			} else {
				grad.hotBmp = this.buildGradientBitmap(grad.hoverStColor, grad.hoverEnColor);
			}

			grad.dirty = false;
		}
	}

	fn char lerpu8(char a, char b, double t) @inline 
	{
    	return (char)((double)a + ((double)b - (double)a) * t);
	}


	fn Hbitmap Button.buildGradientBitmap(&this, RgbColor start, RgbColor end)
	{
		if (this.width <= 0 || this.height <= 0) return (Hbitmap)null;

		BitmapInfo bmi;
		bmi.bmiHeader.biSize = BitmapInfoHeader::size;
		bmi.bmiHeader.biWidth = this.width;
		bmi.bmiHeader.biHeight = -this.height; // top-down DIB
		bmi.bmiHeader.biPlanes = 1;
		bmi.bmiHeader.biBitCount = 32;
		bmi.bmiHeader.biCompression = BI_RGB;

		uint* bits = null;
		double row_size = (double)((this.width * 32 + 31) / 32) * 4;
		uint bits_size = (uint)(row_size * (double)this.height);

		Hbitmap hbm = api_CreateDIBSection((Hdc)null, &bmi, DIB_RGB_COLORS, (void**)&bits, (Handle)null, 0);
		if (hbm == null || bits == null) {
			print("null hbitmap");
			(Hbitmap)null;
		}

		// Fill pixels: DIB is 0xAARRGGBB, but we set alpha = 0
		for (int y = 0; y < this.height; y++) {
			double t = (double)y / (double)(this.height > 1? this.height - 1 : 1);

			char r = lerpu8(start.red, end.red, t);
			char g = lerpu8(start.green, end.green, t);
			char b = lerpu8(start.blue, end.blue, t);

			uint color = (uint)r << 16 | (uint)g << 8 | (uint)b; // 0x00RRGGBB
			uint* row = bits + y * this.width;
			for (int x = 0; x < this.width; x++) {row[x] = color;}
		}
		return hbm;
	}
// End of Private functions


fn Lresult btnWndProc(Hwnd hw, uint msg, Wparam wp, Lparam lp, Uintptr scID, Dwordptr refData) // @private
{
	
	// io::printfn("message %s", msg);
	Button* this = bitcast(refData, Button*);
	MsgHandlerResult res = this.baseWndProc(hw, msg, wp, lp);
	if (res == MsgHandlerResult.CALL_DEF_PROC) {
		return api_DefSubclassProc(hw, msg, wp, lp);
	} else if (res == MsgHandlerResult.RET_IMMEDIATE) {
		return 1;
	}
	switch (msg) {
		case WM_DESTROY: 
			api_RemoveWindowSubclass(hw, &btnWndProc, scID);;
			this.dtor(); 		

		case MM_NOTIFY_REFLECT: 
			return this.wmNotifyHandler(lp);

		default:
			return api_DefSubclassProc(hw, msg, wp, lp);
	}
	return api_DefSubclassProc(hw, msg, wp, lp);
}
