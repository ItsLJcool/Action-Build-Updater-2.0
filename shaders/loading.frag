// Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel
// original shader by https://www.shadertoy.com/view/Xd3cR8
#pragma header

#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;

// end of ShadertoyToFlixel header

#define PI 3.14159

#define THICCNESS 0.08
#define RADIUS 0.35
#define SPEED 4.0

#define aa 2.0 / min(iResolution.x,iResolution.y)

vec2 remap(vec2 coord) {
	return coord / min(iResolution.x,iResolution.y);
}

float circle(vec2 uv, vec2 pos, float rad) {
	return 1.0 - smoothstep(rad,rad+0.005,length(uv-pos));
}

float ring(vec2 uv, vec2 pos, float innerRad, float outerRad) {
	return (1.0 - smoothstep(outerRad,outerRad+aa,length(uv-pos))) * smoothstep(innerRad-aa,innerRad,length(uv-pos));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = remap(fragCoord.xy);
    uv -= vec2(0.5 / iResolution.y * iResolution.x,0.5);

    float geo = 0.0;

    geo += ring(uv,vec2(0.0),RADIUS-THICCNESS,RADIUS);

    float rot = -iTime * SPEED;

    uv *= mat2(cos(rot), sin(rot), -sin(rot), cos(rot));

    float a = atan(uv.x,uv.y)*PI*0.05 + 0.5;

    a = max(a,circle(uv,vec2(0.0,-RADIUS+THICCNESS/2.0),THICCNESS/2.0));

    fragColor = vec4(a*geo);
}

void main() {
	mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
}