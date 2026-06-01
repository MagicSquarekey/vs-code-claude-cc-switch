# VS Code + Claude Code + CC-Switch 一键部署工具

适用于 Windows 10/11 x64 系统的一键安装脚本，自动完成以下软件的安装和配置：

| 组件 | 版本 | 说明 |
|------|------|------|
| **Node.js** | v24.16.0 | JavaScript 运行时，Claude Code 的运行环境 |
| **Visual Studio Code** | latest | 代码编辑器，支持 Claude Code 扩展 |
| **Claude Code CLI** | latest | Anthropic 官方 AI 编程助手命令行工具 |
| **CC-Switch** | v3.16.0 | Claude Code API Key 管理与切换工具 |

---

## 🚀 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/MagicSquarekey/vs-code-claude-cc-switch.git
cd vs-code-claude-cc-switch
```

### 2. 双击运行

双击 `install.bat`，按提示完成安装（需要管理员权限）。

或通过命令行：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

### 高级选项

```powershell
# 静默安装 (无弹窗，适合批量部署)
.\install.ps1 -Silent

# 跳过已安装的组件
.\install.ps1 -SkipVSCode   # 不装 VS Code
.\install.ps1 -SkipNode      # 不装 Node.js
.\install.ps1 -SkipClaude    # 不装 Claude Code
.\install.ps1 -SkipCCSwitch  # 不装 CC-Switch
```

---

## 📦 文件结构

```
vs-code-claude-cc-switch/
├── README.md                # 本文件
├── install.bat              # 双击启动入口
├── install.ps1              # 核心安装脚本
└── packages/
    ├── node-v24.16.0-x64.msi          # Node.js 安装包
    └── CC-Switch-v3.16.0-Windows.msi  # CC-Switch 安装包
```

---

## 🔧 手动安装步骤

如果自动安装出现问题，可以按以下步骤手动操作：

### 1. 安装 Node.js
```cmd
msiexec /i packages\node-v24.16.0-x64.msi /qn /norestart
```

### 2. 安装 VS Code
- 下载: https://code.visualstudio.com/download
- 或命令行: `winget install Microsoft.VisualStudioCode`

### 3. 安装 Claude Code
```cmd
npm install -g @anthropic-ai/claude-code
```

### 4. 安装 CC-Switch
```cmd
msiexec /i packages\CC-Switch-v3.16.0-Windows.msi /qn /norestart
```

---

## ✅ 验证安装

安装完成后，打开新的终端窗口，运行以下命令验证：

```powershell
# 检查 Node.js
node --version          # 应输出: v24.16.0

# 检查 Claude Code
claude --version        # 应输出版本信息

# 检查 VS Code
code --version          # 应输出版本信息

# CC-Switch 在开始菜单中查看
```

---

## ❓ 常见问题

**Q: 提示"无法加载脚本，因为在此系统上禁止运行脚本"**
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

**Q: npm 安装 Claude Code 失败**
- 检查网络连接，可能需要代理
- 尝试: `npm config set registry https://registry.npmmirror.com`

**Q: VS Code 没有添加到 PATH**
- 安装完成后重启电脑
- 或手动添加 `%LOCALAPPDATA%\Programs\Microsoft VS Code\bin` 到 PATH
