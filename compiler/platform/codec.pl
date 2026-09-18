% Explicit transport values: never guess whether a number list is text.
cc_encode_value(Value,Wire) :-
    (acyclic_term(Value)->true;throw(error(representation_error(cyclic_value),_))),
    copy_term(Value,Copy),numbervars(Copy,0,_),cc_encode_ground(Copy,Wire).
cc_encode_ground('$VAR'(Id),_{type:"variable",id:Id}) :- !.
cc_encode_ground(Value,_{type:"string",value:Value}) :- string(Value),!.
cc_encode_ground(Value,_{type:"integer",value:Text}) :-
    integer(Value),abs(Value)>9007199254740991,!,number_string(Value,Text).
cc_encode_ground(Value,_{type:"rational",numerator:N,denominator:D}) :-
    rational(Value),\+ integer(Value),!,Num is numerator(Value),Den is denominator(Value),
    number_string(Num,N),number_string(Den,D).
cc_encode_ground(Value,_{type:"number",value:Value}) :- number(Value),!.
cc_encode_ground(Value,_{type:"list",items:Items}) :- is_list(Value),!,maplist(cc_encode_ground,Value,Items).
cc_encode_ground(Value,_{type:"table",entries:Entries}) :- is_assoc(Value),!,
    assoc_to_list(Value,Pairs),maplist(cc_encode_pair,Pairs,Entries).
cc_encode_ground(Value,_{type:"atom",value:Text}) :- atom(Value),!,system:atom_string(Value,Text).
cc_encode_ground(Value,_{type:"functor",name:Text,args:Args}) :-
    compound_name_arguments(Value,Name,Values),system:atom_string(Name,Text),
    maplist(cc_encode_ground,Values,Args).
cc_encode_pair(Key-Value,_{key:K,value:V}) :- cc_encode_ground(Key,K),cc_encode_ground(Value,V).

% One answer is a success even when its exported value is []. Exceptions and
% logical failure have different tags, including errors during serialization.
:- meta_predicate cc_query_result(1,-).
cc_query_result(Closure,Result) :-
    catch((once(call(Closure,Value)) -> cc_encode_value(Value,Wire),Result=_{status:"success",value:Wire}
          ; Result=_{status:"failure"}),
          Error,(term_string(Error,Message,[quoted(true)]),Result=_{status:"error",message:Message})).
