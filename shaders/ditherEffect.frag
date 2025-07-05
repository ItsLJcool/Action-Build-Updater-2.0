// Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel

#pragma header

#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
#define iChannel0 bitmap
uniform sampler2D iChannel1;
#define texture flixel_texture2D

// end of ShadertoyToFlixel header

#define SCALE 20.0
#define PI 3.141592
    
float dither[64] = float[64]
    (0., 32., 8., 40., 2., 34., 10., 42.,
     48., 16., 56., 24., 50., 18., 58., 26.,
     12., 44., 4., 36., 14., 46., 6., 38.,
     60., 28., 52., 20., 62., 30., 54., 22.,
     3., 35., 11., 43., 1., 33., 9., 41.,
     51., 19., 59., 27., 49., 17., 57., 25.,
     15., 47., 7., 39., 13., 45., 5., 37.,
     63., 31., 55., 23., 61., 29., 53., 21.);

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{    
    vec2 uv = fragCoord/iResolution.xy;
    
    vec3 col1 = texture(iChannel0, uv).rgb;
    vec3 col2 = texture(iChannel1, uv).rgb;
    
    uv.x *= iResolution.x/iResolution.y;
    float x = uv.x;
    uv = floor(fract(uv * SCALE) * 8.0) * 0.125;
    
    float d = uv.x + 8.0 * uv.y;
    d = dither[int(d*8.0)]/64.0;
    
    float c = sin(x + iTime) + 0.5;
    col1 = mix(col2, col1, smoothstep(d, d, clamp(0.0, 1.0, c)));
    
    fragColor = vec4(col1, texture(iChannel1, uv).a);
}

void main() {
	mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
}