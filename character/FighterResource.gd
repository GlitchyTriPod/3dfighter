@tool
# Catch-all class for any fighter-related resource that needs to be saved to file to cut down on save/load times
extends Resource
class_name FighterResource

@export_storage var dict: Dictionary[StringName, Variant] = {}