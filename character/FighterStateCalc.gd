extends WeakRef
class_name FighterStateCalc

const BACK_TURNED_CALC: StringName = &"back_turned_calc"
const FIX_BLENDING_CALC: StringName = &"fix_blending_calc"
const CROUCHING: StringName = &"crouching"
const CROUCHING_CALC: StringName = &"crouching_calc"
const RISING_CALC: StringName = &"rising_calc"

static var methods: Array[Callable] = [
    calc_backturn_state,
    calc_rising_state,
    calc_count_stun_frames,
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

        # print("crouching!!!")

        if me.state_data.has(CROUCHING_CALC):
            me.state_data[CROUCHING_CALC] += 1
        else:
            me.state_data.get_or_add(CROUCHING_CALC, 1)

        return
    
    if me.states.has(RISING_CALC):
        # player should not have rising state & crouching state simultaneously
        if me.state_data.has(CROUCHING_CALC):
            me.state_data.erase(CROUCHING_CALC)

        me.state_data[RISING_CALC] -= 1

        if me.state_data[RISING_CALC] <= 0:
            me.states.erase(RISING_CALC)
            me.state_data.erase(RISING_CALC)

    # player has exited crouching state
    if me.state_data.has(CROUCHING_CALC) && !me.states.has(CROUCHING):

        # player has been in crouch long enough to get rising status
        if me.state_data[CROUCHING_CALC] >= 8:
            me.states.append(RISING_CALC)
            me.state_data[RISING_CALC] = 6 
        
        me.state_data.erase(CROUCHING_CALC)
