# 开源可视化一键脚本
![主页面](https://upload.cc/i1/2024/12/31/ohVGvW.jpeg)
![Docker管理](https://upload.cc/i1/2024/12/31/di9yhx.jpeg)
![Nginx管理](https://upload.cc/i1/2024/12/31/0dkn17.jpeg)
# 安装指南
## 1.安装weget curl依赖包  
*Debian/Ubuntu*  
```
apt-get update -y && apt-get install curl -y
```
*CentOS/Fedora*  
```
yum update -y && yum install curl -y
```
## 2.运行一键脚本  
```
curl -sS -O https://raw.githubusercontent.com/Garfleld/docker-nginx/main/yaxp.sh && sudo chmod +x yaxp.sh && ./yaxp.sh
```

## 项目名称
**Docker+Nginx管理面板**
## 简介
这是一个Shell脚本，包含Docker管理和Nginx管理。
## 特性
- Docker一键安装：快速部署Docker环境。
- Nginx配置脚本：轻松实现反代、重定向及证书申请与续签功能。
- 逐步完善中...
## 贡献
如果你想要贡献代码或改进我们的脚本，非常欢迎！请通过Pull Request或Issue与我联系。
## 许可证
本项目采用 MIT 许可证。有关更多详细信息，请查看 [LICENSE](LICENSE) 文件。
## 免责声明
本项目中的脚本部分收集自互联网，作者对脚本的安全性和功能性不做任何承诺，使用者需严格遵守当地的法律法规，在使用脚本时应自行承担风险。