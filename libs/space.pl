:- style_check(-singleton).
space(A):-(cosmos_host_root("js","space",B),A=B),cosmos_host_root("js","canvas",C),cosmos_set_or_unify(A,"canvas",C).
