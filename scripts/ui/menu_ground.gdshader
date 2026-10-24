shader_type canvas_item;
uniform vec2 offset = vec2(0.0);

float hash(vec2 p) { return fract(sin(dot(mod(p, 4096.0), vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
void fragment() {
	vec2 p = floor((FRAGCOORD.xy + offset * 6.0) / 6.0);
	float n = vnoise(p / 22.0) * 0.6 + vnoise(p / 7.0) * 0.3 + vnoise(p / 2.0) * 0.1;
	vec3 a = vec3(0.33, 0.52, 0.22), b = vec3(0.27, 0.45, 0.19), c = vec3(0.40, 0.60, 0.27);
	vec3 col = mix(b, a, smoothstep(0.38, 0.52, n));
	col = mix(col, c, smoothstep(0.62, 0.72, n));
	if (hash(p) > 0.975) col = c * 1.12;
	if (hash(p + 31.7) > 0.997) col = vec3(1.0, 0.9, 0.5);
	COLOR = vec4(col, 1.0);
}
