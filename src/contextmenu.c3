// cforms.contextmenu - Moved on 25-Aug-2024 19:19

/*==============================ContextMenu Docs=============================================
    Constructor - newContextMenu()	: ContextMenu*
    Properties:
        parent  : Control* - Any windows control which host a context menu.
        tray    : TrayIcon* - A TrayIcon can host a context menu.
        width   : int - Width of context menu
        height  : int - Height of context menu
    Methods:
        addMenu()  : Adding one menu item
        addMenus()  : Adding menu items in bulk
    Events:
		All public events inherited from Control struct. (See controls.c3)
        onMenuShown     : EventHandler (fn void(Control* s, EventArgs* e))
        onMenuClose     : EventHandler
        onTrayMenuShown : TrayIconEventHandler (fn void(TrayIcon* c, EventArgs* e))
        onTrayMenuClose : TrayIconEventHandler
=========================================================================================== */
 
module cforms;

struct ContextMenu
{
	inline MenuBase _base;
	Control* parent;
	TrayIcon* tray;
    int width, height;
    bool rightClick;
	bool _menuInserted;
	bool _trayParent;
    Colorref _grayCref;
    Hwnd _dummyHwnd;    
    Hbrush _defBgBrush, _hotBgBrush, _borderBrush, _grayBrush;

	// Events
    EventHandler onMenuShown, onMenuClose;
    TrayIconEventHandler onTrayMenuShown, onTrayMenuClose;
}

fn ContextMenu* newContextMenu()
{
	ContextMenu* this = allocator::new(mem, ContextMenu);
	this.handle = api_CreatePopupMenu();	
	this.width = 120;
	this.height = 25;
	this.rightClick = true;
	this.font = newFont("Tahoma", 11);
	this._defBgBrush = getHbrush(0xe9ecef);
	this._hotBgBrush = getHbrush(0x90e0ef);
	this._borderBrush = getHbrush(0x0077b6);
	this._grayBrush = getHbrush(0xced4da);
	this._grayCref = getClrRef(0x979dac);

	/*--------------------------------------------------------------------------
	We are using a message-only-window to handle all messages from context menu.
	So just register a window class for the message-only-window. So that we can..
	create a message-only-windows for each time a context menu appears and...
	destroy the message-only window when the context menu dissappears.
	***************************************************************************/
	if (!cmenuMsgWinCreated) registerCmenuMessageWindow();
	return this;
}

fn MenuItem* ContextMenu.addMenu(&this, String menuText)
{
	MenuType mtyp = menuText == "_" ? MenuType.SEPRATOR : MenuType.MENU_ITEM;
	MenuItem* mi = newMenuItem(menuText, mtyp, this.handle, this._menuCount);
	this._menuCount += 1;
	this._menuList.push(mi);
	return mi;
}

fn void ContextMenu.addMenus(&this, String[] menuNames)
{
	foreach (name: menuNames) {
		MenuType mtyp = name == "|" ? MenuType.SEPRATOR : MenuType.MENU_ITEM;
		MenuItem* mi = newMenuItem(name, mtyp, this.handle, this._menuCount);
		this._menuCount += 1;
		this._menuList.push(mi);
		// ptf("menu: %s, type: %s", mi.text, mi.kind);
	}	
}

fn void MenuItem.insertCmenuInternal(&this) @private
{
	if (this._menuList.len() > 0) {		
		foreach(menu: this._menuList) {menu.insertCmenuInternal();}		
	}
	// ptf("menu: %s, type: %s", this.text, this.kind );
	if (this.kind == MenuType.MENU_ITEM) {
        this.insertMenuInternal(this.parentHandle);
    } else if (this.kind == MenuType.SEPRATOR) {
        api_AppendMenu(this.parentHandle, MF_SEPARATOR, 0, null);
	}
}

fn void ContextMenu.createHandle(&this) 
{
	if (this._menuList.len() > 0) {		
		foreach(menu: this._menuList) {menu.insertCmenuInternal();}
	}
	this._menuInserted = true;
}


fn MenuItem* ContextMenu.getMenuItem(&this, uint id) @private
{	
	// ptf("given id: %d", id);
	if (this._menuList.len() > 0) {
		foreach(menu: this._menuList) {
			// ptf("menu name: %s, menu id: %d", menu.text, menu.idNum);
			if (menu.idNum == id) return menu;
		}
	}
	return null;
}

<*
 @require this.parent || this._trayParent && this._menuList.len() "Either parent is null or no menu items added"
*>
fn void ContextMenu.showMenu(&this, Lparam lpm) @private
{	
	/*===================================================================================
	Let's first create the message-only-window for this menu. These are lightweight windows.
	so that they occupy very less memory. And they are good for handling messages. We will
	destroy this window right after the context menu dissapears.
	========================================================================================*/
	this.createMessageWindow();
	defer {
		api_DestroyWindow(this._dummyHwnd);
		this._dummyHwnd = null;
	}		
	if (!this._menuInserted) this.createHandle();
	Point pt;
	lpm ? getMousePoints2(&pt, lpm) : api_GetCursorPos(&pt);	

	/*-------------------------------------------------------------------------------------
	If ContextMenu is generated by a keybord shortcut like 'Ctrl + F10' or 'VK_APPS' key,
	x & y might be -1. So we need to find the mouse position on our own.
	NOTE: Short keys are working with only TrayMenuTrigger.RIGHT_CLICK
	-------------------------------------------------------------------------------------*/
	if (pt.x == -1 && pt.y == -1) pt = getMousePosOnMsg();

	/*------------------------------------------------------------------------------------
	This is a hack. If context menu is displayed from a tray icon A window from this thread
	must be in forground, otherwise we won't get any keyboard messages. If user wants to 
	select any menu item, we must activate any window. So we are bringing our tray's 
	message-only window to foreground. 
	---------------------------------------------------------------------------------------*/
	if (!lpm) api_SetForegroundWindow(this.tray._msgWinHwnd);

	/*------------------------------------------------------------------------
	We are using TPM_RETURNCMD, so we don't get the WM_COMMAND in our wndproc, 
	we will get the selected menu id in return value.
	----------------------------------------------------------------------------*/
	uint mid = (uint)api_TrackPopupMenu(this.handle, TPM_RETURNCMD, 
										pt.x, pt.y, 0, this._dummyHwnd, null);	
	/*-------------------------------------------------------------
	We got the result here. So if user has selected any menu item,
	we need to find the menu item and execute it's onClick handler.
	---------------------------------------------------------------*/
	// print("======================================");
	if (mid > 0) {
		MenuItem* menu = this.getMenuItem(mid);
		if (menu && menu._isEnabled) {
			if (menu.onClick) menu.onClick(menu, &gea);
		}
	}
		
	
}

// Registering message-only window class for context menu.
fn void registerCmenuMessageWindow() @private
{
	WndClassEx wc;
	wc.cbSize = WndClassEx.sizeof;
	wc.lpfnWndProc = &cmenuWndProc;
	wc.hInstance = app.hins;
	wc.lpszClassName = &cmenuMsgWinClass[0];
	api_RegisterClassEx(&wc);
	cmenuMsgWinCreated = true;
}

// Creating message only window for handling menu messages.
fn void ContextMenu.createMessageWindow(&this) @private
{	
	this._dummyHwnd = api_CreateWindowEx(0, &cmenuMsgWinClass[0], null, 0, 0, 0, 0, 0, HWND_MESSAGE, null, app.hins, null);    
    api_SetWindowLongPtr(this._dummyHwnd, GWLP_USERDATA, bitcast(this, Longptr));
	if (!this.font.handle) this.font.createHandle();
	// ptf("Cmenu message only win handle %d", this._dummyHwnd);
}

fn void ContextMenu.destroy(&this) @private
{
	/*====================================================================	
	When a control is enabled it's context menu, it is responsible...
	to call this destroyer when it is done with the context menu.
	=====================================================================*/

	// We first clean our menu items.
	if (this._menuCount > 0) {		
		foreach(menu: this._menuList) {menu.destroy();}
		this._menuList.free();
	}
	// Destroying our GDI resources.
	api_DeleteObject((Hgdiobj)this._defBgBrush);
	api_DeleteObject((Hgdiobj)this._hotBgBrush);
	api_DeleteObject((Hgdiobj)this._borderBrush);
	api_DeleteObject((Hgdiobj)this._grayBrush);
	api_DestroyMenu(this.handle);
	allocator::free(mem, this);
	// print("Context menu struct destroyed");
}

fn Lresult cmenuWndProc(Hwnd hw, uint msg, Wparam wp, Lparam lp) @private
{	
	// log("cmenu wnd proc %d", msg);
	switch (msg) {
		//case WM_DESTROY:			
			//print("context menu's message-only-window destroyed");

		case WM_MEASUREITEM:
			ContextMenu* this = bitcast(api_GetWindowLongPtr(hw, GWLP_USERDATA), ContextMenu*);
			MeasureItemStruct* pmi = (MeasureItemStruct*)lp;
			pmi.itemWidth = this.width;
			pmi.itemHeight = this.height;
			return 1;

    	case WM_DRAWITEM:
			ContextMenu* this = bitcast(api_GetWindowLongPtr(hw, GWLP_USERDATA), ContextMenu*);
			DrawItemStruct* dis = (DrawItemStruct*)lp;
			MenuItem* mi = (MenuItem*)((void*)dis.itemData);
			Colorref txtClrRef = mi.fgColor.ref;
			if (dis.itemState & 1) {
				if (mi._isEnabled) {
					Rect rc = {dis.rcItem.left + 4, dis.rcItem.top + 2, dis.rcItem.right, dis.rcItem.bottom - 2};
					api_FillRect(dis.hDC, &rc, this._hotBgBrush);
					api_FrameRect(dis.hDC, &rc, this._borderBrush);
					txtClrRef = 0x00000000;
				} else {
					api_FillRect(dis.hDC, &dis.rcItem, this._grayBrush);
					txtClrRef = this._grayCref;
				}
			} else {
				api_FillRect(dis.hDC, &dis.rcItem, this._defBgBrush);
				if (!mi._isEnabled) txtClrRef = this._grayCref;
			}

			api_SetBkMode(dis.hDC, 1);
			dis.rcItem.left += 25;
			api_SelectObject(dis.hDC, (Hgdiobj)this.font.handle);
			api_SetTextColor(dis.hDC, txtClrRef);
			api_DrawText(dis.hDC, mi._wideText, -1, &dis.rcItem, DT_LEFT | DT_SINGLELINE | DT_VCENTER);
			return 0;

		case WM_ENTERMENULOOP:			
			ContextMenu* this = bitcast(api_GetWindowLongPtr(hw, GWLP_USERDATA), ContextMenu*);
			// ptf("WM_ENTERMENULOOP, cmenu handle %d", this.handle);
			if (this.onMenuShown) {
				if (this._trayParent) {
					this.onTrayMenuShown(this.tray, &gea);
				} else {
					this.onMenuShown(this.parent, &gea);
				}
			}				

		case WM_EXITMENULOOP:
			// print("WM_EXITMENULOOP");
			ContextMenu* this = bitcast(api_GetWindowLongPtr(hw, GWLP_USERDATA), ContextMenu*);
			if (this.onMenuClose) {
				if (this._trayParent) {
					this.onTrayMenuClose(this.tray, &gea);
				} else {			
					this.onMenuClose(this.parent, &gea);
				}
			}

		case WM_MENUSELECT:
			ContextMenu* this = bitcast(api_GetWindowLongPtr(hw, GWLP_USERDATA), ContextMenu*);
			int idNum = (int) loWord(wp);
			Hmenu hMenu = (Hmenu) lp;
			if (hMenu && idNum > 0) {
				MenuItem* menu = this.getMenuItem(idNum);
				// ptf("menu text %s, onClick %d", menu.text, (int)(uptr)menu.onClick);
				if (menu && menu._isEnabled) {
					if (menu.onFocus) menu.onFocus(menu, &gea);
				}
			}	

		default:
			return api_DefWindowProc(hw, msg, wp, lp);
	}
	return 0;
}
