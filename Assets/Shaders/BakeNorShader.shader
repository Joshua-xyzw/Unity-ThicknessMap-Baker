Shader "Bake/BakeNorShader"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Back

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                float4 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 nor : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = float4(v.uv.xy,0,1.0);
                o.vertex = mul(UNITY_MATRIX_P,o.vertex);
                o.nor = v.normal;
                return o;
            }

            float4 frag (v2f i) : SV_Target //use float4 to keep the precision
            {
                return float4(normalize(i.nor.xyz),1.0);
            }
            ENDCG
        }
    }
}
