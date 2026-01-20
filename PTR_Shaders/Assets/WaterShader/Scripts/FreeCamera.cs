using UnityEngine;

public class FreeCamera : MonoBehaviour
{
    public float speed = 10f;
    public float mouseSensitivity = 2f;

    float rotX;
    float rotY;

    void Start()
    {
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
    }

    void Update()
    {
        Move();
        Look();
    }

    void Move()
    {
        float h = Input.GetAxis("Horizontal"); // A D
        float v = Input.GetAxis("Vertical");   // W S

        float up = 0f;
        if (Input.GetKey(KeyCode.Q)) up = -1f;
        if (Input.GetKey(KeyCode.E)) up = 1f;

        Vector3 dir = new Vector3(h, up, v);
        transform.Translate(dir * speed * Time.deltaTime, Space.Self);
    }

    void Look()
    {
        float mx = Input.GetAxis("Mouse X") * mouseSensitivity * 100f * Time.deltaTime;
        float my = Input.GetAxis("Mouse Y") * mouseSensitivity * 100f * Time.deltaTime;

        rotY += mx;
        rotX -= my;
        rotX = Mathf.Clamp(rotX, -90f, 90f);

        transform.rotation = Quaternion.Euler(rotX, rotY, 0f);
    }
}
