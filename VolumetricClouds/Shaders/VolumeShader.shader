// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/VolumeShader"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _SpecularPower("Specular Power", Range(0, 100)) = 10
        _Gloss("Gloss", Range(0, 5)) = 1
        _Radius("Radius", float) = 1
        _Centre("Centre", Vector) = (0,0,0,0)
        _MinDistance("Min Distance", float) = 0.01
        _Steps("Steps", int) = 64

        _CloudDensity("Cloud Density", Vector) = (0.18, 0.8,0,0)
        _NoiseOffsets("Noise Offsets", 2D) = "white" {}
        _NoiseBlend("Noise Blend", 2D) = "white" {}

        _ViewDistance("View Distance", Range(0, 5)) = 3.36
        _Iterations("Iterations", Range(0, 500)) = 325
        _CloudDensity("Cloud Density", Vector) = (0.18, 0.8,0,0)
    }
        SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        //Cull front
        LOD 100

        Pass
        {
            //cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #define MIN_DISTANCE 0.01

            fixed4 _Color;
            float _Radius, _Steps, _MinDistance, _SpecularPower, _Gloss, _Iterations, _ViewDistance;
            float2 ObjUVS;
            float3 viewDirection;
            float4 _Centre, _CloudDensity;
            sampler2D _NoiseOffsets, _NoiseBlend;

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 wPos : TEXCOORD1; // World position
            }; 

            float map(float3 p)
            {
                return distance(p, _Centre.xyz) - _Radius;
            }

            float3 normal(float3 p)
            {
                const float eps = 0.01;

                return normalize
                (float3
                    (map(p + float3(eps, 0, 0)) - map(p - float3(eps, 0, 0)),
                        map(p + float3(0, eps, 0)) - map(p - float3(0, eps, 0)),
                        map(p + float3(0, 0, eps)) - map(p - float3(0, 0, eps))
                        )
                );
            }
            // Shamelessly stolen from https://www.shadertoy.com/view/4sfGzS
            float noise(float3 x)
            {
                x *= 4.0;
                float3 p = floor(x);
                float3 f = frac(x);
                f = f * f*(3.0 - 2.0*f);
                float2 uv = (p.xy + float2(37.0, 17.0)*p.z) + f.xy;
                float2 rg = tex2D(_NoiseOffsets, (uv + 0.5) / 256.0).yx;
                return lerp(rg.x, rg.y, f.z);
            }
            float fbm(float3 pos, int octaves)
            {
                float f = 0.;
                for (int i = 0; i < octaves; i++)
                {
                    f += noise(pos) / pow(2, i + 1); pos *= 2.01;
                }
                f /= 1 - 1 / pow(2, octaves + 1);
                return f;
            }

            fixed4 simpleLambert(fixed3 normal) {
                fixed3 lightDir = _WorldSpaceLightPos0.xyz; // Light direction
                fixed3 lightCol = _LightColor0.rgb; // Light color

                fixed NdotL = max(dot(normal, lightDir), 0);
                fixed4 c;
                // Specular
                fixed3 h = (lightDir - viewDirection) / 2.;
                fixed s = pow(dot(normal, h), _SpecularPower) * _Gloss;
                c.rgb = _Color * lightCol * NdotL + s;
                c.a = 1;
                return c;
            }

            fixed4 renderSurface(float3 p)
            {
                float3 n = normal(p);
                return simpleLambert(n);
            }

            //  Does this render a cloud?
            fixed4 cloudRender(float3 ray, float3 pos)
            {
                fixed3 lightDir = _WorldSpaceLightPos0.xyz; // Light direction
                fixed3 lightCol = _LightColor0.rgb; // Light color
                fixed NdotL = max(dot(normal(pos), lightDir), 0);

                float3 p = pos;
                float cloudDensity = 0;
                float maxDensity = 0;

                for (float i = 0; i < _Iterations; i++)
                {
                    float sphere = smoothstep(0, -1, map(p));
                    float f = i / _Iterations;
                    float alpha = smoothstep(0, 20, i) * (1 - f) * (1 - f);
                    float clouds = smoothstep(_CloudDensity.x, _CloudDensity.y, fbm(p, 5)) * sphere;
                    maxDensity = max(maxDensity, clouds + 0.1);
                    cloudDensity += clouds * alpha * smoothstep(0.7, 0.4, maxDensity);
                    p = pos + ray * f * _ViewDistance;
                }

                float cloudFactor = 1 - (cloudDensity / _Iterations) * 20 * _Color.a;
                float4 color = lerp(_Color, float4(1, 1, 1, 0), smoothstep(max(0.3 , NdotL), 1, cloudFactor));
                return fixed4(color * cloudFactor);
            }

            fixed4 raymarch(inout float3 position, float3 direction)
            {
                for (int i = 0; i < _Steps; i++)
                {
                    float distance = map(position);
                    if (distance < _MinDistance)
                        return renderSurface(position);

                    position += distance * direction;
                }
                return fixed4(1, 1, 1, 0);
            }

            v2f vert(appdata_base  v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = v.texcoord;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 worldPosition = i.wPos;
                ObjUVS = i.uv;
                viewDirection = normalize(i.wPos - _WorldSpaceCameraPos);
                //return raymarch(worldPosition, viewDirection);
                fixed4 position = raymarch(worldPosition, viewDirection);
                return cloudRender(viewDirection, worldPosition);//_Color * 
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
