Shader "Unlit/textured with detail"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_DetailTex ("Detail Texture", 2D)="gray"{}
		_Tint("tint",Color)=(1,1,1,1)
	}
		SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float2 uvDetail:TEXCOORD1;
			};

			sampler2D _MainTex,_DetailTex;
			float4 _MainTex_ST,_DetailTex_ST;
			float4 _Tint;
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.uvDetail = TRANSFORM_TEX(v.uv,_DetailTex);
				return o;
			}
		
			float4 frag (v2f i) : SV_Target
			{
				// sample the texture
				float4 col=tex2D(_MainTex,i.uv)*_Tint;
				col*=tex2D(_MainTex,i.uvDetail)*2;
				// apply fog
				return col;
			}
			ENDCG
		}
	}
	
}
