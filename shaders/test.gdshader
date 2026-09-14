shader_type spatial;
render_mode blend_mix, cull_back, specular_toon;

uniform vec4 base_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_tex: source_color;
uniform float roughness: hint_range(0.0, 1.0) = 0.3;

uniform int band_count: hint_range(1, 6) = 3;
uniform float shadow_strength: hint_range(0, 1.0) = 0.4;

uniform vec4 rim_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float rim_width: hint_range(0.0, 1.0);
uniform float rim_strength: hint_range(0.0, 2.0);

void fragment() {
	float albedo = texture(albedo_tex, UV + vec2(TIME * 0.2, TIME * 0.1)).r;
	
	ALBEDO = (base_color * texture(albedo_tex, UV)).rgb;
	ROUGHNESS = roughness;
	
	float rim = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	rim = smoothstep(1.0 - rim_width, 1.0, rim) * rim_strength;
	
	EMISSION = rim_color.rgb * rim;
}

void light() {
	float ndotl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float banded = ceil(ndotl * float(band_count)) / float(band_count);
	
	if (ndotl <= 0.0001) {
		banded = 0.0;
	}
	
	float lit = mix(shadow_strength, 1.0, banded);
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION * lit;
}
