using UnityEngine;
using UnityEditor;
using BSPhysics;
using System.Diagnostics;
using System.Linq;
using Unity.Mathematics;
using Debug = UnityEngine.Debug;
using System.IO;
using System.Runtime.InteropServices;

public class ThicknessBakerWindow : EditorWindow
{
    public MeshFilter TargetMesh;

    public int TextureSize = 1024;
    public ComputeShader BakeThicknessCS;
    public float DepthMultiply = 1.0f;
    public float Exp = 1.0f;
    private Triangle[] m_Triangles;
    private BvhData[] m_bvhs;
    private bool m_IsButtonActive = false;
    private bool m_IsBvhReady = false;
    [MenuItem("Window/OpenThicknessBaker")]
    static void Init()
    {
        var window = GetWindowWithRect<ThicknessBakerWindow>(new Rect(0f, 0f, 400f, 130f));
        window.Show();
    }
    void OnGUI()
    {
        GUILayout.Space(16f);
        EditorGUI.BeginChangeCheck();
        GUIContent meshLabel = new GUIContent("MeshFilter", "Please select the meshfilter you need to bake");
        TargetMesh = EditorGUILayout.ObjectField(meshLabel, TargetMesh, typeof(MeshFilter), true) as MeshFilter;
        bool meshChanged = EditorGUI.EndChangeCheck();
        EditorGUILayout.Space(10f);

        bool originalBuildGUIState = GUI.enabled;
        GUI.enabled = m_IsButtonActive;
        if (GUILayout.Button("Build BVH", GUILayout.Height(30)))
        {
            if (!TargetMesh.sharedMesh.isReadable)
            {
                Debug.LogError("Model file must enable Read/Write");
                return;
            }
            m_IsButtonActive = false;  //Disable button after click
            BuildBvh(TargetMesh);
        }
        GUI.enabled = originalBuildGUIState;
        if (meshChanged)
        {
            m_IsButtonActive = TargetMesh != null;
            m_IsBvhReady = false;
            Repaint();
        }
        EditorGUILayout.Space(10f);
        GUIContent sizeLabel = new GUIContent("TextureSize", "Texture size you want to bake");
        TextureSize = EditorGUILayout.IntField(sizeLabel, TextureSize);
        GUIContent csLabel = new GUIContent("ComputeShader", "Please assgin BakeThicknessCS here");
        BakeThicknessCS = EditorGUILayout.ObjectField(csLabel, BakeThicknessCS, typeof(ComputeShader), false) as ComputeShader;
        GUIContent depthMultiplyLabel = new GUIContent("DepthMultiply", "Max thick multiply");
        DepthMultiply = EditorGUILayout.Slider(depthMultiplyLabel, DepthMultiply, 0f, 1.0f);
        GUIContent expLabel = new GUIContent("Exponent", "Texture color level exponent correct");
        Exp = EditorGUILayout.FloatField(expLabel, Exp);
        EditorGUILayout.Space(10f);
        bool originalBakeGUIState = GUI.enabled;
        GUI.enabled = m_IsBvhReady && (BakeThicknessCS != null);
        if (GUILayout.Button("Bake Thickness Map", GUILayout.Height(30)))
        {
            BakeThicknessMap();
        }
        GUI.enabled = originalBakeGUIState;
    }
    void BuildBvh(MeshFilter meshFilter)
    {
        Stopwatch sw = new Stopwatch();
        sw.Start();
        var vertices = meshFilter.sharedMesh.vertices.Select(x => new float3(x.x, x.y, x.z)).ToArray();
        var triangles = meshFilter.sharedMesh.triangles;
        (m_Triangles, m_bvhs) = BSPhysics.BvhBuilder.BuildBVH(vertices, triangles, 64);
        m_IsBvhReady = true;
        sw.Stop();
        Debug.Log($"Initialization construction BVH complete!cost {sw.ElapsedMilliseconds} ms");
    }
    void BakeThicknessMap()
    {
        var sw = new Stopwatch();
        sw.Start();
        //Step 1：Bake positions and normals(model space) to texture.
        var bakeCamera = new GameObject("BakeCamera").AddComponent<Camera>();
        bakeCamera.gameObject.hideFlags = HideFlags.HideInHierarchy;
        bakeCamera.allowMSAA = false;
        bakeCamera.orthographic = true;
        bakeCamera.depth = -10;
        bakeCamera.clearFlags = CameraClearFlags.Nothing;//Disable clear, avoid camera clear the result


        var bakePosMat = new Material(Shader.Find("Bake/BakePosShader"));
        var bakeNorMat = new Material(Shader.Find("Bake/BakeNorShader"));

        GL.PushMatrix();
        GL.LoadOrtho();
        var rtPOS = RenderTexture.GetTemporary(TextureSize, TextureSize, 0, RenderTextureFormat.ARGBFloat);
        Graphics.SetRenderTarget(rtPOS);
        GL.Clear(true, true, Color.clear);
        bakePosMat.SetPass(0);
        Graphics.DrawMeshNow(TargetMesh.sharedMesh, Matrix4x4.identity);
        // SaveTexture(rtPOS, "Position");//Debug output

        var rtNOR = RenderTexture.GetTemporary(TextureSize, TextureSize, 0, RenderTextureFormat.ARGBFloat);
        Graphics.SetRenderTarget(rtNOR);
        GL.Clear(true, true, Color.clear);
        bakeNorMat.SetPass(0);
        Graphics.DrawMeshNow(TargetMesh.sharedMesh, Matrix4x4.identity);
        // SaveTexture(rtNOR, "Normal");//Debug output
        GL.PopMatrix();
        DestroyImmediate(bakeCamera.gameObject);

        //Step 2：Bake the thickness to a map.
        var maxThick = TargetMesh.sharedMesh.bounds.size.magnitude * DepthMultiply;
        var rtThick = RenderTexture.GetTemporary(TextureSize, TextureSize, 0, RenderTextureFormat.Default);
        rtThick.enableRandomWrite = true;

        int kernelIndex = BakeThicknessCS.FindKernel("CSMain");
        var triangleBuffer = new ComputeBuffer(m_Triangles.Count(), Marshal.SizeOf<Triangle>());
        triangleBuffer.SetData(m_Triangles);
        int triangleBufferID = Shader.PropertyToID("triangleBuffer");
        var bvhBuffer = new ComputeBuffer(m_bvhs.Count(), Marshal.SizeOf<BvhData>());
        int bvhBufferID = Shader.PropertyToID("bvhBuffer");
        bvhBuffer.SetData(m_bvhs);
        int posTexID = Shader.PropertyToID("ModelSpacePosition");
        int norTexID = Shader.PropertyToID("ModelSpaceNormal");
        int resultTexID = Shader.PropertyToID("Result");
        int maxDepthID = Shader.PropertyToID("MaxDepth");
        int expID = Shader.PropertyToID("Exponent");

        BakeThicknessCS.SetTexture(kernelIndex, posTexID, rtPOS);
        BakeThicknessCS.SetTexture(kernelIndex, norTexID, rtNOR);
        BakeThicknessCS.SetTexture(kernelIndex, resultTexID, rtThick);
        BakeThicknessCS.SetBuffer(kernelIndex, triangleBufferID, triangleBuffer);
        BakeThicknessCS.SetBuffer(kernelIndex, bvhBufferID, bvhBuffer);
        BakeThicknessCS.SetFloat(maxDepthID, maxThick);
        BakeThicknessCS.SetFloat(expID, Exp);

        BakeThicknessCS.GetKernelThreadGroupSizes(kernelIndex, out var THREAD_X, out var THREAD_Y, out var _);
        BakeThicknessCS.Dispatch(kernelIndex, (int)math.ceil(TextureSize / (float)THREAD_X), (int)math.ceil(TextureSize / (float)THREAD_Y), 1);
        //Step 3.PostProcessing.Dilate to clear the uv border and do some gauss blur.
        var rtDilate = RenderTexture.GetTemporary(TextureSize, TextureSize, 0, RenderTextureFormat.Default);
        Graphics.Blit(rtThick, rtDilate, new Material(Shader.Find("Bake/Dilate")));
        var gaussMat = new Material(Shader.Find("Bake/GaussShader"));
        Graphics.Blit(rtDilate, rtThick, gaussMat, 0);
        Graphics.Blit(rtThick, rtDilate, gaussMat, 1);
        SaveTexture(rtDilate, $"{TargetMesh.gameObject.name}-thickness");
        sw.Stop();
        Debug.Log($"Thicknessmap baking complete!cost {sw.ElapsedMilliseconds} ms");
        rtPOS.Release();
        rtNOR.Release();
        rtDilate.Release();
        triangleBuffer.Release();
        bvhBuffer.Release();
    }
    void SaveTexture(RenderTexture rt, string mname)
    {
        string fullPath = Application.dataPath + "/BakedTextures/" + mname + ".png";
        byte[] _bytes = ToTexture2D(rt).EncodeToPNG();
        File.Delete(fullPath);
        File.WriteAllBytes(fullPath, _bytes);
    }
    Texture2D ToTexture2D(RenderTexture rTex)
    {
        Texture2D tex = new Texture2D(rTex.width, rTex.height, TextureFormat.RGBAFloat, false);
        RenderTexture.active = rTex;
        tex.ReadPixels(new Rect(0, 0, rTex.width, rTex.height), 0, 0);
        tex.Apply();
        RenderTexture.active = null;
        return tex;
    }
}
