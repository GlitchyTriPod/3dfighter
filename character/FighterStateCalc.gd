extends WeakRef
class_name FighterStateCalc

const BACK_TURNED_CALC: StringName = &"back_turned_calc"

static var methods: Array[Callable] = [
    calc_backturn_state
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
