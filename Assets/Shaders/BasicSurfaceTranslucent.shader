Shader "Custom/BasicSurfaceTranslucent"
{
    Properties
    {
        [Enum(Both,0,Back,1,Front,2)]
        _RenderMode("RenderMode ",Float) = 2
        [Header(Basic PBR)]
        _AlphaClipThreshold("AlphaClipThreshold",Range(0,1)) = 0.1
        _Color ("AlbedoColor", Color) = (1,1,1,1)
        _MainTex ("AlbedoTex(RGB)", 2D) = "white" {}
        _SpecColor("SpecularColor",Color) = (0,0,0,1)
        [NoScaleOffset]_RoughnessMap("RoughnessMap",2D) = "black" {}
        _SmoothnessScale("SmoothnessMultiply",Range(0,1)) = 1.0
        [NoScaleOffset][Normal]_BumpMap("NormalMap",2D) = "bump"{}
        _BumpScale("NormalMultiply",Float) = 1.0
        [NoScaleOffset]_OcclusionMap("AOMap",2D) = "white"{}
        _OcclusionStrength("AOMultiply",Range(0,1)) = 1.0
        [NoScaleOffset]_EmissionMap("EmissionMap",2D) = "White"{}
        [HDR]_EmissionColor("EmissionColor",Color) = (0,0,0,1)
        [Header(Scatter Settings)]
        [NoScaleOffset]
        _TranslucentMap("SSSMap",2D) = "White"{}
        [HDR]_TranslucentColor("SSSColor",Color) = (1,1,1,1)
        _TranslucentDistortion("SSSDistortion",Range(0,1)) = 0.5
        _TranslucentPower("SSSPower",Range(0.1,10)) = 1
        _TranslucentScale("SSSScale",Range(0,1)) = 0.0
        _TranslucentRadius("SSSRadius",Range(0,1)) = 0.5
        [Header(SecondaryMaps)]
        _DetailAlbedoMap("DetailAlbedo",2D) = "white"{}
        [KeywordEnum(UV0,UV1)]_UVSet("UV Set",Float) = 0
        [NoScaleOffset]_DetailNormalMap("DetailNormalMap",2D) = "bump"{}
        _DetailNormalMapScale("DetailNormalMultiply",Float) = 1.0
        [Header(DitherTransparent)]
        [Toggle(ENABLE_DITHER)]
        _DitherToggle("Enable Dither",Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opacity" }
        Cull [_RenderMode]
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf StandardTranslucent fullforwardshadows

        #pragma multi_compile _UVSET_UV0 _UVSET_UV1 //Manager uvset of the DetailTex

        #pragma shader_feature ENABLE_DITHER 

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        #include "UnityPBSLighting.cginc"
        #include "UnityStandardUtils.cginc"
        struct Input
        {
            float2 uv_MainTex;
            #if defined(_UVSET_UV1)
            float2 uv2_DetailAlbedoMap;
            #else
            float2 uv_DetailAlbedoMap;
            #endif
            float4 screenPos;
        };
        sampler2D _MainTex,_RoughnessMap,_BumpMap,_OcclusionMap,_EmissionMap,_TranslucentMap,_DetailAlbedoMap,_DetailNormalMap;
        fixed4 _Color,_EmissionColor,_TranslucentColor;
        half _AlphaClipThreshold,_SmoothnessScale,_OcclusionStrength,_BumpScale,_TranslucentDistortion,_TranslucentPower,_TranslucentScale,_TranslucentRadius,_DetailNormalMapScale;
        float thickness;
        #ifdef ENABLE_DITHER
        //Dither matrix
        static const float4x4  DITHER_THRESHOLDS =
        {
            1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
            13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
            4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
            16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
        };
        #endif
        inline void LightingStandardTranslucent_GI(SurfaceOutputStandardSpecular s,UnityGIInput data,inout UnityGI gi)
        {
            LightingStandardSpecular_GI(s, data, gi); 
        }

        void surf (Input IN, inout SurfaceOutputStandardSpecular o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 t =  tex2D (_MainTex, IN.uv_MainTex);
            clip(t.a-_AlphaClipThreshold);
            fixed4 c = t * _Color;
            half3 normal = UnpackScaleNormal(tex2D(_BumpMap, IN.uv_MainTex),_BumpScale);
            float3 detailNormal;
            #if defined(_UVSET_UV1)
            c*= tex2D(_DetailAlbedoMap,IN.uv2_DetailAlbedoMap);
            detailNormal = UnpackScaleNormal(tex2D(_DetailNormalMap,IN.uv2_DetailAlbedoMap),_DetailNormalMapScale);
            #else 
            c*= tex2D(_DetailAlbedoMap,IN.uv_DetailAlbedoMap);
            detailNormal = UnpackScaleNormal(tex2D(_DetailNormalMap,IN.uv_DetailAlbedoMap),_DetailNormalMapScale);
            #endif
            #ifdef ENABLE_DITHER
            //Dither透明
            uint2 screenUV = (uint2)abs((IN.screenPos.xy / IN.screenPos.w)*_ScreenParams.xy+_Time.xx);//添加随机偏移值
            uint2 ditherPos = screenUV % 4;
            float ditherValue = DITHER_THRESHOLDS[ditherPos.x][ditherPos.y];
            clip(saturate(c.a)-ditherValue);
            #endif
            o.Normal = BlendNormals(normal,detailNormal);
            //Specular and Smoothness comes from input
            o.Specular = _SpecColor;
            o.Smoothness = (1.0 - tex2D(_RoughnessMap,IN.uv_MainTex).r)*_SmoothnessScale;
            half ao = 1.0-(1.0-tex2D(_OcclusionMap,IN.uv_MainTex).r)*_OcclusionStrength; 
            o.Albedo = c.rgb*ao;
            o.Emission = tex2D(_EmissionMap,IN.uv_MainTex)*_EmissionColor;
            fixed4 sssColor = tex2D(_TranslucentMap,IN.uv_MainTex);
            thickness = sssColor.r;
        }
        inline fixed4 LightingStandardTranslucent(SurfaceOutputStandardSpecular s,fixed3 viewDir,UnityGI gi)
        {
            fixed4 pbr = LightingStandardSpecular(s,viewDir,gi);
            //Translucnet BTDF，Reference https://www.alanzucconi.com/2017/08/30/fast-subsurface-scattering-2/中的方法
            float3 L = gi.light.dir;
            float3 V = viewDir;
            float3 N = s.Normal;

            float3 H = normalize(L+N*_TranslucentDistortion);
            float3 I = pow(saturate(dot(V,-H)),_TranslucentPower)*thickness*_TranslucentColor;
            //Translucnet BSSDF,Reference https://zhuanlan.zhihu.com/p/606880884
            half NdotL = saturate(dot(N,L));
            half alpha = _TranslucentRadius;
            half theta = max(0,NdotL+alpha)-alpha;
            half normalization_jgt = (2+alpha)/(2*(1+alpha));
            half wrapped_jgt = (pow(((theta + alpha) / (1 + alpha)), 1 + alpha)) * normalization_jgt;
            half3 subsurface_radiance = _TranslucentColor * wrapped_jgt * pow((1 - NdotL),_TranslucentPower);
            pbr.rgb = pbr.rgb*(1-_TranslucentScale*_TranslucentScale)+gi.light.color*I*_TranslucentScale+gi.light.color*subsurface_radiance*_TranslucentScale;
            return pbr;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
