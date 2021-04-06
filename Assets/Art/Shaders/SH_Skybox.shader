// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "SH_Skybox"
{
	Properties
	{
		[HDR]_ZenithColour("Zenith Colour", Color) = (1,1,1,0)
		[HDR]_HorizonColour("Horizon Colour", Color) = (0.5,0.5,0.5,0)
		_SunSize("Sun Size", Range( 0 , 1)) = 0.1
		[HDR]_SunColour("Sun Colour", Color) = (2,1.47451,0.972549,0)
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Background"  "Queue" = "Background+0" "IsEmissive" = "true"  }
		Cull Back
		Blend One OneMinusSrcAlpha
		
		CGPROGRAM
		#pragma target 3.0
		#pragma exclude_renderers metal xbox360 xboxone ps4 psp2 n3ds wiiu 
		#pragma surface surf Unlit keepalpha noshadow noambient novertexlights nolightmap  nodynlightmap nodirlightmap nofog nometa noforwardadd 
		struct Input
		{
			float3 worldPos;
			float3 viewDir;
		};

		uniform float4 _HorizonColour;
		uniform float4 _ZenithColour;
		uniform float4 _SunColour;
		uniform float _SunSize;

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			float3 ase_worldPos = i.worldPos;
			float3 normalizeResult3 = normalize( ase_worldPos );
			float3 break5 = normalizeResult3;
			float WorldX86 = break5.x;
			float WorldZ87 = break5.z;
			float WorldY82 = break5.y;
			float2 appendResult93 = (float2(( atan2( WorldX86 , WorldZ87 ) / 6.28318548202515 ) , ( asin( WorldY82 ) / ( UNITY_PI / 2.0 ) )));
			float2 UVs95 = appendResult93;
			float4 lerpResult98 = lerp( _HorizonColour , _ZenithColour , UVs95.y);
			float4 AltitudeColours22 = lerpResult98;
			float4 SunColour119 = _SunColour;
			float3 normalizeResult102 = normalize( i.viewDir );
			float dotResult104 = dot( float3(0.5,0.5,0.5) , normalizeResult102 );
			float temp_output_107_0 = ( (0.191 + (_SunSize - 0.0) * (0.193 - 0.191) / (1.0 - 0.0)) * acos( dotResult104 ) );
			float temp_output_109_0 = round( temp_output_107_0 );
			float lerpResult114 = lerp( pow( temp_output_107_0 , 5.0 ) , temp_output_109_0 , saturate( temp_output_109_0 ));
			float SunMask111 = lerpResult114;
			float4 lerpResult120 = lerp( AltitudeColours22 , SunColour119 , SunMask111);
			o.Emission = lerpResult120.rgb;
			o.Alpha = 1;
		}

		ENDCG
	}
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18800
459;704;1068;295;4873.461;1881.192;1.984998;True;False
Node;AmplifyShaderEditor.CommentaryNode;23;-5097.163,82.04043;Inherit;False;4063.85;792.444;;26;35;57;59;58;33;19;54;18;7;38;40;61;62;15;20;64;39;16;5;3;2;80;79;82;86;87;ALTITUDE GRADIENT;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldPosInputsNode;2;-5031.69,328.7534;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NormalizeNode;3;-4811.13,325.2134;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;5;-4624.004,342.19;Inherit;True;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.CommentaryNode;94;-5073.044,1104.173;Inherit;False;1360.58;608.6234;;12;93;84;76;83;75;74;88;89;90;92;91;95;UVs;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;86;-4369.044,232.173;Inherit;False;WorldX;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;87;-4376.044,600.173;Inherit;False;WorldZ;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;124;-5031.919,-2024.691;Inherit;False;2119.508;722.3765;;16;101;102;123;104;106;105;116;107;109;113;118;114;119;111;100;125;SUN;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;82;-4183.808,394.2938;Inherit;False;WorldY;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;88;-5023.044,1165.173;Inherit;False;86;WorldX;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;101;-4976.128,-1490.312;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;89;-5021.044,1275.173;Inherit;False;87;WorldZ;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.PiNode;75;-4878.64,1569.677;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;83;-5012.24,1448.312;Inherit;False;82;WorldY;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ASinOpNode;74;-4620.152,1459.281;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ATan2OpNode;90;-4642.044,1154.173;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;76;-4622.64,1553.677;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;102;-4778.125,-1465.072;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector3Node;123;-4971.457,-1974.69;Inherit;False;Constant;_Vector0;Vector 0;5;0;Create;True;0;0;0;True;0;False;0.5,0.5,0.5;0.5,0.5,0.5;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TauNode;92;-4639.044,1286.173;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;104;-4512.803,-1595.752;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;106;-4499.666,-1757.708;Inherit;False;Property;_SunSize;Sun Size;5;0;Create;True;0;0;0;False;0;False;0.1;0.1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;84;-4445.886,1502.479;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;91;-4435.044,1157.173;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ACosOpNode;105;-4364.304,-1587.833;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;116;-4155.484,-1745.179;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0.191;False;4;FLOAT;0.193;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;93;-4191.044,1317.173;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;95;-3982.313,1318.442;Inherit;False;UVs;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;37;-5075.95,-999.3891;Inherit;False;2621.687;850.2369;;16;22;44;42;43;32;27;29;31;26;36;24;28;30;25;96;98;ALTITUDE COLOURS;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;107;-3881.413,-1637.045;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RoundOpNode;109;-3667.55,-1577.507;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;96;-4040.907,-726.3888;Inherit;False;95;UVs;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PowerNode;125;-3593.14,-1700.287;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;113;-3513.994,-1473.014;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;97;-3170.788,-673.3124;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.ColorNode;25;-5025.95,-949.3891;Inherit;False;Property;_ZenithColour;Zenith Colour;0;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;26;-5017.998,-733.8669;Inherit;False;Property;_HorizonColour;Horizon Colour;2;1;[HDR];Create;True;0;0;0;False;0;False;0.5,0.5,0.5,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;98;-3611.758,-939.7057;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;118;-3482.007,-1933.244;Inherit;False;Property;_SunColour;Sun Colour;6;1;[HDR];Create;True;0;0;0;False;0;False;2,1.47451,0.972549,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;114;-3355.196,-1629.829;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;111;-3136.415,-1634.598;Inherit;False;SunMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;119;-3155.57,-1927.027;Inherit;False;SunColour;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;22;-2668.211,-672.145;Inherit;True;AltitudeColours;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;121;-789.2761,8.33394;Inherit;False;111;SunMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;8;-804.1685,-248.1641;Inherit;False;22;AltitudeColours;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;122;-794.5015,-141.8606;Inherit;False;119;SunColour;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;28;-4760.78,-815.8729;Inherit;False;7;ZenithMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;35;-1395.311,372.9179;Inherit;False;HorizonMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;80;-3022.71,666.3049;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;30;-4779.158,-345.3478;Inherit;False;18;NadirMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;64;-3760.902,512.7022;Inherit;False;Constant;_FalloffBias;FalloffBias;5;0;Create;True;0;0;0;False;0;False;1.25;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;31;-4565.318,-440.3879;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;29;-4519.319,-680.0474;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;79;-3006.642,222.3724;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;44;-3659.673,-570.8137;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0.25,0.25,0.25,1;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;62;-3389.947,496.9921;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1.25;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;40;-3248.82,676.3479;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;120;-445.1964,-142.9457;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;112;-281.6537,149.2085;Inherit;False;111;SunMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;58;-1970.688,498.8519;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;27;-4520.737,-905.4474;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;61;-3385.002,335.7922;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;1.25;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;24;-5017.133,-496.1788;Inherit;False;Property;_NadirColour;Nadir Colour;3;1;[HDR];Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;33;-2201.56,367.708;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;43;-4179.613,-325.1432;Inherit;False;35;HorizonMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;7;-2776.298,257.8763;Inherit;False;ZenithMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;57;-1624.43,366.0959;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;19;-2456.139,354.7502;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;42;-3914.459,-498.3195;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;15;-3853.349,188.0952;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;-3589.755,668.2097;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;18;-2816.327,581.02;Inherit;False;NadirMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;36;-4752.969,-572.5369;Inherit;False;35;HorizonMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;100;-4981.919,-1769.528;Inherit;False;Global;_SunDirection;_SunDirection;5;0;Fetch;True;0;0;0;True;0;False;0.5,0.5,0.5;0.13819,-0.6025605,-0.7860184;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode;32;-4207.514,-573.2672;Inherit;True;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.PowerNode;38;-3249.287,188.6432;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;54;-3206.893,422.9579;Inherit;False;HorizonFalloff;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;59;-1785.507,496.8517;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;39;-3866.216,348.2585;Inherit;False;Property;_HorizonFalloff;Horizon Falloff;4;0;Create;True;0;0;0;False;0;False;1;0;0.1;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMinOpNode;16;-3829.635,659.7798;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;-30.54006,-186.0303;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;SH_Skybox;False;False;False;False;True;True;True;True;True;True;True;True;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.5;True;False;0;True;Background;;Background;All;7;d3d9;d3d11_9x;d3d11;glcore;gles;gles3;vulkan;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;False;3;1;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;3;0;2;0
WireConnection;5;0;3;0
WireConnection;86;0;5;0
WireConnection;87;0;5;2
WireConnection;82;0;5;1
WireConnection;74;0;83;0
WireConnection;90;0;88;0
WireConnection;90;1;89;0
WireConnection;76;0;75;0
WireConnection;102;0;101;0
WireConnection;104;0;123;0
WireConnection;104;1;102;0
WireConnection;84;0;74;0
WireConnection;84;1;76;0
WireConnection;91;0;90;0
WireConnection;91;1;92;0
WireConnection;105;0;104;0
WireConnection;116;0;106;0
WireConnection;93;0;91;0
WireConnection;93;1;84;0
WireConnection;95;0;93;0
WireConnection;107;0;116;0
WireConnection;107;1;105;0
WireConnection;109;0;107;0
WireConnection;125;0;107;0
WireConnection;113;0;109;0
WireConnection;97;0;96;0
WireConnection;98;0;26;0
WireConnection;98;1;25;0
WireConnection;98;2;97;1
WireConnection;114;0;125;0
WireConnection;114;1;109;0
WireConnection;114;2;113;0
WireConnection;111;0;114;0
WireConnection;119;0;118;0
WireConnection;22;0;98;0
WireConnection;35;0;57;0
WireConnection;80;0;20;0
WireConnection;31;0;24;0
WireConnection;31;1;30;0
WireConnection;29;0;26;0
WireConnection;29;1;36;0
WireConnection;79;0;15;0
WireConnection;44;0;32;0
WireConnection;44;1;42;0
WireConnection;62;0;39;0
WireConnection;62;1;64;0
WireConnection;40;0;20;0
WireConnection;40;1;62;0
WireConnection;120;0;8;0
WireConnection;120;1;122;0
WireConnection;120;2;121;0
WireConnection;58;0;33;0
WireConnection;27;0;25;0
WireConnection;27;1;28;0
WireConnection;61;0;39;0
WireConnection;61;1;64;0
WireConnection;33;0;19;0
WireConnection;7;0;79;0
WireConnection;57;0;33;0
WireConnection;57;1;59;0
WireConnection;19;0;7;0
WireConnection;19;1;18;0
WireConnection;42;0;32;0
WireConnection;42;1;43;0
WireConnection;15;0;5;1
WireConnection;20;0;16;0
WireConnection;18;0;80;0
WireConnection;32;0;27;0
WireConnection;32;1;29;0
WireConnection;32;2;31;0
WireConnection;38;0;15;0
WireConnection;38;1;61;0
WireConnection;54;0;39;0
WireConnection;59;0;58;0
WireConnection;16;0;5;1
WireConnection;0;2;120;0
ASEEND*/
//CHKSM=C1FEB1C2103663034484E1BD4E76C2C103D8BEE9