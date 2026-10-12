// Bedrock geo + animation (Chiikawa mod) -> ModelEngine .bbmodel
// usage: deno run -A geo2bb.ts <assetsDir> <character> <outFile> <modelName>
const [assets, ch, outFile, modelName] = Deno.args;
const geo = JSON.parse(Deno.readTextFileSync(`${assets}/models/entity/${ch}.json`))["minecraft:geometry"][0];
const anims = JSON.parse(Deno.readTextFileSync(`${assets}/animations/${ch}.json`)).animations;
const png = Deno.readFileSync(`${assets}/textures/entities/${ch}.png`);

// bones hidden by default in the mod (shown only during special actions) + prop bones.
// happyeyes (and mouth3 for hachiware/usagi) are kept: they show during "happy". The plugin hides them otherwise.
const KEEP_MOUTH3 = ch === "hachiware" || ch === "usagi";
const HIDDEN = new Set([...(ch === "furuhonya" ? ["mouth2"] : []), ...(KEEP_MOUTH3 ? [] : ["mouth3"]),
  "cryeyes", "tears", "tear", "sweat", "dots", "exampaper", "exampencil", "guitar", "pouchstrap", "packstrap"]);
const KEEP_ANIMS: Record<string, string> = Object.fromEntries(
  ["idle", "walk", "blink", "run", "sit", "swim", "swim_stand", "happy", "clap", "crab_greeting", "eat", "drink"].map((n) => [n, n]));
// ModelEngine bone tags: h_ = turns with the entity's head, ir_ = shows what the entity holds in its main hand
const RENAME: Record<string, string> = { allhead: "h_allhead" };
// The mod's HeldItemLayer, from RightHandLocator: turn X -90 (the item's up points out of the front of the fist),
// move (0, 2, -1)px in that turned frame (into the palm, ahead of the knuckles), lift X +18, scale 0.6.
// Both turns are about X, so this is one child bone ir_hand at locator + (0, -1, -2)px turned X -72, drawn at 0.6.
const HAND_OFFSET = [0, -1, -2];
const HAND_TURN = [-72, 0, 0];
const HAND_SCALE = 0.6;

let uuidN = 0;
const uuid = () => crypto.randomUUID();
const TW = geo.description.texture_width, TH = geo.description.texture_height;

type Bone = { name: string; parent?: string; pivot?: number[]; rotation?: number[]; cubes?: any[] };
const bones: Bone[] = geo.bones;
const byName = new Map<string, Bone>();
for (const b of bones) byName.set(b.name.toLowerCase(), b);

// drop hidden bones with all their descendants
const dropped = new Set<string>();
const isDropped = (b: Bone): boolean => {
  const n = b.name.toLowerCase();
  if (HIDDEN.has(n)) return true;
  if (!b.parent) return false;
  const p = byName.get(b.parent.toLowerCase());
  return p ? isDropped(p) : false;
};
for (const b of bones) if (isDropped(b)) dropped.add(b.name.toLowerCase());

const children = new Map<string, Bone[]>();
for (const b of bones) {
  if (dropped.has(b.name.toLowerCase())) continue;
  const p = (b.parent ?? "").toLowerCase();
  if (!children.has(p)) children.set(p, []);
  children.get(p)!.push(b);
}
// a bone is useful if it (or a descendant) has cubes
const useful = (b: Bone): boolean =>
  (b.cubes?.length ?? 0) > 0 || b.name.toLowerCase() === "righthandlocator" || (children.get(b.name.toLowerCase()) ?? []).some(useful);

const VALID = new Set([-45, -22.5, 0, 22.5, 45]);
const validRot = (r: number[]) => {
  const nz = r.filter((v) => Math.abs(v) > 1e-6);
  return nz.length === 0 || (nz.length === 1 && VALID.has(Math.round(nz[0] * 10) / 10));
};

const elements: any[] = [];
const usedNames = new Set<string>();
const uniq = (n: string) => { let s = n, i = 1; while (usedNames.has(s)) s = `${n}_${++i}`; usedNames.add(s); return s; };

function boxFaces(c: any) {
  const fl = (v: number) => Math.floor(v + 1e-6);
  const [w, h, d] = [fl(c.size[0]), fl(c.size[1]), fl(c.size[2])];
  const [u, v] = c.uv;
  const r = (a: number, b: number, cc: number, dd: number) => [u + a, v + b, u + cc, v + dd];
  let f: Record<string, number[]> = {
    north: r(d, d, d + w, d + h),
    east: r(0, d, d, d + h),
    south: r(2 * d + w, d, 2 * d + 2 * w, d + h),
    west: r(d + w, d, 2 * d + w, d + h),
    up: r(d + w, d, d, 0),
    down: r(d + 2 * w, 0, d + w, d),
  };
  if (c.mirror) {
    [f.east, f.west] = [f.west, f.east];
    for (const k in f) f[k] = [f[k][2], f[k][1], f[k][0], f[k][3]];
  }
  const out: any = {};
  for (const k in f) out[k] = { uv: f[k], texture: 0 };
  return out;
}
function perFaces(c: any) {
  const out: any = {};
  for (const k of ["north", "east", "south", "west", "up", "down"]) {
    const fc = c.uv[k];
    if (!fc) continue;
    const [u, v] = fc.uv, [w, h] = fc.uv_size ?? [0, 0];
    out[k] = { uv: [u, v, u + w, v + h], texture: 0 };
  }
  return out;
}

function makeCube(c: any, name: string) {
  const from = [-(c.origin[0] + c.size[0]), c.origin[1], c.origin[2]];
  const to = [from[0] + c.size[0], from[1] + c.size[1], from[2] + c.size[2]];
  const pivot = c.pivot ? [-c.pivot[0], c.pivot[1], c.pivot[2]] : [0, 0, 0];
  const rot = c.rotation ? [-c.rotation[0], -c.rotation[1], c.rotation[2]] : [0, 0, 0];
  const el: any = {
    name, box_uv: false, rescale: false, locked: false, light_emission: 0, render_order: "default",
    allow_mirror_modeling: true, from, to, autouv: 0, color: 0, origin: pivot,
    faces: Array.isArray(c.uv) ? boxFaces(c) : perFaces(c), type: "cube", uuid: uuid(),
  };
  if (c.inflate) el.inflate = c.inflate;
  if (rot.some((v) => Math.abs(v) > 1e-6)) el.rotation = rot;
  return el;
}

// Blockbench (three.js, order ZYX): R = Rz*Ry*Rx. Returns R^-1(Pi-P0) - (Pi-P0).
function shiftFor(rot: number[], pi: number[], p0: number[]) {
  const [x, y, z] = rot.map((v) => v * Math.PI / 180);
  const Rx = [[1, 0, 0], [0, Math.cos(x), -Math.sin(x)], [0, Math.sin(x), Math.cos(x)]];
  const Ry = [[Math.cos(y), 0, Math.sin(y)], [0, 1, 0], [-Math.sin(y), 0, Math.cos(y)]];
  const Rz = [[Math.cos(z), -Math.sin(z), 0], [Math.sin(z), Math.cos(z), 0], [0, 0, 1]];
  const mul = (A: number[][], B: number[][]) => A.map((r) => B[0].map((_, j) => r.reduce((a, _v, k) => a + A[A.indexOf(r)][k] * B[k][j], 0)));
  const R = mul(mul(Rz, Ry), Rx);
  const v = [pi[0] - p0[0], pi[1] - p0[1], pi[2] - p0[2]];
  const inv = [0, 1, 2].map((i) => R[0][i] * v[0] + R[1][i] * v[1] + R[2][i] * v[2]); // R^T v
  return [inv[0] - v[0], inv[1] - v[1], inv[2] - v[2]];
}
function group(name: string, origin: number[], rotation: number[] | undefined) {
  const g: any = {
    name, origin, color: 0, uuid: uuid(), export: true, mirror_uv: false, isOpen: true, locked: false,
    visibility: true, autouv: 0, selected: false, children: [] as any[],
  };
  if (rotation && rotation.some((v) => Math.abs(v) > 1e-6)) g.rotation = rotation;
  return g;
}

const boneUuid = new Map<string, string>(); // lowercased mod name -> group uuid
let wrapped = 0;
function build(b: Bone): any {
  const lname = b.name.toLowerCase();
  const piv = b.pivot ?? [0, 0, 0];
  const rot = b.rotation ? [-b.rotation[0], -b.rotation[1], b.rotation[2]] : undefined;
  const g = group(uniq(RENAME[lname] ?? lname), [-piv[0], piv[1], piv[2]], rot);
  boneUuid.set(lname, g.uuid);
  if (lname === "righthandlocator") {
    const hand = group(uniq("ir_hand"), g.origin.map((v: number, i: number) => v + HAND_OFFSET[i]), HAND_TURN);
    g.children.push(hand);
    boneUuid.set("ir_hand", hand.uuid);
  }
  // cubes whose rotation an item model cannot hold go into their own rotated sub-bone
  const sub = new Map<string, any>();
  for (const c of b.cubes ?? []) {
    const el = makeCube(c, lname);
    if (el.rotation && !validRot(el.rotation)) {
      const key = el.rotation.join(",");
      if (!sub.has(key)) {
        const sg = group(uniq(`${lname}_rot`), el.origin, el.rotation);
        sub.set(key, sg);
        g.children.push(sg);
        wrapped++;
      }
      const sg = sub.get(key);
      const d = shiftFor(el.rotation, el.origin, sg.origin);
      for (let i = 0; i < 3; i++) { el.from[i] += d[i]; el.to[i] += d[i]; }
      el.origin = [...sg.origin];
      delete el.rotation;
      sg.children.push(el.uuid);
    } else {
      g.children.push(el.uuid);
    }
    elements.push(el);
  }
  for (const c of children.get(lname) ?? []) if (useful(c)) g.children.push(build(c));
  return g;
}
const outliner = (children.get("") ?? []).filter(useful).map(build);
// ModelEngine hitbox: a box as tall as the model, 8px wide
{
  const top = Math.ceil(Math.max(...elements.map((e) => e.to[1])));
  const hb = group("hitbox", [0, Math.round(top * 0.8), 0], undefined); // origin y = eye height
  const el = makeCube({ origin: [-4, 0, -4], size: [8, top, 8], uv: [0, 0] }, "hitbox");
  elements.push(el); hb.children.push(el.uuid); outliner.push(hb);
}

// ── animations ──
const vec = (x: any): any[] | null => {
  if (x == null) return null;
  if (Array.isArray(x)) return x;
  if (typeof x === "number" || typeof x === "string") return [x, x, x];
  if (x.vector) return vec(x.vector);
  if (x.post !== undefined) return vec(x.post);
  if (x.pre !== undefined) return vec(x.pre);
  return null;
};
const num = (v: any) => {
  if (typeof v === "number") return v;
  const n = Number(v);
  if (!Number.isFinite(n)) throw new Error("molang value: " + v);
  return n;
};
const animations: any[] = [];
let skippedMolang = 0;
for (const [src, dst] of Object.entries(KEEP_ANIMS)) {
  const a = anims[src];
  if (!a) continue;
  const animators: any = {};
  let maxT = 0;
  for (const [bn, chans] of Object.entries<any>(a.bones ?? {})) {
    const id = boneUuid.get(bn.toLowerCase());
    if (!id) continue; // bone not in this model (shared rig) or hidden
    const kfs: any[] = [];
    for (const ch of ["rotation", "position", "scale"]) {
      const c = chans[ch];
      if (c === undefined) continue;
      const entries: [number, any][] =
        (Array.isArray(c) || typeof c !== "object" || c.vector !== undefined || c.post !== undefined)
          ? [[0, c]]
          : Object.entries(c).map(([t, v]) => [Number(t), v]);
      for (const [t, v] of entries) {
        const p = vec(v);
        if (!p) continue;
        let xyz: number[];
        try { xyz = p.map(num); } catch { skippedMolang++; continue; }
        maxT = Math.max(maxT, t);
        const interp = (typeof v === "object" && !Array.isArray(v) && v.lerp_mode) ? v.lerp_mode : "linear";
        kfs.push({
          channel: ch, data_points: [{ x: String(xyz[0]), y: String(xyz[1]), z: String(xyz[2]) }],
          uuid: uuid(), time: t, color: -1, interpolation: interp === "catmullrom" ? "catmullrom" : "linear",
          easing: "linear", easingArgs: [],
        });
      }
    }
    if (kfs.length) {
      // name as ModelEngine knows the bone
      const g = findGroup(outliner, id)!;
      animators[id] = { name: g.name, type: "bone", keyframes: kfs };
    }
  }
  // the held item is drawn at hand size in every animation
  const handId = boneUuid.get("ir_hand");
  if (handId) {
    animators[handId] = { name: findGroup(outliner, handId).name, type: "bone", keyframes: [{
      channel: "scale", data_points: [{ x: String(HAND_SCALE), y: String(HAND_SCALE), z: String(HAND_SCALE) }],
      uuid: uuid(), time: 0, color: -1, interpolation: "linear", easing: "linear", easingArgs: [] }] };
  }
  animations.push({
    uuid: uuid(), name: dst, loop: a.loop ? "loop" : "once", override: false,
    length: a.animation_length ?? Math.max(maxT, 0.05), snapping: 24, selected: false,
    anim_time_update: "", blend_weight: "", start_delay: "", loop_delay: "", animators,
  });
}
function findGroup(list: any[], id: string): any {
  for (const g of list) {
    if (typeof g !== "object") continue;
    if (g.uuid === id) return g;
    const r = findGroup(g.children, id);
    if (r) return r;
  }
  return null;
}

let b64 = "";
{ const CH = 0x8000; let s = ""; for (let i = 0; i < png.length; i += CH) s += String.fromCharCode(...png.subarray(i, i + CH)); b64 = btoa(s); }

const out = {
  meta: { format_version: "4.10", model_format: "free", box_uv: false },
  name: modelName, model_identifier: "", visible_box: [1, 1, 0], variable_placeholders: "",
  variable_placeholder_buttons: [], timeline_setups: [], unhandled_root_fields: {},
  resolution: { width: TW, height: TH },
  elements, outliner,
  textures: [{
    path: "", name: `${modelName}.png`, folder: "", namespace: "", id: "0", group: "", width: TW, height: TH,
    uv_width: TW, uv_height: TH, particle: false, use_as_default: false, layers_enabled: false,
    sync_to_project: "", render_mode: "default", render_sides: "auto", pbr_channel: "color", frame_time: 1,
    frame_order_type: "loop", frame_order: "", frame_interpolate: false, visible: true, internal: true,
    saved: true, uuid: uuid(), relative_path: `${modelName}.png`, source: "data:image/png;base64," + b64,
  }],
  animations,
};
Deno.writeTextFileSync(outFile, JSON.stringify(out, null, "\t"));
console.log(`${ch}: elements=${elements.length} bones=${usedNames.size} rotSubBones=${wrapped} dropped=${[...dropped].join("/")} anims=${animations.map((a) => a.name + "(" + Object.keys(a.animators).length + ")").join(",")} molangSkipped=${skippedMolang}`);
