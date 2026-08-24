# 安装与使用

## 安装

下载或克隆 [alinbori2080/Skills](https://github.com/alinbori2080/Skills)，然后在 Windows PowerShell 中复制这个 Skill：

```powershell
$source = ".\Skills\github-proxy-aware-push"
$target = Join-Path $env:USERPROFILE ".codex\skills\github-proxy-aware-push"
Copy-Item -LiteralPath $source -Destination $target -Recurse -Force
```

如果 Git 直连 GitHub 失败，而本机代理仍使用默认端口 `7897`，克隆时只对这一条命令使用代理：

```powershell
git -c http.proxy=http://127.0.0.1:7897 clone https://github.com/alinbori2080/Skills.git
```

安装后重新打开 Codex 或新建任务。

## 调用

这个 Skill 只接受显式调用：

```text
使用 $github-proxy-aware-push 把当前任务相关改动安全推送到 GitHub main。
```

只输入 Skill 名称不会授权提交或推送；需要同时明确要求上传、推送或发布。
