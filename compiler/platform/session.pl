% Revision-scoped lifecycle for compiled Cosmos artifacts.
%
% The current emitter prefixes generated predicates instead of emitting SWI
% modules.  Embedders must therefore allocate a unique Prefix for every
% revision and explicitly dispose it before reusing a session.

:- ensure_loaded(driver).

compiler_session_compile(Stage, Source, Prefix, Code) :-
    compiler_load(Stage),
    cc_query_text(Source, Text),
    compiler_session_prefix(Prefix, Name),
    system:atom_string(Name, Module),
    compiler_compile(Text, Module, Code).

% Compile a goal fragment with an explicit, ordered set of result variables.
% Query remains the compiler's metadata table: module, entry, variables,
% source, and generated Prolog.  The session owns only its generated prefix.
compiler_session_compile_query(Stage, Source, Variables, Prefix, Query) :-
    compiler_load(Stage),
    cc_query_text(Source, Text),
    compiler_session_prefix(Prefix, Name),
    system:atom_string(Name, Module),
    compiler(Api),
    get_(Api, "compile_query", CompileQuery),
    ( once(call_cl(CompileQuery, [Text, Variables, Module, Query])) -> true
    ; throw(error(compilation_failed, _))
    ).

compiler_session_compile_query_file(Stage, Input, Variables, Output, Prefix, Query) :-
    read_file_to_string(Input, Source, []),
    compiler_session_compile_query(Stage, Source, Variables, Prefix, Query),
    getnil(Query, "prolog", Code),
    setup_call_cleanup(
        open(Output, write, Stream, [encoding(utf8), newline(posix)]),
        write(Stream, Code),
        close(Stream)).

compiler_session_compile_file(Stage, Input, Output, Prefix) :-
    read_file_to_string(Input, Source, []),
    compiler_session_compile(Stage, Source, Prefix, Code),
    setup_call_cleanup(
        open(Output, write, Stream, [encoding(utf8), newline(posix)]),
        write(Stream, Code),
        close(Stream)).

compiler_session_entry(Prefix, Output) :-
    compiler_session_prefix(Prefix, Entry),
    Goal =.. [Entry, Output],
    call(Goal).

compiler_session_result(Prefix,Result) :-
    cc_query_result(compiler_session_entry(Prefix),Result).

compiler_session_dispose(Prefix) :-
    compiler_session_prefix(Prefix, NamePrefix),
    findall(Name/Arity,
        ( current_predicate(Name/Arity),
          atom(Name),
          sub_atom(Name, 0, _, _, NamePrefix)
        ),
        Predicates),
    maplist(compiler_session_abolish, Predicates).

compiler_session_abolish(Name/Arity) :-
    catch(abolish(Name/Arity), _, true).

compiler_session_prefix(Prefix, Name) :-
    ( string(Prefix) -> system:atom_string(Name, Prefix)
    ; atom(Prefix) -> Name = Prefix
    ; throw(error(type_error(atom_or_string, Prefix), _))
    ),
    ( sub_atom(Name, 0, 7, _, cosmos_) -> true
    ; throw(error(domain_error(cosmos_session_prefix, Name), _))
    ).
