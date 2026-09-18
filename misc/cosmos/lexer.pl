:- style_check(-singleton).
cosmos_lexer__load_parser(_parser) :- crequire("parser", _parser, _).
cosmos_lexer__lex(_source, _tokens) :- cosmos_lexer__load_parser(_parser), getnil(_parser, "lex", T1), call_cl(T1, [_source, _tokens]).
cosmos_lexer__whitespace_token(fc_Token(_type, _, _, _)) :- (_type = "NEWLINE" ; _type = "INDENT" ; _type = "DEDENT").
cosmos_lexer__remove_whitespace([], _result) :- _result = [].
cosmos_lexer__remove_whitespace([_head|_tail], _result) :- (cosmos_lexer__whitespace_token(_head) -> cosmos_lexer__remove_whitespace(_tail, _result) ; cosmos_lexer__remove_whitespace(_tail, _rest), _result = [_head|_rest]).
cosmos_lexer__remove_layout(_tokens, _result) :- cosmos_lexer__remove_whitespace(_tokens, _result).
cosmos_lexer__tokenize(_source, _tokens) :- cosmos_lexer__lex(_source, _tokens).
cosmos_lexer__tokenize_without_whitespace(_source, _tokens) :- cosmos_lexer__lex(_source, _all_tokens), cosmos_lexer__remove_whitespace(_all_tokens, _tokens).
cosmos_lexer__value_load_parser(V1, _upvals) :- cosmos_lexer__load_parser(V1).
cosmos_lexer__value_lex(V1, V2, _upvals) :- cosmos_lexer__lex(V1, V2).
cosmos_lexer__value_whitespace_token(V1, _upvals) :- cosmos_lexer__whitespace_token(V1).
cosmos_lexer__value_remove_whitespace(V1, V2, _upvals) :- cosmos_lexer__remove_whitespace(V1, V2).
cosmos_lexer__value_remove_whitespace(V1, V2, _upvals) :- cosmos_lexer__remove_whitespace(V1, V2).
cosmos_lexer__value_remove_layout(V1, V2, _upvals) :- cosmos_lexer__remove_layout(V1, V2).
cosmos_lexer__value_tokenize(V1, V2, _upvals) :- cosmos_lexer__tokenize(V1, V2).
cosmos_lexer__value_tokenize_without_whitespace(V1, V2, _upvals) :- cosmos_lexer__tokenize_without_whitespace(V1, V2).
lexer(T7) :- new(T2), set_(T2, "lex", clos(upvals, cosmos_lexer__value_lex), T3), set_(T3, "tokenize", clos(upvals, cosmos_lexer__value_tokenize), T4), set_(T4, "remove_whitespace", clos(upvals, cosmos_lexer__value_remove_whitespace), T5), set_(T5, "remove_layout", clos(upvals, cosmos_lexer__value_remove_layout), T6), set_(T6, "tokenize_without_whitespace", clos(upvals, cosmos_lexer__value_tokenize_without_whitespace), T7).
