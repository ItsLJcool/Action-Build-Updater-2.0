#pragma header

uniform float corner_pixel;
uniform vec2 box_size;

uniform bool use_pixels;
uniform bool custom_size = false;

float roundedBoxSDF(vec2 CenterPosition, vec2 Size, float Radius) {
    return smoothstep(0.0, 0.005, length(max(abs(CenterPosition) - Size + Radius, 0.0)) - Radius);
}

void main() {
    vec2 size = openfl_TextureSize;
    if (custom_size) size = box_size;

    vec2 ar = vec2(max(size.x/size.y, 1.0), max(size.y/size.x, 1.0));
    
    float radius = corner_pixel;
    if (use_pixels) radius /= min(size.x, size.y);
    
    float alpha = 1.0 - roundedBoxSDF(openfl_TextureCoordv * ar - vec2(0.5) * ar, vec2(0.5) * ar, radius);
    gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv) * alpha;
}