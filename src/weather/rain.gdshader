// M010: rain falling over the city, on a screen-wide rect under the HUD. Two
// layers of slanting streaks (the nearer faster and brighter) and small rings
// where drops land; anchored to the world, so the rain moves with it as the
// camera follows Danny. `intensity` 0 draws nothing.
shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec2 offset = vec2(0.0);
uniform float zoom = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	if (intensity <= 0.001) {
		discard;
	}
	vec2 px = FRAGCOORD.xy;
	float a = 0.0;
	for (int l = 0; l < 2; l++) {
		float near = l == 0 ? 1.0 : 0.62;
		vec2 q = (px + offset * zoom * (0.5 + 0.3 * near)) / near;
		q.x += q.y * 0.2;
		q.y -= TIME * (950.0 + 250.0 * near);
		vec2 cell = vec2(10.0, 78.0);
		vec2 id = floor(q / cell);
		vec2 f = fract(q / cell);
		float rnd = hash(id + float(l) * 17.0);
		float here = step(1.0 - intensity * (0.5 + 0.12 * near), rnd);
		float x0 = 0.15 + hash(id + 3.1) * 0.7;
		float streak = smoothstep(0.14, 0.0, abs(f.x - x0)) * smoothstep(0.0, 0.3, f.y) * smoothstep(1.0, 0.6, f.y);
		a += streak * here * (0.22 + 0.16 * near);
	}
	vec2 s = (px + offset * zoom) / (34.0 * zoom);
	vec2 sid = floor(s);
	float ph = fract(TIME * 1.4 + hash(sid) * 7.0);
	vec2 sc = fract(s) - (0.25 + vec2(hash(sid + 1.3), hash(sid + 2.7)) * 0.5);
	float ring = smoothstep(0.035, 0.0, abs(length(sc) - ph * 0.22)) * (1.0 - ph);
	a += ring * 0.3 * step(1.0 - intensity * 0.55, hash(sid + 9.0));
	COLOR = vec4(0.68, 0.74, 0.86, clamp(a * intensity, 0.0, 0.55) + 0.05 * intensity);
}
