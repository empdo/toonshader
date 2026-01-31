extends Node

signal dialog_requested(dialog: DialogResource)
signal dialog_stop_requested
signal dialog_finished(dialog: DialogResource)

const DEFAULT_CHARS_PER_SECOND: float = 30.0

var queue: Array[DialogResource] = []
var current: DialogResource = null
var _ui_ready: bool = false

func play(dialog: DialogResource) -> void:
	if dialog.prioritized:
		queue.clear()
		if current:
			dialog_stop_requested.emit()
		current = dialog
		if _ui_ready:
			dialog_requested.emit(dialog)
	else:
		queue.append(dialog)
		_next()

func stop() -> void:
	queue.clear()
	if current:
		dialog_stop_requested.emit()
		current = null

func _on_finished() -> void:
	var finished = current
	current = null
	dialog_finished.emit(finished)
	_next()

func _next() -> void:
	if current != null or queue.is_empty():
		return
	current = queue.pop_front()
	if _ui_ready:
		dialog_requested.emit(current)

# Anropas av DialogUI när den är redo
func ui_ready() -> void:
	_ui_ready = true
	if current:
		dialog_requested.emit(current)
