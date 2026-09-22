# Synology Bing Wallpaper

自动获取 Bing 每日壁纸，并将其应用到 Synology DSM 登录页和默认桌面壁纸。

默认固定使用 **Bing 中国市场（`zh-CN`）**。即使 NAS 通过日本、美国或其他地区的 VPN / 代理访问 Bing，也会主动请求中文市场，避免标题、版权信息和每日图片被自动切换到其他地区。

## 功能

- 获取 Bing 每日壁纸及标题、版权信息
- 默认请求 `https://cn.bing.com/HPImageArchive.aspx`
- 显式指定 `mkt=zh-CN`，不依赖出口 IP 判断地区
- 默认请求 3840×2160 UHD 图片
- 更新 DSM 登录背景
- 将 Bing 标题和版权信息写入 DSM 登录欢迎信息
- 更新 DSM 默认桌面壁纸
- 自动保存每日图片，文件名格式为 `YYYYMMDD_bing.jpg`
- 优先使用 `curl`，不可用时自动回退到 `wget`
- 下载到临时目录，成功后再写入目标位置
- 默认启用正常 TLS 校验
- 支持运行前自动从 GitHub 同步最新脚本
- 同步失败时自动回退到 NAS 上一次可用版本

## 目录结构

```text
.
├── config/
│   └── config.example.sh
├── scripts/
│   └── sync-and-run.sh
├── .editorconfig
├── .gitignore
├── README.md
└── synology-bing-wallpaper.sh
```

`synology-bing-wallpaper.sh` 是实际业务脚本。

`scripts/sync-and-run.sh` 用于“先同步、再执行”。

## 推荐部署方式：计划任务只保留一条命令

不建议再把整段业务脚本复制到 DSM 任务计划的文本框里。

更容易维护的方式是把仓库放在 NAS 的持久目录，然后让 DSM 任务计划只运行：

```sh
/volume1/scripts/synology-bing-wallpaper/scripts/sync-and-run.sh
```

这样以后 GitHub 上修改脚本，不需要再手工复制到任务计划。

### 1. 一次性安装

如果 NAS 已安装 Git：

```sh
mkdir -p /volume1/scripts
cd /volume1/scripts
git clone https://github.com/SiuKam/synology-bing-wallpaper.git
chmod +x synology-bing-wallpaper/synology-bing-wallpaper.sh
chmod +x synology-bing-wallpaper/scripts/sync-and-run.sh
```

如果已经 clone 过，只需要：

```sh
cd /volume1/scripts/synology-bing-wallpaper
git pull --ff-only
```

### 2. 建议创建本地配置

```sh
cd /volume1/scripts/synology-bing-wallpaper
cp config/config.example.sh config/config.sh
```

然后按需要编辑 `config/config.sh`。

`config/config.sh` 已加入 `.gitignore`，所以执行 `git pull` 时本机配置不会被覆盖。

### 3. DSM 任务计划

在 **控制面板 → 任务计划 → 新增 → 计划的任务 → 用户定义的脚本** 中创建：

- 用户：`root`
- 周期：每天一次
- 用户定义的脚本：

```sh
/volume1/scripts/synology-bing-wallpaper/scripts/sync-and-run.sh
```

路径按你自己的实际安装位置调整。

每次运行时，脚本会先：

1. 如果目录是 Git 仓库并且有 `git`，执行 `git pull --ff-only`
2. 同步成功后运行最新版
3. 如果 GitHub 暂时不可达或同步失败，继续运行 NAS 上现有版本

因此不会因为一次网络故障就停止更新壁纸。

## 没有 Git 也可以自动同步

`scripts/sync-and-run.sh` 还支持无 Git 模式。

只要本地存在：

```text
/volume1/scripts/synology-bing-wallpaper/
├── scripts/
│   └── sync-and-run.sh
└── synology-bing-wallpaper.sh
```

同步脚本就会直接从：

```text
https://raw.githubusercontent.com/SiuKam/synology-bing-wallpaper/main/synology-bing-wallpaper.sh
```

下载最新业务脚本。

下载后会先执行 `sh -n` 语法检查，检查通过才会替换本地版本；如果下载失败或语法检查失败，则继续使用旧版本。

> 无 Git 模式只自动更新主业务脚本。若希望 `sync-and-run.sh` 本身也自动更新，推荐使用 Git clone 方案。

## 手动运行

不经过同步：

```sh
sudo ./synology-bing-wallpaper.sh
```

先同步再运行：

```sh
sudo ./scripts/sync-and-run.sh
```

脚本需要修改 DSM 系统文件，因此应以 `root` 身份运行。

## 配置

默认情况下无需创建配置文件。

需要修改保存目录、市场或其他选项时：

```sh
cp config/config.example.sh config/config.sh
```

默认配置：

```sh
SAVE_DIR="/volume1/download/wallpaper"
BING_MARKET="zh-CN"
BING_HOST="cn.bing.com"
UHD_WIDTH="3840"
UHD_HEIGHT="2160"
INSECURE_TLS="0"
UPDATE_LOGIN="1"
UPDATE_DESKTOP="1"
```

也可以通过 `WALLPAPER_CONFIG` 指定其他配置文件：

```sh
WALLPAPER_CONFIG=/volume1/path/my-config.sh ./synology-bing-wallpaper.sh
```

## 为什么以前会变成日语？

旧脚本请求 Bing 壁纸接口时没有指定 `mkt`。

Bing 可以依据请求地区选择市场，因此当 NAS 经日本 VPN 出口访问时，可能返回日本市场的每日壁纸、日语标题和版权信息。

现在接口请求中明确包含：

```text
mkt=zh-CN
```

并默认使用：

```text
https://cn.bing.com/HPImageArchive.aspx
```

因此市场选择不再依赖 VPN 出口 IP。

## 常用市场

| 市场 | 值 |
| --- | --- |
| 中国大陆 / 简体中文 | `zh-CN` |
| 日本 / 日语 | `ja-JP` |
| 美国 / 英语 | `en-US` |
| 加拿大 / 英语 | `en-CA` |
| 英国 / 英语 | `en-GB` |
| 德国 / 德语 | `de-DE` |
| 法国 / 法语 | `fr-FR` |

## TLS 证书问题

旧脚本默认使用 `--no-check-certificate`，这会关闭 HTTPS 证书验证。

现在默认：

```sh
INSECURE_TLS="0"
```

只有在旧版 DSM 的证书环境确实无法正常访问 Bing 时，才建议临时设置：

```sh
INSECURE_TLS="1"
```

更推荐先修复 DSM 的 CA 证书，而不是长期关闭 TLS 校验。

## 排错

手动执行同步脚本并观察日志：

```sh
sudo ./scripts/sync-and-run.sh
```

只测试业务脚本：

```sh
sudo ./synology-bing-wallpaper.sh
```

验证 Bing 是否返回中文市场：

```sh
curl -fsSL "https://cn.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=zh-CN"
```

重点检查返回 JSON 中的 `title`、`copyright` 和图片 URL。

## 兼容性说明

DSM 更新可能改变系统壁纸文件的位置。脚本会在相关目录不存在时给出警告并跳过对应操作，而不是因为某个 DSM 路径变化直接破坏已下载的壁纸。

目前桌面壁纸路径沿用 DSM 7：

```text
/usr/syno/synoman/webman/resources/images/2x/default_wallpaper/dsm7_01.jpg
/usr/syno/synoman/webman/resources/images/1x/default_wallpaper/dsm7_01.jpg
```

## 致谢

最初脚本思路来自 GXNAS 的相关文章：

- https://wp.gxnas.com/4045.html

本项目后来改为直接使用 Bing 的壁纸接口，并在此基础上继续维护和重构。
