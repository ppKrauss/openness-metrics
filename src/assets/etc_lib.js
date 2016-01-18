/**
 * Global state control.
 * g_state.id is the $('#id') of any object. 
 * g_state.ini('id' or obj or jObj, state_value) iniciatizes the object with its state value.
 * g_state.chg('id' or obj or jObj) triggs the change of state, see swich code.
 * 
 */
var g_state = {
	_ID: 0
	,_OBJ: null
	,_checkObjId: function(obj) {
		if (obj === undefined) alert("BUG1")
		if (typeof obj === 'string' || obj instanceof String) { // and not at nonDomStates
			this._ID = obj;
			this._OBJ = document.getElementById(id);
		} else {
			this._OBJ = (obj instanceof jQuery)? obj[0]: obj;
			this._ID = this._OBJ.id;
		}
	}
	,ini: function(obj,newval,debug) {  //obj.hasOwnProperty(prop)
		this._checkObjId(obj);  // gets _ID
		this[this._ID] = newval;  // or this._OBJ.dataset.g_state = newval
		if (debug) this.show_states();
	}
	,chg_func: {}  // container of all id_func:function(){..}  
	,chg: function(obj,params) {
		// make change on obj. @obj is a DOM id or DOM object. @params is optional. 
		this._checkObjId(obj); // get _OBJ and _ID
		var oldval = this._OBJ.dataset.g_state;
		var newval = this.onChangeHub(this._ID,this._OBJ,params); // KERNEL, get changed value.
		if (newval===null)
			alert("g_state.chg ERROR 1\n case "+ this._ID +" not implemented at onChangeHub()");
		else
			this[this._ID] = newval;
		if ( !this.afterChangeHub(this._ID,this._OBJ,params) )   // KERNEL, trigg the change-dependences.
			alert("g_state.chg ERROR 2\n case "+ this._ID +" fail at afterChangeHub()");
		if (params=='debug') this.show_states();
		return (newval!=oldval); // flag a change
	}
	,show_states: function() { // debug
		alert("DEBUG g_state states\n v="+ this.degvers +"\n"+ this.lang0 +"\nex="+ this.exemp);
	}
	//g_state,ini
	// ini(obj or id) e chg(obj or id,val) 
	// o ideal é armazenar em data-dom o valor padronizado. O estado pode ser uma string ou um json.
};

/// UTIL LIB 


function keyVal_toString(lst) {
	var s=[];
	for(var i in lst)
 		s.push(i+'='+lst[i])
	return s.join();
}


