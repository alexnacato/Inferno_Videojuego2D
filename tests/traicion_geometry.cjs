// Quick reachability check without requiring the Godot editor.
const fs = require('fs');
const path = require('path');
const assert = require('assert');

const root = path.resolve(__dirname, '..');
const scene = fs.readFileSync(path.join(root, 'scenes/Traicion.tscn'), 'utf8');
for (const file of ['scenes/Traicion.tscn', 'scenes/TraicionLucifer.tscn', 'scenes/FinTraicion.tscn', 'scripts/traicion.gd', 'scripts/traicion_lucifer.gd', 'scripts/fin_traicion.gd']) {
  const source = fs.readFileSync(path.join(root, file), 'utf8');
  for (const [, reference] of source.matchAll(/res:\/\/([^"\s)]+)/g)) {
    assert(fs.existsSync(path.join(root, reference)), `${file} references missing ${reference}`);
  }
}
const sections = scene.split(/(?=\[node name=)/g);
function polygonOf(section) {
  const match = section.match(/polygon = PackedVector2Array\(([^)]+)\)/);
  if (!match) return null;
  const nums = match[1].split(',').map(Number);
  return Array.from({ length: nums.length / 2 }, (_, i) => [nums[i * 2], nums[i * 2 + 1]]);
}
function pointInPolygon([x, y], poly) {
  let inside = false;
  for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    const [xi, yi] = poly[i], [xj, yj] = poly[j];
    if ((yi > y) !== (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi) inside = !inside;
  }
  return inside;
}
const floors = sections.filter(s => s.includes('parent="Suelo"')).map(polygonOf).filter(Boolean);
const hazards = sections.filter(s => s.includes('parent="HieloFino"')).map(polygonOf).filter(Boolean);
const samples = [[0, 0], [1, 0], [-1, 0], [0, 1], [0, -1], [.7071, .7071], [-.7071, .7071], [.7071, -.7071], [-.7071, -.7071]];
function walk([x, y], radius = 10) {
  return samples.every(([dx, dy]) => floors.some(p => pointInPolygon([x + dx * radius, y + dy * radius], p)));
}
assert(floors.length >= 5, 'missing walkable areas');
assert(hazards.length >= 2, 'missing thin ice');
assert(walk([724, 1000]), 'spawn outside floor');
assert(walk([724, 355], 58), 'boss outside arena');
assert(!walk([50, 200]), 'abyss is walkable');
const cell = 12, queue = [[Math.floor(724 / cell), Math.floor(1000 / cell)]], seen = new Set(queue.map(([x, y]) => `${x},${y}`));
for (let i = 0; i < queue.length; i++) {
  const [x, y] = queue[i];
  for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
    const nx = x + dx, ny = y + dy, key = `${nx},${ny}`;
    if (nx < 0 || ny < 0 || nx > 120 || ny > 90 || seen.has(key) || !walk([(nx + .5) * cell, (ny + .5) * cell])) continue;
    seen.add(key); queue.push([nx, ny]);
  }
}
const markerSections = sections.filter(s => s.includes('parent="Marcadores"'));
for (const section of markerSections) {
  const label = section.match(/uid = "([^"]+)"/);
  const pos = section.match(/position = Vector2\((\d+), (\d+)\)/);
  assert(label && pos, 'marker missing identity or position');
  const [tx, ty] = [Number(pos[1]), Number(pos[2])];
  assert(queue.some(([x, y]) => Math.hypot((x + .5) * cell - tx, (y + .5) * cell - ty) < 80), `${label[1]} unreachable`);
}
for (const [file, width, height] of [
  ['assets/traicion/world/cocito.png', 1448, 1086],
  ['assets/traicion/enemies/lucifer.png', 1536, 1024],
]) {
  const image = fs.readFileSync(path.join(root, file));
  assert.equal(image.toString('ascii', 1, 4), 'PNG');
  assert.equal(image.readUInt32BE(16), width);
  assert.equal(image.readUInt32BE(20), height);
}
assert.equal(fs.readFileSync(path.join(root, 'assets/traicion/enemies/lucifer.png'))[25], 6, 'boss sprite has no alpha channel');
console.log(`Traición: ${markerSections.length} objetivos alcanzables, ${queue.length} celdas recorribles, imágenes válidas.`);
