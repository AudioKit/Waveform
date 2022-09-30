
#include <metal_stdlib>
using namespace metal;

kernel void waveform_bin(device const float* in,
                         device float* out_min,
                         device float* out_max,
                         constant uint& count,
                         uint tid [[ thread_position_in_grid]]) {
    
    if(tid >= count) {
        return;
    }
    
    auto a = in[tid*2];
    auto b = in[tid*2+1];
    out_min[tid] = min(a, b);
    out_max[tid] = max(a, b);
}

struct FragIn {
    float4 position [[ position ]];
    float2 uv; // (0, 1) x (-1, 1)
};


constant float2 pos[4] = { {-1,-1}, {1,-1}, {-1,1}, {1,1 } };
constant float2 uv[4] = { {0, -1}, {1, -1}, {0,1}, {1,1 } };

vertex FragIn waveform_vert(uint id [[ vertex_id ]]) {
    FragIn out;
    out.position = float4(pos[id], 0, 1);
    out.uv = uv[id];
    return out;
}

struct Constants {
    
};

float sample_waveform(device const float* min_waveform,
                      device const float* max_waveform,
                      uint count,
                      float2 uv) {

    int x = clamp(int(count * uv.x), 0, int(count));

    auto min_value = min_waveform[x];
    auto max_value = max_waveform[x];
    
    auto falloff = 4 * length(fwidth(uv));
    
    // Feather the top and bottom.
    auto s0 = smoothstep(min_value - falloff, min_value, uv.y);
    auto s1 = 1.0 - smoothstep(max_value, max_value + falloff, uv.y);

    // return (uv.y > min_value && uv.y < max_value) ? 1.0 : 0.0;
    
    return s0 * s1;
}

// From the graph in https://medium.com/@warrenm/thirty-days-of-metal-day-20-multisample-antialiasing-374389136b06
constant float2 sample_offsets[8] = {
    {-5, -5},
    {-1, -3},
    {3, -7},
    {5, -1},
    {-7, 1},
    {-3, 5},
    {1, 3},
    {7,7}
};

fragment half4 waveform_frag(FragIn in   [[ stage_in ]],
                             device const float* min_waveform,
                             device const float* max_waveform,
                             constant uint& count,
                             constant Constants& constants) {

//    half s = 0.0;
//    for(int i=0;i<8;++i) {
//        auto off = length(fwidth(in.uv)) * (sample_offsets[i] / 8.0f);
//        s += sample_waveform(min_waveform, max_waveform, count, in.uv + off);
//    }
//    s /= 8;
    
    half s = sample_waveform(min_waveform, max_waveform, count, in.uv);
    
    return {1,1,1,s};

}
