# RM500U-WEBUI

Quectel RM500U 5G 模组的 Web 管理界面，适配 OpenWrt 的 procd 服务和 UCI 配置。
支持 RM500U-CN、RM500U-CNV、RM500U-EA，目前打包目录仅面向 **x86_64 / musl**。

## 功能

- 设备状态、信号、小区和流量查看
- APN、拨号、网络模式与频段设置
- 短信收发、会话管理和 webhook 转发
- AT 命令终端、运行日志和模拟环境
- 在“服务管理”页面修改 WebUI 端口、用户名和密码

## 默认访问

| 项目 | 默认值 |
| --- | --- |
| 地址 | `http://路由器IP:5080` |
| 用户名 | `admin` |
| 密码 | `admin` |

登录后可在“服务管理”中修改。新密码留空表示保留原密码。

## 安装

将编译好的安装包上传至路由器 `/tmp`，执行对应命令。

OpenWrt 25.12（APK；以下方式允许安装未受信任签名的本地包）：

```sh
apk add --allow-untrusted /tmp/rm500u-web-*.apk
```

OpenWrt 24.10（IPK）：

```sh
opkg install /tmp/rm500u-web_*.ipk
```

启动服务：

```sh
/etc/init.d/rm500u-web enable
/etc/init.d/rm500u-web restart
```

模组需要先被 OpenWrt 正常识别，串口及 USB 网卡驱动按实际连接模式安装。本项目使用独立 WebUI，不会在 LuCI 中新增功能菜单。

## 编译

在 OpenWrt 源码或 SDK 根目录导入本仓库：

```sh
git clone https://github.com/SepMiao/RM500U-WEBUI.git package/rm500u-web
make menuconfig
```

在 `Network` 中选择 `rm500u-web`，然后编译：

```sh
make defconfig
make package/rm500u-web/compile -j1 V=s
```

产物位于 `bin/packages/` 下。24.10 与 25.12 应分别使用各自版本、目标架构对应的编译环境。

本仓库是 OpenWrt 打包目录，`payload/` 包含预编译程序及网页；打包阶段不需要安装 .NET SDK。若修改后端功能，需要先从应用源码重新发布并更新 `payload/`。

## 配置与卸载

服务配置：`/etc/config/rm500u-web`；程序数据：`/etc/rm500u-web/data`。

```sh
/etc/init.d/rm500u-web restart   # 重启服务
logread -e rm500u-web           # 查看日志
apk del rm500u-web             # OpenWrt 25.12 卸载
# opkg remove rm500u-web        # OpenWrt 24.10 卸载
```

当前 r5 打包脚本在正常卸载时清理默认配置和数据，升级时保留设置。自定义的外部数据目录不递归删除。

## 许可证

[AGPL-3.0-only](LICENSE)
