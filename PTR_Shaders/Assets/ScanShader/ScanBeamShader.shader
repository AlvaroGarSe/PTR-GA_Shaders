Shader "Custom/Scan/Beam"
{
    Properties
    {
        _Color ("Color", Color) = (0,1,1,1)
        _Intensity ("Intensity", Range(0,10)) = 3
        _FadePower ("Vertical Fade", Range(0.1,5)) = 2
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Blend One One
        ZWrite Off
        Cull Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float4 _Color;
            float _Intensity;
            float _FadePower;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float height : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.height = saturate(v.vertex.y + 0.5);

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float fade = pow(i.height, _FadePower);

                half3 col = _Color.rgb * (_Intensity * fade);
                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}
