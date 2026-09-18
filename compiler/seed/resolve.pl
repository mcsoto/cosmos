:- style_check(-singleton).
cosmos_resolve__type_references(_words, _names) :- subtract(_words, ["Any"|["Functor"|["Number"|["String"|["Integer"|["Real"|["List"|["Table"|["Host"|["Relation"|["In"|["Out"|["InOut"|[]]]]]]]]]]]]]], _names).
cosmos_resolve__variables(_node, _names) :- cosmos_resolve__variable_walk(_node, _found), sort(_found, _names).
cosmos_resolve__scope_variables(_node, _names) :- cosmos_resolve__scope_walk(_node, _found), sort(_found, _names).
cosmos_resolve__scope_walk(_node, _names) :- (_node = fc_ClassDecl(_name,_value,_) -> cosmos_resolve__scope_walk(_value, _tail), _names = [_name|_tail] ; (_node = fc_ProtocolDecl(_name,_,_) -> _names = [_name|[]] ; (_node = fc_ClosureExpr(_,_,_,_) -> _names = [] ; (_node = fc_VarExpr(_name,_) -> cosmos_resolve__variable_walk(_node, _names) ; (_node = fc_TypedParam(_,_name,_) -> _names = [_name|[]] ; (_node = fc_TypedDecl(_words,_name,_value,_) -> cosmos_resolve__scope_walk(_value, _tail), cosmos_resolve__type_references(_words, _types), append([_name|_tail], _types, _names) ; (_node = fc_IsGoal(_value,_typeName,_) -> cosmos_resolve__scope_walk(_value, _tail), cosmos_resolve__type_references([_typeName|[]], _types), append(_tail, _types, _names) ; (is_list(_node) -> cosmos_resolve__scope_list(_node, _names) ; (compound(_node) -> cc_parts(_node, _, _children), cosmos_resolve__scope_list(_children, _names) ; _names = []))))))))).
cosmos_resolve__scope_list([], []) :- true.
cosmos_resolve__scope_list([_node|_nodes], _names) :- cosmos_resolve__scope_walk(_node, _first), cosmos_resolve__scope_list(_nodes, _tail), append(_first, _tail, _names).
cosmos_resolve__variable_walk(_node, _names) :- (_node = fc_ClassDecl(_name,_value,_) -> cosmos_resolve__variable_walk(_value, _tail), _names = [_name|_tail] ; (_node = fc_ProtocolDecl(_name,_,_) -> _names = [_name|[]] ; (_node = fc_VarExpr(_name,_) -> ((_name = "_" ; sub_string(_name, _, _, _, "::")) -> _names = [] ; _names = [_name|[]]) ; (_node = fc_TypedParam(_,_name,_) -> _names = [_name|[]] ; (_node = fc_TypedDecl(_words,_name,_value,_) -> cosmos_resolve__variable_walk(_value, _tail), cosmos_resolve__type_references(_words, _types), append([_name|_tail], _types, _names) ; (_node = fc_IsGoal(_value,_typeName,_) -> cosmos_resolve__variable_walk(_value, _tail), cosmos_resolve__type_references([_typeName|[]], _types), append(_tail, _types, _names) ; (is_list(_node) -> cosmos_resolve__variables_list(_node, _names) ; (compound(_node) -> cc_parts(_node, _, _children), cosmos_resolve__variables_list(_children, _names) ; _names = [])))))))).
cosmos_resolve__variables_list([], []) :- true.
cosmos_resolve__variables_list([_item|_items], _names) :- cosmos_resolve__variable_walk(_item, _first), cosmos_resolve__variables_list(_items, _rest), append(_first, _rest, _names).
cosmos_resolve__partition([], [], [], [], []) :- true.
cosmos_resolve__partition([_item|_items], _relations, _top, _names, _functors) :- cosmos_resolve__partition(_items, _rs, _ts, _ns, _fs), (_item = fc_RelationDecl(_,_name,_,_,_) -> _relations = [_item|_rs], _top = _ts, _names = [_name|_ns], _functors = _fs ; (_item = fc_FunctorDecl(_name,_,_) -> _relations = _rs, _top = _ts, _names = _ns, _functors = [_name|_fs] ; _relations = _rs, _top = [_item|_ts], _names = _ns, _functors = _fs)).
cosmos_resolve__signatures([], _globals, []) :- true.
cosmos_resolve__signatures([fc_RelationDecl(_kind, _name, _params, _body, _)|_rs], _globals, [_sig|_rest]) :- cosmos_resolve__variables(_params, _parameters), cosmos_resolve__variables(_body, _used), subtract(_used, _parameters, _free), intersection(_globals, _free, _captures), size_(_params, T1), _arity = T1, _sig = fc_Signature(_name,_arity,_captures,_free,_kind), cosmos_resolve__signatures(_rs, _globals, _rest).
cosmos_resolve__inherited([], _knownSignatures, []) :- true.
cosmos_resolve__inherited([_name|_names], _knownSignatures, _captures) :- (member(fc_Signature(_name,_,_current,_,_), _knownSignatures) -> _first = _current ; _first = []), cosmos_resolve__inherited(_names, _knownSignatures, _rest), append(_first, _rest, _captures).
cosmos_resolve__expand([], _all, []) :- true.
cosmos_resolve__expand([fc_Signature(_name, _arity, _captured, _calls, _kind)|_xs], _all, [_updated|_rest]) :- cosmos_resolve__inherited(_calls, _all, _extra), append(_captured, _extra, _combined), sort(_combined, _following), _updated = fc_Signature(_name,_arity,_following,_calls,_kind), cosmos_resolve__expand(_xs, _all, _rest).
cosmos_resolve__capture_fixpoint(_before, _after) :- cosmos_resolve__expand(_before, _before, _following), (_following = _before -> _after = _following ; cosmos_resolve__capture_fixpoint(_following, _after)).
cosmos_resolve__merge_signature(_sig, [], [_sig|[]]) :- true.
cosmos_resolve__merge_signature(fc_Signature(_name, _arity, _caps, _calls, _kind), [_head|_tail], _result) :- (_head = fc_Signature(_name,_previous,_oldCaps,_oldCalls,_oldKind) -> cosmos_resolve__category(_kind, _newCategory), cosmos_resolve__category(_oldKind, _oldCategory), (_arity = _previous, _newCategory = _oldCategory -> append(_caps, _oldCaps, _combinedCaps), sort(_combinedCaps, _mergedCaps), append(_calls, _oldCalls, _combinedCalls), sort(_combinedCalls, _mergedCalls), _result = [fc_Signature(_name,_arity,_mergedCaps,_mergedCalls,_kind)|_tail] ; add_("Inconsistent declaration for relation: ", _name, T2), throw(T2)) ; cosmos_resolve__merge_signature(fc_Signature(_name,_arity,_caps,_calls,_kind), _tail, _rest), _result = [_head|_rest]).
cosmos_resolve__category(_kind, _name) :- (is_assoc(_kind) -> getnil(_kind, "category", T3), _name = T3 ; _name = _kind).
cosmos_resolve__merge_signatures([], []) :- true.
cosmos_resolve__merge_signatures([_head|_tail], _merged) :- cosmos_resolve__merge_signatures(_tail, _rest), cosmos_resolve__merge_signature(_head, _rest, _merged).
cosmos_resolve__analyze(_items, _program) :- cosmos_resolve__partition(_items, _relations, _top, _names, _declared), cosmos_resolve__scope_variables(_top, _used), append(_names, _declared, _excluded), subtract(_used, _excluded, _globals), cosmos_resolve__signatures(_relations, _globals, _initial), cosmos_resolve__merge_signatures(_initial, _merged), cosmos_resolve__capture_fixpoint(_merged, _resolved), append(["Cons"|["T"|["Tuple"|["Pair"|["Some"|["None"|[]]]]]]], _declared, _functors), new(T4), set_(T4, "relations", _relations, T5), set_(T5, "top", _top, T6), set_(T6, "globals", _globals, T7), set_(T7, "signatures", _resolved, T8), set_(T8, "functors", _functors, T9), _program = T9.
cosmos_resolve__value_type_references(V1, V2, _upvals) :- cosmos_resolve__type_references(V1, V2).
cosmos_resolve__value_variables(V1, V2, _upvals) :- cosmos_resolve__variables(V1, V2).
cosmos_resolve__value_scope_variables(V1, V2, _upvals) :- cosmos_resolve__scope_variables(V1, V2).
cosmos_resolve__value_scope_walk(V1, V2, _upvals) :- cosmos_resolve__scope_walk(V1, V2).
cosmos_resolve__value_scope_list(V1, V2, _upvals) :- cosmos_resolve__scope_list(V1, V2).
cosmos_resolve__value_scope_list(V1, V2, _upvals) :- cosmos_resolve__scope_list(V1, V2).
cosmos_resolve__value_variable_walk(V1, V2, _upvals) :- cosmos_resolve__variable_walk(V1, V2).
cosmos_resolve__value_variables_list(V1, V2, _upvals) :- cosmos_resolve__variables_list(V1, V2).
cosmos_resolve__value_variables_list(V1, V2, _upvals) :- cosmos_resolve__variables_list(V1, V2).
cosmos_resolve__value_partition(V1, V2, V3, V4, V5, _upvals) :- cosmos_resolve__partition(V1, V2, V3, V4, V5).
cosmos_resolve__value_partition(V1, V2, V3, V4, V5, _upvals) :- cosmos_resolve__partition(V1, V2, V3, V4, V5).
cosmos_resolve__value_signatures(V1, V2, V3, _upvals) :- cosmos_resolve__signatures(V1, V2, V3).
cosmos_resolve__value_signatures(V1, V2, V3, _upvals) :- cosmos_resolve__signatures(V1, V2, V3).
cosmos_resolve__value_inherited(V1, V2, V3, _upvals) :- cosmos_resolve__inherited(V1, V2, V3).
cosmos_resolve__value_inherited(V1, V2, V3, _upvals) :- cosmos_resolve__inherited(V1, V2, V3).
cosmos_resolve__value_expand(V1, V2, V3, _upvals) :- cosmos_resolve__expand(V1, V2, V3).
cosmos_resolve__value_expand(V1, V2, V3, _upvals) :- cosmos_resolve__expand(V1, V2, V3).
cosmos_resolve__value_capture_fixpoint(V1, V2, _upvals) :- cosmos_resolve__capture_fixpoint(V1, V2).
cosmos_resolve__value_merge_signature(V1, V2, V3, _upvals) :- cosmos_resolve__merge_signature(V1, V2, V3).
cosmos_resolve__value_merge_signature(V1, V2, V3, _upvals) :- cosmos_resolve__merge_signature(V1, V2, V3).
cosmos_resolve__value_category(V1, V2, _upvals) :- cosmos_resolve__category(V1, V2).
cosmos_resolve__value_merge_signatures(V1, V2, _upvals) :- cosmos_resolve__merge_signatures(V1, V2).
cosmos_resolve__value_merge_signatures(V1, V2, _upvals) :- cosmos_resolve__merge_signatures(V1, V2).
cosmos_resolve__value_analyze(V1, V2, _upvals) :- cosmos_resolve__analyze(V1, V2).
resolve(T14) :- new(T10), set_(T10, "variables", clos(upvals, cosmos_resolve__value_variables), T11), set_(T11, "scopeVariables", clos(upvals, cosmos_resolve__value_scope_variables), T12), set_(T12, "captures", clos(upvals, cosmos_resolve__value_inherited), T13), set_(T13, "analyze", clos(upvals, cosmos_resolve__value_analyze), T14).
