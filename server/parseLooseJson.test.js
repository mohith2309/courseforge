const test = require('node:test');
const assert = require('node:assert');
const { parseLooseJson } = require('./server.js');

test('parseLooseJson parses pure JSON object', () => {
  const input = '{"key":"value"}';
  const expected = { key: 'value' };
  assert.deepStrictEqual(parseLooseJson(input), expected);
});

test('parseLooseJson parses loose JSON wrapped in text', () => {
  const input = 'Here is the result: {"name":"John","age":30} ... and some more text.';
  const expected = { name: 'John', age: 30 };
  assert.deepStrictEqual(parseLooseJson(input), expected);
});

test('parseLooseJson handles control character replacements', () => {
  // \u0000 to \u001F are replaced with ' '
  // For example, a newline \n is \u000A, a tab is \u0009
  // The function: text.slice(s, e + 1).replace(/[\u0000-\u001F]+/g, ' ')
  // Let's create an input that has raw control characters (not escaped).
  const input = 'Prefix\n\t{"key":"val\nue"}\u0000Suffix';
  // Note: parsing '{"key":"val ue"}' should succeed.
  const expected = { key: 'val ue' };
  assert.deepStrictEqual(parseLooseJson(input), expected);
});

test('parseLooseJson throws Error when no { is found', () => {
  const input = 'Just some text, no braces.';
  assert.throws(() => parseLooseJson(input), { message: 'no JSON' });
});

test('parseLooseJson throws Error when no } is found', () => {
  const input = '{ "key": "value" ';
  assert.throws(() => parseLooseJson(input), { message: 'no JSON' });
});

test('parseLooseJson throws Error when { is after }', () => {
  const input = ' closing } then opening { ';
  assert.throws(() => parseLooseJson(input), { message: 'no JSON' });
});

test('parseLooseJson throws Error on invalid JSON structure inside', () => {
  const input = 'Prefix { "key": "value", } Suffix'; // Trailing comma
  assert.throws(() => parseLooseJson(input), SyntaxError);
});
