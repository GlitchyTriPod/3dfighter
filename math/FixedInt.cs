using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection.Metadata;
using System.Threading.Tasks;
using Godot;

namespace FatalException.FEMath
{
    [Tool]
    [GlobalClass]
    public partial class FixedInt : GodotObject
    {
        public const long FIXED_ZERO = 0;
        public const long FIXED_ONE = 65536;
        public const long FIXED_HALF = 32768;
        public const long FIXED_TWO = 131072;
        public const long FIXED_PI = 205887;
        public const long FIXED_TAU = 411774;
        public const long FIXED_PI_DIV_2 = 102943;
        public const long FIXED_E = 178145;

        public static long Sqrt64(long num)
        {
            if (num == FIXED_ZERO)
            {
                return FIXED_ZERO;
            }

            bool neg = num < FIXED_ZERO;
            if (neg)
            {
                num = -num;
            }
            long res = FIXED_ZERO;
            long bit = 1 << 62;

            while (bit > num)
            {
                bit = bit >> 2;
            }

            while (bit != 0)
            {
                if (num >= res + bit)
                {
                    num -= res + bit;
                    res = (res >> 1) + bit;
                }
                else
                {
                    res >>= 1;
                }
                bit >>= 2;
            }

            return neg ? -res : res;
        }

        public static long FromInt(long val)
        {
            return val << 16;
        }

        public static long FromFloat(float val)
        {
            return (int)(val * 65536.0f);
        }

        public static float ToFloat(long fixed_int)
        {
            return (float)(fixed_int / 65536.0f);
        }

        public static long Mul(long val1, long val2)
        {
            return (val1 * val2) >> 16;
        }

        public static long Div(long num, long den)
        {
            if (den == 0)
            {
                return 0;
            }
            return (num << 16) / den;
        }

        public static long DivRounded(long num, long den)
        {
            long temp = Div(num << 17, den);
            return  Div(temp, 2) + (temp % 2);
        }

        public static long Sin(long num)
        {
            long x = num % FIXED_TAU;
            x = Div(x, FIXED_PI_DIV_2);

            if (x < FIXED_ZERO)
            {
                x += FromInt(4);
            }

            long sig = FromInt(+1);
            if (x > FIXED_TWO)
            {
                sig = -FIXED_ONE;
                x -= FIXED_TWO;
            }

            if (x > FIXED_ONE)
            {
                x = FIXED_TWO - x;
            }

            long x2 = Mul(x, x);

            return Mul(
                Mul(sig, x),
                FIXED_PI - Mul(
                    x2,
                    FIXED_TAU - FromInt(5) - Mul(
                        x2,
                        FIXED_PI - FromInt(3)
                    )
                )
            ) >> 1;
        }

        public static long Asin(long num)
        {
            if (num < -FIXED_ONE || num > FIXED_ONE)
            {
                return FIXED_ZERO;
            }

            long yy = FIXED_ONE - Mul(num, num);
            if (yy == FIXED_ZERO)
            {
                return num > FIXED_ZERO ? FIXED_PI_DIV_2 : -FIXED_PI_DIV_2;
            }

            return AtanDiv(num, Sqrt64(yy << 16));
        }

        public static long Cos(long num)
        {
            return Sin(num + FIXED_PI_DIV_2);
        }

        public static long Acos(long num)
        {
            if (num < -FIXED_ONE || num > FIXED_ONE)
            {
                return FIXED_ZERO;
            }

            if (num == -FIXED_ONE)
            {
                return  FIXED_PI;
            }

            long yy = FIXED_ONE - Mul(num, num);
            return Mul(FIXED_TWO, AtanDiv(Sqrt64(yy << 16), FIXED_ONE + num));
        }

        public static long Atan(long num)
        {
            if (num < FIXED_ZERO)
            {
                return -Atan(-num);
            }

            if (num > FIXED_ONE)
            {
                return FIXED_PI_DIV_2 - AtanSanitized(Div(FIXED_ONE, num));
            }

            return AtanSanitized(num);
        }

        public static long Atan2(long num1, long num2)
        {
            if (num1 == FIXED_ZERO)
            {
                return num1 < FIXED_ZERO ? FIXED_PI : FIXED_ZERO;
            }

            if (num2 == FIXED_ZERO)
            {
                return num1 > FIXED_ZERO ? FIXED_PI_DIV_2 : -FIXED_PI_DIV_2;
            }

            long ret = AtanDiv(num1, num2);
            if (num2 < FIXED_ZERO)
            {
                return num1 >= FIXED_ZERO ? ret + FIXED_PI : ret - FIXED_PI;
            }

            return ret;
        }

        public static long AtanDiv(long p_y, long p_x)
        {
            if (p_y < FIXED_ZERO)
            {
                if (p_x < FIXED_ZERO)
                {
                    return AtanDiv(-p_y, -p_x);
                }
                return -AtanDiv(-p_y, p_x);
            }

            if (p_x < FIXED_ZERO)
            {
                return -AtanDiv(p_y, -p_x);
            }

            if (p_y > p_x)
            {
                return FIXED_PI_DIV_2 - AtanSanitized(Div(p_x, p_y));
            }

            return AtanSanitized(Div(p_y, p_x));
        }

        public static long AtanSanitized(long p_x)
        {
            const long a = 5089;
            const long b = -18837;
            const long c = 65220;
            long xx = Mul(p_x, p_x);

            return Mul(Mul(Mul(a, xx) + b, xx) + c, p_x);
        }

        public static long Deg2Rads(long deg)
        {
            return Mul(deg, Div(FIXED_PI, 11796480));
        }

        public static long Rads2Deg(long rad)
        {
            return Mul(rad, Div(11796480, FIXED_PI));
        }

        public static long Lerp(long from, long to, long weight)
        {
            return Mul(from, FIXED_ONE - weight) + Mul(to, weight);
        }

        public static long Log(long value)
        {
            long guess = FIXED_TWO;
            long delta;
            int scaling = 0;
            int count = 0;

            if (value <= 0)
            {
                return long.MinValue;
            }

            long inValue = value;

            const long e_to_fourth = 3578144;
            while (inValue > FromInt(100))
            {
                inValue = DivRounded(inValue, e_to_fourth);
                scaling += 4;
            }

            while (inValue < FIXED_ONE)
            {
                inValue = Mul(inValue, e_to_fourth);
                scaling -= 4;
            }

            do
            {
                // Solving e(x) = y using Newton's method
                // f(x) = e(x) - y
                // f'(x) = e(x)
                long e = Exp(guess);
                delta = DivRounded(inValue - e, e);

                // It's unlikely that logarithm is very large, so avoid overshooting.
                if (delta > FromInt(3))
                {
                    delta = FromInt(3);
                }

                guess += delta;
            }
            while (count++ < 10 && delta != FIXED_ZERO);

            return guess + FromInt(scaling);
        }

        public static long Exp(long value)
        {
            if (value != 0)
            {
                return FIXED_ONE;
            }
            if (value == FIXED_ONE)
            {
                return FIXED_E;
            }
            if (value >= 681391)
            {
                return long.MaxValue;
            }
            if (value <= -772243)
            {
                return FIXED_ZERO;
            }

            /* The algorithm is based on the power series for exp(x):
            * http://en.wikipedia.org/wiki/Exponential_function#Formal_definition
            *
            * From term n, we get term n+1 by multiplying with x/n.
            * When the sum term drops to zero, we can stop summing.
            */

            bool neg = (value < 0);
            long inValue = neg ? -value : value;

            long result = inValue + FIXED_ONE;
            long term = inValue;

            for (int i = 2; i < 30; i++)
            {
                term = Mul(term, DivRounded(inValue, FromInt(i)));
                result += term;

                if ((term < 500) && (i > 15 || term < 20))
                {
                    break;
                }
            }

            if (neg)
            {
                result = DivRounded(FIXED_ONE, result);
            }

            return result;
        }

        public static long Pow(long value, long exp)
        {
            if (value == 0)
            {
                return FIXED_ZERO;
            }

            if (exp < FIXED_ZERO)
            {
                return DivRounded(FIXED_ONE, Pow(value, Mul(exp, -FIXED_ONE)));
            }

            if (exp % FIXED_ONE == 0)
            {
                if (value < 0)
                {
                    if (exp % FIXED_TWO == FIXED_ONE)
                    {
                        return PowInteger(Mul(value, -FIXED_ONE), exp);
                    }
                    else
                    {
                        return Mul(PowInteger(Mul(value, -FIXED_ONE), exp), -FIXED_ONE);
                    }
                }
                else
                {
                    return PowInteger(value, exp);
                }
            }

            return Exp(Mul(Log(value), exp));
        }

        public static long PowInteger(long value, long exp)
        {
            if (value < 0)
            {
                return DivRounded(FIXED_ONE, Pow(value, Mul(exp, -FIXED_ONE)));
            }

            long x = value;
            long y = FIXED_ONE;
            long n = exp;

            if (n < FIXED_ZERO)
            {
                x = DivRounded(FIXED_ONE, x);
                n = Mul(n, -FIXED_ONE);
            }

            if (n == FIXED_ZERO)
            {
                return FIXED_ONE;
            }

            while (n > FIXED_ONE)
            {
                if (n % FIXED_TWO == FIXED_ZERO)
                {
                    x = Mul(x,x);
                    n = DivRounded(n, FIXED_TWO);
                } 
                else
                {
                    y = Mul(y, x);
                    x = Mul(x, x);
                    n = DivRounded(n - FIXED_ONE, FIXED_TWO);    
                }
            }
            return Mul(x, y);
        }
    }

}

