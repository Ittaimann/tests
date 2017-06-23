Shader "Unlit/personaltest"
{
	Properties
	{
		_color("Color",Color)=(1,1,1,1)
		_MainTex("MainTex",2D)="white"{}
		_Metallic("Metallic",Range(0,1))=0
		_smoothness("Smoothness",Range(0,1))=0.5
	}

	SubShader
	{

		Pass
		{
			Tags{"LightMode"="ForwardBase"}
		CGPROGRAM

		#pragma target 3.0 
		#pragma vertex vert
		#pragma fragment frag

		#include "UnityPBSLighting.cginc"
		


		struct appdata
		{
			float4 position:POSITION;
			float2 uv:TEXCOORD0;
			float3 normal:NORMAL;

		};

		struct v2f
		{
			float4 position:POSITION;
			float2 uv:TEXCOORD0;
			float3 normal:TEXCOORD1;
			float3 worldPos:TEXCOORD2;
		};
		
		sampler2D _MainTex;
		float4 _MainTex_ST;
		float4 _color;
		float _smoothness;
		float _Metallic;

		v2f vert(appdata i)
		{
			v2f o;
			o.position=UnityObjectToClipPos(i.position);
			o.normal=UnityObjectToWorldNormal(i.normal);
			o.worldPos=mul(unity_ObjectToWorld,i.position);
			o.uv=TRANSFORM_TEX(i.uv,_MainTex);
		//	o.normal=normalize(i.normal);
			return o;
		};
	

		float4 frag(v2f i) : SV_TARGET 
		{
			i.normal=normalize(i.normal);
			float3 lightDir = _WorldSpaceLightPos0.xyz;
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

				float3 lightColor = _LightColor0.rgb;
				float3 albedo = tex2D(_MainTex, i.uv).rgb * _color.rgb;

				float3 specularTint;
				float oneMinusReflectivity;
				albedo = DiffuseAndSpecularFromMetallic(
					albedo, _Metallic, specularTint, oneMinusReflectivity
				);
				
				UnityLight light;
				light.color = lightColor;
				light.dir = lightDir;
				light.ndotl = DotClamped(i.normal, lightDir);
				UnityIndirect indirectLight;
				indirectLight.diffuse = 0;
				indirectLight.specular = 0;

				return UNITY_BRDF_PBS(
					albedo, specularTint,
					oneMinusReflectivity, _smoothness,
					i.normal, viewDir,
					light, indirectLight
				);
			//return pow(DotClamped(halfVector,o.normal),_smoothness*100);
		};

		ENDCG
		}
	}
}


