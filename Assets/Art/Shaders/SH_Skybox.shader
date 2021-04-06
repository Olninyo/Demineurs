// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "SH_Skybox"
{
	Properties
	{
		[HDR]_ZenithColour("Zenith Colour", Color) = (1,1,1,0)
		[HDR]_HorizonColour("Horizon Colour", Color) = (0.5,0.5,0.5,0)
		[HDR]_NadirColour("Nadir Colour", Color) = (0,0,0,0)
		_HorizonFalloff("Horizon Falloff", Range( 0.1 , 1)) = 1
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
			float smoothstepResult11 = smoothstep( 0.0 , 1.0 , normalizeResult3.y);
			float ZenithMask7 = pow( max( smoothstepResult11 , 0.0 ) , _HorizonFalloff );
			float smoothstepResult21 = smoothstep( 0.0 , 1.0 , ( min( normalizeResult3.y , 0.0 ) * -1.0 ));
			float NadirMask18 = pow( smoothstepResult21 , _HorizonFalloff );
			float HorizonMask35 = ( 1.0 - ( ZenithMask7 + NadirMask18 ) );
			float4 AltitudeColours22 = ( ( _ZenithColour * ZenithMask7 ) + ( _HorizonColour * HorizonMask35 ) + ( _NadirColour * NadirMask18 ) );
			o.Emission = AltitudeColours22.rgb;
			o.Alpha = 1;
		}

		ENDCG
	}
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18800
462;704;1065;295;5479.142;43.99794;3.215007;True;False
Node;AmplifyShaderEditor.CommentaryNode;23;-4704.096,80.04043;Inherit;False;2580.78;615.5547;;16;33;19;18;7;15;21;20;11;16;5;3;2;35;39;38;40;ALTITUDE GRADIENT;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldPosInputsNode;2;-4654.096,246.3681;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NormalizeNode;3;-4433.536,242.8281;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;5;-4194.526,240.0616;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleMinOpNode;16;-4000.96,475.7602;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;-3864.442,470.9599;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;11;-3757.685,141.7701;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;15;-3485.525,144.0654;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;21;-3684.369,470.7452;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;39;-3626.186,370.1684;Inherit;False;Property;_HorizonFalloff;Horizon Falloff;4;0;Create;True;0;0;0;False;0;False;1;0;0.1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;40;-3288.636,470.3783;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;38;-3285.948,154.5335;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;18;-3093.948,470.3601;Inherit;False;NadirMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;7;-3106.846,148.0313;Inherit;False;ZenithMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;19;-2829.604,273.8351;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;33;-2569.745,269.1928;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;37;-4404.305,-912.5394;Inherit;False;1458.354;770.0417;;11;36;28;30;24;26;25;27;31;29;32;22;ALTITUDE COLOURS;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;35;-2351.141,305.4278;Inherit;False;HorizonMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;30;-4107.513,-258.4977;Inherit;False;18;NadirMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;36;-4081.325,-485.6871;Inherit;False;35;HorizonMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;28;-4089.136,-729.0232;Inherit;False;7;ZenithMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;26;-4346.353,-647.0173;Inherit;False;Property;_HorizonColour;Horizon Colour;2;1;[HDR];Create;True;0;0;0;False;0;False;0.5,0.5,0.5,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;24;-4345.489,-409.3287;Inherit;False;Property;_NadirColour;Nadir Colour;3;1;[HDR];Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;25;-4354.305,-862.5394;Inherit;False;Property;_ZenithColour;Zenith Colour;1;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;27;-3849.093,-818.5978;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;31;-3893.674,-353.5378;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;29;-3847.675,-593.1977;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;32;-3435.258,-565.8072;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;22;-3171.951,-556.9905;Inherit;True;AltitudeColours;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;8;-329.283,53.22631;Inherit;False;22;AltitudeColours;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;0,0;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;SH_Skybox;False;False;False;False;True;True;True;True;True;True;True;True;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.5;True;False;0;True;Background;;Background;All;7;d3d9;d3d11_9x;d3d11;glcore;gles;gles3;vulkan;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;False;3;1;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;0;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;3;0;2;0
WireConnection;5;0;3;0
WireConnection;16;0;5;1
WireConnection;20;0;16;0
WireConnection;11;0;5;1
WireConnection;15;0;11;0
WireConnection;21;0;20;0
WireConnection;40;0;21;0
WireConnection;40;1;39;0
WireConnection;38;0;15;0
WireConnection;38;1;39;0
WireConnection;18;0;40;0
WireConnection;7;0;38;0
WireConnection;19;0;7;0
WireConnection;19;1;18;0
WireConnection;33;0;19;0
WireConnection;35;0;33;0
WireConnection;27;0;25;0
WireConnection;27;1;28;0
WireConnection;31;0;24;0
WireConnection;31;1;30;0
WireConnection;29;0;26;0
WireConnection;29;1;36;0
WireConnection;32;0;27;0
WireConnection;32;1;29;0
WireConnection;32;2;31;0
WireConnection;22;0;32;0
WireConnection;0;2;8;0
ASEEND*/
//CHKSM=9ADBE7C27A2E616EBF1546F60964EFD84321D27E