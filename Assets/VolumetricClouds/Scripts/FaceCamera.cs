using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FaceCamera : MonoBehaviour
{
    [Tooltip("Set the camera to face. If no camera assigned, uses Camera.main.")]
    public Camera toFace;

    // Use this for initialization
    void Start()
    {
        if (toFace == null)
        {
            toFace = Camera.main;
        }
    }

    // Update is called once per frame
    void Update()
    {
        if (toFace != null)
        {
            Quaternion lookRot = Quaternion.LookRotation(transform.position - toFace.transform.position);
            transform.rotation = lookRot;
        }
    }
}
