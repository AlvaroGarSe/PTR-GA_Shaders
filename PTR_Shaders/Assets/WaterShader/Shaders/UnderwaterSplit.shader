Shader "Hidden/UnderwaterSplit_Legacy"
{
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" }
        Pass
        {
            ZWrite Off
            ZTest Always
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D_X(_MainTex); SAMPLER(sampler_MainTex);

            TEXTURE2D_X_FLOAT(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            float _WaterY;
            float _BlendDepth;
            float4 _UnderTint;
            float _UnderTintStrength;
            float _UnderDarken;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.uv;
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                float2 uv = i.uv;

                half4 col = SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv);

                float rawDepth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, uv).r;
                if (rawDepth >= 0.999999) return col;

                float3 worldPos = ComputeWorldSpacePosition(uv, rawDepth, UNITY_MATRIX_I_VP);

                float depthUnder = _WaterY - worldPos.y;
                float mask = saturate(depthUnder / max(_BlendDepth, 1e-4));

                float3 tinted = lerp(col.rgb, col.rgb * _UnderTint.rgb, _UnderTintStrength);
                tinted *= lerp(1.0, 1.0 - _UnderDarken, mask);

                col.rgb = lerp(col.rgb, tinted, mask);
                return col;
            }
            ENDHLSL
        }
    }
}
