using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Godot;

[GlobalClass]
public partial class StageGarbageCollection : GodotObject
{
    public StageGarbageCollection() {}

    public static void CollectGarbage()
    {
        GC.Collect(0, GCCollectionMode.Forced);
        GC.WaitForPendingFinalizers();
    }
}