% Table {lexer.Any;parse_body.Relation Any Any Any;parse_call.Relation Any Any Any;parse_exp.Relation Any Any Any;run.Relation Any Any;run_parser.Relation Any Any;run_ws.Relation Any Any}
% Op Functor;TList Functor Functor;Func Functor;ObjGet2 Functor;ObjGet Functor;Id Functor;Str Functor;Num Functor;Fact Functor;Rel Functor;Size Functor;Mutable Functor;Declaration Functor;Once Functor;Host Functor;Op Functor;SoftCut Functor;Cond Functor;If Functor;ObjPred Functor;Bracket Functor;Or Functor;And Functor;Pred Functor;False Functor;True Functor;Inequality Functor;Stm2 Functor;Stm Functor;Neq Functor;Eq Functor;T Functor;Pair Functor;Info Functor;Token Functor;Cons Functor
% purser
% run
purser_run(_s,_l1,_upvals):-_upvals=[_run2,_debug,_debug,_ws,_debug,_lexer,_debug],(call_cl(_debug,["lexer..."]),get_(_lexer,"run",T29),_T28 = T29,once(call_cl(_T28,[_s,_l])),call_cl(_debug,["whitespace..."]),get_(_ws,"run",T31),_T30 = T31,call_cl(_T30,[_l,_l2]),call_cl(_debug,[_l2]),!,call_cl(_debug,["parser..."]),call_cl(_run2,[_l2,_l1]),!).
% run2
purser_run2(_l,_code,_upvals):-_upvals=[_debug,_parse_body],(call_cl(_parse_body,[_l,_tail,_code]),call_cl(_debug,[_code])).
% parse_body
purser_parse_body(_l,_tail,_s,_upvals):-_upvals=[_parse_pred],(call_cl(_parse_pred,[_l,_l2,_s])).
% parse_exp2
purser_parse_exp2(_l,_tail,_f,_upvals):-_upvals=[_c2,_id_exp,_parse_type],((((call_cl(_parse_type,[_l,_,"id"])),(call_cl(_id_exp,[_l,_tail,_f]));call_cl(_c2,[_l,_tail,_f])))).
% parse_exp3
purser_parse_exp3(_l,_tail,_f,_upvals):-_upvals=[_c2,_debug,_id_exp2,_debug],((((_l = '[|]'(fc_Token(_name,"id",_),_l2)),(call_cl(_debug,['[|]'("token",'[|]'(_name,[]))]),call_cl(_id_exp2,[_l,_tail,_f]));call_cl(_debug,['[|]'("non-id",'[|]'(_name,[]))]),call_cl(_c2,[_l,_tail,_f])))).
% info2
purser_info2(_l,_t2,_upvals):-_upvals=[],(writeln_('[|]'(_l,'[|]'(_t2,[]))),((_l = '[|]'(_t,_tail),_t = fc_Token(_,"connective",_))->(call(purser_info2(_tail,_t2),_upvals));((_l = [])->(throw("could not get line"));(_l = '[|]'(_t,_),_t = _t2)))).
% parse_body2
purser_parse_body2(_l2,_tail,_s1,_code,_upvals):-_upvals=[_parse_body,_debug,_get_line,_get_line],(((_l2 = '[|]'(fc_Token(_conn,"connective",_),_l3),((_conn = "and",call_cl(_get_line,[_l2,_i1]),call_cl(_get_line,[_l3,_i2]),call_cl(_debug,['[|]'(_i1,'[|]'(_i2,[]))]),_code = fc_And(_s1,_s2,fc_T(_i2,_i2)));(dif(_conn,"and"),(_conn = "or"),(_code = fc_Or(_s1,_s2)))),call_cl(_parse_body,[_l3,_tail,_s2]));(dif(_l2,'[|]'(fc_Token(_conn,"connective",_),_l3)),_l2 = _tail,_s1 = _code))).
% parse_call
purser_parse_call(_l,_tail,_code,_upvals):-_upvals=[_parse_declaration,_parse_definition,_parse_host,_parse_obj_pred,_parse_pred,_parse_word,_parse_inequality,_parse_neq,_parse_eq,_parse_all,_parse_struct4,_parse_struct2,_parse_once,_parse_case,_parse_struct3,_parse_struct,_parse_if,_parse_atom,_parse_false,_parse_true],((call_cl(_parse_true,[_l,_tail,_code]);(call_cl(_parse_false,[_l,_tail,_code]);(call_cl(_parse_atom,[_l,_tail,_code]);(call_cl(_parse_if,[_l,_tail,_code]);(call_cl(_parse_struct,[_l,_tail,_code]);(call_cl(_parse_struct3,[_l,_tail,_code]);(call_cl(_parse_case,[_l,_tail,_code]);(call_cl(_parse_once,[_l,_tail,_code]);(call_cl(_parse_struct2,[_l,_tail,_code]);(call_cl(_parse_struct4,[_l,_tail,_code]);(call_cl(_parse_all,[_l,_tail,_code]);(call_cl(_parse_eq,[_l,_tail,_code]);(call_cl(_parse_neq,[_l,_tail,_code]);(call_cl(_parse_inequality,[_l,_tail,_code]);(call_cl(_parse_word,[_l,_tail,_code]);(call_cl(_parse_pred,[_l,_tail,_code]);(call_cl(_parse_obj_pred,[_l,_tail,_code]);(call_cl(_parse_host,[_l,_tail,_code]);(call_cl(_parse_definition,[_l,_tail,_code]);call_cl(_parse_declaration,[_l,_tail,_code]))))))))))))))))))))).
% parse_definition
purser_parse_definition(_l,_tail,_f,_upvals):-_upvals=[_parse_body,_parse_args,_parse_body,_parse_args],((((true),(_l = '[|]'(fc_Token(_,_mode,_),'[|]'(fc_Token(_name,"id",_),'[|]'(fc_Token(_,"(",_),_l2))),((_mode = "rel",_f = fc_Rel(_name,_args,_body));(dif(_mode,"rel"),(_mode = "fun",_f = fc_Rel(_name,_args,_body,_mode));(dif(_mode,"fun"),false))),call_cl(_parse_args,[_l2,_l3,_args]),_l3 = '[|]'(fc_Token(_,")",_),_l4),call_cl(_parse_body,[_l4,_l5,_body]),_l5 = '[|]'(fc_Token(_,";",_),_tail));true))).
% parse_declaration
purser_parse_declaration(_l,_tail,_code,_upvals):-_upvals=[_parse_name],(call_cl(_parse_name,[_l,_tail,_type,_name]),_code = fc_Declaration(_name,_type)).
% parse_struct2
purser_parse_struct2(_l,_tail,_f,_upvals):-_upvals=[_parse_body,_parse_args,_get_info],(_l = '[|]'(fc_Token(_name,"id",_),'[|]'(fc_Token(_,"(",_),_l2)),((_name = "foreach",call_cl(_get_info,[_l,_T25]),_f = fc_Stm(_name,_body1,_body,_T25));(dif(_name,"foreach"),false)),call_cl(_parse_args,[_l2,_l3,_body1]),_l3 = '[|]'(fc_Token(_,")",_),_l4),call_cl(_parse_body,[_l4,_l5,_body]),_l5 = '[|]'(fc_Token(_,";",_),_tail)).
% parse_struct4
purser_parse_struct4(_l,_tail,_f,_upvals):-_upvals=[_parse_body,_parse_exp,_parse_exp,_parse_exp,_get_info],(_l = '[|]'(fc_Token("for","id",_),'[|]'(fc_Token(_,"(",_),_l2)),call_cl(_get_info,[_l,_T24]),_f = fc_Stm("for-in",'[|]'(_f1,'[|]'(_f2,'[|]'(_body1,[]))),_body,_T24),call_cl(_parse_exp,[_l2,_l_a,_f1]),_l_a = '[|]'(fc_Token(_,",",_),_l_b),call_cl(_parse_exp,[_l_b,_l3,_f2]),_l3 = '[|]'(fc_Token(_,"in",_),_l4),call_cl(_parse_exp,[_l4,_lc,_body1]),_lc = '[|]'(fc_Token(_,")",_),_l5),call_cl(_parse_body,[_l5,_l6,_body]),_l6 = '[|]'(fc_Token(_,";",_),_tail)).
% parse_pred
purser_parse_pred(_l,_tail,_code,_upvals):-_upvals=[_parse_args],(_l = [fc_Token(_a,"id",_)|[fc_Token(_,"(",_)|_l2]],call_cl(_parse_args,[_l2,_l3,_code_args]),_l3 = '[|]'(fc_Token(_,")",_),'[|]'(fc_Token(_,".",_),_tail)),calc(_a+"(",T21),calc(T21+_sargs,T22),calc(T22+")",T23),_code = T23).
% parse_stm
purser_parse_stm(_l,_tail,_f,_upvals):-_upvals=[_get_info,_parse_body,_parse_args],(_l = '[|]'(fc_Token(_name,"id",_),'[|]'(fc_Token(_,"(",_),_l2)),_name = "functor",call_cl(_parse_args,[_l2,_l3,_args]),_l3 = '[|]'(fc_Token(_,")",_),_l4),call_cl(_parse_body,[_l4,_l5,_body]),_l5 = '[|]'(fc_Token(_,";",_),_tail),call_cl(_get_info,[_l,_T20]),_f = fc_Stm(_name,_args,_body,_T20)).
% parse_inequality
purser_parse_inequality(_l,_tail,_f,_upvals):-_upvals=[_get_info,_parse_exp,_parse_type,_parse_exp],(call_cl(_parse_exp,[_l,_l2,_a]),call_cl(_parse_type,[_l2,_l3,_op]),((((_op = "<";(_op = ">";(_op = "<=";_op = ">=")))),(call_cl(_parse_exp,[_l3,_tail,_b]),call_cl(_get_info,[_l,_T19]),_f = fc_Inequality(_a,_b,_op,_T19));false))).
% parse_all
purser_parse_all(_l,_tail,_f,_upvals):-_upvals=[_get_info,_parse_body,_parse_body],(_l = '[|]'(fc_Token(_name,"id",_),'[|]'(fc_Token(_,"(",_),_l2)),_name = "forall",call_cl(_parse_body,[_l2,_l3,_body1]),_l3 = '[|]'(fc_Token(_,")",_),_l4),call_cl(_parse_body,[_l4,_l5,_body]),_l5 = '[|]'(fc_Token(_,";",_),_tail),call_cl(_get_info,[_l,_T18]),_f = fc_Stm2(_name,_body1,_body2,_T18)).
% parse_once
purser_parse_once(_l,_tail,_f,_upvals):-_upvals=[_get_info,_parse_call],(_l = '[|]'(fc_Token(_name,_name,_),_l2),((_name = "once",true);(dif(_name,"once"),_name = "not")),call_cl(_parse_call,[_l2,_tail,_body]),call_cl(_get_info,[_l,_T17]),_f = fc_Stm(_name,[],_body,_T17)).
% parse_false
purser_parse_false(_l,_tail,_f,_upvals):-_upvals=[],(_l = '[|]'(fc_Token(_a,"false",_),_tail),_f = fc([],"False")).
% parse_atom
purser_parse_atom(_l,_tail,_f,_upvals):-_upvals=[_get_info],(_l = '[|]'(fc_Token("cut","id",_),_tail),call_cl(_get_info,[_l,_T16]),_f = fc_Fact(_a,[],_T16)).
% parse_true
purser_parse_true(_l,_tail,_f,_upvals):-_upvals=[],(_l = '[|]'(fc_Token(_a,"true",_),_tail),_f = fc([],"True")).
% parse_neq
purser_parse_neq(_l,_tail,_f,_upvals):-_upvals=[_parse_exp,_parse_type,_parse_exp],(call_cl(_parse_exp,[_l,_l2,_a]),call_cl(_parse_type,[_l2,_l3,"!="]),call_cl(_parse_exp,[_l3,_tail,_b]),_f = fc_Neq(_a,_b)).
% parse_eq
purser_parse_eq(_l,_tail,_f,_upvals):-_upvals=[_get_info,_parse_exp,_parse_type,_parse_exp],(call_cl(_parse_exp,[_l,_l2,_a]),call_cl(_parse_type,[_l2,_l3,"="]),call_cl(_parse_exp,[_l3,_tail,_b]),call_cl(_get_info,[_l,_info]),_f = fc_Eq(_a,_b,_info)).
% parse_word
purser_parse_word(_l,_tail,_f,_upvals):-_upvals=[_get_info,_parse_exp,_parse_type,_parse_exp],(call_cl(_parse_exp,[_l,_l2,_a]),call_cl(_parse_type,[_l2,_l3,"in"]),call_cl(_parse_exp,[_l3,_tail,_b]),call_cl(_get_info,[_l,_info]),_f = fc_Stm("in",'[|]'(_a,'[|]'(_b,[])),_,_info)).
% parse_case
purser_parse_case(_l,_tail,_f,_upvals):-_upvals=[_debug,_parse_case1,_parse_body,_parse_case2],(call_cl(_parse_case2,[_l,_l1]),call_cl(_parse_body,[_l1,_l2,_f1]),call_cl(_parse_case1,[_l2,_l3,_c_]),_l3 = '[|]'(fc_Token(_,";",_),_tail),_f = fc_Cond(fc([],"True"),_f1,_c_),call_cl(_debug,[_f])).
% parse_case1
purser_parse_case1(_l,_tail,_f,_upvals):-_upvals=[_parse_body,_parse_case2,_parse_body,_parse_case2],((((true),(call_cl(_parse_case2,[_l,_l1]),call_cl(_parse_body,[_l1,_l2,_f1]),call(purser_parse_case1(_l2,_tail,_c_),_upvals),_f = '[|]'(_f1,_c_));_f = [],_tail = _l))).
% parse_case2
purser_parse_case2(_l,_l1,_upvals):-_upvals=[],((_l = '[|]'(fc_Token(_,"case",_),_l1);_l = '[|]'(fc_Token(_,"cond",_),_l1))).
% parse_struct3
purser_parse_struct3(_l,_tail,_f,_upvals):-_upvals=[_parse_body,_debug,_parse_body,_parse_body,_parse_body,_get_info,_debug],(_l = '[|]'(fc_Token(_name,"id",_),'[|]'(fc_Token(_,"(",_),_l2)),call_cl(_debug,["st3"]),((_name = "for",call_cl(_get_info,[_l,_T15]),_f = fc_Stm(_name,'[|]'(_body1,'[|]'(_body2,'[|]'(_body3,[]))),_body,_T15));(dif(_name,"for"),false)),call_cl(_parse_body,[_l2,_l3,_body1]),_l3 = '[|]'(fc_Token(_,";",_),_l4),call_cl(_parse_body,[_l4,_l5,_body2]),_l5 = '[|]'(fc_Token(_,";",_),_l6),call_cl(_parse_body,[_l6,_l7,_body3]),_l7 = '[|]'(fc_Token(_,";",_),'[|]'(fc_Token(_,")",_),_l8)),call_cl(_debug,["st3-for"]),call_cl(_parse_body,[_l8,_l9,_body]),_l9 = '[|]'(fc_Token(_,";",_),_tail)).
% parse_struct
purser_parse_struct(_l,_tail,_f,_upvals):-_upvals=[_parse_body,_parse_body,_get_info],(_l = '[|]'(fc_Token(_name,"id",_),'[|]'(fc_Token(_,"(",_),_l2)),((_name = "while",call_cl(_get_info,[_l,_T14]),_f = fc_Stm(_name,_body1,_body,_T14));(dif(_name,"while"),false)),call_cl(_parse_body,[_l2,_l3,_body1]),_l3 = '[|]'(fc_Token(_,")",_),_l4),call_cl(_parse_body,[_l4,_l5,_body]),_l5 = '[|]'(fc_Token(_,";",_),_tail)).
% parse_if
purser_parse_if(_l,_tail,_f,_upvals):-_upvals=[_debug,_parse_elseifs,_debug,_parse_body,_parse_body,_debug],(((_l = [fc_Token(_,"if",_)|_l0],_f = fc_Cond(_fbody1,_fbody2,_c_,"if"));(dif(_l,[fc_Token(_,"if",_)|_l0]),(_l = [fc_Token(_,"when",_)|_l0],_f = fc_Cond(_fbody1,_fbody2,_c_,"when"));(dif(_l,[fc_Token(_,"when",_)|_l0]),_l = [fc_Token(_,"choose",_)|_l0],_f = fc_SoftCut(_fbody1,_fbody2,_c_)))),_l0 = '[|]'(fc_Token(_,"(",_),_l2),call_cl(_debug,["if"]),call_cl(_parse_body,[_l2,_l3,_fbody1]),_l3 = '[|]'(fc_Token(_,")",_),_l4),call_cl(_parse_body,[_l4,_l5,_fbody2]),call_cl(_debug,['[|]'("elseif",'[|]'(_fbody2,[]))]),call_cl(_parse_elseifs,[_l5,_l11,_c_]),_l11 = '[|]'(fc_Token(_,";",_),_tail),call_cl(_debug,['[|]'("end",[])])).
% parse_elseifs
purser_parse_elseifs(_l,_tail,_c_,_upvals):-_upvals=[_parse_body,_parse_body,_parse_body,_parse_body,_parse_body],((((true),(_l = [fc_Token(_,"elseif",_)|[fc_Token(_,"(",_)|_l1]],call_cl(_parse_body,[_l1,_l2,_f1]),_l2 = [fc_Token(_,")",_)|_l3],call_cl(_parse_body,[_l3,_l4,_f2]),call(purser_parse_elseifs(_l4,_tail,_c_2),_upvals),_c_ = [fc_Pair(_f1,_f2)|_c_2]);(_l = [fc_Token(_,"else",_)|_l10],call_cl(_parse_body,[_l10,_tail,_f1]),_c_ = '[|]'(_f1,[]);_c_ = [],_tail = _l)))).
% parse_exp
purser_parse_exp(_l,_tail,_f,_upvals):-_upvals=[_fget,_parse_math2,_debug,_parse_exp2],(call_cl(_parse_exp2,[_l,_l2,_a]),call_cl(_debug,['[|]'("exp",'[|]'(_a,[]))]),call_cl(_parse_math2,[_l2,_tail,_a,_f2]),call_cl(_fget,[_f2,_f,_a,_f2])).
% parse_math2
purser_parse_math2(_l,_tail,_prev,_f,_upvals):-_upvals=[_fget,_get_info,_parse_exp2,_debug,_debug,_op_,_parse_type],(call_cl(_parse_type,[_l,_l2,_op]),((call_cl(_op_,[_op]))->(call_cl(_debug,['[|]'("op",'[|]'(_op,[]))]),call_cl(_debug,['[|]'("exp2",'[|]'(_b,[]))]),call_cl(_get_info,[_l,_T13]),call_cl(_parse_exp2,[_l2,_l4,_T12]),_fcur = fc_Op(_prev,_T12,_op,_T13),call(purser_parse_math2(_l4,_tail,_fcur,_fnext),_upvals),call_cl(_fget,[_fnext,_f,_fcur,_fnext]));(_f = _None,_tail = _l))).
% op_
purser_op_(_op,_upvals):-_upvals=[],((_op = "+";(_op = "-";(_op = "*";_op = "/")))).
% fget
purser_fget(_f2,_f,_a,_f2,_upvals):-_upvals=[],(((_f2 = _None,_f = _a);(dif(_f2,_None),_f = _f2))).
% c2
purser_c2(_l,_tail,_f,_upvals):-_upvals=[_parse_value,_parse_name,_parse_obj_get2,_parse_obj_get,_parse_type,_debug,_parse_exp,_parse_type,_parse_excl,_parse_length,_parse_lambda,_parse_list,_parse_list],((((true),(call_cl(_parse_list,[_l,_tail,_f]));(call_cl(_parse_lambda,[_l,_tail,_f]);(call_cl(_parse_length,[_l,_tail,_f]);(call_cl(_parse_excl,[_l,_tail,_f]);(call_cl(_parse_type,[_l,_l2,"("]),call_cl(_parse_exp,[_l2,_l3,_f1]),call_cl(_debug,[fc_T(_f1,_f)]),_f = _f1,call_cl(_parse_type,[_l3,_tail,")"]);(call_cl(_parse_obj_get,[_l,_tail,_f]);(call_cl(_parse_obj_get2,[_l,_tail,_f]);(call_cl(_parse_name,[_l,_tail,_type,_name]),_f = fc_Id(_name,_type);call_cl(_parse_value,[_l,_tail,_f]))))))))))).
% id_exp
purser_id_exp(_l,_tail,_f,_upvals):-_upvals=[_parse_host,_parse_obj_get2,_parse_obj_get,_parse_obj_pred,_parse_exp_call],((call_cl(_parse_exp_call,[_l,_tail,_f]);(call_cl(_parse_obj_pred,[_l,_tail,_f]);(call_cl(_parse_obj_get,[_l,_tail,_f]);(call_cl(_parse_obj_get2,[_l,_tail,_f]);call_cl(_parse_host,[_l,_tail,_f])))))).
% id_exp2
purser_id_exp2(_l,_tail,_f,_upvals):-_upvals=[_parse_exp_call,_parse_obj_get2,_parse_obj_get],((call_cl(_parse_obj_get,[_l,_tail,_f]);(call_cl(_parse_obj_get2,[_l,_tail,_f]);call_cl(_parse_exp_call,[_l,_tail,_f])))).
% parse_host2
purser_parse_host2(_l,_tail,_f,_upvals):-_upvals=[],(_l = '[|]'(fc_Token(_a,"id",_),'[|]'(fc_Token(_,".",_),'[|]'(fc_Token(_b,"id",_),_tail))),_f = fc_ObjGet(_a,_b)).
% parse_host
purser_parse_host(_l,_tail,_code,_upvals):-_upvals=[_parse_args,_parse_args],((((true),(_l = [fc_Token(_obj,"id",_)|[fc_Token(_,"::",_)|[fc_Token(_a,"id",_)|[fc_Token(_,"(",_)|_l2]]]],call_cl(_parse_args,[_l2,_l3,_code_args]),_l3 = '[|]'(fc_Token(_,")",_),_tail),_code = fc_Host(_obj,_a,_code_args));(_l = [fc_Token(_obj,"id",_)|[fc_Token(_,"::",_)|_l2]],_l2 = '[|]'(fc_Token(_str,"string",_),_tail),_code = fc_Host(_obj,_str);_l = '[|]'(fc_Token(_obj,"id",_),'[|]'(fc_Token(_,"::",_),_l2)),_l2 = '[|]'(fc_Token(_obj2,"id",_),_tail),_code = fc_Host(_obj,_obj2))))).
% match_any
purser_match_any(_l,_l2,_f,_upvals):-_upvals=[],((((true),(call_cl(_f,[_l,_tail,_f2]),call(purser_match_any(_tail,_l2,_f1),_upvals));_l = _l2))).
% parse_length
purser_parse_length(_l,_tail,_code,_upvals):-_upvals=[_get_info,_parse_exp],(_l = '[|]'(fc_Token(_,"#",_),_l2),call_cl(_parse_exp,[_l2,_tail,_a]),call_cl(_get_info,[_l,_T11]),_code = fc_Size(_a,_T11)).
% parse_excl
purser_parse_excl(_l,_tail,_code,_upvals):-_upvals=[],(_l = [fc_Token(_,"!",_)|[fc_Token(_a,"id",_)|_tail]],_code = fc_Mutable(_a)).
% parse_value
purser_parse_value(_l,_tail,_f,_upvals):-_upvals=[],((((true),(_l = '[|]'(fc_Token(_a,"string",_),_tail),_f = fc_Str(_a));(_l = '[|]'(fc_Token(_,"-",_),'[|]'(fc_Token(_a,"number",_),_tail)),calc("-"+_a,T10),_f = fc_Num(T10);_l = '[|]'(fc_Token(_a,"number",_),_tail),_f = fc_Num(_a))))).
% parse_name
purser_parse_name(_l,_tail,_type,_name,_upvals):-_upvals=[_name_list_to_type,_parse_name2],(call_cl(_parse_name2,[_l,_tail,_name_list,_name]),call_cl(_name_list_to_type,[_name_list,_type])).
% parse_name2
purser_parse_name2(_l,_tail,_type,_name,_upvals):-_upvals=[_debug,_debug],((((true),(_l = '[|]'(fc_Token(_a,"id",_),_l2),call(purser_parse_name2(_l2,_tail,_type2,_name),_upvals),_type = '[|]'(_a,_type2),call_cl(_debug,['[|]'(_name,'[|]'(_type,[]))]));_l = '[|]'(fc_Token(_a,"id",_),_tail),_type = [],_name = _a))).
% name_list_to_type
purser_name_list_to_type(_l,_l2,_upvals):-_upvals=[_name_list_to_type2],(((_l = [],_l2 = _l);(dif(_l,[]),(_l = '[|]'(_a,[]),_l2 = _l);(dif(_l,'[|]'(_a,[])),_l = [_a|_tail],call_cl(_name_list_to_type2,[_tail,_tail2]),_l2 = [_a|_tail2])))).
% name_list_to_type2
purser_name_list_to_type2(_l,_l2,_upvals):-_upvals=[],(((_l = '[|]'(_head,[]),_l2 = '[|]'('[|]'(_head,[]),[]));(dif(_l,'[|]'(_head,[])),_l = [_head|_tail],call(purser_name_list_to_type2(_tail,_tail2),_upvals),_l2 = ['[|]'(_head,[])|_tail2]))).
% parse_lambda
purser_parse_lambda(_l,_tail,_f,_upvals):-_upvals=[_parse_body,_parse_args],(_l = [fc_Token(_,"rel",_)|[fc_Token(_,"(",_)|_l2]],call_cl(_parse_args,[_l2,_l3,_args]),_l3 = [fc_Token(_,")",_)|_l4],call_cl(_parse_body,[_l4,_l5,_body]),_l5 = [fc_Token(_,";",_)|_tail],_f = fc_Rel(_args,_body)).
% parse_list
purser_parse_list(_l,_tail,_f,_upvals):-_upvals=[_parse_args2],(_l = '[|]'(fc_Token(_,"[",_),_l2),call_cl(_parse_args2,[_l2,_l3,_args]),_l3 = '[|]'(fc_Token(_,"]",_),_tail),_f = fc_TList(_args)).
% parse_obj_pred
purser_parse_obj_pred(_l,_tail,_f,_upvals):-_upvals=[_get_info,_parse_args],(_l = '[|]'(fc_Token(_obj,"id",_),'[|]'(fc_Token(_,".",_),'[|]'(fc_Token(_a,"id",_),'[|]'(fc_Token(_,"(",_),_l2)))),call_cl(_parse_args,[_l2,_l3,_code_args]),_l3 = '[|]'(fc_Token(_,")",_),_tail),call_cl(_get_info,[_l,_T9]),_f = fc_ObjPred(_obj,_a,_code_args,_T9)).
% parse_exp_call
purser_parse_exp_call(_l,_tail,_f,_upvals):-_upvals=[_get_info,_parse_args],(_l = '[|]'(fc_Token(_name,"id",_),'[|]'(fc_Token(_,"(",_),_l2)),call_cl(_parse_args,[_l2,_l3,_args]),_l3 = '[|]'(fc_Token(_,")",_),_tail),call_cl(_get_info,[_l,_T8]),_f = fc_Func(_name,_args,_T8)).
% parse_obj_get2
purser_parse_obj_get2(_l,_tail,_f,_upvals):-_upvals=[_parse_exp],(_l = '[|]'(fc_Token(_a,"id",_),'[|]'(fc_Token(_,"[",_),_l2)),call_cl(_parse_exp,[_l2,_l3,_f1]),_l3 = '[|]'(fc_Token(_,"]",_),_tail),_f = fc_ObjGet2(_a,_f1)).
% parse_obj_get
purser_parse_obj_get(_l,_tail,_f,_upvals):-_upvals=[],(_l = '[|]'(fc_Token(_a,"id",_),'[|]'(fc_Token(_,".",_),'[|]'(fc_Token(_b,"id",_),_tail))),_f = fc_ObjGet(_a,_b)).
% parse_args2
purser_parse_args2(_l,_tail,_f,_upvals):-_upvals=[_parse_exp,_parse_exp,_parse_type,_parse_exp,_parse_exp,_parse_type,_parse_exp],((((true),(call_cl(_parse_exp,[_l,_l1,_f1]),call_cl(_parse_type,[_l1,_l2,_s]),((_s = "|",call_cl(_parse_exp,[_l2,_tail,_f2]),_f = '[|]'(_f1,'[|]'(fc_T(_f2),[])));(dif(_s,"|"),(_s = ",",call(purser_parse_args2(_l2,_tail,_f2),_upvals),_f = '[|]'(_f1,_f2));(dif(_s,","),false))));(call_cl(_parse_exp,[_l,_tail,_f1]),_f = '[|]'(_f1,[]);_f = [],_tail = _l)))).
% parse_args
purser_parse_args(_l,_tail,_f,_upvals):-_upvals=[_parse_exp,_parse_type,_parse_exp,_parse_type,_parse_exp],((((true),(call_cl(_parse_exp,[_l,_l1,_f1]),call_cl(_parse_type,[_l1,_l2,","]),call(purser_parse_args(_l2,_tail,_f2),_upvals),_f = '[|]'(_f1,_f2));(call_cl(_parse_exp,[_l,_tail,_f1]),_f = '[|]'(_f1,[]);_f = [],_tail = _l)))).
% custom_throw
purser_custom_throw(_msg,_info,_upvals):-_upvals=[],(_info = fc_Info(_line,_col),writeln_(_info),calc("(line "+_line,T2),calc(T2+", col ",T3),calc(T3+_col,T4),calc(T4+") ",T5),calc(T5+_msg,T6),str(T6,T7),throw(T7)).
% get_line
purser_get_line(_l,_info1,_upvals):-_upvals=[],(_l = '[|]'(fc_Token(_,_,_info),_),_info = fc_Info(_info1,_)).
% get_info
purser_get_info(_l,_info,_upvals):-_upvals=[],(_l = '[|]'(fc_Token(_,_,_info),_)).
% parse_type
purser_parse_type(_l,_tail,_type,_upvals):-_upvals=[],(_l = '[|]'(fc_Token(_,_type,_),_tail)).
% debug
purser_debug(_s,_upvals):-_upvals=[],(writeln_(_s)).
% main
purser(X):-_debug = clos([],purser_debug),creq1("list",_list,T1),call(T1,_list),_parse_type = clos([],purser_parse_type),_get_info = clos([],purser_get_info),_get_line = clos([],purser_get_line),_custom_throw = clos([],purser_custom_throw),_parse_args = clos([_parse_exp,_parse_type,_parse_exp,_parse_type,_parse_exp],purser_parse_args),_parse_args2 = clos([_parse_exp,_parse_exp,_parse_type,_parse_exp,_parse_exp,_parse_type,_parse_exp],purser_parse_args2),_parse_obj_get = clos([],purser_parse_obj_get),_parse_obj_get2 = clos([_parse_exp],purser_parse_obj_get2),_parse_exp_call = clos([_get_info,_parse_args],purser_parse_exp_call),_parse_obj_pred = clos([_get_info,_parse_args],purser_parse_obj_pred),_parse_list = clos([_parse_args2],purser_parse_list),_parse_lambda = clos([_parse_body,_parse_args],purser_parse_lambda),_name_list_to_type2 = clos([],purser_name_list_to_type2),_name_list_to_type = clos([_name_list_to_type2],purser_name_list_to_type),_parse_name2 = clos([_debug,_debug],purser_parse_name2),_parse_name = clos([_name_list_to_type,_parse_name2],purser_parse_name),_parse_value = clos([],purser_parse_value),_parse_excl = clos([],purser_parse_excl),_parse_length = clos([_get_info,_parse_exp],purser_parse_length),_match_any = clos([],purser_match_any),_parse_host = clos([_parse_args,_parse_args],purser_parse_host),_parse_host2 = clos([],purser_parse_host2),_id_exp2 = clos([_parse_exp_call,_parse_obj_get2,_parse_obj_get],purser_id_exp2),_id_exp = clos([_parse_host,_parse_obj_get2,_parse_obj_get,_parse_obj_pred,_parse_exp_call],purser_id_exp),_c2 = clos([_parse_value,_parse_name,_parse_obj_get2,_parse_obj_get,_parse_type,_debug,_parse_exp,_parse_type,_parse_excl,_parse_length,_parse_lambda,_parse_list,_parse_list],purser_c2),_fget = clos([],purser_fget),_op_ = clos([],purser_op_),_parse_math2 = clos([_fget,_get_info,_parse_exp2,_debug,_debug,_op_,_parse_type],purser_parse_math2),_parse_exp = clos([_fget,_parse_math2,_debug,_parse_exp2],purser_parse_exp),_parse_elseifs = clos([_parse_body,_parse_body,_parse_body,_parse_body,_parse_body],purser_parse_elseifs),_parse_if = clos([_debug,_parse_elseifs,_debug,_parse_body,_parse_body,_debug],purser_parse_if),_parse_struct = clos([_parse_body,_parse_body,_get_info],purser_parse_struct),_parse_struct3 = clos([_parse_body,_debug,_parse_body,_parse_body,_parse_body,_get_info,_debug],purser_parse_struct3),_parse_case2 = clos([],purser_parse_case2),_parse_case1 = clos([_parse_body,_parse_case2,_parse_body,_parse_case2],purser_parse_case1),_parse_case = clos([_debug,_parse_case1,_parse_body,_parse_case2],purser_parse_case),_parse_word = clos([_get_info,_parse_exp,_parse_type,_parse_exp],purser_parse_word),_parse_eq = clos([_get_info,_parse_exp,_parse_type,_parse_exp],purser_parse_eq),_parse_neq = clos([_parse_exp,_parse_type,_parse_exp],purser_parse_neq),_parse_true = clos([],purser_parse_true),_parse_atom = clos([_get_info],purser_parse_atom),_parse_false = clos([],purser_parse_false),_parse_once = clos([_get_info,_parse_call],purser_parse_once),_parse_all = clos([_get_info,_parse_body,_parse_body],purser_parse_all),_parse_inequality = clos([_get_info,_parse_exp,_parse_type,_parse_exp],purser_parse_inequality),_parse_stm = clos([_get_info,_parse_body,_parse_args],purser_parse_stm),_parse_pred = clos([_parse_args],purser_parse_pred),_parse_struct4 = clos([_parse_body,_parse_exp,_parse_exp,_parse_exp,_get_info],purser_parse_struct4),_parse_struct2 = clos([_parse_body,_parse_args,_get_info],purser_parse_struct2),_parse_declaration = clos([_parse_name],purser_parse_declaration),_parse_definition = clos([_parse_body,_parse_args,_parse_body,_parse_args],purser_parse_definition),_parse_call = clos([_parse_declaration,_parse_definition,_parse_host,_parse_obj_pred,_parse_pred,_parse_word,_parse_inequality,_parse_neq,_parse_eq,_parse_all,_parse_struct4,_parse_struct2,_parse_once,_parse_case,_parse_struct3,_parse_struct,_parse_if,_parse_atom,_parse_false,_parse_true],purser_parse_call),_parse_body2 = clos([_parse_body,_debug,_get_line,_get_line],purser_parse_body2),_info2 = clos([],purser_info2),_parse_exp3 = clos([_c2,_debug,_id_exp2,_debug],purser_parse_exp3),_parse_exp2 = clos([_c2,_id_exp,_parse_type],purser_parse_exp2),creq1("lexor",_lexer,T26),call(T26,_lexer),creq1("ws2",_ws,T27),call(T27,_ws),_parse_body = clos([_parse_pred],purser_parse_body),_run2 = clos([_debug,_parse_body],purser_run2),_run = clos([_run2,_debug,_debug,_ws,_debug,_lexer,_debug],purser_run),new(T32),set_(T32,"parse_exp",_parse_exp,T34),set_(T34,"parse_call",_parse_call,T35),set_(T35,"parse_body",_parse_body,T36),set_(T36,"run",_run,T37),set_(T37,"run_ws",_run2,T38),set_(T38,"lexer",_run_lexer,T39),set_(T39,"run_parser",_run2,T33),_t2 = T33,X=_t2,creq1("io",_io,T40),call(T40,_io),_s = "p(x).",writeln_(_t),clock(_t3),call_cl(_run,[_s,_l]),clock(_t4),writeln_('[|]'("l",'[|]'(_l,[]))),{_t4-_t3=T41},{X1 = T41},writeln_(X1).