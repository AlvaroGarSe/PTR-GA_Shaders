using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class UnderwaterToggle : MonoBehaviour
{
    [SerializeField] Transform waterPlane;
    [SerializeField] Volume underwaterVolume;
    [SerializeField] float enterOffset = 0.0f;
    [SerializeField] float exitOffset = 0.05f;

    [SerializeField] float exposurePerMeter = 1.0f; // ajusta esto

    private ColorAdjustments colorAdj;
    private bool underwater;

    void Awake()
    {
        underwater = false;
        if (underwaterVolume) underwaterVolume.weight = 0f;

        if (!underwaterVolume || !underwaterVolume.profile)
        {
            Debug.LogError("UnderwaterVolume o su Profile no está asignado.");
            enabled = false;
            return;
        }

        if (!underwaterVolume.profile.TryGet(out colorAdj) || colorAdj == null)
        {
            Debug.LogError("El Profile NO tiene un override de ColorAdjustments.");
            enabled = false;
            return;
        }

        // Asegura que el parámetro esté habilitado en el override
        colorAdj.postExposure.overrideState = true;
    }

    void Update()
    {
        float waterY = waterPlane.position.y;
        float camY = transform.position.y;

        if (!underwater)
        {
            if (camY < waterY - enterOffset)
            {
                underwater = true;
                underwaterVolume.weight = 1f;
            }
        }
        else
        {
            if (camY > waterY + exitOffset)
            {
                underwater = false;
                underwaterVolume.weight = 0f;
            }
        }

        if (underwater)
        {
            float depth = Mathf.Max(0f, waterY - camY); // metros bajo la superficie
            colorAdj.postExposure.value = -depth * exposurePerMeter;
        }
    }
}
