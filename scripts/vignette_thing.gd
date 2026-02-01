extends TextureRect

var start_radius = 0.0
var mat = material as ShaderMaterial

func _ready():
	var mat = material as ShaderMaterial
	start_radius = mat.get_shader_parameter("vignette_radius")


func _process(delta):
	var v
	v = Globals.time_used_seeingmask / Globals.max_time_used_seeingmask_until_collapse
	v = lerp(start_radius, 0.0, v)
	mat.set_shader_parameter("vignette_radius", v)
