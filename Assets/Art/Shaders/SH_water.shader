// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "OSW/Water"
{
	Properties
	{
		_shallowcolour("shallow colour", Color) = (1,1,1,0)
		_shorecolour("shore colour", Color) = (1,1,1,0)
		_deepcolour("deep colour", Color) = (0,0,0,0)
		_waterdepth("water depth", Range( 0 , 100)) = 75.8225
		_shallowsopacity("shallows opacity", Range( 0 , 1)) = 1
		_foamdistance("foam distance", Range( 0 , 10)) = 1
		_foamcolour("foam colour", Color) = (0.8,0.8,0.8,1)
		_foamspeed("foam speed", Range( 0 , 1)) = 0.5
		_foamtilingY("foam tiling Y", Float) = 1
		_foamtilingX("foam tiling X", Float) = 1
		_foamnoiseamount("foam noise amount", Range( 0 , 1)) = 0
		_refractionIOR("refraction IOR", Range( -5 , 5)) = 1
		[NoScaleOffset][Normal]_wavesnormal("waves normal", 2D) = "bump" {}
		_wavenormaltile("wave normal tile", Range( 0 , 100)) = 0
		_wavenormalstrength("wave normal strength", Range( 0 , 1)) = 1
		_refractionopacity("refraction opacity", Range( 0 , 1)) = 1
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Back
		GrabPass{ }
		CGINCLUDE
		#include "UnityStandardUtils.cginc"
		#include "UnityCG.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
		#define ASE_DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex);
		#else
		#define ASE_DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex)
		#endif
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
			float3 worldPos;
			float4 screenPos;
			float3 worldNormal;
			INTERNAL_DATA
			float eyeDepth;
		};

		uniform sampler2D _wavesnormal;
		uniform float _wavenormaltile;
		uniform float _wavenormalstrength;
		uniform float4 _foamcolour;
		UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
		uniform float4 _CameraDepthTexture_TexelSize;
		uniform float _foamdistance;
		uniform float _foamtilingX;
		uniform float _foamtilingY;
		uniform float _foamspeed;
		uniform float _foamnoiseamount;
		uniform float4 _shorecolour;
		uniform float4 _shallowcolour;
		uniform float4 _deepcolour;
		uniform float _refractionIOR;
		uniform float _waterdepth;
		uniform float _shallowsopacity;
		ASE_DECLARE_SCREENSPACE_TEXTURE( _GrabTexture )
		uniform float _refractionopacity;


		float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }

		float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }

		float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }

		float snoise( float2 v )
		{
			const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
			float2 i = floor( v + dot( v, C.yy ) );
			float2 x0 = v - i + dot( i, C.xx );
			float2 i1;
			i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
			float4 x12 = x0.xyxy + C.xxzz;
			x12.xy -= i1;
			i = mod2D289( i );
			float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
			float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
			m = m * m;
			m = m * m;
			float3 x = 2.0 * frac( p * C.www ) - 1.0;
			float3 h = abs( x ) - 0.5;
			float3 ox = floor( x + 0.5 );
			float3 a0 = x - ox;
			m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
			float3 g;
			g.x = a0.x * x0.x + h.x * x0.y;
			g.yz = a0.yz * x12.xz + h.yz * x12.yw;
			return 130.0 * dot( m, g );
		}


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			o.eyeDepth = -UnityObjectToViewPos( v.vertex.xyz ).z;
		}

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float3 ase_worldPos = i.worldPos;
			float2 appendResult205 = (float2(ase_worldPos.x , ase_worldPos.z));
			float2 temp_output_207_0 = ( appendResult205 * float2( 0.01,0.01 ) );
			float2 temp_output_206_0 = ( _wavenormaltile * temp_output_207_0 );
			o.Normal = UnpackScaleNormal( tex2D( _wavesnormal, temp_output_206_0 ), ( _wavenormalstrength * 0.025 ) );
			float4 ase_screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			float4 ase_screenPosNorm = ase_screenPos / ase_screenPos.w;
			ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
			float screenDepth97 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ase_screenPosNorm.xy ));
			float distanceDepth97 = abs( ( screenDepth97 - LinearEyeDepth( ase_screenPosNorm.z ) ) / ( 1.0 ) );
			float depth_raw65 = distanceDepth97;
			float2 worldUV209 = temp_output_207_0;
			float mulTime70 = _Time.y * ( _foamspeed / 10.0 );
			float2 appendResult60 = (float2(( _foamtilingX * (worldUV209).x ) , ( ( _foamtilingY * depth_raw65 ) - mulTime70 )));
			float simplePerlin2D90 = snoise( appendResult60*50.0 );
			simplePerlin2D90 = simplePerlin2D90*0.5 + 0.5;
			float lerpResult79 = lerp( 1.0 , simplePerlin2D90 , _foamnoiseamount);
			float foam_mask73 = (0.0 + (( ( ( ( 1.0 - depth_raw65 ) - 1.0 ) + _foamdistance ) * lerpResult79 ) - 0.7) * (1.0 - 0.0) / (1.0 - 0.7));
			float clampResult89 = clamp( foam_mask73 , 0.0 , 1.0 );
			float4 lerpResult45 = lerp( float4( 0,0,0,0 ) , _foamcolour , clampResult89);
			o.Albedo = lerpResult45.rgb;
			float3 normals212 = UnpackScaleNormal( tex2D( _wavesnormal, temp_output_206_0 ), _wavenormalstrength );
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float eyeDepth28_g5 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ase_screenPosNorm.xy ));
			float2 temp_output_20_0_g5 = ( (BlendNormals( normals212 , ase_worldNormal )).xy * ( _refractionIOR / max( i.eyeDepth , 0.1 ) ) * saturate( ( eyeDepth28_g5 - i.eyeDepth ) ) );
			float eyeDepth2_g5 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ( float4( temp_output_20_0_g5, 0.0 , 0.0 ) + ase_screenPosNorm ).xy ));
			float2 temp_output_32_0_g5 = (( float4( ( temp_output_20_0_g5 * saturate( ( eyeDepth2_g5 - i.eyeDepth ) ) ), 0.0 , 0.0 ) + ase_screenPosNorm )).xy;
			float2 temp_output_1_0_g5 = ( ( floor( ( temp_output_32_0_g5 * (_CameraDepthTexture_TexelSize).zw ) ) + 0.5 ) * (_CameraDepthTexture_TexelSize).xy );
			float2 temp_output_160_38 = temp_output_1_0_g5;
			float2 refractionUV219 = temp_output_160_38;
			float eyeDepth216 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, float4( refractionUV219, 0.0 , 0.0 ).xy ));
			float clampResult30 = clamp( (0.0 + (( eyeDepth216 - i.eyeDepth ) - 0.0) * (1.0 - 0.0) / (_waterdepth - 0.0)) , 0.0 , 1.0 );
			float depth_refracted61 = clampResult30;
			float4 lerpResult8 = lerp( _shallowcolour , _deepcolour , depth_refracted61);
			float clampResult77 = clamp( ( (0.0 + (depth_refracted61 - 0.0) * (1.0 - 0.0) / (0.1 - 0.0)) + _shallowsopacity ) , 0.0 , 1.0 );
			float4 lerpResult167 = lerp( _shorecolour , lerpResult8 , clampResult77);
			float4 screenColor159 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabTexture,temp_output_160_38);
			float4 blendOpSrc232 = lerpResult167;
			float4 blendOpDest232 = screenColor159;
			float4 lerpResult228 = lerp( lerpResult167 , ( saturate( 2.0f*blendOpDest232*blendOpSrc232 + blendOpDest232*blendOpDest232*(1.0f - 2.0f*blendOpSrc232) )) , _refractionopacity);
			o.Emission = lerpResult228.rgb;
			o.Smoothness = 0.975;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma only_renderers d3d9 d3d11_9x d3d11 glcore gles gles3 
		#pragma surface surf Standard alpha:fade keepalpha fullforwardshadows exclude_path:deferred nolightmap  nodynlightmap nodirlightmap vertex:vertexDataFunc 

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
				float1 customPack1 : TEXCOORD1;
				float4 screenPos : TEXCOORD2;
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
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
				o.customPack1.x = customInputData.eyeDepth;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				o.screenPos = ComputeScreenPos( o.pos );
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
				surfIN.eyeDepth = IN.customPack1.x;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				surfIN.screenPos = IN.screenPos;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
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
1920;0;1920;1019;1436.15;-432.0212;1;True;False
Node;AmplifyShaderEditor.CommentaryNode;195;354.1393,310.8446;Inherit;False;1764.266;647.7748;;13;202;194;192;206;197;209;207;205;204;212;214;225;227;NORMALS;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldPosInputsNode;204;392.3276,768.4167;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;205;585.3766,791.7665;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;197;400.0498,672.1943;Inherit;False;Property;_wavenormaltile;wave normal tile;13;0;Create;True;0;0;0;False;0;False;0;0;0;100;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;207;776.2345,798.7227;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0.01,0.01;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;214;692.045,545.6073;Inherit;False;Property;_wavenormalstrength;wave normal strength;14;0;Create;True;0;0;0;False;0;False;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;192;400.6848,366.1265;Inherit;True;Property;_wavesnormal;waves normal;12;2;[NoScaleOffset];[Normal];Create;True;0;0;0;False;0;False;b8b43c26acee0b94f9fae5c1dbb29d55;b8b43c26acee0b94f9fae5c1dbb29d55;True;bump;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;206;1045.493,701.062;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;225;1219.118,366.0264;Inherit;True;Property;_TextureSample0;Texture Sample 0;12;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;212;1611.976,373.3975;Inherit;False;normals;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;168;-1381.137,-606.28;Inherit;False;2255.505;769.107;;22;76;171;40;167;77;8;169;159;160;7;5;63;184;200;213;219;223;224;228;229;231;232;REFRACTION;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;213;-795.8409,-109.7637;Inherit;False;212;normals;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldNormalVector;224;-827.0413,-24.44298;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.BlendNormalsNode;223;-598.6272,-114.3029;Inherit;False;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;184;-614.1791,26.02627;Inherit;False;Property;_refractionIOR;refraction IOR;11;0;Create;True;0;0;0;False;0;False;1;1;-5;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;160;-356.1263,-158.0148;Inherit;False;DepthMaskedRefraction;-1;;5;c805f061214177c42bca056464193f81;2,40,0,103,0;2;35;FLOAT3;0,0,0;False;37;FLOAT;5;False;1;FLOAT2;38
Node;AmplifyShaderEditor.CommentaryNode;95;-2894.696,-223.9258;Inherit;False;1239.176;493.7792;;10;218;217;216;61;65;30;37;31;97;220;DEPTH FADE;1,1,1,1;0;0
Node;AmplifyShaderEditor.DepthFade;97;-2643.446,-170.1244;Inherit;False;True;False;True;2;1;FLOAT3;0,0,0;False;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;96;-2832.084,728.9548;Inherit;False;3097.174;803.4672;;24;73;134;79;142;143;90;80;44;60;140;66;102;70;82;67;59;101;57;191;210;211;221;222;236;FOAM;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;219;91.50146,66.38379;Inherit;False;refractionUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;57;-2746.637,1394.733;Float;False;Property;_foamspeed;foam speed;7;0;Create;True;0;0;0;False;0;False;0.5;0.3;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;209;1156.969,864.1328;Inherit;False;worldUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;218;-2873.869,-58.5558;Inherit;False;219;refractionUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;65;-2319.878,-177.0158;Float;False;depth_raw;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SurfaceDepthNode;217;-2741.55,30.08428;Inherit;False;0;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;101;-2393.696,1200.23;Inherit;False;65;depth_raw;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;210;-2506.848,920.7383;Inherit;False;209;worldUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;59;-2545.667,1103.665;Float;False;Property;_foamtilingY;foam tiling Y;8;0;Create;True;0;0;0;False;0;False;1;0.2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenDepthNode;216;-2652.869,-51.73572;Inherit;False;0;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;67;-2446.084,1386.955;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;10;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;220;-2463.6,-21.25139;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;82;-2132.473,1126.935;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;70;-2190.084,1386.955;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;222;-2562.254,807.8076;Float;False;Property;_foamtilingX;foam tiling X;9;0;Create;True;0;0;0;False;0;False;1;0.2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;211;-2310.226,920.7679;Inherit;False;True;False;True;True;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;31;-2702.676,145.7434;Float;False;Property;_waterdepth;water depth;3;0;Create;True;0;0;0;False;0;False;75.8225;25;0;100;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;221;-2092.899,831.0775;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;66;-1585.815,802.0148;Inherit;False;65;depth_raw;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;37;-2299.099,70.67767;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;10;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;102;-1974.04,1235.65;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;140;-1370.674,806.4294;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;60;-1812.475,1062.935;Inherit;False;FLOAT2;4;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ClampOpNode;30;-2104.438,-17.27121;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;44;-1457.206,946.6396;Float;False;Property;_foamdistance;foam distance;5;0;Create;True;0;0;0;False;0;False;1;1;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;80;-1324.342,1334.207;Float;False;Property;_foamnoiseamount;foam noise amount;10;0;Create;True;0;0;0;False;0;False;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;90;-1584.435,1082.58;Inherit;True;Simplex2D;True;False;2;0;FLOAT2;5,5;False;1;FLOAT;50;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;61;-1891.27,-25.76024;Float;False;depth_refracted;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;143;-1126.298,824.9965;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;142;-956.1581,957.8363;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;79;-927.4956,1068.101;Inherit;False;3;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;63;-1310.108,-166.5453;Inherit;False;61;depth_refracted;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;171;-989.8171,-235.3837;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;134;-533.7347,945.7651;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;40;-1119.605,-31.08916;Float;False;Property;_shallowsopacity;shallows opacity;4;0;Create;True;0;0;0;False;0;False;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;76;-764.9821,-258.9415;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;236;-295.1501,939.0212;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0.7;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;7;-1277.578,-361.0576;Float;False;Property;_deepcolour;deep colour;2;0;Create;True;0;0;0;False;0;False;0,0,0,0;0.1490195,0.2980391,0.1642255,1;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;5;-1279.936,-556.28;Float;False;Property;_shallowcolour;shallow colour;0;0;Create;True;0;0;0;False;0;False;1,1,1,0;0.6078431,0.8,0.6,1;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;174;179.9292,-1295.849;Inherit;False;741.72;627.8366;;4;75;46;89;45;ALBEDO;1,1,1,1;0;0
Node;AmplifyShaderEditor.ClampOpNode;77;-607.2527,-363.5933;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;73;54.17426,926.1697;Float;False;foam_mask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;8;-941.1351,-438.968;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;231;-711.6328,-552.5031;Float;False;Property;_shorecolour;shore colour;1;0;Create;True;0;0;0;False;0;False;1,1,1,0;0.6078431,0.8,0.6,1;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;75;229.9292,-833.2335;Inherit;False;73;foam_mask;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;159;51.64902,-306.9515;Inherit;False;Global;_GrabScreen0;Grab Screen 0;10;0;Create;True;0;0;0;False;0;False;Object;-1;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;167;-395.8715,-482.942;Inherit;False;3;0;COLOR;1,1,1,0;False;1;COLOR;1,1,1,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClampOpNode;89;469.0689,-827.0121;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.BlendOpsNode;232;309.638,-511.1729;Inherit;False;SoftLight;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;227;1042.694,579.0358;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.025;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;46;388.948,-1245.849;Float;False;Property;_foamcolour;foam colour;6;0;Create;True;0;0;0;False;0;False;0.8,0.8,0.8,1;0.8,0.8,0.8,1;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;229;242.4024,-146.5085;Inherit;False;Property;_refractionopacity;refraction opacity;15;0;Create;True;0;0;0;False;0;False;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;194;440.184,576.4446;Inherit;False;191;shoreUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;108;1480.148,97.5157;Inherit;False;Constant;_Gloss;Gloss;11;0;Create;True;0;0;0;False;0;False;0.975;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;191;-1638.587,1332.591;Inherit;False;shoreUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;202;1451.683,597.7758;Inherit;True;Property;_TextureSample1;Texture Sample 1;12;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;228;543.9728,-447.7593;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;169;295.2557,-326.7288;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;45;739.6492,-1080.753;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;200;-400.1417,-353.0002;Inherit;False;depthShallows;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;2203.103,-11.22004;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;OSW/Water;False;False;False;False;False;False;True;True;True;False;False;False;False;False;True;False;False;False;False;False;False;Back;1;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Transparent;0.5;True;True;0;False;Transparent;;Transparent;ForwardOnly;6;d3d9;d3d11_9x;d3d11;glcore;gles;gles3;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;2;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;205;0;204;1
WireConnection;205;1;204;3
WireConnection;207;0;205;0
WireConnection;206;0;197;0
WireConnection;206;1;207;0
WireConnection;225;0;192;0
WireConnection;225;1;206;0
WireConnection;225;5;214;0
WireConnection;212;0;225;0
WireConnection;223;0;213;0
WireConnection;223;1;224;0
WireConnection;160;35;223;0
WireConnection;160;37;184;0
WireConnection;219;0;160;38
WireConnection;209;0;207;0
WireConnection;65;0;97;0
WireConnection;216;0;218;0
WireConnection;67;0;57;0
WireConnection;220;0;216;0
WireConnection;220;1;217;0
WireConnection;82;0;59;0
WireConnection;82;1;101;0
WireConnection;70;0;67;0
WireConnection;211;0;210;0
WireConnection;221;0;222;0
WireConnection;221;1;211;0
WireConnection;37;0;220;0
WireConnection;37;2;31;0
WireConnection;102;0;82;0
WireConnection;102;1;70;0
WireConnection;140;0;66;0
WireConnection;60;0;221;0
WireConnection;60;1;102;0
WireConnection;30;0;37;0
WireConnection;90;0;60;0
WireConnection;61;0;30;0
WireConnection;143;0;140;0
WireConnection;142;0;143;0
WireConnection;142;1;44;0
WireConnection;79;1;90;0
WireConnection;79;2;80;0
WireConnection;171;0;63;0
WireConnection;134;0;142;0
WireConnection;134;1;79;0
WireConnection;76;0;171;0
WireConnection;76;1;40;0
WireConnection;236;0;134;0
WireConnection;77;0;76;0
WireConnection;73;0;236;0
WireConnection;8;0;5;0
WireConnection;8;1;7;0
WireConnection;8;2;63;0
WireConnection;159;0;160;38
WireConnection;167;0;231;0
WireConnection;167;1;8;0
WireConnection;167;2;77;0
WireConnection;89;0;75;0
WireConnection;232;0;167;0
WireConnection;232;1;159;0
WireConnection;227;0;214;0
WireConnection;191;0;60;0
WireConnection;202;0;192;0
WireConnection;202;1;206;0
WireConnection;202;5;227;0
WireConnection;228;0;167;0
WireConnection;228;1;232;0
WireConnection;228;2;229;0
WireConnection;169;0;167;0
WireConnection;169;1;159;0
WireConnection;45;1;46;0
WireConnection;45;2;89;0
WireConnection;200;0;77;0
WireConnection;0;0;45;0
WireConnection;0;1;202;0
WireConnection;0;2;228;0
WireConnection;0;4;108;0
ASEEND*/
//CHKSM=8A409999647B7D7DABF3B33EEDBD924860479F30