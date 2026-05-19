using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using FatalException.FEMath;
using Godot;

[GlobalClass]
public partial class CollisionMath : GodotObject
{
    public CollisionMath() {}

    public static long CalculatePushback(long pushbackForce, float animPosition)
    {
        return FixedInt.Lerp(
            pushbackForce,
            0,
            Math.Clamp(
                FixedInt.Div(
                    FixedInt.FromFloat(animPosition),
                    FixedInt.FIXED_HALF
                ),
                0,
                FixedInt.FIXED_ONE
            )
        );
    }

    public static bool CalculateBackturned(long currentRotationAng, long facingTowardAng)
    {
        long diff = Math.Abs(currentRotationAng - facingTowardAng);;

        if (Math.Abs(currentRotationAng) > 102944 && 
            Math.Abs(facingTowardAng) > 102944 && 
            ((currentRotationAng < 0 && facingTowardAng > 0) ||
            (currentRotationAng > 0 && facingTowardAng < 0))
        )
        {
            long trueRotationDef = FixedInt.FIXED_PI - Math.Abs(currentRotationAng);
            long trueRotationDes = FixedInt.FIXED_PI - Math.Abs(facingTowardAng);

            if (currentRotationAng < 0)
            {
                trueRotationDef = -trueRotationDef;
            }
            if (facingTowardAng < 0)
            {
                trueRotationDes = -trueRotationDes;
            }

            diff = Math.Abs(trueRotationDef - trueRotationDes);
        }
        
        if (diff > 114382)
        {
            return true;
        }
        return false;
    }
}