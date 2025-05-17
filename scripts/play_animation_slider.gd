extends Control

class_name AnimationSlider
@export var num_steps: int = 0
var step_rate: float = 0
var speed_up := 1


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func set_step_rate(value: float) -> void:
	step_rate = value
func tick() -> void:
	$Slider.value += step_rate
func reset() -> void:
	$Slider.value = 0
func _on_play_btn_pressed() -> void:
	# animation_state = ANIMATION_STATE.STARTED
	# animation_started.emit()
	# print("ciao")
	get_tree().call_group("animation", "animation_started")
	$PlayBtn.disabled = true
	$PauseBtn.disabled = false
	$StopBtn.disabled = false
func _on_pause_btn_pressed() -> void:
	# animation_state = ANIMATION_STATE.PAUSED
	# animation_paused.emit()
	get_tree().call_group("animation", "animation_paused")
	$PlayBtn.disabled = false
	$PauseBtn.disabled = true
	$StopBtn.disabled = false
func _on_stop_btn_pressed() -> void:
	# animation_state = ANIMATION_STATE.STOPPED
	# animation_stopped.emit()
	get_tree().call_group("animation", "animation_stopped")
	$PlayBtn.disabled = false
	$PauseBtn.disabled = true
	$StopBtn.disabled = true
func _on_speed_up_btn_pressed() -> void:
	match speed_up:
		1:
			$SpeedUpBtn.text = "Speed Up 2x"
			speed_up = 2
		2:
			$SpeedUpBtn.text = "Speed Up 3x"
			speed_up = 3
		3:
			$SpeedUpBtn.text = "Speed Up"
			speed_up = 1
	get_tree().call_group("animation", "speed_up", speed_up)
