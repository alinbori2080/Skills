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

## 安装

### 方法一：手动安装

1. 点击仓库右上角的 **Code → Download ZIP**。
2. 解压下载文件。
3. 将 `editorial-dual-zone-poster` 文件夹复制到：

```text
%USERPROFILE%\.codex\skills\
```

### 方法二：使用 PowerShell

```powershell
git clone https://github.com/alinbori2080/Skills.git
Copy-Item -Recurse -Force ".\Skills\editorial-dual-zone-poster" "$env:USERPROFILE\.codex\skills\"
```

## 使用

上传或指定一张参考图，然后输入：

```text
使用 $editorial-dual-zone-poster 根据这张参考图制作一张上下各占 50% 的高级极简海报。
```

对于视觉要求较高的作品，可以先讨论构图、姿势、抽象程度和文字，再让 Skill 开始生成。

## 运行要求

- 支持本地 Skills 的 Codex 环境
- 可用的 `imagegen` 图像生成能力
- 编辑本地图片时，需要允许 Codex 查看对应图片文件

## 目录结构

```text
editorial-dual-zone-poster/
├─ SKILL.md
├─ agents/
│  └─ openai.yaml
└─ references/
   └─ prompt-template.md
```
