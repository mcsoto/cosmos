:- ensure_loaded('../../compiler/platform/driver').
:- initialization(main,main).
empty([]).
rejected(_) :- fail.
broken(_) :- throw(codec_test_error).
main :- compiler_load_runtime,
 cc_encode_value(["AB",[65,66],[],fc_Binary("+",X,X)],Wire),
 Wire=_{type:"list",items:[_{type:"string",value:"AB"},
     _{type:"list",items:[_{type:"number",value:65},_{type:"number",value:66}]},
     _{type:"list",items:[]},_{type:"functor",name:"fc_Binary",args:[_,V,V]}]},
 V=_{type:"variable",id:0},
 cc_query_result(empty,_{status:"success",value:_{type:"list",items:[]}}),
 cc_query_result(rejected,_{status:"failure"}),
 cc_query_result(broken,Error),system:get_dict(status,Error,"error"),
 cc_encode_value(9007199254740993,_{type:"integer",value:"9007199254740993"}),
 R is 1 rdiv 3,cc_encode_value(R,_{type:"rational",numerator:"1",denominator:"3"}),
 catch(cc_query_text(42,_),error(type_error(text,42),_),Caught=true),Caught=true,
 writeln('Codec passed').
