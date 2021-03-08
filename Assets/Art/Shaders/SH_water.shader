// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "OSW/Water"
{
	Properties
	{
		_shallowcolour("shallow colour", Color) = (1,1,1,0)
		_deepcolour("deep colour", Color) = (0,0,0,0)
		_waterdepth("water depth", Range( 0 , 100)) = 75.8225
		_opacity("opacity", Range( 0 , 1)) = 1
		_foamdistance("foam distance", Range( 0 , 10)) = 1
		_foamcolour("foam colour", Color) = (0.8,0.8,0.8,1)
		_foamspeed("foam speed", Range( 0 , 1)) = 0.5
		_foamtiling("foam tiling", Float) = 1
		_foamnoiseamount("foam noise amount", Range( 0 , 1)) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Back
		GrabPass{ }
		CGINCLUDE
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
			float3 worldNormal;
			INTERNAL_DATA
			float4 screenPos;
			float2 uv_texcoord;
			float eyeDepth;
		};

		UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
		uniform float4 _CameraDepthTexture_TexelSize;
		uniform float _foamdistance;
		uniform float _foamtiling;
		uniform float _foamspeed;
		uniform float _foamnoiseamount;
		uniform float4 _foamcolour;
		uniform float4 _shallowcolour;
		uniform float4 _deepcolour;
		uniform float _waterdepth;
		uniform float _opacity;
		ASE_DECLARE_SCREENSPACE_TEXTURE( _GrabTexture )


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


		float3 PerturbNormal107_g4( float3 surf_pos, float3 surf_norm, float height, float scale )
		{
			// "Bump Mapping Unparametrized Surfaces on the GPU" by Morten S. Mikkelsen
			float3 vSigmaS = ddx( surf_pos );
			float3 vSigmaT = ddy( surf_pos );
			float3 vN = surf_norm;
			float3 vR1 = cross( vSigmaT , vN );
			float3 vR2 = cross( vN , vSigmaS );
			float fDet = dot( vSigmaS , vR1 );
			float dBs = ddx( height );
			float dBt = ddy( height );
			float3 vSurfGrad = scale * 0.05 * sign( fDet ) * ( dBs * vR1 + dBt * vR2 );
			return normalize ( abs( fDet ) * vN - vSurfGrad );
		}


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			o.eyeDepth = -UnityObjectToViewPos( v.vertex.xyz ).z;
		}

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float3 ase_worldPos = i.worldPos;
			float3 surf_pos107_g4 = ase_worldPos;
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 surf_norm107_g4 = ase_worldNormal;
			float4 ase_screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			float4 ase_screenPosNorm = ase_screenPos / ase_screenPos.w;
			ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
			float screenDepth97 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ase_screenPosNorm.xy ));
			float distanceDepth97 = abs( ( screenDepth97 - LinearEyeDepth( ase_screenPosNorm.z ) ) / ( 1.0 ) );
			float depth_raw65 = distanceDepth97;
			float mulTime70 = _Time.y * ( _foamspeed / 10.0 );
			float2 appendResult60 = (float2(i.uv_texcoord.x , ( ( _foamtiling * depth_raw65 ) - mulTime70 )));
			float simplePerlin2D90 = snoise( appendResult60*10.0 );
			simplePerlin2D90 = simplePerlin2D90*0.5 + 0.5;
			float lerpResult79 = lerp( 1.0 , simplePerlin2D90 , _foamnoiseamount);
			float clampResult50 = clamp( ( ( ( ( 1.0 - depth_raw65 ) - 1.0 ) + _foamdistance ) * lerpResult79 ) , 0.0 , 1.0 );
			float height107_g4 = clampResult50;
			float scale107_g4 = 0.5;
			float3 localPerturbNormal107_g4 = PerturbNormal107_g4( surf_pos107_g4 , surf_norm107_g4 , height107_g4 , scale107_g4 );
			float3 ase_worldTangent = WorldNormalVector( i, float3( 1, 0, 0 ) );
			float3 ase_worldBitangent = WorldNormalVector( i, float3( 0, 1, 0 ) );
			float3x3 ase_worldToTangent = float3x3( ase_worldTangent, ase_worldBitangent, ase_worldNormal );
			float3 worldToTangentDir42_g4 = mul( ase_worldToTangent, localPerturbNormal107_g4);
			float3 temp_output_109_40 = worldToTangentDir42_g4;
			o.Normal = temp_output_109_40;
			float foam_mask73 = round( clampResult50 );
			float clampResult89 = clamp( foam_mask73 , 0.0 , 1.0 );
			float4 lerpResult45 = lerp( float4( 0,0,0,0 ) , _foamcolour , clampResult89);
			o.Albedo = lerpResult45.rgb;
			float clampResult30 = clamp( (0.0 + (distanceDepth97 - 0.0) * (1.0 - 0.0) / (_waterdepth - 0.0)) , 0.0 , 1.0 );
			float depth_mapped61 = clampResult30;
			float4 lerpResult8 = lerp( _shallowcolour , _deepcolour , depth_mapped61);
			float clampResult77 = clamp( ( (0.0 + (depth_mapped61 - 0.0) * (1.0 - 0.0) / (0.1 - 0.0)) + _opacity ) , 0.0 , 1.0 );
			float4 lerpResult167 = lerp( float4( 1,1,1,0 ) , lerpResult8 , clampResult77);
			float eyeDepth28_g3 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ase_screenPosNorm.xy ));
			float2 temp_output_20_0_g3 = ( (temp_output_109_40).xy * ( 5.0 / max( i.eyeDepth , 0.1 ) ) * saturate( ( eyeDepth28_g3 - i.eyeDepth ) ) );
			float eyeDepth2_g3 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ( float4( temp_output_20_0_g3, 0.0 , 0.0 ) + ase_screenPosNorm ).xy ));
			float2 temp_output_32_0_g3 = (( float4( ( temp_output_20_0_g3 * saturate( ( eyeDepth2_g3 - i.eyeDepth ) ) ), 0.0 , 0.0 ) + ase_screenPosNorm )).xy;
			float2 temp_output_1_0_g3 = ( ( floor( ( temp_output_32_0_g3 * (_CameraDepthTexture_TexelSize).zw ) ) + 0.5 ) * (_CameraDepthTexture_TexelSize).xy );
			float4 screenColor159 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabTexture,temp_output_1_0_g3);
			o.Emission = ( lerpResult167 * screenColor159 ).rgb;
			o.Smoothness = 0.95;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma exclude_renderers vulkan xbox360 xboxone ps4 psp2 n3ds wiiu 
		#pragma surface surf Standard alpha:fade keepalpha fullforwardshadows exclude_path:deferred nodynlightmap nodirlightmap vertex:vertexDataFunc 

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
				float3 customPack1 : TEXCOORD1;
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
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				o.customPack1.z = customInputData.eyeDepth;
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
				surfIN.uv_texcoord = IN.customPack1.xy;
				surfIN.eyeDepth = IN.customPack1.z;
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
1920;0;1920;1019;59.06909;583.5505;1.401943;True;False
Node;AmplifyShaderEditor.CommentaryNode;95;-2725.376,-223.9258;Inherit;False;1069.856;492.7592;;6;31;37;30;61;65;97;DEPTH FADE;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;96;-2832.084,728.9548;Inherit;False;3097.174;803.4672;;21;73;47;50;134;79;142;143;90;80;44;60;140;58;66;102;70;82;67;59;101;57;FOAM;1,1,1,1;0;0
Node;AmplifyShaderEditor.DepthFade;97;-2643.446,-170.1244;Inherit;False;True;False;True;2;1;FLOAT3;0,0,0;False;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;65;-2319.878,-173.9258;Float;False;depth_raw;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;57;-2746.637,1394.733;Float;False;Property;_foamspeed;foam speed;6;0;Create;True;0;0;0;False;0;False;0.5;0.3;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;101;-2393.696,1200.23;Inherit;False;65;depth_raw;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;59;-2378.588,1081.385;Float;False;Property;_foamtiling;foam tiling;7;0;Create;True;0;0;0;False;0;False;1;0.2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;67;-2446.084,1386.955;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;10;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;70;-2190.084,1386.955;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;82;-2132.473,1126.935;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;58;-2149.408,934.635;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;66;-1585.815,802.0148;Inherit;False;65;depth_raw;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;102;-1974.04,1235.65;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;60;-1812.475,1062.935;Inherit;False;FLOAT2;4;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.OneMinusNode;140;-1370.674,806.4294;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;31;-2702.676,145.7434;Float;False;Property;_waterdepth;water depth;2;0;Create;True;0;0;0;False;0;False;75.8225;25;0;100;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;37;-2299.099,70.67767;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;10;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;90;-1594.815,1080.06;Inherit;True;Simplex2D;True;False;2;0;FLOAT2;5,5;False;1;FLOAT;10;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;80;-1419.246,1329.077;Float;False;Property;_foamnoiseamount;foam noise amount;8;0;Create;True;0;0;0;False;0;False;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;143;-1126.298,824.9965;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;44;-1457.206,946.6396;Float;False;Property;_foamdistance;foam distance;4;0;Create;True;0;0;0;False;0;False;1;1;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;79;-927.4956,1068.101;Inherit;False;3;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;30;-2104.438,-17.27121;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;142;-956.1581,957.8363;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;168;-1360.108,-606.28;Inherit;False;2234.477;692.0001;;12;169;159;167;8;77;160;7;76;5;171;40;63;REFRACTION;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;134;-533.7347,945.7651;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;61;-1880.52,-2.01013;Float;False;depth_mapped;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;63;-1310.108,-165.0353;Inherit;False;61;depth_mapped;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;50;-360.7703,932.9799;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;40;-1089.354,-14.91056;Float;False;Property;_opacity;opacity;3;0;Create;True;0;0;0;False;0;False;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;171;-988.9503,-195.7118;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RoundOpNode;47;-126.9586,925.6012;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;174;179.9292,-1295.849;Inherit;False;741.72;627.8366;;4;75;46;89;45;ALBEDO;1,1,1,1;0;0
Node;AmplifyShaderEditor.ColorNode;5;-1279.936,-556.28;Float;False;Property;_shallowcolour;shallow colour;0;0;Create;True;0;0;0;False;0;False;1,1,1,0;0.6078431,0.8,0.6,1;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;7;-1277.578,-361.0576;Float;False;Property;_deepcolour;deep colour;1;0;Create;True;0;0;0;False;0;False;0,0,0,0;0.1490195,0.2980392,0.1642256,1;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;109;-200.6842,475.8044;Inherit;False;Normal From Height;-1;;4;1942fe2c5f1a1f94881a33d532e4afeb;0;2;20;FLOAT;0;False;110;FLOAT;0.5;False;2;FLOAT3;40;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;76;-756.5706,-191.6485;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;73;54.17426,926.1697;Float;False;foam_mask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;160;38.36607,-108.6842;Inherit;False;DepthMaskedRefraction;-1;;3;c805f061214177c42bca056464193f81;2,40,0,103,0;2;35;FLOAT3;0,0,0;False;37;FLOAT;5;False;1;FLOAT2;38
Node;AmplifyShaderEditor.ClampOpNode;77;-562.391,-214.9873;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;8;-940.9485,-372.7544;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;75;229.9292,-833.2335;Inherit;False;73;foam_mask;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;89;469.0689,-827.0121;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;167;-396.0092,-396.3362;Inherit;False;3;0;COLOR;1,1,1,0;False;1;COLOR;1,1,1,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ScreenColorNode;159;420.0952,-183.6964;Inherit;False;Global;_GrabScreen0;Grab Screen 0;10;0;Create;True;0;0;0;False;0;False;Object;-1;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;46;388.948,-1245.849;Float;False;Property;_foamcolour;foam colour;5;0;Create;True;0;0;0;False;0;False;0.8,0.8,0.8,1;0.8,0.8,0.8,1;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NormalVertexDataNode;172;-233.11,258.6819;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RefractOpVec;173;270.8901,204.282;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;108;942.2869,117.8557;Inherit;False;Constant;_Gloss;Gloss;11;0;Create;True;0;0;0;False;0;False;0.95;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;169;687.1685,-381.059;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;166;931.7685,354.3037;Inherit;False;Property;_Refraction;Refraction;9;0;Create;True;0;0;0;False;0;False;1;0.48;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;45;739.6492,-1080.753;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1849.317,-3.040045;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;OSW/Water;False;False;False;False;False;False;False;True;True;False;False;False;False;False;True;False;False;False;False;False;False;Back;1;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Transparent;0.5;True;True;0;False;Transparent;;Transparent;ForwardOnly;7;d3d9;d3d11_9x;d3d11;glcore;gles;gles3;metal;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;2;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;3;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;65;0;97;0
WireConnection;67;0;57;0
WireConnection;70;0;67;0
WireConnection;82;0;59;0
WireConnection;82;1;101;0
WireConnection;102;0;82;0
WireConnection;102;1;70;0
WireConnection;60;0;58;1
WireConnection;60;1;102;0
WireConnection;140;0;66;0
WireConnection;37;0;97;0
WireConnection;37;2;31;0
WireConnection;90;0;60;0
WireConnection;143;0;140;0
WireConnection;79;1;90;0
WireConnection;79;2;80;0
WireConnection;30;0;37;0
WireConnection;142;0;143;0
WireConnection;142;1;44;0
WireConnection;134;0;142;0
WireConnection;134;1;79;0
WireConnection;61;0;30;0
WireConnection;50;0;134;0
WireConnection;171;0;63;0
WireConnection;47;0;50;0
WireConnection;109;20;50;0
WireConnection;76;0;171;0
WireConnection;76;1;40;0
WireConnection;73;0;47;0
WireConnection;160;35;109;40
WireConnection;77;0;76;0
WireConnection;8;0;5;0
WireConnection;8;1;7;0
WireConnection;8;2;63;0
WireConnection;89;0;75;0
WireConnection;167;1;8;0
WireConnection;167;2;77;0
WireConnection;159;0;160;38
WireConnection;169;0;167;0
WireConnection;169;1;159;0
WireConnection;45;1;46;0
WireConnection;45;2;89;0
WireConnection;0;0;45;0
WireConnection;0;1;109;40
WireConnection;0;2;169;0
WireConnection;0;4;108;0
ASEEND*/
//CHKSM=650421DCFF596D8E1E8457AC0FC027B1E4B88542