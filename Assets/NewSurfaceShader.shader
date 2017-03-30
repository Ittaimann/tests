Shader "Custom/NewSurfaceShader" {
	Properties{
		_MainTex("albedo texture",2D)= "white"{}
	}
	SubShader{
		Tags{"RenderType"="Opaque"}

		Pass
		{
			Material
			{
				Diffuse[_Color]
			}
		Lighting On

		}
		
	
	}




	Fallback "Diffuse"
}