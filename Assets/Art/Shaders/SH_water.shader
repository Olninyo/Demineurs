// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "OSW/Water"
{
	Properties
	{
		_TessValue( "Max Tessellation", Range( 1, 32 ) ) = 8
		_TessMin( "Tess Min Distance", Float ) = 10
		_TessMax( "Tess Max Distance", Float ) = 50
		[Header(Colour)]_foamcolour("foam colour", Color) = (0.8,0.8,0.8,1)
		_shallowcolour("shallow colour", Color) = (1,1,1,0)
		_deepcolour("deep colour", Color) = (0,0,0,0)
		[Header(Scattering)]_scatteringdepth("scattering depth", Range( 0 , 100)) = 75.8225
		_scatteringfalloff("scattering falloff", Range( 0 , 10)) = 5
		[Header(Foam)]_foamdistance("foam distance", Range( 0 , 10)) = 1
		_speed("speed", Range( 0 , 1)) = 0.5
		_foamtilingY("foam tiling Y", Float) = 1
		_foamtilingX("foam tiling X", Float) = 1
		_foamnoiseamount("foam noise amount", Range( 0 , 1)) = 0
		[Header(Refraction)]_refractionIOR("refraction IOR", Range( -5 , 5)) = 1
		_refractionfalloff("refraction falloff", Range( 0 , 10)) = 1
		_refractiontint("refraction tint", Range( 0 , 1)) = 1
		[Header(Waves)][NoScaleOffset][Normal]_wavesnormal("waves normal", 2D) = "bump" {}
		_wavenormaltile("wave normal tile", Range( 0 , 10)) = 0
		_wavenormalstrength("wave normal strength", Range( 0 , 1)) = 1
		_bluramount("blur amount", Range( 0 , 1)) = 0.5
		_displacementstrength("displacement strength", Float) = 1
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Back
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityStandardUtils.cginc"
		#include "UnityCG.cginc"
		#include "Tessellation.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 4.6
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
		};

		uniform float _speed;
		uniform float _displacementstrength;
		uniform sampler2D _wavesnormal;
		uniform float _foamtilingX;
		uniform float _foamtilingY;
		UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
		uniform float4 _CameraDepthTexture_TexelSize;
		uniform float _wavenormaltile;
		uniform float _scatteringdepth;
		uniform float _scatteringfalloff;
		uniform float _wavenormalstrength;
		uniform float4 _foamcolour;
		uniform float _foamdistance;
		uniform float _foamnoiseamount;
		uniform float4 _deepcolour;
		uniform float4 _shallowcolour;
		uniform float _refractionIOR;
		uniform sampler2D _GrabBlurTexture;
		uniform sampler2D _GrabNoBlurTexture;
		uniform float _bluramount;
		uniform float _refractiontint;
		uniform float _refractionfalloff;
		uniform float _TessValue;
		uniform float _TessMin;
		uniform float _TessMax;


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


		float4 tessFunction( appdata_full v0, appdata_full v1, appdata_full v2 )
		{
			return UnityDistanceBasedTess( v0.vertex, v1.vertex, v2.vertex, _TessMin, _TessMax, _TessValue );
		}

		void vertexDataFunc( inout appdata_full v )
		{
			float mulTime70 = _Time.y * ( _speed / 10.0 );
			float time302 = mulTime70;
			float3 ase_worldPos = mul( unity_ObjectToWorld, v.vertex );
			float2 appendResult205 = (float2(ase_worldPos.x , ase_worldPos.z));
			float2 worldUV209 = ( appendResult205 * float2( 0.01,0.01 ) );
			float2 panner370 = ( time302 * float2( 1,0.5 ) + worldUV209);
			float simplePerlin2D379 = snoise( panner370*10.0 );
			simplePerlin2D379 = simplePerlin2D379*0.5 + 0.5;
			float temp_output_357_0 = ( simplePerlin2D379 * _displacementstrength );
			float3 ase_vertexNormal = v.normal.xyz;
			float3 displacement347 = ( temp_output_357_0 * ase_vertexNormal );
			v.vertex.xyz += displacement347;
			v.vertex.w = 1;
			float3 vertexNormals391 = ( ase_vertexNormal + temp_output_357_0 );
			v.normal = vertexNormals391;
		}

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float speed335 = _speed;
			float2 temp_cast_0 = (( speed335 * 0.25 )).xx;
			float3 ase_worldPos = i.worldPos;
			float2 appendResult205 = (float2(ase_worldPos.x , ase_worldPos.z));
			float2 worldUV209 = ( appendResult205 * float2( 0.01,0.01 ) );
			float2 temp_output_206_0 = ( float2( 20,20 ) * worldUV209 );
			float2 panner333 = ( 1.0 * _Time.y * temp_cast_0 + temp_output_206_0);
			float2 temp_cast_1 = (( speed335 * 0.1 )).xx;
			float2 panner355 = ( 1.0 * _Time.y * temp_cast_1 + temp_output_206_0);
			float2 temp_output_338_0 = ( panner355 / float2( 2,2 ) );
			float temp_output_221_0 = ( _foamtilingX * (worldUV209).x );
			float4 ase_screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			float4 ase_screenPosNorm = ase_screenPos / ase_screenPos.w;
			ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
			float screenDepth97 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ase_screenPosNorm.xy ));
			float distanceDepth97 = abs( ( screenDepth97 - LinearEyeDepth( ase_screenPosNorm.z ) ) / ( 1.0 ) );
			float depth_raw65 = distanceDepth97;
			float temp_output_82_0 = ( _foamtilingY * depth_raw65 );
			float2 appendResult301 = (float2(temp_output_221_0 , temp_output_82_0));
			float2 shoreUV191 = appendResult301;
			float2 break305 = ( shoreUV191 * _wavenormaltile );
			float mulTime70 = _Time.y * ( _speed / 10.0 );
			float time302 = mulTime70;
			float2 appendResult308 = (float2(break305.x , ( break305.y - ( 7.0 * time302 ) )));
			float depthDistance324 = _scatteringdepth;
			float clampResult327 = clamp( (1.0 + (depth_raw65 - 0.0) * (0.0 - 1.0) / (depthDistance324 - 0.0)) , 0.0 , 1.0 );
			float saferPower328 = max( clampResult327 , 0.0001 );
			float depthFalloff325 = _scatteringfalloff;
			float temp_output_328_0 = pow( saferPower328 , depthFalloff325 );
			float3 lerpResult313 = lerp( BlendNormals( UnpackScaleNormal( tex2D( _wavesnormal, panner333 ), 0.5 ) , UnpackScaleNormal( tex2D( _wavesnormal, temp_output_338_0 ), 0.5 ) ) , UnpackNormal( tex2D( _wavesnormal, appendResult308 ) ) , temp_output_328_0);
			float2 temp_output_293_0 = (lerpResult313).xy;
			float3 appendResult298 = (float3(( temp_output_293_0 * ( _wavenormalstrength * 0.025 ) ) , lerpResult313.z));
			float3 normals257 = appendResult298;
			o.Normal = normals257;
			float2 appendResult60 = (float2(temp_output_221_0 , ( temp_output_82_0 - time302 )));
			float simplePerlin2D90 = snoise( appendResult60*50.0 );
			simplePerlin2D90 = simplePerlin2D90*0.5 + 0.5;
			float lerpResult79 = lerp( 1.0 , simplePerlin2D90 , _foamnoiseamount);
			float foam_mask73 = (0.0 + (( ( ( ( 1.0 - depth_raw65 ) - 1.0 ) + _foamdistance ) * lerpResult79 ) - 0.7) * (1.0 - 0.0) / (1.0 - 0.7));
			float clampResult89 = clamp( foam_mask73 , 0.0 , 1.0 );
			float4 lerpResult45 = lerp( float4( 0,0,0,0 ) , _foamcolour , clampResult89);
			float4 albedo259 = lerpResult45;
			o.Albedo = albedo259.rgb;
			float3 appendResult297 = (float3(( temp_output_293_0 * _wavenormalstrength ) , lerpResult313.z));
			float3 refractionnormals212 = appendResult297;
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float4 ase_vertex4Pos = mul( unity_WorldToObject, float4( i.worldPos , 1 ) );
			float3 ase_viewPos = UnityObjectToViewPos( ase_vertex4Pos );
			float ase_screenDepth = -ase_viewPos.z;
			float eyeDepth28_g5 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ase_screenPosNorm.xy ));
			float2 temp_output_20_0_g5 = ( (BlendNormals( refractionnormals212 , ase_worldNormal )).xy * ( _refractionIOR / max( ase_screenDepth , 0.1 ) ) * saturate( ( eyeDepth28_g5 - ase_screenDepth ) ) );
			float eyeDepth2_g5 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ( float4( temp_output_20_0_g5, 0.0 , 0.0 ) + ase_screenPosNorm ).xy ));
			float2 temp_output_32_0_g5 = (( float4( ( temp_output_20_0_g5 * saturate( ( eyeDepth2_g5 - ase_screenDepth ) ) ), 0.0 , 0.0 ) + ase_screenPosNorm )).xy;
			float2 temp_output_1_0_g5 = ( ( floor( ( temp_output_32_0_g5 * (_CameraDepthTexture_TexelSize).zw ) ) + 0.5 ) * (_CameraDepthTexture_TexelSize).xy );
			float2 refractionUV219 = temp_output_1_0_g5;
			float eyeDepth216 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, float4( refractionUV219, 0.0 , 0.0 ).xy ));
			float clampResult30 = clamp( (1.0 + (( eyeDepth216 - ase_screenDepth ) - 0.0) * (0.0 - 1.0) / (_scatteringdepth - 0.0)) , 0.0 , 1.0 );
			float depth_refracted61 = pow( clampResult30 , _scatteringfalloff );
			float4 lerpResult8 = lerp( _deepcolour , _shallowcolour , depth_refracted61);
			float clampResult289 = clamp( ( depth_refracted61 + (-5.0 + (_bluramount - 1.0) * (5.0 - -5.0) / (0.0 - 1.0)) ) , 0.0 , 1.0 );
			float4 lerpResult275 = lerp( tex2D( _GrabBlurTexture, refractionUV219 ) , tex2D( _GrabNoBlurTexture, refractionUV219 ) , clampResult289);
			float4 grabPass280 = lerpResult275;
			float4 blendOpSrc232 = lerpResult8;
			float4 blendOpDest232 = grabPass280;
			float4 lerpBlendMode232 = lerp(blendOpDest232,2.0f*blendOpDest232*blendOpSrc232 + blendOpDest232*blendOpDest232*(1.0f - 2.0f*blendOpSrc232),_refractiontint);
			float clampResult270 = clamp( depth_refracted61 , 0.0 , 1.0 );
			float saferPower267 = max( clampResult270 , 0.0001 );
			float4 lerpResult228 = lerp( lerpResult8 , ( saturate( lerpBlendMode232 )) , pow( saferPower267 , _refractionfalloff ));
			float4 refraction261 = lerpResult228;
			o.Emission = refraction261.rgb;
			o.Smoothness = 0.975;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma only_renderers d3d9 d3d11_9x d3d11 glcore gles gles3 
		#pragma surface surf Standard alpha:fade keepalpha fullforwardshadows exclude_path:deferred nolightmap  nodynlightmap nodirlightmap vertex:vertexDataFunc tessellate:tessFunction 

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
				float4 screenPos : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
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
				vertexDataFunc( v );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
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
1920;0;1920;1019;-1163.363;3.477448;1;True;False
Node;AmplifyShaderEditor.CommentaryNode;195;536.5412,848.4501;Inherit;False;3701.612;1059.535;;46;328;326;327;329;315;330;257;298;299;227;212;297;319;294;293;214;313;337;225;309;308;336;338;339;303;192;333;332;305;300;206;306;331;197;194;334;209;207;205;204;355;356;382;391;399;397;NORMALS;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldPosInputsNode;204;570.9938,1360.189;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;205;764.0427,1383.539;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;207;915.4139,1384.209;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0.01,0.01;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;95;-2894.696,-223.9258;Inherit;False;1359.176;505.7792;;14;61;30;37;220;31;216;217;65;218;97;250;252;324;325;DEPTH FADE;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;209;1059.816,1375.875;Inherit;False;worldUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;96;-2832.084,728.9548;Inherit;False;3097.174;803.4672;;27;73;134;79;142;143;90;80;44;60;140;66;102;70;82;67;59;101;57;191;210;211;221;222;236;301;302;335;FOAM;1,1,1,1;0;0
Node;AmplifyShaderEditor.DepthFade;97;-2643.446,-170.1244;Inherit;False;True;False;True;2;1;FLOAT3;0,0,0;False;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;210;-2506.848,920.7383;Inherit;False;209;worldUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;65;-2319.878,-177.0158;Float;False;depth_raw;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;211;-2310.226,920.7679;Inherit;False;True;False;True;True;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;101;-2393.696,1200.23;Inherit;False;65;depth_raw;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;222;-2562.254,807.8076;Float;False;Property;_foamtilingX;foam tiling X;15;0;Create;True;0;0;0;False;0;False;1;0.2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;59;-2545.667,1103.665;Float;False;Property;_foamtilingY;foam tiling Y;14;0;Create;True;0;0;0;False;0;False;1;0.2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;57;-2814.361,1399.75;Float;False;Property;_speed;speed;13;0;Create;True;0;0;0;False;0;False;0.5;0.3;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;221;-2092.899,831.0775;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;82;-2132.473,1126.935;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;301;-1792.614,954.988;Inherit;False;FLOAT2;4;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;67;-2513.808,1391.972;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;10;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;191;-1657.796,947.7449;Inherit;False;shoreUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;335;-2522.043,1300.324;Inherit;False;speed;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;70;-2371.261,1399.742;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;302;-2181.481,1396.409;Inherit;False;time;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;197;590.5835,1187.202;Inherit;False;Property;_wavenormaltile;wave normal tile;21;0;Create;True;0;0;0;False;0;False;0;0;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;194;610.5015,1100.463;Inherit;False;191;shoreUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;31;-2707.427,155.4797;Float;False;Property;_scatteringdepth;scattering depth;10;1;[Header];Create;True;1;Scattering;0;0;False;0;False;75.8225;25;0;100;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;334;1052.682,1478.128;Inherit;False;335;speed;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;306;795.781,1288.499;Inherit;False;302;time;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;356;1256.114,1515.285;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;300;895.2302,1106.18;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;206;1280.796,1295.272;Inherit;False;2;2;0;FLOAT2;20,20;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;324;-2402.903,189.9359;Inherit;False;depthDistance;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;315;1652.063,1624.389;Inherit;False;65;depth_raw;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;355;1429.114,1417.285;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BreakToComponentsNode;305;1041.203,1101;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.GetLocalVarNode;330;1389.824,1738.239;Inherit;False;324;depthDistance;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;331;1266.255,1407.06;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.25;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;332;1015.466,1229.007;Inherit;False;2;2;0;FLOAT;7;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;252;-2210.973,187.5173;Inherit;False;Property;_scatteringfalloff;scattering falloff;11;0;Create;True;0;0;0;False;0;False;5;5;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;329;1860.121,1622.882;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;10;False;3;FLOAT;1;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;325;-1857.41,188.352;Inherit;False;depthFalloff;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;338;1639.947,1351.591;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;2,2;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;339;1421.652,1197.85;Inherit;False;Constant;_waveNormalScale;waveNormalScale;19;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;303;1200.856,1160.945;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;333;1426.01,1299.964;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ClampOpNode;327;2070.614,1622.579;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;336;1765.8,1321.19;Inherit;True;Property;_TextureSample2;Texture Sample 2;12;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;True;Instance;225;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;0.25;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;309;1774.102,1099.581;Inherit;True;Property;_TextureSample1;Texture Sample 1;12;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;True;Instance;225;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;0.25;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexturePropertyNode;192;592.8522,899.5503;Inherit;True;Property;_wavesnormal;waves normal;20;3;[Header];[NoScaleOffset];[Normal];Create;True;1;Waves;0;0;False;0;False;b8b43c26acee0b94f9fae5c1dbb29d55;b8b43c26acee0b94f9fae5c1dbb29d55;True;bump;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.DynamicAppendNode;308;1330.613,1099.36;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;326;2052.801,1754.098;Inherit;False;325;depthFalloff;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;328;2235.08,1622.436;Inherit;False;True;2;0;FLOAT;0;False;1;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.BlendNormalsNode;337;2136.308,1104.861;Inherit;False;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;225;1782.509,903.9403;Inherit;True;Property;_TextureSample0;Texture Sample 0;12;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;313;2402.155,927.8057;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;293;2747.315,914.1771;Inherit;False;True;True;False;True;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;214;2491.718,1124.413;Inherit;False;Property;_wavenormalstrength;wave normal strength;22;0;Create;True;0;0;0;False;0;False;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;294;3004.082,912.5385;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BreakToComponentsNode;319;2698.169,995.587;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.DynamicAppendNode;297;3211.265,953.2701;Inherit;False;FLOAT3;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;212;3405.903,937.6496;Inherit;False;refractionnormals;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;168;-2899.562,-1576.912;Inherit;False;2712.406;948.0295;;27;270;273;240;267;228;261;232;8;7;5;63;219;160;223;184;224;213;279;277;275;276;280;282;285;286;289;290;REFRACTION;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldNormalVector;224;-2817.117,-919.2572;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;213;-2832.774,-1052.079;Inherit;False;212;refractionnormals;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;184;-2800.956,-736.5526;Inherit;False;Property;_refractionIOR;refraction IOR;17;1;[Header];Create;True;1;Refraction;0;0;False;0;False;1;1;-5;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.BlendNormalsNode;223;-2595.1,-1042.68;Inherit;False;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;160;-2358.16,-1046.927;Inherit;False;DepthMaskedRefraction;-1;;5;c805f061214177c42bca056464193f81;2,40,0,103,0;2;35;FLOAT3;0,0,0;False;37;FLOAT;5;False;1;FLOAT2;38
Node;AmplifyShaderEditor.RegisterLocalVarNode;219;-1990.162,-1046.927;Inherit;False;refractionUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;218;-2873.869,-58.5558;Inherit;False;219;refractionUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScreenDepthNode;216;-2668.343,-54.83024;Inherit;False;0;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SurfaceDepthNode;217;-2726.55,46.00962;Inherit;False;0;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;220;-2463.6,-21.25139;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;37;-2288.626,-16.96892;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;10;False;3;FLOAT;1;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;102;-1953.974,1235.65;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;30;-2078.133,-17.27121;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;66;-1585.815,802.0148;Inherit;False;65;depth_raw;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;140;-1370.674,806.4294;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;60;-1784.884,1085.51;Inherit;False;FLOAT2;4;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PowerNode;250;-1913.667,-17.41504;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;90;-1584.435,1082.58;Inherit;True;Simplex2D;True;False;2;0;FLOAT2;5,5;False;1;FLOAT;50;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;61;-1750.399,-14.87626;Float;False;depth_refracted;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;80;-1324.342,1334.207;Float;False;Property;_foamnoiseamount;foam noise amount;16;0;Create;True;0;0;0;False;0;False;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;44;-1457.206,946.6396;Float;False;Property;_foamdistance;foam distance;12;1;[Header];Create;True;1;Foam;0;0;False;0;False;1;1;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;143;-1126.298,824.9965;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;285;-2344.135,-833.3099;Inherit;False;Property;_bluramount;blur amount;23;0;Create;True;0;0;0;False;0;False;0.5;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;142;-956.1581,957.8363;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;79;-927.4956,1068.101;Inherit;False;3;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;290;-2034.276,-879.2621;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;3;FLOAT;-5;False;4;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;279;-2265.476,-934.0047;Inherit;False;61;depth_refracted;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;400;1016.846,2155.863;Inherit;False;2639.912;907.1086;;16;373;380;370;361;379;357;347;340;346;345;343;381;341;342;367;360;DISPLACEMENT;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;134;-533.7347,945.7651;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;286;-1795.321,-895.0176;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;373;1399.983,2759.26;Inherit;False;209;worldUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;380;1066.846,2838.979;Inherit;False;302;time;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;276;-1762.155,-1320.822;Inherit;True;Global;_GrabNoBlurTexture;_GrabNoBlurTexture;6;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCRemapNode;236;-295.1501,939.0212;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0.7;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;277;-1755.615,-1126.065;Inherit;True;Global;_GrabBlurTexture;_GrabBlurTexture;7;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ClampOpNode;289;-1618.073,-901.5825;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;7;-2796.002,-1331.69;Float;False;Property;_deepcolour;deep colour;9;0;Create;True;0;0;0;False;0;False;0,0,0,0;0.1490195,0.2980391,0.1642255,1;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;63;-2217.289,-1282.546;Inherit;False;61;depth_refracted;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;174;-1096.884,-230.238;Inherit;False;1116.819;499.6698;;5;45;46;89;75;259;ALBEDO;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;240;-1387.718,-968.1622;Inherit;False;61;depth_refracted;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;275;-1343.433,-1261.822;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.PannerNode;370;1612.175,2771.378;Inherit;False;3;0;FLOAT2;0.2,0.2;False;2;FLOAT2;1,0.5;False;1;FLOAT;0.02;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;73;54.17426,926.1697;Float;False;foam_mask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;5;-2798.362,-1526.912;Float;False;Property;_shallowcolour;shallow colour;8;0;Create;True;0;0;0;False;0;False;1,1,1,0;0.6078431,0.8,0.6,1;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NoiseGeneratorNode;379;1872.737,2803.971;Inherit;True;Simplex2D;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;10;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;270;-1170.471,-965.4634;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;361;2548.112,2637.426;Inherit;False;Property;_displacementstrength;displacement strength;26;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;227;2812.661,1181.465;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.025;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;8;-1879.923,-1512.797;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;282;-1261.029,-1134.115;Inherit;False;Property;_refractiontint;refraction tint;19;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;75;-1011.117,93.78194;Inherit;False;73;foam_mask;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;273;-1425.341,-800.2729;Inherit;False;Property;_refractionfalloff;refraction falloff;18;0;Create;True;0;0;0;False;0;False;1;0;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;280;-1184.488,-1268.334;Inherit;False;grabPass;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.NormalVertexDataNode;399;2857.367,1515.208;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PowerNode;267;-971.7845,-950.8771;Inherit;False;True;2;0;FLOAT;0;False;1;FLOAT;25;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;46;-892.336,-140.0015;Float;False;Property;_foamcolour;foam colour;5;1;[Header];Create;True;1;Colour;0;0;False;0;False;0.8,0.8,0.8,1;0.8,0.8,0.8,1;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;299;2994.718,1123.587;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;357;2815.946,2373.653;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalVertexDataNode;360;2997.224,2497.978;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BlendOpsNode;232;-884.7056,-1394.349;Inherit;False;SoftLight;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.ClampOpNode;89;-771.9777,100.0034;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;228;-611.1495,-1455.443;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;367;3242.959,2376.623;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;45;-537.1641,-15.14206;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;298;3214.824,1054.767;Inherit;False;FLOAT3;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;397;3198.889,1525.887;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;391;3371.27,1529.868;Inherit;False;vertexNormals;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;347;3432.759,2371.024;Inherit;False;displacement;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;259;-238.8312,12.33708;Inherit;False;albedo;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;257;3708.074,1064.778;Inherit;False;normals;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;261;-419.5096,-1454.648;Inherit;False;refraction;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TexturePropertyNode;340;1091.324,2397.093;Inherit;True;Property;_Height;Height;24;2;[Header];[NoScaleOffset];Create;True;1;Displacement;0;0;False;0;False;f293baeaf87cdff4687cd0bfb5bc69b5;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.GetLocalVarNode;281;1823.746,353.2446;Inherit;False;391;vertexNormals;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;342;1860.625,2396.959;Inherit;True;Property;_TextureSample4;Texture Sample 4;12;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;341;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;341;1857.428,2205.863;Inherit;True;Property;_TextureSample3;Texture Sample 3;12;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;381;1319.87,2896.211;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;343;1850.323,2598.14;Inherit;True;Property;_TextureSample5;Texture Sample 5;12;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;341;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMaxOpNode;345;2231.01,2445.281;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;346;2410.476,2283.592;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;262;1897.999,95.55206;Inherit;False;261;refraction;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;348;1830.63,269.0117;Inherit;False;347;displacement;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldNormalVector;385;2048.53,622.6135;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;352;1459.153,520.0425;Inherit;False;Constant;_Float3;Float 3;21;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;258;1901.748,20.7692;Inherit;False;257;normals;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;350;1749.667,610.0425;Inherit;False;Property;_receiveshadows;receive shadows;25;0;Create;True;0;0;0;False;0;False;0;0;0;True;UNITY_PASS_SHADOWCASTER;Toggle;2;Key0;Key1;Fetch;True;True;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;353;1574.153,165.0425;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;382;3509.999,1133.816;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.IntNode;351;1454.153,682.0425;Inherit;False;Constant;_Int0;Int 0;21;0;Create;True;0;0;0;False;0;False;1;0;False;0;1;INT;0
Node;AmplifyShaderEditor.RangedFloatNode;108;1808.61,181.8114;Inherit;False;Constant;_Gloss;Gloss;11;0;Create;True;0;0;0;False;0;False;0.975;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;260;1909.614,-85.73596;Inherit;False;259;albedo;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;2203.103,-11.22004;Float;False;True;-1;6;ASEMaterialInspector;0;0;Standard;OSW/Water;False;False;False;False;False;False;True;True;True;False;False;False;False;False;True;False;False;False;False;False;False;Back;1;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Transparent;0.5;True;True;0;False;Transparent;;Transparent;ForwardOnly;6;d3d9;d3d11_9x;d3d11;glcore;gles;gles3;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;True;0;8;10;50;False;0.5;True;2;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;0;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;205;0;204;1
WireConnection;205;1;204;3
WireConnection;207;0;205;0
WireConnection;209;0;207;0
WireConnection;65;0;97;0
WireConnection;211;0;210;0
WireConnection;221;0;222;0
WireConnection;221;1;211;0
WireConnection;82;0;59;0
WireConnection;82;1;101;0
WireConnection;301;0;221;0
WireConnection;301;1;82;0
WireConnection;67;0;57;0
WireConnection;191;0;301;0
WireConnection;335;0;57;0
WireConnection;70;0;67;0
WireConnection;302;0;70;0
WireConnection;356;0;334;0
WireConnection;300;0;194;0
WireConnection;300;1;197;0
WireConnection;206;1;209;0
WireConnection;324;0;31;0
WireConnection;355;0;206;0
WireConnection;355;2;356;0
WireConnection;305;0;300;0
WireConnection;331;0;334;0
WireConnection;332;1;306;0
WireConnection;329;0;315;0
WireConnection;329;2;330;0
WireConnection;325;0;252;0
WireConnection;338;0;355;0
WireConnection;303;0;305;1
WireConnection;303;1;332;0
WireConnection;333;0;206;0
WireConnection;333;2;331;0
WireConnection;327;0;329;0
WireConnection;336;1;338;0
WireConnection;336;5;339;0
WireConnection;309;1;333;0
WireConnection;309;5;339;0
WireConnection;308;0;305;0
WireConnection;308;1;303;0
WireConnection;328;0;327;0
WireConnection;328;1;326;0
WireConnection;337;0;309;0
WireConnection;337;1;336;0
WireConnection;225;0;192;0
WireConnection;225;1;308;0
WireConnection;313;0;337;0
WireConnection;313;1;225;0
WireConnection;313;2;328;0
WireConnection;293;0;313;0
WireConnection;294;0;293;0
WireConnection;294;1;214;0
WireConnection;319;0;313;0
WireConnection;297;0;294;0
WireConnection;297;2;319;2
WireConnection;212;0;297;0
WireConnection;223;0;213;0
WireConnection;223;1;224;0
WireConnection;160;35;223;0
WireConnection;160;37;184;0
WireConnection;219;0;160;38
WireConnection;216;0;218;0
WireConnection;220;0;216;0
WireConnection;220;1;217;0
WireConnection;37;0;220;0
WireConnection;37;2;31;0
WireConnection;102;0;82;0
WireConnection;102;1;302;0
WireConnection;30;0;37;0
WireConnection;140;0;66;0
WireConnection;60;0;221;0
WireConnection;60;1;102;0
WireConnection;250;0;30;0
WireConnection;250;1;252;0
WireConnection;90;0;60;0
WireConnection;61;0;250;0
WireConnection;143;0;140;0
WireConnection;142;0;143;0
WireConnection;142;1;44;0
WireConnection;79;1;90;0
WireConnection;79;2;80;0
WireConnection;290;0;285;0
WireConnection;134;0;142;0
WireConnection;134;1;79;0
WireConnection;286;0;279;0
WireConnection;286;1;290;0
WireConnection;276;1;219;0
WireConnection;236;0;134;0
WireConnection;277;1;219;0
WireConnection;289;0;286;0
WireConnection;275;0;277;0
WireConnection;275;1;276;0
WireConnection;275;2;289;0
WireConnection;370;0;373;0
WireConnection;370;1;380;0
WireConnection;73;0;236;0
WireConnection;379;0;370;0
WireConnection;270;0;240;0
WireConnection;227;0;214;0
WireConnection;8;0;7;0
WireConnection;8;1;5;0
WireConnection;8;2;63;0
WireConnection;280;0;275;0
WireConnection;267;0;270;0
WireConnection;267;1;273;0
WireConnection;299;0;293;0
WireConnection;299;1;227;0
WireConnection;357;0;379;0
WireConnection;357;1;361;0
WireConnection;232;0;8;0
WireConnection;232;1;280;0
WireConnection;232;2;282;0
WireConnection;89;0;75;0
WireConnection;228;0;8;0
WireConnection;228;1;232;0
WireConnection;228;2;267;0
WireConnection;367;0;357;0
WireConnection;367;1;360;0
WireConnection;45;1;46;0
WireConnection;45;2;89;0
WireConnection;298;0;299;0
WireConnection;298;2;319;2
WireConnection;397;0;399;0
WireConnection;397;1;357;0
WireConnection;391;0;397;0
WireConnection;347;0;367;0
WireConnection;259;0;45;0
WireConnection;257;0;298;0
WireConnection;261;0;228;0
WireConnection;342;1;333;0
WireConnection;341;0;340;0
WireConnection;341;1;308;0
WireConnection;381;0;380;0
WireConnection;343;1;338;0
WireConnection;345;0;342;1
WireConnection;345;1;343;1
WireConnection;346;0;345;0
WireConnection;346;1;341;1
WireConnection;346;2;328;0
WireConnection;350;1;352;0
WireConnection;350;0;351;0
WireConnection;382;0;298;0
WireConnection;0;0;260;0
WireConnection;0;1;258;0
WireConnection;0;2;262;0
WireConnection;0;4;108;0
WireConnection;0;11;348;0
WireConnection;0;12;281;0
ASEEND*/
//CHKSM=BC9ADC71BEA580F3644AADDFC9D5E8797BA00606