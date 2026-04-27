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
    %CheckBakeHitboxes.disabled = true

    self.anim_player.stop()
    self.anim_player.clear_queue()

    var velocity_data: Dictionary = {}
    var hurtbox_data: Dictionary = {}
    
    self.fighter.record_velocity_data.connect(self._on_fighter_record_velocity_data.bind(velocity_data))
    if %CheckBakeHitboxes.button_pressed:
        self.fighter.record_hurtbox_data.connect(self._on_fighter_record_hurtbox_data.bind(hurtbox_data))

    self.anim_player.current_animation_changed.connect(self._on_anim_player_current_animation_changed)
    self.anim_player.animation_finished.connect(self._on_anim_player_animation_finished.bind(velocity_data, hurtbox_data))

    self.anim_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    self.fighter._velocity_bake_mode = true
    if %CheckBakeHitboxes.button_pressed:
        self.fighter._hurtbox_bake_mode = true

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

func _on_fighter_record_hurtbox_data(data: Array, hurtbox_data: Dictionary) -> void:
    var frame: int = roundi(self.anim_player.current_animation_position * 60)
    if hurtbox_data.has(self.anim_player.current_animation) && \
        hurtbox_data[self.anim_player.current_animation].has(str(frame)):
        return

    if !hurtbox_data.has(self.anim_player.current_animation):
        hurtbox_data[self.anim_player.current_animation] = {}

    var data_min: Array = []
    for shape: FECollisionShape in data:
        data_min.append({
            "radius": shape.fixed_sphere_radius,
            "body_part": shape.body_part,
            "position": FixedVector3.from_vec3(shape.global_position)
        })
    
    hurtbox_data[self.anim_player.current_animation][str(frame)] = data_min

func _on_anim_player_current_animation_changed(anim_name: StringName) -> void:
    var anim: Animation = self.anim_player.get_animation(anim_name)
    if anim.loop_mode == Animation.LOOP_LINEAR:
        anim.loop_mode = Animation.LOOP_NONE

func _on_anim_player_animation_finished(anim_name: StringName, velocity_data: Dictionary, hurtbox_data: Dictionary) -> void:
    self.update_progress_label()

    if self.looping_anims.has(anim_name):
        self.anim_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR

    if self.anim_player.is_playing():
        return

    self.fighter._velocity_bake_mode = false
    self.fighter._hurtbox_bake_mode = false

    var toaster: EditorToaster = EditorInterface.get_editor_toaster()

    toaster.push_toast("Compiling Velocity Data...")

    var vel_res: FighterResource = FighterResource.new()
    vel_res.dict = velocity_data 
    vel_res.take_over_path("res://character/anim_data/%s_velocity.tres" % self.fighter.fighter_name)
    self.fighter.animation_velocity_data = vel_res

    toaster.push_toast("Compiled. Saving Velocity Data to disk...")
    ResourceSaver.save(self.fighter.animation_velocity_data, "res://character/anim_data/%s_velocity.tres" % self.fighter.fighter_name)
    toaster.push_toast("Saved Velocity data to disk.")
    
    if %CheckBakeHitboxes.button_pressed:
        toaster.push_toast("Compiling Hurtbox Data...")
        var hurt_res: FighterResource = FighterResource.new()
        hurt_res.dict = hurtbox_data
        hurt_res.take_over_path("res://character/anim_data/%s_hurtbox.tres" % self.fighter.fighter_name)
        self.fighter.animation_hurtbox_data = hurt_res

        toaster.push_toast("Compiled. Saving Hurtbox data to disk...")
        ResourceSaver.save(self.fighter.animation_hurtbox_data, "res://character/anim_data/%s_hurtbox.tres" % self.fighter.fighter_name)
        toaster.push_toast("Saved Hurtbox data to disk.")

    self.anim_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE

    self.looping_anims.clear()

    %BakeButton.disabled = false
    %ExitButton.disabled = false
    %CheckBakeHitboxes.disabled = false
    $Label.text = "Bake complete!!!"

func _on_bake_button_button_up() -> void:
    self.bake_velocity_process()
    
func _on_exit_button_button_up() -> void:
    if self.fighter.record_velocity_data.is_connected(self._on_fighter_record_velocity_data):
        self.fighter.record_velocity_data.disconnect(self._on_fighter_record_velocity_data)
    if self.fighter.record_hurtbox_data.is_connected(self._on_fighter_record_hurtbox_data):
        self.fighter.record_hurtbox_data.disconnect(self._on_fighter_record_hurtbox_data)
    if self.anim_player.animation_finished.is_connected(self._on_anim_player_animation_finished):
        self.anim_player.animation_finished.disconnect(self._on_anim_player_animation_finished)
    if self.anim_player.current_animation_changed.is_connected(self._on_anim_player_current_animation_changed):
        self.anim_player.current_animation_changed.disconnect(self._on_anim_player_current_animation_changed)

    self.request_dock_removal.emit(self)
