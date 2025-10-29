using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using Unity.Mathematics;

namespace BSPhysics
{
    //构造BVH用
    [Serializable]
    public struct Triangle
    {
        public float3 Pos0;
        public float3 Pos1;
        public float3 Pos2;
        public float3 normal;
    }
    public struct AABB
    {
        public float3 Min;
        public float3 Max;
        public float3 Size
        { get { return Max - Min; } }
        public float3 Center
        { get { return (Max + Min) * 0.5f; } }
        public AABB(float3 min, float3 max)
        {
            Min = min;
            Max = max;
        }
    }
    public struct TriangleData
    {
        public AABB TriangleAABB;
        public int TriangleIndex;
    }
    [Serializable]
    public class BvhNode
    {
        public AABB BvhAABB;
        public BvhNode Left;
        public BvhNode Right;
        public int[] TriangleIndices;

        public bool IsLeaf => TriangleIndices != null;
    }
    //Flatten bvh data to use in ComputeShader
    [System.Serializable]
    public struct BvhData
    {
        public float3 Min;
        public float3 Max;

        public int LeftIdx;
        public int RightIdx;

        public int TriangleStartIdx;//-1 if not leaf 
        public int TrianglesCount;
        public bool IsLeaf => TriangleStartIdx >= 0;

    }
}
