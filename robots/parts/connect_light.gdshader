shader_type spatial;

uniform float speed: hint_range(1.0, 2.0) = 1.0;
uniform bool enable = false;

void fragment() {
	if (enable == false) {
		ALBEDO = vec3(0,0,0);
	}
	else {
		float period = 1.0 / speed;
	if (mod(TIME, period) > (period / 2.0))
	{
		ALBEDO = vec3(0,0,0);
	}
	else {
		ALBEDO = vec3(1.0, 0.0, 0.0);
		EMISSION = vec3(1.0, 0.0, 0.0);
	}
	}
	
}
