shader_type canvas_item;
render_mode blend_premul_alpha;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform sampler2D albedo_tex : source_color;
uniform bool  use_refraction = true;
uniform float refract_pixels : hint_range(0.0, 16.0) = 3.0;
uniform float albedo_mix : hint_range(0.0, 1.0)  = 0.30;
uniform float master_opacity : hint_range(0.0, 1.0)  = 1.0;
uniform vec3  glass_tint_color = vec3(0.85, 0.95, 1.0);
uniform float glass_tint : hint_range(0.0, 1.0) = 0.20;
uniform float edge_normal_gain : hint_range(0.0, 5.0)  = 1.4;
uniform float bulge_gain : hint_range(0.0, 4.0)  = 0.8;
uniform vec2  sphere_center = vec2(0.5, 0.5);
uniform float fresnel_power : hint_range(0.1, 5.0)  = 2.0;
uniform float rim_strength : hint_range(0.0, 1.0)  = 0.15;
uniform float min_px_for_refract : hint_range(0.0, 2.0)  = 1.0;
uniform float clamp_margin_uv : hint_range(0.0, 0.01) = 0.002;

float atex(vec2 uv){ return texture(albedo_tex, uv).a; }
float luma(vec3 c){ return dot(c, vec3(0.2126,0.7152,0.0722)); }

vec2 alpha_grad(vec2 uv){
    vec2 ts = 1.0 / vec2(textureSize(albedo_tex, 0));
    float aL = atex(uv - vec2(ts.x, 0.0));
    float aR = atex(uv + vec2(ts.x, 0.0));
    float aD = atex(uv - vec2(0.0, ts.y));
    float aU = atex(uv + vec2(0.0, ts.y));
    return vec2(aR - aL, aU - aD);
}

vec3 sample_screen_unpremul(vec2 uv, vec3 fallback_rgb){
    vec4 s = textureLod(SCREEN_TEXTURE, uv, 0.0);
    if (s.a > 0.001) {
        return s.rgb / s.a;
    } else {
        return fallback_rgb;
    }
}

void fragment(){
    vec4 sprite = texture(albedo_tex, UV);
    if (sprite.a <= 0.001) { discard; }

    vec2 g = alpha_grad(UV);
    float glen = length(g);
    vec2 edge_dir = (glen > 1e-5) ? (-g / glen) : vec2(0.0);

    float screen_aspect = (SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x);
    vec2 p = UV - sphere_center; p.x *= screen_aspect;
    float r2 = dot(p, p);
    vec2 bulge_dir = p * max(0.0, 1.0 - r2);

    vec2 sum = edge_dir * edge_normal_gain + bulge_dir * bulge_gain;
    float sum_len = length(sum);
    vec3 N = (sum_len > 1e-5) ? normalize(vec3(sum / sum_len, 1.0))
                              : vec3(0.0, 0.0, 1.0);

    float fresnel = pow(clamp(1.0 - N.z, 0.0, 1.0), fresnel_power);

    vec3 base_look = mix(sprite.rgb, glass_tint_color, glass_tint);

    vec3 refr_rgb = base_look;
    if (use_refraction) {
        vec2 px = vec2(SCREEN_PIXEL_SIZE.x, SCREEN_PIXEL_SIZE.y);
        vec2 offset_uv = (-N.xy) * refract_pixels * px;

        float min_uv = min_px_for_refract * min(px.x, px.y);
        bool do_refract = length(offset_uv) >= min_uv;

        vec2 uv = clamp(SCREEN_UV + (do_refract ? offset_uv : vec2(0.0)),
                        vec2(clamp_margin_uv), vec2(1.0 - clamp_margin_uv));

        vec3 bg = sample_screen_unpremul(uv, base_look);

        refr_rgb = mix(base_look, bg, 0.9);
    }

    vec3 final_rgb = mix(refr_rgb, sprite.rgb, albedo_mix);

    float bg_y = luma(refr_rgb);
    float rim_w = rim_strength * fresnel * smoothstep(0.10, 0.35, bg_y);
    final_rgb = clamp(final_rgb + rim_w, 0.0, 1.0);

    float out_a = sprite.a * master_opacity;
    COLOR = vec4(final_rgb * out_a, out_a);
}