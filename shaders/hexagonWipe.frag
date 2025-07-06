// Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel

#pragma header

#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
#define iChannel0 bitmap
uniform sampler2D iChannel1;
#define round(a) floor(a+.5)
#define texture flixel_texture2D

// end of ShadertoyToFlixel header

const float density = 6. * 6.;
const float speed = 1.0;
const float boundary_size = 0.6; //0..1, ideally
const float antialiasing_intensity = 2.;
// ^ play with these constants!

vec4 primary;
vec4 secondary;

const float PI = 3.1415926535897932385;
const float s3o2 = sqrt(3.)/2.;
const float cell_radius = 1./density;
// ^ probably best not to touch these.

float modulus(float a, float b) {
    return a - b * floor(a / b);
}

vec2 axial_round(vec2 fractional_axial){
	float fractional_q = fractional_axial.x;
	float fractional_r = fractional_axial.y;
	float fractional_s = 0. - fractional_q - fractional_r;

	float whole_q = round(fractional_q);
	float whole_r = round(fractional_r);
	float whole_s = round(fractional_s);

	float q_diff = abs(fractional_q - whole_q);
	float r_diff = abs(fractional_r - whole_r);
	float s_diff = abs(fractional_s - whole_s);

	float q = mix(whole_q, -whole_r-whole_s, step(r_diff, q_diff) * step(s_diff, q_diff));
	float r = mix(whole_r, -whole_q-whole_s, step(q_diff, r_diff) * step(s_diff, r_diff));

	return vec2(q, r);
}

vec2 axial_to_cartesian(vec2 axial, float grid_scale)
{
    float x = (sqrt(3.0) * axial.x + sqrt(3.0) / 2.0 * axial.y)/grid_scale;
    float y = (3.0 / 2.0 * axial.y)/grid_scale;
	
    return vec2(x, y);
}

vec2 cartesian_to_fractional_axial(vec2 cartesian, float grid_scale)
{
    float q = ((cartesian.x / sqrt(3.0)) - (cartesian.y / 3.0)) * grid_scale;
    float r = (2.0 * cartesian.y / 3.0) * grid_scale;

    return vec2(q, r);
}

vec2 cartesian_to_whole_axial(vec2 cartesian, float grid_scale)
{
	return axial_round(cartesian_to_fractional_axial(cartesian, grid_scale));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.x; //only accounting for width, keeping aspect
    
    primary = texture(iChannel0, uv);
    secondary = texture(iChannel1, uv);
    
    vec2 cell_center_axial = cartesian_to_whole_axial(uv, density);
	vec2 cell_center = axial_to_cartesian(cell_center_axial, density);
        
    float dist_from_cell_center = distance(cell_center, uv);
    
    float timer = iTime * speed;
    float flip = step(sin(timer + uv.x), 0.0);
    
    float oscillator = cos(timer + uv.x)*(1./boundary_size);
        
    float distance_threshold = mix(0., cell_radius, oscillator);
    
    ////leaving the un-antialiased version because it's easier to understand
    //vec4 color = mix(primary, secondary, step(dist_from_cell_center, distance_threshold));
    //vec4 flipped = mix(secondary, primary, step(dist_from_cell_center, distance_threshold*-1.));
        
    float proximity = (distance_threshold - dist_from_cell_center)*density;
    float flipped_proximity = (distance_threshold*-1. - dist_from_cell_center)*density;
    proximity = mix(proximity, flipped_proximity, flip);
    float scaled_proximity = proximity*iResolution.x/density/antialiasing_intensity;
    
    vec4 color = mix(primary, secondary, smoothstep(0., 1., scaled_proximity));
    vec4 flipped_color = mix(secondary, primary, smoothstep(0., 1., scaled_proximity));
    
    fragColor = mix(color, flipped_color, flip);
}

void main() {
	mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
}