// M010: street-level fog. Drawn over the ground, the people and the cars but
// under the walls and the roofs, so it lies in the streets and alleys and the
// rooftops stand clear above it. Slow drifting banks (world-anchored noise),
// thinner in places; lit by the street lamps and headlights like the street
// (light_mask). Drawn on each district's open ground only (FogCover), whose
// vertices are world coordinates.
shader_type canvas_item;

uniform float density : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fog_color : source_color = vec4(0.66, 0.7, 0.78, 1.0);
// the banks: a seamless cloudy tile (fx/fog), drifted twice at different scales
uniform sampler2D banks_tex : repeat_enable, filter_linear;

varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	if (density <= 0.001) {
		discard;
	}
	vec2 w = world / 900.0;
	float banks = texture(banks_tex, w + vec2(TIME * 0.007, TIME * 0.0025)).r;
	float wisps = texture(banks_tex, w * 2.7 - vec2(TIME * 0.013, -TIME * 0.005)).r;
	float d = smoothstep(0.32, 0.74, banks * 0.8 + wisps * 0.35);
	float a = density * (0.08 + 0.55 * d);
	COLOR = vec4(fog_color.rgb, a);
}
