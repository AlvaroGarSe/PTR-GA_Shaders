Shader "Custom/URP/ScanPulseWorld"
{
    Properties
    {
        _BaseMap ("Base Texture", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1,1,1,1)

        _ScanColor ("Scan Color", Color) = (0,1,1,1)
        _ScanIntensity ("Scan Intensity", Range(0,10)) = 2
        _ScanWidth ("Scan Width (world units)", Range(0.01, 10)) = 0.5
        _ScanSoftness ("Scan Softness", Range(0.0001, 10)) = 1

        // Opcional: se quedan para inspector, pero NO las usaremos en el código del shader
        _ScanOrigin ("Scan Origin (world) [Inspector Only]", Vector) = (0,0,0,0)
        _ScanDistance ("Scan Distance (world) [Inspector Only]", Float) = 0
        _ScanEnabled ("Scan Enabled [Inspector Only]", Float) = 0
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }

        Pass
        {
            Name "Forward"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;

                float4 _ScanColor;
                float _ScanIntensity;
                float _ScanWidth;
                float _ScanSoftness;
            CBUFFER_END

            // Globales (las seteas con Shader.SetGlobalX desde C#)
            float4 _GlobalScanOrigin;
            float  _GlobalScanDistance;
            float  _GlobalScanEnabled;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
                float3 worldPos    : TEXCOORD1;
            };

            float RingMask(float distToOrigin, float ringDistance, float width, float softness)
            {
                float x = abs(distToOrigin - ringDistance);
                float w = max(width, 1e-5);
                float s = max(softness, 1e-5);

                float m = 1.0 - smoothstep(0.0, w, x);
                m = pow(saturate(m), 1.0 / s);
                return m;
            }

            Varyings vert (Attributes v)
            {
                Varyings o;
                VertexPositionInputs posInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionHCS = posInputs.positionCS;
                o.worldPos = posInputs.positionWS;
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 baseTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv) * _BaseColor;

                if (_GlobalScanEnabled < 0.5)
                    return baseTex;

                float dist = distance(i.worldPos.xz, _GlobalScanOrigin.xz);
                float ring = RingMask(dist, _GlobalScanDistance, _ScanWidth, _ScanSoftness);

                half3 scanAdd = (half3)_ScanColor.rgb * (ring * _ScanIntensity);
                baseTex.rgb += scanAdd;

                return baseTex;
            }
            ENDHLSL
        }
    }
}
