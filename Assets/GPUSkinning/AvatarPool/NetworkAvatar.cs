using System;
using UnityEngine;

namespace ET.Client
{
    public class NetworkAvatar : MonoBehaviour
    {
        public ulong avatarID;
        public GPUSkinningPlayerMono mono;

        private void OnDestroy()
        {
            GameObject.Destroy(mono.gameObject);
        }
    }
}