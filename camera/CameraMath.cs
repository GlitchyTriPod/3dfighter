using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using FatalException.FEMath;
using Godot;
using Godot.Collections;

[GlobalClass]
public partial class CameraMath : GodotObject
{
    public CameraMath() {}

    public static long GetDistanceClamped(FixedVector3 from, FixedVector3 to)
    {
        return Math.Clamp(
            FixedInt.Mul(from.DistanceTo(to), FixedInt.FromFloat(0.75f)),
            900,
            1800
        );
    }

    public static bool IsPlayerOnLeftSide(FixedVector3 cameraPosition, FixedVector3 refPosition, FixedVector3 player1Position)
    {
        FixedVector3 cameraRotation = GetCameraTargetRotation(refPosition, cameraPosition);
        FixedVector3 targetRotation = GetCameraTargetRotation(player1Position, cameraPosition);
        long dist = cameraRotation.y - targetRotation.y;
        return dist < 0;
    }

    public static FixedVector3 GetCameraTargetPosition(FixedVector3 p1, FixedVector3 p2)
    {
        return FixedVector3.Div(
            FixedVector3.Add(p1, p2), FixedInt.FIXED_TWO
        );
    }

    public static FixedVector3 GetCameraTargetRotation(FixedVector3 p1, FixedVector3 position)
    {
        FixedVector3 fwd = p1 - position;
        // Array<long[]> lookat_basis = FixedVector3.BasisLookingAt(
        //     fwd, new FixedVector3(0, FixedInt.FIXED_ONE, 0), true
        // );
        return FixedVector3.BasisGetEuler(fwd);

    }

    public static Array<FixedVector3> GetCameraRefPosition(FixedVector3 p1Position, FixedVector3 p2Position)
    {
        long distance = GetDistanceClamped(p1Position, p2Position);       
        FixedVector3 newPosition = GetCameraTargetPosition(p1Position, p2Position);
        FixedVector3 angle = GetCameraTargetRotation(p1Position, newPosition);

        FixedVector3 newRef = new FixedVector3(
            -FixedInt.Lerp(FixedInt.FromInt(4), FixedInt.FromInt(11), FixedInt.Div(distance - 900, 1800)),
            newPosition.y + FixedInt.FromFloat(0.25f),
            0
        );

        Array<FixedVector3> ret = [
            newPosition,
            angle,
            newRef.Rotated(angle.y) + newPosition

        ];

        return ret;
    }

    public static bool NeedsSideSwap(FixedVector3 inside, FixedVector3 cameraTarget, FixedVector3 cameraPos)
    {   
        long a = inside.DistanceSquaredTo(cameraTarget);
        long b = inside.DistanceSquaredTo(cameraPos);
        long c = cameraPos.DistanceSquaredTo(cameraTarget);

        long innerAngle = FixedInt.Acos(
            FixedInt.Div(
                a + b - c,
                FixedInt.Mul(2, FixedInt.Mul(FixedInt.Sqrt64(a), FixedInt.Sqrt64(b)))
            )
        );

        return innerAngle > 180;
    }

    public static FixedVector3 LerpCameraPosition(
        FixedVector3 cameraPosition, 
        FixedVector3 cameraTarget, 
        float smoothingSpeed,
        float tickTime
    )
    {
        long sSpeed = FixedInt.FromFloat(smoothingSpeed);
        long tTime = FixedInt.FromFloat(tickTime);
        return FixedVector3.Lerp(
            cameraPosition,
            cameraTarget,
            FixedInt.Mul(
                sSpeed,
                tTime
            )
        );
    }
}