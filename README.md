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
- 默认启用正常 TLS 校验，不再默认使用 `--no-check-certificate`

## 目录结构

```text
.
├── config/
│   └── config.example.sh
├── scripts/
│   └── synology-bing-wallpaper.sh
├── .editorconfig
├── .gitignore
├── README.md
└── synology_bing_wallpaper.sh
```

根目录的 `synology_bing_wallpaper.sh` 是兼容入口。已有 DSM 任务计划如果一直调用这个路径，不需要修改。

## 安装

SSH 登录 Synology，然后克隆仓库：

```sh
git clone https://github.com/SiuKam/synology-bing-wallpaper.git
cd synology-bing-wallpaper
chmod +x synology_bing_wallpaper.sh scripts/synology-bing-wallpaper.sh
```

先手动执行一次：

```sh
sudo ./synology_bing_wallpaper.sh
```

脚本需要修改 DSM 系统文件，因此应以 `root` 身份运行。

## DSM 任务计划

在 **控制面板 → 任务计划 → 新增 → 计划的任务 → 用户定义的脚本** 中创建任务：

- 用户：`root`
- 周期：每天一次
- 用户定义的脚本：

```sh
/path/to/synology-bing-wallpaper/synology_bing_wallpaper.sh
```

请将路径替换为仓库在 NAS 上的实际位置。

## 配置

默认情况下无需创建配置文件。

需要修改保存目录、市场或其他选项时：

```sh
cp config/config.example.sh config/config.sh
```

然后编辑 `config/config.sh`：

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

`config/config.sh` 已加入 `.gitignore`，本机配置不会被误提交。

也可以通过 `WALLPAPER_CONFIG` 指定其他配置文件：

```sh
WALLPAPER_CONFIG=/volume1/path/my-config.sh ./synology_bing_wallpaper.sh
```

## 为什么以前会变成日语？

旧脚本请求：

```text
https://bing.com/HPImageArchive.aspx?... 
```

但没有指定 `mkt`。Bing 可以依据请求地区选择市场，因此当 NAS 经日本 VPN 出口访问时，可能返回日本市场内容。

现在请求中明确包含：

```text
mkt=zh-CN
```

并使用：

```text
https://cn.bing.com/HPImageArchive.aspx
```

因此市场选择不再依赖日本 VPN 出口 IP。

## 常用市场

如希望使用其他地区的 Bing 每日壁纸，只需修改 `BING_MARKET`，例如：

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

手动执行脚本并查看输出：

```sh
sudo ./synology_bing_wallpaper.sh
```

如果只想验证 Bing 是否返回中文市场，可以执行：

```sh
curl -fsSL "https://cn.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=zh-CN"
```

重点检查返回 JSON 中的 `title`、`copyright` 和图片 URL。

## 兼容性说明

DSM 更新可能改变系统壁纸文件的位置。脚本会在相关目录不存在时给出警告并跳过对应操作，而不是因为某个 DSM 路径变化直接破坏已下载的壁纸。

目前桌面壁纸路径沿用 DSM 7 的：

```text
/usr/syno/synoman/webman/resources/images/2x/default_wallpaper/dsm7_01.jpg
/usr/syno/synoman/webman/resources/images/1x/default_wallpaper/dsm7_01.jpg
```

## 致谢

最初脚本思路来自 GXNAS 的相关文章：

- https://wp.gxnas.com/4045.html

本项目后来改为直接使用 Bing 的壁纸接口，并在此基础上继续维护和重构。
