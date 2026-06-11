const test = require('node:test');
const assert = require('node:assert');
const { parseLooseJson } = require('./server.js');

test('parseLooseJson - valid exact JSON', () => {
  const input = '{"key": "value"}';
  const result = parseLooseJson(input);
  assert.deepStrictEqual(result, { key: 'value' });
});

test('parseLooseJson - JSON with preamble and postamble', () => {
  const input = 'Here is the JSON: {"key": "value"} This was the JSON.';
  const result = parseLooseJson(input);
  assert.deepStrictEqual(result, { key: 'value' });
});

test('parseLooseJson - JSON with nested objects and arrays', () => {
  const input = '{"outer": {"inner": [1, 2, 3]}}';
  const result = parseLooseJson(input);
  assert.deepStrictEqual(result, { outer: { inner: [1, 2, 3] } });
});

test('parseLooseJson - JSON with newlines and spaces', () => {
  const input = 'Text \n {\n\t"key":\n "value" } \n Text';
  const result = parseLooseJson(input);
  assert.deepStrictEqual(result, { key: 'value' });
});

test('parseLooseJson - JSON with control characters directly', () => {
  // Let's use a control character (ASCII 1) inside a string value
  // Note: JSON standard strings cannot have unescaped control chars, but let's test the regex.
  const input = 'Text { "key": "value' + String.fromCharCode(1) + '" } Text';
  const result = parseLooseJson(input);
  // The function does: text.slice(s, e + 1).replace(/[\u0000-\u001F]+/g, ' ')
  // So the control char 1 is replaced by space.
  assert.deepStrictEqual(result, { key: 'value ' });
});

test('parseLooseJson - Error case: No braces', () => {
  const input = 'This is just a string without JSON';
  assert.throws(() => {
    parseLooseJson(input);
  }, /no JSON/);
});

test('parseLooseJson - Error case: Inverted braces', () => {
  const input = '} {"key": "value"} {';
  // This will extract from the first '{' to the last '}'
  // which is '{"key": "value"}', and parse it successfully.
  const result = parseLooseJson(input);
  assert.deepStrictEqual(result, { key: 'value' });
});

test('parseLooseJson - Error case: Inverted braces with no matching', () => {
  const input = '} {';
  assert.throws(() => {
    parseLooseJson(input);
  }, /no JSON/);
});

test('parseLooseJson - Error case: Invalid JSON inside extracted braces', () => {
  const input = '{"key": "value", }'; // Trailing comma
  assert.throws(() => {
    parseLooseJson(input);
  }, SyntaxError); // Node.js JSON.parse throws SyntaxError on trailing comma
});
