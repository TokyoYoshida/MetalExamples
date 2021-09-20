//
//  SimpleShaderType.h
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/05.
//

#ifndef SimpleShaderType_h
#define SimpleShaderType_h


#endif /* SimpleShaderType_h */

struct ColorInOut
{
    float4 position [[ position ]];
    float size [[point_size]];
    float2 texCords;
};
