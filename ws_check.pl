:- style_check(-singleton).
ws_check([]):-new(A),set_(A,"update",B,C),set_(C,"draw",D,E),F=E.
