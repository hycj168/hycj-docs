# Docker在Ubuntu24.04上的安装配置和使用

## 确保安装环境干净，先卸载\清除原Docker（可能没有装，但是不影响）

```bash
sudo apt remove docker \
  docker-client \
  docker-client-latest \
  docker-common \
  docker-latest \
  docker-latest-logrotate \
  docker-logrotate \
  docker-engine
```

---

## 首先更新软件源

```bash
sudo apt update && sudo apt upgrade -y
```

---

## 安装需要的依赖包

```bash
sudo apt install apt-transport-https ca-certificates curl gnupg2 software-properties-common

sudo apt-get install \
	ca-certificates \
	curl \
	gnupg \
	lsb-release
```

---

## 添加阿里云的Docker CE仓库的GPG密钥

```bash
sudo curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

---

## 在apt内加入阿里的Docker源

```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu/ $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

---

### 再次更新软件源

```bash
sudo apt update && sudo apt upgrade -y
```

---

## 使用apt进行安装

```bash
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
```

---

## 验证结果

```bash
docker -v
```

---

## 获取一个加速地址，这个地址用于下面配置

```bash
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
  	"https://docker.hpcloud.cloud",
	"https://docker.m.daocloud.io",
     "https://docker.unsee.tech",        
     "https://docker.1panel.live",
     "http://mirrors.ustc.edu.cn",
     "https://docker.chenby.cn",                 
     "http://mirror.azure.cn",
     "https://dockerpull.org",
     "https://dockerhub.icu",
     "https://hub.rat.dev",         
     "https://proxy.1panel.live",
     "https://docker.1panel.top",
     "https://docker.m.daocloud.io",         
     "https://docker.1ms.run",
     "https://docker.ketches.cn"
  ]
}
EOF
```

---

## 重载配置并重启Docker

```bash
sudo systemctl daemon-reload & sudo systemctl restart docker
```

---

