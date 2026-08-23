shader_type spatial;
render_mode unshaded;

uniform float fill_amount: hint_range(0.0, 1.0) = 1.0;
uniform vec4 bar_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			vec4(normalize(cross(vec3(0.0, 1.0, 0.0), MAIN_CAM_INV_VIEW_MATRIX[2].xyz)), 0.0),
			vec4(0.0, 1.0, 0.0, 0.0),
			vec4(normalize(cross(MAIN_CAM_INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
			MODEL_MATRIX[3]);
}

void fragment() {
	if (UV.x > fill_amount) {
		discard;
	}
	ALBEDO = bar_color.rgb;
	ALPHA = bar_color.a;
}