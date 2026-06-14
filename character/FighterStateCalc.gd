extends WeakRef
class_name FighterStateCalc

const BACK_TURNED_CALC: StringName = &"back_turned_calc"
const FIX_BLENDING_CALC: StringName = &"fix_blending_calc"

static var methods: Array[Callable] = [
    calc_backturn_state,
    calc_blending_fix,
]

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

static func calc_blending_fix(me: Fighter) -> void:
    if me.states.has(&"fix_blending"):
        if !me.state_data.has(FIX_BLENDING_CALC):
            me.state_data.get_or_add(FIX_BLENDING_CALC, 30)
        else:
            me.state_data.set(FIX_BLENDING_CALC, 30)
        me.anim_player.deterministic = true
        return
    
    if me.state_data.has(FIX_BLENDING_CALC):
        me.state_data[FIX_BLENDING_CALC] -= 1
        if me.state_data[FIX_BLENDING_CALC] <= 0:
            me.state_data.erase(FIX_BLENDING_CALC)
        me.anim_player.deterministic = true
        return

    me.anim_player.deterministic = false