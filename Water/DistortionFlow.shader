Shader "Custom/DistortionFlow" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		[NoScaleOffset] _FlowMap ("Flow (RG, A noise)", 2D) = "black" {}
		[NoScaleOffset] _DerivHeightMap ("Deriv (AG) Height (B)", 2D) = "black" {}
		_UJump ("U jump per phase", Range(-0.25, 0.25)) = 0.25
		_VJump ("V jump per phase", Range(-0.25, 0.25)) = 0.25
		_Tiling ("Tiling", Float) = 1
		_Speed ("Speed", Float) = 1
		_FlowStrength ("Flow Strength", Float) = 1
		_FlowOffset ("Flow Offset", Float) = 0
		_HeightScale ("Height Scale, Constant", Float) = 0.25
		_HeightScaleModulated ("Height Scale, Modulated", Float) = 0.75
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
        //
        [HideInInspector] _ReflectionTex ("", 2D) = "white" {}
        //_Color2 ("Color2", Color) = (1,1,1,1)
        //
	}
	SubShader {
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 200
         ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        /////
        //Reflection code implemented from tutorial
        //source: https://www.youtube.com/watch?v=jD9LfpRH5Z4&t=644s
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
            float4 _Color2;
            fixed4 frag(v2f i) : SV_Target
            {
                //float4 col = _Color2;
                //fixed4 tex = tex2D(_MainTex, i.uv);
                float4 refl = tex2Dproj(_ReflectionTex, UNITY_PROJ_COORD(i.refl));
                return refl;
            }
            ENDCG
        }
        
        
        
        
        ////////
        //////// tutorial for water from https://catlikecoding.com/unity/tutorials/flow/looking-through-water/
		CGPROGRAM
		#pragma surface surf Standard alpha
		#pragma target 3.0

		#include "Flow.cginc"

		sampler2D _MainTex, _FlowMap, _DerivHeightMap;
		float _UJump, _VJump, _Tiling, _Speed, _FlowStrength, _FlowOffset;
		float _HeightScale, _HeightScaleModulated;

		struct Input {
			float2 uv_MainTex;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

		float3 UnpackDerivativeHeight (float4 textureData) {
			float3 dh = textureData.agb;
			dh.xy = dh.xy * 2 - 1;
			return dh;
		}
        //creates small waves that are distorted by noise
		void surf (Input IN, inout SurfaceOutputStandard o) {
			float3 flow = tex2D(_FlowMap, IN.uv_MainTex).rgb;
			flow.xy = flow.xy * 2 - 1;
			flow *= _FlowStrength;
			float noise = tex2D(_FlowMap, IN.uv_MainTex).a;
			float time = _Time.y * _Speed + noise;
			float2 jump = float2(_UJump, _VJump);

			float3 uvwA = FlowUVW(
				IN.uv_MainTex, flow.xy, jump,
				_FlowOffset, _Tiling, time, false
			);
			float3 uvwB = FlowUVW(
				IN.uv_MainTex, flow.xy, jump,
				_FlowOffset, _Tiling, time, true
			);

			float finalHeightScale =
				flow.z * _HeightScaleModulated + _HeightScale;

			float3 dhA =
				UnpackDerivativeHeight(tex2D(_DerivHeightMap, uvwA.xy)) *
				(uvwA.z * finalHeightScale);
			float3 dhB =
				UnpackDerivativeHeight(tex2D(_DerivHeightMap, uvwB.xy)) *
				(uvwB.z * finalHeightScale);
			o.Normal = normalize(float3(-(dhA.xy + dhB.xy), 1));

			fixed4 texA = tex2D(_MainTex, uvwA.xy) * uvwA.z;
			fixed4 texB = tex2D(_MainTex, uvwB.xy) * uvwB.z;

			fixed4 c = (texA + texB) * _Color;
			o.Albedo = c.rgb;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
        
	}
}