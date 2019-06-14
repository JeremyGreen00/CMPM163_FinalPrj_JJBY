Shader "Custom/test"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _SpecularPower("Specular Power", Range(0, 100)) = 10
        _Gloss("Gloss", Range(0, 5)) = 1
        _WindSpeed("Wind Speed", float) = 1
        _Radius("Size", Vector) = (1,1,1,0)
        _Centre("Centre", Vector) = (0,0,0,0)
        _MinDistance("Min Distance", float) = 0.01
        _Steps("Steps", int) = 64

        _NoiseOffsets("Noise Offsets", 2D) = "white" {}
        _NoiseBlend("Noise Blend", 2D) = "white" {}
        _NoiseBlendScale("Noise Blend Scale", Range(0.1, 1000)) = 1

        _ViewDistance("View Distance", Range(0, 5)) = 3.36
        _Iterations("Iterations", Range(0, 500)) = 325
        _CloudDensity("Cloud Density", Vector) = (0.18, 0.8,0,0)
        _CloudDetail("Cloud Detail", Range(0, 5)) = 1
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
            float _Steps, _MinDistance, _SpecularPower, _Gloss, _Iterations, _ViewDistance, _CloudDetail, _NoiseBlendScale, _WindSpeed;
            float2 ObjUVS;
            float3 viewDirection;
            float4 _Centre, _CloudDensity, _Radius;
            sampler2D _NoiseOffsets, _NoiseBlend;

            //uniform float _Time.y;

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 wPos : TEXCOORD1; // World position
                //float2 screenPos : TEXCOORD1;
            };
            // Created by inigo quilez - iq/2013
            // License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

            // Volumetric clouds. It performs level of detail (LOD) for faster rendering

            float noise(in float3 x)
            {
                float3 p = floor(x);
                float3 f = frac(x);
                f = f * f*(3.0 - 2.0*f);

#if 1
                float2 uv = (p.xy + float2(37.0, 17.0)*p.z) + f.xy;
                float2 rg = tex2Dlod(_NoiseOffsets, float4((uv + 0.5) / 256.0, 0,0)).yx;
#else
                int3 q = int3(p);
                int2 uv = q.xy + int2(37, 17)*q.z;

                float2 rg = lerp(lerp(texelFetch(_NoiseOffsets, (uv) & 255, 0),
                    texelFetch(_NoiseOffsets, (uv + int2(1, 0)) & 255, 0), f.x),
                    lerp(texelFetch(_NoiseOffsets, (uv + int2(0, 1)) & 255, 0),
                        texelFetch(_NoiseOffsets, (uv + int2(1, 1)) & 255, 0), f.x), f.y).yx;
#endif    

                return -1.0 + 2.0*lerp(rg.x, rg.y, f.z);
            }

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

            float3 sundir = normalize(float3(-1.0, 0.0, -1.0));

            float4 integrate(in float4 sum, in float dif, in float den, in float3 bgcol, in float t)
            {
                // lighting
                float3 lin = float3(0.65, 0.7, 0.75)*1.4 + float3(1.0, 0.6, 0.3)*dif;
                float4 col = float4(lerp(_LightColor0.rgb, float3(0.25, 0.3, 0.35), den), den);
                col.xyz *= lin;
                col.xyz = lerp(col.xyz, bgcol, 1.0 - exp(-0.003*t*t));
                // front to back blending    
                col.a *= 0.4;
                col.rgb *= col.a;
                return sum + col * (1.0 - sum.a);
            }

#define MARCH(STEPS,MAPLOD) for(int i=0; i<STEPS; i++) { float3  pos = ro + t*rd; /*if( pos.y<-5.0 || pos.y>5.0 || sum.a > 0.99 ) break;*/ float den = MAPLOD( pos ); if( den>0.01 ) { float dif =  clamp((den - MAPLOD(pos+0.3*sundir))/0.6, 0.0, 1.0 ); sum = integrate( sum, dif, den, bgcol, t ); } t += max(0.05,0.02*t); }

            float4 raymarch(in float3 ro, in float3 rd, in float3 bgcol)
            {
                float4 sum = float4(0,0,0,0);

                float t = 0.0;//0.05*texelFetch( _NoiseOffsets, px&255, 0 ).x;

                MARCH(_Steps, map5);
                MARCH(_Steps, map4);
                MARCH(_Steps, map3);
                MARCH(_Steps, map2);

                return clamp(sum, 0.0, 1.0);
            }

            float4 render(in float3 ro, in float3 rd)
            {
                // background sky     
                float sun = clamp(dot(sundir, rd), 0.0, 1.0);
                float3 col = float3(0.6, 0.71, 0.75) - rd.y*0.2*float3(1.0, 0.5, 1.0) + 0.15*0.5;
                //col += 0.2*float3(1.0,.6,0.1)*pow( sun, 8.0 );

                // clouds    
                float4 res = raymarch(ro, rd, col);
                col = col * (1.0 - res.w) + res.xyz;

                // sun glare    
                col += 0.2*float3(1.0,0.4,0.2)*pow( sun, 3.0 );

                return float4(col, 0.90);
            }

            v2f vert(appdata_base  v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = v.texcoord;
                //o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                sundir = _WorldSpaceLightPos0.xyz; // Light direction
                //float2 p = (-_ScreenParams.xy + 2.0*i.screenPos.xy) / _ScreenParams.y;
                viewDirection = normalize(i.wPos - _WorldSpaceCameraPos);

                //float2 m = iMouse.xy / iResolution.xy;

                // camera
                //float3 ro = 4.0*normalize(float3(sin(3.0*m.x), 0.4*m.y, cos(3.0*m.x)));
                //float3 ta = float3(0.0, -1.0, 0.0);
                //mat3 ca = setCamera(ro, ta, 0.0);
                // ray
                //float3 rd = ca * normalize(float3(p.xy, 1.5));

                return render(_WorldSpaceCameraPos, viewDirection);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
