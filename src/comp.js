/*

note: registers 251+ are reserved
251 is sometimes a temp register for object code
252 for require code

*/

var scanf = require('scanf');

var fs = require('fs');

var peg = require("pegjs");

let pass = function() {}

let print2 = console.log

let print = console.log
//print = pass

let log = '', lvl = 0

let _ = pass, step = false, args2 = undefined



let assert = function(a, b) {
	if(a)
		0;
	else
		throw b;
}

function s_ref() {
	return 'rel#'+this.name
}

function circular(e) {
	if(e.type=='ref' && unbound(e)) { //e.value===e
		//print('=', e)
		return '#var'+e.i
	}
	else
		return e.toString()
}

function str(e) {
	return e&&(e.toString())||'"null"'
}

function undef(a) {
	return (typeof a)==='undefined'
}

function def(a) {
	return !undef(a)
}

function is(o, s) {
	return o.constructor.name == s
}

function set_type(o, s) {
	o.constructor.name = s
}

function type(o) {
	return o.constructor.name
}

function is_rel(o) {
	return type(o)=='Value'&&undef(o.type)
}

function array(o) {
	return '['+o.toString()+']'
}

let code = {
	pass : 0,
	allocate : 1,
	deallocate : 2,

	proceed : 9,
	call_one : 10,
	call : 11,
	try_else : 12,
	retry_else : 13,
	trust_else_fail : 14,
	call_once : 15,
	halt : 16,

	put_const : 17,
	put_functor : 18,
	put_table : 19,
	get_const : 20,
	get_table : 21,
	
	closure : 22,
	move : 23,
	call_c : 24,

	put_value_loc : 25,
	put_variable_loc : 26,

	get_int_loc : 27,
	get_const_loc : 28,
	get_value_loc : 29,
	get_variable_loc : 30,

	get_functor : 31,
	fc_int : 32,
	fc_const : 33,
	fc_value : 34,
	fc_var_loc : 35,

	t_var : 36,
	t_const : 37,
	t_value : 38,
	t_variable : 39,

	obj_get : 40,
	obj_pred : 41,

	call_reg : 42,
	call_once_reg : 43,

	fail: 44,
	cont: 45,
	jmp: 46,
	jmp2: 47,
	a: 48,
	a2: 49,
	
	eq: 51,
	eq_val: 52,
	obj_get_loc: 53,
	obj_put_loc: 54,
	get_obj: 55,
	
	put_void: 56,
	get_void: 57,
	fc_void: 58,
	
	print : 99,
}

//

class Proto {
	constructor(e) {
		return e
	}
}

class Env {
	constructor(e, prev) {
		assert(type(e) == 'Proto', 'not prototype value')
		this.proto=e
		this.locals=new Array(e.n_locs) //locals is the only attribute that is part of the env
		this.upvals=e.upvals
		this.name=e.name
		//closure(this, c1)
		return this
	}
	toString() {
		return 'rel#'+this.name//+'{'+this.proto.insts.length+'}'
	}
}

//
function stringfy2(l,n) {
	if(l.n==0)
		return ''
	//print(l.param[0])//, l.param[1])
	let tk=l.param[0].param[0].value
	print(tk)
	if(tk=='EOF')
		return ''
	else if(tk=='::'||tk=='.') {
		return tk+stringfy2(l.param[1],1)
	}
	else if(def(n)) {
		return tk+stringfy2(l.param[1])
	}
	return ' '+tk+stringfy2(l.param[1])
}

function clistfy(l) {
	print(0,l)
	if(l.length==0)
		return cons0
	else {
		let f=new Functor(cons, 2)
		f.param[0] = def1(l[0])
		f.param[1] = clistfy(l.slice(1))
		//print(';;',str(f), str(l[0]))
		return f
	}
	throw 'clistfy';
	return l1
}

function def1(l, c) {
	print('-',l, typeof(l),c)
	if(typeof(l)=='number')
		return new Value('int', l)
	else if(typeof(l)=='string') {
		return new Value('str', l)
	}
	/*else if(def1(l.name) && l.name=='id'){
		//print(new Value('id', l[0]))
		//return new Value('id', l[0])
		let x=new Value('ref', null)
		x.name = l[0]
		return x
	}*/
	else if(!def(l)) {
		print(l)
		//throw 0;
		return 'null';
	}
	else if(is(l,'Array')) {
		//print('s',str(clistfy(l)))
		return clistfy(l)
	}
	else if(def(l.name)) {
		print(l.name, l.param, c)
		let name=l.name
		if(name=='True'||name=='False')
			return new Functor(set_str(name))
		else if(name=='Num'||name=='Str') { //1
			//let a=def1(l.value)
			print(l)
			let s=name=='Str'&&'str'||'int'
			return set_f1(l.name, new Value(s,l.param[0]))
		}
		else if(name=='TList') { //1
			//let a=def1(l.value)
			print(l)
			return set_fall(l.name, 1, l.param.map(function(x,i){ return def1(x)}))
		}
		else if(name!='ObjPred'&&name!='Op'&&l.param.length==3) { //Rel //3
			let f=set_fall(l.name, 3, l.param.map(function(x,i){print(';;',x,i); return def1(x)}))
			//f.param[1] = clistfy(l.param[1])
			//print(2,f.param[2],str(f.param[2]))
			print(str(f))
			return f
		}/*
		else if(!is(l,'Functor')) {
			throw 12;
			return l
		}*/
		//let a=def1(l.param[0]), b=def1(l.param[1], l), f=set_f(l.name, a, b)
		let f=set_fall(l.name, 2, l.param.map(function(x,i){ return def1(x)}))
		if(name=='Eq'||name=='Pred'||name=='Func') {
			f.n=3
			f.param[2] = _info//any()
			if(name=='Pred'&&f.param[0].value=='functor')
				f.name = set_str('Fact')
			else if(name=='Func'&&f.param[0].value=='functor')
				f.name = set_str('Fact')
		}
		else if(name=='ObjPred'||name=='Op') {
			f.n=4
			f.param[3] = _info//any()
			//throw 2;
		}
		else if(name=='Id') {
			f.param[1] = new Functor(new Value('str', 'Cons'), 0)
		}
		else if(name=='Cond') {
			//f.param[1] = new Functor(new Value('str', 'Cons'), 0)
			print(f.n)
		}
		return f
	}
	else
		return l
}


s = fs.readFileSync('parser.peg', 'utf8')

parser = peg.generate(s)

//print(parser.parse('asd or "2" or sda'))

var p=function(s) {
	print(';',s,typeof(s))
	let s1=parser.parse(s)
	print(';',s1)
	let f=def1(s1)
	//throw 2;
	return f
}

/*
It's all passed to registers before an external c:function (js:function?) is called.
It can be safely assumed they have been deferenced.
It's also up to the writer to see that functions that can receive a ref unbound deal with them,
if a function receives bound values only for some arguments this is to be set in other parts of the language so you can treat them as bound here.
If the ref is unbound you can use the function 'set' to set it, if it's guaranteed to be so.
*/

const v8 = require('v8');

let fn = {
	'print' : function() {
		print(regs[0])
		//print(regs[0].constructor.name)
		print2('\n==')
		print2(regs[0].toString(),'\n==\n')
	},
	'full_print' : function() {
		//print(regs[0])
		print2('\n-')
		print2(regs[0].toString(0, undefined, 1),'\n-\n')
	},
	'throw' : function() {
		throw(regs[0])
	},
	'toString' : function() {
		set(regs[1], 'str', regs[0].value.toString())
	},
	'export' : function() {
		regs[252] = regs[0]
	},
	ws : function() {
		print('#', str(regs[0]), typeof regs[0])
		o=regs[0]
		o2=regs[1]
		unify(o2, ws(o))
		//throw 21;
	},
	lexer : function() {
		//print('#', str(regs[0]), typeof regs[0])
		o=regs[0]
		o2=regs[1]
		let l=lexer(o.value)
		print(str_full(l))
		unify(o2, l)
	},
	parser : function() {
		//print('#', str(regs[0]), typeof regs[0])
		o=regs[0]
		o2=regs[1]
		//let l=p('true and x=2')
		let l=p(o.value)//p('rel p() true and x=2;')
		print(str(l))
		//throw 1;
		unify(o2, l)
	},
	parser2 : function() {
		//print('#', str(regs[0]), typeof regs[0])
		o=regs[0]
		//let l=p('true and x=2')
		//s='if(true) true else x=1;'
		//s='a.p ( 2, 1 )'
		s=' a.p ( \'a\', 2, 1 )'
		s=" string.at ( 'a' , 0 , c )"
		//s='string.at ( 1 , 0 , c )'
		let l=p(s) //p('/*c::p() and*/ a="asd" and x/* */=2')
		print('l',str(l))
		//throw 1;
		//unify(o, l)
	},
	token : function () {
		o = regs[0]; o2 = regs[1]; o3 = regs[2];
		print(o2,o2.value)
		var s=stringfy2(o2)
		//print(o.value)
		print(';',s, o2.value)
		try{
			fs.writeFileSync(o3.value, s, 'utf8')
			/*fs.open(o2.value+'2', 'r+', (err, fd) => {
			  if (err) {
				throw err;
			  }

			  fs.write(fd, s);
			});*/
			print('written to '+o3.value)
			//throw 23;

		}	catch(e) {
			print(e)
			throw e//"file not found";
		}
		unify(o3, new Value('str', o.value+'2'))
	},
	arg : function() {
		let args = process.argv
		if(args[3]==undefined)
			throw 2;
		set(regs[0], 'str', args[3])
		//pause()
	},
	lsize : function() {
		o = regs[0]; o2 = regs[1]; o3 = regs[2];
		let i=0
		while(o.n!=0) {
			o=deref(o.param[1])
			//print('-',o)
			i+=1
		}
		//pause()
		print(o,i)
		unify(regs[1], new Value('int',i))
	},
	add : function() {
		print(regs[0], regs[1], regs[2], is(regs[1], 'Functor'))
		//assert(regs[1].type=='int')
		/*
		if(regs[0].type=='ref') {
			o3=regs[0]
			regs[0]=regs[1]
			regs[1]=o3
		}*/
		if(regs[0].type=='int')
			set(regs[2], 'int', regs[0].value+regs[1].value)
		else if(is(regs[1], 'Functor')) {
			print(regs[1].toString())
			set(regs[2], regs[0].type, regs[0].value+(regs[1].toString())) //regs[0].value+(regs[1].value) //regs[0].value.concat(regs[1].value)
			//throw 2;
		}
		else {
			print(regs[0].value, regs[1].value)
			set(regs[2], regs[0].type, regs[0].value.concat(regs[1].value)) //regs[0].value+(regs[1].value) //regs[0].value.concat(regs[1].value)
		}
	},
	coll : pass,
	ge : function() {
		print(regs[0],'>=',regs[1])
		if(regs[0]<regs[1])
			return false
	},
	sub : function() {
		set(regs[2], 'int', regs[0].value-regs[1].value)
	},
	//bitwise
	bit_and : function() {
		print('--')
		set(regs[2], regs[0].type, regs[0].value & regs[1].value)
		print(regs[2].value, regs[0].value, regs[1].value)
		//throw 3
	},
	bit_shr : function() {
		print('--')
		set(regs[2], regs[0].type, regs[0].value >> regs[1].value)
		print(regs[2].value, regs[0].value, regs[1].value)
		//throw 3
		//step = true
	},
	concat : function() {
		//print(regs[0].value);	print(regs[0].value.concat)
		set(regs[2], regs[0].type, regs[0].value.concat(regs[1].value))
		print(regs[2])
		//throw 3
	},
	random : function() {
		let r=Math.random()
		set(regs[0], 'int', r)
	},
	table_new : function () {
		regs[0].value = new Value('table', {})
		print(regs[0], regs[0].value, type(regs[0].value))
	},
	table_get : function () {
		o = regs[0]; o2 = regs[1]; o3 = regs[2];
		regs[2] = o.value[o2.value]
		//print(regs[2])
	},
	table_set : function () {
		let o = regs[0], o2 = regs[1], o3 = regs[2];
		print('set',str(o) +'['+str(o2)+'] = '+ str(o3))
		//print(o)
		if(!undef(o.value[o2.value])) throw 31;
		let t = o.value, s = o2.value
		//print(mapstr(t), s)
		//print(0,type(t), type(o))
		t[s] = o3
		//print('=',str(o))
		//print(regs[3], t)
		set(regs[3], 'table', t) //new Table(
		if(regs[3].value==null) throw 23;
		//print(regs[3], t)
	},
	neg : function() {
		print(regs[0].value,'!=',regs[1].value, regs[0], regs[1])
		let o = regs[0], o2 = regs[1]
		if(undef(regs[0].value)) { //is composite
			let value=unify(o, o2)
			print(';',value)
			return !value
		}
		else if(regs[0].value===regs[1].value)
			return false
	},
	stringToNumber : function() {
		set(regs[1], 'int', Number.parseInt(regs[0].value))
	},
	//string
	s_le : function() {
		print(regs[0],'<',regs[1])
		if(regs[0]>regs[1])
			return false
	},
	size : function() {
		print('#',str(regs[0]), typeof regs[0])
		o=regs[1]
		return unify(o, new Value('int', regs[0].value.length))
	},
	at : function() {
		o=regs[2]
		var a=regs[0].value[regs[1].value]
		//print(cp_list.length)
		if(undef(a))
			return false;
		set(o, 'str', a)
		//print(regs[0], a.charCodeAt(0), '\n'.charCodeAt(0))
		print(str(regs[0]), str(regs[1]), str(o))//, o, o.value.value.length)
		log += str(o)+'\n'
		//print(';', str(regs[0]), regs[1].value, str(a))
	},
	code : function() {
		let o=regs[0], o2 = regs[1]
		return set_ref(regs[1], 'int', regs[0].value.codePointAt(0))
	},
	slice : function() {
		let s = regs[0].value.slice(regs[1].value, regs[2].value)
		print('#',str(regs[0]), typeof regs[0], s)
		print(regs[2].value)
		assert(regs[2].value!==regs[2],'a')
		unify(o, new Value('str', s))
	},
	findIndex : function() {
		//find s2 in s1, starting from index i
		//rel findIndex(String s1, String s2, Integer i, Integer pos)
		//print('#',str(regs[0]), typeof regs[0])
		o=regs[0].value.indexOf(regs[1].value, regs[2].value)
		if(o==-1)
			return false
		else
			set(regs[3], 'int', o)
	},
	label : function () {
		e.label = i
	},
	goto : function () {
		i = e.label//regs[0].value
	},
	mut : function () {
		let o = locals[regs[0].value], o2 = regs[1]
		print('=',str(o))
		locals[regs[0].value] = o2
		//throw 23;
	},
	inc : function () {
		let o = regs[0], o2 = regs[1]
		o.value = o.value+1
	},
	set : function () {
		let o = regs[0], o2 = regs[1]
		o.value = o2.value
	},
	rec : function () {
		i=0//e.proto.locals.length*3
		print('== rec ==', e.proto.locals, i)
		//print(e)
		//throw 3;
		/*let j2=regs[0].value
		print(j2,'--')
		for(let j=0;j<j2;j++) {
			print(j,str(regs[j]), '<-', str(locals[j]))
			regs[j] = deref(locals[j])
		}*/
	},
	require : function () {
		let i0=i
		let e0=e
		let o2=regs[1]
		print('load',e0.name, regs[0], 'prev', typeof e0.prev, o2, i)
		e = new Env(load(regs[0].value))
		e.cur = [0,0]
		print('require',regs[0],e.name)
		//print(e.consts)
		//unpack(e0);	e=e0; i=i0;	print('back', e.name); unify(o2,regs[252])
		//e.prev=[e0, i0]
		print(trail.length, array(trail))
		e.temp=[[e0, i0, trail], o2]
		i=0
		trail=[]
		//e=e0;	i=i0
		unpack(e)
		//print(e)
		print(bc.toString())
		//unify(regs[1], new Value('table',t))
		
		//print(e.name, bc[i], 'i'+i, 'i'+i0, array(insts), array(bc))
		//print(regs[2])
		//throw 3;
	},
	readFile : function () {
		o = regs[0];
		set(regs[1], 'str', fs.readFileSync(o.value, 'utf8'))
		print(o)
		//print(regs[3])
	},
	fopen_binary : function () {
		let f = regs[2], mode = regs[1].value;
		//set(regs[2], 'file', fs.readFileSync(regs[0].value))
		//f.bc1 = new Uint8Array()
		f.name = regs[0].value
		f.type = 'file'
		f.value = 1
		var b = new Buffer.alloc(0)
		assert(mode=='write',12)
		fs.writeFileSync(f.name, b,  "binary");
	},
	read : function () {
		o = regs[0];
		o = new Value('str', scanf('%S'))
		print(o)
		//print(regs[3])
	},
	pause : function () {
		scanf('%S')
	},
	def : function () {
		if(unbound(regs[0]))
			throw 12;
	},
	str : function () {
		if(regs[0].type!='str')
			throw 'not a string';
	},
	undef : function () {
		if(bound(regs[0]))
			throw 12;
	},
	type : function () {
		if(bound(regs[0]) && regs[0].type!=regs[1].value)
			throw 11;
	},
	write : function () {
		o = regs[0];
		//print(o.value)
		//print(regs[3])
	},
	write8 : function () {
		let f = regs[0], o = regs[1];
		print(f)
		//let bc1 = new Uint8Array(); bc1[0] = o.value
		var b = new Buffer.alloc(1)
		b[0] = o.value
		//print(bc1)
		fs.appendFileSync(f.name, b,  "binary");
		//f.write(o.value, regs[0])
		//f.write(o2)
		
	},
	write32 : function () {
		let f = regs[0], o = regs[1];
		print(f)
		//let bc1 = new Uint8Array(); bc1[0] = o.value
		let bc1 = new Uint32Array(); bc1[0] = o.value
		//var b = new Buffer.from(bc1)
		var b = new Buffer.alloc(4)
		print(o)
		b.writeInt32LE(o.value);
		print(b)
		//b[0] = 1
		fs.appendFileSync(f.name, b,  "binary");
		
	},
	cut : function () {
		//cp_list = []
		//trail = []
		//print('\n=='); print(e.cur,[trail.length, cp_list.length]); print(arraystr(trail)); print(chain_cp())
		trail = trail.slice(0,e.cur[0])
		cp_list = cp_list.slice(0,e.cur[1])
		//while(cp_list.length!=e.cur[1]) {	cp_list.pop() }
		//print('--'); print(arraystr(trail)); print(chain_cp()); print('==\n')
		//ch = scanf('%S')
	},
	'break' : function () {
		step = true
	},
	table_get : function () {
		step = true
	},
	'info' : function () {
		print(v8.getHeapStatistics())
		print(cp_list.length)
		//print(e)
	},
	/*,
	findIndex : function () {
		o = regs[0]; o2 = regs[1]; o3 = regs[2];
		print(str(o), str(o2), str(o3))
		o.value[o2] = o3
		regs[3].value = o
		//print(regs[3])
	},
	findIndex : function () {
		o = regs[0]; o2 = regs[1]; o3 = regs[2];
		print(str(o), str(o2), str(o3))
		o.value[o2] = o3
		regs[3].value = o
		//print(regs[3])
	}*/
}

fn.write = fn.print

function mapstr(t) {
	let s='{'
	let a=0
	for(let i in t) {
		if(a==0)
			s+=''
		else
			s+=', '
		//print(typeof i, type(i), i, t[i])
		if(i=='value') { 
			console.trace(); 
			throw 1;
		}
		//print(i, t[i])
		s+=i+'='+str(t[i])
		a+=1
	}
	s+='}'
	return s
}

function chain() {
	let s=''
	let a=0
	let o=e
	s+='('+o.name+' '+i
	s+=')'
	o=o.prev
	while(def(o)) {
		s+=' -> '
		if(a>=5) {
			s+='..'
			break
		}
		s+='('+o[0].name+' '+o[1]
		s+=')'
		a+=1
		o=o[0].prev
	}
	s+=''
	return s
}

function chain_cp() {
	let s=''
	let a=0
	let t=cp_list
	for(let i=t.length-1; i>=0; i--) {
		if(a>=5) {
			s+='..'
			break
		}
		if(a==0)
			s+=''
		else
			s+=' -> '
		var o=t[i]
		s+='('+o.e.name+' '+o.i+''
		s+=')'
		a+=1
	}
	s+=''
	return s
}

function arraystr(t) {
	let s='['
	let a=0
	for(let i=0; i<t.length; i+=1) {
		if(a==0)
			s+=''
		else
			s+=', '
		if(t[i]==null)
			s+=t[i]//'null'
		else
			s+='\''+i+'\''+':'+str(t[i])
		a+=1
	}
	s+=']'
	return s
}

function arraystr0(t, used, f) {
	let s=''
	let a=0
	for(let i=0; i<t.length; i+=1) {
		if(a==0)
			s+=''
		else
			s+=', '
		let x=t[i]
		if(t[i]===null)
			s+='null'//t[i]//'null'
		else if(t[i]===undefined)
			s+='null+'//t[i]//'null'
		else {
			if(is(x,'Array'))
				s+='js['+x+']'
			else
				s+=t[i].toString(0, used, f)
		}
		a+=1
	}
	s+=''
	return s
}

function arraystr1(t, used) {
	let s='['
	s+=arraystr0(t, used)
	s+=']'
	return s
}


var regs = []

for(j=0;j<255;++j) {
	regs.push(null);
}

function seta(o,t,v) {
	//o.type = t; o.value = v//return new Value('ref', null) //{type:'ref', value:null}
	o.value = new Value(t,v)
}

function set(o,t,v) {
	o.type = t; o.value = v//return new Value('ref', null) //{type:'ref', value:null}
	trail.push(o)
	//o.value = new Value(t,v)
}

function set_ref(o,t,v) {
	if(o.type!='ref') {
		print(o.value, v)
		return o.value===v
	}
	o.type = t; o.value = v//return new Value('ref', null) //{type:'ref', value:null}
	trail.push(o)
	return true
	//o.value = new Value(t,v)
}

/* writing to file */

function buf(a) {
	return Buffer.from(a,'binary')
}

function read_n(bc,start,n) { //read up to n then dropping end byte
	l=[]
	let j=0
	let i
	print(bc[start],bc[start+1])
	for(i=start;i<start+n-1;i+=1) {
		l[j] = bc[i]
		j+=1
	}
	return l
}

function int8(Number) {
    let B0 = Number & 255
	return Buffer.from([B0],'binary')
}

function int32(Number) {
    let B0 = Number & 255
    let B1 = (Number >> 8) & 255
    let B2 = (Number >> 16) & 255
    let B3 = (Number >> 24) & 255
	return [B0,B1,B2,B3]
}

function to_int32(l, i) {
	var Number = read_int32(l.slice(i,i+4)) //l[0] | (l[1] >> 8) | (l[2] >> 16) | (l[3] >> 24)
	//print('int',l[0],l[1],l[2],l[3])
	return Number //L[i]
}

function read_int32(L) {
	var Number = L[0] | (L[1] << 8) | (L[2] << 16) | (L[3] << 24)
	//print('int',L,Number)
	return Number
}

/*
function int32(Number) {
    let B0 = Number & 255
    let B1 = (Number >> 8) & 255
    let B2 = (Number >> 16) & 255
    let B3 = (Number >> 24) & 255
	return Buffer.from([B0,B1,B2,B3],'binary')
}
*/

//i must be set to 0
function read_fn(bc, data, i0) {
	//n = bc.slice(i, i+4)
	//n = data[i/4] //todo don't skip four bits
	let n = bc[i]
	let s=''
	s += 'rel { consts '+n//+' i:'+i
	i += 4
	let cs = []
	let env = {}
	for(let j=0;j<n;++j) {
		c=bc[i]
		s+=' ('+c+') '
		//print('-',c)
		i += 1
		if(c==0) {
			cs[j] = null
			print('c is 0')
			//throw 'c is 0'
		}
		else if(c==1) {
			cs[j] = null
		}
		else if(c==2) {
			c = read_int32(bc.slice(i, i+4)); i += 4
			cs[j] = new Value('int', c)
		}
		else if(c==3) {
			n1 = read_int32(bc.slice(i, i+4)); i += 4 //read size
			var l=read_n(bc, i, n1); i+=n1
			cs[j] = new Value('str', stringfy(l))
			s+=/*'string '+n1+ '['+l.toString()+'] '+*/i+','+n1+' ['+l+'] '+stringfy(l)+' "'+cs[j]+'" '//+bc.slice(i, i+4)
			//print('',s);
			//debugger;
		}
		else if(c==4) {
			//print(cs)
			//s+='rel:\n--'
			//print(bc[i],bc[i+1],bc[i+2],bc[i+3],bc[i+4])
			var env2 = read_fn(bc, data, 1)
			cs[j] = env2
			env.prev = env2
			s+=arraystr1(env2.consts)
			//print('--')
			//throw 2
		}
		else {
			print(c)
			throw 22;
		}
	}
	//print('['+cs.toString()+']')
	
	n = read_int32(bc.slice(i, i+4)); i += 4
	locs = []
	for(j=0;j<n;++j) {
		locs.push(null)
	}
	
	n = bc[i]; i += 1
	//s+=('locals', locs.length, 'upvals', n)
	upvals = []
	for(j=0;j<n;++j) {
		c = read_int32(bc.slice(i, i+4)); i += 4
		upvals.push(c)
	}
	
	//print(bc[i], bc[i+1], bc[i+2], bc[i+3])
	n = read_int32(bc.slice(i, i+4)); i += 4
	s+='insts: '+ n
	insts = []
	for(j=0;j<n;++j) {
		//print(bc[i])
		insts.push(bc[i]); i += 1
	}
	env = {insts : insts, locals : locs, n_locs : locs.length, upvals : upvals, consts : cs, toString : s_ref}
	//print(env.locals, env.upvals, env.consts)
	//print('['+insts.toString()+']')
	if(bc[i]==1) { //debug info
		i+=1
		d = {name:[]}
		//print(bc.slice(i,i+10))
		let size = read_int32(bc.slice(i, i+4)); i += 4
		for(j=0;j<size;++j) {
			d.name.push(bc[i]); i += 1
		}
		d.name = stringfy(d.name)
		d.n_args = read_int32(bc.slice(i, i+4)); i += 4
		env.name = d.name
		env.n_args = d.n_args
		s+=' (debug) '+d.name+'#'+d.n_args
		s1='serialize_string'
		//if(d.name.slice(0, s1.length)==s1) throw 1;
		//throw 1;
	}
	s+=' u:'+env.upvals.length
	s+=' c:'+env.consts.length
	s+=' y:'+env.locals.length
	s+=' l:'+env.insts.length
	s+=' }'
	print(s)
	//print(env.insts.length)
	//if(undef(i0)) print(env.insts)
	//print(arraystr(env.upvals))
	//print(bc[i-1],bc[i],bc[i+1],bc[i+2],bc[i+3],bc[i+4])
	env.constructor = Proto
	return env
}

let debug = {}

let o = {
	type : '',
	value : ''
}

ct2 = 0
class Value {
	constructor(type, value) {
		this.type = type
		this.value = value
		this.i = ct2
		ct2 += 1
	}
	toString(n, used, full) {
		//print(deref(this))
		let o = deref(this)
		//print(used.length)
		//print(o)
		if(o.type!='ref') {
			//if((typeof o=='object')) return o.name
			var s
			if(is(o, 'Functor')) {
				s = o.toString(n+1,used)
			}
			if(o.type=='str') {
				//print(o)
				if(o.value.length>50)
					//s = '"'+o.value.slice(0,10)+'.."'
					s = '"..."'//'#str'
				else {
					//print(o.type, o, o.value)
					s = "'"+o.value.replace(/\n/g,'\\n').replace(/\r/g,'\\r').replace(/\t/g,'\\t')/**/+"'"
				}
			}
			else if(typeof o=='string'||typeof o.value=='string') {
				print(o)
				throw 22;
				if(o.length>10)
					s = '"'+o.value.slice(0,10)+'.."'
				else
					s = '"'+o.value+'"'
			}
			else if(o.type=='table') {
				s = 't#'+mapstr(o.value)
			}
			else if(o.type=='int') {
				assert((typeof o.value)==='number',231)
				s = o.value.toString()
				//if(def(o.i)) s+=':'+o.i
			}
			else if(o.type=='file') {
				//assert((typeof o.value)==='number',231)
				s = '#file'
			}
			//print(o)
			if(!undef(s)) {
				if(this.type=='ref') {
					//print(this)
					if(undef(this.name))
						return '#var'+this.i+' = '+s
					else
						return this.name
				}
				else
					return s
			}
			if(undef(o.value)) return '?'
			return o.value.toString()
		}
		else {
			//print(2,o)
			if(o.value!==null) { //?
				//return '#var'+o.value.toString()
				throw 'no value';
			}
			return '#var'+this.i
		}
	}
}

function eq_key(x,y) {
	//print(x.name.i, y.name.i)
	return x.i==y.i
}

function eq_fc(x,y) {
	//print(x.name.i, y.name.i)
	return x.i==y.i
}

function id_s(x) {
	if(is(x,'Functor'))
		return x.i+(x.param.length>0&&';'+x.param[0].value||'#')
	else
		return x.i
}

class Functor {
	constructor(name, n, param) {
		this.param = []
		this.name = name||''
		this.n = n||0
		this.i = ct2
		ct2 += 1
	}
	eq(o2) {
		let o=this
		print(';', str(o), '=', str(o2), 'cmp')
		if(o.n!=o2.n||o.name.value!=o2.name.value)
			return false
		for(let j=0;j<o.n;j+=1) {
			//print('-',str(o.param[j]))
			if(!unify(deref(o.param[j]), deref(o2.param[j])))
				return false
		}
		//throw 2;
		return true	
	}
	toString(n, used, full) {
		let o=this, l=o.param
		//print('=',o.param, l[0])
		//print(o.name.value)
		//if(def(n)) return '...'
		if(undef(n))
			n=0
		if(undef(used))
			used=[]
		if(used.find(function(x) {return eq_fc(x,o)}) && n>=0) {
			//print(used, o)
			//print('rec')
			return "#rec"+o.name.i; //if this is already in the str, stop
		}
		used.push(o)
		//print(used, o.i, o.name.value)
		//print(o, n); print(used)
		if(o.name.value=='Cons') {
			let s='['//+arraystr0(this.param)/*
			while (o.type!='ref'&&o.param.length!=0) {
				let l=o.param, x=l[0]
				//print('-',x)
				s+=x.toString(n+1, used, full)
				o = deref(o.param[1])
				/*if((o.type=='ref'&&bound(o))) {
					print(this)
					print(o)
					throw 13
				}*/
				if(!is(o,'Functor')) {
					s+=' | '+str(o);
					break;
				}//throw 'incomplete list; not a functor'
				if(o.type!='ref'&&o.param.length!=0) s+=', '
				if(s.length>90&&undef(full)) { s+='...';	break; }
			}
			s+=']'
			let n1=90
			//if(s.length>n1)	return ''+s.slice(0,n1)+'...]'
			return s
		}
		else if(o.name.value=='T') {
			/*if(used.find(function(x) {return eq_fc(x,o)}) && n>=0) {
				//print(o)					print('rec')
				return 'T'
			}*/
			let s='{'
			//print(o.param)
			while (o.type!='ref'&&o.param.length!=0) { //end of dict may be undefined
				let l=o.param, x=l[0], y=l[1]
				o = o.param[2]
				if(undef(o)) return '?' //todo error?
				//print(used.map(id_s));
				//print(o.i, used.map(function(x) {return x.i}))
				if(used.find(function(x) {return eq_fc(x,o)}) && n>=0) {
					//print(o)					print('rec')
					s+= "#rec"+o.name.i; //if this is already in the str, stop
					break
				}
				used.push(o)
				//print(s)
				//print('-',n,x,is(y,'Functor')&&y.name.value, x.i, '#'+used.length); //print(o)
				//print(s.length)
				s+=x.toString(n+1, used, full)+': '
				//print(x.value,used.length)
				s+=y.toString(n+1, used, full)
				if(o.type!='ref'&&o.param.length!=0) s+=', '
				if(s.length>300&&undef(full)) { s+='...';	break; }
			}
			s+='}'
			return s
		}
		else {
			return this.name.value+'('+arraystr0(this.param, used, full)+')#'+this.n
		}
		/*
		s=''
		for (var x of this.param) {
			s+=x.toString()
			print(x)
		}
		*/
	}
}

consts = []

//

var sname = new Value('str', 'Token')
var cons = new Value('str', 'Cons'), sof = new Functor(sname, 3), semicolon = set_tk(';',';'), tand = new Functor(sname, 3)
sof.param[1] = 'SOF'
tand.param[0] = 'and'
tand.param[1] = 'connective'
var eof=set_tk('EOF','EOF')

function set_str(x) {
	let t = new Value('str', x)
	return t
}

function set_f1(sname,x) {
	let t = new Functor(set_str(sname), 1)
	t.param[0] = x
	return t
}

function set_f(sname,x,y) {
	let t = new Functor(set_str(sname), 2)
	t.param[0] = x
	t.param[1] = y
	return t
}

function set_fall(sname,n,x) {
	let t = new Functor(set_str(sname), n)
	t.param = x
	return t
}

_info = new Functor(set_str('Info'),0)

function set_tk(x,y) {
	let t = new Functor(sname, 3)
	t.param[0] = set_str(x)
	t.param[1] = set_str(y)
	t.param[2] = any()//_info
	return t
}

function set_list(l2,x) {
	l2.param[0] = x
	//l2.param[1] = cons
	//print(str(l2), str(x))
	l2.param[1] = new Functor(cons, 2)
	return l2.param[1]
}

//

s = fs.readFileSync('lexer.peg', 'utf8')

parser1 = peg.generate(s)

cons0 = new Functor(cons, 0)

function to_clist(l) {
	let i = 0, l2 = new Functor(cons, 2), l1=l2, t
	for(var x of l) {
		if(typeof(x)=='string') {
			t=set_tk(x,x)
		}
		else if(typeof(x)=='number') {
			t=set_tk(''+x, 'number')
		}
		else if(typeof(x)=='object') {
			if(x[1]=='comment')
				continue;
			t=set_tk(x[0],x[1])
		}
		else {
			//t=set_tk('str',x.toString())
			print(typeof(x),x)
			throw 21;
		}
		l2=set_list(l2,t)
	}
	t=set_tk('EOF','EOF')
	l2=set_list(l2,t)
	l2.n = 0
	print('----\nl',l1)
	print(str(l1))
	return l1
}

function lexer(s) {
	print(s)
	let s2=parser1.parse(s)
	print(s2)
	return to_clist(s2)
}

//ws

function is_ws(x) {
	return deref(x.param[1]).value=='whitespace'
}

function fold(l,fn,a) {
	let s = '', i = 0
	while(i<l.length) {
		a = fn(a, l[i])
		i = i+1
	}
	return a
}

function iterate(fn,n,l2) {
	/*if(n==0) {
		//print('c',str(x))
		return x
	}
	else {
		let l2=iterate(fn, n-1, fn(x))
		l2.name = cons
		print('c',str(l2),n)
		return l2
	}*/
	if(n==0)
		return l2
	//l2=l2.param[1]
	for(var i=0;i<n;++i) {
		print('cc',str(l2))
		//print(str(l2))
		push_semicolon(l2)//.param[1]
		l2=l2.param[1]
	}
	return l2
}

function iterate_(fn,n,x) {
	l2 = iterate(fn, n, l2).param[1]
	l2.name = cons
}

function format(s) {
	let s2 = '', i=0
	while(i<s.length) {
		let ch=s[i]
		if(ch=='\n')
			s2=s2+'\\n'
		else if(ch=='\t')
			s2=s2+'\\t'
		else
			s2=s2+ch
		i=i+1
	}
	print(s2)
	return s2
}

function remove_from_start(s,s2) {
	//remove s2 from s1, e.g. remove_from_start('zxc','z') = 'xc'
	//s3 = s2[#s2+s.find(s2) : #s]
	//print([s,s2])
	if(typeof s!='string')
		return -1
	let pos=s.indexOf(s2)
	if(pos<0)
		return pos
	//print(pos, s2.length)
	return s.slice(s2.length+pos, s.length)
}

function remove_prev_inds(s,ind) {
	//print(['remove',ind,'from',s])
	return fold(ind, remove_from_start, s)
}

function next(l2) {
	return l2.param[1]
}

function add(a,b) {
	return a+b
}

function remove_ind(ind, a) {
	let n=ind.length, s
	
	//for(var i=0;i<ind.length;++i) {
	while(true) {
		s = ind.reduce(add, '')
		if(s==a)
			break;
		ind.pop()
		n2+=1
		//l2=set_list(l2, set_tk(';', ';'))
		/*
		ind1=ind.pop()
		a=a.slice(-ind1.length) //remove ind from after_nl
		n2+=1
		if(a=='')
			break*/
	}
	return ind
	
}

function lastChar(s,n) {
	let i=s.length
	return l2.param[1]
}

function push_semicolon(l) {
	l.param[0] = semicolon
	l.param[1] = new Functor(cons, 2)
	return l
}

function str_full(s) {
	return s.toString(0, undefined, 1)
}

function ws(l) {
	//print(l)
	//print(x)
	cons=l.name
	var l2 = new Functor(l.name, l.n)
	var startl=l2, prevl=l
	var ct=0
	print('\nbegin',str(l2),l2.name)
	var ind=[], prev=sof
	while(is_ws(l.param[0])) { //ws at start
		l=l.param[1]
	}
	while (l.n==2) {
		x = l.param[0] //token
		print('\n-', str(x), ct)
		ct+=1
		//print(x)
		if(is_ws(x)) { //skip
			while(true) {
				x2 = l.param[1].param[0]
				if(x2.value=='EOF') {
					return ;
				}
				else if(is_ws(x2)) {
					l=l.param[1]
					x=x2
					print('\nx', str(x))
				}
				else
					break;
			}
			print('')
			//l2.param[0] = x
			//let next=l.param[1], t2=next.param[0], t1=l.param[0], ind1=x.param[0].value
			let next=l.param[1], t1=l.param[0], t2=next.param[0], ind1=x.param[0].value
			let type_next = t2.param[1].value, type_prev = prev.param[1].value //t1 is the current token's type, t2 being next e.g. ';', 'connective'...
			print('l-type', type_next)
			/*if(l.n==2 && next.n==2 && is_ws(next)) {
				//skip first
				l.param[1] = l.param[1]
			}*/
			let pos=ind1.lastIndexOf('\n')
			if(pos<0) { //indexOf with negative value
				print('a', [pos])
			}
			else {
				let after_nl = ind1.slice(pos+1)
				//break;
				//print(['indent', ind, after_nl])
				let snew = remove_prev_inds(after_nl,ind) //-1 if fail
				var n=ind.length
				//print(['remove',ind,'from',after_nl,snew])
				print(['indent', after_nl, ind, snew])
				//print('ind', ind)
				if(snew==-1) {
					//unindent
					print('= remove', [type_prev, type_next], ';'+n)
					n2=0
					ind=remove_ind(ind, after_nl)
					if(type_next=='EOF') {
						print('eof', n, n2, ind, str(l2))
						n=ind.length
						l2 = iterate(push_semicolon, n2, l2)
						l2=set_list(l2, eof)
						l2.n = 0
						//print('=', str(l2))
					}
					else if(type_next!=';' && type_next!='connective' && type_prev!='connective' && type_prev!='else' && type_prev!='elseif' && type_prev!='case') {
				
						if (type_prev!=';' && type_next!='else' && type_next!='elseif' && type_next!='case') {
							print(1,';'+n2) //; + and
							l2 = iterate(push_semicolon, n2, l2)
							l2.name = cons
							l2 = set_list(l2, set_tk('and', 'connective'))
							//break;
							//print(str_full(startl))
						}
						else if(type_prev==';') { //only add and
							print(2)
							l2 = set_list(l2, set_tk('and', 'connective'))
						}
						else { //unindent
							print(3) //todo work on n (ind length) and n2 (unindents)
							//n2=n-1 //math.sub
							print('n',n,n2); //throw 12;
							l2 = iterate(push_semicolon, n2-1, l2) //todo add or not semicolon before else
							//throw 1;
						}
						print('c2',str(l2))
					}
				}
				else if(snew=='') {
					//same indent level, add 'and'
					if(type_next=='EOF') {
						print('eof', n, str(l2))
						l2 = iterate(push_semicolon, n, l2)
						l2=set_list(l2, eof)
						l2.n = 0
						print('=', str(l2))
					}
					else if(type_next!=';' && type_next!='connective' && type_prev!='connective' && type_prev!='else' && type_prev!='elseif' && type_prev!='case') {
				
						if (type_prev!=';' && type_next!='else' && type_next!='elseif' && type_next!='case') {
							print(1)
							//l2 = iterate(push_semicolon, n, l2).param[1]
							l2=set_list(l2, set_tk('and', 'connective'))
							//break;
						}
						else {
							print(3) //??
						}
					}
				}
				else {
					//new indent
					print('= new', [snew])
					ind.push(snew)
					n=ind.length
				}
			}	
			//set_ws(l2,x,l)
			//print(str(l2))
			//skip ws
			//l2=l2.param[1]
			/*l2=l2.param[1] //skip ws*/
			//print('#', str(x))
		}
		else if(x.param[1].value=='EOF') {
			print('eof')
			l2.n=0
		}
		else {	
			set_list(l2,x)
			l2=l2.param[1]
		}
		prev = x
		l=l.param[1]
	}
	print('l2', str_full(startl))
	print('')
	return startl
}

//unpack env
function unpack(e) {
	bc = e.proto.insts
	locals = e.locals
	consts1 = consts
	consts = e.proto.consts
	n = bc.length
}

function closure(o, c1) {
	
}

function move_upvals(e, prev) {
	e.locals = new Array(e.proto.n_locs)
	e.locals = e.locals.concat(e.proto.upvals)
	/*print('===')
	if(e.upvals>0) {
		print(e.upvals.length)
		print(arraystr1(prev.locals))
		var c1=prev.locals
		for(j=0;j<e.upvals.length;j+=1) {
			print('-', str(c1[e.upvals[j]]), e.upvals[j])
			//print(consts1[e.upvals[j]].toString(), full)
			e.locals.push(c1[e.upvals[j]])
		}
	}*/
}

function check(o) {
	print(str(o))
	if(type(o)=='Proto') {
		var c1=locals //consts
		var e=o//.proto
		//print(e.upvals)
		for(j=0;j<e.upvals.length;j+=1) {
			//print('-', str(c1[e.upvals[j]]), e.upvals[j])
			e.upvals[j] = locals[e.upvals[j]]
		}
		print(arraystr(e.upvals))
	}
	return o
}

function check1(o) {
	if(type(o)=='Proto') {
		var c1=locals //consts
		var e=o//.proto
		for(j=0;j<e.upvals.length;j+=1) {
			//print(consts1[e.upvals[j]].toString(), full)
			o.locals.push(c1[e.upvals[j]])
		}
		//print('rel', o.name, arraystr(e.upvals))
	}
	return o
}

var cp_list=[], trail=[]//, status=true, stack=[]

function stringfy(l) {
	let s=''
	for(j=0;j<l.length;++j) {
		s+=String.fromCharCode(l[j])
	}
	return s
}

function any() {
	return new Value('ref', null) //{type:'ref', value:null}
}

function unbound(o) {
	return o.value===null//o===o.value
}

function bound(o) {
	return o.value!==null//o!==o.value
}

function deref(o) {
	while(o.type=='ref' && o.value!=null && o!=o.value)//(o!=o.value)
		o = o.value
	return o
}

trail2 = []

//unify deref values
function unify(o, o2) {
	print(str(o), '=', str(o2))//, o, o2)
	if(o2.type=='ref') {
		o3 = o
		o = o2
		o2 = o3
	}
	if(o.type!='ref') {
		for(j=0;j<stack;j+=1) log+='|'
		log += /*'\n'+space() +*/'' + str(o) + ' = ' + str(o2) + '\n'
	}
	if(o.type=='ref') {
		//print(o)
		//if(o.type=='ref' && o.value==null)
		//if(unbound(o)) throw 13;
		if(bound(o)) { //variable chain
			print(o,o2)
			let o3=deref(o)
			o3.value = o2
			if(def(cp_list))
				trail.push(o3)
			//throw 13;
			trail2.push(o)
			return true;
		}
		if(unbound(o)) {
			o.value=o2
			if(def(cp_list))
				trail.push(o)
			return true
		}
		else {
			//throw 'not derefed'
		}
	}
	else {
		//print(o,o2)
		if(o.type==o2.type) {
			if(is(o, 'Functor')) {
				print(';', str(o), '=', str(o2), 'cmp')
				if(o.n!=o2.n||o.name.value!=o2.name.value)
					return false
				for(let j=0;j<o.n;j+=1) {
					//print('-',str(o.param[j]))
					if(!unify(deref(o.param[j]), deref(o2.param[j])))
						return false
				}
				//throw 2;
				return true
			}
			else
				return o.value===o2.value
		}
	}
	return false
}

function unify_set(o, o2) {
	if(o.value==null) {
		o.value=o2
		return true
	}
}

function s_locs(e) {
	let s=''
	for(j=0;j<e.proto.n_args;j+=1) {
		//print(regs[j],regs[j].toString(), full)
		s+=str(locals[j])//.toString()
		if(j<e.proto.n_args-1) s+=', '
	}
	s+=''
	return s
}

function s_args(e) {
	let s=''
	for(j=0;j<e.proto.n_args;j+=1) {
		//print(regs[j],regs[j].toString())
		s+=str(regs[j])//.toString()
		if(j<e.proto.n_args-1) s+=', '
	}
	s+=''
	return s	
}

function space(tk) {
	let s=''
	if(undef(tk))
		tk = '|'
	for(j=0;j<stack;j+=1) s+=tk
	return s//+stack+' '
}

function display(e) {
	print('')
	//print('---',e.prev[0].name)//'->', str(e))
	print('--------')
	s=''
	//for(j=0;j<stack;j+=1) s+='|'
	s+=space()
	s+=e.name+'('+s_args(e)
	s+=') ;'
	if(def(e.prev)) {
			s+= e.prev[0].name
		//s+='\n'
		if(e.prev[0].name!=e.name)
			log += s+'\n'
	}
	return s
}

function display_name(e) {
	print('')
	//print('---',e.prev[0].name)//'->', str(e))
	s='--------'//print('--------')
	//s=''
	//for(j=0;j<stack;j+=1) s+='|'
	//s+=space()+e.name//+'\n'
	return s
}

var stack = -1


d_stop = -1
d_bp = -1
d_w = []
ct = 0
function execute(i1) {
	//print('run')
	//print(e)
	print(display_name(e))//,i1);
	//if(bc.length<50) print('['+bc.toString()+']')
	for(i=i1;i<n;) {
		exp = bc[i]; i+=1
		ct +=1
		//print(exp)
		if(step) {
			//print("\n");
			print(chain_cp())
			print("> ");
			ch = scanf('%S')
			if(ch=='a') { return true; }
			else if(ch.slice(0,1)=='s'||ch.slice(0,1)=='n') {
				step=false;
				ct = 0
				//print('\n\n\n\n\n\n\n====')
				d_stop = Number(ch.slice(2))
				print(n)
			}
			else if(ch.slice(0,1)=='t') {
				print(arraystr(trail),trail.length,str(locals[2]), d_w)
			}
			else if(ch.slice(0,1)=='w') {
				d_w.push(locals[ch.slice(2)])
				print(d_w)
			}
			else if(ch.slice(0,1)=='p') {
				print(locals[ch.slice(2)])
			}
			else if(ch.slice(0,1)=='r') {
				step=false;
				ct = 0
				//print('\n\n\n\n\n\n\n====')
				d_stop = Number(200)
				print(n)
			}
			else if(ch=='c') step=false;
			
		}
		else {
			if(ct==d_stop || ct==d_bp)
				step=true
		}
		//print(exp, 'i:'+i)
		switch(exp) {
			//2-args, put, get
			case code.eq:
				c = bc[i]; i+=1;
				c2 = bc[i]; i+=1;
				o = consts[c2]
				//print(c,c2,o)
				print('eq','y'+c,'c'+c2,';',str(o)) //new local[c] is consts[c2]
				//locals[c] = any();
				locals[c] = o
				locals[c] = check(o)
				break;
			case code.eq_val:
				//should be equivalent to put_val c,0 get_const c,0
				c = bc[i]; i+=1;
				c2 = bc[i]; i+=1;
				print('eq_val','y'+c,'c'+c2,str(locals[c])) //local[c] is consts[c2] //consts
				o = deref(locals[c])
				//locals[c] = any();
				//print(arraystr(e.consts));
				//print(arraystr(consts));
				if(!unify(o, consts[c2]))
					return false
				print('eq_val','y'+c,'c'+c2,';',str(o)) //local[c] is consts[c2]
				check(consts[c2])
				//print(e.locals)
				//print(locals.slice(0,4))
				break;
			case code.put_void:
				c = bc[i]; i+=1;
				c2 = bc[i]; i+=1;
				print('put','void',c2)//,';', bc[i-3],bc[i-2],bc[i-1],bc[i],bc[i+1],bc[i+2],bc[i+3])
				regs[c2] = any()
				break;
			case code.put_variable_loc:
				c = bc[i]; i+=1;
				c2 = bc[i]; i+=1;
				o = any();
				locals[c] = o
				print('put','y'+c,c2,';',str(o))
				regs[c2] = locals[c]
				break;
			case code.put_value_loc:
				c = bc[i]; i+=1;
				c2 = bc[i]; i+=1;
				o = locals[c]
				if(undef(locals[c])) {
					//??
					print('?1')
					locals[c] = any();
					throw '21: no local found';
				}
				print('put','y'+c,c2,'; '+str(locals[c]))//str(regs[c2])
				//print(o)
				regs[c2] = deref(o)
				//print(bc[i],bc[i+1],bc[i+2],bc[i+3],bc[i+4])
				//print(array(bc),i)
				break;
			case code.put_const:
				c = bc[i]; i+=1;
				c2 = bc[i]; i+=1;
				regs[c2] = consts[c]
				print('put','c'+c,c2,'; '+str(regs[c2]))
				//print(bc[i])
				break;
			case code.get_variable_loc: //get value from reg and stores it in local (local is now reg)
				c = bc[i]; i+=1;
				c2 = bc[i]; i+=1;
				o = deref(regs[c2])
				print('get_var','y'+c,c2,';',str(o))
				locals[c] = o
				break;
			case code.get_value_loc: //get value from reg and compare to local
				c = bc[i]; i+=1;
				c2 = bc[i]; i+=1;
				o = deref(locals[c])
				//o2 = deref(regs[c2]) //todo necessary?
				print('get_val','y'+c,c2,';',str(o),'<=>',str(regs[c2]))
				if(!unify(o, regs[c2])) return false;
				if(undef(locals[c])) throw 312;
				break;
			
			case code.obj_get:
				c = bc[i]; i+=1;
				c2 = bc[i]; i+=1;
				//place object c attribute in reg[251] in reg[c2]
				print('obj_get', 'y'+c, c2)
				o = deref(locals[c])
				o2 = deref(regs[251])
				//print('obj_get', 'y'+c, c2, ';', str(o2))
				var t=o.value, s=o2.value
				o3=t[s]
				if(undef(o3)) {
					print(str(o),str(o2),str(o3))
					//print(str(o))
				}
				assert(def(o3), 'no attribute '+o2+' in table')
				regs[c2]=o3
				//print('obj_get','y'+c,'c'+c2,'y'+c3,';',regs[c3])
				//print(bc[i],bc[i+1],bc[i+2],bc[i+3],bc[i+4])
				break;
				
			//3-args
			case code.get_functor:
				c = bc[i]; i+=1;
				c2 = bc[i]; i+=1;
				c3 = bc[i]; i+=1;
				o = deref(regs[c2])
				o2 = consts[c]
				if(o && o.type=='ref') {
					fc=new Functor(o2,c3)
					fc.n=c3
					write=true
					print('get_fc','c'+c,c2,'#'+c3,'new',';',/*str(o), */str(o2))
					unify(o, fc)
				}
				else {
					write=false
					fc=o
					if(!is(o,'Functor')) {
						print('get_fc','c'+c,c2,'#'+c3,'cmp')
						return false;
					}
					//print(o,o2)
					//print(fc.name)
					print('get_fc','c'+c,c2,'#'+c3,'cmp',';',/*str(o),*/o2.value,fc.name.value)
					print('cmp',str(o),str(o2))
					//print(str(o))
					if(fc.n!==c3||fc.name.value!=consts[c].value)
						return false;
				}
				fc._i = 0
				//print(o)
				break;
			
			case code.fc_var_loc:
				c = bc[i]; i+=1;
				if(write) {
					o = any()
					fc.param.push(o)
					locals[c] = o
					print('fc <- y'+c, ';', str(o))
				}
				else {
					o = fc.param[fc._i]
					//print(fc._i,str(fc),'y'+c)
					//if(locals[c]==null) {
					locals[c] = any();
					//}
					//print(o, locals[c])
					print('fc['+fc._i+'] = new y'+c, ';', str(o), str(locals[c]))
					if(!unify(deref(locals[c]), o)) return false
					fc._i += 1
					//todo set
				}
				break;
			
			case code.fc_value:
				c = bc[i]; i+=1;
				//print('y'+c, locals[c])
				o = deref(locals[c])
				//print(o)
				if(write) {
					print('fc <- '+'y'+c, ';', str(o))
					fc.param.push(o)
				}
				else {
					//write=false
					//print(o,locals[c], 'y'+c, ';', str(o))
					print('fc['+fc._i+'] = y'+c, ';', str(o))
					o2=deref(fc.param[fc._i])
					if(!unify(o, o2)) return false;
					fc._i += 1
					//throw 1
				}
				break;
			
			case code.fc_const:
				c = bc[i]; i+=1;
				o = deref(consts[c])
				if(write) {
					fc.param.push(o)
					print('fc <- '+'c'+c, ';', str(o))
				}
				else {
					//write=false
					print('fc['+fc._i+'] = '+'c'+c, ';', str(o))
					o2=deref(fc.param[fc._i])
					if(!unify(o2, consts[c])) return false;
					fc._i += 1
					//throw 10;
				}
				break;
					
			case code.deallocate:
				break;
				
			case code.fc_void:
				//print('fc void', bc[i-1],bc[i],bc[i+1],bc[i+2],bc[i+3])
				c = bc[i]; i+=1;
				//print('y'+c, locals[c])
				//print(o)
				if(write) {
					print('fc <- '+'_')
					fc.param.push(any())
				}
				else {
					fc._i += 1
				}
				break;
				
			//1-args
			case code.try_else:
				c = to_int32(bc, i); i+=4
				print('\n{try '+e.name+' '+c+'}')
				print(e.cur)
				//bp=c;
				cp_list.push({i:c,e:e,trail:trail.length,stack:stack})
				break;
			case code.retry_else:
				//throw 3;
				c = to_int32(bc, i); i+=4
				print('\n{retry '+e.name+' '+c+'}')
				//bp=c;
				cp_list.push({i:c,e:e,trail:trail.length,stack:stack})
				print(chain_cp())
				break;
			case code.jmp:
				c = to_int32(bc, i); i+=4
				print('jmp',c)
				i=c;
				break;
			case code.call:
				c = bc[i]; i+=1;
				print('call','y'+c, 'i:'+i)
				stack += 1
				//a closure is created, i.e. we create a new object with Env as the prototype
				var prev = e
				//print(arraystr(locals))
				o = deref(locals[c])
				print(c,str(o))
				if(o.name.slice(0,o.name.length-1)==args2)
					step = true
				//e = Object.create(locals[c])
				//print(locals[c].name, arraystr(locals[c].locals))
				e = new Env(o, prev)
				move_upvals(e, prev)
				print(arraystr(e.proto.upvals))
				assert(type(e) == 'Env', 'call')
				e.prev = [prev, i]
				i = 0
				e.cur = [trail.length, cp_list.length]
				unpack(e)
				//print(chain(e))
				print(display(e))
				//if(e.name=='run\0') throw 2;
				print(s_locs(e))
				if(e.name=='step2\0' && def(locals[4]) && locals[4].type!='int') {
					b=e.locals[4]
					print(b)
					throw 2;
				}
				//print(e.cur)
				break;
			case code.call_reg:
				//print('call',c,';',str(e))
				c = bc[i]; i+=1;
				//print(regs.slice(0,2),regs[1])
				var prev = e
				//e = Object.create(regs[c])
				e = new Env(regs[c])
				move_upvals(e, prev)
				print('call',c,';',str(e))
				stack += 1
				print(e.name)
				if(e.name.slice(0,e.name.length-1)==args2)
					step = true
				assert(type(e) == 'Env', 'call')
				e.prev = [prev, i]
				e.cur = [trail.length, cp_list.length]
				i = 0
				unpack(e)
				print(display(e))
				print(e.cur)
				break;
			case code.call_c:
				c = bc[i]; i+=1;
				print('c:call',c,str(consts[c]),'i:'+i, bc[i-1], bc[i], bc[i+1])
				let f = fn[consts[c].value]
				assert(!undef(f), 'not a function')
				if(f()===false) {
					return false
				}
				//print(i,bc[i])
				break;
				
			//0-args
			case code.trust_else_fail:
				//c = to_int32(bc, i); i+=4
				print('\n{trust_else_fail '+e.name+'}')
				break;
			case code.pass:
				print('pass',code.pass)
				break;
			case code.fail:
				print('pass',code.pass)
				//throw 44;
				return false
				break;
			case code.halt: //16
				o=e.prev
				if(undef(o)) {
					if(undef(e.temp))
						return true
					else { //back from require
						print(252,str(regs[252]))
						unify(e.temp[1], regs[252])
						//print(1,e.temp[1])
						//print(e.temp[2])
						o=e.temp[0]
						print(arraystr(o))
						trail=o[2]
						stack += 1
					}
				}
				//if(i==57) throw 1
				e=o[0]
				i=o[1]
				stack -= 1
				unpack(e)
				print('')
				print(chain(e))
				print('halt','to', /*e.name,*/ e.name/*+'('+s_locs(e)+')'*/, i)
				//print('--'+e.name+'('+s_locs(e)+')')
				//print(arraystr(locals))
				//print('')
				//print('i:'+i,bc[i],bc[i+1],insts.toString(),bc,'\n')
				//return true;
				break;
			case code.print:
				print('test')
			default:
				c=bc[i]
				print(display(e))
				print('['+bc.toString()+']','['+bc[i]+','+bc[i+1]+']','i:'+i)
				print(''+exp)
				throw 'Error: bytecode not found: '+exp;
				break;
		}
	}
	//print(locals.slice(0,4))
	print('')
}

let args = process.argv, name = args[2], flags = args[3] //name of file and flag
print(args)
if(name=='-b') { //breakpoint
	args2 = flags
	flags = name
	name = undefined
	//throw 'no file name given'
}
else if(name=='--bc') {
	name = flags
	//throw 'no file name given'
}

print(flags, name)
if(!undef(flags)&&flags=='--step') { //debug flag was set
	print(flags, name, args2)
	if(undef(args2))
		step = true
	else {
		
	}
}/*
if(name!==undefined) {
	print(name, typeof name)
	start(name+'.bc', true)
	print('obj')
}
else {
	//start('out.bc', false)
	//start('out.bc',true)
	//throw 1;
}*/

if(undef(name))
	name='out'//'out2'

function run() {
	print('')
	unpack(e)
	while(true) {
		if(execute(i1)) {
			break;
		}
		else {
			//false case
			print('')
			//print(chain_cp())
			var cp = cp_list.pop()
			if(typeof cp == 'undefined')
				return false
			for(j=0;j<stack;j+=1) log+=' '
			log += 'x '+e.name//'false '+e.name
			print('false '+e.name, /*'['+arraystr1(cp_list)+']', */cp.i, cp.trail, trail.length)
			e=cp.e
			stack=cp.stack
			//print(chain())
			let a1=cp.trail
			//print(a1,trail.length)
			//log+=a1+' '+trail.length
			log+=' -> '+e.name+'\n'
			//log+='\n'
			i1=cp.i
			unpack(e)
			//print(arraystr(trail))
			//if(trail.length>10000) throw 13;
			if(trail.length>180000) throw "high trail";
			for(let i=trail.length-1; i>=a1; i -= 1) {
			//while(a1<trail.length) {
				if(undef(a1)) throw 1;
				if(cp.trail>trail.length) throw 23;
				let a2=trail.pop()
				print('unwind', str(a2))
				//assert(a2.type==='ref')
				a2.type = 'ref'
				a2.value = null
				//a2.value = a2
				print(str(a2))
				//print(locals[2],a2==locals[2])
				//if(e.name=='step2') throw 3;
			}
			//run(e); execute(cp.e, cp.i) //break;
		}
	}
}
/*
fs.open('log', 'w', (err, fd) => {
	if (err) {
		throw err;
	}
	//print(fd)
	fs.write(fd, log);
});*/

function load(s) {
	try {
	data = fs.readFileSync(s)
	} catch(e) {
		//print(e, typeof(e))
		throw 'Error: no file '+s;
	}
	print('\n=== load file ===', s)
	//print(data); print(data.length); print(int32(data[0]))
	bc = new Uint8Array(data)
	i = 0
	var e = read_fn(bc, data)
	print(arraystr(e.consts)); //throw 1;
	//print('['+e.consts+']')
	//print(e.consts[0])
	//print(bc)
	//n = e.insts.length
	//throw 2;
	print('\n=== run file',s,'==')
	i1 = 0
	//print('=')
	set_type(e,'proto')
	return e
}


//step = true
e = new Env(load(name+'.bc'), []); e.cur = [0, 0]
let error=false
try {
	if(run()===false) {
		print('| false')
		log += 'x'
	}
	else print('| true')
}
catch(e) {	
	print('error', e);
	error=true
}
/*
print(remove_from_start('zxc','z'))
print('zxc'.indexOf('z'))
format(remove_prev_inds('\t\t\n\n',['\t','\t']))
format('\t\t')
*/
fs.writeFileSync('log', log, (err) => {
  if (err) throw err;
});

/*
l=parser.parse('x=2 or true and false or x=3')

//l=parser.parse('x=2')
//l=parser.parse('x=2 or true')
//l=parser.parse('p(2)')
l=p('case true case false;')

print(';',l)

//print(l.param[0])


//f = set_f(l.name, l.param[0], l.param[1])
f = def(l)
print(f)
print(str(f))
*/
if(error) throw 12;
//export({str:str})
this.str = str