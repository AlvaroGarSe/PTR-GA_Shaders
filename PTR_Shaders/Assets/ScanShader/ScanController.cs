using System.Collections.Generic;
using UnityEngine;

public class ScanController : MonoBehaviour
{
    public KeyCode key = KeyCode.E;

    public float speed = 25f;
    public float maxDistance = 200f;
    public float detectWidth = 0.75f;

    private readonly List<ScanItem> scannables = new();

    private bool scanActive;
    private float scanDistance;
    private Vector3 scanOrigin;
    private int scanId = 0;

    // Global variables to control the shader
    private static readonly int ScanOriginID = Shader.PropertyToID("_GlobalScanOrigin");
    private static readonly int ScanDistanceID = Shader.PropertyToID("_GlobalScanDistance");
    private static readonly int ScanEnabledID = Shader.PropertyToID("_GlobalScanEnabled");
    void OnEnable()
    {
        ResetAll();
    }

    void OnDisable()
    {
        ResetAll();
    }

    // Register and Unregister functions called from the ScanItem.cs to enter on the ScanItem list
    public void Register(ScanItem s)
    {
        if (s != null && !scannables.Contains(s)) scannables.Add(s);
    }

    public void Unregister(ScanItem s)
    {
        if (s != null) scannables.Remove(s);
    }

    public int StartScan()
    {
        // Scan id to not call more than once the scan trigger
        scanId++;
        scanOrigin = transform.position;
        scanDistance = 0f;
        scanActive = true;

        // Start shader
        Shader.SetGlobalVector(ScanOriginID, scanOrigin);
        Shader.SetGlobalFloat(ScanDistanceID, 0f);
        Shader.SetGlobalFloat(ScanEnabledID, 1f);

        return scanId;
    }

    void Update()
    {
        if (Input.GetKeyDown(key))
        {
            StartScan();
        }

        if (!scanActive) return;

        scanDistance += speed * Time.deltaTime;

        // Update shader with global variables
        Shader.SetGlobalVector(ScanOriginID, scanOrigin);
        Shader.SetGlobalFloat(ScanDistanceID, scanDistance);

        // End Shader if reaches max distance
        if (scanDistance >= maxDistance)
        {
            scanActive = false;
            ResetShaderGlobals();
            return;
        }

        // Check and clears scannable items
        for (int i = scannables.Count - 1; i >= 0; i--)
        {
            if (scannables[i] == null) scannables.RemoveAt(i);
        }

        // Detect items
        for (int i = 0; i < scannables.Count; i++)
        {
            ScanItem s = scannables[i];
            if (s == null) continue;

            float dx = s.transform.position.x - scanOrigin.x;
            float dz = s.transform.position.z - scanOrigin.z;
            float dist = Mathf.Sqrt(dx * dx + dz * dz);

            if (Mathf.Abs(dist - scanDistance) <= detectWidth)
            {
                s.TryMarkScanned(scanId);
            }
        }
    }

    public void ResetAll()
    {
        scanActive = false;
        scanDistance = 0f;
        scanOrigin = Vector3.zero;

        ResetShaderGlobals();

        // Unmark all ScanItems
        for (int i = scannables.Count - 1; i >= 0; i--)
        {
            if (scannables[i] == null) { scannables.RemoveAt(i); continue; }
            scannables[i].ResetMark();
        }
    }

    private static void ResetShaderGlobals()
    {
        Shader.SetGlobalFloat(ScanEnabledID, 0f);
        Shader.SetGlobalFloat(ScanDistanceID, 0f);
        Shader.SetGlobalVector(ScanOriginID, Vector4.zero);
    }
}