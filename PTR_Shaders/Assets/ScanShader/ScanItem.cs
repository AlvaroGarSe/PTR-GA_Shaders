using UnityEngine;

public class ScanItem : MonoBehaviour
{
    private ScanController scanController;

    public GameObject scanBeam;

    public float markDuration = 5;

    private int lastPulseIdMarked = -1;
    private float markTimer;

    private void Awake()
    {
        scanController = FindAnyObjectByType<ScanController>();
    }

    void OnEnable()
    {
        scanController.Register(this);

        if (scanBeam != null) scanBeam.SetActive(false);
    }

    void OnDisable()
    {
        scanController.Unregister(this);
    }

    void Update()
    {
        if (scanBeam == null || !scanBeam.activeSelf) return;

        if (markDuration > 0f)
        {
            markTimer -= Time.deltaTime;
            if (markTimer <= 0f)
            {
                scanBeam.SetActive(false);
            }
        }
    }

    // Called by the ScanController When the scan is on this position
    public void TryMarkScanned(int pulseId)
    {
        if (pulseId == lastPulseIdMarked) return;
        lastPulseIdMarked = pulseId;

        if (scanBeam != null)
        {
            scanBeam.SetActive(true);
            markTimer = markDuration;
        }
    }

    public void ResetMark()
    {
        lastPulseIdMarked = -1;
        markTimer = 0f;
        if (scanBeam != null) scanBeam.SetActive(false);
    }    
}