// treeview module - Created on 14-Feb-2023 01:13
/*================================TreeView Docs==================
	TreeView------------------------------------------------
		Constructor - newTreeView -> TreeView*
		Properties:
			All Control struct properties are inherited
			noLine				: bool
			noButton			: bool
			hasCheckBox			: bool
			fullRowSelection	: bool
			editable			: bool
			showSelection		: bool
			hotTrack			: bool
			lineColor			: Color
			selNode				: TreeNode*
			nodes				: List<TreeNode*>
			
		Methods:
			createHandle
			addNode
			addNodes
			addChildNode
			addChildNodes
			insertNode
			insertChildNode
			addNodeWithChilds
			deleteNode
			getNode
			
		Events:
			All public events inherited from Control struct. (See controls.c3)
			EventHandler type - fn void(Control*, EventArgs*);
	
	TreeeNode
		Constructor - newTreeNode -> TreeNode*
		Properties:
			handle			: Htreeitem
			parentNode		: TreeNode*
			nodes			: List<TreeNode*>
			imageIndex		: int
			selImageIndex	: int
			index			: int
			nodeID			: int
			foreColor		: Color
			backColor		: Color
			text			: String
			checked			: bool
			
		Methods:
			createHandle
			addChildNode
			insertChildNode
			
		Events:
			NodeNotifyHandler 
				notifyHandler
			
		
======================================================================================== */


module cforms;
// import std::io;
import std::collections::list;

alias TreeNodeList = List{TreeNode*};

// def NodeDisposeHandler = fn void(TreeNode* this);

int tvNumber = 1;
Wstring tvClass = {'S', 'y', 's', 'T', 'r', 'e', 'e', 'V', 'i', 'e', 'w', '3', '2', 0};
enum NodeOps : char {ADDNODE, INSERTNODE, ADDCHILD, INSERTCHILD}

// TreeView control struct
struct TreeView
{
	inline Control control;
	bool noLine;
	bool noButton;
	bool hasCheckBox;
	bool fullRowSelection;
	bool editable;
	bool showSelection;
	bool hotTrack;
	Color lineColor;
	TreeNode selNode;
	TreeNodeList nodes;
	int _nodeCount;
	int _uniqNodeID;
}

struct TreeNode
{
	Htreeitem handle;
	Htreeitem _insAfter;
	TreeView* _treePtr;
	TreeNode* parentNode;
	Hwnd _treeHwnd;
	TreeNodeList nodes;
	int imageIndex;
	int selImageIndex;
	int _childCount;
	int index;
	int nodeID;
	int _insPos;
	Color foreColor;
	Color backColor;
	String text;
	bool checked;
	bool _isCreated;
	bool _inList;
	// bool _hasOwnedText;
	bool _isRoot;
	NodeOps _nodeOp;

	NodeNotifyHandler _notifyHandler;
	// NodeDisposeHandler disposeHandler;
}

// fault TreeNodeError {TV_NOT_CREATED, NODE_NOT_CREATED}

// Public functions
	// TreeView constructor - Create and returns a New TreeView struct
	fn TreeView* newTreeView(Control* parent, int x = 10, int y = 10,
								int width = 200, int height = 200)
	{
		TreeView* this = allocator::new(mem, TreeView);
		this.kind = ControlType.TREE_VIEW;
		this.initBase(parent, x, y, width, height, &tvNumber);	
		this.lineColor = newColor(0x000000);
		this._uniqNodeID = 100;
		this.nodes.init(mem, 8);
		this._createHandleFunc = &_tvCreateHandle;
		return this;
	}

	fn TreeNode* newTreeNode(String txt, int image_index = -1, int sel_image_index = -1)
	{
		TreeNode* this = allocator::new(mem, TreeNode);
		this.text = txt;
		this.selImageIndex = -sel_image_index;
		this.imageIndex = image_index;
		this.index = -1;
		this._childCount = 0;
		this.imageIndex = -1;
		this.foreColor = newColor(0x000000);
		this.backColor = newColor(0xFFFFFF);
		this.nodes.init(mem, initial_capacity: 0);
		return this;
	}

	// Create the handle of TreeView
	fn void _tvCreateHandle(Control* ctl) @private
	{
		TreeView* this = (TreeView*)ctl;
		this.setTVStyle();
		this._createInternal(this.width, this.height);
		if (this.handle) {
			this.setSubClass(&tvWndProc);
			if (this.backColor.value != 0xFFFFFF) this.sendMsg(TVM_SETBKCOLOR, 0, this.backColor.ref);
            if (this.foreColor.value != 0x000000) this.sendMsg(TVM_SETTEXTCOLOR, 0, this.foreColor.ref);
            if (this.lineColor.value != 0x000000) this.sendMsg(TVM_SETLINECOLOR, 0, this.lineColor.ref);
			if (this.nodes.len()) {
				foreach(tn: this.nodes) {this._insertAllNodes(tn);}
			}
		}
	}

	<*
	 * Add a node to tree view. There are two overloads for this macro.
	 * 1. nodeOrText = TreeNode pointer. In this case, imgIndex & selImgIndex are irrelevent.
	 * 2. nodeOrText = A string. This macro will create a new TreeNode pointer from that.
	 * 3. nodeOrText = Any thing that can be converted to a string.
	 *>
	macro TreeView.addNode(TreeView* this, nodeOrText, imgIndex = -1, selImgIndex = -1)
	{
		TreeNode* node = makeNewNode(nodeOrText, imgIndex, selImgIndex);
		if (node) this._tryAddNode(node);
	}

	<*
	 * Add more than one node to tree view. There are two overloads for this macro.
	 * 1. params = A collection of TreeNode pointers
	 * 2. params = A collection of Strings or anything that can be converted to string.
	 *>
	macro void TreeView.addNodes(TreeView* this, params...)
	{
		foreach (item: params) { 
			TreeNode* node = makeNewNode(item, -1, -1);
			if (node) this._tryAddNode(node);
		}
	}


	macro void TreeView.addChildNode(TreeView* this, TreeNode* parent, nodeOrText)
	{
		TreeNode* node = makeNewNode(nodeOrText, -1, -1);
		this._tryAddChildNode(parent, node);
	}

	
	macro void TreeView.addChildNodes(TreeView* this, TreeNode* parent, childs...)
	{
		foreach (item: childs) {
			TreeNode* node = makeNewNode(item, -1, -1);
			this._tryAddChildNode(parent, node);
		}
	}

	macro TreeNode* TreeView.insertNode(TreeView* this, nodeOrText, indexNum)
	{
		if (indexNum < 0 || indexNum >= this.nodes.len()) return;
		TreeNode* node = makeNewNode(nodeOrText, -1, -1);
		node._insPos = indexNum;
		node.index = this._nodeCount;
		node._nodeOp = NodeOps.INSERTNODE;
		node._insAfter = indexNum == 0? TVI_FIRST : this.nodes[index - 1].handle;
		node._isRoot = true;
		node._treePtr = this;
		this._nodeCount += 1;
		this.nodes.push(node);
		node._inList = true;
		if (this.handle) this.addNodeInternal(node);

		
	}

	macro void TreeView.insertChildNode(TreeView* this, TreeNode* parent, nodeOrText,
													indexNum, Allocator using = mem)
	{
		if (indexNum < 0 || indexNum >= this.nodes.len()) return;
		if (parent.nodes.size == 0) parent.nodes.init(mem, 4);
		TreeNode* node = makeNewNode(nodeOrText, -1, -1);
		node._insPos = indexNum;
		node.index = parent._childCount;
		node._nodeOp = NodeOps.INSERTCHILD;
		node._insAfter = indexNum == 0? TVI_FIRST : this.nodes[(usz)indexNum - 1].handle;
		node._treePtr = this;
		parent._childCount += 1;
		parent.nodes.push(node);
		node._inList = true;
		if (this.handle) this.addNodeInternal(node, parent);		
	}

	fn void TreeView.addNodeWithChilds(&this, String... items)
	{
		TreeNode* pnode = makeNewNode(items[0], -1, -1);
		pnode.nodes.init(mem, items.len - 1);
		this._tryAddNode(pnode);
		for (int i = 1; i < items.len; i++) {
			TreeNode* cnode = makeNewNode(items[i], -1, -1);
			cnode._nodeOp = NodeOps.ADDCHILD;
			cnode._insAfter = TVI_LAST;
			cnode.index = pnode._childCount;
			pnode._childCount += 1;
			pnode.nodes.push(cnode);
			cnode._inList = true;		 
			if (this.handle) this.addNodeInternal(cnode, pnode);
		}
	}

	// Delete a node. Parameter textOrIndex can be String or int.
	macro void TreeView.deleteNode(TreeView* this, textOrIndex)
	{
		deleteNodeFromStringOrInt(this, textOrIndex);
	}

	// Get a node by giving the text or index.
	macro TreeNode* TreeView.getNode(TreeView* this, txtOrIndex)
	{
		return getNodeFromStringOrInt(this, txtOrIndex);
	}

	//===========================Private Functions=============================================
	// fn TreeNode* TreeView.addNode1(TreeView* this, String txt, int img, int selImg) @private
	// {
	// 	TreeNode* node = newTreeNode(txt, img, selImg);
	// 	this.addNodeInternal(NodeOps.ADDNODE, node);
	// 	return node;
	// }

	macro TreeNode* makeNewNode(nodeOrText, imgIndex, selImgIndex) @private
	{
		TreeNode* node = null;
		$switch $typeof(nodeOrText):
			$case String: 
				node = newTreeNode(nodeOrText, imgIndex, selImgIndex);				
			$case TreeNode*:
				node = nodeOrText;
			$default: 
				$error "makeNewNode: No overload for this type";
		$endswitch
		return node;
	}

	fn void TreeView._tryAddNode(&this, TreeNode* node) @private
	{
		node._nodeOp = NodeOps.ADDNODE;
		node._insAfter = TVI_LAST;
		node.index = this._nodeCount;
		node._isRoot = true;
		node._treePtr = this;
		this._nodeCount += 1;
		this.nodes.push(node);
		node._inList = true;
		if (this.handle) this.addNodeInternal(node);
	}

	fn void TreeView._tryAddChildNode(&this, TreeNode* parent, TreeNode* child) @private
	{
		if (!parent._inList) {
			// We don't allow new nodes here.
			ptf("Error: %s node is not added already!", parent.text);
			return;
		} 
		if (parent.nodes.size == 0) parent.nodes.init(mem, 8);
		child._nodeOp = NodeOps.ADDCHILD;
		child._insAfter = TVI_LAST;
		child.index = parent._childCount;
		parent._childCount += 1;
		parent.nodes.push(child);
		child._inList = true;		 
		if (this.handle) this.addNodeInternal(child, parent);		
	}

	fn void TreeView._insertAllNodes(&this, TreeNode* node, TreeNode* pnode = null) 
	{
		this.addNodeInternal(node, pnode);	
		if (node.nodes.len()) {
			foreach(tn: node.nodes) {this._insertAllNodes(tn, node);}
		}
	}
	

	fn void TreeView.addNode2(TreeView* this, TreeNode* node) @private
	{
		// this.addNodeInternal(NodeOps.ADDNODE, node);
	}


	<*
	 * @require this._isCreated
	 *>
	fn void TreeView.addChildNode2(TreeView* this, TreeNode* node, TreeNode* parent) @private
	{
		// this.addNodeInternal(NodeOps.ADDCHILD, node, parent);
	}

	fn void TreeView.addChildNodes1(TreeView* this, TreeNode* parent, nodeTexts...) @private
	{
		// foreach (txt: nodeTexts) {
		// 	String* nodeTxt = (String*)txt;
		// 	TreeNode* node = newTreeNode(*nodeTxt);
		// 	this.addNodeInternal(NodeOps.ADDCHILD, node, parent);
		// }
	}

	fn void TreeView.addChildNodes2(TreeView* this, TreeNode* parent, TreeNode*... nodes) @private
	{
		// foreach (node: nodes) this.addNodeInternal(NodeOps.ADDCHILD, node, parent);
	}

	fn TreeNode* TreeView.insertNode1(TreeView* this, String nodeTxt, int index, 
										Allocator using = mem) @private
	{
		// TreeNode* node = newTreeNode(nodeTxt);
		// this.addNodeInternal(NodeOps.INSERTNODE, node, pos: index);
		return null;
	}

	fn void TreeView.insertNode2(TreeView* this, TreeNode* node, int index) @private
	{
		// this.addNodeInternal(NodeOps.INSERTNODE, node, pos: index);
	}

	fn TreeNode* TreeView.insertChildNode1(TreeView* this, String nodeTxt, TreeNode* parent,
												int index, Allocator using = mem) @private
	{
		// TreeNode* tn = newTreeNode(nodeTxt);
		// this.addNodeInternal(NodeOps.INSERTCHILD, tn, parent, index);
		return null;
	}

	fn void TreeView.insertChildNode2(TreeView* this, TreeNode* node, TreeNode* parent, int index) @private
	{
		// this.addNodeInternal(NodeOps.INSERTCHILD, node, parent, index);
	}

		// This macro can be used by both TreeView & TreeNode.
	macro TreeNode* getNodeFromStringOrInt(parent, txtOrIndex) @private
	{
		$switch $typeof(txtOrIndex):
			$case String:
				if (parent.nodes.len() > 0) {
					foreach (node: parent.nodes) {if (node.text == txtOrIndex) return node;}
				}
			$case int:
				if (parent.nodes.len() > 0) {
					foreach (node: parent.nodes) {if (node.index == txtOrIndex) return node;}
				}
			$default: return null;
		$endswitch
		return null;
	}

	// This macro can be used by both TreeView & TreeNode.
	macro void deleteNodeFromStringOrInt(parent, txtOrIndex) @private
	{
		TreeNode* theNode;
		$switch $typeof(txtOrIndex):
			$case String:
				if (parent.nodes.len() > 0) {
					foreach (node: parent.nodes) {
						if (node.text == txtOrIndex) {
							theNode = node;
							break;
						}
					}
				}
			$case int:
				if (parent.nodes.len() > 0) {
					foreach (node: parent.nodes) {
						if (node.index == txtOrIndex) {
							theNode = node;
							break;
						}
					}
				}
			$default: print("Unknown type");
		$endswitch
		if (theNode) {
			$switch $typeof(parent):
				$case TreeView*:
					api_SendMessage(parent.handle, TVM_DELETEITEM, 0, (Lparam) theNode.handle);
					parent.nodes.remove(theNode);
					theNode.destroy();
				$case TreeNode*:
					api_SendMessage(parent._treeHwnd, MM_NODE_DELETED, 0, theNode.toWpm());
			$endswitch
		} else {
			print("The node is null");
		}
	}

	//======================================TREENODE FUNCTIONS============================================================
		// Private use
		struct NodePack
		{
			TreeNode* parent;
			TreeNode* node;
			int indexNum;
		}

		fn Wparam TreeNode.toWpm(TreeNode* this) @private {return (Wparam)((void*) this);}
		fn Lparam TreeNode.toLpm(TreeNode* this) @private {return (Lparam)((void*) this);}

		// Helper function for adding a child node
		fn TreeNode* TreeNode.addChildNode1(TreeNode* this, String nodeTxt, Allocator using = mem) @private
		{
			TreeNode* node = newTreeNode(nodeTxt);
			api_SendMessage(this._treeHwnd, MM_NODE_ADDED, node.toWpm(), this.toLpm());
			return node;
		}

		// Helper function for adding a child node
		fn void TreeNode.addChildNode2(TreeNode* this, TreeNode* node) @private
		{
			api_SendMessage(this._treeHwnd, MM_NODE_ADDED, node.toWpm(), this.toLpm());
		}

		// Add child node node. Parameter nodeOrText can be string or node pointer.
		macro TreeNode* TreeNode.addChildNode(TreeNode* this, nodeOrText, Allocator using = mem)
		{
			$switch $typeof(nodeOrText):
				$case String: return this.addChildNode1(nodeOrText, using);
				$case TreeNode*:
					this.addChildNode2(nodeOrText);
					return null;
				$default: $error "No overload for type";
			$endswitch
		}

		// Insert child node node. Parameter nodeOrText can be string or node pointer.
		macro TreeNode* TreeNode.insertChildNode(TreeNode* this, nodeOrText, indexNum, Allocator using = mem)
		{
			TreeNode* ret;
			NodePack np;
			$switch $typeof(nodeOrText):
				$case String:
					np.node = newTreeNode(nodeOrText);
					ret = np.node;
				$case TreeNode*:
					np.node = nodeOrText;
					ret = null;
				$default: $error "No overload for type";
			$endswitch
			np.parent = this;
			np.indexNum = indexNum;
			api_SendMessage(this._treeHwnd, MM_NODE_INSERTED, 0, (Lparam)((void*) &np));
			return ret;
		}

		// Returns a child node node. Parameter nodeOrText can be string or node pointer.
		macro TreeNode* TreeNode.getNode(TreeNode* this, txtOrIndex)
		{
			return getNodeFromStringOrInt(this, txtOrIndex);
		}

		// Delete a node. Parameter textOrIndex can be String or int.
		macro void TreeNode.deleteNode(TreeNode* this, textOrIndex)
		{
			deleteNodeFromStringOrInt(this, textOrIndex);
		}
	// End of TreeNode functions

// End of Public functions

// Private functions

	// Setting control's style bits.
	fn void TreeView.setTVStyle(TreeView* this) @private
	{
		if (this.noLine) this._style ^= TVS_HASLINES;
		if (this.noButton) this._style ^= TVS_HASBUTTONS;
		if (this.hasCheckBox) this._style |= TVS_CHECKBOXES;
		if (this.fullRowSelection) this._style |= TVS_FULLROWSELECT;
		if (this.editable) this._style |= TVS_EDITLABELS;
		if (this.showSelection) this._style |= TVS_SHOWSELALWAYS;
		if (this.hotTrack) this._style |= TVS_TRACKSELECT;
		if (this.noButton && this.noLine) this._style ^= TVS_LINESATROOT;
	}

	/**
	 * required this._isCreated
	**/
	fn void TreeView.addNodeInternal(TreeView* this, TreeNode* node, 
										TreeNode* pnode = null) @private => @pool()
	{
		node._isCreated = true;
		node._treeHwnd = this.handle;
		node.nodeID = this._uniqNodeID; // We can identify any node with this
		node._treePtr = this;

		TVItemEx tvi;
		tvi.mask = TVIF_TEXT | TVIF_PARAM;
		tvi.pszText = node.text.to_temp_utf16()!!.ptr;

		tvi.cchTextMax = node.text.len;
		tvi.iImage = node.imageIndex;
		tvi.iSelectedImage = node.selImageIndex;
		tvi.stateMask = TVIS_USERMASK;
		if (node.imageIndex > -1) tvi.mask |= TVIF_IMAGE;
		if (node.selImageIndex > -1) tvi.mask |= TVIF_SELECTEDIMAGE;

		//-------------------------
		TVInsertStruct tis;
		tis.itemex = tvi;
		tis.itemex.lParam = (Lparam)((void*) node);
		tis.hInsertAfter = node._insAfter;
		bool isRootNode = false;
		String errMsg = "Can't Add";

		switch(node._nodeOp) {
		case NodeOps.ADDNODE:
			tis.hParent = TVI_ROOT;

		case NodeOps.INSERTNODE:
			tis.hParent = TVI_ROOT;
			errMsg = "Can't Insert";

		case NodeOps.ADDCHILD:
			tis.hParent = pnode.handle;
			node.parentNode = pnode;
			errMsg = "Can't Add Child";

		case NodeOps.INSERTCHILD:
			tis.hParent = pnode.handle;
			node.parentNode = pnode;
			errMsg = "Can't Insert Child";
		}

		Lresult hItem = this.sendMsg(TVM_INSERTITEMW, 0, &tis);
		if (hItem) {
			node.handle = (Htreeitem)hItem;
			this._uniqNodeID += 1;
		} else {
			ptf("%s node!, Error - %d", errMsg, api_GetLastError());
		}
	}


	fn void TreeView.nodeNotifyHandler(TreeView* this, TreeNode* node, String prop, void* data) @private
	{
		print("not implemented");
	}

	fn void TreeNode.destroy(TreeNode* this) @private
	{
		// ptf("Node is destroying, node text %s, node count : %s", this.text, this._childCount);
		if (this._childCount) {foreach (node: this.nodes) { node.destroy();}} // Recursive destruction
		if (this.nodes.capacity > 0) {
			// ptf("nodes list freed %s", this.text);
			this.nodes.free(); // Finally free the container too.
		}
		allocator::free(mem, this);
	}


	// Freeing resources used for this TreeView.
	fn void TreeView.dtor(TreeView* this) @private
	{
		if (this._nodeCount > 0) {
			foreach (node: this.nodes) { node.destroy();} // Recursive destruction
		}
		if (this.nodes.capacity > 0) this.nodes.free();
		this.baseDestroy();
		allocator::free(mem, this);
	}
// End of Private functions


fn Lresult tvWndProc(Hwnd hw, uint msg, Wparam wp, Lparam lp, Uintptr scID, Dwordptr refData) @private
{
	// io::printfn("message %s", msg);
	TreeView* this = bitcast(refData, TreeView*);
	MsgHandlerResult res = this.baseWndProc(hw, msg, wp, lp);	
	if (res == MsgHandlerResult.CALL_DEF_PROC) {
		return api_DefSubclassProc(hw, msg, wp, lp);
	} else if (res == MsgHandlerResult.RET_IMMEDIATE) {
		return 1;
	}
	switch (msg) {
		case WM_DESTROY:			
			api_RemoveWindowSubclass(hw, &tvWndProc, scID);
			this.dtor();

		case MM_NODE_ADDED:
			TreeNode* node = (TreeNode*)((void*) wp);
			TreeNode* pnode = (TreeNode*)((void*) lp);
			this.addChildNode(pnode, node);

		case MM_NODE_INSERTED:
			NodePack* np = (NodePack*)((void*) lp);
			this.insertChildNode(np.parent, np.node, np.indexNum);

		case MM_NODE_DELETED:
			TreeNode* node = (TreeNode*)((void*) lp);
			Lresult ret = this.sendMsg(TVM_DELETEITEM, 0, (Lparam) node.handle);
			this.nodes.remove_first_item(node);
			node.destroy();		

		default:
			return api_DefSubclassProc(hw, msg, wp, lp);
	}
	return api_DefSubclassProc(hw, msg, wp, lp);
}



