// M010: Danny's tiredness before dawn: a soft dark vignette closing in from the
// edges (breathing slowly), and now and then a heavy blink that dims the view.
shader_type canvas_item;

uniform float level : hint_range(0.0, 1.0) = 0.0;
uniform float blink : hint_range(0.0, 1.0) = 0.0;
uniform float breath = 0.0;

void fragment() {
	if (level <= 0.001 && blink <= 0.001) {
		discard;
	}
	vec2 c = UV - vec2(0.5);
	c.x *= 1.6;
	float r = length(c);
	float inner = mix(0.95, 0.3, level) + breath * 0.04;
	float edge = smoothstep(inner, inner + 0.5, r) * (0.3 + 0.7 * level);
	float a = clamp(edge + blink * 0.6 * level, 0.0, 0.92);
	COLOR = vec4(0.01, 0.01, 0.03, a);
}
