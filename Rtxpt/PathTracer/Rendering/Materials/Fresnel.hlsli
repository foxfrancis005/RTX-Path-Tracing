/*
* Copyright (c) 2025, NVIDIA CORPORATION.  All rights reserved.
*
* NVIDIA CORPORATION and its licensors retain all intellectual property
* and proprietary rights in and to this software, related documentation
* and any modifications thereto.  Any use, reproduction, disclosure or
* distribution of this software and related documentation without an express
* license agreement from NVIDIA CORPORATION is strictly prohibited.
*/

/** Evaluates the Fresnel term using Schlick's approximation.
    Introduced in http://www.cs.virginia.edu/~jdl/bib/appearance/analytic%20models/schlick94b.pdf

    The Fresnel term equals f0 at normal incidence, and approaches f90=1.0 at 90 degrees.
    The formulation below is generalized to allow both f0 and f90 to be specified.

    \param[in] f0 Specular reflectance at normal incidence (0 degrees).
    \param[in] f90 Reflectance at orthogonal incidence (90 degrees), which should be 1.0 for specular surface reflection.
    \param[in] cosTheta Cosine of angle between microfacet normal and incident direction (LdotH).
    \return Fresnel term.
*/
float3 evalFresnelSchlick(float3 f0, float3 f90, float cosTheta)
{
    return f0 + (f90 - f0) * pow(max(1 - cosTheta, 0), 5); // Clamp to avoid NaN if cosTheta = 1+epsilon
}

float evalFresnelSchlick(float f0, float f90, float cosTheta)
{
    return f0 + (f90 - f0) * pow(max(1 - cosTheta, 0), 5); // Clamp to avoid NaN if cosTheta = 1+epsilon
}

float3 evalFresnelGeneralizedSchlick(float3 f0, float3 f90, float exponent, float cosTheta)
{
    return f0 + (f90 - f0) * pow(max(1 - cosTheta, 0), exponent); // Clamp to avoid NaN if cosTheta = 1+epsilon
}

/** Evaluates the Fresnel term using dieletric fresnel equations.
    Based on http://www.pbr-book.org/3ed-2018/Reflection_Models/Specular_Reflection_and_Transmission.html

    \param[in] eta Relative index of refraction (etaI / etaT).
    \param[in] cosThetaI Cosine of angle between normal and incident direction.
    \param[out] cosThetaT Cosine of angle between negative normal and transmitted direction (0 for total internal reflection).
    \return Returns Fr(eta, cosThetaI).
*/
float evalFresnelDielectric(float eta, float cosThetaI, out float cosThetaT)
{
    if (cosThetaI < 0)
    {
        eta = 1 / eta;
        cosThetaI = -cosThetaI;
    }

    float sinThetaTSq = eta * eta * (1 - cosThetaI * cosThetaI);
    // Check for total internal reflection
    if (sinThetaTSq > 1)
    {
        cosThetaT = 0;
        return 1;
    }

    cosThetaT = sqrt(1 - sinThetaTSq); // No clamp needed

    // Note that at eta=1 and cosThetaI=0, we get cosThetaT=0 and NaN below.
    // It's important the framework clamps |cosThetaI| or eta to small epsilon.
    float Rs = (eta * cosThetaI - cosThetaT) / (eta * cosThetaI + cosThetaT);
    float Rp = (eta * cosThetaT - cosThetaI) / (eta * cosThetaT + cosThetaI);

    return 0.5 * (Rs * Rs + Rp * Rp);
}

/** Evaluates the Fresnel term using dieletric fresnel equations.
    Based on http://www.pbr-book.org/3ed-2018/Reflection_Models/Specular_Reflection_and_Transmission.html

    \param[in] eta Relative index of refraction (etaI / etaT).
    \param[in] cosThetaI Cosine of angle between normal and incident direction.
    \return Returns Fr(eta, cosThetaI).
*/
float evalFresnelDielectric(float eta, float cosThetaI)
{
    float cosThetaT;
    return evalFresnelDielectric(eta, cosThetaI, cosThetaT);
}

/** Evaluates the Fresnel term using conductor fresnel equations, assuming unpolarized light.
    Base on "PHYSICALLY BASED LIGHTING CALCULATIONS FOR COMPUTER GRAPHICS" by Peter Shirley
    http://www.cs.virginia.edu/~jdl/bib/globillum/shirley_thesis.pdf

    \param[in] eta Real part of complex index of refraction
    \param[in] k Imaginary part of complex index of refraction (the "absorption coefficient")
    \param[in] cosThetaI Cosine of angle between normal and incident direction.
    \return Returns conductor reflectance.
*/
float evalFresnelConductor(float eta, float k, float cosThetaI)
{
    float cosThetaISq = cosThetaI * cosThetaI;
    float sinThetaISq = max(1.0f - cosThetaISq, 0.0f);
    float sinThetaIQu = sinThetaISq * sinThetaISq;

    float innerTerm = eta * eta - k * k - sinThetaISq;
    float aSqPlusBSq = sqrt(max(innerTerm*innerTerm + 4.0f * eta * eta * k * k, 0.0f));
    float a = sqrt(max((aSqPlusBSq + innerTerm) * 0.5f, 0.0f));

    float Rs = ((aSqPlusBSq + cosThetaISq) - (2.0f * a * cosThetaI))/
               ((aSqPlusBSq + cosThetaISq) + (2.0f * a * cosThetaI));
    float Rp = ((cosThetaISq * aSqPlusBSq + sinThetaIQu) - (2.0f * a * cosThetaI * sinThetaISq))/
               ((cosThetaISq * aSqPlusBSq + sinThetaIQu) + (2.0f * a * cosThetaI * sinThetaISq));

    return 0.5f * (Rs + Rs * Rp);
}

/** Evaluates the Fresnel term using conductor fresnel equations, assuming unpolarized light.
    Convenience function that takes coefficients at 3 wavelengths.

    \param[in] eta Real part of complex index of refraction
    \param[in] k Imaginary part of complex index of refraction (the "absorption coefficient")
    \param[in] cosThetaI Cosine of angle between normal and incident direction.
    \return Returns conductor reflectance.
*/
float3 evalFresnelConductor(float3 eta, float3 k, float cosThetaI)
{
    return float3(
        evalFresnelConductor(eta.x, k.x, cosThetaI),
        evalFresnelConductor(eta.y, k.y, cosThetaI),
        evalFresnelConductor(eta.z, k.z, cosThetaI)
    );
}
