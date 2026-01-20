Shader "Custom/URP/ScanOverlay"
{
    Properties
    {
        _ScanColor ("Scan Color", Color) = (0,1,1,1)
        _ScanIntensity ("Scan Intensity", Range(0,10)) = 2
        _ScanWidth ("Scan Width", Range(0.01, 10)) = 0.5
        _ScanSoftness ("Scan Softness", Range(0.0001, 10)) = 1
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "Queue"="Transparent" "RenderType"="Transparent" }

        Pass
        {
            Name "ScanOverlay"
            Tags { "LightMode"="UniversalForward" }

            // Aditivo: suma brillo encima del material base
            Blend One One
            ZWrite Off
            ZTest LEqual
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _ScanColor;
                float _ScanIntensity;
                float _ScanWidth;
                float _ScanSoftness;
            CBUFFER_END

            // Globales (set desde C#)
            float4 _GlobalScanOrigin;
            float  _GlobalScanDistance;
            float  _GlobalScanEnabled;

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 worldPos    : TEXCOORD0;
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
                VertexPositionInputs pos = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionHCS = pos.positionCS;
                o.worldPos = pos.positionWS;
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                if (_GlobalScanEnabled < 0.5)
                    return half4(0,0,0,0);

                float dist = distance(i.worldPos.xz, _GlobalScanOrigin.xz);
                float ring = RingMask(dist, _GlobalScanDistance, _ScanWidth, _ScanSoftness);

                half3 col = (half3)_ScanColor.rgb * (ring * _ScanIntensity);
                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}
