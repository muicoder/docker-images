VAAS（Values as a Service）
---
> __values(data)__ + charts(templates) = kubernetes YAML Resources

__values(data)__
===
### values优先级：
##### （高）$kind.selected.yaml文件（源自values目录，topology.sh脚本）
##### （中）$kind.encrypted*.yaml文件（源自values目录，内有encrypted优先级）
##### （低）$kind.unencrypted.yaml文件（源自values目录，$kind目录文件汇总）
### encrypted优先级：
```text
（高）$kind.encrypted.kube-system.yaml
（中）$kind.encrypted.dev.yaml
（低）$kind.encrypted.yaml
```
charts(templates)
===
### 预留字符串
```text
runNamespace：替换成deploy的名字空间
runEnv：替换成deploy的环境名称（如prod、devN、testN）
run26Env：替换成deploy的环境名称（跟runEnv类似，但仅保留字母）
runExtEnv：替换成deploy环境名称（如prod、devN、testN），prod环境被置空
runExt26Env：替换成deploy环境名称（跟runExtEnv类似，但仅保留字母），prod环境被置空
```
kubernetes YAML Resources
===
##### 通过创建argocd插件（vaas），使用vaas动态生成helmfile.yaml，调用helmfile渲染chart，对接argocd的部署。
使用示例
===
### 新建Secret资源
1. 新建pg Secret资源
>###### 1.1 创建Secret目录：mkdir -p values/Secret
> ###### 1.2 新建pg-demo文件：touch values/Secret/pg-demo.yaml
> ###### 1.3 填写data默认数据：
```yaml
instances:
  - name: secret-pg-demo
    data:
      PG_DEMO_URI: postgresql://username:password@address:port/database_runExtEnv"
      PG_DEMO_HOST: address
```
2. 敏感数据分开保存加密：
> ###### 2.1 新建加密数据文件：touch values/Secret.encrypted.yaml
> ###### 2.2 填写data加密数据：
```yaml
instances:
  - name: secret-pg-demo
    data:
      PG_DEMO_URI: postgresql://postgres:TwrFt8Y4@192.168.100.200:5432/demo_runExtEnv"
```
> ###### 2.3 使用sops加密文件：sops -e -i values/Secret.encrypted.yaml，参数-e替换-d是对已加密文件进行解密
3. 关联使用pg-demo的拓扑关系，检查并git commit提交到远程repo，待自动渲染后同步生效
> ###### 3.1 经确定pg-demo的作用场景范围是sre、demo
> ###### 3.2 编辑拓扑文件：vim values/topology.sh
> ###### 3.3 在projectMap["sre"]、projectMap["demo"]里填写pg-demo
_目录结构含义概述_
===
```shell
├── charts # 定义charts(templates)
│   ├── ConfigMap
│   │   ├── Chart.yaml # chart描述
│   │   ├── templates
│   │   │   └── template.yaml # chart模版
│   │   └── values.yaml # 仅用于chart测试
│   ├── Middleware
│   │   ├── Chart.yaml # chart描述
│   │   ├── templates
│   │   │   └── template.yaml # chart模版
│   │   └── values.yaml # 仅用于chart测试
│   └── Secret
│       ├── Chart.yaml # chart描述
│       ├── templates
│       │   └── template.yaml # chart模版
│       └── values.yaml # 仅用于chart测试
├── vaas # main程序
├── vaas.generated # 自动生成，$kind.values.yaml是最终用于渲染helm的values文件
│   ├── ConfigMap.unencrypted.yaml # 定义的未加密ConfigMap数据汇总
│   ├── Middleware.unencrypted.yaml # 定义的未加密Middleware数据汇总
│   ├── Secret.unencrypted.yaml # 定义的未加密Secret数据汇总
│   └── kube-system # 名字空间
│       ├── ConfigMap.decrypted.yaml # 已解密ConfigMap数据
│       ├── ConfigMap.selected.yaml # 已选择ConfigMap资源
│       ├── ConfigMap.values.yaml # 最终helm渲染ConfigMap的values文件
│       ├── Middleware.decrypted.yaml # 已解密Middleware数据
│       ├── Middleware.selected.yaml # 已选择Middleware资源
│       ├── Middleware.values.yaml # 最终helm渲染Middleware的values文件
│       ├── Secret.decrypted.yaml # 已解密Secret数据
│       ├── Secret.selected.yaml # 已选择Secret资源
│       └── Secret.values.yaml # 最终helm渲染Secret的values文件
└── values # 定义values(data)
    ├── ConfigMap # 非加密ConfigMap
    │   ├── druid.yaml # 定义druid的多个ConfigMap
    │   ├── kafka.yaml # 定义kafka的多个ConfigMap
    ├── ConfigMap.encrypted.yaml # 定义ConfigMap加密数据
    ├── ConfigMap.instances.txt # 自动生成ConfigMap定义列表
    ├── Middleware # 非加密Middleware
    │   ├── compress.yaml # 定义compress的多个Middleware
    │   ├── http2https.yaml # 定义http-https的多个Middleware
    ├── Middleware.encrypted.yaml # 定义Middleware加密数据
    ├── Middleware.instances.txt # 自动生成Middleware定义列表
    ├── Secret # 非加密Secret
    │   ├── elasticsearch.yaml # 定义elasticsearch的多个Secret
    │   ├── kafka.yaml # 定义kafka的多个Secret
    ├── Secret.encrypted.kube-system.yaml # 定义kube-system名字空间的Secret加密数据
    ├── Secret.encrypted.dev.yaml # 定义匹配*-dev*名字空间的Secret加密数据
    ├── Secret.encrypted.yaml # 定义Secret默认加密数据
    ├── Secret.instances.txt # 自动生成Secret定义列表
    └── topology.sh # # 用于vaas生成集群资源的拓扑关系
```
