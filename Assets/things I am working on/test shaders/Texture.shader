Shader "self/Texture"
{
	Properties{
		_MainTex("MainTexture",2D) = "Black"{}
		_Color("Color",Color) = (1,1,1,1)
	}

		SubShader
		{
			Tags  {"RenderType" = "Opaque"}
			LOD 100

			Pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#include "UnityCG.cginc"

				struct v2f
				{
					float2 uv : TEXCOORD0;
					float4 pos : SV_POSITION;
				};


				sampler2D _MainTex;
				float4 _Color;

				v2f vert(appdata_base v)
				{
					v2f o;
					o.uv = v.texcoord;
					o.pos = UnityObjectToClipPos(v.vertex);
					return o;
				}
				fixed4 frag(v2f i): SV_TARGET
				{
					fixed4 col = tex2D(_MainTex, i.uv);
					return col;
				}
				ENDCG
				
		}
	}
}
