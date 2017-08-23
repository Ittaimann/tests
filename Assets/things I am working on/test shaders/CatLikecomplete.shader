Shader "catlike/CatLikecomplete"
{
	Properties
	{
		_MainTex ("Albedo", 2D) = "white" {}
		_Tint("Tint",Color)=(1,1,1,1)
		[NoScaleOffset] _NormalMap("Heights",2D)= "bump"{}
		_BumpScale("Bump Scale",Float)=1
		[NoScaleOffset] _MetallicMap ("Metallic",2D)="White"{}
		[Gamma] _Metallic("Metallic",Range(0,1))=0
		_Smoothness("Smoothness",Range(0,1))=0.5
		_DetailTex ("Detail Albedo",2D)="gray"{}
		[NoScaleOffset] _DetailNormalMap("Detail normals",2D)= "bump"{}
		_DetailBumpScale("Detail Bump Scale",Float)=1

		[NoScaleOffset] _EmissionMap("Emission",2D)="black"{}
		_Emission("Emission",Color)=(0,0,0)
	}
	SubShader
	{


		Pass
		{

			Tags{"LightMode"="ForwardBase"}


			CGPROGRAM



			#pragma target 3.0
			#pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
			#pragma shader_feature _EMISSION_MAP
			#pragma multi_compile _ SHADOWS_SCREEN
			#pragma multi_compile _ VERTEXLIGHT_ON
			#pragma vertex vert
			#pragma fragment frag

			#define FORWARD_BASE_PASS
			#include "My Lighting.cginc"

			ENDCG

		}
		Pass
		{

			Tags{"LightMode"="ForwardAdd"}

			Blend one one
			ZWrite off
			CGPROGRAM

			#pragma target 3.0
			#pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC


			#pragma multi_compile_fwdadd_fullshadows

			#pragma vertex vert
			#pragma fragment frag


			#include "My Lighting.cginc"

			ENDCG

		}
		Pass{
			Tags{"LightMode"="ShadowCaster"}
			CGPROGRAM
			#pragma target 3.0

			#pragma multi_compile_shadowcaster

			#pragma vertex MyShadowVertexProgram
			#pragma fragment MyShadowFragmentProgram

			#include "My Shadows.cginc"

			ENDCG
		}




		}
		CustomEditor "MyLightingShaderGUI"

}
