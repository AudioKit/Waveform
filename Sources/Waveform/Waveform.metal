
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


