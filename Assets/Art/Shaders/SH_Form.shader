// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "SH_Form"
{
	Properties
	{
		_lightwrapscale("light wrap scale", Range( 0 , 1)) = 1
		_lightwrapoffset("light wrap offset", Range( 0 , 1)) = 0
		_LightFresnel("Light Fresnel", Range( 0 , 10)) = 3.60606
		_LightFresnelPower("Light Fresnel Power", Range( 0.01 , 10)) = 4.323316
		[Toggle]_ReflectionToggle("Reflection Toggle", Float) = 1
		[Toggle]_IndirectToggle("Indirect Toggle", Float) = 1
		[Toggle]_FresnelToggle("Fresnel Toggle", Float) = 1
		[Toggle]_LightingToggle("Lighting Toggle", Float) = 1
		[Toggle]_AlbedoToggle("Albedo Toggle", Float) = 1
		[Toggle]_CustomLightFalloffToggle("Custom Light Falloff Toggle", Float) = 1
		_Albedo("Albedo", 2D) = "gray" {}
		_Gloss("Gloss", Range( 0 , 1)) = 0
		_DetailMask("Detail Mask", 2D) = "white" {}
		_HeightGradientScale("Height Gradient Scale", Float) = 1
		_HeightWorldScale("Height World Scale", Float) = 1
		_HeightGradientPatternStrength("Height Gradient Pattern Strength", Range( 0 , 1)) = 1
		_HeightWorldOffset("Height World Offset", Float) = 0
		_HeightMaskColour("Height Mask Colour", Color) = (0.5,0.5,0.5,0)
		_HeightGradient("Height Gradient", Range( 0 , 1)) = 1
		[HideInInspector] _texcoord2( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		Cull Back
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
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
			half3 worldNormal;
			INTERNAL_DATA
			float3 worldPos;
			float4 vertexColor : COLOR;
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

		uniform half _ReflectionToggle;
		uniform half _Gloss;
		uniform sampler2D _DetailMask;
		uniform half _HeightGradientScale;
		uniform half _HeightWorldOffset;
		uniform half _HeightWorldScale;
		uniform half _HeightGradientPatternStrength;
		uniform half _HeightGradient;
		uniform half _IndirectToggle;
		uniform sampler2D _Albedo;
		uniform half4 _Albedo_ST;
		uniform half4 _HeightMaskColour;
		uniform half _FresnelToggle;
		uniform half _LightFresnel;
		uniform half _LightFresnelPower;
		uniform half _LightingToggle;
		uniform half _CustomLightFalloffToggle;
		uniform half _lightwrapscale;
		uniform half _lightwrapoffset;
		uniform half _AlbedoToggle;


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
			half3 ase_worldNormal = WorldNormalVector( i, half3( 0, 0, 1 ) );
			float3 ase_worldPos = i.worldPos;
			float4 triplanar162 = TriplanarSampling162( _DetailMask, ase_worldPos, ase_worldNormal, 1.0, float2( 0.1,0.1 ), 1.0, 0 );
			half DetailPattern_R149 = triplanar162.x;
			half temp_output_189_0 = ( ase_worldPos.y + _HeightWorldOffset );
			half blendOpSrc164 = pow( DetailPattern_R149 , _HeightGradientScale );
			half blendOpDest164 = ( 1.0 - ( temp_output_189_0 * _HeightWorldScale ) );
			half lerpBlendMode164 = lerp(blendOpDest164,( 1.0 - ( ( 1.0 - blendOpDest164) / max( blendOpSrc164, 0.00001) ) ),_HeightGradientPatternStrength);
			half temp_output_175_0 = saturate( ( saturate( lerpBlendMode164 )) );
			half lerpResult202 = lerp( 0.0 , temp_output_175_0 , _HeightGradient);
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
			float2 uv2_Albedo = i.uv2_texcoord2 * _Albedo_ST.xy + _Albedo_ST.zw;
			half4 tex2DNode120 = tex2D( _Albedo, uv2_Albedo );
			half saferPower245 = max( (0.0 + (i.vertexColor.g - 0.25) * (1.0 - 0.0) / (1.0 - 0.25)) , 0.0001 );
			half Edges111 = pow( saferPower245 , 2.2 );
			half4 lerpResult213 = lerp( tex2DNode120 , ( tex2DNode120 + ( tex2DNode120 * Edges111 ) ) , float4( 0,0,0,0 ));
			half4 HeightColour181 = _HeightMaskColour;
			half4 lerpResult170 = lerp( saturate( lerpResult213 ) , HeightColour181 , heightGradientMask168);
			half4 albedo129 = lerpResult170;
			UnityGI gi14 = gi;
			float3 diffNorm14 = ase_worldNormal;
			gi14 = UnityGI_Base( data, 1, diffNorm14 );
			half3 indirectDiffuse14 = gi14.indirect.diffuse + diffNorm14 * 0.0001;
			half4 Indirect151 = ( ( globalIllumination110 + ( albedo129 / 4.0 ) ) * half4( indirectDiffuse14 , 0.0 ) );
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
			half3 Lighting157 = ( (( _CustomLightFalloffToggle )?( max( (dotResult7*_lightwrapscale + _lightwrapoffset) , 0.0 ) ):( max( dotResult7 , 0.0 ) )) * ( ase_lightAtten * ase_lightColor.rgb ) );
			c.rgb = ( half4( (( _ReflectionToggle )?( reflection153 ):( float3( 0,0,0 ) )) , 0.0 ) + ( ( (( _IndirectToggle )?( Indirect151 ):( float4( 0,0,0,0 ) )) + half4( (( _FresnelToggle )?( Fresnel155 ):( float3( 0,0,0 ) )) , 0.0 ) + half4( (( _LightingToggle )?( Lighting157 ):( float3( 0,0,0 ) )) , 0.0 ) ) * (( _AlbedoToggle )?( albedo129 ):( float4( 1,1,1,0 ) )) ) ).rgb;
			c.a = 1;
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
		#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
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
				float2 customPack1 : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
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
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv2_texcoord2;
				o.customPack1.xy = v.texcoord1;
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
				surfIN.uv2_texcoord2 = IN.customPack1.xy;
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
1920;0;1920;1019;158.219;1.735237;1.01;True;False
Node;AmplifyShaderEditor.CommentaryNode;178;-2281.552,-1974.543;Inherit;False;1235.862;459.8746;;6;148;147;146;149;162;145;DETAIL PATTERNS;1,1,1,1;0;0
Node;AmplifyShaderEditor.TexturePropertyNode;145;-2231.552,-1852.977;Inherit;True;Property;_DetailMask;Detail Mask;12;0;Create;True;0;0;0;False;0;False;95fb59503f3acf040b94dae940963d73;95fb59503f3acf040b94dae940963d73;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.CommentaryNode;169;-2167.684,1551.304;Inherit;False;1976.564;969.2802;;23;175;164;168;176;184;183;161;181;172;166;167;177;159;185;189;190;191;193;196;197;198;202;203;HEIGHT GRADIENT;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;179;-2244.699,-1445.456;Inherit;False;1181.245;765.9802;;13;110;111;245;238;219;112;246;218;215;247;239;222;109;VERTEX DATA;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldPosInputsNode;183;-2122.667,1932.017;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.VertexColorNode;109;-2184.879,-1279.506;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TriplanarNode;162;-1826.987,-1851.644;Inherit;True;Spherical;World;False;Top Texture 0;_TopTexture0;white;-1;None;Mid Texture 0;_MidTexture0;white;1;None;Bot Texture 0;_BotTexture0;white;0;None;Triplanar Sampler;Tangent;10;0;SAMPLER2D;;False;5;FLOAT;1;False;1;SAMPLER2D;;False;6;FLOAT;0;False;2;SAMPLER2D;;False;7;FLOAT;0;False;9;FLOAT3;0,0,0;False;8;FLOAT;1;False;3;FLOAT2;0.1,0.1;False;4;FLOAT;1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;193;-2117.233,2108.689;Inherit;False;Property;_HeightWorldOffset;Height World Offset;17;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;197;-1861.137,2220.812;Inherit;False;Property;_HeightWorldScale;Height World Scale;14;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;189;-1879.689,1950.715;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;215;-1757.262,-1285.841;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0.25;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;149;-1276.259,-1924.543;Inherit;False;DetailPattern_R;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;245;-1551.227,-1282.13;Inherit;False;True;2;0;FLOAT;0;False;1;FLOAT;2.2;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;196;-1627.597,2088.532;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;161;-1586.784,1659.117;Inherit;False;149;DetailPattern_R;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;166;-1709.193,1978.144;Inherit;False;Property;_HeightGradientScale;Height Gradient Scale;13;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;191;-1339.313,1714.016;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;119;-365.7762,838.5241;Inherit;False;2351.631;541.4853;;10;213;134;141;129;170;182;136;171;135;120;ALBEDO;1,1,1,1;0;0
Node;AmplifyShaderEditor.OneMinusNode;198;-1352.201,1983.771;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;177;-1435.639,2069.834;Inherit;False;Property;_HeightGradientPatternStrength;Height Gradient Pattern Strength;15;0;Create;True;0;0;0;False;0;False;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;111;-1359.752,-1283.07;Inherit;False;Edges;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;120;-346.6069,897.9252;Inherit;True;Property;_Albedo;Albedo;10;0;Create;True;0;0;0;False;0;False;-1;None;4b47542f94d80e84fbf0f9cda3727ed6;True;1;False;gray;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;134;-314.5005,1099.334;Inherit;False;111;Edges;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.BlendOpsNode;164;-1141.807,1848.655;Inherit;False;ColorBurn;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;203;-990.7776,2005.649;Inherit;False;Property;_HeightGradient;Height Gradient;20;0;Create;True;0;0;0;False;0;False;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;141;53.08612,1001.078;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;175;-931.0084,1858.476;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;135;253.2646,991.9281;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;202;-695.8578,1860.208;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;172;-1040.987,2294.146;Inherit;False;Property;_HeightMaskColour;Height Mask Colour;18;0;Create;True;0;0;0;False;0;False;0.5,0.5,0.5,0;0.5,0.5,0.5,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;168;-489.5311,1850.622;Inherit;False;heightGradientMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;181;-416.661,2278.718;Inherit;False;HeightColour;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;213;457.7238,918.3458;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CommentaryNode;98;-2191.043,429.1801;Inherit;False;1712.387;966.6977;;14;30;34;108;33;9;107;24;19;12;7;20;6;5;157;LIGHTING;1,1,1,1;0;0
Node;AmplifyShaderEditor.SaturateNode;136;770.389,936.6083;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;171;722.1984,1245.841;Inherit;False;168;heightGradientMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;182;728.3296,1053.766;Inherit;False;181;HeightColour;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.WorldNormalVector;5;-2116.713,668.7105;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;6;-2141.043,843.3811;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LerpOp;170;986.9092,940.1732;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.DotProductOpNode;7;-1843.632,773.8607;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;20;-1865.783,1094.233;Inherit;False;Property;_lightwrapoffset;light wrap offset;1;0;Create;True;0;0;0;False;0;False;0;0.25;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;129;1216.1,948.0254;Inherit;False;albedo;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;222;-1955.567,-1348.125;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;143;-905.1546,-1820.582;Inherit;False;Property;_Gloss;Gloss;11;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;12;-1878.607,978.1422;Inherit;False;Property;_lightwrapscale;light wrap scale;0;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;99;-1000.852,-634.1455;Inherit;False;1256.287;399.0397;;8;15;131;14;132;113;133;130;151;INDIRECT;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;207;-861.384,-1725.606;Inherit;False;Constant;_HeightGloss;HeightGloss;21;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;206;-895.7235,-1607.436;Inherit;False;168;heightGradientMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;19;-1542.755,847.9583;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.5;False;2;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;110;-1373.422,-1393.948;Inherit;False;globalIllumination;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;208;-510.914,-1829.636;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;97;-2230.036,-620.9398;Inherit;False;1157.633;784.1101;;7;75;69;65;74;76;64;155;FRESNEL;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;130;-908.2126,-446.9914;Inherit;False;129;albedo;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;133;-897.6968,-350.9792;Inherit;False;Constant;_Float4;Float 4;15;0;Create;True;0;0;0;False;0;False;4;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;204;-228.2394,-1821.813;Inherit;False;gloss;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;100;-980.2807,-1170.111;Inherit;False;1550.794;462.9568;;11;153;211;116;210;115;81;79;102;80;114;205;REFLECTION;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;107;-1461.749,625.5537;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LightAttenuation;9;-1406.055,1029.337;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;69;-2189.696,-484.1892;Inherit;False;Property;_LightFresnel;Light Fresnel;2;0;Create;True;0;0;0;False;0;False;3.60606;1;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;239;-1813.34,-789.6417;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;132;-641.6968,-426.9792;Inherit;False;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LightColorNode;24;-1380.497,1153.389;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;75;-2183.696,-276.1895;Inherit;False;Property;_LightFresnelPower;Light Fresnel Power;3;0;Create;True;0;0;0;False;0;False;4.323316;2;0.01;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;113;-956.477,-564.3163;Inherit;False;110;globalIllumination;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;33;-1346.816,863.8928;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;76;-1813.201,-394.0886;Inherit;False;Standard;WorldNormal;ViewDir;True;True;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;3;False;3;FLOAT;3;False;1;FLOAT;0
Node;AmplifyShaderEditor.LightAttenuation;65;-2003.696,-125.1891;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;108;-1184.547,728.5142;Inherit;False;Property;_CustomLightFalloffToggle;Custom Light Falloff Toggle;9;0;Create;True;0;0;0;False;0;False;1;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;34;-1119.351,1064.393;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;205;-927.7666,-1100.168;Inherit;False;204;gloss;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.IndirectDiffuseLighting;14;-547.5056,-320.1958;Inherit;False;Tangent;1;0;FLOAT3;0,0,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;114;-948.9617,-1002.031;Inherit;False;110;globalIllumination;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LightColorNode;74;-1977.196,-37.78915;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleAddOpNode;131;-437.8944,-515.7396;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;112;-1376.872,-782.4957;Inherit;False;heightGradient;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;80;-789.9624,-916.079;Inherit;False;SchlickIOR;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1.6;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.IndirectSpecularLight;79;-684.415,-1120.111;Inherit;False;Tangent;3;0;FLOAT3;0,0,1;False;1;FLOAT;0.25;False;2;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;30;-874.7369,779.7221;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;64;-1547.591,-170.0292;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;15;-256.2658,-461.2412;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClampOpNode;102;-540.3667,-910.9941;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;210;-306.4898,-815.4988;Inherit;False;204;gloss;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;116;-334.4409,-906.6933;Inherit;False;112;heightGradient;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;155;-1310.814,-154.1692;Inherit;False;Fresnel;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;151;-91.26526,-515.8774;Inherit;False;Indirect;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;211;-92.37615,-892.7212;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;157;-721.2493,777.5148;Inherit;False;Lighting;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;81;-375.227,-1063.255;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;158;-70.49023,270.3047;Inherit;False;157;Lighting;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;156;-51.34976,128.3505;Inherit;False;155;Fresnel;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;152;-81.21483,-27.44731;Inherit;False;151;Indirect;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;115;49.35546,-1067.15;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;140;-86.83379,424.4166;Inherit;False;129;albedo;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;153;310.8263,-1073.783;Inherit;False;reflection;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ToggleSwitchNode;106;152.2288,248.9953;Inherit;False;Property;_LightingToggle;Lighting Toggle;7;0;Create;True;0;0;0;False;0;False;1;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ToggleSwitchNode;105;150.1667,98.51608;Inherit;False;Property;_FresnelToggle;Fresnel Toggle;6;0;Create;True;0;0;0;False;0;False;1;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ToggleSwitchNode;104;131.583,-50.03011;Inherit;False;Property;_IndirectToggle;Indirect Toggle;5;0;Create;True;0;0;0;False;0;False;1;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;154;-92.81944,-152.3679;Inherit;False;153;reflection;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ToggleSwitchNode;126;137.4853,399.7006;Inherit;False;Property;_AlbedoToggle;Albedo Toggle;8;0;Create;True;0;0;0;False;0;False;1;2;0;COLOR;1,1,1,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;43;419.3621,102.5561;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ToggleSwitchNode;103;124.4125,-181.5562;Inherit;False;Property;_ReflectionToggle;Reflection Toggle;4;0;Create;True;0;0;0;False;0;False;1;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;127;576.1302,169.95;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TFHCRemapNode;218;-1749.454,-1081.987;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0.25;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;246;-1543.547,-1074.767;Inherit;False;True;2;0;FLOAT;0;False;1;FLOAT;2.2;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;219;-1324.553,-1080.58;Inherit;False;Cavities;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;148;-1275.314,-1840.518;Inherit;False;DetailPattern_G;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;159;-2138.153,1689.943;Inherit;False;112;heightGradient;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;147;-1277.484,-1758.067;Inherit;False;DetailPattern_B;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;176;-1484.774,1836.994;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;184;-1742.372,1831.781;Inherit;False;Property;_HeightMaskWorldSpace;Height Mask World Space;19;0;Create;True;0;0;0;False;0;False;0;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;185;-608.2004,2167.649;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;186;-794.6358,2157.233;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;190;-1320.623,1882.225;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;10;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;194;-1887.754,1731.736;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;146;-1282.659,-1677.302;Inherit;False;DetailPattern_A;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;167;-2141.936,1781.272;Inherit;False;Property;_HeightGradientOffset;Height Gradient Offset;16;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;128;735.9974,61.66408;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;238;-1388.849,-875.3213;Inherit;False;Curvature;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;247;-1691.382,-859.0886;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;965.2651,-126.375;Half;False;True;-1;2;ASEMaterialInspector;0;0;CustomLighting;SH_Form;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;162;0;145;0
WireConnection;189;0;183;2
WireConnection;189;1;193;0
WireConnection;215;0;109;2
WireConnection;149;0;162;1
WireConnection;245;0;215;0
WireConnection;196;0;189;0
WireConnection;196;1;197;0
WireConnection;191;0;161;0
WireConnection;191;1;166;0
WireConnection;198;0;196;0
WireConnection;111;0;245;0
WireConnection;164;0;191;0
WireConnection;164;1;198;0
WireConnection;164;2;177;0
WireConnection;141;0;120;0
WireConnection;141;1;134;0
WireConnection;175;0;164;0
WireConnection;135;0;120;0
WireConnection;135;1;141;0
WireConnection;202;1;175;0
WireConnection;202;2;203;0
WireConnection;168;0;202;0
WireConnection;181;0;172;0
WireConnection;213;0;120;0
WireConnection;213;1;135;0
WireConnection;136;0;213;0
WireConnection;170;0;136;0
WireConnection;170;1;182;0
WireConnection;170;2;171;0
WireConnection;7;0;5;0
WireConnection;7;1;6;0
WireConnection;129;0;170;0
WireConnection;222;0;109;1
WireConnection;19;0;7;0
WireConnection;19;1;12;0
WireConnection;19;2;20;0
WireConnection;110;0;222;0
WireConnection;208;0;143;0
WireConnection;208;1;207;0
WireConnection;208;2;206;0
WireConnection;204;0;208;0
WireConnection;107;0;7;0
WireConnection;239;0;109;3
WireConnection;132;0;130;0
WireConnection;132;1;133;0
WireConnection;33;0;19;0
WireConnection;76;2;69;0
WireConnection;76;3;75;0
WireConnection;108;0;107;0
WireConnection;108;1;33;0
WireConnection;34;0;9;0
WireConnection;34;1;24;1
WireConnection;131;0;113;0
WireConnection;131;1;132;0
WireConnection;112;0;239;0
WireConnection;79;1;205;0
WireConnection;79;2;114;0
WireConnection;30;0;108;0
WireConnection;30;1;34;0
WireConnection;64;0;76;0
WireConnection;64;1;65;0
WireConnection;64;2;74;1
WireConnection;15;0;131;0
WireConnection;15;1;14;0
WireConnection;102;0;80;0
WireConnection;155;0;64;0
WireConnection;151;0;15;0
WireConnection;211;0;116;0
WireConnection;211;1;210;0
WireConnection;157;0;30;0
WireConnection;81;1;79;0
WireConnection;81;2;102;0
WireConnection;115;0;81;0
WireConnection;115;1;211;0
WireConnection;153;0;115;0
WireConnection;106;1;158;0
WireConnection;105;1;156;0
WireConnection;104;1;152;0
WireConnection;126;1;140;0
WireConnection;43;0;104;0
WireConnection;43;1;105;0
WireConnection;43;2;106;0
WireConnection;103;1;154;0
WireConnection;127;0;43;0
WireConnection;127;1;126;0
WireConnection;218;0;109;2
WireConnection;246;0;218;0
WireConnection;219;0;246;0
WireConnection;148;0;162;2
WireConnection;147;0;162;3
WireConnection;176;0;184;0
WireConnection;184;0;194;0
WireConnection;184;1;189;0
WireConnection;185;0;186;0
WireConnection;185;1;172;0
WireConnection;186;0;175;0
WireConnection;190;0;176;0
WireConnection;190;1;166;0
WireConnection;194;0;159;0
WireConnection;194;1;167;0
WireConnection;146;0;162;4
WireConnection;128;0;103;0
WireConnection;128;1;127;0
WireConnection;238;0;247;0
WireConnection;247;0;109;2
WireConnection;0;13;128;0
ASEEND*/
//CHKSM=D29AA2BC150350AD8795915E12C76E0F65734334