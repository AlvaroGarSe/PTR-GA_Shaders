Shader "Custom/URP/WaterFoamTex_Simple"
{
    Properties
    {
        [Header(Main)]
        _BaseColor ("Base Color", Color) = (0.05, 0.35, 0.5, 0.65)
        _ShallowColor ("Shallow Color", Color) = (0.15, 0.65, 0.7, 0.55)
        _DepthFade ("Depth Fade", Range(0.05, 5)) = 1.0

        [Header(Normal Waves (Pond))]
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _NormalStrength ("Normal Strength", Range(0, 2)) = 1
        _WaveSpeed1 ("Wave Speed 1 (xy)", Vector) = (0.05, 0.03, 0, 0)
        _WaveSpeed2 ("Wave Speed 2 (xy)", Vector) = (-0.03, 0.06, 0, 0)
        _Tiling1 ("Tiling 1", Float) = 1
        _Tiling2 ("Tiling 2", Float) = 2
        _PondMotion ("Pond Motion", Range(0,1)) = 0.2

        [Header(Surface)]
        _Smoothness ("Smoothness", Range(0,1)) = 0.9
        _SpecIntensity ("Spec Intensity", Range(0,2)) = 1.0
        _FresnelPower ("Fresnel Power", Range(0.1, 10)) = 4
        _FresnelIntensity ("Fresnel Intensity", Range(0, 2)) = 0.8

        [Header(Foam (Contact))]
        _FoamColor ("Foam Color", Color) = (1,1,1,1)
        _FoamTex ("Foam Texture (Mask)", 2D) = "white" {}
        _FoamTiling ("Foam Tiling", Float) = 2.0
        _FoamSpeed ("Foam Speed (xy)", Vector) = (0.08, -0.05, 0, 0)
        _FoamDistance ("Foam Distance", Range(0.01, 3)) = 0.35
        _FoamIntensity ("Foam Intensity", Range(0, 3)) = 1.5
        _FoamCut ("Foam Cutoff", Range(0,1)) = 0.35

        [Header(Shoreline Lapping)]
        _ShoreWidth ("Shore Width", Range(0.01, 2)) = 0.35
        _ShoreLapping ("Shore Lapping Amount", Range(0, 0.25)) = 0.06
        _ShoreFreq ("Shore Lapping Frequency", Range(0.1, 5)) = 1.2
        _ShoreEdgeSoft ("Shore Edge Softness", Range(0.001, 0.2)) = 0.03
        _ShoreWorldTiling ("Shore World Tiling", Range(0.05, 10)) = 1.0

        [Header(Shore Vertex Displacement)]
        _ShoreVertAmp ("Shore Vertex Amp", Range(0, 0.5)) = 0.08
        _ShoreVertWidth ("Shore Vertex Width", Range(0.01, 2)) = 0.35
        _ShoreVertFreq ("Shore Vertex Freq", Range(0.1, 5)) = 1.2

        [Header(Refraction)]
        _RefractionStrength ("Refraction Strength", Range(0, 0.1)) = 0.025
        _RefractionDepth ("Refraction Depth Range", Range(0.01, 5)) = 0.8

        [Header(Transparency)]
        _Alpha ("Alpha", Range(0,1)) = 0.8
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
            TEXTURE2D(_FoamTex);   SAMPLER(sampler_FoamTex);

            TEXTURE2D_X_FLOAT(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
            TEXTURE2D_X(_CameraOpaqueTexture);      SAMPLER(sampler_CameraOpaqueTexture);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor, _ShallowColor;
                float _DepthFade;

                float4 _WaveSpeed1, _WaveSpeed2;
                float _Tiling1, _Tiling2, _NormalStrength, _PondMotion;

                float _Smoothness, _SpecIntensity, _FresnelPower, _FresnelIntensity;

                float4 _FoamColor;
                float _FoamTiling;
                float4 _FoamSpeed;
                float _FoamDistance, _FoamIntensity, _FoamCut;

                float _ShoreWidth, _ShoreLapping, _ShoreFreq, _ShoreEdgeSoft, _ShoreWorldTiling;

                float _ShoreVertAmp, _ShoreVertWidth, _ShoreVertFreq;

                float _RefractionStrength, _RefractionDepth;

                float _Alpha;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS   : TEXCOORD1;
                float4 tangentWS  : TEXCOORD2;
                float2 uv         : TEXCOORD3;
                float4 screenPos  : TEXCOORD4;
            };

            float3 SampleWavesNormal(float2 uv, float t, float3 normalWS, float4 tangentWS)
            {
                float3 T = normalize(tangentWS.xyz);
                float3 N = normalize(normalWS);
                float3 B = normalize(cross(N, T) * tangentWS.w);
                
                float2 uv1 = uv * _Tiling1 + _WaveSpeed1.xy * t * _PondMotion;
                float2 uv2 = uv * _Tiling2 + _WaveSpeed2.xy * t * _PondMotion;

                float3 n1 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv1));
                float3 n2 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv2));

                float3 nTS = normalize(float3(n1.xy + n2.xy, n1.z * n2.z));
                nTS.xy *= (_NormalStrength * _PondMotion);

                float3x3 TBN = float3x3(T, B, N);
                return normalize(mul(nTS, TBN));
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                VertexPositionInputs pos = GetVertexPositionInputs(IN.positionOS.xyz);
                VertexNormalInputs nrm = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);

                float3 posWS = pos.positionWS;

                // Depth en vertex para mover SOLO cerca del contacto
                float4 scr = ComputeScreenPos(pos.positionCS);
                float2 suv = scr.xy / scr.w;

                float rawSceneDepth = SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, suv, 0).r;
                float sceneEye = LinearEyeDepth(rawSceneDepth, _ZBufferParams);

                float waterEye = -TransformWorldToView(posWS).z;
                float depthDiff = max(sceneEye - waterEye, 0.0);

                float shoreV = saturate(1.0 - (depthDiff / max(_ShoreVertWidth, 1e-4)));

                // Ruido estable (world) + oscilación
                float2 wuv = posWS.xz * (0.25 * _ShoreWorldTiling);
                float n = SAMPLE_TEXTURE2D_LOD(_FoamTex, sampler_FoamTex, wuv, 0).r;
                float osc = sin(_Time.y * _ShoreVertFreq + n * 6.2831853);

                posWS.y += osc * _ShoreVertAmp * shoreV;

                OUT.positionCS = TransformWorldToHClip(posWS);
                OUT.positionWS = posWS;

                OUT.normalWS  = nrm.normalWS;
                OUT.tangentWS = float4(nrm.tangentWS, IN.tangentOS.w);
                OUT.uv        = IN.uv;
                OUT.screenPos = ComputeScreenPos(OUT.positionCS);

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float t = _Time.y;

                float3 N = SampleWavesNormal(IN.uv, t, IN.normalWS, IN.tangentWS);
                float3 V = normalize(GetWorldSpaceViewDir(IN.positionWS));

                float2 screenUV = IN.screenPos.xy / IN.screenPos.w;

                float rawSceneDepth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV).r;
                float sceneEye = LinearEyeDepth(rawSceneDepth, _ZBufferParams);

                float waterEye = -TransformWorldToView(IN.positionWS).z;
                float depthDiff = max(sceneEye - waterEye, 0.0);

                float depth01 = saturate(depthDiff / max(_DepthFade, 1e-4));
                float4 waterCol = lerp(_ShallowColor, _BaseColor, depth01);

                // Refraction
                float refrMask = saturate(depthDiff / max(_RefractionDepth, 1e-4));
                float2 refrOffset = N.xz * (_RefractionStrength * refrMask);
                float3 behindCol = SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUV + refrOffset).rgb;

                float3 baseWater = lerp(behindCol * waterCol.rgb, waterCol.rgb, 0.25);

                // Lighting simple
                Light mainLight = GetMainLight();
                float3 L = normalize(mainLight.direction);
                float3 H = normalize(L + V);

                float NdotL = saturate(dot(N, -L));
                float NdotH = saturate(dot(N, H));

                float3 diffuse = baseWater * (0.15 + 0.85 * NdotL) * mainLight.color;
                float specPow = lerp(32.0, 256.0, _Smoothness);
                float3 spec = pow(NdotH, specPow) * _SpecIntensity * mainLight.color;

                float fresnel = pow(1.0 - saturate(dot(N, V)), _FresnelPower) * _FresnelIntensity;

                float3 color = diffuse + spec + fresnel;

                // Foam por contacto (depth) + textura anim
                float foamDepth = saturate(1.0 - (depthDiff / max(_FoamDistance, 1e-4)));

                float2 foamUV = IN.uv * _FoamTiling + _FoamSpeed.xy * t;
                foamUV += N.xz * 0.05;

                float foamTex = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, foamUV).r;

                float foamMask = saturate(foamDepth * foamTex * _FoamIntensity);
                foamMask = (foamMask > _FoamCut) ? foamMask : 0.0;

                // Borde que avanza/retrocede (alpha) usando ruido world
                float shoreMask = saturate(1.0 - (depthDiff / max(_ShoreWidth, 1e-4)));

                float2 shoreUV = IN.positionWS.xz * (0.25 * _ShoreWorldTiling);
                float shoreNoise = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, shoreUV).r;

                float shoreOsc = sin(t * _ShoreFreq + shoreNoise * 6.2831853);
                float shoreShift = shoreOsc * _ShoreLapping * shoreMask;

                float edge = smoothstep(0.0, max(_ShoreEdgeSoft, 1e-4), depthDiff + shoreShift);

                // Espuma extra en orilla
                foamMask = saturate(foamMask + shoreMask * (0.35 + 0.35 * shoreOsc) * 0.6);

                color = lerp(color, _FoamColor.rgb, foamMask);

                float alpha = saturate(_Alpha * edge);
                alpha = saturate(alpha + foamMask * 0.35);

                return half4(color, alpha);
            }
            ENDHLSL
        }
    }
}
