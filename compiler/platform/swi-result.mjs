// Normalize actual SWI query status before looking at any bindings.
export function swiResult(answer) {
  if (answer?.error) return { status: 'error', message: String(answer.message ?? 'SWI query error') };
  if (answer === false || answer?.success === false) return { status: 'failure' };
  if (!answer || typeof answer !== 'object') throw new TypeError('Invalid SWI query answer');
  const { success, $tag, ...bindings } = answer;
  return { status: 'success', bindings };
}

// Decode the compiler's explicit codec, preserving atoms/functors/variables as
// tagged records and tables as Maps. A list such as [65,66] remains a list.
function textValue(value) {
  if (typeof value === 'string') return value;
  // The shipped SWI binding returns PrologString instances, not JS strings.
  if (value?.$t === 's' && typeof value.v === 'string') return value.v;
  throw new TypeError('Invalid string value');
}
export function decodeValue(wire, variables = new Map()) {
  if (!wire || typeof wire !== 'object') throw new TypeError('Invalid compiler value');
  switch (textValue(wire.type)) {
    case 'string':
      return textValue(wire.value);
    case 'number':
      if (typeof wire.value !== 'number') throw new TypeError('Invalid numeric value');
      return wire.value;
    case 'integer': return BigInt(textValue(wire.value));
    case 'rational': return { type: 'rational', numerator: BigInt(textValue(wire.numerator)), denominator: BigInt(textValue(wire.denominator)) };
    case 'list': return wire.items.map(value => decodeValue(value, variables));
    case 'table': return new Map(wire.entries.map(entry => [decodeValue(entry.key, variables), decodeValue(entry.value, variables)]));
    case 'atom': return { type: 'atom', value: textValue(wire.value) };
    case 'functor': return { type: 'functor', name: textValue(wire.name), args: wire.args.map(value => decodeValue(value, variables)) };
    case 'variable':
      if (!variables.has(wire.id)) variables.set(wire.id, { type: 'variable', id: wire.id });
      return variables.get(wire.id);
    default: throw new TypeError(`Unknown compiler value type: ${wire.type}`);
  }
}
