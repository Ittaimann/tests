using UnityEngine;
using UnityEditor;

public class MyLightingShaderGUI: ShaderGUI{
	Material target;
	MaterialEditor editor;
	MaterialProperty[] properties;
	static ColorPickerHDRConfig emissionConfig =new ColorPickerHDRConfig(0f, 99f, 1f / 99f, 3f);
	public override void OnGUI(
	MaterialEditor editor, MaterialProperty[] properties)
	{
		this.target=editor.target as Material;
		this.editor=editor;
		this.properties=properties;
		DoMain();
		DoSecondary();

	}

	void DoMain()
	{
		GUILayout.Label("Main Maps", EditorStyles.boldLabel);

		MaterialProperty mainTex=FindProperty("_MainTex",properties);
		editor.TexturePropertySingleLine(MakeLabel(mainTex,"Albedo(RGB)"),mainTex,FindProperty("_Tint") );


		DoMetallic();
		DoSmooth();
		DoNormals();
		DoEmission();

		editor.TextureScaleOffsetProperty(mainTex);

	}

	void DoSecondary(){
		GUILayout.Label("Secondary Maps",EditorStyles.boldLabel);
		MaterialProperty detailTex=FindProperty("_DetailTex");
		editor.TexturePropertySingleLine(MakeLabel(detailTex,
			"Albedo (RGB) multiplied by 2")
			,detailTex
			);
		DoSecondaryNormals();
		editor.TextureScaleOffsetProperty(detailTex);
	}

	void DoNormals(){
		MaterialProperty map = FindProperty("_NormalMap");
		editor.TexturePropertySingleLine(
					MakeLabel(map),map,
					map.textureValue?FindProperty("_BumpScale"):null
		);
	}
	void DoSmooth(){
		SmoothnessSource Source =SmoothnessSource.Uniform;
		if(IsKeywordEnabled("_SMOOTHNESS_ALBEDO")){
			Source=SmoothnessSource.Albedo;
		}
		else if(IsKeywordEnabled("_SMOOTHNESS_METALLIC")){
			Source= SmoothnessSource.Metallic;
		}
		MaterialProperty slider=FindProperty("_Smoothness");
		EditorGUI.indentLevel+=2;
		editor.ShaderProperty(slider,MakeLabel(slider));
		EditorGUI.indentLevel+=1;
		EditorGUI.BeginChangeCheck();
		Source=(SmoothnessSource)EditorGUILayout.EnumPopup(MakeLabel("Source"),Source);
		if(EditorGUI.EndChangeCheck()){
			RecordAction("Smoothness Source");
			SetKeyword("_SMOOTHNESS_ALBEDO",Source==SmoothnessSource.Albedo);
			SetKeyword("_SMOOTHNESS_METALLIC",Source==SmoothnessSource.Metallic);
		}

		EditorGUI.indentLevel-=2;
	}
	void DoMetallic(){
		MaterialProperty map=FindProperty("_MetallicMap");
		EditorGUI.BeginChangeCheck();
		editor.TexturePropertySingleLine(
			MakeLabel(map,"Metallic(R)"),map,map.textureValue? null:FindProperty("_Metallic")
			);
		if(EditorGUI.EndChangeCheck()){
			SetKeyword("_METALLIC_MAP",map.textureValue);
		}

	}

	void DoSecondaryNormals(){
		MaterialProperty map = FindProperty("_DetailNormalMap");
		editor.TexturePropertySingleLine(MakeLabel(map),map,
			map.textureValue ? FindProperty( "_detailBumpScale"):null);
	}

	void DoEmission(){
		MaterialProperty map=FindProperty("_EmissionMap");
		EditorGUI.BeginChangeCheck();

		editor.TexturePropertyWithHDRColor(
			MakeLabel("Emission (RGB)"),map,FindProperty("_Emission"),emissionConfig,false );

		if(EditorGUI.EndChangeCheck()){
			SetKeyword("_EMISSION_MAP",map.textureValue);
		}
	}

	void SetKeyword(string keyword, bool state){
		if(state){
			target.EnableKeyword(keyword);
		}
		else{
			target.DisableKeyword(keyword);
		}
	}

	enum SmoothnessSource{
		Uniform,  Albedo, Metallic
	}

	bool IsKeywordEnabled(string keyword){
		return target.IsKeywordEnabled(keyword);
	}

	MaterialProperty FindProperty(string name){
		return FindProperty (name,properties);
	}


	static GUIContent staticLabel =new GUIContent();

	static GUIContent MakeLabel (string text, string tooltip=null)
	{
		staticLabel.text=text;
		staticLabel.tooltip=tooltip;
		return staticLabel;
	}

	static GUIContent MakeLabel(MaterialProperty property, string tooltip=null)
	{
		staticLabel.text=property.displayName;
		staticLabel.tooltip=tooltip;
		return staticLabel;
	}

	void RecordAction(string label){
		editor.RegisterPropertyChangeUndo(label);
	}
}
