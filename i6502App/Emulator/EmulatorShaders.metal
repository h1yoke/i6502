#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>

using namespace metal;

[[ stitchable ]] float2 crtDistortion(float2 position, float4 bounds, float strength) {
    float2 center = float2(bounds.x + bounds.z / 2.0, bounds.y + bounds.w / 2.0);
    float2 uv = (position - center) / (float2(bounds.z, bounds.w) / 2.0);

    float r2 = dot(uv, uv);
    uv *= 1.0 + strength * r2;

    return uv * (float2(bounds.z, bounds.w) / 2.0) + center;
}

[[ stitchable ]] half4 phosphorGlow(
    float2 position,
    SwiftUI::Layer layer,
    float radius,
    float intensity
) {
    half4 original = layer.sample(position);
    half4 glow = half4(0);
    float totalWeight = 0.0;

    for (float x = -radius; x <= radius; x += 1.0) {
        for (float y = -radius; y <= radius; y += 1.0) {
            float dist = length(float2(x, y));
            if (dist > radius) continue;

            float weight = exp(-dist * dist / (2.0 * (radius * 0.4) * (radius * 0.4)));
            glow += layer.sample(position + float2(x, y)) * half(weight);
            totalWeight += weight;
        }
    }
    glow /= half(totalWeight);
    return original + glow * half(intensity);
}

[[ stitchable ]] half4 scanlines(float2 position, half4 color, float lineSpacing, float opacity) {
    float scanline = step(0.5, fract(position.y / lineSpacing));
    return color * half4(1.0, 1.0, 1.0, 1.0 - half(opacity) * half(scanline));
}
