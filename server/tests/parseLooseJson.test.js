const { test } = require('node:test');
const assert = require('node:assert');
const { parseLooseJson } = require('../server.js');

test('parseLooseJson - valid JSON', () => {
  const input = '{"key": "value"}';
  const expected = { key: 'value' };
  assert.deepStrictEqual(parseLooseJson(input), expected);
});

test('parseLooseJson - JSON with surrounding text', () => {
  const input = 'Here is some text before {"key": "value"} and some text after.';
  const expected = { key: 'value' };
  assert.deepStrictEqual(parseLooseJson(input), expected);
});

test('parseLooseJson - JSON with control characters', () => {
  const input = '{"key": "value\u0000"}';
  const expected = { key: 'value ' };
  assert.deepStrictEqual(parseLooseJson(input), expected);
});

test('parseLooseJson - throws error when no JSON found', () => {
  const input = 'This is just some text with no curly braces.';
  assert.throws(() => parseLooseJson(input), { message: 'no JSON' });
});

test('parseLooseJson - throws error when opening brace missing', () => {
  const input = 'This has only a closing brace }';
  assert.throws(() => parseLooseJson(input), { message: 'no JSON' });
});

test('parseLooseJson - throws error when closing brace missing', () => {
  // e <= s condition
  const input = 'This has only an opening brace {';
  assert.throws(() => parseLooseJson(input), { message: 'no JSON' });
});

test('parseLooseJson - throws error when braces are reversed', () => {
  // e <= s condition
  const input = '} reversed {';
  assert.throws(() => parseLooseJson(input), { message: 'no JSON' });
});
