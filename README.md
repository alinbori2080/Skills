# Skills

面向 Codex 的个人 Skill 集合。每个 Skill 都是一个独立目录，可以单独安装和使用。

## 当前 Skill

### [editorial-dual-zone-poster](./editorial-dual-zone-poster)

根据单张照片、截图或插画，制作高级极简的上下双区竖版海报。

- 上下区域严格各占画面 `50%`
- 上半区保留原图主体、姿势、透视和质感
- 下半区提取同一姿势，转化为几何抽象表达
- 避免把动态姿势自动改成正面、对称或平面化构图
- 每轮只修改一个问题，并保留旧版本

### [codex-connection-doctor](./codex-connection-doctor)

用于处理 Codex Desktop 或 CLI 反复重连、达到 `5/5`、WebSocket 中断和 `10054` 等连接问题。

- 只在识别到典型重连信号时修改配置
- 修改前自动备份 `config.toml`
- 自动切换到禁用 WebSocket 的 HTTPS 通道
- 使用 `codex doctor` 验证，失败时恢复原配置
- 不修改认证文件，不清理任务、缓存或数据库

## 安装

### 方法一：手动安装

1. 点击仓库右上角的 **Code → Download ZIP**。
2. 解压下载文件。
3. 将需要的 Skill 文件夹复制到：

```text
%USERPROFILE%\.codex\skills\
```

### 方法二：使用 PowerShell

```powershell
git clone https://github.com/alinbori2080/Skills.git

$skillName = "codex-connection-doctor"
Copy-Item -Recurse -Force ".\Skills\$skillName" "$env:USERPROFILE\.codex\skills\"
```

将 `$skillName` 改为 `editorial-dual-zone-poster`，即可安装海报 Skill。

安装完成后，重新打开 Codex 或新建任务，让 Codex 重新发现 Skill。

## 使用

### 生成上下双区海报

上传或指定一张参考图，然后输入：

```text
使用 $editorial-dual-zone-poster 根据这张参考图制作一张上下各占 50% 的高级极简海报。
```

### 修复 Codex 反复重连

遇到反复重连、`5/5` 或长响应中断时输入：

```text
使用 $codex-connection-doctor 自动修复 Codex 反复重连问题。
```

该 Skill 会先说明将修改的配置文件，再执行备份、修复和验证。修复后需要重新启动 Codex Desktop，并用一个普通任务确认不再重连。

## 运行要求

- 支持本地 Skills 的 Codex 环境
- `editorial-dual-zone-poster` 需要可用的 `imagegen` 图像生成能力
- `codex-connection-doctor` 适用于 Windows PowerShell，并需要可用的 Codex CLI
- 编辑本地图片或配置时，需要允许 Codex 访问对应文件

## 目录结构

```text
Skills/
├─ README.md
├─ codex-connection-doctor/
│  ├─ SKILL.md
│  ├─ agents/
│  │  └─ openai.yaml
│  └─ scripts/
│     └─ repair_codex_connection.ps1
└─ editorial-dual-zone-poster/
   ├─ SKILL.md
   ├─ agents/
   │  └─ openai.yaml
   └─ references/
      └─ prompt-template.md
```
