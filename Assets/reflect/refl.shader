// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/refl"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        [HideInInspector] _ReflectionTex ("", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent+100" }
        LOD 100
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 refl : TEXCOORD1;
                float4 pos : SV_POSITION;
            };
            float4 _MainTex_ST;
            v2f vert(float4 pos : POSITION, float2 uv : TEXCOORD0)
            {
                v2f o;
                o.pos = UnityObjectToClipPos (pos);
                o.uv = TRANSFORM_TEX(uv, _MainTex);
                o.refl = ComputeScreenPos (o.pos);
                return o;
            }
            sampler2D _MainTex;
            sampler2D _ReflectionTex;
            float4 _Color;
            fixed4 frag(v2f i) : SV_Target
            {
                float4 col = _Color;
                
                fixed4 tex = tex2D(_MainTex, i.uv);
                float4 refl = tex2Dproj(_ReflectionTex, UNITY_PROJ_COORD(i.refl));
                return col*refl ;
            }
            ENDCG
        }
    }
}