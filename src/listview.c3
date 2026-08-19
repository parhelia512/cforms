// listview module - Created on 14-Feb-2023 01:13

/*=========================================ListView Docs==========================================
	Constructor	- newListView()	: ListView*
	Properties:
		All public properties inherited from Control struct. (See controls.c3)
		selectedIndex		: int
		headerHeight		: int
		selectedItem		: string
		editLabel			: bool
		hideSelection		: bool
		multiSelection		: bool
		hasCheckBox			: bool
		fullRowSelect		: bool
		showGrid			: bool
		oneClickActivate	: bool
		hotTrackSelection	: bool	
		noHeader			: bool
		headerClickable		: bool
		checkBoxLast		: bool
		viewStyle			: ViewStyle enum
		headerBackColor		: Color
		headerForeColor		: Color
		headerFont			: Font
		columns				: List<ListViewColumns*>
		items				: List<ListViewItem*>

	Methods:
		createHandle
		addColumn
		addColumns
		addItem
		addRow
		addItems
		addSubItems
	Events:
		All public events inherited from Control struct. (See controls.c3)
		EventHandler type events - fn void(Control*, EventArgs*)		

================================================================================================*/

module cforms;
// import std::io;
import std::collections::list;

int lvNumber = 1;
Wstring lvClass = {'S', 'y', 's', 'L', 'i', 's', 't', 'V', 'i', 'e', 'w', '3', '2', 0};

const LVSTYLE = WS_BORDER | WS_CHILD | WS_VISIBLE | LVS_ALIGNLEFT | LVS_EDITLABELS;
alias ColumnList = List{ListViewColumn*};
alias ItemList = List{ListViewItem*};


// ListView control struct
struct ListView
{
	inline Control control;
	int selectedIndex;
	int _colIndexCounter;
	int _itemIndexCounter;
	int _layoutCount; // To count the number of times HDM_LAYOUT message handled
	int headerHeight;
	Dwordptr _hotHdrIndex;
	Hwnd _hdrHwnd;
	ListViewItem* selectedItem;
	bool editLabel;
	bool hideSelection;
	bool multiSelection;
	bool hasCheckBox;
	bool fullRowSelect;
	bool showGrid;
	bool oneClickActivate;
	bool hotTrackSelection;
	bool noHeader;
	bool headerClickable;
	bool checkBoxLast;
	ListViewStyle viewStyle;
	Color headerBackColor;
	Color headerForeColor;
	Font headerFont;
	ColumnList columns;
	ItemList items;
	ItemList selectedItems;
	Hbrush _hdrHotBrush;
	Hbrush _hdrBkBrush;

	LVItemEventHandler onItemClick;
	LVItemEventHandler onItemDoubleClick;
	LVSelChangeEventHandler onSelectionChanged;
	LVItemCheckEventHandler onItemCheckChanged;
	EventHandler onItemActivate;
}

struct ColAndIndex {int index; LVColumn lvc;}
struct NameAndWidth {String name; int width;}

struct ListViewItem
{
	String text;
	Color backColor;
	Color foreColor;
	int imageIndex;
	int index;
	int _subItemCount;
	Font font;
	bool checked;
	bool _bgdraw;
	bool _fgdraw;
	List{ListViewSubItem*} subItems;
}

struct ListViewSubItem 
{
	String text;
	int index;
}

struct ListViewColumn
{
	bool _drawNeeded;
	bool _isHotItem;
	bool imgOnRight;
	bool hasImage;
	Alignment textAlign;
	Alignment hdrTextAlign;
	Color backColor;
	Color foreColor;
	String text;
	int width;
	int index;
	int imgIndex;
	int _order;
	Dword _hdrTxtFlag;
	Char16* _wideText;
	LVColumn* lvc;
}


// Public functions
	// ListView constructor - Create and returns a New ListView struct
	fn ListView* newListView(Control* parent, int x = 10, int y = 10,
								int width = 300, int height = 200)
	{
		ListView* this = alloc::new(mem, ListView);
		this.kind = ControlType.LIST_VIEW;
		this.initBase(parent, x, y, width, height, &lvNumber);	
		this.headerFont = this.font;
		this.viewStyle = ListViewStyle.REPORT_VIEW;
		this.showGrid = true;
		this.fullRowSelect = true;
		this.hideSelection = true;
		this.oneClickActivate = true;
		this.headerClickable = true;
		this._itemIndexCounter = -1;
		this._hotHdrIndex = -1;
		this.headerHeight = 25;
		this.headerBackColor = newColor(0xb3cccc);
		this.headerForeColor = newColor(0x000000);
		this._createHandleFunc = &_lvCreateHandle;
		this.columns.init(mem, 5);
		return this;
	}

	// ListViewCoulmn constructor.
	fn ListViewColumn* newListViewColumn(String txt, int width = 100,
										int imageIndex = -1, Allocator using = mem)
	{
		ListViewColumn* this = mem::new(ListViewColumn);
		this.text = txt;
		this.width = width;
		this.imgIndex = imageIndex;
		this.imgOnRight = false;
		this.textAlign = Alignment.LEFT;
		// this.index = -1;
		this.hdrTextAlign = Alignment.CENTER;
		this._wideText = String.to_utf16(txt, mem)!!;
		this._hdrTxtFlag = DT_SINGLELINE | DT_VCENTER | DT_CENTER | DT_NOPREFIX;
		return this;
	}

	// ListViewItem constructor
	fn ListViewItem* newListViewItem(String txt, uint bgColor = 0xFFFFFF,
									uint fgColor = 0x000000, int imgIndex = -1,
										Allocator using = mem)
	{
		ListViewItem* this = mem::new(ListViewItem);
		this.text = txt;
		this.backColor = newColor(bgColor);
		this.foreColor = newColor(fgColor);
		this.index = -1;
		this.imageIndex = imgIndex;
		if (bgColor != 0xFFFFFF) this._bgdraw = true;
		if (fgColor != 0x000000) this._fgdraw = true;
		return this;
	}

	fn ListViewSubItem* newListViewSubItem(String txt)
	{
		ListViewSubItem* this = mem::new(ListViewSubItem);
		this.text = txt;
		
		return this;
	}

	macro void ListViewItem.setBackColor(&this, any clr) 
	{
		switch (clr.type) {
			case Color: 
				this.backColor = (Color*)clr;	
			case int:  
				this.backColor = newColor(*(int*)clr);
		}
		this._bgdraw = true;
	}

	macro void ListViewItem.setForeColor(&this, any clr) 
	{
		switch (clr.type) {
			case Color: 
				this.foreColor = (Color*)clr;	
			case int:  
				this.foreColor = newColor(*(int*)clr);
		}
		this._fgdraw = true;
	}

	// // Another ListViewItem constructor, but appends subitems too. Works for only REPORT_VIEW style.
	// fn ListViewItem* newListViewRow(String txt, String... subitems)
	// {
	// 	ListViewItem* item = newListViewItem(txt);
	// 	foreach (sitem: subitems) {
	// 		ListViewSubItem* psi = item._createSubItem(sitem);
	// 		item.subItems.push(psi);	
	// 	}
	// 	return item;
	// }

	// Create the handle of ListView
	fn void _lvCreateHandle(Control* ctl) // @private
	{
		ListView* this = (ListView*)ctl;
		if (this.handle) return;
		this.setLVStyle();
		this._createInternal(this.width, this.height);
		if (this.handle) {
			this.setLVExStyle();
			this.setSubClass(&lvWndProc);
			this._setHeaderSubclass();
			this._postCreationTasks();
			if (this.columns.len()) {
				foreach(col: this.columns) {this._addColumnInternal(col);}
			}

			if (this.items.len()) {
				foreach(item: this.items) {this._addItemInternal(item);}
			}
		}
	}

	/* Add a column to listview. There are two overloads for this.
	 * 1. textOrCol = Name of the column. In this case, you can use width & imgIndx.
	 * 2. textOrCol = ListViewColumn*. In this case, width & imgIndex are irrelevent. 
	 */
	macro void ListView.addColumn(ListView* this, textOrCol, width = 100, imgIndx = -1)
	{
		ListViewColumn* pLvc = null;
		$switch $Typeof(textOrCol):
			$case String: 
				pLvc = newListViewColumn(textOrCol, width, imgIndx);
			$case ListViewColumn*: 
				pLvc = textOrCol;
			$default: $error "No overload for type";
		$endswitch
		if (pLvc) this._tryAddColumn(pLvc);
	}

	/* Adding columns to listview. There are two overloads for this.
	 * 1. lv.addColumns(ListViewColumn*...) // A collection of ListViewColumn pointers
	 * 2. lv.addColumns(String...) // A String collection for column text.
	 */
	macro void ListView.addColumns(ListView* this, params...) => @pool()
	{
		any p1 = params[0]; // This may be the column count or a ListViewColumn pointer		
		switch (p1.type) {
		case String:				
			foreach ( item : params) {
				ListViewColumn* pLvc = newListViewColumn(*((String*)item), 100, -1);
				this._tryAddColumn(pLvc);
			}			
		case ListViewColumn*:
			foreach(vp: params) {
				ListViewColumn* pLvc = *(ListViewColumn**)vp.ptr;
				this._tryAddColumn(pLvc);
			}		
		default:
			print("Unknown type");
		}
	}

	/* Add columns with widths. 
	 * colnames = An array of column names
	 * widths = An array of widths.
	*/
	fn void ListView.addColumnsEx(ListView* this, String[] colnames, int[] widths) 
	{
		if (colnames.len == widths.len) {
			foreach (i, name : colnames) {
				ListViewColumn* pLvc = newListViewColumn(name, widths[i]);
				this._tryAddColumn(pLvc);
			}
		}
	}

	/* Add Item to ListView. There are two overloads for this.
	 * 1. textOrItemPtr = String - The text for listview item. Macro returns the ListViewItem*
	 * 2. textOrItemPtr = ListViewItem* 
	 */
	macro void ListView.addItem(ListView* this, textOrItemPtr)
	{
		ListViewItem* pitem = null;
		$switch $Typeof(textOrItemPtr):
			$case String: 
				pitem = newListViewItem(textOrItemPtr);
			$case ListViewItem*: 
				pitem = textOrItemPtr;
			$default: 
				$error "No overload for type";		
		$endswitch
		this._tryAddItem(pitem);
	}

	/* Adds an item and it's subitems too. Works only in Report view */
	fn void ListView.addRow(&this, String itemtxt, String... subitems)
	{
		ListViewItem* lvitem = newListViewItem(itemtxt);
		this._itemIndexCounter += 1;
		lvitem.index = this._itemIndexCounter;
		foreach (sitem: subitems) {
			ListViewSubItem* psi = lvitem._createSubItem(sitem);
			lvitem.subItems.push(psi);	
		}
		this.items.push(lvitem);
		if (this.handle) this._addItemInternal(lvitem);
	}

	// Add new items to ListView,
	// txtOrItems can be: (1) String, (2) ListViewItem*
	macro void ListView.addItems(&this, txtOrItems...)
	{
		var $item1 = txtOrItems[0];
		$switch $Typeof($item1):
			$case String: 
				foreach(item: txtOrItems) {
					ListViewItem* pitem = newListViewItem(item);
					this._tryAddItem(pitem);
				}
			$case ListViewItem*: 
				foreach(pitem: txtOrItems) {
					this._tryAddItem(pitem);
				}
			$default: 
				$error "No overload for type";		
		$endswitch		
	}

	// Add  sub items to an item which is already in ListViewItem.
	// item can be a string or a ListViewItem ptr.
	macro void ListView.addSubItems(ListView* this, item, subitems...)
	{
		ListViewItem* plvi = null;
		$switch $Typeof(item): // First find the item if item is a string.
			$case String: 
				foreach(pitem: this.items) {
					if (pitem.text == item) {
						plvi = pitem;
						break;
					}
				}
			$case ListViewItem*: 
				plvi = item;
			$default: $error "No overload for type";
		$endswitch
		if (plvi) {
			foreach (subitem: subitems) {
				ListViewSubItem* psi = plvi._createSubItem(subitem);
				plvi.subItems.push(psi);
			}
			if (!this.handle) this._addSubItemsInternal(plvi);
		}		
	}

// End of Public functions

//========================================== Private functions==================================

	// Setting control's style bits.
	fn void ListView.setLVStyle(ListView* this) // @private
	{
		switch (this.viewStyle) {
            case ListViewStyle.LARGE_ICON: this._style |= LVS_ICON;
            case ListViewStyle.REPORT_VIEW: this._style |= LVS_REPORT;
            case ListViewStyle.SMALL_ICON: this._style |= LVS_SMALLICON;
            case ListViewStyle.LIST_VIEW: this._style |= LVS_LIST;
			default: break;
		}

        if (this.editLabel) this._style |= LVS_EDITLABELS;
        if (this.hideSelection) this._style ^= LVS_SHOWSELALWAYS;
        if (this.noHeader) this._style |= LVS_NOCOLUMNHEADER;
        if (this.multiSelection) this._style ^= LVS_SINGLESEL;

        // Set some brushes
        this._hdrBkBrush = api_CreateSolidBrush(this.headerBackColor.ref);
        this._hdrHotBrush = this.headerBackColor.getHotBrush(0.8);
	}

	// Setting ListView's Ex styles
	fn void ListView.setLVExStyle(ListView* this) // @private
	{
		Dword lvExStyle = 0x0000;
        if (this.showGrid) lvExStyle |= LVS_EX_GRIDLINES;
        if (this.hasCheckBox) lvExStyle |= LVS_EX_CHECKBOXES;
        if (this.fullRowSelect) lvExStyle |= LVS_EX_FULLROWSELECT;
        if (this.oneClickActivate) lvExStyle |= LVS_EX_ONECLICKACTIVATE;
        if (this.hotTrackSelection) lvExStyle |= LVS_EX_TRACKSELECT;
        // if (this.viewStyle == ListViewStyle.TILE_VIEW) this.sendMsg(LVM_SETVIEW, 0x0004, 0);
        this.sendMsg(LVM_SETEXTENDEDLISTVIEWSTYLE, 0 , lvExStyle);
	}

	fn void ListView._tryAddColumn(&this, ListViewColumn* pLvc) @inline // @private
	{
		pLvc.index = this._colIndexCounter;			
		this.columns.push(pLvc);
		if (!this.handle) this._addColumnInternal(pLvc);
		this._colIndexCounter += 1;
	}

	fn void ListView._tryAddItem(&this, ListViewItem* pitem) @inline // @private
	{
		this._itemIndexCounter += 1;
		pitem.index = this._itemIndexCounter;		
		this.items.push(pitem);
		if (this.handle) this._addItemInternal(pitem);
	}


	// Adding column to ListView.
	fn void ListView._addColumnInternal(ListView* this, ListViewColumn* lvcol) // @private
	{
		lvcol.index = this._colIndexCounter;
        LVColumn tagLVC;
        tagLVC.mask = LVCF_TEXT | LVCF_WIDTH | LVCF_FMT | LVCF_SUBITEM;
        tagLVC.fmt = (int)lvcol.textAlign.ordinal;
        tagLVC.cx = lvcol.width;
        tagLVC.pszText = lvcol._wideText;       

        if (lvcol.hasImage) {
            tagLVC.mask |= LVCF_IMAGE;
            tagLVC.fmt |= LVCFMT_COL_HAS_IMAGES | LVCFMT_IMAGE;
            tagLVC.iImage = lvcol.imgIndex;
            if (lvcol.imgOnRight) tagLVC.fmt |= LVCFMT_BITMAP_ON_RIGHT;
		}

		this.sendMsg(LVM_INSERTCOLUMNW, lvcol.index, &tagLVC); 
	}

	// Adding item to ListView.
	fn void ListView._addItemInternal(ListView* this, ListViewItem* pitem) // @private => @pool()
	{
		LVItem tagLVI = {};
        tagLVI.mask = LVIF_TEXT | LVIF_PARAM | LVIF_STATE;
        if (pitem.imageIndex != -1) tagLVI.mask |= LVIF_IMAGE;
        tagLVI.state = 0;
        tagLVI.stateMask = 0;
        tagLVI.iItem = pitem.index;
        tagLVI.iSubItem = 0;
        tagLVI.iImage = pitem.imageIndex;
        tagLVI.pszText = pitem.text.to_temp_utf16()!!.ptr;
        tagLVI.cchTextMax = 0; //pitem.text.len;
        tagLVI.lParam = bitcast(pitem, Lparam);
       	this.sendMsg(LVM_INSERTITEMW, 0, &tagLVI);
		if (pitem.subItems.len()) this._addSubItemsInternal(pitem);	
	}

	// Adding subitems to given pitem.
	fn void ListView._addSubItemInternal(ListView* this, 
										ListViewItem* pitem, 
										ListViewSubItem* subitem) // @private => @pool()
	{
        LVItem lvi;
		Char16* sitem = subitem.text.to_temp_utf16()!!.ptr;
        lvi.iSubItem = subitem.index;
        lvi.pszText = sitem;
        lvi.iImage = -1;
        this.sendMsg(LVM_SETITEMTEXTW, pitem.index, &lvi);		
	}

	fn void ListView._addSubItemsInternal(ListView* this, ListViewItem* pitem) // @private => @pool()
	{
		foreach (subitem: pitem.subItems) {
			LVItem lvi;
			Char16* sitem = subitem.text.to_temp_utf16()!!.ptr;
			lvi.iSubItem = subitem.index;
			lvi.pszText = sitem;
			lvi.iImage = -1;
			this.sendMsg(LVM_SETITEMTEXTW, pitem.index, &lvi);
		}        		
	}

	macro ListViewSubItem* ListViewItem._createSubItem(&this, sitem) // @private
	{
		if (this.subItems.size == 0) this.subItems.init(mem, 8);
		ListViewSubItem* psi = newListViewSubItem(sitem);	
		this._subItemCount += 1;
		psi.index = this._subItemCount;
		return psi;	
	}

	// Get the Header handle & subclass it.
	fn void ListView._setHeaderSubclass(ListView* this) // @private
	{
		this._hdrHwnd = (Hwnd) this.sendMsg(LVM_GETHEADER, 0, 0);
		api_SetWindowSubclass(this._hdrHwnd, &hdrWndProc, globalSubClsID, bitcast(this, Dwordptr));
		globalSubClsID += 1;
	}

	// Some post creation tasks for this listview.
	fn void ListView._postCreationTasks(ListView* this) // @private
	{
		if (this.backColor.value != 0xFFFFFF) this.sendMsg(LVM_SETBKCOLOR, 0, this.backColor.ref);
		if (this.checkBoxLast) {
			@pool() {
				IntList iList;
				iList.tinit(this.columns.len()); // Ensure we never need realloc
				foreach (col: this.columns) {if (col.index > 0) iList.push(col.index);}
				iList.push(0);
				this.sendMsg(LVM_SETCOLUMNORDERARRAY, iList.len(), &iList[0]);
			};
		}
	}

	// Drawing the header
	fn Lresult ListView._drawHeader(ListView* this, NMCustomDraw* nmcd) // @private
	{
		/* Drawing header to beautify with colors and font.
		 * Windows's own header drawing is white bkg color.
         * But listview itself is white bkg. We can't allow both hdr & listview in white.
         * So, we need to draw it on our own. */
        if (nmcd.dwItemSpec != 0) nmcd.rc.left += 1; // Give room for header divider.
        ListViewColumn* col = this.columns[(sz)nmcd.dwItemSpec]; // Get our column struct
        api_SetBkMode(nmcd.hdc, TRANSPARENT);

        if (nmcd.uItemState & CDIS_SELECTED) {
			api_FillRect(nmcd.hdc, &nmcd.rc, this._hdrBkBrush);
		} else {
            // We will draw with a different color if mouse is over this hdr.
            if (nmcd.dwItemSpec == this._hotHdrIndex) {
				api_FillRect(nmcd.hdc, &nmcd.rc, this._hdrHotBrush);
			} else {
				api_FillRect(nmcd.hdc, &nmcd.rc, this._hdrBkBrush);
			}
		}

        api_SelectObject(nmcd.hdc, (Hgdiobj)(this.headerFont.handle));
        api_SetTextColor(nmcd.hdc, this.headerForeColor.ref);
        if (this.headerClickable && (nmcd.uItemState & CDIS_SELECTED)) {
            /* We are mimicing the dotnet listview header's nature here.
             * They did not resize the overall header item. They just reduce...
             * it for drawing text. That means, text is drawing in a small rect.
             * Thus, viewer thinks like header is pressed a little bit. */
            nmcd.rc.left += 2;
            nmcd.rc.top += 2;
		}
        api_DrawText(nmcd.hdc, col._wideText, -1, &nmcd.rc, col._hdrTxtFlag);
		return CDRF_SKIPDEFAULT;
	}

	// Handling the WM_NOTIFY message from header
	fn Lresult ListView._headerNotifyHandler(ListView* this, Lparam lpm) // @private
	{
		NMHdr* nmh = (NMHdr*) lpm;
		if (nmh.code == NM_CUSTOMDRAW) {
			NMCustomDraw* nmcd = (NMCustomDraw*) lpm;
			switch (nmcd.dwDrawStage) {
				case CDDS_PREPAINT: return CDRF_NOTIFYITEMDRAW;
				case CDDS_ITEMPREPAINT: return this._drawHeader(nmcd);
			}
		}
		return CDRF_DODEFAULT;
	}

	// fn ListViewItem* ListView._findLvItemStr(&this, String itemTxt) // @private
	// {
	// 	if (this.items.len() > 0) {
	// 		foreach (item: this.items) {
	// 			if (item.text == itemTxt) return item;
	// 		}
	// 	}
	// 	return null;
	// }

	// fn ListViewItem* ListView._findLvItemInt(&this, int indx) // @private
	// {
	// 	if (this.items.len() > 0) {
	// 		foreach (item: this.items) {
	// 			if (item.index == indx) return item;
	// 		}
	// 	}
	// 	return null;
	// }

	// Helper function for the above macro
	// fn ListViewColumn* ListView._addColumnStr(ListView* this, String txt,
	// 										int width = 100, int imgIndx = -1) // @private
	// {
	// 	ListViewColumn* lvc = newListViewColumn(txt, width, imgIndx);
	// 	this._addColumnInternal(lvc);
	// 	return lvc;
	// }


	// Helper function for the above macro
	// fn void ListView.addColumnLvc(ListView* this, ListViewColumn* lvc) // @private
	// {
	// 	this._addColumnInternal(lvc);
	// }

	fn void ListView.removeFromSelItems(&this, ListViewItem* pitem)
	{
		foreach (i, item: this.selectedItems) {
			if (item.index == pitem.index) {
				this.selectedItems.remove_at(i);
				break;
			}
		}
	}

	fn Lresult ListView.wmNotifyHandler(&this, Lparam lpm)
	{
		NMHdr* nmh = (NMHdr*)lpm;
		switch (nmh.code) {
		case NM_CLICK: 
			nextcase;
		case NM_DBLCLK: 
			if ((this.onItemClick || this.onItemDoubleClick) && this.items.len()) {
				NMItemActivate* nmia = (NMItemActivate*)lpm;
				ListViewItem* pitem = this.items[nmia.iItem];				
				LVItemEventArgs lviea = {.item = pitem, .index = nmia.iItem};
				if (nmh.code == NM_CLICK && this.onItemClick) {
					this.onItemClick(this, &lviea);	
				} else if (nmh.code == NM_DBLCLK && this.onItemDoubleClick) {
					this.onItemDoubleClick(this, &lviea);
				}		
			}
		case LVN_ITEMCHANGED: 
			LVNMListView* nmlv = (LVNMListView*)lpm;
			if (nmlv.uChanged & LVIF_STATE) {
				uint nowSelected = (nmlv.uNewState & LVIS_SELECTED);
				uint wasSelected = (nmlv.uOldState & LVIS_SELECTED);
				if (nowSelected && !wasSelected) {
					ListViewItem* pitem = this.items[nmlv.iItem];
					if (this.multiSelection) {
						this.selectedItems.push(pitem);
					} else{
						this.selectedItem = pitem;
					}
					if (this.onSelectionChanged) {
						LVSelChangedEventArgs lsea = {.item = pitem, 
														.index = nmlv.iItem, 
														.isSelected = (bool)nowSelected};
						this.onSelectionChanged(this, &lsea);
					}
				} else if (!nowSelected & (wasSelected > 0)) {						
					ListViewItem* pitem = this.items[nmlv.iItem];
					if (this.multiSelection) {
						this.removeFromSelItems(pitem);                              
						if (this.onSelectionChanged) {
							LVSelChangedEventArgs lsea = {.item = pitem, 
															.index = nmlv.iItem, 
															.isSelected = (bool)nowSelected};
							this.onSelectionChanged(this, &lsea);
						}
					}
				}
			}
			int state_index = ((int)nmlv.uNewState & LVIS_STATEIMAGEMASK) >> 12;
			int old_state_index = (int)(nmlv.uOldState & LVIS_STATEIMAGEMASK) >> 12;
			if (state_index != old_state_index) { // Item checkbox changed 
				bool is_checked = (state_index == 2); // 2 = checked, 1 = unchecked
				if (this.items.len()) {                               
					ListViewItem* pitem = this.items[nmlv.iItem];
					pitem.checked = is_checked  ;
					if (this.onItemCheckChanged) {
						LVItemCheckEventArgs licea = {.item = pitem, 
														.index = nmlv.iItem, 
														.isChecked = is_checked};
						this.onItemCheckChanged(this, &licea);
					}
				}
			}

		case LVN_ITEMACTIVATE:
			if (this.onItemActivate) {
				this.onItemActivate(this, &gea);
			}

		case NM_CUSTOMDRAW:
			NMLVCustomDraw* lvcd = (NMLVCustomDraw*)lpm;
			if (lvcd.nmcd.dwDrawStage == CDDS_PREPAINT) {
				return CDRF_NOTIFYITEMDRAW;
			} 
			if (lvcd.nmcd.dwDrawStage == CDDS_ITEMPREPAINT) {
				ListViewItem* pitem = this.items[(sz)lvcd.nmcd.dwItemSpec];
				if (pitem._bgdraw) lvcd.clrTextBk = pitem.backColor.ref;
				if (pitem._fgdraw) lvcd.clrText = pitem.foreColor.ref;
				return CDRF_NEWFONT; // | CDRF_DODEFAULT;
			}
		}
		return CDRF_DODEFAULT;
	}

	// Destructor for ListViewColumn
	fn void ListViewColumn.destroy(&this) // @private
	{
		alloc::free(mem, this._wideText);
		mem::free(this);
	}

	// Destructor for ListViewItem
	fn void ListViewItem.destroy(&this) // @private
	{
		if (this.subItems.len()) {
			foreach(sitem: this.subItems) {free(sitem);}
		}
		this.subItems.free();
		free(this);
	}

	// fn void ListViewSubItem.destroy(&this) // @private
	// {
	// 	// ptf("is owned: %s", this._isOwnedText);
	// 	// if (this._isOwnedText) this.text.free(mem);
	// 	free(this);
	// 	// print("subitem freed");
	// }

	// Freeing resources used for this ListView.
	fn void ListView.dtor(ListView* this) // @private
	{
		if (this._itemIndexCounter > -1) {
			foreach (item: this.items) {item.destroy();}
		}
		if (this.columns.len()) {
			foreach (col: this.columns) {col.destroy();}
		}
		this.columns.free();
		this.items.free();
		this.selectedItems.free();
		this.baseDestroy();
		alloc::free(mem, this);
	}
// End of Private functions


fn Lresult lvWndProc(Hwnd hw, uint msg, Wparam wp, Lparam lp, Uintptr scID, Dwordptr refData) // @private
{
	ListView* this = bitcast(refData, ListView*);
	MsgHandlerResult res = this.baseWndProc(hw, msg, wp, lp);	
	if (res == MsgHandlerResult.CALL_DEF_PROC) {
		return api_DefSubclassProc(hw, msg, wp, lp);
	} else if (res == MsgHandlerResult.RET_IMMEDIATE) {
		return 1;
	}
	// io::printfn("message %s", msg);
	switch (msg) {
		case WM_DESTROY:
			api_RemoveWindowSubclass(hw, &lvWndProc, scID);
			this.dtor();		

		case WM_NOTIFY:
			return this._headerNotifyHandler(lp);

		case MM_NOTIFY_REFLECT:
			return this.wmNotifyHandler(lp);

		default:
			return api_DefSubclassProc(hw, msg, wp, lp);
	}
	return api_DefSubclassProc(hw, msg, wp, lp);
}

fn Lresult hdrWndProc(Hwnd hw, uint msg, Wparam wp, Lparam lp, Uintptr scID, Dwordptr refData) // @private
{	
	// io::printfn("message %s", msg);
	ListView* this = bitcast(refData, ListView*);
	switch (msg) {
		case WM_DESTROY: 			
			api_RemoveWindowSubclass(hw, &hdrWndProc, scID);

		case WM_MOUSEMOVE:
			Point mp = getMousePoints(lp);
			HDHitTestInfo hti; hti.pt = mp;
			this._hotHdrIndex = (Dwordptr) api_SendMessage(hw, HDM_HITTEST, 0, (Lparam) &hti);

		case WM_MOUSELEAVE: 
			this._hotHdrIndex = -1;

		case WM_PAINT: // Drawing the last part of header.
			api_DefSubclassProc(hw, msg, wp, lp);
			Rect hrc;
			api_SendMessage(hw, HDM_GETITEMRECT, (Wparam)this.columns.len() - 1, (Lparam)&hrc);
			Rect rc = {hrc.right + 1, hrc.top, this.width, hrc.bottom};
			Hdc hdc = api_GetDC(hw);
			defer api_ReleaseDC(hw, hdc);
			api_FillRect(hdc, &rc, this._hdrBkBrush);
			return 0;

		case HDM_LAYOUT:
			HdLayout* phl = (HdLayout*)lp;
			WindowPos* wps = phl.pwpos;
			wps.flags = SWP_FRAMECHANGED;
			wps.hwnd = hw;
			wps.y = 0;
			wps.x = phl.prc.left;
			wps.cx = phl.prc.right - phl.prc.left;
			wps.cy = this.headerHeight;
			phl.prc.top = this.headerHeight;
			return -1;

		default:
			return api_DefSubclassProc(hw, msg, wp, lp);
	}
	return api_DefSubclassProc(hw, msg, wp, lp);
}



