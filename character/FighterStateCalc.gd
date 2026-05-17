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

    # var diff: int
    
    # # if def. & des rotation is > 90 deg., but have opposite signs
    # if (absi(me.collision_body.fixed_rotation.y) > 102944 && absi(if_facing_towards.y) > 102944) && \
    #     ((me.collision_body.fixed_rotation.y < 0 && if_facing_towards.y > 0) || \
    #     (me.collision_body.fixed_rotation.y > 0 && if_facing_towards.y < 0)):
        
    #     # get interior angles
    #     var true_rotation_def: int = FixedIntGDConstant.FIXED_PI - absi(me.collision_body.fixed_rotation.y)
    #     var true_rotation_des: int = FixedIntGDConstant.FIXED_PI - absi(if_facing_towards.y)

    #     # fix signs
    #     if me.collision_body.fixed_rotation.y < 0:
    #         true_rotation_def = FixedInt.Mul(true_rotation_def, -FixedIntGDConstant.FIXED_ONE)
    #     if if_facing_towards.y < 0:
    #         true_rotation_des = FixedInt.Mul(true_rotation_des, -FixedIntGDConstant.FIXED_ONE)
    
    #     diff = absi(true_rotation_def - true_rotation_des)

    # else:
    #     diff = absi(me.collision_body.fixed_rotation.y - if_facing_towards.y)

    #         # 100 deg. or 1.74533 rad.
    # if diff > 114382: