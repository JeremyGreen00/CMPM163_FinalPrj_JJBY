// Taken from Sirenix at http://www.blog.sirenix.net/blog/realtime-volumetric-clouds-in-unity

using UnityEngine;
using System.Collections.Generic;

public class ShaderVariables : MonoBehaviour
{
   [SerializeField]
   private Texture2D noiseOffsetTexture;

   public static List<Vector4> allRaySpheres;
    public Camera cam;

   private void Awake()
   {
      allRaySpheres = new List<Vector4>(10000);

      Shader.SetGlobalTexture("_NoiseOffsets", this.noiseOffsetTexture);
   }

   private void OnRenderImage(RenderTexture sourceTexture, RenderTexture destTexture)
   {
      // A lot of these may be better off in another class.
      if (RenderSettings.sun != null)
      {
         Shader.SetGlobalColor("_LightColor", RenderSettings.sun.color);
         Shader.SetGlobalVector("_LightDir", RenderSettings.sun.transform.forward);
      }

     // Shader.SetGlobalVectorArray("_AllSpheres", allRaySpheres.ToArray());
    if(cam != null)
        {
            // Position and rotation of camera
            Shader.SetGlobalVector("_CamPos", cam.transform.position);
            Shader.SetGlobalVector("_CamRight", cam.transform.right);
            Shader.SetGlobalVector("_CamUp", cam.transform.up);
            Shader.SetGlobalVector("_CamForward", cam.transform.forward);
        }
    else
        {
            // Position and rotation of camera
            Shader.SetGlobalVector("_CamPos", this.transform.position);
            Shader.SetGlobalVector("_CamRight", this.transform.right);
            Shader.SetGlobalVector("_CamUp", this.transform.up);
            Shader.SetGlobalVector("_CamForward", this.transform.forward);
        }

      // Screen parameters
      Shader.SetGlobalFloat("_AspectRatio", (float)Screen.width / (float)Screen.height);
      Shader.SetGlobalFloat("_FieldOfView", Mathf.Tan(Camera.main.fieldOfView * Mathf.Deg2Rad * 0.5f) * 2f);

        Graphics.Blit(sourceTexture, destTexture);
    }

   public void OnPostRender()
   {
      allRaySpheres.Clear();
   }
}
