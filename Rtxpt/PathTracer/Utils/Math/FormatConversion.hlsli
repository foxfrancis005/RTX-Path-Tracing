/*
* Copyright (c) 2025, NVIDIA CORPORATION.  All rights reserved.
*
* NVIDIA CORPORATION and its licensors retain all intellectual property
* and proprietary rights in and to this software, related documentation
* and any modifications thereto.  Any use, reproduction, disclosure or
* distribution of this software and related documentation without an express
* license agreement from NVIDIA CORPORATION is strictly prohibited.
*/

#ifndef __FORMAT_CONVERSION_HLSLI__ // using instead of "#pragma once" due to https://github.com/microsoft/DirectXShaderCompiler/issues/3943
#define __FORMAT_CONVERSION_HLSLI__

#include "../../Config.h"    

/** Utility code for converting between various packed formats.

    The functions have been written to be compatible with the DXGI formats.
    Some use the 'precise' keyword to ensure bit exact results. We should add
    unit tests to make sure it is correctly implemented.

    It'd also be good to add optimized versions that don't care about NaN/inf
    propagation etc., as well as make the header shareable between the CPU/GPU.
*/

///////////////////////////////////////////////////////////////////////////////
//                              8-bit snorm
///////////////////////////////////////////////////////////////////////////////

/** Convert float value to 8-bit snorm value.
    Values outside [-1,1] are clamped and NaN is encoded as zero.
    \return 8-bit snorm value in low bits, high bits are all zeros or ones depending on sign.
*/
int floatToSnorm8(float v)
{
    v = isnan(v) ? 0.f : min(max(v, -1.f), 1.f);
    return (int)trunc(v * 127.f + (v >= 0.f ? 0.5f : -0.5f));
}

/** Unpack a single 8-bit snorm from the lower bits of a dword.
    \param[in] packed 8-bit snorm in low bits, high bits don't care.
    \return Float value in [-1,1].
*/
float unpackSnorm8(uint packed)
{
    int bits = (int)(packed << 24) >> 24;
    precise float unpacked = max((float)bits / 127.f, -1.0f);
    return unpacked;
}

/** Pack single float into a 8-bit snorm in the lower bits of the returned dword.
    \return 8-bit snorm in low bits, high bits all zero.
*/
uint packSnorm8(precise float v)
{
    return floatToSnorm8(v) & 0x000000ff;
}

/** Unpack two 8-bit snorm values from the lo bits of a dword.
    \param[in] packed Two 8-bit snorm in low bits, high bits don't care.
    \return Two float values in [-1,1].
*/
float2 unpackSnorm2x8(uint packed)
{
    int2 bits = int2((int)(packed << 24), (int)(packed << 16)) >> 24;
    precise float2 unpacked = max((float2)bits / 127.f, -1.0f);
    return unpacked;
}

/** Pack two floats into 8-bit snorm values in the lo bits of a dword.
    \return Two 8-bit snorm in low bits, high bits all zero.
*/
uint packSnorm2x8(precise float2 v)
{
    return (floatToSnorm8(v.x) & 0x000000ff) | ((floatToSnorm8(v.y) << 8) & 0x0000ff00);
}

///////////////////////////////////////////////////////////////////////////////
//                              8-bit unorm
///////////////////////////////////////////////////////////////////////////////

/** Convert float value to 8-bit unorm (unsafe version).
    \param[in] v Float value assumed to be in [0,1].
    \return 8-bit unorm in low bits, high bits all zeros.
*/
uint packUnorm8_unsafe(float v)
{
    return (uint)trunc(v * 255.f + 0.5f);
}

/** Convert float value to 8-bit unorm.
    Values outside [0,1] are clamped and NaN is encoded as zero.
    \param[in] v Float value.
    \return 8-bit unorm in low bits, high bits all zeros.
*/
uint packUnorm8(float v)
{
    v = isnan(v) ? 0.f : saturate(v);
    return packUnorm8_unsafe(v);
}

/** Pack two floats into 8-bit unorm values.
    Values outside [0,1] are clamped and NaN is encoded as zero.
    \param[in] v Two float values.
    \return Packed 8-bit unorm values in low bits, high bits all zeros.
*/
uint packUnorm2x8(float2 v)
{
    return (packUnorm8(v.y) << 8) | packUnorm8(v.x);
}

/** Pack two floats into 8-bit unorm values (unsafe version)
    \param[in] v Two float values assumed to be in [0,1].
    \return Packed 8-bit unorm values in low bits, high bits all zeros.
*/
uint packUnorm2x8_unsafe(float2 v)
{
    return (packUnorm8_unsafe(v.y) << 8) | packUnorm8_unsafe(v.x);
}

/** Pack three floats into 8-bit unorm values.
    Values outside [0,1] are clamped and NaN is encoded as zero.
    \param[in] v Three float values.
    \return Packed 8-bit unorm values in low bits, high bits all zeros.
*/
uint packUnorm3x8(float3 v)
{
    return (packUnorm8(v.z) << 16) | (packUnorm8(v.y) << 8) | packUnorm8(v.x);
}

/** Pack three floats into 8-bit unorm values (unsafe version)
    \param[in] v Three float values assumed to be in [0,1].
    \return Packed 8-bit unorm values in low bits, high bits all zeros.
*/
uint packUnorm3x8_unsafe(float3 v)
{
    return (packUnorm8_unsafe(v.z) << 16) | (packUnorm8_unsafe(v.y) << 8) | packUnorm8_unsafe(v.x);
}

/** Pack four floats into 8-bit unorm values.
    Values outside [0,1] are clamped and NaN is encoded as zero.
    \param[in] v Four float values.
    \return Packed 8-bit unorm values.
*/
uint packUnorm4x8(float4 v)
{
    return (packUnorm8(v.w) << 24) | (packUnorm8(v.z) << 16) | (packUnorm8(v.y) << 8) | packUnorm8(v.x);
}

/** Pack four floats into 8-bit unorm values (unsafe version)
    \param[in] v Four float values assumed to be in [0,1].
    \return Packed 8-bit unorm values.
*/
uint packUnorm4x8_unsafe(float4 v)
{
    return (packUnorm8_unsafe(v.w) << 24) | (packUnorm8_unsafe(v.z) << 16) | (packUnorm8_unsafe(v.y) << 8) | packUnorm8_unsafe(v.x);
}

/** Convert 8-bit unorm to float value.
    \param[in] packed 8-bit unorm in low bits, high bits don't care.
    \return Float value in [0,1].
*/
float unpackUnorm8(uint packed)
{
    return float(packed & 0xff) * (1.f / 255);
}

/** Unpack two 8-bit unorm values.
    \param[in] packed 8-bit unorm values in low bits, high bits don't care.
    \return Two float values in [0,1].
*/
float2 unpackUnorm2x8(uint packed)
{
    return float2(uint2(packed, packed >> 8) & 0xff) * (1.f / 255);
}

/** Unpack three 8-bit unorm values.
    \param[in] packed 8-bit unorm values in low bits, high bits don't care.
    \return Three float values in [0,1].
*/
float3 unpackUnorm3x8(uint packed)
{
    return float3(uint3(packed, packed >> 8, packed >> 16) & 0xff) * (1.f / 255);
}

/** Unpack four 8-bit unorm values.
    \param[in] packed 8-bit unorm values.
    \return Four float values in [0,1].
*/
float4 unpackUnorm4x8(uint packed)
{
    return float4(uint4(packed, packed >> 8, packed >> 16, packed >> 24) & 0xff) * (1.f / 255);
}

///////////////////////////////////////////////////////////////////////////////
//                              16-bit snorm
///////////////////////////////////////////////////////////////////////////////

/** Convert float value to 16-bit snorm value.
    Values outside [-1,1] are clamped and NaN is encoded as zero.
    \return 16-bit snorm value in low bits, high bits are all zeros or ones depending on sign.
*/
int floatToSnorm16(float v)
{
    v = isnan(v) ? 0.f : min(max(v, -1.f), 1.f);
    return (int)trunc(v * 32767.f + (v >= 0.f ? 0.5f : -0.5f));
}

/** Unpack a single 16-bit snorm from the lower bits of a dword.
    \param[in] packed 16-bit snorm in low bits, high bits don't care.
    \return Float value in [-1,1].
*/
float unpackSnorm16(uint packed)
{
    int bits = (int)(packed << 16) >> 16;
    precise float unpacked = max((float)bits / 32767.f, -1.0f);
    return unpacked;
}

/** Pack single float into a 16-bit snorm in the lower bits of the returned dword.
    \return 16-bit snorm in low bits, high bits all zero.
*/
uint packSnorm16(precise float v)
{
    return floatToSnorm16(v) & 0x0000ffff;
}

/** Unpack two 16-bit snorm values from the lo/hi bits of a dword.
    \param[in] packed Two 16-bit snorm in low/high bits.
    \return Two float values in [-1,1].
*/
float2 unpackSnorm2x16(uint packed)
{
    int2 bits = int2(packed << 16, packed) >> 16;
    precise float2 unpacked = max((float2)bits / 32767.f, -1.0f);
    return unpacked;
}

/** Pack two floats into 16-bit snorm values in the lo/hi bits of a dword.
    \return Two 16-bit snorm in low/high bits.
*/
uint packSnorm2x16(precise float2 v)
{
    return (floatToSnorm16(v.x) & 0x0000ffff) | (floatToSnorm16(v.y) << 16);
}

///////////////////////////////////////////////////////////////////////////////
//                              16-bit unorm
///////////////////////////////////////////////////////////////////////////////

/** Convert float value to 16-bit unorm (unsafe version).
    \param[in] v Value assumed to be in [0,1].
    \return 16-bit unorm in low bits, high bits all zeros.
*/
uint packUnorm16_unsafe(float v)
{
    return (uint)trunc(v * 65535.f + 0.5f);
}

/** Convert float value to 16-bit unorm.
    Values outside [0,1] are clamped and NaN is encoded as zero.
    \return 16-bit unorm in low bits, high bits all zeros.
*/
uint packUnorm16(float v)
{
    v = isnan(v) ? 0.f : saturate(v);
    return packUnorm16_unsafe(v);
}

/** Pack two floats into 16-bit unorm values in a dword.
*/
uint packUnorm2x16(float2 v)
{
    return (packUnorm16(v.y) << 16) | packUnorm16(v.x);
}

/** Pack two floats into 16-bit unorm values in a dword (unsafe version)
    \param[in] v Two values assumed to be in [0,1].
*/
uint packUnorm2x16_unsafe(float2 v)
{
    return (packUnorm16_unsafe(v.y) << 16) | packUnorm16_unsafe(v.x);
}

/** Convert 16-bit unorm to float value.
    \param[in] packed 16-bit unorm in low bits, high bits don't care.
    \return Float value in [0,1].
*/
float unpackUnorm16(uint packed)
{
    return float(packed & 0xffff) * (1.f / 65535);
}

/** Unpack two 16-bit unorm values from a dword.
*/
float2 unpackUnorm2x16(uint packed)
{
    return float2(packed & 0xffff, packed >> 16) * (1.f / 65535);
}

///////////////////////////////////////////////////////////////////////////////
// 32-bit HDR color format
///////////////////////////////////////////////////////////////////////////////

/** Pack three positive floats into a dword.
    https://github.com/microsoft/DirectX-Graphics-Samples/blob/master/MiniEngine/Core/Shaders/PixelPacking_R11G11B10.hlsli
*/
uint packR11G11B10(float3 v)
{
    // Clamp upper bound so that it doesn't accidentally round up to INF
    v = min(v, asfloat(0x477C0000));
    // Exponent=15, Mantissa=1.11111
    uint r = ((f32tof16(v.x) + 8) >> 4) & 0x000007ff;
    uint g = ((f32tof16(v.y) + 8) << 7) & 0x003ff800;
    uint b = ((f32tof16(v.z) + 16) << 17) & 0xffc00000;
    return r | g | b;
}

/** Unpack three positive floats from a dword.
    https://github.com/microsoft/DirectX-Graphics-Samples/blob/master/MiniEngine/Core/Shaders/PixelPacking_R11G11B10.hlsli
*/
float3 unpackR11G11B10(uint packed)
{
    float r = f16tof32((packed << 4 ) & 0x7FF0);
    float g = f16tof32((packed >> 7 ) & 0x7FF0);
    float b = f16tof32((packed >> 17) & 0x7FE0);
    return float3(r, g, b);
}

///////////////////////////////////////////////////////////////////////////////
//                          64-bit unsigned integer
///////////////////////////////////////////////////////////////////////////////

/** Encodes the 32-bit unsigned integers of v in a 64-bit unsigned integer.
    v.x will become the low bits of the return value while v.y will become the high bits.
*/
uint64_t u2x32to64(uint2 v)
{
    return (uint64_t(v.y) << 32) | uint64_t(v.x);
}

/** Encodes the 64-bit unsigned integer v in two 32-bit unsigned integers.
    The return value will store the low bits of v in the x-component and the high bits of v in the y-component.
*/
uint2 u64to2x32(uint64_t v)
{
    return uint2(v & 0xffffffff, v >> 32);
}

#endif // __FORMAT_CONVERSION_HLSLI__