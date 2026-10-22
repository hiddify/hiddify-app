precision highp float;

/** @resolution */
uniform vec2 u_resolution;
/** @time */
uniform float u_time;
/** @label Original Blizzard particle ribbon */
uniform sampler2D u_texture;
/** @label Logical frame width @default 353 */
uniform float u_width;
/** @label Logical frame height @default 260 */
uniform float u_height;
/** @label Button center from top @default 137 */
uniform float u_center_y;
/** @label Clear top area for status text @default 24 */
uniform float u_top_clear;
/** @label Action caption top @default 227 */
uniform float u_label_top;
/** @label Action caption width @default 94 */
uniform float u_label_width;
/** @label Ribbon source scale @default 0.58 */
uniform float u_scale;
/** @label Motion amount; zero for Reduce Motion @default 1 @range 0, 1 */
uniform float u_motion;
/** @label Motion phase in seconds @default 0 */
uniform float u_phase;
/** @label Ribbon intensity @default 0.64 @range 0, 1 */
uniform float u_intensity;
/** @label Blizzard ice tint @color @default #72D1FF */
uniform vec3 u_tint;

void main() {
    vec2 frame = vec2(u_width, u_height);
    vec2 point = vec2(gl_FragCoord.x / u_resolution.x,
                      1.0 - gl_FragCoord.y / u_resolution.y) * frame;
    vec2 delta = point - vec2(u_width * 0.5, u_center_y);
    float phase = (u_time * u_motion + u_phase) * 0.5235987756;
    float angle = 0.035 * sin(phase) * u_motion;
    mat2 turn = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    vec2 drift = vec2(3.0 * cos(phase), 2.0 * sin(phase)) * u_motion;
    vec2 textureSizePx = vec2(1168.0, 912.0);
    vec2 uv = 0.5 + turn * (delta - drift) / (textureSizePx * u_scale);
    vec3 source = texture2D(u_texture, uv).rgb;
    vec2 reverseUv = 0.5 - turn * (delta + drift * 0.4) / (textureSizePx * u_scale);
    vec3 reverseSource = texture2D(u_texture, reverseUv).rgb;
    float light = dot(source, vec3(0.2126, 0.7152, 0.0722));
    float particles = clamp((light - 0.045) * 1.8, 0.0, 1.0);
    float reverseLight = dot(reverseSource, vec3(0.2126, 0.7152, 0.0722));
    particles = max(particles, clamp((reverseLight - 0.045) * 1.8, 0.0, 1.0) * 0.62);
    float horizontal = 1.0 - smoothstep(u_width * 0.38, u_width * 0.5, abs(delta.x));
    float envelope = 1.0 - smoothstep(0.68, 1.08,
        length(delta / vec2(u_width * 0.5, u_center_y + 3.0)));
    float top = smoothstep(u_top_clear, u_top_clear + 24.0, point.y);
    float bottom = 1.0 - smoothstep(u_height - 28.0, u_height, point.y);
    vec2 captionDelta = abs(point - vec2(u_width * 0.5, u_label_top + 11.0))
        - vec2(u_label_width * 0.5 - 2.0, 4.0);
    float captionDistance = length(max(captionDelta, 0.0))
        + min(max(captionDelta.x, captionDelta.y), 0.0) - 10.0;
    float captionClear = smoothstep(-3.0, 5.0, captionDistance);
    float inside = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
    vec3 ice = mix(u_tint, vec3(0.85, 0.97, 1.0), smoothstep(0.45, 0.92, light) * 0.35);
    float alpha = particles * horizontal * envelope * top * bottom * captionClear * inside * u_intensity;
    gl_FragColor = vec4(ice * alpha, alpha);
}
