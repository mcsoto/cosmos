% Cosmos execution profiler.
%
% Answers one question: where does a compiled Cosmos program spend its
% time?  The measurement uses the sampling profiler that is built into
% SWI-Prolog (the machinery behind library(prolog_profile)), which keeps
% the distortion low enough that the program still behaves like itself.
%
% Two things are added on top of the raw sampler:
%
%   - A frame hook.  A Space/XPCE program runs until its window is
%     closed, so a report can only be taken from inside the loop.  The
%     Space backend calls space_profile_frame/1 once per frame; the
%     profiler counts the frames and writes the report every
%     --profile-frames frames (300 by default), so the report on disk is
%     always the most recent snapshot and the program never has to stop
%     to be inspected.
%
%   - A split by category.  "The game is slow" is not actionable.
%     "The game spends half of its time creating XPCE rectangles" is.
%     The report therefore separates the Cosmos program itself, the XPCE
%     backend it runs on, the Cosmos runtime, and the SWI-Prolog
%     machinery underneath.
%
% Usage:
%
%   cosmos -l misc/dungeon.co --xpce --profile
%   cosmos -r test4 --xpce --profile --profile-out test4.profile.txt
%   cosmos -l misc/dungeon.co --xpce --profile --profile-frames 600
%
% Options (all optional):
%
%   --profile               turn the profiler on
%   --profile-out FILE      report file (default cosmos_profile.txt)
%   --profile-frames N      report every N frames (default 300)
%   --profile-seconds N     report once, N seconds into the run
%   --profile-top N         predicates listed per table (default 25)
%
% The profiler is loaded by the generated entry point (see driver.pl) and
% started there, so the same run works through `cosmos -l`, `cosmos -r`
% and a bare `swipl -s program.pl` as long as cosmos_profile_requested
% is set before the program starts.

:- module(cosmos_profile,
          [ cosmos_profile_start/0,
            cosmos_profile_stop/1,
            cosmos_profile_frame/1,
            cosmos_profile_write/1,
            cosmos_profile_render/3,
            cosmos_profile_collect/1
          ]).

:- use_module(library(lists)).
:- use_module(library(assoc)).

% The sampler is driven through the kernel's own profiling primitives
% rather than through library(prolog_profile): the library is an
% autoloaded module and the saved cosmos.exe is built with autoload
% disabled, so a library that is not embedded in the image cannot be
% loaded at run time.  These three primitives are built into the
% kernel and are therefore always available:
%
%   profiler(Old, Enabled)          enable/disable the sampler
%   '$prof_statistics'(-,-,-,-,-,-,-)  overall counters
%   prolog_statistics:profile_procedure_data/2  per predicate data
%
% The library is only a presentation layer over exactly these, so the
% report below is the same measurement with a Cosmos-shaped summary.

% ---------------------------------------------------------------- state
%
% Everything lives in non-backtrackable globals: the profiler runs inside
% a frame callback, so it must not leave choice points behind and must
% not be undone by a backtrack into the frame.

:- initialization(cosmos_profile_defaults).

% The defaults never overwrite a value the command line already set: the
% module is loaded by the generated entry point, which runs after the
% launcher has configured the run.
cosmos_profile_defaults :-
    cosmos_profile_default(cosmos_profile_frames, 0),
    cosmos_profile_default(cosmos_profile_dump_frames, 300),
    cosmos_profile_default(cosmos_profile_seconds, 0),
    cosmos_profile_default(cosmos_profile_out, 'cosmos_profile.txt'),
    cosmos_profile_default(cosmos_profile_top, 25),
    cosmos_profile_default(cosmos_profile_module, user),
    cosmos_profile_default(cosmos_profile_program, ''),
    cosmos_profile_default(cosmos_profile_source, ''),
    cosmos_profile_default(cosmos_profile_target, ''),
    cosmos_profile_default(cosmos_profile_compile_ms, 0).

cosmos_profile_default(Key, Value) :-
    (   nb_current(Key, _)
    ->  true
    ;   nb_setval(Key, Value)
    ).

% ---------------------------------------------------------------- start/stop

% Enable the sampler in the thread that runs the program.  The profiler
% data is per thread (a watchdog thread cannot read it), so this has to
% happen on the thread that ends up in the Space event loop.
cosmos_profile_start :-
    (   nb_current(cosmos_profile_active, true)
    ->  true
    ;   nb_setval(cosmos_profile_active, true),
        get_time(Start),
        nb_setval(cosmos_profile_start_time, Start),
        nb_setval(cosmos_profile_frames, 0),
        profiler(Old, true),
        nb_setval(cosmos_profile_profiler_state, Old),
        cosmos_profile_install_hook
    ).

% Restore the sampler state and write the final report.  Reason is free
% text for the report header.
cosmos_profile_stop(Reason) :-
    (   nb_current(cosmos_profile_active, true)
    ->  nb_setval(cosmos_profile_active, false),
        (   nb_getval(cosmos_profile_profiler_state, Old)
        ->  profiler(_, Old)
        ;   true
        ),
        catch(cosmos_profile_write(stop(Reason)), _, true)
    ;   true
    ).

% Install the per-frame hook.  The clause is asserted in front of the
% Space backend's no-op default so the profiler sees every frame; the
% install is guarded because the hook must not be counted twice.  The
% body is module qualified: an asserted clause runs in the module of the
% predicate it was added to, which is `user' for the backend.
cosmos_profile_install_hook :-
    (   nb_current(cosmos_profile_hook_installed, true)
    ->  true
    ;   nb_setval(cosmos_profile_hook_installed, true),
        catch(asserta((user:space_profile_frame(Prefix) :-
                          cosmos_profile:cosmos_profile_frame(Prefix))), _, true)
    ).

% ---------------------------------------------------------------- frame hook
%
% Called once per frame by the Space backend.  It must never fail and
% must never raise: a failure here would take the whole frame down.

cosmos_profile_frame(_Prefix) :-
    catch(cosmos_profile_tick, _, true).

cosmos_profile_tick :-
    cosmos_profile_value(cosmos_profile_frames, 0, Frames),
    Next is Frames + 1,
    nb_setval(cosmos_profile_frames, Next),
    cosmos_profile_value(cosmos_profile_dump_frames, 300, Interval),
    (   Interval > 0,
        0 is Next mod Interval
    ->  catch(cosmos_profile_write(frame(Next)), _, true)
    ;   true
    ),
    cosmos_profile_tick_time(Next).

% A value with a fallback.  nb_getval/2 fails when the key is not there,
% and a failure in the frame hook would stop the frame from being
% counted at all.
cosmos_profile_value(Key, Default, Value) :-
    (   nb_getval(Key, Found)
    ->  Value = Found
    ;   Value = Default
    ).

% The same report, triggered by wall clock instead of by frame count.
% A frame budget is the more useful unit for a program that runs at a
% fixed rate, but a program whose frames get slow needs a time budget.
% It fires once: writing a report is itself work, and a report that
% re-writes itself on every frame would measure the measurement.
cosmos_profile_tick_time(Frames) :-
    cosmos_profile_value(cosmos_profile_seconds, 0, Seconds),
    (   Seconds > 0,
        \+ nb_current(cosmos_profile_seconds_fired, true)
    ->  get_time(Now),
        cosmos_profile_value(cosmos_profile_start_time, Now, Start),
        Elapsed is Now - Start,
        (   Elapsed >= Seconds
        ->  nb_setval(cosmos_profile_seconds_fired, true),
            catch(cosmos_profile_write(seconds(Frames, Elapsed)), _, true)
        ;   true
        )
    ;   true
    ).

% ---------------------------------------------------------------- the report

% Collect the samples, aggregate them per predicate and write the report.
cosmos_profile_write(Reason) :-
    cosmos_profile_collect(Profile),
    cosmos_profile_render(Profile, Reason, Text),
    cosmos_profile_output(Text).

% Gather the profile data.  Collection suspends the sampler, exactly as
% library(prolog_profile) does, so the numbers are not distorted by the
% act of reading them.
cosmos_profile_collect(Profile) :-
    setup_call_cleanup(
        profiler(Old, false),
        (   '$prof_statistics'(Samples, Ticks, Accounting, Time, Nodes,
                               Period, Ports),
            findall(node{predicate:Pred,
                         ticks_self:Self,
                         ticks_siblings:Siblings,
                         call:Calls},
                    (   prolog_statistics:profile_procedure_data(_:_, Node),
                        Node.predicate = Pred,
                        Node.ticks_self = Self,
                        Node.ticks_siblings = Siblings,
                        Node.call = Calls
                    ),
                    PredicateNodes)
        ),
        profiler(_, Old)),
    Profile = profile{
        summary: summary{samples:Samples, ticks:Ticks, accounting:Accounting,
                         time:Time, nodes:Nodes, sample_period:Period,
                         ports:Ports},
        nodes: PredicateNodes
    }.

% Write through a temporary file and rename, so a reader never sees a
% half-written report: the program keeps running while it is written.
cosmos_profile_output(Text) :-
    nb_getval(cosmos_profile_out, File),
    atom_concat(File, '.tmp', Temp),
    setup_call_cleanup(
        open(Temp, write, Stream, [encoding(utf8)]),
        ( write(Stream, Text),
          close(Stream),
          catch(rename_file(Temp, File), _, true)
        ),
        catch(close(Stream), _, true)
    ).

cosmos_profile_render(Data, Reason, Text) :-
    Data.summary = Summary,
    Data.nodes = Nodes,
    cosmos_profile_aggregate(Nodes, Entries),
    cosmos_profile_scale(Summary, Scale),
    cosmos_profile_categories(Entries, Categories),
    cosmos_profile_header(Summary, Scale, Reason, Header),
    cosmos_profile_category_table(Categories, Scale, CategoryTable),
    cosmos_profile_predicate_table(Entries, Scale, self, PredicateTable),
    cosmos_profile_predicate_table(Entries, Scale, calls, CallTable),
    string_concat(Header, CategoryTable, Part),
    string_concat(Part, PredicateTable, Part2),
    string_concat(Part2, CallTable, Text).
% Ticks are milliseconds on the Windows sampler and virtual ticks on the
% POSIX one; the scale converts both to milliseconds.
cosmos_profile_scale(Summary, Scale) :-
    Summary.ticks = Ticks,
    Summary.time = Time,
    (   Ticks > 0
    ->  Scale is 1000.0 * Time / Ticks
    ;   Scale is 1.0
    ).

cosmos_profile_header(Summary, Scale, Reason, Header) :-
    nb_getval(cosmos_profile_program, Program),
    nb_getval(cosmos_profile_source, Source),
    nb_getval(cosmos_profile_target, Target),
    nb_getval(cosmos_profile_compile_ms, CompileMs),
    nb_getval(cosmos_profile_module, Module),
    nb_getval(cosmos_profile_start_time, Start),
    get_time(Now),
    Elapsed is Now - Start,
    nb_getval(cosmos_profile_frames, Frames),
    statistics(inferences, Inferences),
    Summary.samples = Samples,
    Summary.ticks = Ticks,
    Summary.time = Sampled,
    SampledMs is Sampled * 1000.0,
    (   Frames > 0
    ->  PerFrame is SampledMs / Frames
    ;   PerFrame = 0.0
    ),
    format(string(Bar), '~w~n', ['================================================================']),
    format(string(Rule), '~w~n', ['----------------------------------------------------------------']),
    format(string(Head), '~w Cosmos profile -- ~w~n~w', [Bar, Program, Rule]),
    format(string(L1), ' program     : ~w', [Program]),
    format(string(L1b), ' module      : ~w', [Module]),
    format(string(L2), ' source      : ~w', [Source]),
    format(string(L3), ' generated   : ~w', [Target]),
    format(string(L4), ' compiled in : ~w ms', [CompileMs]),
    format(string(L5), ' profiled    : ~w frames, ~2f s wall, ~w inferences',
           [Frames, Elapsed, Inferences]),
    format(string(L6), ' sampler     : ~w samples, ~w ticks, ~2f ms sampled (~2f ms/tick, ~2f ms/frame)',
           [Samples, Ticks, SampledMs, Scale, PerFrame]),
    format(string(L7), ' report      : ~w', [Reason]),
    atomic_list_concat([L1, L1b, L2, L3, L4, L5, L6, L7, Rule], '\n', Body),
    string_concat(Head, Body, Header).

% --- aggregation ----------------------------------------------------------

cosmos_profile_aggregate(Nodes, Entries) :-
    list_to_assoc([], Empty),
    foldl(cosmos_profile_add, Nodes, Empty, Assoc),
    assoc_to_list(Assoc, Pairs),
    maplist(cosmos_profile_entry, Pairs, Entries).

cosmos_profile_add(Node, Assoc0, Assoc) :-
    PI = Node.predicate,
    (   get_assoc(PI, Assoc0, entry(Calls0, Self0, Siblings0))
    ->  true
    ;   Calls0 = 0, Self0 = 0, Siblings0 = 0
    ),
    Calls is Calls0 + Node.call,
    Self is Self0 + Node.ticks_self,
    Siblings is Siblings0 + Node.ticks_siblings,
    put_assoc(PI, Assoc0, entry(Calls, Self, Siblings), Assoc).
cosmos_profile_entry(PI-Value, entry(PI, Category, Calls, Self, Siblings)) :-
    Value = entry(Calls, Self, Siblings),
    cosmos_profile_category(PI, Category).

% --- categories -----------------------------------------------------------

% The Cosmos compiler does not emit SWI modules: it prefixes the
% predicates with the module they belong to (`test4::update/4'), so
% that prefix is what tells a program predicate from a library one.
% The Space backend lives in `user' with a space_ prefix, library(pce)
% is the XPCE core, and cosmos_ predicates are the runtime that sits
% between the generated code and the backend.
cosmos_profile_category(PI, Category) :-
    cosmos_profile_split(PI, Module, Name),
    (   sub_atom(Name, Before, _, _, '::')
    ->  Cosmos = Before
    ;   Cosmos = ''
    ),
    nb_getval(cosmos_profile_module, Program),
    (   Module == cosmos_profile
    ->  % The measurement itself.  It is reported as its own category:
        % it is the cost of looking at the program, not the cost of the
        % program, and mixing the two makes both unreadable.
        Category = profiler
    ;   Cosmos == Program
    ->  Category = program
    ;   Cosmos == 'space'
    ->  Category = 'space bridge'
    ;   Cosmos \== ''
    ->  Category = 'cosmos library'
    ;   cosmos_profile_prefix(Name, 'space_')
    ->  Category = 'space backend'
    ;   Module == pce
    ->  Category = 'xpce core'
    ;   cosmos_profile_prefix(Name, 'cosmos_')
    ->  Category = 'cosmos runtime'
    ;   Module == system
    ->  Category = 'swi system'
    ;   Module == user
    ->  Category = host
    ;   Module == ''
    ->  Category = host
    ;   Category = 'swi library'
    ).

cosmos_profile_prefix(Name, Prefix) :-
    atom_concat(Prefix, _, Name).

cosmos_profile_split(PI, Module, Name) :-
    (   PI = M:N/_
    ->  Module = M, Name = N
    ;   PI = N/_
    ->  Module = '', Name = N
    ;   Module = '', Name = PI
    ).

cosmos_profile_categories(Entries, Categories) :-
    findall(Category-entry(Calls, Self),
            (   member(entry(_PI, Category, Calls, Self, _Siblings), Entries)
            ),
            Pairs),
    list_to_assoc([], Empty),
    foldl(cosmos_profile_category_add, Pairs, Empty, Assoc),
    assoc_to_list(Assoc, Ordered),
    maplist(cosmos_profile_category_pair, Ordered, List),
    predsort(cosmos_profile_by_self, List, Categories).

cosmos_profile_category_pair(Category-entry(Calls, Self), Category-entry(Calls, Self)).

% Descending by self time.
cosmos_profile_by_self(Order, _C1-entry(_, Self1), _C2-entry(_, Self2)) :-
    compare(Order, Self2, Self1).

cosmos_profile_category_add(Category-entry(Calls, Self), Assoc0, Assoc) :-
    (   get_assoc(Category, Assoc0, entry(C0, S0))
    ->  true
    ;   C0 = 0, S0 = 0
    ),
    C is C0 + Calls,
    S is S0 + Self,
    put_assoc(Category, Assoc0, entry(C, S), Assoc).

% --- tables ---------------------------------------------------------------
%
% A table is a title, a list of headers, a list of alignments (left or
% right) per column and a list of rows (each row a list of cells).  The
% column widths are derived from the content.

cosmos_profile_category_table(Categories, Scale, Table) :-
    foldl(cosmos_profile_category_total, Categories, 0, Total),
    findall([Category, Calls, Ms, Percent],
            (   member(Category-entry(Calls, Self), Categories),
                Ms is Self * Scale,
                (   Total > 0
                ->  Percent is 100.0 * Self / Total
                ;   Percent = 0.0
                )
            ),
            Rows),
    cosmos_profile_table(
        ' Time by category',
        [ 'category', 'calls', 'self ms', '%' ],
        [ left, right, right, right ],
        Rows,
        Table).

cosmos_profile_category_total(_Category-entry(_Calls, Self), Total0, Total) :-
    Total is Total0 + Self.

% The predicate tables leave out the profiler's own predicates: they
% are the cost of measuring, not of the program, and they would
% otherwise fill the table.  The percentages are relative to the time
% that is left, so they still add up to 100.
cosmos_profile_predicate_table(Entries, Scale, Sort, Table) :-
    findall(entry(PI, Calls, Ms),
            (   member(entry(PI, Category, Calls, Self, _Siblings), Entries),
                Category \== profiler,
                Ms is Self * Scale
            ),
            Measured),
    foldl(cosmos_profile_predicate_total, Measured, 0, Total),
    findall(entry(PI, Calls, Ms, Percent),
            (   member(entry(PI, Calls, Ms), Measured),
                (   Total > 0
                ->  Percent is 100.0 * Ms / Total
                ;   Percent = 0.0
                )
            ),
            Rows0),
    (   Sort == self
    ->  Title = ' Hot predicates (self time)',
        predsort(cosmos_profile_by_ms, Rows0, Sorted)
    ;   Title = ' Most called predicates',
        predsort(cosmos_profile_by_calls, Rows0, Sorted)
    ),
    maplist(cosmos_profile_predicate_row, Sorted, TableRows),
    cosmos_profile_table(
        Title,
        [ 'predicate', 'calls', 'self ms', '%' ],
        [ left, right, right, right ],
        TableRows,
        Table).

% Descending by self time, then by call count.
cosmos_profile_by_ms(Order, entry(_P1, C1, M1, _), entry(_P2, C2, M2, _)) :-
    (   compare(=, M1, M2)
    ->  compare(Order, C2, C1)
    ;   compare(Order, M2, M1)
    ).

% Descending by call count, then by self time.
cosmos_profile_by_calls(Order, entry(_P1, C1, M1, _), entry(_P2, C2, M2, _)) :-
    (   compare(=, C1, C2)
    ->  compare(Order, M2, M1)
    ;   compare(Order, C2, C1)
    ).

cosmos_profile_predicate_row(entry(PI, Calls, Ms, Percent),
                             [ PI, Calls, Ms, Percent ]).

cosmos_profile_predicate_total(entry(_PI, _Calls, Ms), Total0, Total) :-
    Total is Total0 + Ms.

% The table writer.  Cells are formatted first, then padded to the
% column width so the numbers line up.
cosmos_profile_table(Title, Headers, Aligns, Rows0, Table) :-
    nb_getval(cosmos_profile_top, Top),
    length(Rows0, Total),
    (   Top > 0, Total > Top
    ->  % Keep the first Top rows.  The split has to be made against
        % Rows0, otherwise Keep stays a list of fresh variables.
        length(Keep, Top),
        append(Keep, _, Rows0),
        Rows = Keep,
        Extra is Total - Top
    ;   Rows = Rows0,
        Extra = 0
    ),
    cosmos_profile_cell_texts(Rows, Aligns, TextRows),
    cosmos_profile_header_texts(Headers, HeaderText),
    cosmos_profile_widths(HeaderText, TextRows, Widths),
    format(string(Head), '~w~n', [Title]),
    format(string(Rule), '~w~n', ['------------------------------------------------------------------------']),
    cosmos_profile_row(HeaderText, Aligns, Widths, HeadRow),
    format(string(HeadRowText), '~w~n', [HeadRow]),
    string_concat(Head, Rule, Part),
    string_concat(Part, HeadRowText, Part2),
    foldl(cosmos_profile_table_row(Aligns, Widths), TextRows, Part2, Part3),
    (   Extra > 0
    ->  format(string(Foot), ' ... and ~w more~n', [Extra]),
        string_concat(Part3, Foot, Table)
    ;   Table = Part3
    ).

cosmos_profile_header_texts(Headers, Texts) :-
    maplist(cosmos_profile_atom_text, Headers, Texts).

cosmos_profile_atom_text(Atom, Text) :-
    (   atom(Atom)
    ->  atom_string(Atom, Text)
    ;   string(Atom)
    ->  Text = Atom
    ;   term_to_atom(Atom, Text)
    ).

cosmos_profile_cell_texts([], _Aligns, []).
cosmos_profile_cell_texts([Row|Rows], Aligns, [Text|Texts]) :-
    cosmos_profile_row_texts(Row, Aligns, Text),
    cosmos_profile_cell_texts(Rows, Aligns, Texts).

cosmos_profile_row_texts([], [], []).
cosmos_profile_row_texts([Cell|Cells], [_Align|Aligns], [Text|Texts]) :-
    cosmos_profile_cell_text(Cell, Text),
    cosmos_profile_row_texts(Cells, Aligns, Texts).

cosmos_profile_cell_text(Cell, Text) :-
    (   number(Cell)
    ->  (   integer(Cell)
        ->  format(string(Text), '~d', [Cell])
        ;   format(string(Text), '~1f', [Cell])
        )
    ;   atom(Cell)
    ->  atom_string(Cell, Text)
    ;   string(Cell)
    ->  Text = Cell
    ;   term_to_atom(Cell, Text)
    ).

% Column widths: the widest cell in the column, header included.
% Column widths: the widest cell in the column, header included.
cosmos_profile_widths(Headers, TextRows, Widths) :-
    findall(W, ( member(H, Headers), string_length(H, W) ), HeaderWidths),
    cosmos_profile_merge_widths(HeaderWidths, TextRows, Widths).

cosmos_profile_merge_widths(Widths, [], Widths).
cosmos_profile_merge_widths(Widths, [Row|Rows], Out) :-
    findall(W, ( member(C, Row), string_length(C, W) ), CellWidths),
    cosmos_profile_pair_max(Widths, CellWidths, Merged),
    cosmos_profile_merge_widths(Merged, Rows, Out).

cosmos_profile_pair_max([], [], []).
cosmos_profile_pair_max([H|Hs], [C|Cs], [W|Ws]) :-
    (   H >= C
    ->  W = H
    ;   W = C
    ),
    cosmos_profile_pair_max(Hs, Cs, Ws).

cosmos_profile_table_row(Aligns, Widths, Row, Acc0, Acc) :-
    cosmos_profile_row(Row, Aligns, Widths, Line),
    format(string(LineText), '~w~n', [Line]),
    string_concat(Acc0, LineText, Acc).

% One rendered row.  A left aligned column is padded on the right, a
% right aligned column on the left, which is what makes the numbers
% readable.
cosmos_profile_row(Cells, Aligns, Widths, Text) :-
    cosmos_profile_pad_cells(Cells, Aligns, Widths, Padded),
    atomic_list_concat(Padded, '  ', Text).

cosmos_profile_pad_cells([], [], [], []).
cosmos_profile_pad_cells([Cell|Cells], [Align|Aligns], [Width|Widths], [Padded|Paddeds]) :-
    string_length(Cell, Length),
    Pad is Width - Length,
    (   Pad < 0
    ->  Pad = 0
    ;   true
    ),
    cosmos_profile_blanks(Pad, Blanks),
    (   Align == left
    ->  atomic_list_concat([Cell, Blanks], Padded)
    ;   atomic_list_concat([Blanks, Cell], Padded)
    ),
    cosmos_profile_pad_cells(Cells, Aligns, Widths, Paddeds).

% A run of spaces.  SWI has no fill_blanks/2 in this installation, and
% the widths are small, so the run is built directly.
cosmos_profile_blanks(0, '') :- !.
cosmos_profile_blanks(N, Blanks) :-
    N > 0,
    Rest is N - 1,
    cosmos_profile_blanks(Rest, Tail),
    string_concat(" ", Tail, Blanks).
