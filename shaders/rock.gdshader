shader_type spatial;

uniform sampler2D noise_tex;
uniform sampler2D normal_tex : hint_normal;
uniform float bump_depth : hint_range(0.0, 5.0) = 1.5;

void fragment() {
	float n = texture(noise_tex, UV * 8.0).r;

	// Fake Bumps
	NORMAL_MAP = texture(normal_tex, UV).xyz;
	NORMAL_MAP_DEPTH = bump_depth;

	// Color variation
	ALBEDO = vec3(0.45, 0.45, 0.42) + (n - 0.5) * 0.08;

	// Random roughness across the surface
	ROUGHNESS = mix(0.6, 0.95, n);

	// Control specular
	METALLIC = 0.0;
}