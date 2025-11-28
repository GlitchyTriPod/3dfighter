extends "res://models/testing/face_mouth_rig.gd"

@export var thruster_override := false

@export_range(0, 5) var thruster_override_power := 4

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	super(_delta)
	if !self.thruster_override: return
	var thrusters = []

	thrusters += self.skeleton_node.get_node("ThrusterBone").get_children()
	thrusters += self.skeleton_node.get_node("RightForearmBone").get_children()
	thrusters += self.skeleton_node.get_node("LeftForearmBone").get_children()
	thrusters += self.skeleton_node.get_node("LeftFootBone").get_children()
	thrusters += self.skeleton_node.get_node("RightFootBone").get_children()

	for i in thrusters:
		i.trail_life = self.thruster_override_power
