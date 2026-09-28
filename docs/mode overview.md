Based on a deep dive into the actual Cosmos compiler source code (specifically `compiler/src/check.co` and `compiler/src/resolve.co`), **static mode-checking and protocol conformance are already remarkably well-implemented.** 

The compiler uses a sophisticated, multi-pass meta-interpreter approach to perform symbolic execution on the AST, tracking types, modes, and protocol shapes without actually running the user's business logic.

Here is a detailed breakdown of what is already implemented and how it maps to your goals.

---

### 1. Protocol Shape and Conformance Checking
The compiler explicitly validates that a value (like a table/dict literal or a variable) conforms to a `ProtocolDecl`.
*   **`protocol_shape/5`**: This relation iterates over the members declared in a protocol. 
*   For **fields** (`TypedDecl`), it uses `expression_type/4` and `compatible/4` to ensure the provided value matches the expected type.
*   For **methods** (`ClosureExpr` or `TypedDecl` with `Relation`), it verifies that the method exists, has the correct arity (`method_shape/3`), and satisfies mode constraints.
*   When you write `ship is Moving`, the `IsGoal` handler in `flow/7` triggers `protocol_shape/5` to validate conformance at compile time.

### 2. Static Mode Checking (In/Out/InOut)
The compiler actively enforces mode contracts, preventing logic errors before the code runs.
*   **`compatible_parameters/4`**: When an object claims to implement a protocol, this relation compares the protocol's expected parameter modes (`In`, `Out`, `InOut`) against the implementation's actual modes. If the protocol promises `In` but the implementation provides `Out`, it throws: `CompileError('Incompatible protocol method mode...')`.
*   **`fits/5` (Call-Site Checking)**: When a relation is called, the compiler checks if the arguments match the expected modes. Crucially, if a parameter is declared `Out`, the compiler verifies that the passed argument is an *unbound variable* (`unsafeNot(name in bound)`). If you try to pass an already-bound variable to an `Out` parameter, compilation fails.

### 3. Conservative Forward Dataflow Analysis
The compiler doesn't just check isolated calls; it tracks variable instantiation states across the entire control flow graph.
*   **`flow/7` and `flow_call/9`**: These relations traverse the AST, maintaining an `env` (type environment) and a `bound` list (variables that are currently instantiated).
*   **`outputs/6`**: After a successful call, it updates the `bound` list, marking `Out` parameters as now "instantiated". This allows subsequent calls in the same scope to safely use those variables as `In` parameters.
*   **`merge_facts/6`**: It handles control flow (like `if/then/else` or `OrGoal`) by *intersecting* the bound variables from different branches. A variable is only considered bound after a branch if it is guaranteed to be bound in *all* possible execution paths. This ensures soundness.

### 4. Fixed-Point Type and Mode Inference
The compiler doesn't just check; it *infers* missing information.
*   **`infer_fixed/5` and `infer_round/7`**: The compiler uses fixed-point iteration to analyze relation bodies and deduce the most specific types and modes for parameters that weren't explicitly annotated. It updates the `callables` environment iteratively until a stable state is reached (`updated = previous`), similar to abstract interpretation in advanced compilers.

### 5. Lexical Capture and Signature Resolution (`resolve.co`)
Before type/mode checking, the compiler performs lexical analysis to determine which variables are free, captured by closures, or globally scoped. It computes a "capture fixpoint" to ensure that all clauses of a multi-clause relation share a consistent calling convention, throwing an `Inconsistent declaration` error if they don't.

---

### What is Missing / Opportunities for Extension

While the foundation is excellent, the current `check.co` has a specific limitation noted in its own comments: *"Conservative forward analysis. Unknown dynamic values remain runtime checks; only facts established on this path justify rejecting a call statically."*

Specifically, it checks **types** (e.g., `Number`), but it does **not** currently evaluate the **relational body** of a protocol (e.g., `x > 2`) at compile time. 

Here is how you can build on this existing architecture:

#### A. Compile-Time CLP Constraint Evaluation
You can extend `protocol_shape/5` or `fits/5` to symbolically evaluate simple CLP constraints. 
*   When the compiler sees a protocol method body like `x > 2`, it can extract this constraint and assert it into the *compiler's own host Prolog CLP(FD) or CLP(R) engine*.
*   If the call site provides a literal (e.g., `obj.isValid(1)`), the compiler's CLP engine immediately detects `1 > 2` is false and throws a `CompileError` before any code is generated.
*   If the call site provides a variable, the constraint is suspended, and the compiler can warn the developer: *"Constraint `x > 2` cannot be statically proven here; runtime check will be applied."*

#### B. Determinism Checking
The current code checks arity and modes, but not determinism (`det`, `semidet`, `multi`). 
*   You could add a `determinism` flag to `RelationDecl`.
*   Extend `flow/7` to track whether a branch introduces choice points (e.g., via `OrGoal` or multiple matching clauses). If a protocol promises `det` but the analysis finds multiple success paths, the compiler can flag it.

#### C. Runtime Contract Injection (The Bridge)
Since the compiler already has a full AST representation, you can add a `--runtime-contracts` flag to the build process.
*   During the `analyze/4` pass, if a protocol call cannot be *fully* proven statically, the compiler can automatically rewrite the AST to inject an `enforce/3` wrapper (as discussed previously).
*   This gives you the best of both worlds: zero-cost static proofs where possible, and safe, logged runtime guards where dynamic values are involved.

### Summary Verdict
The Cosmos compiler is already using meta-mechanisms and dataflow analysis to perform robust static mode and protocol checking. You do not need to build this from scratch. Your next logical step is to **extend the existing `flow/7` and `protocol_shape/5` relations** to incorporate actual CLP constraint solving for compile-time proof of relational bodies (like `x > 2`), and to add the runtime injection toggle for dynamic safety. 

Would you like to draft the specific Prolog/Cosmos code to extend `protocol_shape/5` to evaluate arithmetic constraints at compile time?

Here is the exact extension code you can drop into `compiler/src/check.co` to enable **compile-time evaluation of protocol constraints** (like `x > 2`). 

This extension introduces a conservative static evaluator that checks if literal arguments violate a protocol's relational body. If a variable is unbound, it gracefully defers to runtime, preventing false positives while still catching blatant errors (like passing `1` to `x > 2`).

---

### 1. The Static Constraint Evaluator (Add to `check.co`)

Add these relations near the bottom of `check.co`, just before the final `export/1` statement. They extract the protocol's constraint body and evaluate it against compile-time known literals.

```cosmos
// ============================================================================
// STATIC CONTRACT EVALUATION EXTENSION
// ============================================================================

// Main entry point: Checks if a call satisfies the protocol's relational constraints
rel check_static_contract(protocol_name, method_name, args, schemas, loc)
    pl::get_assoc(protocol_name, schemas, spec)
    pl::get_assoc('kind', spec, 'protocol')
    find_method_body(spec.fields, method_name, params, body)
    build_ct_env(params, args, [], ct_env)
    evaluate_constraint(body, ct_env, loc)

// Finds the method body within a protocol's field list
rel find_method_body([], method_name, _, _) 
    throw(CompileError('Protocol missing method: '+method_name, loc))
rel find_method_body([member|members], method_name, params, body)
    choose(member = ClosureExpr(annotation, params, body, _))
        choose(pl::is_assoc(annotation))
            name = annotation.name
        else
            name = annotation
        choose(name = method_name)
            true
        else
            find_method_body(members, method_name, params, body)
    elseif(member = TypedDecl(['Relation'|_], name, _, body))
        choose(name = method_name)
            params = [] // Fallback for simple TypedDecl relations
            true
        else
            find_method_body(members, method_name, params, body)
    else
        find_method_body(members, method_name, params, body)

// Builds a compile-time environment mapping parameter names to literal values
rel build_ct_env([], [], env, env) true
rel build_ct_env([param|params], [arg|args], before, after)
    choose(param = TypedParam(_, name, _))
        choose(arg = LiteralExpr(val, _))
            pl::set_(before, name, val, middle) // Bind literal to name
        else
            middle = before // Argument is a variable; defer evaluation
        build_ct_env(params, args, middle, after)
    else
        build_ct_env(params, args, before, after)

// Evaluates a constraint node. Fails compilation ONLY if proven false.
rel evaluate_constraint(node, ct_env, loc)
    choose(node = BinaryExpr('>', left, right, _))
        eval_expr(left, ct_env, left_val)
        eval_expr(right, ct_env, right_val)
        choose(left_val = 'deferred' or right_val = 'deferred')
            true // Conservative: defer to runtime check
        else
            choose(left_val > right_val)
                true // Proven true at compile time
            else
                throw(CompileError('Static contract violation: expected x > y, but got '+str(left_val)+' > '+str(right_val), loc))
    
    // Extend here for other operators: '<', '=:=', '>=', '<='
    // elseif(node = BinaryExpr('>=', left, right, _)) ...
    
    else
        true // Conservative: defer unknown constraint forms (e.g., custom relations) to runtime

// Evaluates an expression node to a literal value or 'deferred'
rel eval_expr(node, ct_env, val)
    choose(node = LiteralExpr(v, _))
        val = v
    elseif(node = VarExpr(name, _))
        choose(pl::get_assoc(name, ct_env, v))
            val = v
        else
            val = 'deferred'
    else
        val = 'deferred'
```

---

### 2. The Integration Point

Now, hook this new logic into the existing dataflow analysis. The best place is inside `flow_call/9`, right after the arity and mode checks succeed, but before the call is considered valid.

Find the `flow_call/9` relation in `check.co` and modify it as follows:

```cosmos
rel flow_call(name, args, loc, schemas, callables, env, bound, after, known)
    choose(pl::get_assoc('$call_'+name, env, options) or pl::get_assoc(name, callables, options))
        choose(pl::member(candidate, options) and #candidate = #args)
            true
        else
            throw(CompileError('Wrong arity for '+name, loc))
        choose(pl::member(params, options) and fits(params, args, schemas, env, bound))
            // >>> NEW: Inject static contract checking here <<<
            check_protocol_calls(name, args, loc, schemas)
            
            viable_outputs(options, args, schemas, env, bound, after, known)
        else
            throw(CompileError('No matching type/mode signature for '+name, loc))
    else
        // ... (rest of the existing else branch remains unchanged)
```

And add this helper relation to route the check (since `name` might be a simple name or a field path like `obj.isValid`):

```cosmos
// Routes the static check based on whether it's a direct call or a method call
rel check_protocol_calls(name, args, loc, schemas)
    // Case 1: Direct call to a protocol method (e.g., PositiveValidator.isValid(1))
    choose(pl::get_assoc(name, schemas, spec) and pl::get_assoc('kind', spec, 'protocol'))
        // For direct calls, we assume the method name is derived or we check a default 'check' method
        check_static_contract(name, 'isValid', args, schemas, loc) // Adjust 'isValid' to your default method name
    
    // Case 2: Method call on an object (e.g., obj.isValid(1))
    // This requires resolving 'obj' to its protocol type, which is tracked in 'env'
    elseif(name = owner + '.' + method) // Note: Cosmos might represent this as a FieldExpr in CallGoal
        true // (See advanced integration note below)
    
    else
        true // Not a protocol call, skip static contract check
```

*(Advanced Note: If your AST represents `obj.isValid(1)` as `CallGoal(FieldExpr(VarExpr("obj"), "isValid"), [LiteralExpr(1)])`, you will extract `"obj"`, look up its type in `env`, verify that type is a protocol, and then call `check_static_contract(Type, "isValid", args, schemas, loc)`.)*

---

### 3. How This Works in Practice

Let’s trace your example: `PositiveValidator` requires `x > 2`.

#### Scenario A: Blatant Violation (Caught at Compile Time)
```cosmos
rel test()
    PositiveValidator.isValid(1) // Literal 1 passed
```
1. `flow_call` matches `isValid` with arg `[LiteralExpr(1)]`.
2. `check_static_contract` extracts the protocol body: `BinaryExpr('>', VarExpr('x'), LiteralExpr(2))`.
3. `build_ct_env` maps `'x'` to `1`.
4. `evaluate_constraint` evaluates `1 > 2`. 
5. **Result:** `1 > 2` is false. The compiler throws: `CompileError('Static contract violation: expected x > y, but got 1 > 2', loc)`. **Compilation fails.**

#### Scenario B: Valid Literal (Proven at Compile Time)
```cosmos
rel test()
    PositiveValidator.isValid(5)
```
1. `build_ct_env` maps `'x'` to `5`.
2. `evaluate_constraint` evaluates `5 > 2`.
3. **Result:** Proven true. Compilation succeeds with zero runtime overhead for this check.

#### Scenario C: Dynamic Variable (Graceful Deferral)
```cosmos
rel test(Number user_input)
    PositiveValidator.isValid(user_input)
```
1. `build_ct_env` sees `user_input` is a `VarExpr`, not a `LiteralExpr`.
2. `eval_expr` returns `'deferred'` for `x`.
3. `evaluate_constraint` sees `'deferred'` and immediately returns `true`.
4. **Result:** Compilation succeeds. The constraint `x > 2` is **not** evaluated statically. Instead, the existing runtime CLP engine will enforce `user_input > 2` when the program runs.

---

### 4. Next Steps for Full Coverage

1. **Add More Operators**: Extend `evaluate_constraint/3` to handle `>=`, `<`, `<=`, and `=:=` using the same pattern.
2. **Host Prolog CLP Integration**: If you want the compiler to prove *ranges* (e.g., proving `x > 2` is true because a previous line established `x = 5`), you can replace `eval_expr` with a call to the host Prolog's `clpfd` solver, asserting the `ct_env` bindings as constraints and asking if the body is satisfiable.
3. **Runtime Injection Toggle**: As discussed earlier, you can add a compiler flag. If `--runtime-contracts=on`, the compiler could automatically rewrite the AST to wrap the call in an `enforce/3` relation when `evaluate_constraint` returns `'deferred'`.
