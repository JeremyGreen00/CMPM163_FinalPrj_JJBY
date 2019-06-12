using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Visibility : MonoBehaviour
{
    Renderer rend;
    float count;
    // Start is called before the first frame update
    void Start()
    {
        rend = GetComponent<Renderer>();
        rend.enabled = false;

        count = 0;
    }

    // Update is called once per frame
    void Update()
    {
        count++;
        if(count/100 >= 3.4) {
            rend.enabled = true;
        }
        //Debug.Log(count/100);
    }
}
