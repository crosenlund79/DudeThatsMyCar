// M012: the fog banked at the buildings' feet (City's FogFeet mesh, coloured
// by its vertices and the layer's modulate) - kept out of the building whose
// room Danny is in, like the street fog (`hole`: world x, y, w, h).
shader_type canvas_item;

uniform vec4 hole = vec4(0.0);

varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	if (hole.z > 0.0 && world.x > hole.x && world.x < hole.x + hole.z && world.y > hole.y && world.y < hole.y + hole.w) {
		discard;
	}
}
