using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Rotate : MonoBehaviour
{
    [SerializeField] float speed = .1f;
    [SerializeField] Vector3 dir = Vector3.up;

    // Update is called once per frame
    void Update()
    {
        transform.Rotate(dir, speed);
    }
}
