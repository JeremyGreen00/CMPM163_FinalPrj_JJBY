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

        _NoiseOffsets("Noise Offsets", 2D) = "white" {}
        _NoiseBlend("Noise Blend", 2D) = "white" {}

        _ViewDistance("View Distance", Range(0, 5)) = 3.36
        _Iterations("Iterations", Range(0, 500)) = 325
        _CloudDensity("Cloud Density", Vector) = (0.18, 0.8,0,0)
        //_Time.y("Time", float) = 1
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

            //uniform float _Time.y;

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 wPos : TEXCOORD1; // World position
            }; 
            
            float map5(in float3 p)
            {
                float3 q = p - float3(0.0, 0.1, 1.0)*_Time.y;
                float f;
                f = 0.50000*noise(q); q = q * 2.02;
                f += 0.25000*noise(q); q = q * 2.03;
                f += 0.12500*noise(q); q = q * 2.01;
                f += 0.06250*noise(q); q = q * 2.02;
                f += 0.03125*noise(q);
                return clamp(1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0);
            }

            float map4(in float3 p)
            {
                float3 q = p - float3(0.0, 0.1, 1.0)*_Time.y;
                float f;
                f = 0.50000*noise(q); q = q * 2.02;
                f += 0.25000*noise(q); q = q * 2.03;
                f += 0.12500*noise(q); q = q * 2.01;
                f += 0.06250*noise(q);
                return clamp(1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0);
            }
            float map3(in float3 p)
            {
                float3 q = p - float3(0.0, 0.1, 1.0)*_Time.y;
                float f;
                f = 0.50000*noise(q); q = q * 2.02;
                f += 0.25000*noise(q); q = q * 2.03;
                f += 0.12500*noise(q);
                return clamp(1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0);
            }
            float map2(in float3 p)
            {
                float3 q = p - float3(0.0, 0.1, 1.0)*_Time.y;
                float f;
                f = 0.50000*noise(q); q = q * 2.02;
                f += 0.25000*noise(q);;
                return clamp(1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0);
            }
            float4 integrate(in float4 sum, in float dif, in float den, in float3 bgcol, in float t)
            {
                // lighting
                float3 lin = float3(0.65, 0.7, 0.75)*1.4 + float3(1.0, 0.6, 0.3)*dif;
                float4 col = float4(lerp(float3(1.0, 0.95, 0.8), float3(0.25, 0.3, 0.35), den), den);
                col.xyz *= lin;
                col.xyz = lerp(col.xyz, bgcol, 1.0 - exp(-0.003*t*t));
                // front to back blending    
                col.a *= 0.4;
                col.rgb *= col.a;
                return sum + col * (1.0 - sum.a);
            }
            //  Map the shape
            float map(float3 p)
            {
                return distance(p, _Centre.xyz) - _Radius;
            }

            //  Noise function
            float noise(in float3 x)
            {
                return 1;
                /*
                float3 p = floor(x);
                float3 f = frac(x);
                float2 rg = float2(0, 0);
                f = f * f*(3.0 - 2.0*f);

                if (true)
                {
                    float2 uv = (p.xy + float2(37.0, 17.0)*p.z) + f.xy;
                    rg = tex2D(_NoiseOffsets, (uv + 0.5) / 256.0).yx;
                }
                else
                {
                    int3 q = int3(p);
                    int2 uv = q.xy + int2(37, 17)*q.z;
                    rg = lerp(lerp(  tex2D(_NoiseOffsets, (uv             ) & 255),
                                            tex2D(_NoiseOffsets, (uv + int2(1, 0)) & 255), f.x),
                                     lerp(  tex2D(_NoiseOffsets, (uv + int2(0, 1)) & 255),
                                            tex2D(_NoiseOffsets, (uv + int2(1, 1)) & 255), f.x), f.y).yx;
                }

                return -1.0 + 2.0*lerp(rg.x, rg.y, f.z); //*/
            }

            //  Render a lambert
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

#define MARCH(STEPS,MAPLOD) for(int i=0; i<STEPS; i++) { float3  pos = position; if( pos.y<-3.0 || pos.y>2.0 || sum.a > 0.99 ) break; float den = MAPLOD( pos ); if( den>0.01 ) { float dif =  clamp((den - MAPLOD(pos+0.3*direction))/0.6, 0.0, 1.0 ); sum = integrate( sum, dif, den, _Color.rgb, t ); } t += max(0.05,0.02*t); }

            fixed4 raymarch(inout float3 position, float3 direction)
            {
                float4 sum = float4(0, 0, 0, 0);

                float t = 0.0;//0.05*texelFetch(iChannel0, px & 255, 0).x;

                for (int i = 0; i < _Steps; i++)
                {
                    if (position.y<-3.0 || position.y>2.0 || sum.a > 0.99) break;
                    float den = map5(position);
                    if (den > 0.01)
                    {
                        float dif = clamp((den - map5(position + 0.3*direction)) / 0.6, 0.0, 1.0);
                        sum = integrate(sum, dif, den, _Color, t);
                    }
                    t += max(0.05, 0.02*t);
                }
                //MARCH(_Steps, map5);
                //MARCH(_Steps, map4);
                //MARCH(_Steps, map3);
                //MARCH(_Steps, map2);

                return clamp(sum, 0.0, 1.0);//*/
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
                viewDirection = normalize(i.wPos - _WorldSpaceCameraPos);
                fixed3 lightDir = _WorldSpaceLightPos0.xyz; // Light direction
                fixed3 lightCol = _LightColor0.rgb; // Light color
                return fixed4(0,0,0,0);
                /*
                // background sky     
                float sun = clamp(dot(lightDir, viewDirection), 0.0, 1.0);
                float3 col = float3(0.6, 0.71, 0.75) - viewDirection.y*0.2*float3(1.0, 0.5, 1.0) + 0.15*0.5;
                col += 0.2*float3(1.0,.6,0.1)*pow( sun, 8.0 );

                // clouds    
                float4 res = raymarch(worldPosition, viewDirection);
                col = col * (1.0 - res.w) + res.xyz;

                // sun glare    
                //col += 0.2*float3(1.0,0.4,0.2)*pow( sun, 3.0 );

                return float4(col, 1.0);*/
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
