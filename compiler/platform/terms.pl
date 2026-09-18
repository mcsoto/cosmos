% Generic platform operations. All compiler policy lives in compiler/src/*.co.
% These helpers construct/inspect Prolog terms, serialize them, and own cells.
cc_atom(Text,Atom) :- system:atom_string(Atom,Text).
cc_term(Name,Args,Term) :- system:atom_string(Atom,Name),
    (Args=[] -> Term=Atom ; compound_name_arguments(Term,Atom,Args)).
cc_parts(Term,Name,Args) :- compound(Term),!,compound_name_arguments(Term,Atom,Args),system:atom_string(Atom,Name).
cc_parts(Term,Name,[]) :- atom(Term),system:atom_string(Term,Name).
cc_cell(Value,cell(Value)).
cc_cell_get(cell(Value),Value).
cc_cell_set(Cell,Value) :- nb_setarg(1,Cell,Value).
cc_variable(_).
% Turn a Cosmos fragment and its explicitly selected variables into normal
% compiler input.  Keeping this small string boundary in the platform avoids
% making the compiler AST depend on an editor/query transport representation.
cc_compile_query(Source0, Names0, Module0, Code) :-
    cc_query_text(Source0, Source),
    (is_list(Names0)->true;throw(error(type_error(list,Names0),_))),
    maplist(cc_query_variable, Names0, Names),
    cc_query_text(Module0, Module),
    system:atomic_list_concat(Names, ',', SelectedAtom),
    system:atom_string(SelectedAtom, Selected),
    system:string_concat(Source, '\nexport([', BeforeExport),
    system:string_concat(BeforeExport, Selected, WithNames),
    system:string_concat(WithNames, '])\n', QuerySource),
    compiler_compile(QuerySource, Module, Code).
cc_query_variable(Name0, Name) :-
    cc_query_text(Name0, Name),
    system:string_codes(Name, [First|Rest]),
    cc_query_identifier_start(First),
    maplist(cc_query_identifier_continue, Rest).
cc_query_variable(Name, _) :-
    throw(error(domain_error(cosmos_query_variable, Name), _)).
% Source-text arguments explicitly accept legacy code lists as well as SWI
% strings and atoms. General values use codec.pl and never infer text from lists.
cc_query_text(Value, Text) :- string(Value), !, Text = Value.
cc_query_text(Value, Text) :- atom(Value), !, system:atom_string(Value, Text).
cc_query_text(Value, Text) :- is_list(Value), !, system:string_codes(Text, Value).
cc_query_text(Value, _) :- throw(error(type_error(text,Value),_)).
cc_query_identifier_start(Code) :- code_type(Code, csymf).
cc_query_identifier_start(0'_).
cc_query_identifier_continue(Code) :- code_type(Code, csym).
cc_write_clauses(Clauses,Text) :-
    with_output_to(string(Text),maplist(cc_write_clause,Clauses)).
cc_write_clause(Clause) :- copy_term(Clause,C),numbervars(C,0,_),
    write_term(C,[quoted(true),numbervars(true),fullstop(true),nl(true)]).
