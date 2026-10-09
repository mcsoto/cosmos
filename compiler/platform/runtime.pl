% Runtime operations used by generated programs. No parsing/lowering policy.
% Embeddings implement cosmos_host_op/3; native compilation needs no host.
:- multifile cosmos_host_op/3.
% Emitter configuration, shared by the native driver and the browser bundle.
% This is consulted only while compiling; generated application code never
% calls it.
cc_trace_requested(1.0) :- nb_current(cosmos_trace_requested,true), !.
cc_trace_requested(0.0).
% Trace source-level calls, never the compiler's generated helper predicates.
% Backtrackable depth restores nesting on success, redo, failure and exceptions.
:- meta_predicate cosmos_trace_call(+,?,0).
cosmos_trace_call(Name,Args,Goal) :-
    (nb_current(cosmos_trace_enabled,true)->
        (nb_current(cosmos_trace_depth,Depth)->true;Depth=0),
        forall(between(1,Depth,_),put_char('|')),
        format('~s(',[Name]),cosmos_trace_args(Args),writeln(')'),flush_output,
        Next is Depth+1,b_setval(cosmos_trace_depth,Next),
        call(Goal),b_setval(cosmos_trace_depth,Depth)
    ;call(Goal)).
cosmos_trace_args([]).
cosmos_trace_args([Value|Values]) :-
    cosmos_trace_value(Value),
    (Values=[]->true;write(','),cosmos_trace_args(Values)).
cosmos_trace_value(Value) :- number(Value),!,format('~g',[Value]).
cosmos_trace_value(Value) :- var(Value),!,
    term_to_atom(Value,Raw),atom_concat('_',Id,Raw),format('#var~w',[Id]).
cosmos_trace_value(Value) :-
    write_term(Value,[quoted(true),max_depth(8)]).

% SWI-WASM returns JavaScript text as atoms. Use printable reserved tokens:
% embedded NULs cannot survive the reverse Prolog-to-JavaScript call.
% Cosmos code consistently sees host(Id), including returned get/method values.
cosmos_host_decode(Wire,host(Id)) :- is_dict(Wire),get_dict(host,Wire,Id),!.
cosmos_host_decode(Wire,host(Id)) :-
    (atom(Wire);string(Wire)),sub_string(Wire,0,13,_,"@cosmos-host:"),
    sub_string(Wire,13,_,0,Text),catch(number_string(Id,Text),_,fail),
    integer(Id),Id>0,!.
cosmos_host_decode(Value,Value).
cosmos_host_encode(host(Id),Wire) :- !,number_string(Id,Text),string_concat("@cosmos-host:",Text,Wire).
cosmos_host_encode([],[]) :- !.
cosmos_host_encode([Value|Values],[Wire|Wires]) :- !,
    cosmos_host_encode(Value,Wire),cosmos_host_encode(Values,Wires).
cosmos_host_encode(Value,Value).
cosmos_host_call(Operation,Args,Result) :-
    cosmos_host_encode(Args,WireArgs),cosmos_host_op(Operation,WireArgs,WireResult),cosmos_host_decode(WireResult,Result).
cosmos_host_root(Domain,Name,Host) :- cosmos_host_call("root",[Domain,Name],Host).
cosmos_get(host(Id),Key,Value) :- !,cosmos_host_call("get",[host(Id),Key],Value).
cosmos_get(prototype_object(Prototype,Fields),Key,Value) :- !,
    (get_assoc(Key,Fields,Raw)->true;cosmos_get(Prototype,Key,Raw)),
    cosmos_receiver_value(prototype_object(Prototype,Fields),Raw,Value).
cosmos_get(typed(_,Object),Key,Value) :- !,cosmos_get(Object,Key,Value).
cosmos_get(cosmos_class(Name,Object),Key,Value) :- !,
    cosmos_get(Object,Key,Raw),cosmos_receiver_value(cosmos_class(Name,Object),Raw,Value).
cosmos_get(instance(Name,Object),Key,Value) :- !,
    cosmos_get(Object,Key,Raw),cosmos_receiver_value(instance(Name,Object),Raw,Value).
cosmos_get(conforming(Object,Protocol,Schemas),Key,Value) :- !,
    Protocol=protocol(_,_,Methods),
    (member(method(Key,_,_),Methods)->Value=cosmos_protocol_method(Object,Protocol,Schemas,Key)
    ;cosmos_get(Object,Key,Value)).
cosmos_get(Object,Key,Value) :- getnil(Object,Key,Value).
cosmos_set_or_unify(host(Id),Key,Value) :- !,cosmos_host_call("set",[host(Id),Key,Value],_).
cosmos_set_or_unify(Object,Key,Value) :- cosmos_get(Object,Key,Value).
cosmos_method(host(Id),Key,Args) :- !,cosmos_host_call("method",[host(Id),Key,Args],Result),Result\==false.
cosmos_method(Object,Key,Args) :- cosmos_object_wrapper(Object),!,cosmos_get(Object,Key,F),call_cl(F,Args).
cosmos_method(conforming(Object,Protocol,Schemas),Key,Args) :- !,
    cosmos_protocol_invoke(Object,Protocol,Schemas,Key,Args).
cosmos_method(Object,Key,Args) :- getnil(Object,Key,F),call_cl(F,Args).
cosmos_method_value(host(Id),Key,Args,Value) :- !,cosmos_host_call("method",[host(Id),Key,Args],Value).
cosmos_method_value(Object,Key,Args,Value) :- cosmos_object_wrapper(Object),!,
    cosmos_get(Object,Key,F),append(Args,[Value],All),call_cl(F,All).
cosmos_method_value(conforming(Object,Protocol,Schemas),Key,Args,Value) :- !,
    append(Args,[Value],All),cosmos_protocol_invoke(Object,Protocol,Schemas,Key,All).
cosmos_method_value(Object,Key,Args,Value) :- getnil(Object,Key,F),append(Args,[Value],All),call_cl(F,All).
cosmos_require(Name,Value) :- crequire(Name,Value,_).
cosmos_receiver("object",V) :- !,
    (var(V)->list_to_assoc(["create"-clos(upvals,cosmos_object_create)],V);true).
cosmos_receiver("canvas",V) :- !,
    (var(V)->cosmos_host_root("js","canvas",V);true).
cosmos_receiver(Name,V) :- (var(V)->default_lib(Name,V);true).
cosmos_object_create(Prototype,Fields,prototype_object(Prototype,Fields),_) :-
    (is_assoc(Fields)->true;throw(error(type_error(table,Fields),_))).

:- meta_predicate cosmos_assert(0,+),cosmos_callable(+,+,0),cosmos_checked_call(+,+,+,+,+,0),cosmos_checked_call(+,+,+,+,+,0,+).
:- meta_predicate cosmos_declared_call(+,+,?,0).
cosmos_assert(Goal,Message) :- (once(Goal)->true;throw(error(cosmos_assertion(Message),_))).
cosmos_callable("rel",_,Goal) :- !,call(Goal).
cosmos_callable("bool",_,Goal) :- !,once(Goal).
cosmos_callable(_,Name,Goal) :- (once(Goal)->true;throw(error(cosmos_function_failed(Name),_))).
cosmos_checked_call(Kind,Name,Options,Args,Schemas,Goal) :-
    cosmos_checked_call(Kind,Name,Options,Args,Schemas,Goal,none).
cosmos_checked_call(Kind,Name,Options,Args,Schemas,Goal,Loc) :-
    nb_setval(cosmos_contract_location,Loc),
    (member(Option,Options),get_assoc("parameters",Option,Spec),maplist(cosmos_input(Schemas),Spec,Args)->true
    ;cosmos_contract_violation(input,Kind,Name,Options,Args,Loc)),
    get_assoc("determinism",Option,Determinism),
    cosmos_declared_call(Determinism,Name,Args,cosmos_callable(Kind,Name,Goal)),
    (maplist(cosmos_output(Schemas),Spec,Args)->true
    ;cosmos_contract_violation(output,Kind,Name,Options,Args,Loc)).

% The declared parameters are resolved here instead of being passed in from the
% caller's failing if-then-else: (C -> T ; E) discards C's bindings, so a Spec
% looked up inside the condition arrives unbound and the signature reported
% below collapses to "". The formal names the phase so a caller can tell a bad
% argument from an unsatisfied result; the signature rides in the context so
% printing the error still shows it.
cosmos_contract_violation(Phase,Kind,Name,Options,Args,Loc) :-
    cosmos_contract_signature_of(Options,Spec),
    cosmos_contract_message(Kind,Name,Spec,Args,Loc,Message),
    cosmos_contract_formal(Phase,Name,Formal),
    throw(error(Formal,cosmos_contract_detail(Message))).

cosmos_contract_signature_of([],[]) :- !.
cosmos_contract_signature_of([Option|Options],Spec) :-
    (get_assoc("parameters",Option,Spec)->true
    ;cosmos_contract_signature_of(Options,Spec)).

% Built by hand rather than with `=..`: a one-element list deconstructs to an
% atom, which would throw `cosmos_input_contract` instead of
% `cosmos_input_contract(Name)`.
cosmos_contract_formal(input,Name,cosmos_input_contract(Name)) :- !.
cosmos_contract_formal(output,Name,cosmos_output_contract(Name)).

cosmos_contract_message(Kind,Name,Spec,Args,Loc,Message) :-
    cosmos_contract_kind(Kind,KindName),
    cosmos_contract_signature(Spec,Expected),
    cosmos_contract_actual_signature(Args,Actual),
    cosmos_contract_location(Loc,Prefix),
    format(string(Message),'~s calling "~s" of type ~s ~s as ~s ~s',[Prefix,Name,KindName,Expected,KindName,Actual]).

cosmos_contract_location(none,"") :- !.
cosmos_contract_location(fc_Loc(Line,Column),Prefix) :- !,
    format(string(Prefix),'line ~g:~g: ',[Line,Column]).
cosmos_contract_location(_,"").

cosmos_contract_kind("rel","Relation") :- !.
cosmos_contract_kind("function","Function") :- !.
cosmos_contract_kind("bool","Bool") :- !.
cosmos_contract_kind(Kind,Kind).

cosmos_contract_signature([],"") :- !.
cosmos_contract_signature([Spec|Specs],Text) :-
    get_assoc("mode",Spec,Mode),get_assoc("type",Spec,Type),
    cosmos_contract_piece(Mode,Type,Piece),
    cosmos_contract_signature(Specs,Tail),
    cosmos_contract_join(Piece,Tail,Text).

cosmos_contract_piece(Mode,_Type,Mode) :- Mode \= "Unspecified", !.
cosmos_contract_piece(_Mode,Type,Type).

cosmos_contract_actual_signature([],"") :- !.
cosmos_contract_actual_signature([Value|Values],Text) :-
    cosmos_contract_actual_piece(Value,Piece),
    cosmos_contract_actual_signature(Values,Tail),
    cosmos_contract_join(Piece,Tail,Text).

cosmos_contract_actual_piece(Value,"Out") :- var(Value), !.
cosmos_contract_actual_piece(Value,"String") :- string(Value), !.
cosmos_contract_actual_piece(Value,"Number") :- number(Value), !.
cosmos_contract_actual_piece(Value,"Table") :- is_assoc(Value), !.
cosmos_contract_actual_piece(Value,"List") :- is_list(Value), !.
cosmos_contract_actual_piece(Value,"Relation") :- Value=clos(_,_), !.
cosmos_contract_actual_piece(_Value,"In").

cosmos_contract_join("",Tail,Tail) :- !.
cosmos_contract_join(Piece,"",Piece) :- !.
cosmos_contract_join(Piece,Tail,Text) :- format(string(Text),'~s ~s',[Piece,Tail]).

:- multifile prolog:message//1.
prolog:message(error(cosmos_input_contract(_),cosmos_contract_detail(Detail))) --> [Detail].
prolog:message(error(cosmos_output_contract(_),cosmos_contract_detail(Detail))) --> [Detail].
prolog:message(error(cosmos_input_contract(Name),_)) --> ['input contract violated for "',Name,'"'].
prolog:message(error(cosmos_output_contract(Name),_)) --> ['output contract violated for "',Name,'"'].
prolog:message(error(cosmos_function_failed(Name),_)) -->
    [ 'function "',Name,'" failed' ].
prolog:message(error(cosmos_type_error(Expected,Value),_)) -->
    {cosmos_contract_value_kind(Value,Actual),(nb_current(cosmos_contract_location,Loc)->true;Loc=none),cosmos_contract_location(Loc,Prefix),format(string(Message),'~stype error: expected ~s, got ~s',[Prefix,Expected,Actual])},
    [Message].

cosmos_contract_value_kind(Value,"Out") :- var(Value), !.
cosmos_contract_value_kind(Value,"String") :- string(Value), !.
cosmos_contract_value_kind(Value,"Number") :- number(Value), !.
cosmos_contract_value_kind(Value,"Table") :- is_assoc(Value), !.
cosmos_contract_value_kind(Value,"List") :- is_list(Value), !.
cosmos_contract_value_kind(Value,"List") :- Value=[_|_], !.
cosmos_contract_value_kind(Value,"Relation") :- Value=clos(_,_), !.
cosmos_contract_value_kind(_Value,"Functor").
% Debug instrumentation may explore a second solution. Keep it opt-in for
% effectful relations; ordinary execution never probes extra alternatives.
cosmos_declared_call(Det,Name,Args,Goal) :-
    (nb_current(cosmos_debug_contracts,true)->cosmos_check_determinism(Det,Name,Args,Goal);call(Goal)).
:- meta_predicate cosmos_check_determinism(+,+,?,0).
cosmos_check_determinism("nondet",_,_,Goal) :- !,call(Goal).
cosmos_check_determinism("multi",Name,_,Goal) :- !,
    (call(Goal)*->true;throw(error(cosmos_determinism(Name,"multi",0),_))).
cosmos_check_determinism(Det,Name,Args,Goal) :-
    once(findnsols(2,Args-Goal,Goal,Answers)),
    (Answers=[Answer-Solved]->Args=Answer,Goal=Solved
    ;Answers=[],Det="semidet"->fail
    ;length(Answers,Count),throw(error(cosmos_determinism(Name,Det,Count),_))).
cosmos_input(Schemas,Spec,Value) :-
    get_assoc("mode",Spec,Mode),get_assoc("type",Spec,Type),
    (Mode="In"->ground(Value);Mode="Out"->var(Value);true),
    (var(Value)->cosmos_type_constraint(Value,Type,Schemas);cosmos_is(Value,Type,Schemas)).
cosmos_output(Schemas,Spec,Value) :-
    get_assoc("mode",Spec,Mode),get_assoc("type",Spec,Type),
    (Mode="Out"->nonvar(Value);true),
    (var(Value)->cosmos_type_constraint(Value,Type,Schemas);cosmos_is(Value,Type,Schemas)).
cosmos_is(_,"Any",_) :- !.
cosmos_is(typed(Name,_),Name,_) :- !.
cosmos_is(instance(Name,_),Name,_) :- !.
cosmos_is(cosmos_class(Name,_),Name,_) :- !.
cosmos_is(prototype_object(cosmos_class(Name,_),_),Name,_) :- !.
cosmos_is(Object,Type,Schemas) :- cosmos_object_wrapper(Object),!,arg(2,Object,Fields),cosmos_is(Fields,Type,Schemas).
cosmos_is(conforming(_,protocol(Name,_,_),_),Name,_) :- !.
cosmos_is(conforming(Object,_,_),Type,Schemas) :- !,cosmos_is(Object,Type,Schemas).
cosmos_is(V,"Number",_) :- !,number(V).
cosmos_is(V,"String",_) :- !,string(V).
cosmos_is(V,"Integer",_) :- !,integer(V).
cosmos_is(V,"Real",_) :- !,float(V).
% Cosmos lists may be proper lists or open-tail lists while a relation is
% being assembled.  Both are List values; is_list/1 only recognizes the
% former.
cosmos_is(V,"List",_) :- !,(is_list(V);V=[_|_]).
cosmos_is(V,"Table",_) :- !,is_assoc(V).
cosmos_is(V,"Relation",_) :- !,nonvar(V),V=clos(_,_).
cosmos_is(V,"Host",_) :- !,nonvar(V),V=host(_).
cosmos_is(V,Expected,Schemas) :-
    nonvar(V),functor(V,Tag,_),atom(Tag),atom_concat(fc_,Name,Tag),
    system:atom_string(Name,Actual),cosmos_subtype(Actual,Expected,Schemas),
    (get_assoc(Actual,Schemas,Spec),get_assoc("open",Spec,0.0)->
        get_assoc("fields",Spec,Fields),V=..[_|Args],maplist(cosmos_typed_field(Schemas),Args,Fields)
    ;true).
cosmos_typed_field(Schemas,Value,Type) :- cosmos_is(Value,Type,Schemas).
cosmos_require_type(Value,Type,Schemas) :-
    cosmos_type_constraint(Value,Type,Schemas).
cosmos_type_constraint(_,"Any",_) :- !.
cosmos_type_constraint(Value,Type,Schemas) :- var(Value),!,
    when(nonvar(Value),cosmos_type_constraint(Value,Type,Schemas)).
cosmos_type_constraint(Value,Type,Schemas) :-
    functor(Value,Tag,_),atom(Tag),atom_concat(fc_,Name,Tag),system:atom_string(Name,Actual),
    get_assoc(Actual,Schemas,Spec),get_assoc("open",Spec,0.0),!,
    get_assoc("fields",Spec,Fields),Value=..[_|Args],
    (cosmos_subtype(Actual,Type,Schemas),same_length(Args,Fields)->
        maplist(cosmos_constraint_field(Schemas),Args,Fields)
    ;throw(error(cosmos_type_error(Type,Value),_))).
cosmos_type_constraint(Value,Type,Schemas) :-
    (cosmos_is(Value,Type,Schemas)->true;throw(error(cosmos_type_error(Type,Value),_))).
cosmos_constraint_field(Schemas,Value,Type) :- cosmos_type_constraint(Value,Type,Schemas).
cosmos_subtype(Name,Name,_) :- !.
cosmos_subtype(_,"Functor",_) :- !.
cosmos_subtype(Name,Expected,Schemas) :-
    get_assoc(Name,Schemas,Spec),get_assoc("parent",Spec,Parent),
    cosmos_subtype(Parent,Expected,Schemas).
cosmos_each(Collection,Key,Value) :-
    cosmos_iter_start(Collection,Iterator),cosmos_each_iterator(Iterator,Key,Value).
cosmos_each_iterator(Iterator,Key,Value) :-
    cosmos_iter_next(Iterator,Next,K,V,Status),Status=1.0,
    (Key=K,Value=V;cosmos_each_iterator(Next,Key,Value)).
cosmos_while(Condition,Step,State,Final) :-
    (call_cl(Condition,[State])->call_cl(Step,[State,Next]),cosmos_while(Condition,Step,Next,Final)
    ;Final=State).
cosmos_for(Collection,Step,State,Final) :-
    cosmos_iter_start(Collection,Iterator),cosmos_for_iterator(Iterator,Step,State,Final).
cosmos_for_iterator(Iterator,Step,State,Final) :-
    cosmos_iter_next(Iterator,Next,Key,Value,Status),
    (Status=0.0->Final=State
    ;call_cl(Step,[Key,Value,State,NextState]),cosmos_for_iterator(Next,Step,NextState,Final)).

cosmos_conforms(conforming(Object,_,_),Protocol,Schemas) :- !,cosmos_conforms(Object,Protocol,Schemas).
cosmos_conforms(Object,protocol(_,Fields,Methods),Schemas) :-
    cosmos_record(Object),maplist(cosmos_protocol_field(Object,Schemas),Fields),
    maplist(cosmos_protocol_method_exists(Object),Methods).
cosmos_protocol_field(Object,Schemas,field(Key,Type)) :-
    cosmos_has_field(Object,Key),cosmos_get(Object,Key,Value),cosmos_is(Value,Type,Schemas).
cosmos_protocol_method_exists(Object,method(Key,Specs,_)) :-
    cosmos_has_field(Object,Key),cosmos_get(Object,Key,Closure),
    length(Specs,Arity),cosmos_callable_arity(Closure,Arity).
cosmos_callable_arity(clos(_,Predicate),Arity) :- atom(Predicate),Total is Arity+1,current_predicate(Predicate/Total).
cosmos_callable_arity(method_cl(_,Closure),Arity) :- More is Arity+1,cosmos_callable_arity(Closure,More).
cosmos_record(Object) :- is_assoc(Object),!.
cosmos_record(Object) :- cosmos_object_wrapper(Object),arg(2,Object,Fields),cosmos_record(Fields).
cosmos_has_field(Object,Key) :- is_assoc(Object),!,get_assoc(Key,Object,_).
cosmos_has_field(prototype_object(Prototype,Fields),Key) :- !,
    (get_assoc(Key,Fields,_)->true;cosmos_has_field(Prototype,Key)).
cosmos_has_field(Object,Key) :- cosmos_object_wrapper(Object),arg(2,Object,Fields),cosmos_has_field(Fields,Key).
cosmos_protocol_view(Object,Protocol,Schemas,conforming(Object,Protocol,Schemas)) :-
    (cosmos_conforms(Object,Protocol,Schemas)->true
    ;throw(error(cosmos_protocol_structure(Protocol),_))).
cosmos_protocol_invoke(Object,protocol(Name,_,Methods),Schemas,Key,Args) :-
    cosmos_protocol_requirements(Key,Methods,Required),
    maplist(cosmos_protocol_before(Schemas,Args),Required),
    cosmos_protocol_dispatch(Required,Object,Key,Args),
    maplist(cosmos_protocol_after(Name,Key,Schemas,Args),Required).
cosmos_protocol_requirements(_,[],[]).
cosmos_protocol_requirements(Key,[method(Name,Specs,Contract)|Methods],Required) :-
    cosmos_protocol_requirements(Key,Methods,Tail),
    (Key=Name->Required=[Specs-Contract|Tail];Required=Tail).
cosmos_protocol_before(Schemas,Args,Specs-_) :-
    (maplist(cosmos_input(Schemas),Specs,Args)->true;throw(error(cosmos_protocol_input,_))).
cosmos_protocol_dispatch([_-contract(Kind,Det,_)|_],Object,Key,Args) :- !,
    cosmos_declared_call(Det,Key,Args,cosmos_callable(Kind,Key,cosmos_method(Object,Key,Args))).
cosmos_protocol_dispatch(_,Object,Key,Args) :- cosmos_method(Object,Key,Args).
% Behavioral postconditions are opt-in on typed protocol views. Structural
% conformance (cosmos_conforms/3) never runs a method or its protocol body.
cosmos_protocol_after(Name,Key,Schemas,Args,Specs-Contract) :-
    (maplist(cosmos_output(Schemas),Specs,Args)->true;throw(error(cosmos_protocol_output(Name,Key),_))),
    (nb_current(cosmos_debug_contracts,true)->
        (cosmos_protocol_behavior(Contract,Args)->true;
         throw(error(cosmos_protocol_behavior(Name,Key),_)))
    ;true).
cosmos_protocol_behavior(deferred,_) :- !.
cosmos_protocol_behavior(contract(_,_,Behavior),Args) :- !,
    cosmos_protocol_behavior(Behavior,Args).
cosmos_protocol_behavior(Closure,Args) :-
    copy_term(Closure-Args,Check-Values),once(call_cl(Check,Values)).

cosmos_object_wrapper(Object) :- nonvar(Object),
    (Object=typed(_,_);Object=instance(_,_);Object=cosmos_class(_,_);Object=prototype_object(_,_)).
cosmos_receiver_value(Receiver,clos(Env,Predicate),method_cl(Receiver,clos(Env,Predicate))) :- !.
cosmos_receiver_value(Receiver,method_cl(_,Closure),method_cl(Receiver,Closure)) :- !.
cosmos_receiver_value(_,Value,Value).
cosmos_new(cosmos_class(Name,Prototype),_,Args,instance(Name,Value)) :- !,
    get_assoc("new",Prototype,New),append([cosmos_class(Name,Prototype),Value],Args,All),call_cl(New,All).
cosmos_new(Prototype,Name,Args,typed(Name,Value)) :-
    get_assoc("new",Prototype,New),call_cl(New,[Value|Args]).
cosmos_update(Object,Key,Value,Result) :- cosmos_object_wrapper(Object),!,
    Object=..[Tag,Name,Fields],cosmos_update(Fields,Key,Value,Updated),Result=..[Tag,Name,Updated].
cosmos_update(conforming(Object,Protocol,Schemas),Key,Value,Result) :- !,
    cosmos_update(Object,Key,Value,Updated),cosmos_protocol_view(Updated,Protocol,Schemas,Result).
cosmos_update(Object,Key,Value,Result) :- set_(Object,Key,Value,Result).
