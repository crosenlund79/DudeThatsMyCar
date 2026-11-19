// M010: rain falling over the city, on a screen-wide rect under the HUD. Two
// layers of slanting streaks (the nearer faster and brighter) and small rings
// where drops land; anchored to the world, so the rain moves with it as the
// camera follows Danny. `intensity` 0 draws nothing.
// M012: the wind sets the slant (`slant`, sideways px a px of fall); a
// downpour (`heavy`) packs the streaks tighter and draws them longer; a
// lightning `flash` lights the whole street for a moment; and no rain falls
// in `hole` (the building whose room Danny is in, as a part of this rect,
// x, y, w, h in 0..1 - zero size for none).
shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec2 offset = vec2(0.0);
uniform float zoom = 1.0;
uniform float slant = 0.2;
uniform float heavy : hint_range(0.0, 1.0) = 0.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 hole = vec4(0.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	if (intensity <= 0.001 && flash <= 0.001) {
		discard;
	}
	if (hole.z > 0.0 && UV.x > hole.x && UV.x < hole.x + hole.z && UV.y > hole.y && UV.y < hole.y + hole.w) {
		discard;  // under the roof of the room he is in: dry
	}
	vec2 px = FRAGCOORD.xy;
	float a = 0.0;
	for (int l = 0; l < 2; l++) {
		float near = l == 0 ? 1.0 : 0.62;
		vec2 q = (px + offset * zoom * (0.5 + 0.3 * near)) / near;
		q.x += q.y * slant;
		q.y -= TIME * (950.0 + 250.0 * near + 300.0 * heavy);
		vec2 cell = vec2(10.0 - 3.0 * heavy, 78.0 + 30.0 * heavy);
		vec2 id = floor(q / cell);
		vec2 f = fract(q / cell);
		float rnd = hash(id + float(l) * 17.0);
		float here = step(1.0 - intensity * (0.5 + 0.12 * near + 0.25 * heavy), rnd);
		float x0 = 0.15 + hash(id + 3.1) * 0.7;
		float streak = smoothstep(0.14, 0.0, abs(f.x - x0)) * smoothstep(0.0, 0.3, f.y) * smoothstep(1.0, 0.6, f.y);
		a += streak * here * (0.22 + 0.16 * near);
	}
	vec2 s = (px + offset * zoom) / (34.0 * zoom);
	vec2 sid = floor(s);
	float ph = fract(TIME * (1.4 + 0.8 * heavy) + hash(sid) * 7.0);
	vec2 sc = fract(s) - (0.25 + vec2(hash(sid + 1.3), hash(sid + 2.7)) * 0.5);
	float ring = smoothstep(0.035, 0.0, abs(length(sc) - ph * 0.22)) * (1.0 - ph);
	a += ring * 0.3 * step(1.0 - intensity * (0.55 + 0.3 * heavy), hash(sid + 9.0));
	vec4 rain = vec4(0.68, 0.74, 0.86, clamp(a * intensity, 0.0, 0.6) + (0.05 + 0.04 * heavy) * intensity);
	// lightning: a cold, even light over the street for a breath
	COLOR = mix(rain, vec4(0.82, 0.86, 1.0, 0.5), flash * 0.55);
}
