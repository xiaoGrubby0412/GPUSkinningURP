using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using ET.Client;

public class AvatarPool
{
    private static AvatarPool _instance = null;

    public static AvatarPool Instance
    {
        get
        {
            if (_instance == null)
            {
                _instance = new AvatarPool();
            }
            return _instance;
        }
    }

    public bool ifInited = false;

    private UnityEngine.Object f5 = null;
    private UnityEngine.Object f7 = null;
    private UnityEngine.Object f3 = null;
    private UnityEngine.Object m5 = null;
    private UnityEngine.Object m7 = null;
    private UnityEngine.Object m3 = null;
    private UnityEngine.Object f7YuanBang = null;
    private UnityEngine.Object m7YuanBang = null;

    private Transform PoolRootTrans;
    private ulong[] ids = new ulong[] { 10000, 10001, 10002, 10003, 10004, 10005, 10006, 10007 };
    private int cacheCount = 10;
    private List<NetworkAvatar> lst;
    public void Init()
    {
        // string path = AvatarProc.GetPlayerAvatarModelName(10000);
        // f5 = ABResources.Load<UnityEngine.Object>(path);
        // path = AvatarProc.GetPlayerAvatarModelName(10001);
        // f7 = ABResources.Load<UnityEngine.Object>(path);
        // path = AvatarProc.GetPlayerAvatarModelName(10002);
        // f3 = ABResources.Load<UnityEngine.Object>(path);
        // path = AvatarProc.GetPlayerAvatarModelName(10003);
        // m5 = ABResources.Load<UnityEngine.Object>(path);
        // path = AvatarProc.GetPlayerAvatarModelName(10004);
        // m7 = ABResources.Load<UnityEngine.Object>(path);
        // path = AvatarProc.GetPlayerAvatarModelName(10005);
        // m3 = ABResources.Load<UnityEngine.Object>(path);
        // path = AvatarProc.GetPlayerAvatarModelName(10006);
        // f7YuanBang = ABResources.Load<UnityEngine.Object>(path);
        // path = AvatarProc.GetPlayerAvatarModelName(10007);
        // m7YuanBang = ABResources.Load<UnityEngine.Object>(path);
            
        f5 = Resources.Load("female5");
        f7 = Resources.Load("female7"); 
        f3 = Resources.Load("female3");
        m5 = Resources.Load("male5");
        m7 = Resources.Load("male7");
        m3 = Resources.Load("male3");
        f7YuanBang = Resources.Load("female7YuanBang");
        m7YuanBang = Resources.Load("male7YuanBang");

        PoolRootTrans = new GameObject("PoolRoot").transform;
        GameObject.DontDestroyOnLoad(PoolRootTrans.gameObject);
        PoolRootTrans.position = Vector3.zero;
        PoolRootTrans.rotation = Quaternion.identity;
        PoolRootTrans.localScale = Vector3.one;
        
        lst = new List<NetworkAvatar>(ids.Length * cacheCount);
        
        for (int j = 0; j < ids.Length; j++)
        {
            for (int i = 0; i < cacheCount; i++)
            {
                NetworkAvatar avatar = CacheAvatar(ids[j]);
                lst.Add(avatar);
            }
        }

        ifInited = true;
    }

    public GPUSkinningPlayerMono CreateAvatarByID(ulong avatarID)
    {
        UnityEngine.Object obj = null;
        UnityEngine.GameObject go = null;
        GPUSkinningPlayerMono mono = null;
        switch (avatarID)
        {
            case 10000:
                obj = f5;
                break;
            case 10001:
                obj = f7;
                break;
            case 10002:
                obj = f3;
                break;
            case 10003:
                obj = m5;
                break;
            case 10004:
                obj = m7;
                break;
            case 10005:
                obj = m3;
                break;
            case 10006:
                obj = f7YuanBang;
                break;
            case 10007:
                obj = m7YuanBang;
                break;
        }

        if (obj == null)
        {
            Debug.LogError("in CreateAvatarByID obj == null AvatarID == " + avatarID);
        }

        go = UnityEngine.GameObject.Instantiate(obj) as GameObject;
        return go.GetComponent<GPUSkinningPlayerMono>();
    }

    private NetworkAvatar CacheAvatar(ulong avatarID)
    {
        GPUSkinningPlayerMono mono = CreateAvatarByID(avatarID);
        mono.gameObject.SetActive(false);
        mono.transform.SetParent(PoolRootTrans);
        NetworkAvatar avatar = mono.gameObject.AddComponent<NetworkAvatar>();
        avatar.avatarID = avatarID;
        avatar.mono = mono;
        return avatar;
    }

    public NetworkAvatar GetAvatar(ulong avatarID)
    {
        int rId = -1;
        for (int i = 0; i < lst.Count; i++)
        {
            if (lst[i] != null && lst[i].avatarID == avatarID)
            {
                rId = i;
                break;
            }
        }

        if (rId != -1)
        {
            NetworkAvatar avatar = lst[rId]; 
            lst.RemoveAt(rId);
            return avatar;
        }
        else
        {
            GPUSkinningPlayerMono mono = CreateAvatarByID(avatarID);
            NetworkAvatar avatar = mono.gameObject.AddComponent<NetworkAvatar>();
            avatar.avatarID = avatarID;
            avatar.mono = mono;
            avatar.gameObject.layer = LayerMask.NameToLayer("Player");
            return avatar;   
        }
    }

    public void RecycleAvatar(NetworkAvatar avatar)
    {
        lst.Add(avatar);
        if (avatar.mono.Player != null)
        {
            avatar.mono.Player.Play("idle");   
        }
        avatar.mono.gameObject.SetActive(false);
        avatar.mono.transform.SetParent(PoolRootTrans);
    }

    public void OnDestroy()
    {
        if (lst != null && lst.Count > 0)
        {
            for (int i = 0; i < lst.Count; i++)
            {
                GameObject.Destroy(lst[i].gameObject);
            }
        }
    }

}
