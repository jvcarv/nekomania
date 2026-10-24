shader_type canvas_item;
// Chão procedural: grama/terra com manchas, tufos e flores, em coordenadas do mundo.

uniform vec4 col_a : source_color = vec4(0.33, 0.52, 0.22, 1.0);
uniform vec4 col_b : source_color = vec4(0.27, 0.45, 0.19, 1.0);
uniform vec4 col_c : source_color = vec4(0.40, 0.60, 0.27, 1.0);
uniform vec4 flower : source_color = vec4(1.0, 0.9, 0.5, 1.0);
uniform float seed = 0.0;

varying vec2 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash(vec2 p) {
	p = mod(p + seed, 4096.0);
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
	           mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 p = floor(wpos / 2.0);           // "pixels" de 2x2 no mundo
	float n = vnoise(p / 45.0) * 0.6 + vnoise(p / 15.0) * 0.3 + vnoise(p / 4.0) * 0.1;
	vec3 c = mix(col_b.rgb, col_a.rgb, smoothstep(0.38, 0.52, n));
	c = mix(c, col_c.rgb, smoothstep(0.62, 0.72, n));
	float h = hash(p);
	if (h > 0.975) { c = col_c.rgb * 1.12; }
	else if (h < 0.02) { c = col_b.rgb * 0.82; }
	if (hash(p + 31.7) > 0.9975) { c = flower.rgb; }
	COLOR = vec4(c, 1.0);
}
