using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using FatalException.FEMath;
using Godot;

namespace FatalException.character
{
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
    }
}