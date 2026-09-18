:- ensure_loaded('../../compiler/platform/driver').
:- initialization(main,main).
raises(Goal,Pattern) :- catch((call(Goal),fail),Pattern,true).
main :- compiler_load_runtime,consult('tests/compiler/v2.pl'),v2(Api),
 get_(Api,"valid",Valid),once(call_cl(Valid,[])),
 get_(Api,"badInput",Bad),raises(call_cl(Bad,[]),error(cosmos_input_contract("increment"),_)),
 get_(Api,"missing",Missing),raises(call_cl(Missing,[_]),error(cosmos_output_contract("missing"),_)),
 get_(Api,"broken",Broken),raises(call_cl(Broken,[]),error(cosmos_function_failed("broken"),_)),
 get_(Api,"assertFailed",Assert),raises(call_cl(Assert,[]),error(cosmos_assertion("specific failure"),_)),
 get_(Api,"alternatives",Alternatives),findall(X,call_cl(Alternatives,[X]),[2.0,2.0,3.0]),
 get_(Api,"test",Bool),findall(X,call_cl(Bool,[X]),[1.0]),
 nb_setval(cosmos_debug_contracts,true),
 once(call_cl(Valid,[])),
 get_(Api,"exact",Exact),once(call_cl(Exact,[One])),One=1.0,
 get_(Api,"tooMany",Many),raises(call_cl(Many,[_]),error(cosmos_determinism("tooMany","det",2),_)),
 get_(Api,"badProtocol",BadProtocol),raises(call_cl(BadProtocol,[]),error(cosmos_protocol_behavior("Positive","accept"),_)),
 get_(Api,"badType",BadType),raises(call_cl(BadType,[]),error(cosmos_type_error("String",7.0),_)),
 writeln('V2 passed').
