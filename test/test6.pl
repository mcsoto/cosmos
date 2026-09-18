:- style_check(-singleton).
cosmos_test6__p() :- (_x = 1.0 ; _y = 2.0 ; _y = 2.0 ; _y = 2.0).
cosmos_test6__value_p(_upvals) :- cosmos_test6__p().
test6(_) :- true.
