:- style_check(-singleton).
'x::$impl_local':-ensure_loaded("bootstrap"),ensure_loaded("config"),ensure_loaded("message"),ensure_loaded("llm").
x([]):-'x::local',send("hi",A),print(A).
'x::local':-'x::$impl_local'.
'x::$value_local'(upvals([])):-'x::local'.
