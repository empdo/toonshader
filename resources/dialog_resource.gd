extends Resource
class_name DialogResource

@export var lines: Array[String] = []
@export var line_audio: Array[AudioStream] = []  # Audio per line (can be null for individual lines)
@export var prioritized: bool = false  # If true, clears queue and plays immediately
