// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "SH_Skybox"
{
	Properties
	{
		[HDR]_ZenithColour("Zenith Colour", Color) = (1,1,1,0)
		[HDR]_HorizonColour("Horizon Colour", Color) = (0.5,0.5,0.5,0)
		[HDR]_NadirColour("Nadir Colour", Color) = (0.3019608,0.3019608,0.3019608,0)
		_HorizonFalloff("Horizon Falloff", Range( 0.01 , 1)) = 0.5
		_SunSize("Sun Size", Range( 0 , 1)) = 0.1
		_SunAtmosDensity("Sun Atmos Density", Range( 0 , 1)) = 0.5
		_SunAtmosFalloff("Sun Atmos Falloff", Range( 0 , 1)) = 0.5
		[HDR]_SunColour("Sun Colour", Color) = (2,1.47451,0.972549,0)
		[Toggle]_UseEnvironmentGradient("Use Environment Gradient", Float) = 1
		_TextureSample0("Texture Sample 0", 2D) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Background"  "Queue" = "Background+0" "IsEmissive" = "true"  }
		Cull Back
		Blend One OneMinusSrcAlpha
		
		CGPROGRAM
		#include "UnityShaderVariables.cginc"
		#pragma target 3.0
		#pragma exclude_renderers metal xbox360 xboxone ps4 psp2 n3ds wiiu 
		#pragma surface surf Unlit keepalpha noshadow noambient novertexlights nolightmap  nodynlightmap nodirlightmap nofog nometa noforwardadd 
		struct Input
		{
			float3 worldPos;
			float3 viewDir;
		};

		uniform float _UseEnvironmentGradient;
		uniform float4 _NadirColour;
		uniform float4 _ZenithColour;
		uniform float4 _HorizonColour;
		uniform sampler2D _TextureSample0;
		uniform float _HorizonFalloff;
		uniform float4 _SunColour;
		uniform float _SunAtmosDensity;
		uniform float3 _SunDirection;
		uniform float _SunAtmosFalloff;
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
			float ZenithMask7 = saturate( max( break5.y , 0.0 ) );
			float4 lerpResult166 = lerp( _NadirColour , _ZenithColour , ZenithMask7);
			float WorldX86 = break5.x;
			float WorldZ87 = break5.z;
			float WorldY82 = break5.y;
			float2 appendResult93 = (float2(( atan2( WorldX86 , WorldZ87 ) / 6.28318548202515 ) , ( asin( WorldY82 ) / ( UNITY_PI / 2.0 ) )));
			float2 UVs95 = appendResult93;
			float4 tex2DNode193 = tex2D( _TextureSample0, ( UVs95 * float2( 1,0.5 ) ) );
			float NadirMask18 = saturate( ( min( break5.y , 0.0 ) * -1.0 ) );
			float HorizonFalloff54 = (0.01 + (_HorizonFalloff - 0.0) * (25.0 - 0.01) / (1.0 - 0.0));
			float smoothstepResult183 = smoothstep( 0.0 , 1.0 , pow( ( 1.0 - ( ZenithMask7 + NadirMask18 ) ) , HorizonFalloff54 ));
			float blendOpSrc200 = tex2DNode193.g;
			float blendOpDest200 = smoothstepResult183;
			float lerpBlendMode200 = lerp(blendOpDest200,(( blendOpDest200 > 0.5 ) ? ( 1.0 - 2.0 * ( 1.0 - blendOpDest200 ) * ( 1.0 - blendOpSrc200 ) ) : ( 2.0 * blendOpDest200 * blendOpSrc200 ) ),0.25);
			float HorizonMask35 = ( saturate( lerpBlendMode200 ));
			float4 lerpResult167 = lerp( lerpResult166 , _HorizonColour , HorizonMask35);
			float4 lerpResult172 = lerp( unity_AmbientGround , unity_AmbientSky , ZenithMask7);
			float4 lerpResult175 = lerp( lerpResult172 , unity_AmbientEquator , HorizonMask35);
			float4 AltitudeColours22 = (( _UseEnvironmentGradient )?( ( lerpResult175 * 0.75 ) ):( lerpResult167 ));
			float4 SunColour119 = _SunColour;
			float DetailPattern_B204 = tex2DNode193.b;
			float3 normalizeResult102 = normalize( i.viewDir );
			float dotResult104 = dot( _SunDirection , normalizeResult102 );
			float temp_output_160_0 = ( 1.0 - acos( dotResult104 ) );
			float temp_output_168_0 = (0.705 + (_SunSize - 0.0) * (0.75 - 0.705) / (1.0 - 0.0));
			float temp_output_109_0 = round( ( temp_output_160_0 * ( temp_output_168_0 * temp_output_168_0 ) ) );
			float lerpResult114 = lerp( pow( ( ( _SunAtmosDensity / 3.0 ) * max( ( 2.0 + temp_output_160_0 ) , 0.0 ) ) , (2.0 + (_SunAtmosFalloff - 0.0) * (50.0 - 2.0) / (1.0 - 0.0)) ) , temp_output_109_0 , saturate( temp_output_109_0 ));
			float blendOpSrc206 = DetailPattern_B204;
			float blendOpDest206 = lerpResult114;
			float lerpBlendMode206 = lerp(blendOpDest206,(( blendOpDest206 > 0.5 ) ? ( 1.0 - 2.0 * ( 1.0 - blendOpDest206 ) * ( 1.0 - blendOpSrc206 ) ) : ( 2.0 * blendOpDest206 * blendOpSrc206 ) ),0.5);
			float SunMask111 = ( saturate( lerpBlendMode206 ));
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
528;704;999;295;3347.005;-240.1797;2.175;True;False
Node;AmplifyShaderEditor.CommentaryNode;23;-5097.163,82.04043;Inherit;False;4063.85;792.444;;29;35;33;19;54;18;7;15;20;39;16;5;3;2;80;79;82;86;87;183;188;192;193;195;196;200;202;203;204;205;ALTITUDE GRADIENT;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldPosInputsNode;2;-5031.69,328.7534;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NormalizeNode;3;-4811.13,325.2134;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;5;-4624.004,342.19;Inherit;True;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RegisterLocalVarNode;82;-4183.808,394.2938;Inherit;False;WorldY;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;87;-4376.044,600.173;Inherit;False;WorldZ;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;86;-4369.044,232.173;Inherit;False;WorldX;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;94;-5073.044,1104.173;Inherit;False;1360.58;608.6234;;12;93;84;76;83;75;74;88;89;90;92;91;95;UVs;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;89;-5021.044,1275.173;Inherit;False;87;WorldZ;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;88;-5023.044,1165.173;Inherit;False;86;WorldX;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMinOpNode;16;-4118.744,580.1707;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PiNode;75;-4878.64,1569.677;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;83;-5012.24,1448.312;Inherit;False;82;WorldY;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;76;-4622.64,1553.677;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.ASinOpNode;74;-4620.152,1459.281;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;-3945.904,578.1259;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TauNode;92;-4639.044,1286.173;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;15;-4115.883,236.2802;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ATan2OpNode;90;-4642.044,1154.173;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;84;-4445.886,1502.479;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;91;-4435.044,1157.173;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;80;-3774.34,588.4454;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;79;-3775.032,245.0724;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;124;-5453.486,-3180.906;Inherit;False;3403.099;806.8715;;27;114;113;109;128;119;111;118;125;139;142;140;163;107;141;164;138;160;168;165;105;106;104;102;100;101;206;207;SUN;1,1,1,1;0;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;101;-5398.607,-2668.489;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;7;-3555.163,253.3413;Inherit;False;ZenithMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;93;-4191.044,1317.173;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;18;-3595.191,576.4849;Inherit;False;NadirMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;39;-3356.509,661.5132;Inherit;False;Property;_HorizonFalloff;Horizon Falloff;4;0;Create;True;0;0;0;False;0;False;0.5;0;0.01;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;100;-5389.593,-2851.472;Inherit;False;Global;_SunDirection;_SunDirection;8;0;Create;True;0;0;0;False;0;False;0.5,0.5,0.5;0.8816397,-0.4626313,-0.09318799;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NormalizeNode;102;-5200.604,-2643.249;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;19;-3311.06,366.0002;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;95;-3982.313,1318.442;Inherit;False;UVs;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TFHCRemapNode;192;-3034.661,661.5323;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0.01;False;4;FLOAT;25;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;104;-5019.27,-2853.684;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;33;-3105.498,361.2981;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;54;-2828.015,653.1127;Inherit;False;HorizonFalloff;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;195;-2533.278,639.4994;Inherit;False;95;UVs;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PowerNode;188;-2563.037,363.5174;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;106;-4795.472,-2600.073;Inherit;False;Property;_SunSize;Sun Size;5;0;Create;True;0;0;0;False;0;False;0.1;0.1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;196;-2352.138,639.5783;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;1,0.5;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ACosOpNode;105;-4863.368,-2852.838;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;183;-2340.511,355.3381;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;193;-2172.197,598.9399;Inherit;True;Property;_TextureSample0;Texture Sample 0;10;0;Create;True;0;0;0;False;0;False;-1;95fb59503f3acf040b94dae940963d73;95fb59503f3acf040b94dae940963d73;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;165;-4691.886,-2937.293;Inherit;False;Constant;_SunAtmosBoost;SunAtmosBoost;10;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;160;-4701.069,-2851.906;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;168;-4481.179,-2594.675;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0.705;False;4;FLOAT;0.75;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;138;-4890.36,-3041.503;Inherit;False;Property;_SunAtmosDensity;Sun Atmos Density;6;0;Create;True;0;0;0;False;0;False;0.5;0.1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;128;-4262.917,-2608.275;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;37;-5130.788,-2173.884;Inherit;False;2750.297;1770.45;;18;182;175;167;143;22;177;26;166;148;129;24;152;174;172;25;131;169;132;ALTITUDE COLOURS;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;164;-4417.386,-2884.989;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BlendOpsNode;200;-1791.26,351.1342;Inherit;False;Overlay;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.25;False;1;FLOAT;0
Node;AmplifyShaderEditor.FogAndAmbientColorsNode;131;-5051.167,-1926.269;Inherit;False;unity_AmbientSky;0;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;169;-5007.62,-1782.114;Inherit;False;7;ZenithMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;35;-1283.369,357.5528;Inherit;False;HorizonMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FogAndAmbientColorsNode;132;-5058.172,-2038.647;Inherit;False;unity_AmbientGround;0;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;107;-4081.562,-2765.72;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;141;-4693.225,-3135.268;Inherit;False;Property;_SunAtmosFalloff;Sun Atmos Falloff;7;0;Create;True;0;0;0;False;0;False;0.5;0.1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;140;-4276.037,-3033.671;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;3;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;163;-4256.281,-2882.036;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;139;-4060.042,-2912.092;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;172;-4725.864,-1965.9;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.TFHCRemapNode;142;-4008.445,-3119.147;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;2;False;4;FLOAT;50;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;152;-5000.241,-913.8664;Inherit;True;7;ZenithMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RoundOpNode;109;-3917.464,-2765.357;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;174;-5019.252,-1558.433;Inherit;False;35;HorizonMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;25;-5038.288,-1318.507;Inherit;False;Property;_ZenithColour;Zenith Colour;0;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FogAndAmbientColorsNode;129;-5030.141,-1676.691;Inherit;False;unity_AmbientEquator;0;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;24;-5032.082,-1122.346;Inherit;False;Property;_NadirColour;Nadir Colour;3;1;[HDR];Create;True;0;0;0;False;0;False;0.3019608,0.3019608,0.3019608,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;204;-1745.282,679.96;Inherit;False;DetailPattern_B;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;166;-4709.401,-1132.499;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;148;-4683.125,-661.3991;Inherit;True;35;HorizonMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;26;-4699.497,-878.3729;Inherit;False;Property;_HorizonColour;Horizon Colour;2;1;[HDR];Create;True;0;0;0;False;0;False;0.5,0.5,0.5,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;175;-4449.738,-1708.454;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;113;-3736.547,-2675.265;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;125;-3786.197,-2906.683;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;177;-4424.597,-1435.777;Inherit;False;Constant;_EnvLightBoost;EnvLightBoost;10;0;Create;True;0;0;0;False;0;False;0.75;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;167;-4174.484,-1121.756;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;207;-3500.326,-2527.929;Inherit;False;204;DetailPattern_B;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;114;-3577.749,-2791.624;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;182;-4071.644,-1708.875;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;118;-3562.268,-3089.458;Inherit;False;Property;_SunColour;Sun Colour;8;1;[HDR];Create;True;0;0;0;False;0;False;2,1.47451,0.972549,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BlendOpsNode;206;-3221.449,-2800.975;Inherit;False;Overlay;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;143;-3837.703,-1440.912;Inherit;False;Property;_UseEnvironmentGradient;Use Environment Gradient;9;0;Create;True;0;0;0;False;0;False;1;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;111;-2603.66,-2809.898;Inherit;False;SunMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;119;-3235.831,-3083.241;Inherit;False;SunColour;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;22;-2731.577,-1440.392;Inherit;True;AltitudeColours;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;8;-804.1685,-248.1641;Inherit;False;22;AltitudeColours;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;122;-794.5015,-141.8606;Inherit;False;119;SunColour;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;121;-789.2761,8.33394;Inherit;False;111;SunMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;203;-1749.993,592.0399;Inherit;False;DetailPattern_G;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;112;-281.6537,149.2085;Inherit;False;111;SunMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;120;-445.1964,-142.9457;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;205;-1767.262,766.3102;Inherit;False;DetailPattern_A;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;202;-1749.993,508.8294;Inherit;False;DetailPattern_R;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;-30.54006,-186.0303;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;SH_Skybox;False;False;False;False;True;True;True;True;True;True;True;True;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.5;True;False;0;True;Background;;Background;All;7;d3d9;d3d11_9x;d3d11;glcore;gles;gles3;vulkan;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;False;3;1;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;3;0;2;0
WireConnection;5;0;3;0
WireConnection;82;0;5;1
WireConnection;87;0;5;2
WireConnection;86;0;5;0
WireConnection;16;0;5;1
WireConnection;76;0;75;0
WireConnection;74;0;83;0
WireConnection;20;0;16;0
WireConnection;15;0;5;1
WireConnection;90;0;88;0
WireConnection;90;1;89;0
WireConnection;84;0;74;0
WireConnection;84;1;76;0
WireConnection;91;0;90;0
WireConnection;91;1;92;0
WireConnection;80;0;20;0
WireConnection;79;0;15;0
WireConnection;7;0;79;0
WireConnection;93;0;91;0
WireConnection;93;1;84;0
WireConnection;18;0;80;0
WireConnection;102;0;101;0
WireConnection;19;0;7;0
WireConnection;19;1;18;0
WireConnection;95;0;93;0
WireConnection;192;0;39;0
WireConnection;104;0;100;0
WireConnection;104;1;102;0
WireConnection;33;0;19;0
WireConnection;54;0;192;0
WireConnection;188;0;33;0
WireConnection;188;1;54;0
WireConnection;196;0;195;0
WireConnection;105;0;104;0
WireConnection;183;0;188;0
WireConnection;193;1;196;0
WireConnection;160;0;105;0
WireConnection;168;0;106;0
WireConnection;128;0;168;0
WireConnection;128;1;168;0
WireConnection;164;0;165;0
WireConnection;164;1;160;0
WireConnection;200;0;193;2
WireConnection;200;1;183;0
WireConnection;35;0;200;0
WireConnection;107;0;160;0
WireConnection;107;1;128;0
WireConnection;140;0;138;0
WireConnection;163;0;164;0
WireConnection;139;0;140;0
WireConnection;139;1;163;0
WireConnection;172;0;132;0
WireConnection;172;1;131;0
WireConnection;172;2;169;0
WireConnection;142;0;141;0
WireConnection;109;0;107;0
WireConnection;204;0;193;3
WireConnection;166;0;24;0
WireConnection;166;1;25;0
WireConnection;166;2;152;0
WireConnection;175;0;172;0
WireConnection;175;1;129;0
WireConnection;175;2;174;0
WireConnection;113;0;109;0
WireConnection;125;0;139;0
WireConnection;125;1;142;0
WireConnection;167;0;166;0
WireConnection;167;1;26;0
WireConnection;167;2;148;0
WireConnection;114;0;125;0
WireConnection;114;1;109;0
WireConnection;114;2;113;0
WireConnection;182;0;175;0
WireConnection;182;1;177;0
WireConnection;206;0;207;0
WireConnection;206;1;114;0
WireConnection;143;0;167;0
WireConnection;143;1;182;0
WireConnection;111;0;206;0
WireConnection;119;0;118;0
WireConnection;22;0;143;0
WireConnection;203;0;193;2
WireConnection;120;0;8;0
WireConnection;120;1;122;0
WireConnection;120;2;121;0
WireConnection;205;0;193;4
WireConnection;202;0;193;1
WireConnection;0;2;120;0
ASEEND*/
//CHKSM=4ADBF4ACA1C05E28C1CC279ADBE6CE727BE76B5F