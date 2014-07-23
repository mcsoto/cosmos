%appendToFile Relation String String;writeToFile Relation String String;readFile Relation String String;fileReadAll Relation File String;fileReadChar Relation File String;fileReadLine Relation File String;fileRead Relation File String;fileWrite Relation File String;openWrite Relation String File;close Relation File;open Relation String String Any;rawWriteln Relation Any;rawWrite Relation Any;read Relation String;writeln Relation Any;write Relation Any
:- style_check([-singleton,-no_effect]), ensure_loaded("core.pl").
:- ensure_loaded("logic.pl").
io_write(Env0,_x) :- obj_call2(Env0,"logic","toString",[_x,T1]),write(T1).
io_writeln(Env0,_x) :- env_call(Env0,"write",[Env0,_x]),env_call(Env0,"write",[Env0,"\n"]).
io_read(Env0,_x) :- ioread(_x).
io_rawWrite(Env0,_x) :- write(_x).
io_rawWriteln(Env0,_x) :- env_call(Env0,"rawWrite",[Env0,_x]),env_call(Env0,"rawWrite",[Env0,"\n"]).
io_open(Env0,_name,_mode,_f) :- fopen(_name,_mode,_f).
io_close(Env0,_f) :- close(_f).
io_openWrite(Env0,_name,_f) :- fopen(_name,"write",_f).
io_fileWrite(Env0,_f,_x) :- write(_f,_x).
io_fileRead(Env0,_f,_s) :- fread(_f,_s).
io_fileReadLine(Env0,_f,_s) :- fread(_f,_s).
io_fileReadChar(Env0,_f,_s) :- read_string(_f,1,_s).
io_fileReadAll(Env0,_f,_s) :- fread_all(_f,_s).
io_readFile(Env0,_name,_s) :- env_call(Env0,"open",[Env0,_name,"read",_f]),env_call(Env0,"fileReadAll",[Env0,_f,_s]),env_call(Env0,"close",[Env0,_f]).
io_writeToFile(Env0,_name,_s) :- env_call(Env0,"open",[Env0,_name,"write",_f]),env_call(Env0,"fileWrite",[Env0,_f,_s]),env_call(Env0,"close",[Env0,_f]).
io_appendToFile(Env0,_name,_s) :- env_call(Env0,"open",[Env0,_name,"append",_f]),env_call(Env0,"fileWrite",[Env0,_f,_s]),env_call(Env0,"close",[Env0,_f]).
io_env(X) :- new(X0),set(X0,"appendToFile",io_appendToFile,X1),set(X1,"writeToFile",io_writeToFile,X2),set(X2,"readFile",io_readFile,X3),set(X3,"fileReadAll",io_fileReadAll,X4),set(X4,"fileReadChar",io_fileReadChar,X5),set(X5,"fileReadLine",io_fileReadLine,X6),set(X6,"fileRead",io_fileRead,X7),set(X7,"fileWrite",io_fileWrite,X8),set(X8,"openWrite",io_openWrite,X9),set(X9,"close",io_close,X10),set(X10,"open",io_open,X11),set(X11,"rawWriteln",io_rawWriteln,X12),set(X12,"rawWrite",io_rawWrite,X13),set(X13,"read",io_read,X14),set(X14,"writeln",io_writeln,X15),set(X15,"write",io_write,X16),logic_env(Y16),set(X16,"logic",Y16,X17),set(X17,"Some",io_Some,X18),set(X18,"None",io_None,X19),set(X19,"Left",io_Left,X20),set(X20,"Right",io_Right,X21),X=X21.