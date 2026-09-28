:- initialization(main,main).
main :- catch((run -> writeln('Compiler semantics passed') ; throw(test_failed)),E,
              (print_message(error,E),halt(1))).
run :-
 consult('compiler/swi.pl'),consult('compiler/platform/runtime.pl'),
 consult('tests/compiler/semantics.pl'),semantics(Api),
 get_(Api,"run",Run),once(call_cl(Run,[])),
 get_(Api,"alternatives",Alternatives),findall(X,call_cl(Alternatives,[X]),[1.0,2.0]),
 get_(Api,"clauses",Clauses),findall(Y,call_cl(Clauses,[Y]),[1.0,2.0]),
 get_(Api,"reject",Reject),\+ call_cl(Reject,[]),
 consult('tests/compiler/host.pl'),host(host(1)),
 host_assignment("@cosmos-host:1","canvas","@cosmos-host:2").
:- multifile cosmos_host_op/3.
:- dynamic host_assignment/3.
cosmos_host_op("root",["js","space"],"@cosmos-host:1").
cosmos_host_op("root",["js","canvas"],"@cosmos-host:2").
cosmos_host_op("set",[Id,Key,Value],true) :- assertz(host_assignment(Id,Key,Value)).
