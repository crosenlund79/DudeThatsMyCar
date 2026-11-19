// M010: rain falling over the city, on a screen-wide rect under the HUD.
// M012: a wind-driven slant, downpours, lightning, and no rain in `hole`.
// M013: rebuilt after the M012 rain ran upwards and doubled. The fall is no
// longer TIME times a speed that changes with the downpour (after a few minutes
// of play every change of speed threw the whole field by hundreds of pixels a
// frame - streaks jumped, ran up and showed twice); WeatherView integrates each
// layer's fall and the camera's movement into `anchor_*` (continuous, wrapped to
// the pattern's period), so whatever the downpour does the drops only ever move
// down along their slant. Coordinates are the rect's own logical pixels (UV x
// size), not the window's, so the rain stays fixed to the street at any window
// size. The cells never change size; columns are staggered and every drop has
// its own length and brightness (no rows marching in step); an integer hash
// (no sin() of huge numbers, which banded into patterns). Three depths, the
// nearer larger, faster and moving more as the camera pans; a streak is faint
// at its tail and bright at its head, and catches the light of what is under it
// (lamps, windows, headlights), nearly gone in the dark. Splashes are rings on
// a grid fixed to the street.
shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float heavy : hint_range(0.0, 1.0) = 0.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 hole = vec4(0.0);
// sideways px a px of fall (the wind)
uniform float slant = 0.15;
// the rect's size in logical px
uniform vec2 screen_size = vec2(1280.0, 720.0);
// per depth (near, middle, far): where the pattern stands (cell units x CELL, wrapped)
uniform vec2 anchor_near = vec2(0.0);
uniform vec2 anchor_mid = vec2(0.0);
uniform vec2 anchor_far = vec2(0.0);
// splashes: the street under the screen's centre in splash cells (wrapped), the
// size of a splash cell on screen (px), and how far each ring has spread (0..1, wrapped)
uniform vec2 splash_anchor = vec2(0.0);
uniform float splash_cell = 34.0;
uniform float splash_time = 0.0;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;

const vec2 CELL = vec2(12.0, 110.0);
const float PERIOD = 1024.0;

float hash(vec2 k, float salt) {
	uvec2 q = uvec2(ivec2(mod(k, PERIOD))) + uvec2(uint(salt) * 7919u, uint(salt) * 104729u);
	uint h = q.x * 1597334677u ^ q.y * 3812015801u;
	h ^= h >> 16u;
	h *= 2146121005u;
	h ^= h >> 15u;
	h *= 2221713035u;
	h ^= h >> 16u;
	return float(h) * (1.0 / 4294967296.0);
}

// one depth of falling drops: alpha of the streak at screen point p
float drops(vec2 p, vec2 anchor, float near, float layer, float density) {
	vec2 q = p / near + anchor;
	float col = floor(q.x / CELL.x);
	q.y += hash(vec2(col, 3.0), layer + 1.0) * CELL.y;  // each column its own stagger
	vec2 id = vec2(col, floor(q.y / CELL.y));
	vec2 f = q / CELL - id;
	if (hash(id, layer + 11.0) > density) {
		return 0.0;
	}
	float x0 = 0.2 + 0.6 * hash(id, layer + 21.0);
	float len = (0.46 + 0.24 * heavy) * (0.75 + 0.5 * hash(id, layer + 31.0));
	float y0 = (1.0 - len) * hash(id, layer + 41.0);
	float t = (f.y - y0) / len;  // 0 at the tail, 1 at the head
	if (t < 0.0 || t > 1.0) {
		return 0.0;
	}
	float dx = abs(f.x - x0) * CELL.x * near;  // screen px from the streak's line
	float w = 0.55 + 0.6 * near;
	float line = 1.0 - smoothstep(w, w + 0.9, dx);
	float along = (0.3 + 0.7 * t) * smoothstep(0.0, 0.12, t) * smoothstep(1.0, 0.93, t);
	return line * along * (0.55 + 0.45 * hash(id, layer + 51.0));
}

void fragment() {
	if (intensity <= 0.001 && flash <= 0.001) {
		discard;
	}
	if (hole.z > 0.0 && UV.x > hole.x && UV.x < hole.x + hole.z && UV.y > hole.y && UV.y < hole.y + hole.w) {
		discard;  // under the roof of the room he is in: dry
	}
	vec2 px = UV * screen_size;
	// the wind leans the fall about the middle of the screen
	vec2 p = vec2(px.x - (px.y - 0.5 * screen_size.y) * slant, px.y);
	float d = intensity * (0.5 + 0.22 * heavy);
	float a = drops(p, anchor_near, 1.0, 0.0, d * 0.8) * 0.9
		+ drops(p, anchor_mid, 0.72, 1.0, d) * 0.66
		+ drops(p, anchor_far, 0.5, 2.0, min(d * 1.1, 0.95)) * 0.45;
	// splashes on the street, a grid fixed to the ground
	vec2 s = (px - 0.5 * screen_size) / splash_cell + splash_anchor;
	vec2 sid = floor(s);
	if (hash(sid, 61.0) < intensity * (0.5 + 0.3 * heavy)) {
		float ph = fract(splash_time + hash(sid, 71.0));
		vec2 sc = fract(s) - (0.25 + vec2(hash(sid, 81.0), hash(sid, 91.0)) * 0.5);
		a += smoothstep(0.035, 0.0, abs(length(sc) - ph * 0.22)) * (1.0 - ph) * 0.3;
	}
	// the drops catch what light there is
	vec3 under = texture(screen_tex, SCREEN_UV).rgb;
	float lum = dot(under, vec3(0.3, 0.59, 0.11));
	vec3 col = mix(vec3(0.62, 0.68, 0.8), min(under * 1.6 + vec3(0.3), vec3(1.0)), 0.55);
	float alpha = clamp(a * intensity * (0.62 - 0.12 * heavy + 1.3 * lum), 0.0, 0.58) + (0.04 + 0.025 * heavy) * intensity;
	// lightning: a cold, even light over the street for a breath
	COLOR = mix(vec4(col, alpha), vec4(0.82, 0.86, 1.0, 0.5), flash * 0.55);
}
