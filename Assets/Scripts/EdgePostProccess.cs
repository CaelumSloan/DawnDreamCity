using UnityEngine;

[ExecuteInEditMode]
public class EdgePostProccess : MonoBehaviour
{
    public Material material;

    private void Awake()
    {
        GetComponent<Camera>().depthTextureMode = DepthTextureMode.DepthNormals;

    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        Graphics.Blit(src, dest, material);
    }
}