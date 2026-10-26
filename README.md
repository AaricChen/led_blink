# led_blink

STM32F103C8T6（Blue Pill）LED 闪烁示例，由 STM32CubeMX 生成，使用 **GNU Make + arm-none-eabi-gcc** 构建。

| 项目 | 说明 |
|------|------|
| MCU | STM32F103C8Tx（Cortex-M3） |
| LED | PC13 |
| 调试 | SWD（PA13/PA14），ST-Link |

## 开发工具

| 工具 | 用途 | 推荐安装方式 |
|------|------|----------------|
| [GNU Arm Embedded Toolchain](https://developer.arm.com/downloads/-/gnu-rm) | 交叉编译 | `winget install Arm.GnuArmEmbeddedToolchain` |
| [xPack OpenOCD](https://github.com/xpack-dev-tools/openocd-xpack) | 烧录 / 调试 | `winget install xpack-dev-tools.openocd-xpack` |
| [Make (ezwinports)](https://github.com/ezwinports/make) | 构建 | `winget install ezwinports.make` |
| Git for Windows | Bash 终端 | 可选，Cursor 集成终端常用 |

### 一键配置（Windows）

在 **PowerShell** 中执行（仓库根目录）：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-dev-env.ps1
```

脚本会安装缺失组件、把 `bin` 目录加入**用户 PATH**，并设置 `OPENOCD_SCRIPTS`。完成后**重新打开** Cursor 或终端。

在 **Git Bash** 中若 PATH 未生效，可先加载：

```bash
source scripts/env.sh
```

> **注意**：请勿在 Windows 上对带空格的安装路径使用 `make GCC_PATH=...`；应把 `arm-none-eabi-gcc` 所在 `bin` 加入 PATH。

## 构建

```bash
make        # 输出 build/led_blink.{elf,hex,bin}
make clean
```

## 烧录

连接 ST-Link 与板子 SWD 后：

```bash
openocd -f openocd.cfg -c "program build/led_blink.elf verify reset exit"
```

或在 Cursor 中：**Terminal → Run Task → Flash (OpenOCD)**。

## 在 Cursor / VS Code 中调试

1. 安装推荐扩展：**Cortex-Debug**、**C/C++**（打开仓库时会提示）。
2. 运行 **Build** 任务或 `make`。
3. 按 **F5**，选择 **Debug (OpenOCD + ST-Link)**。

## CubeMX

修改引脚或时钟后，用 STM32CubeMX 打开 `led_blink.ioc`，重新生成代码（保留 `USER CODE` 区域）。
