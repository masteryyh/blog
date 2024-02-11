---
title: Kubernetes E01 - 第一次握手
tags:
  - Kubernetes
  - 运维
categories:
  - Kubernetes
date: 2024-02-09 07:08:39
---

![first-handshake](/assets/first-handshake.png "First Handshake")

## 第一次握手

启动一个 K3s 单节点集群

```bash
$ curl -sfL https://get.k3s.io | sh -
```

等待片刻，查看节点状态

```bash
$ sudo kubectl get nodes
NAME     STATUS   ROLES                  AGE   VERSION
ubuntu   Ready    control-plane,master   58s   v1.28.6+k3s2
```

<!--more-->
查看各个 Pod 状态

```bash
$ sudo kubectl get pods -A
NAMESPACE     NAME                                      READY   STATUS      RESTARTS   AGE
kube-system   coredns-6799fbcd5-5mzpk                   1/1     Running     0          48s
kube-system   local-path-provisioner-84db5d44d9-t879k   1/1     Running     0          48s
kube-system   helm-install-traefik-crd-gf2g7            0/1     Completed   0          48s
kube-system   helm-install-traefik-ss2bx                0/1     Completed   1          48s
kube-system   svclb-traefik-11d3b09d-954bm              2/2     Running     0          29s
kube-system   traefik-f4564c4f4-66tng                   1/1     Running     0          29s
kube-system   metrics-server-67c658944b-fhgj8           1/1     Running     0          48s
```

对外公布第一个网页

```yaml
---
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:alpine
          ports:
            - name: http
              containerPort: 80
---
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 8080
      targetPort: http
```

部署这些资源

```bash
$ sudo kubectl apply -f deployment.yaml
deployment.apps/nginx created

$ sudo kubectl apply -f service.yaml
service/nginx created
```

等待一会，查看刚才部署的 Pod 状态

```bash
$ sudo kubectl get pods
NAME                     READY   STATUS    RESTARTS   AGE
nginx-7494f5f88c-9t9wq   1/1     Running   0          33s
nginx-7494f5f88c-6bb2v   1/1     Running   0          33s
nginx-7494f5f88c-zvsgz   1/1     Running   0          33s
```

查看 Service 状态

```bash
$ sudo kubectl get svc
NAME         TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)          AGE
kubernetes   ClusterIP      10.43.0.1       <none>           443/TCP          11m
nginx        LoadBalancer   10.43.137.170   172.24.152.126   8080:30797/TCP   57s
```

用 curl 测试一下是否能正常访问

```bash
$ curl --head http://172.24.152.126:8080
HTTP/1.1 200 OK
Server: nginx/1.25.3
Date: Fri, 09 Feb 2024 13:39:24 GMT
Content-Type: text/html
Content-Length: 615
Last-Modified: Tue, 24 Oct 2023 16:48:50 GMT
Connection: keep-alive
ETag: "6537f572-267"
Accept-Ranges: bytes
```