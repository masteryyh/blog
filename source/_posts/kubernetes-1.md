---
title: Kubernetes E01 - 基本
tags:
  - Kubernetes
  - 运维
categories:
  - Kubernetes
date: 2024-02-13 12:40:36
---


## 不太重要的简介

来一段 Wiki 的介绍：

> Kubernetes（常简称为K8s）是用于自动部署、扩展和管理“容器化（containerized）应用程序”的开源系统。该系统由Google设计并捐赠给Cloud Native Computing Foundation（今属Linux基金会）来使用。
> 它旨在提供“跨主机集群的自动部署、扩展以及运行应用程序容器的平台”。它支持一系列容器工具，包括Docker等。

反正 Wiki 的介绍看看就行。简而言之，Kubernetes 是一个容器编排引擎，用于管理和编排容器化应用程序。

## 基本组件和架构

### 架构

Kubernetes 中的计算机被称为节点 (node) ，并且分为两种：主节点 (Master Node, 也叫控制节点 Control Plane Node) 和工作节点 (Worker Node) 。主节点负责运行集群中的关键组件，支撑整个集群的运行，而工作节点负责运行用户所部署的应用负载。

集群上的工作负载由 Kubernetes 来统一编排到不同的工作节点。而容器运行时、网络和存储等基础设施也由 Kubernetes 来管理，具体由几种统一接口来实现：

- 容器运行时接口 (CRI, Container Runtime Interface) ：用于管理容器的生命周期；

- 容器网络接口 (CNI, Container Network Interface) ：支撑了节点和容器之间的网络通信；

- 存储接口 (CSI, Container Storage Interface) ：用于管理容器的持久化存储。

整体架构可以由这张图展现：

![architecture](/assets/k8s-arch.png "Kubernetes Architecture")

### 组件

一个使用官方 Kubernetes 发行版的集群控制节点上，通常包含了三个组件：

- kubeadm: 用于安装和初始化集群的工具；

- kubelet: 负责管理节点上的容器和 Pod；

- kubectl: 用于与集群交互的命令行工具。

在第一篇中，由于使用了 K3s 来安装节点，因此不会包含 kubeadm 组件。

一个 Kubernetes 集群的控制面通常包含了以下的组件：

- kube-apiserver: 集群的 API 服务器，是整个 Kubernetes 集群控制面的前端，由于 Kubernetes API 的设计是基于声明式的 API ，因此它的 API 形式也与一般的 Web Service RESTful API 不同；

- etcd: 集群中的 Key-Value 数据库，用于存储各种对象数据；

- kube-scheduler: 用于调度尚未分配到指定节点的 Pod 到不同的可调度节点上的调度器；

- kube-controller-manager: 用于运行 Kubernetes 内置的控制器；

- cloud-controller-manager: 用于运行公有云或特定 Kubernetes 发行版所提供的特殊功能的控制器；

## 声明式 API 和控制器

> 在 Kubernetes 中，一切皆为对象。

与常规的 RESTful API 不同，Kubernetes API 是声明式的，也就是说用户仅需要提交用户所希望的结果，而不需要去关心实现所希望的结果的步骤。

而 Kubernetes 中的控制器将会持续地检测和更新对象状态，将状态调整为用户所希望的状态，这一行为被称为 "Reconcile" 。

为了帮助理解，我们可以把 Kubernetes 想象成一台空调，可以控制目标温度和风速。

> K8s 牌空调，当前温度：26℃，目标温度：26℃，风速：低

26℃小风怎么够爽！开到16℃最大风。

> K8s 牌空调，当前温度：26℃，目标温度：26℃，风速：低
> 遥控器：设置目标温度16℃，风速：高

> K8s 牌空调，当前温度：26℃，目标温度：16℃，风速：高

遥控器会将用户设置的所有值，也就是目标温度：16℃，风速：高编码后发送给空调。
空调收到这两个值后首先将风速调整为高，其次开始启动压缩机，将温度降为目标温度。

于是在压缩机和高风速的努力下，环境温度逐渐下降。

> K8s 牌空调，当前温度：24℃，目标温度：16℃，风速：高

> K8s 牌空调，当前温度：22℃，目标温度：16℃，风速：高

> K8s 牌空调，当前温度：20℃，目标温度：16℃，风速：高
> ...

空调会持续将当前的环境温度调整为用户所希望的环境温度。

回到 Kubernetes 本身，用户提交的对象状态就是用户所希望的环境温度，而控制器就是空调，持续地将环境温度调整为用户所希望的环境温度。

以一个典型的 Deployment 为例：

```yaml
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
status:
  availableReplicas: 3
  conditions:
  - lastTransitionTime: "2024-02-09T13:37:14Z"
    lastUpdateTime: "2024-02-09T13:37:14Z"
    message: Deployment has minimum availability.
    reason: MinimumReplicasAvailable
    status: "True"
    type: Available
  - lastTransitionTime: "2024-02-09T13:37:04Z"
    lastUpdateTime: "2024-02-09T13:37:14Z"
    message: ReplicaSet "nginx-7494f5f88c" has successfully progressed.
    reason: NewReplicaSetAvailable
    status: "True"
    type: Progressing
  observedGeneration: 1
  readyReplicas: 3
  replicas: 3
  updatedReplicas: 3
```

用户提交了一个 Deployment 对象，其中包含了用户所希望的状态，而 Deployment 控制器会持续地将当前的状态调整为用户所希望的状态。`spec`便是用户所希望的状态，`status`便是当前的状态。Deployment 和其他相关的控制器会持续地创建和监控对应的 ReplicaSet 和 Pod，以保证用户所希望的应用副本数量。