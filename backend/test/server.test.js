const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

test('backend server source is present and non-empty', () => {
  const serverPath = path.join(__dirname, '..', 'server.js');
  const source = fs.readFileSync(serverPath, 'utf8');

  assert.ok(source.includes("require('express')"));
  assert.ok(source.includes('app.listen'));
});
