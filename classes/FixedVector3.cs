using System;
using System.Collections.Generic;
using System.Diagnostics.Tracing;
using System.Linq;
using System.Reflection.Emit;
using System.Security.Cryptography;
using System.Threading.Tasks;
using Godot;
using FatalException.FEMath;
using System.Runtime.InteropServices.Swift;

[Tool]
[GlobalClass]
public partial class FixedVector3 : GodotObject
{
    [Export]
    public int x = 0;

    [Export]
    public int y = 0;

    [Export]
    public int z = 0;

    public static FixedVector3 UP = new FixedVector3(0, 65536, 0);
    public static FixedVector3 RIGHT = new FixedVector3(65536, 0, 0);

    public static FixedVector3 operator +(FixedVector3 left, FixedVector3 right)
    {
        return new FixedVector3(
            left.x + right.x,
            left.y + right.y,
            left.z + right.z
        );
    }

    public static FixedVector3 operator -(FixedVector3 left, FixedVector3 right)
    {
        return new FixedVector3(
            left.x - right.x,
            left.y - right.y,
            left.z - right.z
        );
    }

    public static FixedVector3 operator *(FixedVector3 left, int right)
    {
        return new FixedVector3(
            FixedInt.Mul(left.x, right),
            FixedInt.Mul(left.y, right),
            FixedInt.Mul(left.z, right)
        );
    }

    public static FixedVector3 operator *(FixedVector3 left, FixedVector3 right)
    {
        return new FixedVector3(
            FixedInt.Mul(left.x, right.x),
            FixedInt.Mul(left.y, right.y),
            FixedInt.Mul(left.z, right.z)
        );
    }

    public static FixedVector3 operator /(FixedVector3 left, int right)
    {
        return new FixedVector3(
            FixedInt.Div(left.x, right),
            FixedInt.Div(left.y, right),
            FixedInt.Div(left.z, right)
        );
    }

    public FixedVector3() {}

    public FixedVector3(int x_inc, int y_inc, int z_inc)
    {
        this.x = x_inc;
        this.y = y_inc;
        this.z = z_inc;
    }

    public static FixedVector3 FromVec3(Vector3 val)
    {
        return new FixedVector3(
            FixedInt.FromFloat(val.X),
            FixedInt.FromFloat(val.Y),
            FixedInt.FromFloat(val.Z)
        );
    }

    public static Vector3 ToVec3(FixedVector3 val)
    {
        return new Vector3(
            FixedInt.ToFloat(val.x),
            FixedInt.ToFloat(val.y),
            FixedInt.ToFloat(val.z)
        );
    }

    public static FixedVector3 Lerp(FixedVector3 from, FixedVector3 to, int weight)
    {
        return new FixedVector3(
            FixedInt.Lerp(from.x, to.x, weight),
            FixedInt.Lerp(from.y, to.y, weight),
            FixedInt.Lerp(from.z, to.z, weight)
        );
    }

    public int Dot(FixedVector3 vec2)
    {
        int res = 0;
        res += FixedInt.Mul(this.x, vec2.x);
        res += FixedInt.Mul(this.y, vec2.y);
        res += FixedInt.Mul(this.z, vec2.z);
        return res;
    }

    public int Dot2D(FixedVector3 vec2)
    {
        int res = 0;
        res += FixedInt.Mul(this.x, vec2.x);
        res += FixedInt.Mul(this.z, vec2.z);
        return res;
    }

    public FixedVector3 Cross(FixedVector3 vec2)
    {
        return new FixedVector3(
            FixedInt.Mul(this.y, vec2.z) - FixedInt.Mul(this.z, vec2.y),
            FixedInt.Mul(this.z, vec2.x) - FixedInt.Mul(this.x, vec2.z),
            FixedInt.Mul(this.x, vec2.y) - FixedInt.Mul(this.y, vec2.x)
        );
    }

    public int Length()
    {
        int lengthSqrd = this.LengthSquared();
        if (lengthSqrd == 0)
        {
            return 0;
        }

        int length = FixedInt.Sqrt64(lengthSqrd);
        if (length == 0)
        {
            return FixedInt.FIXED_ONE;
        }
        return length;
    }

    public int Length2D()
    {
        // zzz
        return;
    }

    public int LengthSquared()
    {
        int ret = FixedInt.Mul(this.x, this.x) +
                FixedInt.Mul(this.y, this.y) +
                FixedInt.Mul(this.z, this.z);
        
        if (ret == 0 && (this.x != 0 || this.y != 0 || this.z != 0))
        {
            return FixedInt.FIXED_ONE;
        }
        return ret;
    }
}