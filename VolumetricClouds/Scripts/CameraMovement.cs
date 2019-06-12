using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraMovement : MonoBehaviour
{
    [SerializeField] private float fadePerSecond = 2.5f;
    Renderer rend;
    Camera cam;
    Vector3 movePosition = Vector3.zero;
    Vector3 CamRot = Vector3.zero;
    // Start is called before the first frame update
    void Start()
    {
        cam = GetComponent<Camera>();
        rend = GetComponent<Renderer>();
    }

    // Update is called once per frame
    void Update() {
        // Move the object forward along its z axis 1 unit/second.
        //transform.Translate(transform.position.x + Input.GetAxis("Horizontal"), 0, transform.position.z + Input.GetAxis("Vertical"));
        movePosition = cam.transform.forward * Input.GetAxis("Vertical") * 0.1f + cam.transform.right * Input.GetAxis("Horizontal") * 0.1f;
        CamRot = new Vector3(Input.GetAxis("Mouse Y"), Input.GetAxis("Mouse X") * -1, 0);
        //Debug.Log(Input.GetAxis("Vertical") + " " + Input.GetAxis("Horizontal"));
        transform.position += movePosition;
        transform.eulerAngles = transform.eulerAngles - CamRot;

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
