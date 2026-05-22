using System;
using System.Diagnostics.Tracing;
using System.Linq;
using System.Reflection.Emit;
using System.Security.Cryptography;
using System.Threading.Tasks;
using Godot;
using Godot.Collections;
using FatalException.FEMath;

[Tool]
[GlobalClass]
public partial class FixedVector3 : RefCounted
{
	[Export]
	public long x { get; set; }

	[Export]
	public long y { get; set; }

	[Export]
	public long z { get; set; }

	#region CONSTRUCTORS
	
	public FixedVector3() : this(0, 0, 0) {}

	public FixedVector3(long x_inc, long y_inc, long z_inc)
	{
		this.x = x_inc;
		this.y = y_inc;
		this.z = z_inc;
	}

	public static FixedVector3 NewFromInt(long x_inc, long y_inc, long z_inc)
	{
		return new FixedVector3(x_inc, y_inc, z_inc);
	}

	public FixedVector3(FixedVector3 inc)
	{
		this.x = inc.x;
		this.y = inc.y;
		this.z = inc.z;
	}

	public static FixedVector3 NewFromFixedVec3(FixedVector3 inc)
	{
		return new FixedVector3(inc);
	}

	public FixedVector3(Vector3 inc)
	{
		this.x = FixedInt.FromFloat(inc.X);
		this.y = FixedInt.FromFloat(inc.Y);
		this.z = FixedInt.FromFloat(inc.Z);
	}

	public static FixedVector3 NewFromVec3(Vector3 inc)
	{
		return new FixedVector3(inc);
	}

	#endregion

	#region OPERATORS

	public static FixedVector3 operator +(FixedVector3 left, FixedVector3 right)
	{
		return Add(left, right);
	}

	public static FixedVector3 Add(FixedVector3 left, FixedVector3 right)
	{
		return new FixedVector3(
			left.x + right.x,
			left.y + right.y,
			left.z + right.z
		);
	}

	public static FixedVector3 operator -(FixedVector3 left, FixedVector3 right)
	{
		return Sub(left, right);
	}

	public static FixedVector3 Sub(FixedVector3 left, FixedVector3 right)
	{
		return new FixedVector3(
			left.x - right.x,
			left.y - right.y,
			left.z - right.z
		);
	}

	public static FixedVector3 operator *(FixedVector3 left, long right)
	{
		return Mul(left, right);
	}

	public static FixedVector3 Mul(FixedVector3 left, long right)
	{
		return new FixedVector3(
			FixedInt.Mul(left.x, right),
			FixedInt.Mul(left.y, right),
			FixedInt.Mul(left.z, right)
		);
	}

	public static FixedVector3 operator *(FixedVector3 left, FixedVector3 right)
	{
		return MulVec(left, right);
	}

	public static FixedVector3 MulVec(FixedVector3 left, FixedVector3 right)
	{
		return new FixedVector3(
			FixedInt.Mul(left.x, right.x),
			FixedInt.Mul(left.y, right.y),
			FixedInt.Mul(left.z, right.z)
		);
	}

	public static FixedVector3 operator /(FixedVector3 left, long right)
	{
		return Div(left, right);
	}

	public static FixedVector3 Div(FixedVector3 left, long right)
	{
		return new FixedVector3(
			FixedInt.Div(left.x, right),
			FixedInt.Div(left.y, right),
			FixedInt.Div(left.z, right)
		);
	}
	#endregion

	#region STATIC METHODS

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

	public static FixedVector3 Lerp(FixedVector3 from, FixedVector3 to, long weight)
	{
		return new FixedVector3(
			FixedInt.Lerp(from.x, to.x, weight),
			FixedInt.Lerp(from.y, to.y, weight),
			FixedInt.Lerp(from.z, to.z, weight)
		);
	}

	public static Array<long[]> BasisLookingAt(
		FixedVector3 target,
		FixedVector3 upAxis,
		bool useModelFront = false)
	{
		FixedVector3 v_z = target.Normalized();
		if (!useModelFront)
		{
			v_z.x = -v_z.x;
			v_z.y = -v_z.y;
			v_z.z = -v_z.z;
		}

		FixedVector3 v_x = upAxis.Cross(v_z);
		if (v_x.IsZeroApprox())
		{
			v_x = upAxis.Cross(
				Math.Abs(upAxis.x) <= Math.Abs(upAxis.y) && 
				Math.Abs(upAxis.x) <= Math.Abs(upAxis.z) 
				? new FixedVector3(65536, 0, 0) /* RIGHT */
				: new FixedVector3(0, 65536, 0) /* UP */
			).Normalized();
		}
		v_x.Normalize();

		FixedVector3 v_y = v_z.Cross(v_x).Normalized();

		return [
			[v_x.x, v_y.x, v_z.x],
			[v_x.y, v_y.y, v_z.y],
			[v_x.z, v_y.z, v_z.z]
		];
	}

	public static FixedVector3 BasisGetEuler(Array<long[]> basis)
	{
		// only implementing YXZ euler order for now
		FixedVector3 euler = new FixedVector3();
		long m12 = basis[1][2];

		if (m12 < FixedInt.FIXED_ONE - 1)
		{
			if (m12 > -(FixedInt.FIXED_ONE - 1))
			{
				if (basis[1][0] == 0 &&
					basis[0][1] == 0 &&
					basis[0][2] == 0 &&
					basis[2][0] == 0 &&
					basis[0][0] == FixedInt.FIXED_ONE)
				{
					euler.x = FixedInt.Atan2(-m12, basis[1][1]);
					euler.y = 0;
					euler.z = 0;
				}

				euler.x = FixedInt.Asin(-m12);
				euler.y = FixedInt.Atan2(basis[0][2], basis[2][2]);
				euler.z = FixedInt.Atan2(basis[1][0], basis[1][1]);
			}
			else
			{ // m12 == -1
				euler.x = FixedInt.FIXED_PI_DIV_2;
				euler.y = FixedInt.Atan2(basis[0][1], basis[0][0]);
				euler.z = 0;
			}
		}
		else
		{ // m12 == 1
			euler.x = -FixedInt.FIXED_PI_DIV_2;
			euler.y = -FixedInt.Atan2(basis[0][1], basis[0][0]);
			euler.z = 0;
		}
		return euler;
	}
	#endregion

	#region  METHODS

	public long Dot(FixedVector3 vec2)
	{
		long res = 0;
		res += FixedInt.Mul(this.x, vec2.x);
		res += FixedInt.Mul(this.y, vec2.y);
		res += FixedInt.Mul(this.z, vec2.z);
		return res;
	}

	public long Dot2D(FixedVector3 vec2)
	{
		long res = 0;
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

	public long Length()
	{
		long lengthSqrd = this.LengthSquared();
		if (lengthSqrd == 0)
		{
			return 0;
		}

		long length = FixedInt.Sqrt64(lengthSqrd);
		if (length == 0)
		{
			return FixedInt.FIXED_ONE;
		}
		return length;
	}

	public long LengthSquared()
	{
		long ret = FixedInt.Mul(this.x, this.x) +
				FixedInt.Mul(this.y, this.y) +
				FixedInt.Mul(this.z, this.z);
		
		if (ret == 0 && (this.x != 0 || this.y != 0 || this.z != 0))
		{
			return FixedInt.FIXED_ONE;
		}
		return ret;
	}

	public long DistanceTo(FixedVector3 vec)
	{
		return (vec - this).Length();
	}

	public long DistanceSquaredTo(FixedVector3 vec)
	{
		return (vec - this).LengthSquared();
	}

	public FixedVector3 DirectionTo(FixedVector3 vec2)
	{
		return new FixedVector3(
			vec2.x - this.x,
			vec2.y - this.y,
			vec2.z - this.z
		).Normalized();
	}

	public FixedVector3 Rotated(long ang)
	{
		FixedVector3 v = new FixedVector3(this);
		v.Rotate(ang);
		return v;
	}

	public void Rotate(long ang)
	{
		long s = FixedInt.Sin(ang);
		long c = FixedInt.Cos(ang);

		long x_old = this.x;
		long z_old = this.z;

		this.x = FixedInt.Mul(s, z_old) + FixedInt.Mul(c, x_old);
		this.z = FixedInt.Mul(c, z_old) - FixedInt.Mul(s, x_old);
	}

	public FixedVector3 Normalized()
	{
		FixedVector3 ret = new FixedVector3(this);
		ret.Normalize();
		return ret;
	}

	public void Normalize()
	{
		long x_abs = Math.Abs(this.x);
		long y_abs = Math.Abs(this.y);
		long z_abs = Math.Abs(this.z);

		if ((this.x != 0 && x_abs < 2048) || 
			(this.y != 0 && y_abs < 2048) || 
			(this.z != 0 && z_abs < 2048))
		{
			// # need to watch out for values that may overflow 64 bit integers
			// # 1482910 = sqrt(MAX_SIGNED_64BIT_NUMBER) / 2048
			const long OVERFLOW_CHECK = 1482910;

			if (x_abs >= OVERFLOW_CHECK)
			{
				this.x = this.x > 0 ? FixedInt.FIXED_ONE : -FixedInt.FIXED_ONE;
				this.y = 0;
				this.z = 0; 
			} 
			else if (y_abs >= OVERFLOW_CHECK)
			{
				this.x = 0;
				this.y = this.y > 0 ? FixedInt.FIXED_ONE : -FixedInt.FIXED_ONE;
				this.z = 0;
			}
			else if (z_abs >= OVERFLOW_CHECK)
			{
				this.x = 0;
				this.y = 0;
				this.x = this.z > 0 ? FixedInt.FIXED_ONE : -FixedInt.FIXED_ONE;
			}
			else
			{
				// multiply xyz by 2048
				long x_big = this.x << 11;
				long y_big = this.y << 11;
				long z_big = this.z << 11;

				long lgth = new FixedVector3(
					x_big,
					y_big,
					z_big
				).Length();

				if (lgth != 0)
				{
					this.x = FixedInt.Div(x_big, lgth);
					this.y = FixedInt.Div(y_big, lgth);
					this.z = FixedInt.Div(z_big, lgth);

				}
			}
		}
		else
		{
			long lgth = this.Length();
			if (lgth != 0)
			{
				this.x = FixedInt.Div(this.x, lgth);
				this.y = FixedInt.Div(this.y, lgth);
				this.z = FixedInt.Div(this.z, lgth);

			}
		}
	}

	public bool IsZeroApprox()
	{
		return this.x == FixedInt.FIXED_ZERO &&
			this.y == FixedInt.FIXED_ZERO &&
			this.z == FixedInt.FIXED_ZERO;
	}
	
	public long AngleTo(FixedVector3 target)
	{
		return FixedInt.Atan2(this.Cross(target).Length(), this.Dot(target));
	}
	#endregion
}
