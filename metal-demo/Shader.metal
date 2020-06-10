//
//  Shader.metal
//  metal-demo
//
//  Created by 前川　知紀 on 2020/06/10.
//  Copyright © 2020 前川　知紀. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct MyVertex {
    float4 position [[position]];
    float4 color;
};

struct Constants {
    float animateXBy;
    float animateYBy;
};

vertex MyVertex myVertexShader(device float4 *position [[ buffer(0) ]],
                               device float4 *color [[ buffer(1) ]],
                               constant Constants &constants [[ buffer(2) ]],
                               uint vertexId [[vertex_id]]) {
    
    MyVertex v;
    v.position = position[vertexId];
    v.position.x += constants.animateXBy;
    v.position.y += constants.animateYBy;
    v.color = color[vertexId] + float4(0.0, 0.0, constants.animateYBy, 0.0);
    v.color = color[vertexId] + float4(constants.animateYBy);
    return v;
}

fragment float4 myFragmentShader(MyVertex vertexIn [[stage_in]]) {
    return vertexIn.color;
}
