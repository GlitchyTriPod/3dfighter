using System;
using System.Collections.Generic;
using System.Diagnostics;
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

    public static Array<bool> IsInsidePolygon(FixedVector3 p1_loc, FixedVector3 p2_loc, FixedVector3[] extents)
    {
        bool ValueP1 = false;
        bool ValueP2 = false;

        for (int i = 0; i < extents.Length; i++)
        {  
            FixedVector3 start = extents[i];
            FixedVector3 end = extents[i + 1 >= extents.Length ? 0 : i + 1];

            if (((end.z > p1_loc.z) != (start.z > p1_loc.z) ) &&
                (p1_loc.x < FixedInt.Div(FixedInt.Mul(start.x - end.x, p1_loc.z - end.z), start.z - end.z) + end.x))
            {
                ValueP1 = !ValueP1;
            }

            if (((end.z > p2_loc.z) != (start.z > p2_loc.z)) &&
                (p2_loc.x < FixedInt.Div(FixedInt.Mul(start.x - end.x, p2_loc.z - end.z), start.z - end.z) + end.x))
            {
                ValueP2 = !ValueP2;
            }
            
        }
        return [ValueP1, ValueP2];
    }

    private static bool IsLeftOrOnLine(FixedVector3 loc, FixedVector3 start, FixedVector3 end)
    {
        return FixedInt.Mul(loc.x - start.x, end.z - start.z) - FixedInt.Mul(loc.z - start.z, end.x - start.x) >= 0;
    }

    public static long CalculateWallPushback(long startX, long startZ, long endX, long endZ, FixedVector3 loc, long radius)
    {
        FixedVector3 start = new FixedVector3(startX, loc.y, startZ);
        FixedVector3 end = new FixedVector3(endX, loc.y, endZ);

        FixedVector3 AB = end - start;
        FixedVector3 AC = loc - start;

        FixedVector3 AD = FixedVector3.Mul(AB, FixedInt.Div(AB.Dot2D(AC), AB.Dot2D(AB)));
        FixedVector3 D = start + AD;

        return loc.DistanceSquaredTo(D);
    }
}
