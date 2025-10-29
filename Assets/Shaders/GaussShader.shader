Shader "Bake/GaussShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BackgroundColor ("BackgroundColor", Color) = (0,0,0,0)
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        //Pass 0 horinzontal blur
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;
            //1*7 Guass weight array
            static float _GuassWeights[4] = {0.324,0.232,0.0855,0.0205};
            fixed4 _BackgroundColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 Gauss7(float2 uv)
            {
                float2 delta = _MainTex_TexelSize.xy;
                float4 sumColor = float4(0,0,0,0);
                float sumWeight = 0;
                for(int i = -3;i<=3;i++)
                {
                    float4 neighborCol = clamp(tex2D(_MainTex, uv + float2(i, 0) * delta),0,1);
                    if(neighborCol.a<0.01)
                    {
                        continue;
                    }
                    float weight = _GuassWeights[abs(i)];
                    sumColor += neighborCol*weight;
                    sumWeight += weight;
                }
                sumColor /= sumWeight;
                sumColor.a = 1.0; //keep alpha
                return (sumWeight>0)?sumColor:_BackgroundColor;
            }
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                if(col.a>0.01) return Gauss7(i.uv);
                else return col;
            }
            ENDCG
        }
        //Pass1 vertical blur
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;
            static float _GuassWeights[4] = {0.3820,0.2417,0.0606,0.0060};
            fixed4 _BackgroundColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            fixed4 Gauss7(float2 uv)
            {
                float2 delta = _MainTex_TexelSize.xy;
                float4 sumColor = float4(0,0,0,0);
                float sumWeight = 0;
                for(int i = -3;i<=3;i++)
                {
                    float4 neighborCol = clamp(tex2D(_MainTex, uv + float2(0, i) * delta),0,1);
                    if(neighborCol.a<0.01)
                    {
                        continue;
                    }
                    float weight = _GuassWeights[abs(i)];
                    sumColor += neighborCol*weight;
                    sumWeight += weight;
                }
                sumColor /= sumWeight;
                sumColor.a = 1.0;
                return (sumWeight>0)?sumColor:_BackgroundColor;
            }
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                if(col.a>0.01) return Gauss7(i.uv);
                else return _BackgroundColor;
            }
            ENDCG
        }
    }
}
