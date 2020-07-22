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
};


vertex float4 vertexShader(device float4 *position [[ buffer(0) ]],
                           uint vid [[ vertex_id]]) {
    return position[vid];
}

fragment half4 fragmentShader(VertexIn vertexIn [[ stage_in ]]) {
    return half4(vertexIn.position.x / 800, vertexIn.position.y / 500, 0, 1);
}


