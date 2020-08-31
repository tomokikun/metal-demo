//
//  Shader.metal
//  FilteringWithMetal
//
//  Created by 前川　知紀 on 2020/07/22.
//  Copyright © 2020 Maekawa Tomoki. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[ position ]];
    float2 texCoor;
};

vertex VertexIn vertexShader(device float4 *position [[ buffer(0) ]],
                           device float2 *texCoor [[ buffer(1) ]],
                           uint vid [[ vertex_id]]) {
    return {
        position[vid],
        texCoor[vid],
    };
}

half4 normalFilter3x3(float2 pos, texture2d<float> tex) {
    constexpr sampler defaultSampler;
    
    const float width = 6016.0;
    const float height = 3384.0;
    const float dw = 1.0 / width;
    const float dh = 1.0 / height;
    
    const float3x3 normalF = float3x3(float3(1.0/9.0, 1.0/9.0, 1.0/9.0),
                                      float3(1.0/9.0, 1.0/9.0, 1.0/9.0),
                                      float3(1.0/9.0, 1.0/9.0, 1.0/9.0)) * 0.35;
    // 0 1 2
    // 3 4 5
    // 6 7 8
    float4 c_0 = float4(tex.sample(defaultSampler, pos + float2(-dw, -dh)));
    float4 c_1 = float4(tex.sample(defaultSampler, pos + float2(0.0, -dh)));
    float4 c_2 = float4(tex.sample(defaultSampler, pos + float2(dw, -dh)));
    float4 c_3 = float4(tex.sample(defaultSampler, pos + float2(-dw, 0.0)));
    float4 c_4 = float4(tex.sample(defaultSampler, pos + float2(0.0, 0.0)));
    float4 c_5 = float4(tex.sample(defaultSampler, pos + float2(dw, 0.0)));
    float4 c_6 = float4(tex.sample(defaultSampler, pos + float2(-dw, dh)));
    float4 c_7 = float4(tex.sample(defaultSampler, pos + float2(0.0, dh)));
    float4 c_8 = float4(tex.sample(defaultSampler, pos + float2(dw, dh)));

    float3x3 r = float3x3(float3(c_0.r, c_1.r, c_2.r),
                          float3(c_3.r, c_4.r, c_5.r),
                          float3(c_6.r, c_7.r, c_8.r)) * normalF;
    float3x3 g = float3x3(float3(c_0.g, c_1.g, c_2.g),
                          float3(c_3.g, c_4.g, c_5.g),
                          float3(c_6.g, c_7.g, c_8.g)) * normalF;
    float3x3 b = float3x3(float3(c_0.b, c_1.b, c_2.b),
                          float3(c_3.b, c_4.b, c_5.b),
                          float3(c_6.b, c_7.b, c_8.b)) * normalF;
    
    float sr = 0;
    float sg = 0;
    float sb = 0;

    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            sr += r[i][j];
            sg += g[i][j];
            sb += b[i][j];
        }
    }

    return half4(sr, sg, sb, 1.0);;
}

//half4 normalFilter5x5(float2 pos, texture2d<float> tex) {
//    constexpr sampler defaultSampler;
//
////    const float width = 6016.0;
////    const float height = 3384.0;
//    const float width = 256.0;
//    const float height = 256.0;
//    const float dw = 1.0 / width;
//    const float dh = 1.0 / height;
//
//    const float3x3 normalF = float3x3(float3(1.0/25.0, 1.0/25.0, 1.0/25.0),
//                                      float3(1.0/25.0, 1.0/25.0, 1.0/25.0),
//                                      float3(1.0/25.0, 1.0/25.0, 1.0/25.0));
//    // 00 01 02 03 04
//    // 05 06 07 08 09
//    // 10 11 12 13 14
//    // 15 16 17 18 19
//    // 20 21 22 23 24
//
//    // -1, 1, 0, -2, 2
//    float4 c_0 = float4(tex.sample(defaultSampler, pos + float2(-dw, -dh)));
//    float4 c_1 = float4(tex.sample(defaultSampler, pos + float2(0.0, -dh)));
//    float4 c_2 = float4(tex.sample(defaultSampler, pos + float2(dw, -dh)));
//    float4 c_3 = float4(tex.sample(defaultSampler, pos + float2(-dw, 0.0)));
//    float4 c_4 = float4(tex.sample(defaultSampler, pos + float2(0.0, 0.0)));
//    float4 c_5 = float4(tex.sample(defaultSampler, pos + float2(dw, 0.0)));
//    float4 c_6 = float4(tex.sample(defaultSampler, pos + float2(-dw, dh)));
//    float4 c_7 = float4(tex.sample(defaultSampler, pos + float2(0.0, dh)));
//    float4 c_8 = float4(tex.sample(defaultSampler, pos + float2(dw, dh)));
//    float4 c_9 = float4(tex.sample(defaultSampler, pos + float2(-dw, -dh)));
//    float4 c_10 = float4(tex.sample(defaultSampler, pos + float2(0.0, -dh)));
//    float4 c_11 = float4(tex.sample(defaultSampler, pos + float2(dw, -dh)));
//    float4 c_12 = float4(tex.sample(defaultSampler, pos + float2(-dw, 0.0)));
//    float4 c_13 = float4(tex.sample(defaultSampler, pos + float2(0.0, 0.0)));
//    float4 c_14 = float4(tex.sample(defaultSampler, pos + float2(dw, 0.0)));
//    float4 c_15 = float4(tex.sample(defaultSampler, pos + float2(-dw, dh)));
//    float4 c_16 = float4(tex.sample(defaultSampler, pos + float2(0.0, dh)));
//    float4 c_17 = float4(tex.sample(defaultSampler, pos + float2(dw, dh)));
//    float4 c_18 = float4(tex.sample(defaultSampler, pos + float2(-dw, -dh)));
//    float4 c_19 = float4(tex.sample(defaultSampler, pos + float2(0.0, -dh)));
//    float4 c_20 = float4(tex.sample(defaultSampler, pos + float2(dw, -dh)));
//    float4 c_21 = float4(tex.sample(defaultSampler, pos + float2(-dw, 0.0)));
//    float4 c_22 = float4(tex.sample(defaultSampler, pos + float2(0.0, 0.0)));
//    float4 c_23 = float4(tex.sample(defaultSampler, pos + float2(dw, 0.0)));
//    float4 c_24 = float4(tex.sample(defaultSampler, pos + float2(-dw, dh)));
//
//    float r = float(c_0.r, c_1.r, c_2.r, c_3.r, c_4.r, c_5.r,
//                    c_6.r, c_7.r, c_8.r, c_9.r, c_10.r, c_11.r,
//                    c_12.r, c_13.r, c_14.r, c_15.r, c_16.r, c_17.r,
//                    c_18.r, c_19.r, c_20.r, c_21.r, c_22.r, c_23.r)
////    float3x3 r = float3x3(float3(c_0.r, c_1.r, c_2.r),
////                          float3(c_3.r, c_4.r, c_5.r),
////                          float3(c_6.r, c_7.r, c_8.r)) * normalF;
////    float3x3 g = float3x3(float3(c_0.g, c_1.g, c_2.g),
////                          float3(c_3.g, c_4.g, c_5.g),
////                          float3(c_6.g, c_7.g, c_8.g)) * normalF;
////    float3x3 b = float3x3(float3(c_0.b, c_1.b, c_2.b),
////                          float3(c_3.b, c_4.b, c_5.b),
////                          float3(c_6.b, c_7.b, c_8.b)) * normalF;
//
//    float sr = 0;
//    float sg = 0;
//    float sb = 0;
//
//    for (int i = 0; i < 3; i++) {
//        for (int j = 0; j < 3; j++) {
//            sr += r[i][j];
//            sg += g[i][j];
//            sb += b[i][j];
//        }
//    }
//
//    return half4(sr, sg, sb, 1.0);;
//}

fragment half4 fragmentShader(VertexIn vertexIn [[ stage_in ]],
                              texture2d<float, access::sample> texture [[ texture(0) ]]) {
    constexpr sampler defaultSampler;
    vertexIn.texCoor.y = 1 - vertexIn.texCoor.y;
    half4 color = half4(texture.sample(defaultSampler, vertexIn.texCoor.xy));
    color = normalFilter3x3(vertexIn.texCoor.xy, texture);
    return color;
}
