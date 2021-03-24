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
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
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
			float4 vertexColor : COLOR;
			float3 worldPos;
			float2 uv_texcoord;
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
		uniform half _IndirectToggle;
		uniform sampler2D _Albedo;
		uniform half4 _Albedo_ST;
		uniform half _FresnelToggle;
		uniform half _LightFresnel;
		uniform half _LightFresnelPower;
		uniform half _LightingToggle;
		uniform half _CustomLightFalloffToggle;
		uniform half _lightwrapscale;
		uniform half _lightwrapoffset;
		uniform half _AlbedoToggle;

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
			half globalIllumination110 = i.vertexColor.r;
			Unity_GlossyEnvironmentData g79 = UnityGlossyEnvironmentSetup( _Gloss, data.worldViewDir, ase_worldNormal, float3(0,0,0));
			half3 indirectSpecular79 = UnityGI_IndirectSpecular( data, globalIllumination110, ase_worldNormal, g79 );
			float3 ase_worldPos = i.worldPos;
			half3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			half fresnelNdotV80 = dot( ase_worldNormal, ase_worldViewDir );
			half ior80 = 1.6;
			ior80 = pow( ( 1 - ior80 ) / ( 1 + ior80 ), 2 );
			half fresnelNode80 = ( ior80 + ( 1.0 - ior80 ) * pow( 1.0 - fresnelNdotV80, 5 ) );
			half clampResult102 = clamp( fresnelNode80 , 0.0 , 1.0 );
			half3 lerpResult81 = lerp( float3( 0,0,0 ) , indirectSpecular79 , clampResult102);
			half heightGradient112 = i.vertexColor.b;
			half3 reflection153 = ( lerpResult81 * heightGradient112 );
			float2 uv_Albedo = i.uv_texcoord * _Albedo_ST.xy + _Albedo_ST.zw;
			half4 tex2DNode120 = tex2D( _Albedo, uv_Albedo );
			half thickness111 = i.vertexColor.g;
			half4 albedo129 = saturate( ( tex2DNode120 + ( tex2DNode120 * thickness111 ) ) );
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
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
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
				surfIN.uv_texcoord = IN.customPack1.xy;
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
1920;0;1920;1019;2183.865;313.4651;1.594999;True;False
Node;AmplifyShaderEditor.VertexColorNode;109;-1837.267,-875.4458;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;119;-412.7112,1018.264;Inherit;False;1341.98;536.6354;;6;134;129;136;135;141;120;ALBEDO;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;111;-1586.107,-837.0506;Inherit;False;thickness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;134;-353.1555,1275.97;Inherit;False;111;thickness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;120;-393.5419,1077.665;Inherit;True;Property;_Albedo;Albedo;10;0;Create;True;0;0;0;False;0;False;-1;None;4b47542f94d80e84fbf0f9cda3727ed6;True;0;False;gray;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;141;26.85103,1196.343;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;135;200.1195,1118.884;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CommentaryNode;98;-2191.043,429.1801;Inherit;False;1712.387;966.6977;;14;30;34;108;33;9;107;24;19;12;7;20;6;5;157;LIGHTING;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;6;-2141.043,843.3811;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SaturateNode;136;376.7295,1128.768;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WorldNormalVector;5;-2116.713,668.7105;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CommentaryNode;99;-1000.852,-634.1455;Inherit;False;1256.287;399.0397;;8;15;131;14;132;113;133;130;151;INDIRECT;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;20;-1865.783,1094.233;Inherit;False;Property;_lightwrapoffset;light wrap offset;1;0;Create;True;0;0;0;False;0;False;0;0.25;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;7;-1843.632,773.8607;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;12;-1878.607,978.1422;Inherit;False;Property;_lightwrapscale;light wrap scale;0;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;129;578.0797,1117.705;Inherit;False;albedo;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;133;-897.6968,-350.9792;Inherit;False;Constant;_Float4;Float 4;15;0;Create;True;0;0;0;False;0;False;4;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;130;-908.2126,-446.9914;Inherit;False;129;albedo;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;19;-1542.755,847.9583;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.5;False;2;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;110;-1581.622,-926.2756;Inherit;False;globalIllumination;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;97;-2238.206,-510.6443;Inherit;False;1157.633;784.1101;;7;75;69;65;74;76;64;155;FRESNEL;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;69;-2214.206,-308.5344;Inherit;False;Property;_LightFresnel;Light Fresnel;2;0;Create;True;0;0;0;False;0;False;3.60606;1;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.LightColorNode;24;-1380.497,1153.389;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.CommentaryNode;100;-1109.84,-1173.591;Inherit;False;1307.544;395.0966;;9;153;115;116;81;102;79;114;143;80;REFLECTION;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;75;-2208.206,-100.5343;Inherit;False;Property;_LightFresnelPower;Light Fresnel Power;3;0;Create;True;0;0;0;False;0;False;4.323316;2;0.01;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;113;-956.477,-564.3163;Inherit;False;110;globalIllumination;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;107;-1461.749,625.5537;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;132;-641.6968,-426.9792;Inherit;False;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LightAttenuation;9;-1406.055,1029.337;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;33;-1346.816,863.8928;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LightColorNode;74;-2001.706,137.8661;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;34;-1119.351,1064.393;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;114;-1083.201,-1005.511;Inherit;False;110;globalIllumination;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;131;-437.8944,-515.7396;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LightAttenuation;65;-2028.206,50.46609;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;143;-1097.34,-1098.082;Inherit;False;Property;_Gloss;Gloss;11;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;108;-1184.547,728.5142;Inherit;False;Property;_CustomLightFalloffToggle;Custom Light Falloff Toggle;9;0;Create;True;0;0;0;False;0;False;1;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;80;-924.2018,-919.559;Inherit;False;SchlickIOR;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1.6;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.IndirectDiffuseLighting;14;-547.5056,-320.1958;Inherit;False;Tangent;1;0;FLOAT3;0,0,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FresnelNode;76;-1837.711,-218.4337;Inherit;False;Standard;WorldNormal;ViewDir;True;True;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;3;False;3;FLOAT;3;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;112;-1577.137,-746.8757;Inherit;False;heightGradient;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;30;-874.7369,779.7221;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.IndirectSpecularLight;79;-818.6544,-1123.591;Inherit;False;Tangent;3;0;FLOAT3;0,0,1;False;1;FLOAT;0.25;False;2;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;15;-256.2658,-461.2412;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClampOpNode;102;-674.6061,-914.4741;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;64;-1572.101,5.626102;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;157;-721.2493,777.5148;Inherit;False;Lighting;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;81;-509.4667,-1066.735;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;155;-1335.324,21.48608;Inherit;False;Fresnel;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;116;-493.2508,-901.9832;Inherit;False;112;heightGradient;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;151;-91.26526,-515.8774;Inherit;False;Indirect;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;115;-194.8653,-1050.739;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;156;-51.34976,128.3505;Inherit;False;155;Fresnel;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;152;-81.21483,-27.44731;Inherit;False;151;Indirect;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;158;-70.49023,270.3047;Inherit;False;157;Lighting;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ToggleSwitchNode;106;152.2288,248.9953;Inherit;False;Property;_LightingToggle;Lighting Toggle;7;0;Create;True;0;0;0;False;0;False;1;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ToggleSwitchNode;105;150.1667,98.51608;Inherit;False;Property;_FresnelToggle;Fresnel Toggle;6;0;Create;True;0;0;0;False;0;False;1;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;153;-43.37442,-1050.352;Inherit;False;reflection;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;140;-97.73383,432.0466;Inherit;False;129;albedo;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.ToggleSwitchNode;104;131.583,-50.03011;Inherit;False;Property;_IndirectToggle;Indirect Toggle;5;0;Create;True;0;0;0;False;0;False;1;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ToggleSwitchNode;126;137.4853,399.7006;Inherit;False;Property;_AlbedoToggle;Albedo Toggle;8;0;Create;True;0;0;0;False;0;False;1;2;0;COLOR;1,1,1,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;154;-92.81944,-152.3679;Inherit;False;153;reflection;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;43;419.3621,102.5561;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;127;576.1302,169.95;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ToggleSwitchNode;103;124.4125,-181.5562;Inherit;False;Property;_ReflectionToggle;Reflection Toggle;4;0;Create;True;0;0;0;False;0;False;1;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;149;-1577.155,-1341.706;Inherit;False;DetailPattern_R;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;145;-2178.755,-1265.62;Inherit;True;Property;_DetailMask1;Detail Mask;12;0;Create;True;0;0;0;False;0;False;95fb59503f3acf040b94dae940963d73;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SamplerNode;144;-1917.741,-1264.08;Inherit;True;Property;_TextureSample1;Texture Sample 0;11;0;Create;True;0;0;0;False;0;False;-1;95fb59503f3acf040b94dae940963d73;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;128;735.9974,61.66408;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;147;-1578.38,-1175.231;Inherit;False;DetailPattern_B;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;148;-1576.21,-1257.681;Inherit;False;DetailPattern_G;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;146;-1583.555,-1094.466;Inherit;False;DetailPattern_A;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;965.2651,-126.375;Half;False;True;-1;2;ASEMaterialInspector;0;0;CustomLighting;SH_Form;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;111;0;109;2
WireConnection;141;0;120;0
WireConnection;141;1;134;0
WireConnection;135;0;120;0
WireConnection;135;1;141;0
WireConnection;136;0;135;0
WireConnection;7;0;5;0
WireConnection;7;1;6;0
WireConnection;129;0;136;0
WireConnection;19;0;7;0
WireConnection;19;1;12;0
WireConnection;19;2;20;0
WireConnection;110;0;109;1
WireConnection;107;0;7;0
WireConnection;132;0;130;0
WireConnection;132;1;133;0
WireConnection;33;0;19;0
WireConnection;34;0;9;0
WireConnection;34;1;24;1
WireConnection;131;0;113;0
WireConnection;131;1;132;0
WireConnection;108;0;107;0
WireConnection;108;1;33;0
WireConnection;76;2;69;0
WireConnection;76;3;75;0
WireConnection;112;0;109;3
WireConnection;30;0;108;0
WireConnection;30;1;34;0
WireConnection;79;1;143;0
WireConnection;79;2;114;0
WireConnection;15;0;131;0
WireConnection;15;1;14;0
WireConnection;102;0;80;0
WireConnection;64;0;76;0
WireConnection;64;1;65;0
WireConnection;64;2;74;1
WireConnection;157;0;30;0
WireConnection;81;1;79;0
WireConnection;81;2;102;0
WireConnection;155;0;64;0
WireConnection;151;0;15;0
WireConnection;115;0;81;0
WireConnection;115;1;116;0
WireConnection;106;1;158;0
WireConnection;105;1;156;0
WireConnection;153;0;115;0
WireConnection;104;1;152;0
WireConnection;126;1;140;0
WireConnection;43;0;104;0
WireConnection;43;1;105;0
WireConnection;43;2;106;0
WireConnection;127;0;43;0
WireConnection;127;1;126;0
WireConnection;103;1;154;0
WireConnection;149;0;144;1
WireConnection;144;0;145;0
WireConnection;128;0;103;0
WireConnection;128;1;127;0
WireConnection;147;0;144;3
WireConnection;148;0;144;2
WireConnection;146;0;144;4
WireConnection;0;13;128;0
ASEEND*/
//CHKSM=A2D6DEE573197E88F463068C61CB42EF0D9BC540