:- style_check(-singleton).
io(_t) :- new(T1), _write = clos(upvals, cosmos_io__closure_1), set_(T1, "write", _write, T2), _writeln = clos(upvals, cosmos_io__closure_2), set_(T2, "writeln", _writeln, T3), _read = clos(upvals, cosmos_io__closure_3), set_(T3, "read", _read, T4), _open = clos(upvals, cosmos_io__closure_4), set_(T4, "open", _open, T5), _close = clos(upvals, cosmos_io__closure_5), set_(T5, "close", _close, T6), _pause = clos(upvals, cosmos_io__closure_6), set_(T6, "pause", _pause, T7), _opened = clos(upvals, cosmos_io__closure_7), set_(T7, "opened", _opened, T8), _fwrite = clos(upvals, cosmos_io__closure_8), set_(T8, "fwrite", _fwrite, T9), _fread = clos(upvals, cosmos_io__closure_9), set_(T9, "fread", _fread, T10), _fileReadLine = clos(upvals, cosmos_io__closure_10), set_(T10, "fileReadLine", _fileReadLine, T11), _fileReadChar = clos(upvals, cosmos_io__closure_11), set_(T11, "fileReadChar", _fileReadChar, T13), _exists = clos(upvals, cosmos_io__closure_12), set_(T13, "exists", _exists, T14), _openBinary = clos(upvals, cosmos_io__closure_13), set_(T14, "openBinary", _openBinary, T15), _write8 = clos(upvals, cosmos_io__closure_14), set_(T15, "write8", _write8, T16), _write16 = clos(upvals, cosmos_io__closure_15), set_(T16, "write16", _write16, T17), _write32 = clos(upvals, cosmos_io__closure_16), set_(T17, "write32", _write32, T18), _appendToFile = clos(upvals(_close, _open), cosmos_io__closure_17), set_(T18, "appendToFile", _appendToFile, T19), _writeToFile = clos(upvals(_open), cosmos_io__closure_18), set_(T19, "writeToFile", _writeToFile, T20), _writeFormat = clos(upvals, cosmos_io__closure_19), set_(T20, "writeFormat", _writeFormat, T21), _readFile = clos(upvals(_close, _open), cosmos_io__closure_20), set_(T21, "readFile", _readFile, T22), _t = T22.
cosmos_io__closure_1(_x, _upvals) :- _upvals = upvals, write(_x).
cosmos_io__closure_2(_x, _upvals) :- _upvals = upvals, write(_x), write("\n").
cosmos_io__closure_3(_x, _upvals) :- _upvals = upvals, ioread(_x).
cosmos_io__closure_4(_name, _mode, _f, _upvals) :- _upvals = upvals, fopen(_name, _mode, _f).
cosmos_io__closure_5(_f, _upvals) :- _upvals = upvals, close(_f).
cosmos_io__closure_6(_upvals) :- _upvals = upvals, ioread(_x).
cosmos_io__closure_7(_name, _mode, _f, _upvals) :- _upvals = upvals, fopen_(_name, _mode, _f).
cosmos_io__closure_8(_f, _x, _upvals) :- _upvals = upvals, write(_f, _x).
cosmos_io__closure_9(_f, _s, _upvals) :- _upvals = upvals, read(_f, _s).
cosmos_io__closure_10(_f, _s, _upvals) :- _upvals = upvals, fread(_f, _s).
cosmos_io__closure_11(_f, _s, _upvals) :- _upvals = upvals, int(1.0, T12), read_string(_f, T12, _s).
cosmos_io__closure_12(_name, _upvals) :- _upvals = upvals, fopen_binary(_name, _mode, _).
cosmos_io__closure_13(_name, _mode, _f, _upvals) :- _upvals = upvals, fopen_binary(_name, _mode, _f).
cosmos_io__closure_14(_f, _x, _upvals) :- _upvals = upvals, int(_x, _byte), write8(_f, _byte).
cosmos_io__closure_15(_f, _n, _upvals) :- _upvals = upvals, int(_n, _word), write16(_f, _word).
cosmos_io__closure_16(_f, _n, _upvals) :- _upvals = upvals, int(_n, _word), write32(_f, _word).
cosmos_io__closure_17(_name, _s, _upvals) :- _upvals = upvals(_close, _open), call_cl(_open, [_name, "append", _f]), write(_f, _s), call_cl(_close, [_f]).
cosmos_io__closure_18(_name, _s, _upvals) :- _upvals = upvals(_open), call_cl(_open, [_name, "write", _f]), write(_f, _s), close(_f).
cosmos_io__closure_19(_x, _upvals) :- _upvals = upvals, write_format(_x).
cosmos_io__closure_20(_name, _s, _upvals) :- _upvals = upvals(_close, _open), call_cl(_open, [_name, "read", _f]), fread_all(_f, _s), call_cl(_close, [_f]).
