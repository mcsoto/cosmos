:- style_check(-singleton).
xpce(A):-cosmos_require("xpce_prolog",B),new(C),set_(C,"create",clos(upvals([]),'xpce::$closure_0.0'),D),set_(D,"send",clos(upvals([]),'xpce::$closure_1.0'),E),set_(E,"get",clos(upvals([]),'xpce::$closure_2.0'),F),set_(F,"free",clos(upvals([]),'xpce::$closure_3.0'),G),set_(G,"color",clos(upvals([]),'xpce::$closure_4.0'),H),set_(H,"point",clos(upvals([]),'xpce::$closure_5.0'),I),set_(I,"size",clos(upvals([]),'xpce::$closure_6.0'),J),set_(J,"font",clos(upvals([]),'xpce::$closure_7.0'),K),set_(K,"on_click",clos(upvals([]),'xpce::$closure_8.0'),L),set_(L,"timer",clos(upvals([]),'xpce::$closure_9.0'),M),set_(M,"set_data",clos(upvals([]),'xpce::$closure_10.0'),N),set_(N,"get_data",clos(upvals([]),'xpce::$closure_11.0'),O),set_(O,"loop",clos(upvals([]),'xpce::$closure_12.0'),P),set_(P,"quit",clos(upvals([]),'xpce::$closure_13.0'),Q),set_(Q,"poll",clos(upvals([]),'xpce::$closure_14.0'),R),A=R.
'xpce::$closure_0.0'(A,B,C,upvals([])):-xpce_new(A,B,C).
'xpce::$closure_1.0'(A,B,C,upvals([])):-xpce_send(A,B,C).
'xpce::$closure_2.0'(A,B,C,upvals([])):-xpce_get(A,B,C).
'xpce::$closure_3.0'(A,upvals([])):-xpce_free(A).
'xpce::$closure_4.0'(A,B,upvals([])):-xpce_color(A,B).
'xpce::$closure_5.0'(A,B,C,upvals([])):-int(A,D),int(B,E),xpce_point(D,E,C).
'xpce::$closure_6.0'(A,B,C,upvals([])):-int(A,D),int(B,E),xpce_size(D,E,C).
'xpce::$closure_7.0'(A,B,C,D,upvals([])):-xpce_font(A,B,C,D).
'xpce::$closure_8.0'(A,B,upvals([])):-xpce_on_click(A,B).
'xpce::$closure_9.0'(A,B,C,upvals([])):-xpce_timer(A,B,C).
'xpce::$closure_10.0'(A,B,upvals([])):-xpce_set_data(A,B).
'xpce::$closure_11.0'(A,B,upvals([])):-xpce_get_data(A,B).
'xpce::$closure_12.0'(upvals([])):-xpce_loop.
'xpce::$closure_13.0'(upvals([])):-system:halt.
'xpce::$closure_14.0'(upvals([])):-xpce_poll.
