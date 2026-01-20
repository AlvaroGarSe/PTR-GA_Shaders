using UnityEngine;

public class ScanController : MonoBehaviour
{
    [Header("Scan Settings")]
    public float speed = 25f;            // unidades mundo/segundo
    public float maxDistance = 200f;     // hasta dónde llega el escaneo

    [Header("Optional: set in inspector or use input")]
    public KeyCode key = KeyCode.E;

    private bool scanning;
    private float currentDistance;

    // IDs para evitar strings cada frame
    private static readonly int ScanOriginID = Shader.PropertyToID("_GlobalScanOrigin");
    private static readonly int ScanDistanceID = Shader.PropertyToID("_GlobalScanDistance");
    private static readonly int ScanEnabledID = Shader.PropertyToID("_GlobalScanEnabled");

    void Update()
    {
        if (Input.GetKeyDown(key))
        {
            Debug.Log("StartScan!");
            StartScan();
        }

        if (!scanning) return;
        Debug.Log($"Scan d={currentDistance} origin={transform.position}");

        currentDistance += speed * Time.deltaTime;

        Shader.SetGlobalVector(ScanOriginID, transform.position);
        Shader.SetGlobalFloat(ScanDistanceID, currentDistance);
        Shader.SetGlobalFloat(ScanEnabledID, 1f);

        if (currentDistance >= maxDistance)
        {
            scanning = false;
            Shader.SetGlobalFloat(ScanEnabledID, 0f);
        }
    }

    public void StartScan()
    {
        scanning = true;
        currentDistance = 0f;

        Shader.SetGlobalVector(ScanOriginID, transform.position);
        Shader.SetGlobalFloat(ScanDistanceID, 0f);
        Shader.SetGlobalFloat(ScanEnabledID, 1f);
    }
}
