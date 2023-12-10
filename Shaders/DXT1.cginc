// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles

#define SVIO_DATABITS 16
#define SVIO_DATABLOCK_SIZE 2
#define SVIO_DATABLOCK_X 2
#define SVIO_COMPONENT_COUNT 4
#define SVIO_COMPONENT_COUNT_PER_COMPONENTBLOCK_PIXEL 2
#define SVIO_COMPONENTBLOCK_X 1
#include "../../net.narazaka.unity.shadervalueio/ShaderValueIO.cginc"
#ifndef DECODESCALE
#define DECODESCALE uint2(2, 2)
#endif

float4 UVColor(in float2 uv)
{
    return tex2Dlod(_MainTex, float4(uv, 0, 0));
}

float4 PixelColor(in uint2 pixelCoord)
{
    // +0.5 = center point of the pixel
    return UVColor((pixelCoord + 0.5) * _MainTex_TexelSize.xy);
}

// in color: normalized RGB float(0-1) color
// out color: normalized RGB565 color
// return: RGB565 16bit uint color
uint EncodeRGB565(inout float3 color)
{
    uint3 c = uint3(round(color * float3(31.0, 63.0, 31.0)));
    uint bits = (c.r << 11) | (c.g << 5) | c.b;
    c.rb = (c.rb << 3) | (c.rb >> 2);
    c.g = (c.g << 2) | (c.g >> 4);
    color = float3(c) * (1.0 / 255.0);
    return bits;
}

float3 DecodeRGB565(in uint value)
{
    return float3(
        float((value >> 11u) & 31u) * (1.0 / 31.0),
        float((value >> 5u) & 63u) * (1.0 / 63.0),
        float((value >> 0u) & 31u) * (1.0 / 31.0)
    );
}

float Distance(in float3 color1, in float3 color2)
{
    float3 diff = color1 - color2;
    return dot(diff, diff);
}

// return: 0-3
uint MinDistanceIndex(in float4 distances)
{
    uint4 b = uint4(
        distances.x > distances.w,
        distances.y > distances.z,
        distances.x > distances.z,
        distances.y > distances.w
    );
    uint b4 = distances.z > distances.w;
    return (b.x & b4) | (((b.y & b.z) | (b.x & b.w)) << 1);
}

// blockCoord: DXT1 block start index (4 * n, 4 * n)
// return: 16bit int * 4 (R16G16B16A16 etc)
uint4 EncodeDXT1(in uint2 blockCoord)
{
    float3 colors[16];
    int i;
    for (i = 0; i < 4; i++)
    {
        for (int j = 0; j < 4; j++)
        {
            colors[i * 4 + j] = PixelColor(blockCoord + uint2(j, i)).rgb;
        }
    }

    float3 minColor = colors[0];
    float3 maxColor = colors[0];
    for (i = 1; i < 16; i++)
    {
        minColor = min(minColor, colors[i]);
        maxColor = max(maxColor, colors[i]);
    }

    uint c0 = EncodeRGB565(maxColor);
    uint c1 = EncodeRGB565(minColor);
    // below: RGB565

    if (c1 > c0)
    {
        // swap
        uint utmp = c0;
        c0 = c1;
        c1 = utmp;
        float3 ftmp;
        ftmp = maxColor;
        maxColor = minColor;
        minColor = ftmp;
    }

    float3 color0 = maxColor;
    float3 color1 = minColor;
    float3 color2 = lerp(color0, color1, 1.0 / 3.0);
    float3 color3 = lerp(color0, color1, 2.0 / 3.0);

    uint indexTop = 0u;
    for (i = 0; i < 8; i++)
    {
        float3 color = colors[i];
        float4 dist = float4(
            Distance(color, color0),
            Distance(color, color1),
            Distance(color, color2),
            Distance(color, color3)
        );
        indexTop |= MinDistanceIndex(dist) << (i * 2);
    }

    uint indexBottom = 0u;
    for (i = 0; i < 8; i++)
    {
        float3 color = colors[i + 8];
        float4 dist = float4(
            Distance(color, color0),
            Distance(color, color1),
            Distance(color, color2),
            Distance(color, color3)
        );
        indexBottom |= MinDistanceIndex(dist) << (i * 2);
    }

    return uint4(c0, c1, indexTop, indexBottom);
}

// block: 16bit int * 4 (R16G16B16A16 etc)
// subpixelCoord: 0-3
float3 DecodeDXT1(in uint4 block, in uint2 subpixelCoord)
{
    float3 c0 = DecodeRGB565(block.x);
    float3 c1 = DecodeRGB565(block.y);
    float3 c2 = (2.0 * c0 + c1) / 3.0;
    float3 c3 = (2.0 * c1 + c0) / 3.0;
    float4x3 colors = float4x3(c0, c1, c2, c3);
    uint index = subpixelCoord.x + (subpixelCoord.y & 1u) * 4u;
    if (subpixelCoord.y < 2u)
    {
        return colors[(block.z >> (index * 2u)) & 3u];
    }
    else
    {
        return colors[(block.w >> (index * 2u)) & 3u];
    }
}

uint2 PixelCoord(in float2 uv)
{
    return uint2(uv * _MainTex_TexelSize.zw);
}

uint2 BlockCoord(in float2 uv)
{
    return PixelCoord(uv) & uint2(~3u, ~3u);
}

uint4 EncodeDXT1(in float2 uv)
{
    return EncodeDXT1(BlockCoord(uv));
}

uint2 SubpixelCoord(in uint2 pixelCoord)
{
    return pixelCoord & uint2(3u, 3u);
}

uint2 SubpixelCoord(in float2 uv)
{
    return SubpixelCoord(PixelCoord(uv * DECODESCALE));
}

float3 DecodeDXT1(in uint4 block, in float2 uv)
{
    return DecodeDXT1(block, SubpixelCoord(uv));
}

float4 BlockToNormalized(in uint4 block)
{
    return float4(block) / 65536;
}

uint4 NormalizedToBlock(in float4 normalized)
{
    return uint4((normalized) * 65536);
}
