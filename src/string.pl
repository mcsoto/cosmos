%_add Relation Any Any Any;lessOrEqual Relation String String;code Relation String Integer;toCodes Relation String Functor;toList Relation String Functor;_toList Relation String Integer Functor;toReal Relation String Real;toInteger Relation String Integer;toNumber Relation String Any;replace Relation String String String String;split Relation String String Functor;splitIndex Relation String String Integer Functor;every Relation String (Relation Any);everyIndex Relation String (Relation Any) Integer;map Relation String (Relation Any Any) String;mapIndex Relation String (Relation Any Any) Integer String;each Relation String (Relation Integer Any Any) String;eachIndex Relation String (Relation Integer Any Any) Integer String;concat Relation String String String;lower Relation String String;upper Relation String String;has Relation String String;find Relation String String Integer;findIndex Relation String String Integer Integer;last Relation String String;size Relation String Integer;at Relation Any Any Any;get Relation String Integer String;rest Relation String String;first Relation String String;slice Relation String Integer Integer String
:- style_check([-singleton,-no_effect]), ensure_loaded("core.pl").
:- ensure_loaded("math.pl").
string_slice(Env0,_S1,_I,_J,_S2) :- s_slice(_S1,_I,_J,_S2).
string_first(Env0,_S1,_S2) :- s_at(_S1,0,_S2).
string_rest(Env0,_S1,_S2) :- s_size(_S1,_L),s_slice(_S1,1,_L,_S2).
string_get(Env0,_s,_x,_c) :- sub_string(_s,_x,1,_,_c).
string_at(Env0,_s,_x,_c) :- env_call(Env0,"get",[Env0,_s,_x,_c]).
string_size(Env0,_s,_n) :- string_length(_s,_n).
string_last(Env0,_s,_c) :- env_call(Env0,"size",[Env0,_s,T2]),fd_sub(T2,1,T1),env_call(Env0,"get",[Env0,_s,T1,_c]).
string_findIndex(Env0,_s1,_s2,_i,_pos) :- (((env_call(Env0,"get",[Env0,_s1,_i,_s2])),eq(_i,_pos));(env_call(Env0,"size",[Env0,_s1,T3]),fd_lt(_i,T3),fd_add(_i,1,T4),env_call(Env0,"findIndex",[Env0,_s1,_s2,T4,_pos]))).
string_find(Env0,_s1,_s2,_pos) :- env_call(Env0,"findIndex",[Env0,_s1,_s2,0,_pos]).
string_has(Env0,_s1,_s2) :- env_call(Env0,"findIndex",[Env0,_s1,_s2,0,_]).
string_upper(Env0,_s1,_s2) :- string_upper(_s1,_s2).
string_lower(Env0,_s1,_s2) :- string_lower(_s1,_s2).
string_concat(Env0,_S1,_S2,_S3) :- string_concat(_S1,_S2,_S3).
string_eachIndex(Env0,_s,_p,_i,_s2) :- (((env_call(Env0,"get",[Env0,_s,_i,_c])),closure_call(Env0,_p,[_i,_c,_c2]),fd_add(_i,1,T5),env_call(Env0,"eachIndex",[Env0,_s,_p,T5,_tail2]),env_call(Env0,"concat",[Env0,_c2,_tail2,_s2]));(env_call(Env0,"size",[Env0,_s,T6]),eq(_i,T6),eq(_s2,""))).
string_each(Env0,_s,_p,_s2) :- env_call(Env0,"eachIndex",[Env0,_s,_p,0,_s2]).
string_mapIndex(Env0,_s,_p,_i,_s2) :- (((env_call(Env0,"get",[Env0,_s,_i,_c])),closure_call(Env0,_p,[_c,_c2]),fd_add(_i,1,T7),env_call(Env0,"mapIndex",[Env0,_s,_p,T7,_tail2]),env_call(Env0,"concat",[Env0,_c2,_tail2,_s2]));(env_call(Env0,"size",[Env0,_s,T8]),eq(_i,T8),eq(_s2,""))).
string_map(Env0,_s,_p,_s2) :- env_call(Env0,"mapIndex",[Env0,_s,_p,0,_s2]).
string_everyIndex(Env0,_s,_p,_i) :- (((env_call(Env0,"size",[Env0,_s,T9]),eq(_i,T9)),true);(env_call(Env0,"get",[Env0,_s,_i,_c]),closure_call(Env0,_p,[_c]),fd_add(_i,1,T10),env_call(Env0,"everyIndex",[Env0,_s,_p,T10]))).
string_every(Env0,_s,_p) :- env_call(Env0,"everyIndex",[Env0,_s,_p,0]).
string_splitIndex(Env0,_s,_sep,_i,_l) :- env_call(Env0,"findIndex",[Env0,_s,_sep,_i,_pos]),obj_call2(Env0,"math","inc",[_pos,_pos2]),env_call(Env0,"size",[Env0,_s,_len]),env_call(Env0,"slice",[Env0,_s,_i,_pos,_part1]),eq(_l, '[|]'(_part1,_l2)),env_call(Env0,"splitIndex",[Env0,_s,_sep,_pos2,_l2]);env_call(Env0,"size",[Env0,_s,_len]),env_call(Env0,"slice",[Env0,_s,_i,_len,_part1]),eq(_l, '[|]'(_part1,[])).
string_split(Env0,_s,_sep,_l) :- env_call(Env0,"splitIndex",[Env0,_s,_sep,0,_l]).
string_replace(Env0,_s,_word1,_word2,_s2) :- replace_word(_word1,_word2,_s,_s2).
string_toNumber(Env0,_S,_N) :- number_string(_N,_S).
string_toInteger(Env0,_S,_N) :- number_string(_N,_S).
string_toReal(Env0,_S,_N) :- number_string(_N,_S).
string__toList(Env0,_s,_i,_l2) :- (((env_call(Env0,"get",[Env0,_s,_i,_c])),fd_add(_i,1,T11),env_call(Env0,"_toList",[Env0,_s,T11,_tail]),append('[|]'(_c,[]),_tail,_l2));(env_call(Env0,"size",[Env0,_s,T12]),eq(_i,T12),eq(_l2,[]))).
string_toList(Env0,_s,_l) :- env_call(Env0,"_toList",[Env0,_s,0,_l]).
string_toCodes(Env0,_s,_l) :- string_codes(_s,_l).
string_code(Env0,_s,_n) :- env_call(Env0,"toCodes",[Env0,_s,'[|]'(_n,[])]).
string_lessOrEqual(Env0,_S1,_S2) :- s_le(_S1,_S2).
string__add(Env0,_s1,_s2,_s3) :- env_call(Env0,"concat",[Env0,_s1,_s2,_s3]).
string_env(X) :- new(X0),set(X0,"_add",string__add,X1),set(X1,"lessOrEqual",string_lessOrEqual,X2),set(X2,"code",string_code,X3),set(X3,"toCodes",string_toCodes,X4),set(X4,"toList",string_toList,X5),set(X5,"_toList",string__toList,X6),set(X6,"toReal",string_toReal,X7),set(X7,"toInteger",string_toInteger,X8),set(X8,"toNumber",string_toNumber,X9),set(X9,"replace",string_replace,X10),set(X10,"split",string_split,X11),set(X11,"splitIndex",string_splitIndex,X12),set(X12,"every",string_every,X13),set(X13,"everyIndex",string_everyIndex,X14),set(X14,"map",string_map,X15),set(X15,"mapIndex",string_mapIndex,X16),set(X16,"each",string_each,X17),set(X17,"eachIndex",string_eachIndex,X18),set(X18,"concat",string_concat,X19),set(X19,"lower",string_lower,X20),set(X20,"upper",string_upper,X21),set(X21,"has",string_has,X22),set(X22,"find",string_find,X23),set(X23,"findIndex",string_findIndex,X24),set(X24,"last",string_last,X25),set(X25,"size",string_size,X26),set(X26,"at",string_at,X27),set(X27,"get",string_get,X28),set(X28,"rest",string_rest,X29),set(X29,"first",string_first,X30),set(X30,"slice",string_slice,X31),math_env(Y31),set(X31,"math",Y31,X32),table_env(Y32),set(X32,"table",Y32,X33),list_env(Y33),set(X33,"list",Y33,X34),string_env(Y34),set(X34,"string",Y34,X35),math_env(Y35),set(X35,"math",Y35,X36),io_env(Y36),set(X36,"io",Y36,X37),logic_env(Y37),set(X37,"logic",Y37,X38),set(X38,"Some",string_Some,X39),set(X39,"None",string_None,X40),set(X40,"Left",string_Left,X41),set(X41,"Right",string_Right,X42),X=X42.