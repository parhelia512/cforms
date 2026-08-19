
// apifns - Created on 24-Jan-2023 22:01
module cforms;

// Macros
	// macro makeIntResource($i) { return (Lpcwstr)(UlongPtr)(Word)$i; }


extern fn int _msgBox(Hwnd hWnd, Char16* lpText, Char16* lpCaption, uint uType) @cname("MessageBoxW");

// User32 dll functions
	extern fn Bool api_SetProcessDpiAwarenessContext(DPIAwarenessContext) @cname("SetProcessDpiAwarenessContext");
	extern fn uint api_GetDpiForSystem() @cname("GetDpiForSystem");
	extern fn Hcursor api_LoadCursor(Hinstance instance, Lpcwstr cursorName) @cname("LoadCursorW");
	extern fn Hicon api_LoadIcon(Hinstance instance, Lpcwstr iconName) @cname("LoadIconW");
	extern fn Bool api_DestroyIcon(Hicon) @cname("DestroyIcon");
	extern fn Hicon api_LoadImage(Hinstance instance, Lpcwstr name, uint typ, int cx, int cy, uint fuload) @cname("LoadImageW");
	extern fn short api_RegisterClassEx(WndClassEx*) @cname("RegisterClassExW");
	extern fn Hwnd api_CreateWindowEx(Dword, Lpcwstr, Lpcwstr, Dword, int, int, int, int, Hwnd, Hmenu, Hinstance, Pvoid) @cname("CreateWindowExW");
	extern fn Bool api_ShowWindow(Hwnd, int) @cname("ShowWindow");
	extern fn Bool api_UpdateWindow(Hwnd) @cname("UpdateWindow");
	extern fn Bool api_GetMessage(LpMsg, Hwnd, uint, uint) @cname("GetMessageW");
	extern fn Bool api_TranslateMessage(LpMsg) @cname("TranslateMessage");
	extern fn Bool api_DispatchMessage(LpMsg) @cname("DispatchMessageW");
	extern fn Lresult api_DefWindowProc(Hwnd, uint, Wparam, Lparam) @cname("DefWindowProcW");
	extern fn void api_PostQuitMessage(int) @cname("PostQuitMessage");
	extern fn Hdc api_GetDC(Hwnd) @cname("GetDC");
	extern fn Hdc api_GetWindowDC(Hwnd) @cname("GetWindowDC");
	extern fn Hdc api_GetDCEx(Hwnd, Hrgn, Dword) @cname("GetDCEx");
	extern fn int api_ReleaseDC(Hwnd, Hdc) @cname("ReleaseDC");
	extern fn Lresult api_SendMessage(Hwnd, uint, Wparam, Lparam) @cname("SendMessageW");
	extern fn Lresult api_SendNotifyMessage(Hwnd, uint, Wparam, Lparam) @cname("SendNotifyMessageW");

	extern fn Lresult api_PostMessage(Hwnd, uint, Wparam, Lparam) @cname("PostMessageW");
	extern fn Longptr api_SetWindowLongPtr(Hwnd, int, Longptr) @cname("SetWindowLongPtrW");
	extern fn Longptr api_GetWindowLongPtr(Hwnd, int) @cname("GetWindowLongPtrW");
	extern fn int api_GetSystemMetrics(int) @cname("GetSystemMetrics");
	extern fn Bool api_InvalidateRect(Hwnd, Rect*, bool) @cname("InvalidateRect");
	extern fn Bool api_GetClientRect(Hwnd, Rect*) @cname("GetClientRect");
	extern fn int api_FillRect(Hdc, Rect*, Hbrush) @cname("FillRect");
	extern fn Bool api_TrackMouseEvent(TrackMOUSEEVENT*) @cname("TrackMouseEvent");
	extern fn int api_DrawText(Hdc, Lpcwstr, int, Rect*, uint) @cname("DrawTextW");
	extern fn Bool api_InflateRect(Rect*, int, int) @cname("InflateRect");
	extern fn Bool api_DrawEdge(Hdc, Rect*, uint, uint) @cname("DrawEdge");
	extern fn Bool api_SetWindowPos(Hwnd, Hwnd, int, int, int, int, uint) @cname("SetWindowPos");
	extern fn Bool api_DestroyWindow(Hwnd) @cname("DestroyWindow");
	extern fn Bool api_GetWindowRect(Hwnd, Rect*) @cname("GetWindowRect");
	extern fn Dword api_GetMessagePos() @cname("GetMessagePos");
	extern fn Bool api_PtInRect(Rect*, Point) @cname("PtInRect");
	extern fn Bool api_MoveWindow(Hwnd, int, int, int, int, bool) @cname("MoveWindow");
	extern fn Hdc api_BeginPaint(Hwnd, PaintStruct*) @cname("BeginPaint");
	extern fn Bool api_EndPaint(Hwnd, PaintStruct*) @cname("EndPaint");
	extern fn Bool api_SetRect(Rect*, int, int, int, int) @cname("SetRect");
	extern fn Bool api_OffsetRect(Rect*, int, int) @cname("OffsetRect");
	extern fn Bool api_SetWindowText(Hwnd, Lpcwstr) @cname("SetWindowTextW");
	extern fn int api_GetWindowTextLength(Hwnd) @cname("GetWindowTextLengthW");
	extern fn int api_GetWindowText(Hwnd, Char16*, int) @cname("GetWindowTextW");
	extern fn Dword api_GetSysColor(int) @cname("GetSysColor");
	extern fn int api_FrameRect(Hdc, Rect*, Hbrush) @cname("FrameRect");
	extern fn Bool api_RedrawWindow(Hwnd, Rect*, Hrgn, uint) @cname("RedrawWindow");
	extern fn Hmenu api_CreateMenu() @cname("CreateMenu");
	extern fn Hmenu api_CreatePopupMenu() @cname("CreatePopupMenu");
	extern fn Bool api_AppendMenu(Hmenu, uint, Uintptr, Lpcwstr) @cname("AppendMenuW");
	extern fn Bool api_SetMenu(Hwnd, Hmenu) @cname("SetMenu");
	extern fn Bool api_InsertMenuItemW(Hmenu, uint, Bool, MenuItemInfoW*) @cname("InsertMenuItemW");
	extern fn Bool api_TrackPopupMenu(Hmenu, uint, int, int, int, Hwnd, Rect*) @cname("TrackPopupMenu");
	extern fn Bool api_DestroyMenu(Hmenu) @cname("DestroyMenu");
	extern fn int api_MapWindowPoints(Hwnd, Hwnd, LpPoint, uint) @cname("MapWindowPoints");
	extern fn int api_SetTimer(Hwnd, Uintptr, uint, TimerProc) @cname("SetTimer");
	extern fn int api_KillTimer(Hwnd, Uintptr) @cname("KillTimer");
	extern fn Bool api_UnregisterClass(Lpcwstr, Hinstance) @cname("UnregisterClassW");
	extern fn int api_GetCursorPos(Point*) @cname("GetCursorPos");
	extern fn Bool api_SetForegroundWindow(Hwnd) @cname("SetForegroundWindow");
	extern fn Bool api_IsWindow(Hwnd) @cname("IsWindow");
	extern fn Bool api_RegisterHotKey(Hwnd, int, uint, uint) @cname("RegisterHotKey");
	extern fn Bool api_UnregisterHotKey(Hwnd, int) @cname("UnregisterHotKey");
	extern fn Hwnd api_SetCapture(Hwnd) @cname("SetCapture");
	extern fn Bool api_ReleaseCapture(Hwnd) @cname("ReleaseCapture");
	extern fn Bool api_ScreenToClient(Hwnd, Point*) @cname("ScreenToClient");
	extern fn Bool api_UnionRect(Rect*, Rect*, Rect*) @cname("UnionRect");
	extern fn Bool api_CloseWindow(Hwnd) @cname("CloseWindow");




// End User32

// Kernel32 dll functions
	extern fn Hmodule api_GetModuleHandle(Lpcwstr lpc) @cname("GetModuleHandleW");
	extern fn Dword api_GetLastError() @cname("GetLastError");
	extern fn int api_MulDiv(int, int, int) @cname("MulDiv");
	extern fn Bool api_GetHandleInformation(Handle, Dword*) @cname("GetHandleInformation");

// End Kernel32

// Gdi32 dll functions
	extern fn Hbrush api_CreateSolidBrush(Colorref) @cname("CreateSolidBrush");
	extern fn int api_GetDeviceCaps(Hdc, int) @cname("GetDeviceCaps");
	extern fn Hfont api_CreateFontIndirect(LogFont*) @cname("CreateFontIndirectW");
	extern fn Hfont api_CreateFont(int, int, int, int, int, Dword, Dword, Dword, Dword, Dword, Dword, Dword, Dword, Lpcwstr) @cname("CreateFontW");
	extern fn Bool api_DeleteObject(Hgdiobj) @cname("DeleteObject");
	extern fn Colorref api_SetTextColor(Hdc, Colorref) @cname("SetTextColor");
	extern fn int api_SetBkMode(Hdc, int) @cname("SetBkMode");
	extern fn Hgdiobj api_SelectObject(Hdc, Hgdiobj) @cname("SelectObject");
	extern fn Hpen api_CreatePen(int, int, Colorref) @cname("CreatePen");
	extern fn Bool api_Rectangle(Hdc, int, int, int, int) @cname("Rectangle");
	extern fn Hdc api_CreateCompatibleDC(Hdc) @cname("CreateCompatibleDC");
	extern fn Hbitmap api_CreateCompatibleBitmap(Hdc, int, int) @cname("CreateCompatibleBitmap");
	extern fn Hbrush api_CreatePatternBrush(Hbitmap) @cname("CreatePatternBrush");
	extern fn Bool api_DeleteDC(Hdc) @cname("DeleteDC");
	extern fn Bool api_FillPath(Hdc) @cname("FillPath");
	extern fn Bool api_RoundRect(Hdc, int, int, int, int, int, int) @cname("RoundRect");
	extern fn Bool api_GetTextExtentPoint32(Hdc, Lpcwstr, int, Size*) @cname("GetTextExtentPoint32W");
	extern fn Bool api_SetBkColor(Hdc, Colorref) @cname("SetBkColor");
	extern fn Bool api_MoveToEx(Hdc, int, int, Point*) @cname("MoveToEx");
	extern fn Bool api_LineTo(Hdc, int, int) @cname("LineTo");
	extern fn Bool api_TextOut(Hdc, int, int, Lpcwstr, int) @cname("TextOutW");
	extern fn Hgdiobj api_GetStockObject(int) @cname("GetStockObject");
	extern fn int api_SaveDC(Hdc) @cname("SaveDC");
	extern fn Bool api_RestoreDC(Hdc, int) @cname("RestoreDC");
	extern fn Bool api_BitBlt(Hdc, int, int, int, int, Hdc, int, int, Dword) @cname("BitBlt");
	extern fn Bool api_GetObject(Handle, int, Pvoid) @cname("GetObjectW");
	extern fn Bool api_Polyline(Hdc, Point*, int) @cname("Polyline");
	extern fn Hbitmap api_CreateDIBSection(Hdc, BitmapInfo*, uint, void**, Handle, Dword) @cname("CreateDIBSection");
	extern fn Hrgn api_CreateRoundRectRgn(int, int, int, int, int, int) @cname("CreateRoundRectRgn");
	extern fn int api_SelectClipRgn(Hdc, Hrgn) @cname("SelectClipRgn");



// End Gdi32

// CommCtrl dll functions
	extern fn Bool api_SetWindowSubclass(Hwnd, Subclassproc, Uintptr, Dwordptr) @cname("SetWindowSubclass");
	extern fn Bool api_RemoveWindowSubclass(Hwnd, Subclassproc, Uintptr) @cname("RemoveWindowSubclass");
	extern fn Lresult api_DefSubclassProc(Hwnd, uint, Wparam, Lparam) @cname("DefSubclassProc");
	extern fn Bool api_InitCommonControlsEx(InitCommonControls*) @cname("InitCommonControlsEx");


// End CommCtrl

// Miscs
	extern fn int api_MultiByteToWideChar(uint, Dword, char*, int, Lpwstr, int) @cname("MultiByteToWideChar");
	extern fn Bool api_GetOpenFileName(OpenFileNameW*) @cname("GetOpenFileNameW");
	extern fn Bool api_GetSaveFileName(OpenFileNameW*) @cname("GetSaveFileNameW");
	extern fn PidList_Absolute api_SHBrowseForFolder(BrowseInfoW*) @cname("SHBrowseForFolderW");
	extern fn Bool api_SHGetPathFromIDList(PcIdList_Absolute, Lpwstr) @cname("SHGetPathFromIDListW");
	extern fn void api_CoTaskMemFree(void*) @cname("CoTaskMemFree");
	extern fn Bool api_Shell_NotifyIcon(Dword, NotifyIconData*) @cname("Shell_NotifyIconW");
	extern fn int api_GetScaleFactorForDevice(int) @cname("GetScaleFactorForDevice");
	extern fn Dword api_GetModuleFileName(Hmodule, Lpwstr, Dword) @cname("GetModuleFileNameW");
	extern fn Hresult api_SetWindowTheme(Hwnd, Lpwstr, Lpwstr) @cname("SetWindowTheme");
//


// GDI+ functions
	extern fn Status api_GdiplusStartup(Ulongptr* token, GdiplusStartupInput* input,
    								GdiplusStartupOutput* output) @cname("GdiplusStartup");

	extern fn void api_GdiplusShutdown(Ulongptr* token) @cname("GdiplusShutdown");
	extern fn Status api_GdipCreateBitmapFromFile(Wstring file, 
													void* pBitmap) @cname("GdipCreateBitmapFromFile");
	extern fn Status api_GdipCreateHBITMAPFromBitmap(void* pBitmap,	Hbitmap* pRetHbmp,
													int argb) @cname("GdipCreateHBITMAPFromBitmap");
	extern fn Status api_GdipBitmapSetResolution(void* pBitmap,	int xdpi, 
													int ydpi) @cname("GdipBitmapSetResolution");
	extern fn Status api_GdipLoadImageFromFile(Lpwstr file, void** image) @cname("GdipLoadImageFromFile");
	extern fn Status api_GdipGetImageWidth(void* img, uint* width) @cname("GdipGetImageWidth");
	extern fn Status api_GdipGetImageHeight(void* img, uint* height) @cname("GdipGetImageHeight");
	extern fn Status api_GdipCreateBitmapFromScan0(int width, int height, int stride, 
													PixelFormat pf, Byte* scan0, 
													void* pBmp) @cname("GdipCreateBitmapFromScan0");
	extern fn Status api_GdipGetImageGraphicsContext(void* image, 
													void** graphics) @cname("GdipGetImageGraphicsContext");
	extern fn Status api_GdipSetInterpolationMode(void* graphics, 
												InterPolationMode ipMode) @cname("GdipSetInterpolationMode");
	extern fn Status api_GdipSetPixelOffsetMode(void* graphics, 
												PixelOffsetMode pxoMode) @cname("GdipSetPixelOffsetMode");
	extern fn Status api_GdipCreateImageAttributes(void** imageattr) @cname("GdipCreateImageAttributes");
	extern fn Status api_GdipDisposeImageAttributes(void* imageattr) @cname("GdipDisposeImageAttributes");
	extern fn Status api_GdipDeleteGraphics(void* graphics) @cname("GdipDeleteGraphics");
	extern fn Status api_GdipDisposeImage(void* image) @cname("GdipDisposeImage");
	extern fn Status api_GdipDrawImageRect(GpGraphics* graphics, GpImage* image, float x, float y,
										float width, float height) @cname("GdipDrawImageRect");
	extern fn Status api_GdipDrawImageRectRect(void* graphics, void* image, int dstx, int dsty,
											int dstwidth, int dstheight, int srcx, int srcy,
											int srcwidth, int srcheight, GpUnit srcUnit,
											void* imageAttributes, void* callback,
											void* callbackData) @cname("GdipDrawImageRectRect");
	extern fn Status api_GdipCreateFromHDC(Hdc hdc,	GpGraphics** graphics) @cname("GdipCreateFromHDC");

