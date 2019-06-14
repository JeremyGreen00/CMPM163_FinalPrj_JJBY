using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SetPosition : MonoBehaviour
{
    public Transform location;
    private Renderer rend;
    // Start is called before the first frame update
    void Start()
    {
        rend = GetComponent<Renderer>();
        if (location != null)
            rend.material.SetVector("_Centre", location.position);
        else
            rend.material.SetVector("_Centre", this.transform.position);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
