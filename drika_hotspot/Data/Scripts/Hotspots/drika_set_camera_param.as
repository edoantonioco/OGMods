enum camera_params {	tint = 0,
						vignette_tint = 1,
						fov = 2,
						dof = 3
					};

class DrikaSetCameraParam : DrikaElement{
	int current_type;
	string param_name;

	string string_param_before;
	string string_param_after;

	array<float> float_array_param_before;
	array<float> float_array_param_after;

	float float_param_before;
	float float_param_after;

	vec3 vec3_param_before;
	vec3 vec3_param_after;

	camera_params camera_param;
	param_types param_type;

	array<int> float_parameters = {fov};
	array<int> vec3_color_parameters = {tint, vignette_tint};
	array<int> float_array_parameters = {dof};

	array<string> param_names = {	"Tint",
	 								"Vignette Tint",
									"FOV",
									"DOF"
								};

	DrikaSetCameraParam(int _camera_param = 0, string _param_after = "1,1,1"){
		camera_param = camera_params(_camera_param);
		current_type = camera_param;
		param_name = param_names[current_type];

		drika_element_type = drika_set_camera_param;
		has_settings = true;
		SetParamType();
		GetBeforeParam();
		string_param_after = _param_after;
		InterpParam();
	}

	void SetParamType(){
		if(float_parameters.find(camera_param) != -1){
			param_type = float_param;
		}else if(vec3_color_parameters.find(camera_param) != -1){
			param_type = vec3_color_param;
		}else if(float_array_parameters.find(camera_param) != -1){
			param_type = float_array_param;
		}
	}

	void InterpParam(){
		if(param_type == vec3_color_param){
			vec3_param_after = StringToVec3(string_param_after);
		}else if(param_type == float_param){
			float_param_after = atof(string_param_after);
		}else if(param_type == float_array_param){
			float_array_param_after = StringToFloatArray(string_param_after);
		}
	}

	string GetSaveString(){
		string save_string;
		if(param_type == vec3_color_param){
			save_string = Vec3ToString(vec3_param_after);
		}else if(param_type == float_param){
			save_string = "" + float_param_after;
		}else if(param_type == float_array_param){
			save_string = FloatArrayToString(float_array_param_after);
		}
		return "set_camera_param" + param_delimiter + int(camera_param) + param_delimiter + save_string;
	}

	string GetDisplayString(){
		return "SetCameraParam " + param_name + " " + string_param_after;
	}

	void ApplySettings(){
		UpdateDisplayString();
	}

	void UpdateDisplayString(){
		if(param_type == float_param){
			string_param_after = "" + float_param_after;
		}else if(param_type == float_array_param){
			string_param_after = "";
			for(uint i = 0; i < float_array_param_after.size(); i++){
				string_param_after += ((i == 0)?"":" ") + float_array_param_after[i];
			}
		}else if(param_type == vec3_color_param){
			string_param_after = vec3_param_after.x + "," + vec3_param_after.y + "," + vec3_param_after.z;
		}
	}

	void AddSettings(){
		if(ImGui_Combo("Param Type", current_type, param_names)){
			camera_param = camera_params(current_type);
			param_name = param_names[current_type];
			SetParamType();
			GetBeforeParam();
			if(param_type == float_param){
				float_param_after = float_param_before;
			}else if(param_type == float_array_param){
				float_array_param_after = float_array_param_before;
			}else if(param_type == vec3_color_param){
				vec3_param_after = vec3_param_before;
			}
			UpdateDisplayString();
		}

		if(param_type == float_param){
			ImGui_SliderFloat("After", float_param_after, -1000.0f, 1000.0f, "%.4f");
		}else if(param_type == vec3_color_param){
			ImGui_ColorPicker3("After", vec3_param_after, 0);
		}else if(param_type == float_array_param){
			ImGui_SliderFloat("Near Blur", float_array_param_after[0], -1000.0f, 1000.0f, "%.4f");
			ImGui_SliderFloat("Near Dist", float_array_param_after[1], -1000.0f, 1000.0f, "%.4f");
			ImGui_SliderFloat("Near Transition", float_array_param_after[2], -1000.0f, 1000.0f, "%.4f");
			ImGui_SliderFloat("Far Blur", float_array_param_after[3], -1000.0f, 1000.0f, "%.4f");
			ImGui_SliderFloat("Far Dist", float_array_param_after[4], -1000.0f, 1000.0f, "%.4f");
			ImGui_SliderFloat("Far Transition", float_array_param_after[5], -1000.0f, 1000.0f, "%.4f");
		}
	}

	void GetBeforeParam(){
		switch(camera_param){
			case tint:
				vec3_param_before = camera.GetTint();
				break;
			case vignette_tint:
				vec3_param_before = camera.GetVignetteTint();
				break;
			case fov:
				float_param_before = camera.GetFOV();
				break;
			case dof:
				float_array_param_before = {0.0f,0.0f,0.0f,0.0f,0.0f,0.0f};
				break;
			default:
				Log(warning, "Found a non standard parameter type. " + param_type);
				break;
		}
	}

	bool Trigger(){
		return SetParameter(false);
	}

	bool SetParameter(bool reset){
		switch(camera_param){
			case tint:
				Log(info, "Setting tint to " + vec3_param_after.x + " " + vec3_param_after.y + " " + vec3_param_after.z);
				camera.SetTint(reset?vec3_param_before:vec3_param_after);
				break;
			case vignette_tint:
				camera.SetVignetteTint(reset?vec3_param_before:vec3_param_after);
				break;
			case fov:
				camera.SetFOV(reset?float_param_before:float_param_after);
				break;
			case dof:
				{
					array<float>@ new_setting = reset?float_array_param_before:float_array_param_after;
					camera.SetDOF(new_setting[0],new_setting[1],new_setting[2],new_setting[3],new_setting[4],new_setting[5]);
				}
				break;
			default:
				Log(warning, "Found a non standard parameter type. " + param_type);
				break;
		}
		return true;
	}

	void Reset(){
		SetParameter(true);
	}
}
