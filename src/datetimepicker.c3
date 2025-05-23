// datetimepicker module - Created on 09-Feb-2023 01:30

/*================================DateTimePicker Docs==================
	Constructor - newDateTimePicker()	: DateTimePicker*
	Properties:
		All Control struct properties are inherited
		value				: DateTimeInfo
		format				: DTPFormat (See enums.c3)
		formatStr			: String
		rightAlign			: bool
		fourDigitYear		: bool
		showWeekNum			: bool
		noTodayCircle		: bool
		noToday				: bool
		noTraillDates		: bool
		shortDateNames		: bool
		showUpdown			: bool
	Methods
		createHandle()		: Create DTP's handle
	Events
		All public events inherited from Control struct. (See controls.c3)
		onTextChanged		: DateTimeEventHandler (fn void(Control*, DateTimeEventArgs*))
		onCalendarOpened	: EventHandler
		onValueChanged		: EventHandler
		onCalendarClosed	: EventHandler
======================================================================================== */
module cforms;


int dtpNumber = 1;
Wstring dtpClass = {'S', 'y', 's', 'D', 'a', 't', 'e', 'T', 'i', 'm', 'e', 'P', 'i', 'c', 'k', '3', '2', 0};


// DateTimePicker control struct
struct DateTimePicker
{
	inline Control control;
	DateTimeInfo value;
	DTPFormat format;
	String formatStr;
	bool rightAlign;
	bool fourDigitYear;
	bool showWeekNum ;
	bool noTodayCircle ;
	bool noToday ;
	bool noTraillDates ;
	bool shortDateNames ;
	bool showUpdown ;
	Dword _calStyle ;
	int _ddCount;

	DateTimeEventHandler onTextChanged;
	EventHandler onCalendarOpened;
	EventHandler onValueChanged;
	EventHandler onCalendarClosed;
}

enum DTPFormat : int(String descrption, int value )
{
	LONG_DATE = {"Long Date format", 1},
	SHORT_DATE = {"Short Date Format", 2},
	TIME_ONLY = {"Only show Time", 4},
	CUSTOM = {"User Defined Format", 8}
}



// Public functions
	// DateTimePicker constructor
	fn DateTimePicker* newDateTimePicker(Form* parent, int x = 10, int y = 10)
	{
		DateTimePicker* this = allocator::new(mem, DateTimePicker);
		this.kind = ControlType.DATE_TIME_PICKER;
		this.name = dstring::new(mem, "DateTimePicker_");
		this.name.appendf("%d", dtpNumber);
		this._className = &dtpClass[0];
		this._parent = parent;
		this._style = WS_VISIBLE | WS_CHILD | WS_TABSTOP;
		this._exStyle = 0;
		this.xpos = x;
		this.ypos = y;
		this.width = 0;
		this.height = 0;
		this.format = DTPFormat.CUSTOM;
		this.formatStr = " dd-MM-yyyy";
		this.backColor = newColor(0xffffff);
		this.foreColor = newColor(0x000000);
		dtpNumber += 1;
		this.font.cloneFrom(parent.font);
		this._parent.controls.push(this);
		if (parent.createChilds) this.createHandle();
		return this;
	}

	// Create the handle of DateTimePicker
	fn void DateTimePicker.createHandle(DateTimePicker* this)
	{
		this.seDTPStyle();
		this.createInternal();
		if (this.handle) {
			this.setSubClass(&dtpWndProc);
			this.setFontInternal();
			this.postCreationTasks();
		}
	}

// End of Public functions

// Private functions

	// Setting control's style bits.
	fn void DateTimePicker.seDTPStyle(DateTimePicker* this) @private
	{
		switch (this.format) {
			case DTPFormat.CUSTOM: this._style |= DTS_LONGDATEFORMAT | DTS_APPCANPARSE;
			case DTPFormat.LONG_DATE: this._style |= DTS_LONGDATEFORMAT;
			case DTPFormat.SHORT_DATE: this._style |= this.fourDigitYear ? DTS_SHORTDATECENTURYFORMAT : DTS_SHORTDATEFORMAT;
			case DTPFormat.TIME_ONLY: this._style |= DTS_TIMEFORMAT;
		}
		if (this.showWeekNum) this._calStyle |= MCS_WEEKNUMBERS;
		if (this.noTodayCircle) this._calStyle |= MCS_NOTODAYCIRCLE;
		if (this.noToday) this._calStyle |= MCS_NOTODAY;
		if (this.noTraillDates) this._calStyle |= MCS_NOTRAILINGDATES;
		if (this.shortDateNames) this._calStyle |= MCS_SHORTDAYSOFWEEK;

		if (this.rightAlign) this._style |= DTS_RIGHTALIGN;
		if (this.showUpdown) this._style ^=  DTS_UPDOWN;

		this._bkBrush = this.backColor.getBrush();
	}

	fn void DateTimePicker.postCreationTasks(DateTimePicker* this) @private
	{
		if (this.format == DTPFormat.CUSTOM) {
			/*  Here, we have a strange situation. Since, we are working with unicode string, we need...
				to use the W version functions & messages. So, here DTM_SETFORMATW is the candidate.
				But it won't work. For some unknown reason, only DTM_SETFORMATA is working here. So we need...
				to pass a null terminated c string ptr to this function. Why MS, why ?
			*/
			this.sendMsg(DTM_SETFORMATA, 0, this.formatStr.ptr);
		}
		if (this._calStyle > 0 ) this.sendMsg(DTM_SETMCSTYLE, 0, this._calStyle);
		Size ss;
		this.sendMsg(DTM_GETIDEALSIZE, 0, &ss);
		this.width = ss.cx + 2;
		this.height = ss.cy + 5;
		api_SetWindowPos(this.handle, null, this.xpos, this.ypos, this.width, this.height, SWP_NOZORDER);
	}

	fn void DateTimePicker.wmNotifyHandler(DateTimePicker* this, Lparam lpm) @private
	{
		NMHdr* nm = (NMHdr*)lpm;
		switch (nm.code) {
			case DTN_USERSTRING:
				if (this.onTextChanged) {
					NMDateTimeString* dts = (NMDateTimeString*)lpm;
					DateTimeEventArgs dtea = newDateTimeEventArgs(dts.pszUserString);
					this.onTextChanged(this, &dtea);
					if (dtea.handled) this.sendMsg(DTM_SETSYSTEMTIME, 0, &dtea.dateStruct);
				}
			case DTN_DROPDOWN: if (this.onCalendarOpened) this.onCalendarOpened(this, &gea);
			case DTN_DATETIMECHANGE:
				if (this._ddCount == 0) {
					this._ddCount = 1;
					NMDateTimeChange* nmd = (NMDateTimeChange*) lpm;
					this.value = dateTimeFromSysTime(nmd.st);
					if (this.onValueChanged) this.onValueChanged(this, &gea);

				} else if (this._ddCount == 1) {
					this._ddCount = 0;
				}
			case DTN_CLOSEUP: if (this.onCalendarClosed) this.onCalendarClosed(this, &gea);
		}
	}

	// Freeing resources used for this DateTimePicker.
	fn void DateTimePicker.dtor(DateTimePicker* this) @private
	{
		this.baseDestroy();
		allocator::free(mem, this);
	}
// End of Private functions


fn Lresult dtpWndProc(Hwnd hw, uint msg, Wparam wp, Lparam lp, Uintptr scID, Dwordptr refData) @private
{
	
	// io::printfn("message %s", msg);
	switch (msg) {
		case WM_DESTROY:
			DateTimePicker* this = bitcast(refData, DateTimePicker*);
			api_RemoveWindowSubclass(hw, &dtpWndProc, scID);
			this.dtor();
		case WM_LBUTTONDOWN:
			DateTimePicker* this = bitcast(refData, DateTimePicker*);
			this.leftMouseDownHandler(msg, wp, lp);
		case WM_LBUTTONUP:
			DateTimePicker* this = bitcast(refData, DateTimePicker*);
			this.leftMouseUpHandler(msg, wp, lp);
		case MM_MOUSE_LBCLICK:
			DateTimePicker* this = bitcast(refData, DateTimePicker*);
			this.leftClickHandler();

		case WM_RBUTTONDOWN:
			DateTimePicker* this = bitcast(refData, DateTimePicker*);
			this.rightMouseDownHandler(msg, wp, lp);
		case WM_RBUTTONUP:
			DateTimePicker* this = bitcast(refData, DateTimePicker*);
			this.rightMouseUpHandler(msg, wp, lp);
		case MM_MOUSE_RBCLICK:
			DateTimePicker* this = bitcast(refData, DateTimePicker*);
			this.rightClickHandler();

		case WM_MOUSEMOVE:
			DateTimePicker* this = bitcast(refData, DateTimePicker*);
			this.mouseMoveHandler(msg, wp, lp);
		case WM_MOUSELEAVE:
			DateTimePicker* this = bitcast(refData, DateTimePicker*);
			this.mouseLeaveHandler();
		case WM_MOUSEWHEEL:
			DateTimePicker* this = bitcast(refData, DateTimePicker*);
			this.mouseWheelHandler(msg, wp, lp);
		case WM_CONTEXTMENU:
			DateTimePicker* this = bitcast(refData, DateTimePicker*);
			if (this.contextMenu) this.contextMenu.showMenu(lp);
		case WM_KEYDOWN:
			DateTimePicker* this = bitcast(refData, DateTimePicker*);
			this.keyDownHandler(wp);
		case WM_KEYUP:
			DateTimePicker* this = bitcast(refData, DateTimePicker*);
			this.keyUpHandler(wp);
		case WM_CHAR:
			DateTimePicker* this = bitcast(refData, DateTimePicker*);
			this.keyPressHandler(wp);

		default:
			return api_DefSubclassProc(hw, msg, wp, lp);

		// case MM_COLOR_LBOX: return (Lresult) this.colorMsgHandler(wp);

		// case MM_CTL_COMMAND : this.wmCommandHandler(wp);

		// case MM_RUNDTOR: this.dtor(); return 0;
	}
	return api_DefSubclassProc(hw, msg, wp, lp);
}






fn DateTimeInfo dateTimeFromSysTime(SystemTime st) {
	DateTimeInfo this;
	this.year = st.wYear ;
	this.month = st.wMonth ;
	this.day = st.wDay ;
	this.hour = st.wHour ;
	this.minute = st.wMinute ;
	this.second = st.wSecond ;
	this.milliSeconds = st.wMilliseconds ;
	this.dayOfWeek = WeekDays.from_ordinal(st.wDayOfWeek);
	return this;
}