shader_type spatial;
// https://www.shadertoy.com/view/XtBfzz

uniform float factor = 1.0;
uniform float N= 20;

float grid_texture(vec2 p) {
	// coordinates
    vec2 i = step( fract(p), vec2(1.0/N) );
	//pattern
    return (1.0-i.x)*(1.0-i.y);   // grid (N=10)
}

void fragment() {
	vec2 uv = UV*factor;
	vec3 col = vec3(grid_texture(uv));
	ALBEDO = col;
}
