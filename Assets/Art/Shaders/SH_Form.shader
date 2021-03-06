// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "OSW/Form"
{
	Properties
	{
		_SunAtmosDensity("Sun Atmos Density", Range( 0 , 1)) = 0.5
		_SunAtmosFalloff("Sun Atmos Falloff", Range( 0 , 1)) = 0.5
		[HDR]_SunColour("Sun Colour", Color) = (2,1.47451,0.972549,0)
		_Albedo("Albedo", 2D) = "white" {}
		_DetailMask("Detail Mask", 2D) = "white" {}
		_lightwrapscale("light wrap scale", Range( 0 , 1)) = 1
		_lightwrapoffset("light wrap offset", Range( 0 , 1)) = 0
		_LightFresnel("Light Fresnel", Range( 0 , 10)) = 3.60606
		_Cutoff( "Mask Clip Value", Float ) = 0.5
		_LightFresnelPower("Light Fresnel Power", Range( 0.01 , 10)) = 4.323316
		[Toggle]_ReflectionToggle("Reflection Toggle", Float) = 1
		[Toggle]_IndirectToggle("Indirect Toggle", Float) = 1
		[Toggle]_FresnelToggle("Fresnel Toggle", Float) = 1
		[Toggle]_LightingToggle("Lighting Toggle", Float) = 1
		[Toggle]_AlbedoToggle("Albedo Toggle", Float) = 1
		[Toggle]_CustomLightFalloffToggle("Custom Light Falloff Toggle", Float) = 0
		_Gloss("Gloss", Range( 0 , 1)) = 0
		_WorldGradientOffset("World Gradient Offset", Float) = 0
		_WorldGradientScale("World Gradient Scale", Float) = 1
		_HeightGradientScale("Height Gradient Scale", Float) = 1
		_HeightGradientPatternStrength("Height Gradient Pattern Strength", Range( 0 , 1)) = 1
		_DitherNoise("DitherNoise", 2D) = "gray" {}
		_HeightMaskColour("Height Mask Colour", Color) = (0.5,0.5,0.5,0)
		_HeightGradient("Height Gradient", Range( 0 , 1)) = 1
		[HideInInspector] _texcoord2( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "TransparentCutout"  "Queue" = "AlphaTest+0" }
		Cull Back
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		#pragma target 4.6
		#pragma shader_feature_local _LOD_FADE_CROSSFADE
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float4 screenPosition;
			float4 vertexColor : COLOR;
			float3 worldPos;
			half3 worldNormal;
			INTERNAL_DATA
			float2 uv2_texcoord2;
		};

		struct SurfaceOutputCustomLightingCustom
		{
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			half Alpha;
			Input SurfInput;
			UnityGIInput GIData;
		};

		uniform sampler2D _DitherNoise;
		float4 _DitherNoise_TexelSize;
		uniform sampler2D _DetailMask;
		uniform half _ReflectionToggle;
		uniform half _Gloss;
		uniform half _HeightGradientScale;
		uniform half _WorldGradientOffset;
		uniform half _WorldGradientScale;
		uniform half _HeightGradientPatternStrength;
		uniform half _HeightGradient;
		uniform half _IndirectToggle;
		uniform sampler2D _Albedo;
		uniform half4 _HeightMaskColour;
		uniform half _FresnelToggle;
		uniform half _LightFresnel;
		uniform half _LightFresnelPower;
		uniform half _LightingToggle;
		uniform half _CustomLightFalloffToggle;
		uniform half _lightwrapscale;
		uniform half _lightwrapoffset;
		uniform half _AlbedoToggle;
		uniform half4 _SunColour;
		uniform half _SunAtmosDensity;
		uniform half3 _SunDirection;
		uniform half _SunAtmosFalloff;
		UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
		uniform float4 _CameraDepthTexture_TexelSize;
		uniform float _Cutoff = 0.5;


		inline float DitherNoiseTex( float4 screenPos, sampler2D noiseTexture, float4 noiseTexelSize )
		{
			float dither = tex2Dlod( noiseTexture, float4(screenPos.xy * _ScreenParams.xy * noiseTexelSize.xy, 0, 0) ).g;
			float ditherRate = noiseTexelSize.x * noiseTexelSize.y;
			dither = ( 1 - ditherRate ) * dither + ditherRate;
			return dither;
		}


		inline float4 TriplanarSampling162( sampler2D topTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index )
		{
			float3 projNormal = ( pow( abs( worldNormal ), falloff ) );
			projNormal /= ( projNormal.x + projNormal.y + projNormal.z ) + 0.00001;
			float3 nsign = sign( worldNormal );
			half4 xNorm; half4 yNorm; half4 zNorm;
			xNorm = tex2D( topTexMap, tiling * worldPos.zy * float2(  nsign.x, 1.0 ) );
			yNorm = tex2D( topTexMap, tiling * worldPos.xz * float2(  nsign.y, 1.0 ) );
			zNorm = tex2D( topTexMap, tiling * worldPos.xy * float2( -nsign.z, 1.0 ) );
			return xNorm * projNormal.x + yNorm * projNormal.y + zNorm * projNormal.z;
		}


		struct Gradient
		{
			int type;
			int colorsLength;
			int alphasLength;
			float4 colors[8];
			float2 alphas[8];
		};


		Gradient NewGradient(int type, int colorsLength, int alphasLength, 
		float4 colors0, float4 colors1, float4 colors2, float4 colors3, float4 colors4, float4 colors5, float4 colors6, float4 colors7,
		float2 alphas0, float2 alphas1, float2 alphas2, float2 alphas3, float2 alphas4, float2 alphas5, float2 alphas6, float2 alphas7)
		{
			Gradient g;
			g.type = type;
			g.colorsLength = colorsLength;
			g.alphasLength = alphasLength;
			g.colors[ 0 ] = colors0;
			g.colors[ 1 ] = colors1;
			g.colors[ 2 ] = colors2;
			g.colors[ 3 ] = colors3;
			g.colors[ 4 ] = colors4;
			g.colors[ 5 ] = colors5;
			g.colors[ 6 ] = colors6;
			g.colors[ 7 ] = colors7;
			g.alphas[ 0 ] = alphas0;
			g.alphas[ 1 ] = alphas1;
			g.alphas[ 2 ] = alphas2;
			g.alphas[ 3 ] = alphas3;
			g.alphas[ 4 ] = alphas4;
			g.alphas[ 5 ] = alphas5;
			g.alphas[ 6 ] = alphas6;
			g.alphas[ 7 ] = alphas7;
			return g;
		}


		float4 SampleGradient( Gradient gradient, float time )
		{
			float3 color = gradient.colors[0].rgb;
			UNITY_UNROLL
			for (int c = 1; c < 8; c++)
			{
			float colorPos = saturate((time - gradient.colors[c-1].w) / ( 0.00001 + (gradient.colors[c].w - gradient.colors[c-1].w)) * step(c, (float)gradient.colorsLength-1));
			color = lerp(color, gradient.colors[c].rgb, lerp(colorPos, step(0.01, colorPos), gradient.type));
			}
			#ifndef UNITY_COLORSPACE_GAMMA
			color = half3(GammaToLinearSpaceExact(color.r), GammaToLinearSpaceExact(color.g), GammaToLinearSpaceExact(color.b));
			#endif
			float alpha = gradient.alphas[0].x;
			UNITY_UNROLL
			for (int a = 1; a < 8; a++)
			{
			float alphaPos = saturate((time - gradient.alphas[a-1].y) / ( 0.00001 + (gradient.alphas[a].y - gradient.alphas[a-1].y)) * step(a, (float)gradient.alphasLength-1));
			alpha = lerp(alpha, gradient.alphas[a].x, lerp(alphaPos, step(0.01, alphaPos), gradient.type));
			}
			return float4(color, alpha);
		}


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float4 ase_screenPos = ComputeScreenPos( UnityObjectToClipPos( v.vertex ) );
			o.screenPosition = ase_screenPos;
		}

		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			#ifdef UNITY_PASS_FORWARDBASE
			float ase_lightAtten = data.atten;
			if( _LightColor0.a == 0)
			ase_lightAtten = 0;
			#else
			float3 ase_lightAttenRGB = gi.light.color / ( ( _LightColor0.rgb ) + 0.000001 );
			float ase_lightAtten = max( max( ase_lightAttenRGB.r, ase_lightAttenRGB.g ), ase_lightAttenRGB.b );
			#endif
			#if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
			half bakedAtten = UnitySampleBakedOcclusion(data.lightmapUV.xy, data.worldPos);
			float zDist = dot(_WorldSpaceCameraPos - data.worldPos, UNITY_MATRIX_V[2].xyz);
			float fadeDist = UnityComputeShadowFadeDistance(data.worldPos, zDist);
			ase_lightAtten = UnityMixRealtimeAndBakedShadows(data.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
			#endif
			float4 ase_screenPos = i.screenPosition;
			half4 ase_screenPosNorm = ase_screenPos / ase_screenPos.w;
			ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
			half dither343 = DitherNoiseTex(ase_screenPosNorm, _DitherNoise, _DitherNoise_TexelSize);
			half VertexAlpha308 = i.vertexColor.a;
			float3 ase_worldPos = i.worldPos;
			half3 ase_worldNormal = WorldNormalVector( i, half3( 0, 0, 1 ) );
			float4 triplanar162 = TriplanarSampling162( _DetailMask, ase_worldPos, ase_worldNormal, 1.0, float2( 0.05,0.05 ), 1.0, 0 );
			half DetailPattern_A146 = triplanar162.w;
			half saferPower339 = max( ( VertexAlpha308 / DetailPattern_A146 ) , 0.0001 );
			#ifdef _LOD_FADE_CROSSFADE
				half staticSwitch331 = unity_LODFade.x;
			#else
				half staticSwitch331 = round( saturate( max( VertexAlpha308 , pow( saferPower339 , 2.2 ) ) ) );
			#endif
			dither343 = step( dither343, staticSwitch331 );
			half AlphaCutout318 = dither343;
			half DetailPattern_R149 = triplanar162.x;
			half temp_output_189_0 = ( ase_worldPos.y + ( 1.0 - _WorldGradientOffset ) );
			half temp_output_198_0 = ( 1.0 - ( temp_output_189_0 * ( _WorldGradientScale / 100.0 ) ) );
			half saferPower246 = max( (0.0 + (i.vertexColor.g - 0.25) * (1.0 - 0.0) / (0.0 - 0.25)) , 0.0001 );
			half Cavities219 = saturate( pow( saferPower246 , 2.2 ) );
			half lerpResult298 = lerp( temp_output_198_0 , ( temp_output_198_0 * Cavities219 ) , 0.5);
			half blendOpSrc164 = pow( DetailPattern_R149 , _HeightGradientScale );
			half blendOpDest164 = lerpResult298;
			half lerpBlendMode164 = lerp(blendOpDest164,( 1.0 - ( ( 1.0 - blendOpDest164) / max( blendOpSrc164, 0.00001) ) ),_HeightGradientPatternStrength);
			half lerpResult202 = lerp( 0.0 , saturate( ( saturate( lerpBlendMode164 )) ) , _HeightGradient);
			half heightGradientMask168 = lerpResult202;
			half lerpResult208 = lerp( _Gloss , 1.0 , heightGradientMask168);
			half gloss204 = lerpResult208;
			half globalIllumination110 = i.vertexColor.r;
			Unity_GlossyEnvironmentData g79 = UnityGlossyEnvironmentSetup( gloss204, data.worldViewDir, ase_worldNormal, float3(0,0,0));
			half3 indirectSpecular79 = UnityGI_IndirectSpecular( data, globalIllumination110, ase_worldNormal, g79 );
			half3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			half fresnelNdotV80 = dot( ase_worldNormal, ase_worldViewDir );
			half ior80 = 1.6;
			ior80 = pow( ( 1 - ior80 ) / ( 1 + ior80 ), 2 );
			half fresnelNode80 = ( ior80 + ( 1.0 - ior80 ) * pow( 1.0 - fresnelNdotV80, 5 ) );
			half clampResult102 = clamp( fresnelNode80 , 0.0 , 1.0 );
			half3 lerpResult81 = lerp( float3( 0,0,0 ) , indirectSpecular79 , clampResult102);
			half heightGradient112 = i.vertexColor.b;
			half3 reflection153 = ( lerpResult81 * max( heightGradient112 , gloss204 ) );
			half saferPower245 = max( (0.0 + (i.vertexColor.g - 0.25) * (1.0 - 0.0) / (1.0 - 0.25)) , 0.0001 );
			half Edges111 = saturate( pow( saferPower245 , 2.2 ) );
			half DetailPattern_B147 = triplanar162.z;
			half saferPower264 = max( ( Edges111 * DetailPattern_B147 * 50 ) , 0.0001 );
			half DetailPattern_G148 = triplanar162.y;
			half saferPower289 = max( ( Cavities219 * DetailPattern_G148 * 5 ) , 0.0001 );
			half2 appendResult409 = (half2(i.uv2_texcoord2.x , ( ( ( saturate( pow( saferPower264 , 1.25 ) ) * 0.1 ) + i.uv2_texcoord2.y ) - ( saturate( pow( saferPower289 , 1.25 ) ) * 0.1 ) )));
			half2 Albedo_UV410 = appendResult409;
			half4 HeightColour181 = _HeightMaskColour;
			half4 lerpResult170 = lerp( saturate( tex2D( _Albedo, Albedo_UV410 ) ) , HeightColour181 , heightGradientMask168);
			half4 albedo129 = lerpResult170;
			UnityGI gi14 = gi;
			float3 diffNorm14 = ase_worldNormal;
			gi14 = UnityGI_Base( data, 1, diffNorm14 );
			half3 indirectDiffuse14 = gi14.indirect.diffuse + diffNorm14 * 0.0001;
			half4 Indirect151 = ( ( globalIllumination110 + ( ( 1.0 - globalIllumination110 ) * ( albedo129 / 2.0 ) ) ) * half4( indirectDiffuse14 , 0.0 ) );
			half3 ase_normWorldNormal = normalize( ase_worldNormal );
			half fresnelNdotV76 = dot( ase_normWorldNormal, ase_worldViewDir );
			half fresnelNode76 = ( 0.0 + _LightFresnel * pow( max( 1.0 - fresnelNdotV76 , 0.0001 ), _LightFresnelPower ) );
			#if defined(LIGHTMAP_ON) && ( UNITY_VERSION < 560 || ( defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN) ) )//aselc
			half4 ase_lightColor = 0;
			#else //aselc
			half4 ase_lightColor = _LightColor0;
			#endif //aselc
			half3 Fresnel155 = ( fresnelNode76 * ase_lightAtten * ase_lightColor.rgb );
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			half3 ase_worldlightDir = 0;
			#else //aseld
			half3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			half dotResult7 = dot( ase_worldNormal , ase_worldlightDir );
			Gradient gradient387 = NewGradient( 0, 2, 2, float4( 0, 0, 0, 0.4500038 ), float4( 1, 1, 1, 0.5499962 ), 0, 0, 0, 0, 0, 0, float2( 1, 0 ), float2( 1, 1 ), 0, 0, 0, 0, 0, 0 );
			#ifdef UNITY_PASS_FORWARDBASE
				half staticSwitch388 = SampleGradient( gradient387, ase_lightAtten ).r;
			#else
				half staticSwitch388 = ase_lightAtten;
			#endif
			half4 appendResult381 = (half4(( ase_lightColor.rgb * staticSwitch388 ) , 0.0));
			half4 Lighting157 = ( ( (( _CustomLightFalloffToggle )?( max( (dotResult7*_lightwrapscale + _lightwrapoffset) , 0.0 ) ):( max( dotResult7 , 0.0 ) )) * ase_lightColor.a ) * appendResult381 );
			half4 SunColour138_g1 = _SunColour;
			half3 normalizeResult114_g1 = normalize( ase_worldViewDir );
			half dotResult115_g1 = dot( _SunDirection , normalizeResult114_g1 );
			half SunAtmosMask139_g1 = pow( ( ( _SunAtmosDensity / 3.0 ) * max( ( 2.0 + ( 1.0 - acos( dotResult115_g1 ) ) ) , 0.0 ) ) , (2.0 + (_SunAtmosFalloff - 0.0) * (50.0 - 2.0) / (1.0 - 0.0)) );
			half4 SunAtmos359 = ( SunColour138_g1 * SunAtmosMask139_g1 );
			half eyeDepth346 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ase_screenPosNorm.xy ));
			half SkyAtmosMask363 = saturate( ( eyeDepth346 * unity_FogParams.x ) );
			half4 lerpResult349 = lerp( ( half4( (( _ReflectionToggle )?( reflection153 ):( float3( 0,0,0 ) )) , 0.0 ) + ( ( (( _IndirectToggle )?( Indirect151 ):( float4( 0,0,0,0 ) )) + half4( (( _FresnelToggle )?( Fresnel155 ):( float3( 0,0,0 ) )) , 0.0 ) + (( _LightingToggle )?( Lighting157 ):( float4( 0,0,0,0 ) )) ) * (( _AlbedoToggle )?( albedo129 ):( float4( 0.5,0.5,0.5,0 ) )) ) ) , ( half4( ( ase_lightColor.rgb * float3( 0.3,0.3,0.3 ) ) , 0.0 ) * SunAtmos359 ) , SkyAtmosMask363);
			c.rgb = lerpResult349.rgb;
			c.a = 1;
			clip( AlphaCutout318 - _Cutoff );
			return c;
		}

		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
			o.Normal = float3(0,0,1);
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows exclude_path:deferred nolightmap  nodynlightmap nodirlightmap dithercrossfade vertex:vertexDataFunc 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 4.6
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float4 customPack1 : TEXCOORD1;
				float2 customPack2 : TEXCOORD2;
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				half4 color : COLOR0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				vertexDataFunc( v, customInputData );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xyzw = customInputData.screenPosition;
				o.customPack2.xy = customInputData.uv2_texcoord2;
				o.customPack2.xy = v.texcoord1;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				o.color = v.color;
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.screenPosition = IN.customPack1.xyzw;
				surfIN.uv2_texcoord2 = IN.customPack2.xy;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				surfIN.vertexColor = IN.color;
				SurfaceOutputCustomLightingCustom o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputCustomLightingCustom, o )
				surf( surfIN, o );
				UnityGI gi;
				UNITY_INITIALIZE_OUTPUT( UnityGI, gi );
				o.Alpha = LightingStandardCustomLighting( o, worldViewDir, gi ).a;
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18800
1920;0;1920;1019;147.5576;55.39143;1.559999;True;False
Node;AmplifyShaderEditor.CommentaryNode;179;-2244.699,-1445.456;Inherit;False;1181.245;765.9802;;17;110;111;245;238;219;112;246;218;215;247;239;222;109;308;336;404;405;VERTEX DATA;1,1,1,1;0;0
Node;AmplifyShaderEditor.VertexColorNode;109;-2184.879,-1279.506;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;178;-2281.552,-1974.543;Inherit;False;1235.862;459.8746;;6;148;147;146;149;162;145;DETAIL PATTERNS;1,1,1,1;0;0
Node;AmplifyShaderEditor.TFHCRemapNode;215;-1817.862,-1277.761;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0.25;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;218;-1815.104,-1074.917;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0.25;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;145;-2229.312,-1854.097;Inherit;True;Property;_DetailMask;Detail Mask;14;0;Create;True;0;0;0;False;0;False;95fb59503f3acf040b94dae940963d73;95fb59503f3acf040b94dae940963d73;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.PowerNode;245;-1640.098,-1275.06;Inherit;False;True;2;0;FLOAT;0;False;1;FLOAT;2.2;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;246;-1610.808,-1074.232;Inherit;False;True;2;0;FLOAT;0;False;1;FLOAT;2.2;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;404;-1464.052,-1266.82;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TriplanarNode;162;-1825.867,-1852.764;Inherit;True;Spherical;World;False;Top Texture 0;_TopTexture0;white;-1;None;Mid Texture 0;_MidTexture0;white;1;None;Bot Texture 0;_BotTexture0;white;0;None;Triplanar Sampler;Tangent;10;0;SAMPLER2D;;False;5;FLOAT;1;False;1;SAMPLER2D;;False;6;FLOAT;0;False;2;SAMPLER2D;;False;7;FLOAT;0;False;9;FLOAT3;0,0,0;False;8;FLOAT;1;False;3;FLOAT2;0.05,0.05;False;4;FLOAT;1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;169;-3051.952,1466.075;Inherit;False;2635.429;1027.185;;26;296;190;159;176;167;194;184;181;168;202;172;203;175;164;177;191;198;166;161;196;197;189;193;183;298;301;HEIGHT GRADIENT;1,1,1,1;0;0
Node;AmplifyShaderEditor.SaturateNode;405;-1431.052,-1071.82;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;111;-1317.592,-1272.19;Inherit;False;Edges;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;147;-1277.484,-1758.067;Inherit;False;DetailPattern_B;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;119;-365.7763,803.8242;Inherit;False;2961.959;888.0752;;29;134;281;410;408;407;280;409;406;129;170;136;182;171;291;287;290;345;271;289;264;288;344;265;270;266;292;293;295;411;ALBEDO;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;219;-1261.932,-1080.58;Inherit;False;Cavities;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;266;-108.1897,1178.642;Inherit;False;147;DetailPattern_B;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.IntNode;270;-60.62831,1293.73;Inherit;False;Constant;_EdgeStrength;EdgeStrength;21;0;Create;True;0;0;0;False;0;False;50;0;False;0;1;INT;0
Node;AmplifyShaderEditor.GetLocalVarNode;134;-90.68562,1064.634;Inherit;False;111;Edges;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;148;-1275.314,-1840.518;Inherit;False;DetailPattern_G;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;193;-3004.871,2021.561;Inherit;False;Property;_WorldGradientOffset;World Gradient Offset;27;0;Create;True;0;0;0;False;0;False;0;-43.16;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;265;141.6603,1148.775;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;197;-2969.179,2176.352;Inherit;False;Property;_WorldGradientScale;World Gradient Scale;28;0;Create;True;0;0;0;False;0;False;1;25;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.IntNode;295;-53.21743,1571.615;Inherit;False;Constant;_CavityStrength;CavityStrength;21;0;Create;True;0;0;0;False;0;False;5;0;False;0;1;INT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;183;-3006.935,1846.788;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;344;152.1283,1293.722;Inherit;False;Constant;_EdgeCavityPower;EdgeCavityPower;24;0;Create;True;0;0;0;False;0;False;1.25;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;293;-69.92226,1487.851;Inherit;False;148;DetailPattern_G;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;300;-2742.949,2022.935;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;292;-55.78652,1397.904;Inherit;False;219;Cavities;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;301;-2586.446,2182.572;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;100;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;189;-2570.143,1896.019;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;264;358.8104,1141.405;Inherit;False;True;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;288;223.5479,1400.525;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;196;-2426.418,2008.492;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;289;403.6978,1394.155;Inherit;False;True;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;271;520.1266,1141.116;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;345;477.4081,1277.697;Inherit;False;Constant;_EdgeCavityAmount;EdgeCavityAmount;24;0;Create;True;0;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;290;565.0145,1393.866;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;296;-2355.216,2230.198;Inherit;False;219;Cavities;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;406;955.3319,1228.47;Inherit;False;1;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;198;-2283.418,2011.219;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;149;-1276.259,-1924.543;Inherit;False;DetailPattern_R;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;287;724.9836,1127.192;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.075;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;407;1278.599,1130.497;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;305;-2109.123,2094.933;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;161;-1882.619,1577.018;Inherit;False;149;DetailPattern_R;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;166;-2255.429,1872.57;Inherit;False;Property;_HeightGradientScale;Height Gradient Scale;30;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;291;759.6017,1390.817;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.075;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;408;1567.764,1364.154;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;191;-1635.148,1631.917;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;177;-1690.778,1992.428;Inherit;False;Property;_HeightGradientPatternStrength;Height Gradient Pattern Strength;31;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;298;-1927.975,1997.011;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;409;1923.342,1257.541;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BlendOpsNode;164;-1354.693,1749.341;Inherit;False;ColorBurn;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;410;2141.496,1247.81;Inherit;False;Albedo_UV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SaturateNode;175;-1143.894,1759.162;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;203;-1203.663,1906.335;Inherit;False;Property;_HeightGradient;Height Gradient;35;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;411;-253.5684,900.8723;Inherit;False;410;Albedo_UV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ColorNode;172;-1925.257,2208.917;Inherit;False;Property;_HeightMaskColour;Height Mask Colour;33;0;Create;True;0;0;0;False;0;False;0.5,0.5,0.5,0;0.5499999,0.5133326,0.3299996,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;202;-908.7432,1760.894;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;168;-702.4153,1751.308;Inherit;False;heightGradientMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;181;-1428.375,2207.849;Inherit;False;HeightColour;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;281;16.55632,862.8063;Inherit;True;Property;_TextureSample1;Texture Sample 1;13;0;Create;True;0;0;0;False;0;False;-1;None;None;True;1;False;white;Auto;False;Instance;280;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;182;1850.6,986.2901;Inherit;False;181;HeightColour;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.CommentaryNode;98;-3044.109,349.9129;Inherit;False;2554.764;985.2625;;18;107;24;9;33;157;30;108;34;19;20;12;7;6;5;381;386;387;388;LIGHTING;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;171;1849.6,1081.291;Inherit;False;168;heightGradientMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;136;1852.399,883.4896;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;222;-1955.567,-1348.125;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;6;-2997.239,676.4863;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LerpOp;170;2152.6,888.2897;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.WorldNormalVector;5;-2972.909,501.8158;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;12;-2734.803,786.4366;Inherit;False;Property;_lightwrapscale;light wrap scale;15;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LightAttenuation;9;-2829.826,1216.626;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;7;-2699.827,606.9659;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;20;-2721.979,927.3377;Inherit;False;Property;_lightwrapoffset;light wrap offset;16;0;Create;True;0;0;0;False;0;False;0;0.25;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;249;-955.1546,-1879.636;Inherit;False;950.9152;388.2;;5;143;207;206;208;204;GLOSS;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;99;-1000.852,-634.1455;Inherit;False;1256.287;399.0397;;10;15;131;14;132;113;133;130;151;251;252;INDIRECT;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;110;-1373.422,-1393.948;Inherit;False;globalIllumination;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;129;2356.597,883.2897;Inherit;False;albedo;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GradientNode;387;-2838.591,1048.133;Inherit;False;0;2;2;0,0,0,0.4500038;1,1,1,0.5499962;1,0;1,1;0;1;OBJECT;0
Node;AmplifyShaderEditor.RangedFloatNode;143;-905.1546,-1820.582;Inherit;False;Property;_Gloss;Gloss;26;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;113;-956.477,-564.3163;Inherit;False;110;globalIllumination;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;130;-908.2126,-446.9914;Inherit;False;129;albedo;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;19;-2425.741,766.1241;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.5;False;2;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;133;-896.6468,-350.9792;Inherit;False;Constant;_Float4;Float 4;15;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;206;-895.7235,-1607.436;Inherit;False;168;heightGradientMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;336;-1928.162,-806.8273;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GradientSampleNode;386;-2585.036,1060.163;Inherit;True;2;0;OBJECT;;False;1;FLOAT;0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;207;-861.384,-1725.606;Inherit;False;Constant;_HeightGloss;HeightGloss;21;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;33;-2211.281,764.8139;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;251;-709.0109,-514.6468;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;388;-2251.832,1212.17;Inherit;False;Property;_Keyword0;Keyword 0;25;0;Create;True;0;0;0;False;0;False;0;0;0;False;UNITY_PASS_FORWARDBASE;Toggle;2;Key0;Key1;Fetch;True;True;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;132;-641.6968,-426.9792;Inherit;False;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LightColorNode;24;-2170.893,934.464;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.RegisterLocalVarNode;308;-1288.13,-758.1471;Inherit;False;VertexAlpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;208;-510.914,-1829.636;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;320;-197.7316,1837.686;Inherit;False;2044.87;602.4746;;12;371;318;343;329;331;330;342;341;339;337;311;310;ALPHA CUTOUT;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;97;-2230.036,-620.9398;Inherit;False;1157.633;784.1101;;7;75;69;65;74;76;64;155;FRESNEL;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;146;-1282.659,-1677.302;Inherit;False;DetailPattern_A;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;107;-2416.264,564.2794;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;239;-1847.675,-843.597;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;69;-2189.696,-484.1892;Inherit;False;Property;_LightFresnel;Light Fresnel;17;0;Create;True;0;0;0;False;0;False;3.60606;0.5;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;204;-228.2394,-1821.813;Inherit;False;gloss;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;100;-980.2807,-1170.111;Inherit;False;1550.794;462.9568;;11;153;211;116;210;115;81;79;102;80;114;205;REFLECTION;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;75;-2183.696,-276.1895;Inherit;False;Property;_LightFresnelPower;Light Fresnel Power;19;0;Create;True;0;0;0;False;0;False;4.323316;3;0.01;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;252;-489.4882,-503.1767;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;34;-1936.509,1024.063;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;311;-146.1615,1976.361;Inherit;False;146;DetailPattern_A;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;310;-138.7821,1887.686;Inherit;False;308;VertexAlpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;108;-2040.742,561.6194;Inherit;False;Property;_CustomLightFalloffToggle;Custom Light Falloff Toggle;25;0;Create;True;0;0;0;False;0;False;0;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.IndirectDiffuseLighting;14;-547.5056,-320.1958;Inherit;False;Tangent;1;0;FLOAT3;0,0,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LightColorNode;74;-1977.196,-37.78915;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;380;-1736.706,564.6489;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;131;-324.4746,-519.9796;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;114;-948.9617,-1002.031;Inherit;False;110;globalIllumination;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;112;-1298.391,-854.4362;Inherit;False;heightGradient;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LightAttenuation;65;-2003.696,-125.1891;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;381;-1371.523,1025.408;Inherit;False;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.FresnelNode;76;-1813.201,-394.0886;Inherit;False;Standard;WorldNormal;ViewDir;True;True;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;3;False;3;FLOAT;3;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;337;120.5863,1953.141;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;205;-927.7666,-1100.168;Inherit;False;204;gloss;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;80;-789.9624,-916.079;Inherit;False;SchlickIOR;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1.6;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.IndirectSpecularLight;79;-684.415,-1120.111;Inherit;False;Tangent;3;0;FLOAT3;0,0,1;False;1;FLOAT;0.25;False;2;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;116;-334.4409,-906.6933;Inherit;False;112;heightGradient;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;102;-540.3667,-910.9941;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;339;261.873,1955.086;Inherit;False;True;2;0;FLOAT;0;False;1;FLOAT;2.2;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;210;-306.4898,-815.4988;Inherit;False;204;gloss;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;15;-142.846,-465.4812;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;30;-1045.088,565.8421;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;64;-1547.591,-170.0292;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;157;-753.6042,562.749;Inherit;False;Lighting;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CommentaryNode;362;-2892.764,2737.168;Inherit;False;1296.587;592.0852;;5;350;363;361;346;370;SKY ATMOS MASK;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;341;449.8784,1890.386;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;250;-365.8394,-170.6563;Inherit;False;1322.913;834.1477;;19;349;360;364;128;103;127;126;43;154;140;104;105;106;158;156;152;393;392;395;COMPOSITE;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;151;38.98471,-521.6474;Inherit;False;Indirect;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;155;-1310.814,-154.1692;Inherit;False;Fresnel;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;81;-375.227,-1063.255;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;211;-92.37615,-892.7212;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;358;-864.785,2632.949;Inherit;False;1354.628;679.9285;;5;352;354;355;353;359;SKY ATMOS;1,1,1,1;0;0
Node;AmplifyShaderEditor.SaturateNode;342;601.5053,1892.615;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;355;-802.3374,3100.117;Inherit;False;Property;_SunAtmosFalloff;Sun Atmos Falloff;11;0;Create;True;0;0;0;False;0;False;0.5;0.2;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;354;-806.4727,2990.882;Inherit;False;Property;_SunAtmosDensity;Sun Atmos Density;10;0;Create;True;0;0;0;False;0;False;0.5;0.9;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;352;-814.785,2682.949;Inherit;False;Property;_HorizonFalloff;Horizon Falloff;9;0;Create;True;0;0;0;False;0;False;0.5;0.5;0.01;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenDepthNode;346;-2862.969,2860.632;Inherit;False;0;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FogParamsNode;370;-2833.836,2989.583;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;115;49.35546,-1067.15;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;156;-274.3698,189.2504;Inherit;False;155;Fresnel;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;353;-747.1304,2790.299;Inherit;False;Property;_SunColour;Sun Colour;12;1;[HDR];Create;True;0;0;0;False;0;False;2,1.47451,0.972549,0;2.996078,1.998792,0.7789804,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;158;-293.5102,331.2046;Inherit;False;157;Lighting;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;152;-304.2348,33.45266;Inherit;False;151;Indirect;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;350;-2380.498,2869.159;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.01;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;153;310.8263,-1073.783;Inherit;False;reflection;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LODFadeNode;330;761.6368,2090.329;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RoundOpNode;371;762.324,1898.114;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;106;-70.79145,308.8952;Inherit;False;Property;_LightingToggle;Lighting Toggle;23;0;Create;True;0;0;0;False;0;False;1;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.FunctionNode;394;-353.4372,2846.991;Inherit;False;SHF_SkyboxAtmos;0;;1;17edc35a0a6a77a4e97013dfc1d7324b;0;4;140;FLOAT;0.5;False;141;COLOR;0,0,0,0;False;142;FLOAT;0.9;False;143;FLOAT;0.6;False;3;COLOR;0;COLOR;144;COLOR;145
Node;AmplifyShaderEditor.GetLocalVarNode;140;-309.8537,485.3165;Inherit;False;129;albedo;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.ToggleSwitchNode;105;-72.85355,160.416;Inherit;False;Property;_FresnelToggle;Fresnel Toggle;22;0;Create;True;0;0;0;False;0;False;1;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ToggleSwitchNode;104;-91.43725,10.86987;Inherit;False;Property;_IndirectToggle;Indirect Toggle;21;0;Create;True;0;0;0;False;0;False;1;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;43;196.3432,163.4561;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT4;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ToggleSwitchNode;126;-85.53494,460.6005;Inherit;False;Property;_AlbedoToggle;Albedo Toggle;24;0;Create;True;0;0;0;False;0;False;1;2;0;COLOR;0.5,0.5,0.5,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;154;-315.8394,-91.46796;Inherit;False;153;reflection;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;359;47.62207,2850.093;Inherit;False;SunAtmos;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;361;-2142.452,2873.487;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LightColorNode;393;288.5498,-109.1319;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.StaticSwitch;331;1037.709,1987.269;Inherit;False;Property;_LOD_FADE_CROSSFADE;LOD_FADE_CROSSFADE;24;0;Create;True;0;0;0;False;0;False;0;0;0;False;;Toggle;2;Key0;Key1;Create;True;True;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;329;1043.525,2147.037;Inherit;True;Property;_DitherNoise;DitherNoise;32;0;Create;True;0;0;0;False;0;False;c5dfece29a2a5f4498d0616dcad73f65;c5dfece29a2a5f4498d0616dcad73f65;False;gray;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RegisterLocalVarNode;363;-1954.457,2869.015;Inherit;False;SkyAtmosMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;360;428.4375,24.82592;Inherit;False;359;SunAtmos;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;395;453.52,-86.02344;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0.3,0.3,0.3;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ToggleSwitchNode;103;-98.60773,-120.6563;Inherit;False;Property;_ReflectionToggle;Reflection Toggle;20;0;Create;True;0;0;0;False;0;False;1;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;127;353.1115,230.8499;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DitheringNode;343;1333.807,1984.727;Inherit;False;2;False;4;0;FLOAT;0;False;1;SAMPLER2D;;False;2;FLOAT4;0,0,0,0;False;3;SAMPLERSTATE;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;318;1566.087,1891.096;Inherit;False;AlphaCutout;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;128;517.6778,140.189;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;392;610.0226,-34.80862;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;364;574.2684,309.1372;Inherit;False;363;SkyAtmosMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;184;-2462.317,1746.552;Inherit;False;Property;_HeightMaskWorldSpace;Height Mask World Space;34;0;Create;True;0;0;0;False;0;False;0;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;319;1083.284,40.78177;Inherit;False;318;AlphaCutout;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;167;-3026.204,1694.478;Inherit;False;Property;_HeightGradientOffset;Height Gradient Offset;29;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;349;797.0843,132.1516;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;176;-2198.955,1754.895;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;280;905.0341,1483.062;Inherit;True;Property;_Albedo;Albedo;13;0;Create;True;0;0;0;False;0;False;-1;4b47542f94d80e84fbf0f9cda3727ed6;4b47542f94d80e84fbf0f9cda3727ed6;True;1;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;238;-1305.464,-953.8018;Inherit;False;Curvature;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;247;-1801.953,-895.879;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;159;-3022.421,1604.714;Inherit;False;112;heightGradient;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;401;1090.523,272.8561;Inherit;False;129;albedo;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.PowerNode;190;-2006.14,1750.047;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;10;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;194;-2770.952,1580.167;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1347.3,-100.1051;Half;False;True;-1;6;ASEMaterialInspector;0;0;CustomLighting;OSW/Form;False;False;False;False;False;False;True;True;True;False;False;False;True;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Masked;0.5;True;True;0;False;TransparentCutout;;AlphaTest;ForwardOnly;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0.1;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;18;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;215;0;109;2
WireConnection;218;0;109;2
WireConnection;245;0;215;0
WireConnection;246;0;218;0
WireConnection;404;0;245;0
WireConnection;162;0;145;0
WireConnection;405;0;246;0
WireConnection;111;0;404;0
WireConnection;147;0;162;3
WireConnection;219;0;405;0
WireConnection;148;0;162;2
WireConnection;265;0;134;0
WireConnection;265;1;266;0
WireConnection;265;2;270;0
WireConnection;300;0;193;0
WireConnection;301;0;197;0
WireConnection;189;0;183;2
WireConnection;189;1;300;0
WireConnection;264;0;265;0
WireConnection;264;1;344;0
WireConnection;288;0;292;0
WireConnection;288;1;293;0
WireConnection;288;2;295;0
WireConnection;196;0;189;0
WireConnection;196;1;301;0
WireConnection;289;0;288;0
WireConnection;289;1;344;0
WireConnection;271;0;264;0
WireConnection;290;0;289;0
WireConnection;198;0;196;0
WireConnection;149;0;162;1
WireConnection;287;0;271;0
WireConnection;287;1;345;0
WireConnection;407;0;287;0
WireConnection;407;1;406;2
WireConnection;305;0;198;0
WireConnection;305;1;296;0
WireConnection;291;0;290;0
WireConnection;291;1;345;0
WireConnection;408;0;407;0
WireConnection;408;1;291;0
WireConnection;191;0;161;0
WireConnection;191;1;166;0
WireConnection;298;0;198;0
WireConnection;298;1;305;0
WireConnection;409;0;406;1
WireConnection;409;1;408;0
WireConnection;164;0;191;0
WireConnection;164;1;298;0
WireConnection;164;2;177;0
WireConnection;410;0;409;0
WireConnection;175;0;164;0
WireConnection;202;1;175;0
WireConnection;202;2;203;0
WireConnection;168;0;202;0
WireConnection;181;0;172;0
WireConnection;281;1;411;0
WireConnection;136;0;281;0
WireConnection;222;0;109;1
WireConnection;170;0;136;0
WireConnection;170;1;182;0
WireConnection;170;2;171;0
WireConnection;7;0;5;0
WireConnection;7;1;6;0
WireConnection;110;0;222;0
WireConnection;129;0;170;0
WireConnection;19;0;7;0
WireConnection;19;1;12;0
WireConnection;19;2;20;0
WireConnection;336;0;109;4
WireConnection;386;0;387;0
WireConnection;386;1;9;0
WireConnection;33;0;19;0
WireConnection;251;0;113;0
WireConnection;388;1;9;0
WireConnection;388;0;386;1
WireConnection;132;0;130;0
WireConnection;132;1;133;0
WireConnection;308;0;336;0
WireConnection;208;0;143;0
WireConnection;208;1;207;0
WireConnection;208;2;206;0
WireConnection;146;0;162;4
WireConnection;107;0;7;0
WireConnection;239;0;109;3
WireConnection;204;0;208;0
WireConnection;252;0;251;0
WireConnection;252;1;132;0
WireConnection;34;0;24;1
WireConnection;34;1;388;0
WireConnection;108;0;107;0
WireConnection;108;1;33;0
WireConnection;380;0;108;0
WireConnection;380;1;24;2
WireConnection;131;0;113;0
WireConnection;131;1;252;0
WireConnection;112;0;239;0
WireConnection;381;0;34;0
WireConnection;76;2;69;0
WireConnection;76;3;75;0
WireConnection;337;0;310;0
WireConnection;337;1;311;0
WireConnection;79;1;205;0
WireConnection;79;2;114;0
WireConnection;102;0;80;0
WireConnection;339;0;337;0
WireConnection;15;0;131;0
WireConnection;15;1;14;0
WireConnection;30;0;380;0
WireConnection;30;1;381;0
WireConnection;64;0;76;0
WireConnection;64;1;65;0
WireConnection;64;2;74;1
WireConnection;157;0;30;0
WireConnection;341;0;310;0
WireConnection;341;1;339;0
WireConnection;151;0;15;0
WireConnection;155;0;64;0
WireConnection;81;1;79;0
WireConnection;81;2;102;0
WireConnection;211;0;116;0
WireConnection;211;1;210;0
WireConnection;342;0;341;0
WireConnection;115;0;81;0
WireConnection;115;1;211;0
WireConnection;350;0;346;0
WireConnection;350;1;370;1
WireConnection;153;0;115;0
WireConnection;371;0;342;0
WireConnection;106;1;158;0
WireConnection;394;140;352;0
WireConnection;394;141;353;0
WireConnection;394;142;354;0
WireConnection;394;143;355;0
WireConnection;105;1;156;0
WireConnection;104;1;152;0
WireConnection;43;0;104;0
WireConnection;43;1;105;0
WireConnection;43;2;106;0
WireConnection;126;1;140;0
WireConnection;359;0;394;145
WireConnection;361;0;350;0
WireConnection;331;1;371;0
WireConnection;331;0;330;1
WireConnection;363;0;361;0
WireConnection;395;0;393;1
WireConnection;103;1;154;0
WireConnection;127;0;43;0
WireConnection;127;1;126;0
WireConnection;343;0;331;0
WireConnection;343;1;329;0
WireConnection;318;0;343;0
WireConnection;128;0;103;0
WireConnection;128;1;127;0
WireConnection;392;0;395;0
WireConnection;392;1;360;0
WireConnection;184;0;194;0
WireConnection;184;1;189;0
WireConnection;349;0;128;0
WireConnection;349;1;392;0
WireConnection;349;2;364;0
WireConnection;176;0;184;0
WireConnection;238;0;247;0
WireConnection;247;0;109;2
WireConnection;190;0;176;0
WireConnection;190;1;166;0
WireConnection;194;0;159;0
WireConnection;194;1;167;0
WireConnection;0;10;319;0
WireConnection;0;13;349;0
ASEEND*/
//CHKSM=516AFF06F0E3CAB104CDBD246FAA3E15DA3475B0