// listbox module - Created on 08-Feb-2023 11:32
// Note: Add selectedIndices property
/*==================================================ListBox Docs======================================
	ListBox type
		Constructor: newListBox(...)	: ListBox*
		Properties:
			Inherits all properties from Control struct
			hasSort				: bool
			noSelection			: bool
			multiColumn			: bool
			keyPreview			: bool
			verticalScroll		: bool
			horizontalScroll	: bool
			multiSelection		: bool
			selectedIndices		: Lis<int>
			items				: List<String>
			selectedIndex		: int
		Methods:
			createHandle()		: void. Creates the handle
			addItem()			: void. Add an item
			addItems()			: void. Add items in bulk
			insertItem()		: void. Insert an Item
			removeItem()		: void. Remove an item
			clearItems()		: void. Clear all items
			selectedItem()		: String. Get the selected item
			selectedItems()		: List<String>. Get the selected items from multi selection listbox
			selectAll()			: void. Select all the items
			clearSelection()	: void. Clear the selection
			indexOf()			: int. Get the index of given item
			hotIndex()			: int. Get the index of the item under mouse pointer
			hotItem()			: String. Get the item under mouse pointer
		Events:
			Inherits all events from Control struct
			EventHandler type events - (fn void(Control*, EventArgs*))
				onSelectionChanged
				onSelectionCancelled
				onDoubleClick

=====================================================================================================*/
module cforms;
import std::collections::list;
// import std::io;

int lbxNumber = 1;
Wstring lbxClass = {'L', 'i', 's', 't', 'B', 'o', 'x', 0};


// ListBox control struct
struct ListBox
{
	inline Control control;
	bool hasSort;
	bool noSelection ;
	bool multiColumn;
	bool keyPreview;
	bool verticalScroll;
	bool horizontalScroll;
	bool multiSelection;
	IntList selectedIndices;
	StrList items;
	int _dummyIndex;
	int selectedIndex;

	EventHandler onSelectionChanged;
	EventHandler onSelectionCancelled;
	EventHandler onDoubleClick;
}

// Public functions
	// ListBox constructor
	fn ListBox* newListBox(Form* parent, int x = 10, int y = 10,
							int width = 150, int height = 150)
	{
		ListBox* this = allocator::new(mem, ListBox);
		this.kind = ControlType.LIST_BOX;
		this.name = dstring::new(mem, "ListBox_");
		this.name.appendf("%d", lbxNumber);
		this._className = &lbxClass[0];
		this._parent = parent;
		//this.font = parent.font;
		this._style = WS_VISIBLE | WS_CHILD | WS_BORDER  | LBS_NOTIFY | LBS_HASSTRINGS;
		this._exStyle = 0;
		this.xpos = x;
		this.ypos = y;
		this.width = width;
		this.height = height;
		this.backColor = newColor(0xffffff);
		this.foreColor = newColor(0x000000);
		this._dummyIndex = -1;
		this.selectedIndex = -1;
		lbxNumber += 1;
		this.font.cloneFrom(parent.font);
		this._parent.controls.push(this);
		if (parent.createChilds) this.createHandle();
		return this;
	}

	// Create the handle of ListBox
	fn void ListBox.createHandle(ListBox* this)
	{
		this.setLbxStyle();
		this.createInternal();
		if (this.handle) {
			this.setSubClass(&lbxWndProc);
			this.setFontInternal();
			this.manageItems();
		}
	}

	// Add an item to list box.
	fn void ListBox.addItem(ListBox* this, String item)
	{
		this.items.push(item);
		if (this._isCreated) {
			Char16* lbtext = String.to_utf16(item, mem)!!.ptr;
			defer free(lbtext);
			this.sendMsg(LB_ADDSTRING, 0, lbtext);
		}
	}

	// Add multiple items to listbox
	fn void ListBox.addItems(ListBox* this, String... items) => @pool()
	{
		foreach (item: items) {
			if (this._isCreated) {
				Char16* sitem = item.to_temp_utf16()!!.ptr;
				this.sendMsg(LB_ADDSTRING, 0, sitem);
			}
			this.items.push(item);
		}
	}

	// Insert an item at given index
	fn void ListBox.insertItem(ListBox* this, String item, int index) => @pool()
	{
		this.items.insert_at(index, item);
		if (this._isCreated) {
			Char16* sitem = item.to_temp_utf16()!!.ptr;			
			this.sendMsg(LB_INSERTSTRING, index, sitem);
		}
	}

	// Remove an item with given index
	fn void ListBox.removeItem(ListBox* this, int index)
	{
		if (this.items.len()) {
			this.clearAllInternal();
			this.items.remove_at(index);
			this.manageItems();
		}

	}

	// Delete all items from listbox
	fn void ListBox.clearItems(ListBox* this)
	{
		if (this.items.len()) {
			this.clearAllInternal();
			this.items.clear();
		}
	}

	// Returns the selected item from ListBox. Don't forget to free the string.
	fn String ListBox.selectedItem(ListBox* this)
	{
		if (this._isCreated && !this.multiSelection) {
			int indx = (int)this.sendMsg(LB_GETCURSEL, 0, 0);
            if (indx != LB_ERR) {
				this.selectedIndex = indx;
				String selItem = this.getItemInternal(this.selectedIndex);
				return selItem;
			} else {
				return "";
			}
		}
		return "";
	}

	// Returns the selected items from a multi selection listbox. Dont forget to free the list.
	fn StrList ListBox.selectedItems(ListBox* this)
	{
		StrList sItems;
		if (this._isCreated && this.multiSelection) {
			int selCount = (int)this.sendMsg(LB_GETSELCOUNT, 0, 0);
			if (selCount != LB_ERR) {
				@pool() {
					int[] buffer = mem::talloc_array(int, selCount);
					this.sendMsg(LB_GETSELITEMS, selCount, &buffer[0]);
					foreach (indx: buffer) { sItems.push(this.getItemInternal(indx));}
				};
			}
		}
		return sItems;
	}

	// Select all items
	fn void ListBox.selectAll(ListBox* this)
	{
		if (this._isCreated && this.multiSelection) this.sendMsg(LB_SETSEL, true, -1);
	}

	// Clear the selection from listbox
	fn void ListBox.clearSelection(ListBox* this)
	{
		if (this._isCreated) {
			uint msg = this.multiSelection ? LB_SETSEL : LB_SETCURSEL;
			int lpm = this.multiSelection ? -1 : 0;
			this.sendMsg(msg, false, lpm);
		}
	}

	// Returns the index of given item
	fn int ListBox.indexOf(ListBox* this, String item)
	{
		Char16[] witem = String.to_utf16(item, mem)!!;
		defer free(witem);
		return (int) this.sendMsg(LB_FINDSTRINGEXACT, -1, witem.ptr);
	}

	// Returns the index of the item which is under mouse pointer
	fn int ListBox.hotIndex(ListBox* this)
	{
		if (this.multiSelection) return (int) this.sendMsg(LB_GETCARETINDEX, 0, 0);
		return -1;
	}

	// Returns item which is under mouse. Don't forget to free the string
	fn String ListBox.hotItem(ListBox* this)
	{
		if (this.multiSelection) {
			int hindex =  (int) this.sendMsg(LB_GETCARETINDEX, 0, 0);
			if (hindex != LB_ERR) return this.getItemInternal(hindex);
		}
		return "";
	}

// End of Public functions

// Private functions

	// Setting control's style bits.
	fn void ListBox.setLbxStyle(ListBox* this) @private
	{
		if (this.hasSort) this._style |= LBS_SORT;
		if (this.multiSelection) this._style |= LBS_EXTENDEDSEL | LBS_MULTIPLESEL;
		if (this.multiColumn) this._style |= LBS_MULTICOLUMN;
		if (this.noSelection) this._style |= LBS_NOSEL;
		if (this.keyPreview) this._style |= LBS_WANTKEYBOARDINPUT;
		if (this.horizontalScroll) this._style |= WS_HSCROLL;
		if (this.verticalScroll) this._style |= WS_VSCROLL;
		this._bkBrush = this.backColor.getBrush();
	}

	fn void ListBox.manageItems(ListBox* this) @private
	{
		if (this.items.len() > 0)  {// We need to add those items to list box
            foreach (item: this.items) {
				Char16* sitem = String.to_utf16(item, mem)!!.ptr;
				defer free(sitem);
				this.sendMsg(LB_ADDSTRING, 0, sitem);
			}
            if (this._dummyIndex > -1) this.sendMsg(LB_SETCURSEL, this._dummyIndex, 0);
        }
	}

	// Internal function to clear all items
	fn void ListBox.clearAllInternal(ListBox* this) @private @inline
	{
		this.sendMsg(LB_RESETCONTENT, 0, 0);
		api_UpdateWindow(this.handle);
	}

	//fault ArrayResult {EMPTY_ARRAY}

	// Internal function to get an item. Caller must free the return value
	fn String ListBox.getItemInternal(ListBox* this, int index) @private
	{
		int sLen = (int)this.sendMsg(LB_GETTEXTLEN, index, 0);
		if (sLen) {
			@pool() {
				Char16[] buffer = mem::talloc_array(Char16, sLen);
				Lresult res =this.sendMsg(LB_GETTEXT, index, &buffer[0]);
				String x = string::from_utf16(mem, buffer)!!;
				return x;
			};
		}
		return "" ;
	}

	// Internal function for handling wm_command message
	fn void ListBox.wmCommandHandler(ListBox* this, Wparam wpm) @private
	{
		Word ncode = hiWord(wpm);
		switch (ncode) {
			case LBN_DBLCLK: if (this.onDoubleClick) this.onDoubleClick(this, &gea);
			case LBN_KILLFOCUS: if (this.onLostFocus) this.onLostFocus(this, &gea);
			case LBN_SELCHANGE: if (this.onSelectionChanged) this.onSelectionChanged(this, &gea);
			case LBN_SETFOCUS: if (this.onGotFocus) this.onGotFocus(this, &gea);
			case LBN_SELCANCEL: if (this.onSelectionCancelled) this.onSelectionCancelled(this, &gea);
		}
	}


	// Handling back & fore color changing in WndProc function
	fn Hbrush ListBox.colorMsgHandler(ListBox* this, Wparam wpm) @private
	{
		Hdc hdc = (Hdc)wpm;
		api_SetBkMode(hdc, TRANSPARENT);
		if (this._drawMode & 1) api_SetTextColor(hdc, this.foreColor.ref);
		api_SetBkColor(hdc, this.backColor.ref);
		return this._bkBrush;
	}


	// Freeing resources used for this ListBox.
	fn void ListBox.dtor(ListBox* this) @private
	{
		this.selectedIndices.free();
		this.items.free();
		this.baseDestroy();
		allocator::free(mem, this);
	}
// End of Private functions


fn Lresult lbxWndProc(Hwnd hw, uint msg, Wparam wp, Lparam lp, Uintptr scID, Dwordptr refData) @private
{
	
	// io::printfn("message %s", msg);
	switch (msg) {
		case WM_DESTROY:
			ListBox* this = bitcast(refData, ListBox*);
			api_RemoveWindowSubclass(hw, &lbxWndProc, scID);
			this.dtor();

		case WM_LBUTTONDOWN:
			ListBox* this = bitcast(refData, ListBox*);
			this.leftMouseDownHandler(msg, wp, lp);
		case WM_LBUTTONUP:
			ListBox* this = bitcast(refData, ListBox*);
			this.leftMouseUpHandler(msg, wp, lp);
		case MM_MOUSE_LBCLICK:
			ListBox* this = bitcast(refData, ListBox*);
			this.leftClickHandler();

		case WM_RBUTTONDOWN:
			ListBox* this = bitcast(refData, ListBox*);
			this.rightMouseDownHandler(msg, wp, lp);
		case WM_RBUTTONUP:
			ListBox* this = bitcast(refData, ListBox*);
			this.rightMouseUpHandler(msg, wp, lp);
		case MM_MOUSE_RBCLICK:
			ListBox* this = bitcast(refData, ListBox*);
			this.rightClickHandler();

		case WM_MOUSEMOVE:
			ListBox* this = bitcast(refData, ListBox*);
			this.mouseMoveHandler(msg, wp, lp);
		case WM_MOUSELEAVE:
			ListBox* this = bitcast(refData, ListBox*);
			this.mouseLeaveHandler();
		case WM_MOUSEWHEEL:
			ListBox* this = bitcast(refData, ListBox*);
			this.mouseWheelHandler(msg, wp, lp);

		case WM_KEYDOWN:
			ListBox* this = bitcast(refData, ListBox*);
			this.keyDownHandler(wp);
		case WM_KEYUP:
			ListBox* this = bitcast(refData, ListBox*);
			this.keyUpHandler(wp);
		case WM_CHAR:
			ListBox* this = bitcast(refData, ListBox*);
			this.keyPressHandler(wp);
		case WM_CONTEXTMENU:
			ListBox* this = bitcast(refData, ListBox*);
			if (this.contextMenu) this.contextMenu.showMenu(lp);
		case MM_COLOR_LBOX:
			ListBox* this = bitcast(refData, ListBox*);
			return (Lresult) this.colorMsgHandler(wp);
		case MM_CTL_COMMAND :
			ListBox* this = bitcast(refData, ListBox*);
			this.wmCommandHandler(wp);
		default:
			return api_DefSubclassProc(hw, msg, wp, lp);
		// case MM_RUNDTOR: this.dtor(); return 0;
	}
	return api_DefSubclassProc(hw, msg, wp, lp);
}


