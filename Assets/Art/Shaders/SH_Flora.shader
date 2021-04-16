// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "OSW/SH_Flora"
{
	Properties
	{
		_Cutoff( "Mask Clip Value", Float ) = 0.5
		_BillboardSize("Billboard Size", Range( 0 , 1)) = 1
		_BillboardAmount("Billboard Amount", Range( 0 , 1)) = 1
		_BillboardInflate("Billboard Inflate", Range( 0 , 1)) = 0.1
		_FloraAlbedo("Flora Albedo", 2D) = "white" {}
		[Toggle]_FresnelGamma("Fresnel Gamma", Float) = 1
		[HideInInspector] _texcoord2( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "TransparentCutout"  "Queue" = "AlphaTest+0" }
		Cull Back
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		struct Input
		{
			float3 worldPos;
			float3 worldNormal;
			float2 uv2_texcoord2;
		};

		uniform float _BillboardInflate;
		uniform float _BillboardSize;
		uniform float _BillboardAmount;
		uniform float _FresnelGamma;
		uniform sampler2D _FloraAlbedo;
		uniform float4 _FloraAlbedo_ST;
		uniform float _Cutoff = 0.5;


		float3 HSVToRGB( float3 c )
		{
			float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
			float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
			return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
		}


		float3 RGBToHSV(float3 c)
		{
			float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
			float4 p = lerp( float4( c.bg, K.wz ), float4( c.gb, K.xy ), step( c.b, c.g ) );
			float4 q = lerp( float4( p.xyw, c.r ), float4( c.r, p.yzx ), step( p.x, c.r ) );
			float d = q.x - min( q.w, q.y );
			float e = 1.0e-10;
			return float3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
		}

		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float3 ase_vertexNormal = v.normal.xyz;
			float2 temp_output_3_0 = (float2( -1,-1 ) + (v.texcoord.xy - float2( 0,0 )) * (float2( 1,1 ) - float2( -1,-1 )) / (float2( 1,1 ) - float2( 0,0 )));
			float3 appendResult6 = (float3(temp_output_3_0 , 0.0));
			float3 normalizeResult9 = normalize( mul( float4( mul( float4( appendResult6 , 0.0 ), UNITY_MATRIX_V ).xyz , 0.0 ), unity_ObjectToWorld ).xyz );
			float3 lerpResult69 = lerp( float3( 0,0,0 ) , ( ( ase_vertexNormal * _BillboardInflate ) + ( normalizeResult9 * _BillboardSize ) ) , _BillboardAmount);
			float3 VertexOffset11 = lerpResult69;
			v.vertex.xyz += VertexOffset11;
			v.vertex.w = 1;
		}

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float4 color10 = IsGammaSpace() ? float4(0.4676306,0.5019608,0.2454589,0) : float4(0.1852941,0.2158605,0.04907704,0);
			float3 hsvTorgb28 = RGBToHSV( color10.rgb );
			float3 hsvTorgb32 = HSVToRGB( float3(hsvTorgb28.x,saturate( ( hsvTorgb28.y + 0.05 ) ),saturate( ( hsvTorgb28.z + 0.1 ) )) );
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float3 ase_worldNormal = i.worldNormal;
			float fresnelNdotV26 = dot( ase_worldNormal, ase_worldViewDir );
			float fresnelNode26 = ( 0.0 + 1.0 * pow( 1.0 - fresnelNdotV26, 1.0 ) );
			float4 lerpResult33 = lerp( color10 , float4( hsvTorgb32 , 0.0 ) , saturate( fresnelNode26 ));
			float2 uv2_FloraAlbedo = i.uv2_texcoord2 * _FloraAlbedo_ST.xy + _FloraAlbedo_ST.zw;
			float4 tex2DNode19 = tex2D( _FloraAlbedo, uv2_FloraAlbedo );
			float4 Albedo21 = ( (( _FresnelGamma )?( lerpResult33 ):( color10 )) * tex2DNode19 );
			o.Albedo = Albedo21.rgb;
			o.Alpha = 1;
			float AlphaCutout23 = tex2DNode19.a;
			clip( AlphaCutout23 - _Cutoff );
		}

		ENDCG
		CGPROGRAM
		#pragma exclude_renderers metal xbox360 xboxone ps4 psp2 n3ds wiiu 
		#pragma surface surf Standard keepalpha fullforwardshadows nolightmap  nodynlightmap nodirlightmap vertex:vertexDataFunc 

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
				float3 worldPos : TEXCOORD2;
				float3 worldNormal : TEXCOORD3;
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
				o.worldNormal = worldNormal;
				o.customPack1.xy = customInputData.uv2_texcoord2;
				o.customPack1.xy = v.texcoord1;
				o.worldPos = worldPos;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
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
				float3 worldPos = IN.worldPos;
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = IN.worldNormal;
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
538;729;1037;270;4513.903;978.7615;2.860036;True;False
Node;AmplifyShaderEditor.CommentaryNode;74;-3678.815,503.5665;Inherit;False;3136.509;854.5336;;22;1;3;6;4;5;7;8;13;46;47;9;45;48;70;69;11;54;55;50;71;72;49;VERTEX OFFSET;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;73;-3482.946,-741.1312;Inherit;False;2521.684;767.1814;;16;10;28;40;30;38;26;39;37;44;32;33;19;43;20;23;21;ALBEDO;1,1,1,1;0;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;1;-3628.815,840.9224;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCRemapNode;3;-3411.543,840.4329;Inherit;False;5;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT2;1,1;False;3;FLOAT2;-1,-1;False;4;FLOAT2;1,1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ColorNode;10;-3432.946,-691.1312;Inherit;False;Constant;_AlbedoColour;Albedo Colour;0;0;Create;True;0;0;0;False;0;False;0.4676306,0.5019608,0.2454589,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;6;-2680.317,843.3232;Inherit;False;FLOAT3;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RGBToHSVNode;28;-3133.548,-581.8301;Inherit;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ViewMatrixNode;4;-2660.203,1029.807;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.ObjectToWorldMatrixNode;7;-2442.781,1036.989;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;5;-2454.009,907.723;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;40;-2801.897,-455.2736;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.05;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;30;-2807.555,-338.5288;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;38;-2675.295,-450.9334;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;26;-2623.215,-234.051;Inherit;False;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;39;-2664.344,-334.8838;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;8;-2190.119,903.2429;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;9;-2017.342,902.2531;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;13;-2079.83,1058.122;Inherit;False;Property;_BillboardSize;Billboard Size;1;0;Create;True;0;0;0;False;0;False;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;47;-1803.648,720.7612;Inherit;False;Property;_BillboardInflate;Billboard Inflate;3;0;Create;True;0;0;0;False;0;False;0.1;0.1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalVertexDataNode;46;-1750.192,553.5665;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WireNode;44;-2379.408,-663.5653;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.HSVToRGBNode;32;-2453.377,-555.3335;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SaturateNode;37;-2369.771,-231.4344;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;33;-2137.977,-579.351;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;45;-1673.761,900.4074;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;48;-1484.231,621.8771;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;70;-1258.124,1098.568;Inherit;False;Property;_BillboardAmount;Billboard Amount;2;0;Create;True;0;0;0;False;0;False;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;49;-1222.475,875.3193;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ToggleSwitchNode;43;-1795.065,-691.0652;Inherit;False;Property;_FresnelGamma;Fresnel Gamma;5;0;Create;True;0;0;0;False;0;False;1;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;19;-1951.758,-203.9498;Inherit;True;Property;_FloraAlbedo;Flora Albedo;4;0;Create;True;0;0;0;False;0;False;-1;4684d9a9a8c4a1043a03d70df774cbf1;4684d9a9a8c4a1043a03d70df774cbf1;True;1;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;-1543.66,-210.4547;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;69;-953.9802,875.8766;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;23;-1185.262,-99.42487;Inherit;False;AlphaCutout;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;11;-766.3066,862.2033;Inherit;False;VertexOffset;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;21;-1192.322,-213.4445;Inherit;False;Albedo;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.PosVertexDataNode;71;-3606.188,1175.1;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;72;-3321.186,1191.725;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;10;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;22;208.8076,-1.354742;Inherit;False;21;Albedo;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;24;277.2783,158.9651;Inherit;False;23;AlphaCutout;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;12;205.7779,304.7719;Inherit;False;11;VertexOffset;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.VertexIdVariableNode;54;-3605.741,1068.615;Inherit;False;0;1;INT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;55;-3380.444,1068.745;Inherit;False;2;0;INT;0;False;1;INT;50;False;1;INT;0
Node;AmplifyShaderEditor.RotatorNode;50;-3076.799,920.3814;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;495.1353,6.915004;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;OSW/SH_Flora;False;False;False;False;False;False;True;True;True;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Masked;0.5;True;True;0;False;TransparentCutout;;AlphaTest;All;7;d3d9;d3d11_9x;d3d11;glcore;gles;gles3;vulkan;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Spherical;True;Relative;0;;0;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;3;0;1;0
WireConnection;6;0;3;0
WireConnection;28;0;10;0
WireConnection;5;0;6;0
WireConnection;5;1;4;0
WireConnection;40;0;28;2
WireConnection;30;0;28;3
WireConnection;38;0;40;0
WireConnection;39;0;30;0
WireConnection;8;0;5;0
WireConnection;8;1;7;0
WireConnection;9;0;8;0
WireConnection;44;0;10;0
WireConnection;32;0;28;1
WireConnection;32;1;38;0
WireConnection;32;2;39;0
WireConnection;37;0;26;0
WireConnection;33;0;44;0
WireConnection;33;1;32;0
WireConnection;33;2;37;0
WireConnection;45;0;9;0
WireConnection;45;1;13;0
WireConnection;48;0;46;0
WireConnection;48;1;47;0
WireConnection;49;0;48;0
WireConnection;49;1;45;0
WireConnection;43;0;44;0
WireConnection;43;1;33;0
WireConnection;20;0;43;0
WireConnection;20;1;19;0
WireConnection;69;1;49;0
WireConnection;69;2;70;0
WireConnection;23;0;19;4
WireConnection;11;0;69;0
WireConnection;21;0;20;0
WireConnection;72;0;71;1
WireConnection;55;0;54;0
WireConnection;50;0;3;0
WireConnection;50;2;55;0
WireConnection;0;0;22;0
WireConnection;0;10;24;0
WireConnection;0;11;12;0
ASEEND*/
//CHKSM=F5DF749F4EF1085740F9C71BEC95FA8E54D0DF2E