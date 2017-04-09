Shader "Unlit/something"
{

	Properties
	{
		_Color("Color",Color) = (1,1,1,1)
	}
	SubShader
	{


		Pass
		{

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			struct v2f
			{
				float2 uv:TEXCOORD0;
				float4 position : SV_POSITION;
			};

			v2f vert(float4 vertex:POSITION, float2 uv : TEXCOORD0)
			{
				v2f o;
				o.position = UnityObjectToClipPos(vertex);
				o.uv=uv;
				return o;
			}
			fixed4 _Color;
			fixed4 frag(v2f i) :SV_TARGET
			{
				return fixed4(i.uv,0,0)+_Color;
			}
				ENDCG
		}	 
	}
}
