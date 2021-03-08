// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "VertReynolds"
{
	Properties
	{
		[Toggle]_RedChannel("Red Channel", Float) = 1
		[Toggle]_GreenChannel("Green Channel", Float) = 1
		[Toggle]_BlueChannel("Blue Channel", Float) = 1
		[Toggle]_Greyscale("Greyscale", Float) = 0
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGPROGRAM
		#pragma target 3.0
		#pragma surface surf Unlit keepalpha addshadow fullforwardshadows noambient novertexlights nolightmap  nodynlightmap nodirlightmap nofog nometa noforwardadd 
		struct Input
		{
			float4 vertexColor : COLOR;
		};

		uniform half _Greyscale;
		uniform half _RedChannel;
		uniform half _GreenChannel;
		uniform half _BlueChannel;

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			half4 appendResult11 = (half4((( _RedChannel )?( i.vertexColor.r ):( 0.0 )) , (( _GreenChannel )?( i.vertexColor.g ):( 0.0 )) , (( _BlueChannel )?( i.vertexColor.b ):( 0.0 )) , 0.0));
			half4 temp_cast_0 = (( (( _RedChannel )?( i.vertexColor.r ):( 0.0 )) + (( _GreenChannel )?( i.vertexColor.g ):( 0.0 )) + (( _BlueChannel )?( i.vertexColor.b ):( 0.0 )) )).xxxx;
			o.Emission = (( _Greyscale )?( temp_cast_0 ):( appendResult11 )).xyz;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18800
1920;0;1920;1019;1437.279;534.5297;1.355;True;True
Node;AmplifyShaderEditor.VertexColorNode;1;-999.6139,35.92489;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ToggleSwitchNode;2;-723.1943,-77.8946;Inherit;False;Property;_RedChannel;Red Channel;0;0;Create;True;0;0;0;False;0;False;1;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;3;-725.9036,35.92535;Inherit;False;Property;_GreenChannel;Green Channel;1;0;Create;True;0;0;0;False;0;False;1;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;7;-720.4841,157.8753;Inherit;False;Property;_BlueChannel;Blue Channel;2;0;Create;True;0;0;0;False;0;False;1;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;11;-369.5395,-161.9047;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;6;-361.4086,12.89042;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;13;35.60609,-77.89502;Inherit;False;Property;_Greyscale;Greyscale;3;0;Create;True;0;0;0;False;0;False;0;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;380.7551,-33.87499;Half;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;VertReynolds;False;False;False;False;True;True;True;True;True;True;True;True;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;2;1;1;1
WireConnection;3;1;1;2
WireConnection;7;1;1;3
WireConnection;11;0;2;0
WireConnection;11;1;3;0
WireConnection;11;2;7;0
WireConnection;6;0;2;0
WireConnection;6;1;3;0
WireConnection;6;2;7;0
WireConnection;13;0;11;0
WireConnection;13;1;6;0
WireConnection;0;2;13;0
ASEEND*/
//CHKSM=C657EE93155DE2CC1C1A3A7588C01B82E9AB16CF