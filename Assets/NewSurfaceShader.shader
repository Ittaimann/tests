Shader "Custom/NewSurfaceShader" {
	Properties{
	_Color("DICKSDICSK",Color)=(1,1,.5,1)}
	SubShader{
		
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