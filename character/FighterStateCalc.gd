extends WeakRef
class_name FighterStateCalc

const BACK_TURNED_CALC: StringName = &"back_turned_calc"
const WALL_STOP_CALC: StringName = &"wall_stop_calc"
const WALL_PROCEED_CALC: StringName = &"wall_proceed_calc"
const CROUCHING: StringName = &"crouching"
const CROUCHING_CALC: StringName = &"crouching_calc"
const RISING_CALC: StringName = &"rising_calc"
const CALC_COMBO_EXTEND_USED: StringName = &"combo_extend_used_calc"
const CALC_WALL_STATUS: StringName = &"preserve_wall_status_calc"

static var methods: Array[Callable] = [
    calc_backturn_state,
    calc_wall_stop,
    calc_rising_state,
    calc_count_stun_frames,
    calc_combo_extension,
    calc_combo_wall_stun,
]

static func calc_count_stun_frames(me: Fighter) -> void:
    if !me.stun_reason.stun_name.is_empty():
        if me.state_data.has(&"stun_frame_count"):
            me.state_data[&"stun_frame_count"] += 1
        else:
            me.state_data.get_or_add(&"stun_frame_count", 1)
    
    if me.state_data.has(&"stun_frame_count") && me.state_data[&"stun_frame_count"] >= 5:
        me.stun_reason.stun_name = ""
        me.state_data.erase(&"stun_frame_count")
        
static func calc_wall_stop(me: Fighter) -> void:
    if !me.states.has("wall_stun"):
        me.state_data.erase(WALL_STOP_CALC)
        me.state_data.erase(WALL_PROCEED_CALC)
        me.states.erase(WALL_STOP_CALC)
        me.states.erase(WALL_PROCEED_CALC)
        return
    
    # implicit: has wall_stun state
    if me.is_on_ground:
        if !me.state_data.has(WALL_STOP_CALC):
            me.state_data.get_or_add(WALL_STOP_CALC, 0)
        me.state_data[WALL_STOP_CALC] = clampi(me.state_data[WALL_STOP_CALC] + 1, 1, 31)
        if me.state_data[WALL_STOP_CALC] > 0 && me.state_data[WALL_STOP_CALC] < 31:
            if !me.states.has(WALL_STOP_CALC):
                me.states.append(WALL_STOP_CALC)
        else:
            me.states.erase(WALL_STOP_CALC)
            me.states.append(WALL_PROCEED_CALC)

static func calc_backturn_state(me: Fighter) -> void:
    var oppo_collision_body: FEFighterCollisionBody = me.message_bus.get_oppo_collision_body(me)
    var if_facing_towards: FixedVector3 = me.collision_body.get_look_at(
        oppo_collision_body.fixed_position
    )

    if CollisionMath.CalculateBackturned(me.collision_body.fixed_rotation.y, if_facing_towards.y):
        if !me.states.has(BACK_TURNED_CALC):
            me.states.append(BACK_TURNED_CALC)
        if !me.state_data.has(BACK_TURNED_CALC):
            me.state_data.get_or_add(BACK_TURNED_CALC)
        return
    
    if me.states.has(BACK_TURNED_CALC):
        me.states.erase(BACK_TURNED_CALC)
    if me.state_data.has(BACK_TURNED_CALC):
        me.state_data.erase(BACK_TURNED_CALC)

static func calc_rising_state(me: Fighter) -> void:
    if me.states.has(CROUCHING):
        # player should not have rising state & crouching state simultaneously
        if me.states.has(RISING_CALC) || me.state_data.has(RISING_CALC):
            me.states.erase(RISING_CALC)
            me.state_data.erase(RISING_CALC)

        if me.state_data.has(CROUCHING_CALC):
            me.state_data[CROUCHING_CALC] += 1
        else:
            me.state_data.get_or_add(CROUCHING_CALC, 1)

        return
    
    if me.state_data.has(RISING_CALC):
        # player should not have rising state & crouching state simultaneously
        if me.state_data.has(CROUCHING_CALC):
            me.state_data.erase(CROUCHING_CALC)

        if !me.states.has(RISING_CALC):
            me.states.append(RISING_CALC)
            
        me.state_data[RISING_CALC] -= 1

        if me.state_data[RISING_CALC] <= 0:
            me.states.erase(RISING_CALC)
            me.state_data.erase(RISING_CALC)

        return

    # player has exited crouching state
    if me.state_data.has(CROUCHING_CALC) && !me.states.has(CROUCHING):

        # player has been in crouch long enough to get rising status
        if me.state_data[CROUCHING_CALC] >= 8:
            me.states.append(RISING_CALC)
            me.state_data[RISING_CALC] = 6 
        
        me.state_data.erase(CROUCHING_CALC)

static func calc_combo_extension(me: Fighter) -> void:
    if me.states.has("combo_extend_used"):
        if !me.state_data.has(CALC_COMBO_EXTEND_USED):
            me.state_data.get_or_add(CALC_COMBO_EXTEND_USED)
    
    if me.states.has("actionable") && me.state_data.has(CALC_COMBO_EXTEND_USED):
        me.state_data.erase(CALC_COMBO_EXTEND_USED)
    
static func calc_combo_wall_stun(me: Fighter) -> void:
    if me.states.has("preserve_wall_status"):
        me.state_data.get_or_add(CALC_WALL_STATUS)
        return # should never have both 'preserve_wall_status' and actionable at same time
    
    if me.states.has("actionable"):
        me.state_data.erase(CALC_WALL_STATUS)