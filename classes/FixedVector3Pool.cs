using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using System.Reflection.Metadata.Ecma335;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using Godot;
using Microsoft.Extensions.ObjectPool;

// public class FixedVector3PoolPolicy : IPooledObjectPolicy<FixedVector3>
// {
//     public FixedVector3 Create() => new FixedVector3();
//     public FixedVector3 Create(int x_inc, int y_inc, int z_inc) => new FixedVector3(x_inc, y_inc, z_inc);

//     public bool Return(FixedVector3 obj)
//     {
//         obj.x = 0;
//         obj.y = 0;
//         obj.z = 0;
//         return true;
//     }
// }

// public partial class FixedVector3Pool : GodotObject
// {
//     private DefaultObjectPool<FixedVector3> _pool = new DefaultObjectPool<FixedVector3>(new FixedVector3PoolPolicy());

//     public FixedVector3Pool() {}

//     public FixedVector3 Get()
//     {
//         return this._pool.Get();
//     }

//     public void Return
// }