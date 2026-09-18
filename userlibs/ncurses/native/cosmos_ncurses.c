/* Cygwin ncurses bridge for Cygwin-native SWI-Prolog. */
#include <SWI-Prolog.h>
#include <curses.h>

static int integer_arg(term_t term, int *value) {
  int64_t number;
  if (!PL_get_int64(term, &number)) return FALSE;
  *value = (int)number;
  return TRUE;
}

static foreign_t pl_ncurses_init(void) {
  if (initscr() == NULL) return FALSE;
  cbreak(); noecho(); keypad(stdscr, TRUE);
  return TRUE;
}
static foreign_t pl_ncurses_close(void) { endwin(); return TRUE; }
static foreign_t pl_ncurses_clear(void) { return clear() == ERR ? FALSE : TRUE; }
static foreign_t pl_ncurses_refresh(void) { return refresh() == ERR ? FALSE : TRUE; }
static foreign_t pl_ncurses_move(term_t row, term_t column) {
  int y, x;
  return integer_arg(row, &y) && integer_arg(column, &x) && move(y, x) != ERR;
}
static foreign_t pl_ncurses_write(term_t text) {
  char *utf8;
  size_t length;
  int flags = CVT_ATOM|CVT_STRING|CVT_LIST|BUF_MALLOC|REP_UTF8;
  if (!PL_get_nchars(text, &length, &utf8, flags)) return FALSE;
  int result = addnstr(utf8, (int)length) != ERR;
  PL_free(utf8);
  return result;
}
static foreign_t pl_ncurses_print_at(term_t row, term_t column, term_t text) {
  return pl_ncurses_move(row, column) && pl_ncurses_write(text);
}
static foreign_t pl_ncurses_getch(term_t key) { return PL_unify_integer(key, getch()); }
static foreign_t pl_ncurses_nodelay(term_t enabled) {
  int flag;
  return PL_get_bool(enabled, &flag) && nodelay(stdscr, flag ? TRUE : FALSE) != ERR;
}

install_t install(void) {
  PL_register_foreign("ncurses_init", 0, pl_ncurses_init, 0);
  PL_register_foreign("ncurses_close", 0, pl_ncurses_close, 0);
  PL_register_foreign("ncurses_clear", 0, pl_ncurses_clear, 0);
  PL_register_foreign("ncurses_refresh", 0, pl_ncurses_refresh, 0);
  PL_register_foreign("ncurses_move", 2, pl_ncurses_move, 0);
  PL_register_foreign("ncurses_write", 1, pl_ncurses_write, 0);
  PL_register_foreign("ncurses_print_at", 3, pl_ncurses_print_at, 0);
  PL_register_foreign("ncurses_getch", 1, pl_ncurses_getch, 0);
  PL_register_foreign("ncurses_nodelay", 1, pl_ncurses_nodelay, 0);
}
