using System.Collections;
using System.Collections.Generic;
using ET.Client;
using UnityEngine;

public class TestAvatarPool : MonoBehaviour
{
    private Transform root;

    public List<NetworkAvatar> lst;
    // Start is called before the first frame update
    void Start()
    {
        root = new GameObject("root").transform;
        lst = new List<NetworkAvatar>();
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            if (AvatarPool.Instance.ifInited == false)
            {
                AvatarPool.Instance.Init();
            }

            NetworkAvatar avatar = AvatarPool.Instance.GetAvatar(10000);
            avatar.mono.transform.SetParent(root);
            avatar.mono.transform.localScale = Vector3.one;
            avatar.mono.transform.localRotation = Quaternion.identity;
            avatar.mono.transform.localPosition =
                new Vector3(Random.Range(0f, 10f), Random.Range(0f, 10f), Random.Range(0f, 10f));
            avatar.mono.gameObject.SetActive(true);
            //mono.Player.CrossFade("run", 0.1f);
            //StartCoroutine(PlayAnim(avatar.mono));
            lst.Add(avatar);
            
            RecycleAvatar();
        }

        if (Input.GetKeyDown(KeyCode.A))
        {
            AvatarPool.Instance.AddAvatarToPool();
        }

        if (Input.GetKeyDown(KeyCode.T))
        {
            NetworkAvatar avatar = AvatarPool.Instance.GetAvatar(10000);
            avatar.mono.transform.SetParent(root);
            avatar.mono.transform.localScale = Vector3.one;
            avatar.mono.transform.localRotation = Quaternion.identity;
            avatar.mono.transform.localPosition =
                new Vector3(Random.Range(0f, 10f), Random.Range(0f, 10f), Random.Range(0f, 10f));
            avatar.mono.gameObject.SetActive(true);
            lst.Add(avatar);
            StartCoroutine(PlayAnim(avatar.mono));
        }

        if (Input.GetKeyDown(KeyCode.R))
        {
            RecycleAvatar();
        }

        if (Input.GetKeyDown(KeyCode.E))
        {
            AvatarPool.Instance.OnDestroy();
        }
    }
    
    private void RecycleAvatar()
    {
        //test recycle
        GPUSkinningPlayerMono mono = root.GetChild(0).GetComponent<GPUSkinningPlayerMono>();
        NetworkAvatar avatar = RemoveAvatar(mono);
        AvatarPool.Instance.RecycleAvatar(avatar);
    }

    private NetworkAvatar RemoveAvatar(GPUSkinningPlayerMono mono)
    {
        int rID = -1;
        for (int i = 0; i < lst.Count; i++)
        {
            if (lst[i].mono == mono)
            {
                rID = i;
                break;
            }
        }

        if (rID != -1)
        {
            NetworkAvatar avatar = lst[rID]; 
            lst.RemoveAt(rID);
            return avatar;
        }
        else
        {
            Debug.LogError("No Rid Found !!");
            return null;
        }
    }

    private IEnumerator PlayAnim(GPUSkinningPlayerMono mono)
    {
        yield return 1;
        mono.Player.CrossFade("run", 0.2f);
    }
}
