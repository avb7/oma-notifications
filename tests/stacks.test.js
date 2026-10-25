// node tests/stacks.test.js
const assert = require("assert")
const L = require("../NotificationLogic.js")

const CRITICAL = 2
let passed = 0
function test(name, fn) {
  fn()
  passed++
  console.log("ok - " + name)
}

function row(app, ts, extra) {
  const r = Object.assign({ app: app, appIcon: "", originalId: ts, timestamp: ts, urgency: 1 }, extra || {})
  r.name = L.popupFileName(r)
  return r
}

// Apply syncSteps to a plain array the way the service applies them to a ListModel.
function applySteps(list, steps) {
  const out = list.slice()
  for (const s of steps) {
    if (s.op === "insert") out.splice(s.index, 0, s.item)
    else if (s.op === "move") out.splice(s.to, 0, out.splice(s.from, 1)[0])
    else if (s.op === "update") out[s.index] = s.item
    else if (s.op === "remove") out.splice(s.index, 1)
  }
  return out
}

test("same app shares a stack, case-insensitive", () => {
  assert.strictEqual(L.stackKey(row("Slack", 1)), L.stackKey(row("slack", 2)))
  assert.notStrictEqual(L.stackKey(row("Slack", 1)), L.stackKey(row("Discord", 2)))
})

test("no app name falls back to icon, then to its own stack", () => {
  assert.strictEqual(L.stackKey(row("", 1, { appIcon: "x" })), L.stackKey(row("", 2, { appIcon: "x" })))
  assert.notStrictEqual(L.stackKey(row("", 1)), L.stackKey(row("", 2)))
})

test("12 alerts from one app become one stack of 12", () => {
  const rows = []
  for (let i = 12; i >= 1; i--) rows.push(row("Grok Bot", i))
  const { stacks, evict } = L.stackRows(rows, 3, CRITICAL, {})
  assert.strictEqual(stacks.length, 1)
  assert.strictEqual(stacks[0].count, 12)
  assert.strictEqual(stacks[0].rows[0].timestamp, 12)
  assert.deepStrictEqual(evict, [])
})

test("stacks are ordered by their newest popup", () => {
  const rows = [row("A", 10), row("B", 9), row("A", 1), row("C", 5)]
  const { stacks } = L.stackRows(rows, 3, CRITICAL, {})
  assert.deepStrictEqual(stacks.map(s => s.app), ["A", "B", "C"])
})

test("rows out of order in the model still sort newest-first", () => {
  const rows = [row("A", 3), row("B", 9), row("A", 7)]
  const { stacks } = L.stackRows(rows, 3, CRITICAL, {})
  assert.deepStrictEqual(stacks.map(s => s.app), ["B", "A"])
  assert.deepStrictEqual(stacks[1].rows.map(r => r.timestamp), [7, 3])
})

test("a 4th app pushes the oldest stack off screen", () => {
  const rows = [row("D", 40), row("C", 30), row("B", 20), row("A", 10), row("A", 5)]
  const { stacks, evict } = L.stackRows(rows, 3, CRITICAL, {})
  assert.deepStrictEqual(stacks.map(s => s.app), ["D", "C", "B"])
  assert.deepStrictEqual(evict, [row("A", 10).name, row("A", 5).name])
})

test("a hovered or expanded stack is never pushed off", () => {
  const rows = [row("D", 40), row("C", 30), row("B", 20), row("A", 10)]
  const keep = {}
  keep[L.stackKey(row("A", 0))] = true
  const { stacks, evict } = L.stackRows(rows, 3, CRITICAL, keep)
  assert.strictEqual(stacks.length, 4)
  assert.deepStrictEqual(evict, [])
})

test("trusted critical alerts stay past the limit; untrusted ones do not", () => {
  const rows = [row("D", 40), row("C", 30), row("B", 20),
    row("notify-send", 10, { urgency: CRITICAL }), row("Grok Bot", 5, { urgency: CRITICAL })]
  const { stacks, evict } = L.stackRows(rows, 3, CRITICAL, {})
  assert.deepStrictEqual(stacks.map(s => s.app), ["D", "C", "B", "notify-send"])
  assert.deepStrictEqual(evict, [row("Grok Bot", 5).name])
})

test("trusted senders", () => {
  assert.ok(L.isTrustedSender("omarchy-action"))
  assert.ok(L.isTrustedSender("notify-send"))
  assert.ok(!L.isTrustedSender("Grok Bot"))
  assert.ok(!L.isTrustedSender(""))
})

test("syncSteps: insert, move, update and remove reach the target", () => {
  const k = (key) => ({ key: key })
  const cases = [
    [[], [k("a"), k("b")]],
    [[k("a"), k("b"), k("c")], [k("c"), k("a")]],
    [[k("a"), k("b")], []],
    [[k("a"), k("b"), k("c")], [k("b"), k("d"), k("a"), k("c")]],
    [[k("x")], [k("x")]]
  ]
  for (const [current, next] of cases) {
    const result = applySteps(current, L.syncSteps(current, next))
    assert.deepStrictEqual(result.map(i => i.key), next.map(i => i.key))
  }
})

test("syncSteps keeps an unchanged stack in place (no remove + insert)", () => {
  const steps = L.syncSteps([{ key: "a" }, { key: "b" }], [{ key: "a" }, { key: "b" }])
  assert.ok(steps.every(s => s.op === "update"))
})

console.log("\n" + passed + " tests passed")
