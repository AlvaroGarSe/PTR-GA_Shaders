using System.Linq;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

public class ScanOverlayTool : EditorWindow
{
    [SerializeField] private Material overlayMaterial;
    [SerializeField] private bool includeInactive = true;
    [SerializeField] private bool avoidDuplicates = true;

    [SerializeField] private bool skipParticleSystemRenderers = true;
    [SerializeField] private bool skipTrailRenderers = true;
    [SerializeField] private bool skipLineRenderers = true;

    [MenuItem("Tools/Scanner/Scan Overlay Tool")]
    public static void Open()
    {
        var w = GetWindow<ScanOverlayTool>("Scan Overlay Tool");
        w.minSize = new Vector2(360, 260);
        w.Show();
    }

    private void OnGUI()
    {
        EditorGUILayout.LabelField("Scan Overlay (Editor Tool)", EditorStyles.boldLabel);
        EditorGUILayout.Space(6);

        overlayMaterial = (Material)EditorGUILayout.ObjectField(
            new GUIContent("Overlay Material", "Material que usa el shader Custom/URP/ScanOverlay"),
            overlayMaterial,
            typeof(Material),
            false
        );

        EditorGUILayout.Space(6);
        includeInactive = EditorGUILayout.ToggleLeft("Incluir objetos inactivos", includeInactive);
        avoidDuplicates = EditorGUILayout.ToggleLeft("Evitar duplicados", avoidDuplicates);

        EditorGUILayout.Space(6);
        EditorGUILayout.LabelField("Omitir tipos (opcional)", EditorStyles.boldLabel);
        skipParticleSystemRenderers = EditorGUILayout.ToggleLeft("Omitir ParticleSystemRenderer", skipParticleSystemRenderers);
        skipTrailRenderers = EditorGUILayout.ToggleLeft("Omitir TrailRenderer", skipTrailRenderers);
        skipLineRenderers = EditorGUILayout.ToggleLeft("Omitir LineRenderer", skipLineRenderers);

        EditorGUILayout.Space(12);

        using (new EditorGUI.DisabledScope(overlayMaterial == null))
        {
            if (GUILayout.Button("Aplicar a TODA la escena", GUILayout.Height(32)))
                ApplyToScene();

            if (GUILayout.Button("Aplicar a SELECCIÓN", GUILayout.Height(28)))
                ApplyToSelection();

            EditorGUILayout.Space(8);

            if (GUILayout.Button("Quitar de TODA la escena", GUILayout.Height(28)))
                RemoveFromScene();

            if (GUILayout.Button("Quitar de SELECCIÓN", GUILayout.Height(28)))
                RemoveFromSelection();
        }

        EditorGUILayout.Space(10);
        EditorGUILayout.HelpBox(
            "Nota: Esto afecta solo a Renderers (MeshRenderer/SkinnedMeshRenderer, etc.). " +
            "Terrain no usa Renderer normal: si tu escena tiene Terrain, dímelo y te paso la extensión.",
            MessageType.Info
        );
    }

    private bool ShouldSkip(Renderer r)
    {
        if (skipParticleSystemRenderers && r is ParticleSystemRenderer) return true;
        if (skipTrailRenderers && r is TrailRenderer) return true;
        if (skipLineRenderers && r is LineRenderer) return true;
        return false;
    }

    private bool HasOverlay(Renderer r)
    {
        var mats = r.sharedMaterials;
        if (mats == null) return false;
        return mats.Any(m => m != null && m == overlayMaterial);
    }

    private void Apply(Renderer[] renderers)
    {
        if (overlayMaterial == null)
        {
            Debug.LogError("ScanOverlayTool: falta overlayMaterial.");
            return;
        }

        int changed = 0;

        Undo.IncrementCurrentGroup();
        int undoGroup = Undo.GetCurrentGroup();

        foreach (var r in renderers)
        {
            if (r == null) continue;
            if (ShouldSkip(r)) continue;

            var mats = r.sharedMaterials;
            if (mats == null || mats.Length == 0) continue;

            if (avoidDuplicates && HasOverlay(r)) continue;

            Undo.RecordObject(r, "Add Scan Overlay Material");

            var newMats = mats.Concat(new[] { overlayMaterial }).ToArray();
            r.sharedMaterials = newMats;

            changed++;
            EditorUtility.SetDirty(r);
        }

        Undo.CollapseUndoOperations(undoGroup);

        if (changed > 0)
            MarkSceneDirty();

        Debug.Log($"ScanOverlayTool: Overlay aplicado a {changed} renderers.");
    }

    private void Remove(Renderer[] renderers)
    {
        if (overlayMaterial == null)
        {
            Debug.LogError("ScanOverlayTool: falta overlayMaterial.");
            return;
        }

        int changed = 0;

        Undo.IncrementCurrentGroup();
        int undoGroup = Undo.GetCurrentGroup();

        foreach (var r in renderers)
        {
            if (r == null) continue;
            if (ShouldSkip(r)) continue;

            var mats = r.sharedMaterials;
            if (mats == null || mats.Length == 0) continue;

            if (!HasOverlay(r)) continue;

            Undo.RecordObject(r, "Remove Scan Overlay Material");

            var newMats = mats.Where(m => m != overlayMaterial).ToArray();
            r.sharedMaterials = newMats;

            changed++;
            EditorUtility.SetDirty(r);
        }

        Undo.CollapseUndoOperations(undoGroup);

        if (changed > 0)
            MarkSceneDirty();

        Debug.Log($"ScanOverlayTool: Overlay quitado de {changed} renderers.");
    }

    private Renderer[] GetSceneRenderers()
    {
        // Nota: FindObjectsByType existe en Unity 2022+. Para compatibilidad amplia, usamos FindObjectsOfType.
        var all = Resources.FindObjectsOfTypeAll<Renderer>();

        // Filtramos cosas del editor/prefabs no instanciados:
        return all
            .Where(r => r != null)
            .Where(r => !EditorUtility.IsPersistent(r)) // evita assets/prefabs en Project
            .Where(r => includeInactive || r.gameObject.activeInHierarchy)
            .ToArray();
    }

    private Renderer[] GetSelectionRenderers()
    {
        var gos = Selection.gameObjects;
        if (gos == null || gos.Length == 0) return new Renderer[0];

        return gos
            .SelectMany(go => go.GetComponentsInChildren<Renderer>(includeInactive))
            .Distinct()
            .Where(r => r != null)
            .ToArray();
    }

    private void ApplyToScene() => Apply(GetSceneRenderers());
    private void RemoveFromScene() => Remove(GetSceneRenderers());

    private void ApplyToSelection()
    {
        var rs = GetSelectionRenderers();
        if (rs.Length == 0)
        {
            Debug.LogWarning("ScanOverlayTool: no hay renderers en la selección.");
            return;
        }
        Apply(rs);
    }

    private void RemoveFromSelection()
    {
        var rs = GetSelectionRenderers();
        if (rs.Length == 0)
        {
            Debug.LogWarning("ScanOverlayTool: no hay renderers en la selección.");
            return;
        }
        Remove(rs);
    }

    private static void MarkSceneDirty()
    {
        var scene = EditorSceneManager.GetActiveScene();
        if (scene.IsValid())
            EditorSceneManager.MarkSceneDirty(scene);
    }
}
