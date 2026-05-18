extends WeakRef
class_name FighterStateCalc

static var methods: Array[Callable] = [
    calc_backturn_state
]

static func calc_backturn_state(me: Fighter) -> void:
    var oppo_collision_body: FEFighterCollisionBody = me.message_bus.get_oppo_collision_body(me)
    var if_facing_towards: FixedVector3 = me.collision_body.get_look_at(
        oppo_collision_body.fixed_position,
        FixedVector3.NewFromInt(0, FixedIntGDConstant.FIXED_ONE, 0)
    )

    if CollisionMath.CalculateBackturned(me.collision_body.fixed_rotation.y, if_facing_towards.y):
        if !me.states.has("back_turned_calc"):
            me.states.append("back_turned_calc")
        return
    
    if me.states.has("back_turned_calc"):
        me.states.erase("back_turned_calc")