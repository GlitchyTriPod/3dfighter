extends Node

const DummyNetworkAdapter = preload("res://addons/delta_rollback/DummyNetworkAdaptor.gd")

@onready var main_menu: HBoxContainer = $CanvasLayer/MainMenu
@onready var connection_panel: Window = $CanvasLayer/ConnectionPanel
@onready var host_field: LineEdit = $CanvasLayer/ConnectionPanel/GridContainer/HostField
@onready var port_field: LineEdit = $CanvasLayer/ConnectionPanel/GridContainer/PortField
@onready var message_label: Label = $CanvasLayer/MessageLabel
@onready var sync_lost_label: Label = $CanvasLayer/SyncLostLabel

@onready var stage: Stage = %Stage

const LOG_FILE_DIRECTORY: String = "user://detailed_logs"

var logging_enabled: bool = false

func _ready() -> void:
	multiplayer.peer_connected.connect(self._on_network_peer_connected)
	multiplayer.peer_disconnected.connect(self._on_network_peer_disconnected)
	multiplayer.server_disconnected.connect(self._on_network_server_disconnected)

	SyncManager.sync_started.connect(self._on_SyncManager_sync_started)
	SyncManager.sync_stopped.connect(self._on_SyncManager_sync_stopped)
	SyncManager.sync_lost.connect(self._on_SyncManager_sync_lost)
	SyncManager.sync_regained.connect(self._on_SyncManager_sync_regained)
	SyncManager.sync_error.connect(self._on_SyncManager_sync_error)

func _on_server_button_pressed() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_server(int(port_field.text), 1)
	multiplayer.multiplayer_peer = peer
	self.connection_panel.visible = false
	self.main_menu.visible = false
	self.message_label.text = "Listening for connection..."

func _on_client_button_pressed() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_client(host_field.text, int(port_field.text))
	multiplayer.multiplayer_peer = peer
	self.connection_panel.visible = false
	self.main_menu.visible = false
	self.message_label.text = "Connecting to host..."

func _on_network_peer_connected(_peer_id: int) -> void:
	self.message_label.text = "Connected!"
	SyncManager.add_peer(_peer_id)

	self.stage.fighter_message_bus.player_1.set_multiplayer_authority(1)
	self.stage.input_listener.set_multiplayer_authority(1)
	if multiplayer.is_server():
		self.stage.fighter_message_bus.player_2.set_multiplayer_authority(_peer_id)
	else:
		self.stage.fighter_message_bus.player_2.set_multiplayer_authority(multiplayer.get_unique_id())

	if multiplayer.is_server():
		message_label.text = "Starting session..."

		await get_tree().create_timer(2.0).timeout
		SyncManager.start()

func _on_network_peer_disconnected(_peer_id:int) -> void:
	self.message_label.text = "Disconnected"
	SyncManager.remove_peer(_peer_id)

func _on_network_server_disconnected() -> void:
	self._on_network_peer_disconnected(1)

func _on_reset_button_pressed() -> void:
	SyncManager.stop()
	SyncManager.clear_peers()
	var peer: MultiplayerPeer = multiplayer.multiplayer_peer
	if peer:
		peer.close()
	get_tree().reload_current_scene()

func _on_SyncManager_sync_started() -> void:
	message_label.text = "Sync Started!"

	if logging_enabled:
		if !DirAccess.dir_exists_absolute(LOG_FILE_DIRECTORY):
			DirAccess.make_dir_absolute(LOG_FILE_DIRECTORY)

		var datetime: Dictionary = Time.get_datetime_dict_from_system(true)
		var log_file_name: String = "%04d%02d%02d-%02d%02d%02d-peer-%d.log" % [
			datetime['year'],
			datetime['month'],
			datetime['day'],
			datetime['hour'],
			datetime['minute'],
			datetime['second'],
			multiplayer.get_unique_id(),
		]
		
		SyncManager.start_logging(LOG_FILE_DIRECTORY + '/' + log_file_name)

	
func _on_SyncManager_sync_stopped() -> void:
	if logging_enabled:
		SyncManager.stop_logging()

func _on_SyncManager_sync_lost() -> void:
	sync_lost_label.visible = true
	pass

func _on_SyncManager_sync_regained() -> void:
	sync_lost_label.visible = false
	pass

func _on_SyncManager_sync_error(message: String) -> void:
	message_label.text= "Fatal sync error: " + message
	sync_lost_label.visible = false

	var peer: MultiplayerPeer = multiplayer.multiplayer_peer
	if peer:
		peer.close()
	SyncManager.clear_peers()


func _on_online_button_pressed() -> void:
	self.connection_panel.visible = true
	SyncManager.reset_network_adaptor()
	self.stage.fighter_message_bus.player_1.is_online = true
	self.stage.fighter_message_bus.player_2.is_online = true

func _on_local_button_pressed() -> void:
	self.main_menu.visible = false
	SyncManager.network_adaptor = DummyNetworkAdapter.new()
	SyncManager.start()
