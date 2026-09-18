% File/platform adapter for the compiler whose implementation lives in .co.
:- dynamic compiler_platform_runtime_loaded/0.

compiler_platform(Here) :- source_file(compiler_platform(_),File),file_directory_name(File,Here).
compiler_file_module(Path,Module) :-
    absolute_file_name(Path,Absolute),file_base_name(Absolute,Base),file_name_extension(Module,_,Base).
compiler_load(Stage) :-
    compiler_load_runtime,
    compiler_platform(Here),
    directory_file_path(Stage,'?',Template),
    directory_file_path(Here,'../../libs/?',Libraries),
    atomic_list_concat([Template,Libraries],';',Path),nb_setval(path,Path),
    crequire("compiler",_,_).
compiler_load_runtime :- compiler_platform_runtime_loaded, !.
compiler_load_runtime :-
    compiler_platform(Here),
    directory_file_path(Here,'../../src/swi.pl',Runtime),consult(Runtime),
    directory_file_path(Here,'terms.pl',Terms),consult(Terms),
    directory_file_path(Here,'runtime.pl',Operations),consult(Operations),
    directory_file_path(Here,'codec.pl',Codec),consult(Codec),
    assertz(compiler_platform_runtime_loaded).
compiler_compile(Source,Module,Code) :-
    compiler(Api),get_(Api,"compile",Compile),
    (once(call_cl(Compile,[Source,Module,Code])) -> true
    ; throw(error(compilation_failed,_))).
compiler_compile_file(Stage,Input,Output,Module) :-
    compiler_load(Stage),read_file_to_string(Input,Source,[]),
    system:atom_string(Module,Name),
    compiler(Api),
    (get_assoc("compile_unit",Api,CompileUnit)->
        get_assoc("imports",Api,Imports),once(call_cl(Imports,[Source,Names])),
        absolute_file_name(Input,Absolute),file_directory_name(Absolute,Directory),
        compiler_read_interfaces(Names,Directory,Pairs),list_to_assoc(Pairs,Interfaces),
        (once(call_cl(CompileUnit,[Source,Name,Interfaces,Unit]))->true;throw(error(compilation_failed,_))),
        get_assoc("prolog",Unit,Code),get_assoc("interface",Unit,Interface)
    ;compiler_compile(Source,Name,Code),Interface=none),
    setup_call_cleanup(open(Output,write,Stream,[encoding(utf8),newline(posix)]),
                       write(Stream,Code),close(Stream)),
    (Interface==none->true;
        file_name_extension(Base,_,Output),file_name_extension(Base,cif,InterfaceFile),
        setup_call_cleanup(open(InterfaceFile,write,Stream2,[encoding(utf8),newline(posix)]),
            write_term(Stream2,Interface,[quoted(true),fullstop(true),nl(true)]),close(Stream2))).

% Data-only sidecars. No consult/1, directives, or imported application execution.
compiler_read_interfaces(Names,Directory,Pairs) :-
    sort(Names,Unique),compiler_read_interfaces_sorted(Unique,Directory,Pairs).
compiler_read_interfaces_sorted([],_,[]).
compiler_read_interfaces_sorted([Name|Names],Directory,Pairs) :-
    string_concat(Name,".cif",Relative),directory_file_path(Directory,Relative,File),
    (exists_file(File)->
        setup_call_cleanup(open(File,read,Stream,[encoding(utf8)]),
            (read_term(Stream,Unit,[]),read_term(Stream,End,[])),close(Stream)),
        (End==end_of_file,ground(Unit),is_assoc(Unit),get_assoc("format",Unit,Format),number(Format),Format=:=1,
         get_assoc("schemas",Unit,Schemas),is_assoc(Schemas),get_assoc("exports",Unit,Exports),is_assoc(Exports)
        ->Pairs=[Name-Unit|Tail]
        ;throw(error(domain_error(cosmos_interface,File),_)))
    ;Pairs=Tail),
    compiler_read_interfaces_sorted(Names,Directory,Tail).
compiler_report(fc_ParseError(Message,[fc_Token(_,_,Line,Column)|_])) :- !,
    format(user_error,'Parse error at ~g:~g: ~s~n',[Line,Column,Message]).
compiler_report(fc_ParseError(Message,Expected,[fc_Token(_,_,Line,Column)|_])) :- !,
    format(user_error,'Parse error at ~g:~g: ~s (expected ~s)~n',[Line,Column,Message,Expected]).
compiler_report(fc_CompileError(Message,fc_Loc(Line,Column))) :- !,
    format(user_error,'Compile error at ~g:~g: ~s~n',[Line,Column,Message]).
compiler_report(Message) :- string(Message),!,format(user_error,'Compile error: ~s~n',[Message]).
compiler_report(Error) :- print_message(error,Error).
