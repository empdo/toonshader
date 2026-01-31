extends Resource
class_name DialogResource

@export var lines: Array[String] = []
@export var characters_per_second: float = -1.0  # -1 means use default
@export var audio: AudioStream = null
@export var prioritized: bool = false  # If true, clears queue and plays immediately
