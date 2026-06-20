using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using FatalException.FEMath;
using Godot;
using Godot.Collections;

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

    public static FixedVector3 CalculateVelocity(
        long delta, 
        long pushbackForce, 
        long pushbackAngle,
        FixedVector3 velocityRotated, 
        long opponentAngle
    )
    {
        FixedVector3 finalVelocity = velocityRotated + new FixedVector3(0, 0, pushbackForce).Rotated(
            opponentAngle + pushbackAngle
        );
        return finalVelocity / delta;
    }

    public static FixedVector3 CalculateCollisionPushback(long p1Rotation, long overlap)
    {
        FixedVector3 pushback = new FixedVector3(0, 0, FixedInt.Mul(overlap, FixedInt.FromInt(20)));
        return pushback.Rotated(p1Rotation);
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

    public static bool IsInsidePolygon(FixedVector3 loc, FixedVector3[] extents)
    {
        bool initValue = false;
        for (int i = 0; i < extents.Length; i++)
        {  
            FixedVector3 start = extents[i];
            FixedVector3 end = extents[i + 1 >= extents.Length ? 0 : i + 1];

            if (i == 0)
            {                
                initValue = IsLeftOrOnLine(loc, start, end);
                continue;
            }

            if (IsLeftOrOnLine(loc, start, end) != initValue)
            {
                return false;
            }
        }
        
        return true;
    }

    private static bool IsLeftOrOnLine(FixedVector3 loc, FixedVector3 start, FixedVector3 end)
    {
        return (loc.z - start.z) * (end.x - start.x) - (loc.x - start.x) * (end.z - start.z) >= 0;
    }
}