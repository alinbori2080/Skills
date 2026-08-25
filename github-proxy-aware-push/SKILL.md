---
name: github-proxy-aware-push
description: Use when Git operations against GitHub on Windows fail or stall while the browser still works, especially for proxy-aware fetch, push, upload, github.com:443, WinINET, 127.0.0.1, or port 7897 workflows.
---

# GitHub Proxy-Aware Push

在 Windows 上先发现浏览器实际使用的代理，再安全完成已授权的 GitHub 上传。浏览器能访问 GitHub 不代表 Git 会继承 WinINET 代理；不要先做一次注定失败的直连。

## 授权与边界

- 单独调用 `$github-proxy-aware-push` 只授权检查，不授权提交或推送。必须有用户明确的“推送、上传、发布”等指令。
- 先说明要检查或修改的仓库、文件和计划。确认仓库根目录、当前分支、目标远端和待上传范围。
- 不显示含用户名、密码或令牌的远端 URL、代理值、配置或日志。发现疑似凭据时只报告文件路径和风险，不回显内容。
- 不执行 `git add .`、`git add -A`、`git commit -a`、`push --force` 或永久 `git config --global http.proxy ...`。

## BI-Tool 默认仓库

处理 BI-Tool 的检查、提交、合并或推送时，如果用户没有明确指定其他路径，使用 `C:\Users\zhoujie\Documents\GitHub\BI-Tool`。先验证该目录存在且 `git rev-parse --show-toplevel` 指向它；不要回退到旧目录 `D:\codex\0810\BI-Tool`。用户明确给出的仓库路径始终覆盖此默认值。

## 1. 发现可用代理

在第一次访问 GitHub 之前运行只读脚本：

```powershell
$report = & "<skill-folder>\scripts\detect-github-proxy.ps1" | ConvertFrom-Json
$report.Candidates | Format-Table Priority, Source, Proxy, Listening, HasCredentials
```

候选顺序固定为：当前 Git 配置、`HTTPS_PROXY` / `HTTP_PROXY` / `ALL_PROXY`、WinINET、`127.0.0.1:7897` 回退。脚本会去重并删除输出中的代理凭据，不修改任何配置。

从上到下验证候选；跳过 `Listening=false`。每次只对当前命令覆盖代理：

```powershell
$proxy = $candidate.Proxy
git -c http.proxy="$proxy" ls-remote origin HEAD
```

首个成功候选用于本次任务后续所有 `fetch`、`push` 和远端哈希检查。候选含 `HasCredentials=true` 时，不要复制、重建或打印凭据；停止并让用户确认安全认证方式。全部失败时，报告已测试的脱敏端点和错误摘要后停止。

非 Windows 系统只检查适用的 Git 配置和代理环境变量；不要假设 WinINET 或端口 `7897` 存在。

## 2. 检查仓库与上传范围

先执行只读检查：

```powershell
git rev-parse --show-toplevel
git status --short --branch
git branch --show-current
git diff --stat
git diff --cached --stat
```

使用已验证代理获取远端状态：

```powershell
git -c http.proxy="$proxy" fetch --prune origin
git rev-list --left-right --count "origin/$branch...HEAD"
```

本地与远端同时各有独有提交时停止，不自动 rebase、合并或强推。仅落后时，只有在目标明确且工作区安全时才允许 `merge --ff-only`，随后重新测试。

保留无关修改和未跟踪文件。只暂存用户任务所需的明确路径，并逐项检查：

```powershell
git add -- <明确路径...>
git diff --cached --name-status
git diff --cached --check
git diff --cached
```

运行与改动相符的测试。检查待提交文件及待推送提交是否包含令牌、私钥、认证 URL、真实配置、日志或备份；测试失败、发现秘密或范围不明时停止。普通未上传文件要按“路径 + 原因”交代。

## 3. 提交、推送与核验

提交前再次确认暂存区只含目标文件。推送前再 `fetch` 一次并复查分叉，避免覆盖并发更新。明确推送本地提交到目标分支：

```powershell
git -c http.proxy="$proxy" push origin "HEAD:refs/heads/$branch"
```

不要把 `ls-remote` 成功当作推送成功。推送后比较哈希：

```powershell
$localHash = git rev-parse HEAD
$remoteLine = git -c http.proxy="$proxy" ls-remote origin "refs/heads/$branch"
$remoteHash = ($remoteLine -split "\s+")[0]
if ($localHash -ne $remoteHash) { throw "Remote hash verification failed." }
```

最终报告目标仓库和分支、提交哈希、测试结果、远端哈希一致性，以及保留未上传的普通文件。不得声称工作区干净，除非已实际检查。

## 停止条件

缺少推送授权、目标远端或分支不明确、范围混入无关内容、测试失败、发现秘密、本地远端分叉、凭据可能泄露、代理候选全部失败，任一情况都停止；禁止用强推或持久代理配置绕过。
