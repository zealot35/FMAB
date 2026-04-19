shader_type spatial;
uniform sampler2D Noise;
uniform float time : hint_range(0.0, 1.0, 0.01);
uniform vec2 dir; // Direction that the Noisemap will scroll to
uniform vec3 emission;
uniform float alpha : hint_range(0.0, 1.0, 0.01);
uniform float freq : hint_range(0.0, 5.0, 0.01) = 1.0;
uniform float amp : hint_range(0.0, 5.0, 0.01) = 3.0;
uniform float offset : hint_range(0.0, 5.0, 0.01) = 2.21;

void fragment(){
	vec2 uv = UV;
	vec2 move = dir * time * TIME;
	ALBEDO.rgb = texture(Noise, uv += move).rgb;
	float pulse_color = sin((TIME * freq) * amp) + offset;
	ALPHA = alpha;
	EMISSION = emission;
	//go ahead and mess around with the values and see what suits the best, by default i set it to blue
	EMISSION.b = pulse_color;
}