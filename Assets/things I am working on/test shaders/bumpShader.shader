Shader "catlike/bump"
{
	Properties
	{
		_MainTex ("Albedo", 2D) = "white" {}
		_Tint("Tint",Color)=(1,1,1,1)
		[NoScaleOffset] _NormalMap("Heights",2D)= "bump"{}
		_BumpScale("Bump Scale",Float)=1
		[Gamma]_Metallic("Metallic",Range(0,1))=0
		_Smoothness("Smoothness",Range(0,1))=0.5
		_DetailTex ("Detail Texture",2D)="gray"{}
		[NoScaleOffset] _DetailNormalMap("Detail normals",2D)= "bump"{}
		_DetailBumpScale("Detail Bump Scale",Float)=1
	}
	SubShader
	{
		

		Pass
		{

			Tags{"LightMode"="ForwardBase"}
		

			CGPROGRAM



			#pragma target 3.0
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

			#pragma multi_compile_fwdadd

			#pragma vertex vert
			#pragma fragment frag


			#include "My Lighting.cginc"

			ENDCG

		}
			
		
	}
}
