% Cygwin ncurses terminal library for Cosmos.
%
% The exported table is available as:
%   require('ncurses', ncurses)
%
% This DLL must be loaded by Cygwin-native SWI-Prolog; it is not compatible
% with the regular Windows SWI-Prolog runtime.
:- use_module(library(shlib)).
:- initialization(cosmos_ncurses_load).

cosmos_ncurses_load :-
    source_file(cosmos_ncurses_load, Source),
    file_directory_name(Source, Directory),
    directory_file_path(Directory, 'ncurses/native/cosmos_ncurses.dll', Library),
    use_foreign_library(Library).

ncurses(Value) :-
    new(Empty),
    set_(Empty, "init", clos(upvals([]), ncurses_init_cl), A),
    set_(A, "close", clos(upvals([]), ncurses_close_cl), B),
    set_(B, "clear", clos(upvals([]), ncurses_clear_cl), C),
    set_(C, "refresh", clos(upvals([]), ncurses_refresh_cl), D),
    set_(D, "move", clos(upvals([]), ncurses_move_cl), E),
    set_(E, "write", clos(upvals([]), ncurses_write_cl), F),
    set_(F, "printAt", clos(upvals([]), ncurses_print_at_cl), G),
    set_(G, "getch", clos(upvals([]), ncurses_getch_cl), H),
    set_(H, "nodelay", clos(upvals([]), ncurses_nodelay_cl), Value).

ncurses_init_cl(upvals([])) :- ncurses_init.
ncurses_close_cl(upvals([])) :- ncurses_close.
ncurses_clear_cl(upvals([])) :- ncurses_clear.
ncurses_refresh_cl(upvals([])) :- ncurses_refresh.
ncurses_move_cl(Row, Column, upvals([])) :- ncurses_move(Row, Column).
ncurses_write_cl(Text, upvals([])) :- ncurses_write(Text).
ncurses_print_at_cl(Row, Column, Text, upvals([])) :- ncurses_print_at(Row, Column, Text).
ncurses_getch_cl(Key, upvals([])) :- ncurses_getch(Key).
ncurses_nodelay_cl(Enabled, upvals([])) :- ncurses_nodelay(Enabled).
