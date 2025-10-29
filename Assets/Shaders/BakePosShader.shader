Shader "Bake/BakePosShader"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        ZWrite Off ZTest Always Cull Back

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 pos : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = float4(v.uv.xy,0,1.0);//Unwrap point to uv position in ViewSpace
                o.vertex = mul(UNITY_MATRIX_P,o.vertex);
                o.pos = v.vertex;
                return o;
            }

            float4 frag (v2f i) : SV_Target //use float4 to keep the precision
            {
                return i.pos;
            }
            ENDCG
        }
    }
}
