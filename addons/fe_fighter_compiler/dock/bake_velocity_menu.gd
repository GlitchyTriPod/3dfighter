@tool
extends VBoxContainer
class_name BakeVelocityMenu

@onready var anim_player: NetworkAnimationPlayer:
    get:
        return EditorInterface.get_edited_scene_root().get_node("NetworkAnimationPlayer")

@onready var fighter: Fighter:
    get:
        return EditorInterface.get_edited_scene_root()

var looping_anims: PackedStringArray = PackedStringArray()

signal request_dock_removal(node: BakeVelocityMenu)

### METHODS ###

func bake_velocity_process() -> void:
    %ProgressBar.value = 0
    %ProgressBar.max_value = self.anim_player.get_animation_list().size()
    %Label.text = "Bake in progress.\n[color=red]DO NOT TOUCH ANYTHING UNTIL COMPLETE.[/color]"
    %BakeButton.disabled = true
    %ExitButton.disabled = true

    self.anim_player.stop()
    self.anim_player.clear_queue()

    var velocity_data: Dictionary = {}
    
    self.fighter.record_velocity_data.connect(self._on_fighter_record_velocity_data.bind(velocity_data))
    self.anim_player.current_animation_changed.connect(self._on_anim_player_current_animation_changed)
    self.anim_player.animation_finished.connect(self._on_anim_player_animation_finished.bind(velocity_data))

    self.anim_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    self.fighter._velocity_bake_mode = true

    self.anim_player.play(self.anim_player.get_animation_list().get(0))
    self.anim_player.seek(0, true)

    for anim: String in self.anim_player.get_animation_list():
        if self.anim_player.get_animation(anim).loop_mode == Animation.LOOP_LINEAR:
            self.looping_anims.append(anim)

        if self.anim_player.current_animation == anim:
            continue
        self.anim_player.queue(anim)


func update_progress_label() -> void:
    var anim_list: PackedStringArray = self.anim_player.get_animation_list()
    var progress: int = anim_list.find(self.anim_player.current_animation)
    %ProgressLabel.text = "%s (%d/%d)" % [self.anim_player.current_animation,
        progress if progress != -1 else anim_list.size(), 
        anim_list.size()]
    %ProgressBar.value = progress

### LISTENERS ###

func _on_fighter_record_velocity_data(data: FixedVector3, velocity_data: Dictionary) -> void:
    var frame: int = roundi(self.anim_player.current_animation_position * 60)
    if velocity_data.has(self.anim_player.current_animation) && \
        velocity_data[self.anim_player.current_animation].has(str(frame)):

        return
        
    if !velocity_data.has(self.anim_player.current_animation):
        velocity_data[self.anim_player.current_animation] = {}

    velocity_data[self.anim_player.current_animation][str(frame)] = data

func _on_anim_player_current_animation_changed(anim_name: StringName) -> void:
    var anim: Animation = self.anim_player.get_animation(anim_name)
    if anim.loop_mode == Animation.LOOP_LINEAR:
        anim.loop_mode = Animation.LOOP_NONE

func _on_anim_player_animation_finished(anim_name: StringName, velocity_data: Dictionary) -> void:
    self.update_progress_label()

    if self.looping_anims.has(anim_name):
        self.anim_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR

    if self.anim_player.is_playing():
        return

    self.fighter._velocity_bake_mode = false
    self.fighter.animation_velocity_data = velocity_data
    self.anim_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE

    self.looping_anims.clear()

    %BakeButton.disabled = false
    %ExitButton.disabled = false
    $Label.text = "Bake complete!!!"

func _on_bake_button_button_up() -> void:
    self.bake_velocity_process()
    
func _on_exit_button_button_up() -> void:
    if self.fighter.record_velocity_data.is_connected(self._on_fighter_record_velocity_data):
        self.fighter.record_velocity_data.disconnect(self._on_fighter_record_velocity_data)
    if self.anim_player.animation_finished.is_connected(self._on_anim_player_animation_finished):
        self.anim_player.animation_finished.disconnect(self._on_anim_player_animation_finished)
    if self.anim_player.current_animation_changed.is_connected(self._on_anim_player_current_animation_changed):
        self.anim_player.current_animation_changed.disconnect(self._on_anim_player_current_animation_changed)

    self.request_dock_removal.emit(self)
