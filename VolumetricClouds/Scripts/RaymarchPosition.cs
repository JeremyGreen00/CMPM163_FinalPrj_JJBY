using UnityEngine;

public class RaymarchPosition : MonoBehaviour
{
    Material material;
    Vector3 lastPosition;

    public void Awake()
    {
        material = GetComponentInChildren<Renderer>().material;
    }

    public void Update()
    {
        ShaderVariables.allRaySpheres.Add(transform.position);

        //if (transform.position != lastPosition 
        //    && material != null)
        //{            
        //    material.SetVector("_Position", transform.position);
        //}

        //lastPosition = transform.position;
    }
}
