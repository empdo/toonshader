extends MeshInstance3D

## Dra in noden som ska agera ljuskälla här (t.ex. en Marker3D)
@export var light_target: Node3D 

var shader_mat: ShaderMaterial

func _ready() -> void:
	# 1. Hämta bas-materialet (det vanliga materialet)
	var base_mat = get_active_material(0)
	
	if base_mat:
		# 2. Kolla om det finns ett Next Pass och om det är en Shader
		if base_mat.next_pass is ShaderMaterial:
			shader_mat = base_mat.next_pass
			print("ShaderMaterial hittat i Next Pass!")
		else:
			push_error("FEL: Inget ShaderMaterial hittades i Next Pass på " + name)
	else:
		push_error("FEL: Inget bas-material hittades på " + name)

func _process(_delta: float) -> void:
	if light_target and shader_mat:
		# Uppdatera positionen i shadern
		shader_mat.set_shader_parameter("light_position_ws", light_target.global_position)
