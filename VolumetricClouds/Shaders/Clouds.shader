Shader "Custom/Clouds"
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
            //  Calculate spherical normals
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
            float noisenew(in float3 x)
            {
                float3 p = floor(x);
                float3 f = frac(x);
                f = f * f*(3.0 - 2.0*f);

                #if 1
                float2 uv = (p.xy + float2(37.0, 17.0)*p.z) + f.xy;
                float2 rg = tex2Dlod(_NoiseOffsets, float4((uv + 0.5) / 256.0, 0,0)).yx;
                #else
                int3 q = ifloat3(p);
                int2 uv = q.xy + ifloat2(37, 17)*q.z;

                float2 rg = lerp(lerp(texelFetch(_NoiseOffsets, (uv) & 255, 0),
                                        texelFetch(_NoiseOffsets, (uv + ifloat2(1, 0)) & 255, 0), f.x),
                                 lerp(texelFetch(_NoiseOffsets, (uv + ifloat2(0, 1)) & 255, 0),
                                        texelFetch(_NoiseOffsets, (uv + ifloat2(1, 1)) & 255, 0), f.x), f.y).yx;
                #endif    

                return -1.0 + 2.0*lerp(rg.x, rg.y, f.z);
            }
            //  FBM
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

            //  Render a lambert
            fixed4 simpleLambert(fixed3 normal) {
                fixed3 lightDir = _WorldSpaceLightPos0.xyz; // Light direction
                fixed3 lightCol = _LightColor0.rgb; // Light color

                fixed NdotL = max(dot(normal, lightDir), 0);
                fixed4 c;
                // Specular
                fixed3 h = (lightDir - viewDirection) / 2.;
                fixed s = pow(dot(normal, h), _SpecularPower) * _Gloss;
                c.rgb = max(_Color * lightCol * NdotL + s, _Color * 0.1);
                c.a = 1;
                return c;
            }

            fixed4 renderSurface(float3 p)
            {
                float3 n = normal(p);
                return simpleLambert(n);
            }

            //  Render cloud color
            fixed4 cloudRender(float3 ray, float3 pos)
            {
                fixed3 lightDir = _WorldSpaceLightPos0.xyz; // Light direction
                fixed3 lightCol = _LightColor0.rgb; // Light color
                fixed NdotL = max(dot(normal(pos), lightDir), 0);

                // Specular
                fixed3 h = (lightDir - viewDirection) / 2.;
                fixed s = pow(dot(normal(pos), h), _SpecularPower) * _Gloss;

                float3 p = pos;
                float cloudDensity = 0;
                float maxDensity = 0;

                for (float i = 0; i < _Iterations; i++)
                {
                    float sphere = smoothstep(0, -1, map(p));
                    float f = i / _Iterations;
                    float alpha = smoothstep(0, 20, i) * (1 - f) * (1 - f);
                    float clouds = smoothstep(_CloudDensity.x, _CloudDensity.y, fbm(p, 5)) *sphere;
                    maxDensity = max(maxDensity, clouds + 0.1);
                    cloudDensity += clouds * alpha * smoothstep(0.7, 0.4, maxDensity);
                    p = pos + ray * f * _ViewDistance;
                }

                float cloudFactor = 1 - (cloudDensity / _Iterations) * 20 * _Color.a;
                float4 color = lerp(_Color * max(NdotL, 0.3), float4(1, 1, 1, 0), smoothstep(0.9, 1, cloudFactor));
                return fixed4(color * cloudFactor);
            }

#define MARCH(STEPS,MAPLOD) for(int i=0; i<STEPS; i++) { float3  pos = position; if( pos.y<-3.0 || pos.y>2.0 || sum.a > 0.99 ) break; float den = MAPLOD( pos ); if( den>0.01 ) { float dif =  clamp((den - MAPLOD(pos+0.3*direction))/0.6, 0.0, 1.0 ); sum = integrate( sum, dif, den, _Color.rgb, t ); } t += max(0.05,0.02*t); }

            fixed4 raymarch(inout float3 position, float3 direction)
            {
                /*float4 sum = float4(0, 0, 0, 0);

                float t = 0.0;//0.05*texelFetch(iChannel0, px & 255, 0).x;

                for (int i = 0; i < _Steps; i++)
                {
                    float3  pos = position;
                    if (pos.y<-3.0 || pos.y>2.0 || sum.a > 0.99) break;
                    float den = map5(pos);
                    if (den > 0.01)
                    {
                        float dif = clamp((den - map5(pos + 0.3*direction)) / 0.6, 0.0, 1.0);
                        sum = integrate(sum, dif, den, _Color, t);
                    }
                    t += max(0.05, 0.02*t);
                }
                //MARCH(_Steps, map5);
                //MARCH(_Steps, map4);
                //MARCH(_Steps, map3);
                //MARCH(_Steps, map2);

                return clamp(sum, 0.0, 1.0);*/
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
                viewDirection = normalize(i.wPos - _WorldSpaceCameraPos);
                //return raymarch(worldPosition, viewDirection);
                fixed4 position = raymarch(worldPosition, viewDirection);
                return cloudRender(viewDirection, worldPosition);//_Color * 
                /*
                // background sky
                fixed3 lightDir = _WorldSpaceLightPos0.xyz; // Light direction
                fixed3 lightCol = _LightColor0.rgb; // Light color
                float sun = clamp(dot(lightDir, viewDirection), 0.0, 1.0);
                float3 col = float3(0.6, 0.71, 0.75) - viewDirection.y*0.2*float3(1.0, 0.5, 1.0) + 0.15*0.5;
                col += 0.2*float3(1.0, .6, 0.1)*pow(sun, 8.0);

                // clouds
                float4 res = raymarch(worldPosition, viewDirection);
                col = col * (1.0 - res.w) + res.xyz;

                // sun glare
                col += 0.2*float3(1.0, 0.4, 0.2)*pow(sun, 3.0);

                return fixed4(col, 1.0);*/
            }
            ENDCG
        }
    }
        FallBack "Diffuse"
}
