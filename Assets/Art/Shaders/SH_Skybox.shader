// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "SH_Skybox"
{
	Properties
	{
		[HDR]_ZenithColour("Zenith Colour", Color) = (1,1,1,0)
		[HDR]_HorizonColour("Horizon Colour", Color) = (0.5,0.5,0.5,0)
		[HDR]_NadirColour("Nadir Colour", Color) = (0,0,0,0)
		_HorizonFalloff("Horizon Falloff", Range( 0.1 , 2)) = 1
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
		};

		uniform float4 _ZenithColour;
		uniform float _HorizonFalloff;
		uniform float4 _HorizonColour;
		uniform float4 _NadirColour;

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			float3 ase_worldPos = i.worldPos;
			float3 normalizeResult3 = normalize( ase_worldPos );
			float ZenithMask7 = pow( max( normalizeResult3.y , 0.0 ) , ( _HorizonFalloff * 1.25 ) );
			float NadirMask18 = pow( ( min( normalizeResult3.y , 0.0 ) * -1.0 ) , ( _HorizonFalloff / 1.25 ) );
			float temp_output_33_0 = ( 1.0 - ( ZenithMask7 + NadirMask18 ) );
			float HorizonMask35 = ( temp_output_33_0 + ( pow( temp_output_33_0 , 5.0 ) / 2.0 ) );
			float4 temp_output_32_0 = ( ( _ZenithColour * ZenithMask7 ) + ( _HorizonColour * HorizonMask35 ) + ( _NadirColour * NadirMask18 ) );
			float4 lerpResult44 = lerp( temp_output_32_0 , ( temp_output_32_0 * HorizonMask35 ) , float4( 0.25,0.25,0.25,1 ));
			float4 AltitudeColours22 = lerpResult44;
			o.Emission = AltitudeColours22.rgb;
			o.Alpha = 1;
		}

		ENDCG
	}
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18800
459;704;1068;295;4444.246;-316.1865;1.435003;True;False
Node;AmplifyShaderEditor.CommentaryNode;23;-4704.096,82.04043;Inherit;False;3191.557;801.729;;20;54;35;33;19;7;18;40;38;39;15;20;16;5;3;2;58;59;61;62;64;ALTITUDE GRADIENT;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldPosInputsNode;2;-4654.096,350.4184;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NormalizeNode;3;-4433.536,346.8784;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;5;-4263.227,350.9819;Inherit;True;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleMinOpNode;16;-3829.635,568.2602;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;39;-3737.511,405.4588;Inherit;False;Property;_HorizonFalloff;Horizon Falloff;4;0;Create;True;0;0;0;False;0;False;1;0;0.1;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;64;-3677.959,489.8221;Inherit;False;Constant;_FalloffBias;FalloffBias;5;0;Create;True;0;0;0;False;0;False;1.25;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;62;-3407.107,539.8922;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1.25;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;61;-3385.002,335.7922;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;1.25;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;-3589.755,571.3349;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;15;-3836.554,265.6606;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;38;-3237.847,257.2836;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;40;-3247.035,584.8282;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;18;-3093.948,574.41;Inherit;False;NadirMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;7;-3070.445,261.1814;Inherit;False;ZenithMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;19;-2829.604,377.8854;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;33;-2575.025,390.8432;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;58;-2344.155,521.9869;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;59;-2158.974,519.9867;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;57;-1997.897,389.2311;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;35;-1768.778,396.0531;Inherit;False;HorizonMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;37;-4404.305,-912.5394;Inherit;False;2621.687;850.2369;;16;22;44;42;43;32;27;29;31;26;36;24;28;30;25;49;52;ALTITUDE COLOURS;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;36;-4081.325,-485.6871;Inherit;False;35;HorizonMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;28;-4089.136,-729.0232;Inherit;False;7;ZenithMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;24;-4345.489,-409.3287;Inherit;False;Property;_NadirColour;Nadir Colour;3;1;[HDR];Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;30;-4107.513,-258.4977;Inherit;False;18;NadirMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;25;-4354.305,-862.5394;Inherit;False;Property;_ZenithColour;Zenith Colour;0;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;26;-4346.353,-647.0173;Inherit;False;Property;_HorizonColour;Horizon Colour;2;1;[HDR];Create;True;0;0;0;False;0;False;0.5,0.5,0.5,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;29;-3847.675,-593.1977;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;27;-3849.093,-818.5978;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;31;-3893.674,-353.5378;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;43;-3417.262,-329.0031;Inherit;False;35;HorizonMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;32;-3445.163,-577.1271;Inherit;True;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;42;-3152.109,-502.1792;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;44;-2897.323,-574.6735;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0.25,0.25,0.25,1;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;22;-1996.568,-585.2953;Inherit;True;AltitudeColours;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;54;-3224.054,460.1381;Inherit;False;HorizonFalloff;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;49;-2501.455,-494.3356;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;52;-2272.084,-509.4445;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0.25,0.25,0.25,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;8;-329.283,53.22631;Inherit;False;22;AltitudeColours;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;0,0;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;SH_Skybox;False;False;False;False;True;True;True;True;True;True;True;True;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.5;True;False;0;True;Background;;Background;All;7;d3d9;d3d11_9x;d3d11;glcore;gles;gles3;vulkan;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;False;3;1;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;3;0;2;0
WireConnection;5;0;3;0
WireConnection;16;0;5;1
WireConnection;62;0;39;0
WireConnection;62;1;64;0
WireConnection;61;0;39;0
WireConnection;61;1;64;0
WireConnection;20;0;16;0
WireConnection;15;0;5;1
WireConnection;38;0;15;0
WireConnection;38;1;61;0
WireConnection;40;0;20;0
WireConnection;40;1;62;0
WireConnection;18;0;40;0
WireConnection;7;0;38;0
WireConnection;19;0;7;0
WireConnection;19;1;18;0
WireConnection;33;0;19;0
WireConnection;58;0;33;0
WireConnection;59;0;58;0
WireConnection;57;0;33;0
WireConnection;57;1;59;0
WireConnection;35;0;57;0
WireConnection;29;0;26;0
WireConnection;29;1;36;0
WireConnection;27;0;25;0
WireConnection;27;1;28;0
WireConnection;31;0;24;0
WireConnection;31;1;30;0
WireConnection;32;0;27;0
WireConnection;32;1;29;0
WireConnection;32;2;31;0
WireConnection;42;0;32;0
WireConnection;42;1;43;0
WireConnection;44;0;32;0
WireConnection;44;1;42;0
WireConnection;22;0;44;0
WireConnection;54;0;39;0
WireConnection;49;0;44;0
WireConnection;52;0;44;0
WireConnection;52;1;49;0
WireConnection;0;2;8;0
ASEEND*/
//CHKSM=9C11F49EB4817624E374D308AC1ABF2EE9690D35