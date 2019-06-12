using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraMovement : MonoBehaviour
{
    [SerializeField] private float fadePerSecond = 2.5f;
    Renderer rend;
    Camera cam; 
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update() {
        // Move the object forward along its z axis 1 unit/second.
        transform.Translate(0, 0, Time.deltaTime);

        rend = GetComponent<Renderer>();
       // cam = GetComponent<Camera>();
        rend.material.shader = Shader.Find("Volumetric Clouds/Raymarch Example With Cam");

        Color color = rend.material.GetColor("_Color");
        
        if(color.a >= 0) {
            color = new Color(color.r, color.g, color.b, color.a - (fadePerSecond * Time.deltaTime));
            rend.material.SetColor("_Color", color);
          //  print(color.a);
        } 
        // else {
        //      cam.enabled = false;
        //      print("toggle");
        // }
       // inspector color doesnt change

       
       // material.color = new Color(color.r, color.g, color.b, color.a - (fadePerSecond * Time.deltaTime));
       // Debug.Log(material.color.a);
    }
}
