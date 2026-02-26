# 在 ImmortalWrt 中配置编译 dae

[dae](https://github.com/daeuniverse/dae) 是基于 eBPF 的高性能透明代理，ImmortalWrt 官方已将其收入 **packages** 仓库，无需额外 feed，按下面步骤即可编进固件。

---

## 一、结论速览

| 项目 | 是否已包含 dae 配置 |
|------|---------------------|
| **immortalwrt** | ✅ 已选好 dae、luci-app-dae、依赖 |
| **padavanonly-mt798x-6.6** | ✅ 已选好 |
| **hanwckf-mt798x** | ❌ 未选，需按下方步骤自选 |

若你编译的是 **immortalwrt** 或 **padavanonly-mt798x-6.6**，可直接用现有 `.config` 触发编译，无需改配置。

---

## 二、为何不需要加 dae 的 feed？

- dae 的 **OpenWrt 包** 在 ImmortalWrt 官方仓库里：  
  [immortalwrt/packages/net/dae](https://github.com/immortalwrt/packages/tree/master/net/dae)
- 该包会从 **daeuniverse/dae** 的 [Releases](https://github.com/daeuniverse/dae/releases) 下载 `dae-full-src.zip` 并编译，无需自己添加 `daeuniverse/dae` 作为 feed。

因此只要使用 ImmortalWrt 的 **packages** feed（你当前项目的 `feeds.conf.default` 已包含），就能编译 dae。

---

## 三、编译前需要选中的包（若你从零配置）

在 **menuconfig** 或 **.config** 中需要选：

### 1. 必选（核心 + 数据 + Web）

- **Network → Web Servers/Proxies**
  - `dae` — 核心程序
  - `dae-geoip` — GeoIP 数据（依赖 v2ray-geoip，会一并选上）
  - `dae-geosite` — Geosite 数据（依赖 v2ray-geosite，会一并选上）
- **LuCI → Applications**
  - `luci-app-dae` — Web 管理界面
  - （可选）`luci-i18n-dae-zh-cn` — 中文语言包

### 2. 依赖（选 dae 后一般会自动勾选）

- `kmod-veth` — 虚拟网卡对（dae 0.5.1+ 需要）
- `kmod-sched-core`、`kmod-sched-bpf` — 流量调度
- `kmod-xdp-sockets-diag` — XDP 诊断
- `v2ray-geoip`、`v2ray-geosite` — dae-geoip / dae-geosite 的依赖

若用 **make menuconfig**，选上 `dae` 和 `luci-app-dae` 后执行一次 `make defconfig` 或保存配置，依赖通常会自动写入 `.config`。

### 3. 内核要求（必须显式开启）

dae 依赖 eBPF，内核需开启以下选项（在 **.config** 里是 `CONFIG_KERNEL_*` 前缀）：

| 内核选项 | 说明 |
|----------|------|
| `CONFIG_KERNEL_DEBUG_INFO_BTF=y` | BTF 调试信息（dae 加载 eBPF 需要） |
| `CONFIG_KERNEL_DEBUG_INFO_BTF_MODULES=y` | 模块的 BTF（若 dae 相关为模块则需要） |
| `CONFIG_KERNEL_KPROBES=y` | kprobes 支持 |
| `CONFIG_KERNEL_KPROBE_EVENTS=y` | kprobe 事件（perf 等） |
| `CONFIG_KERNEL_BPF_EVENTS=y` | eBPF 事件（dae 必需） |

若缺 `CONFIG_KERNEL_BPF_EVENTS` 或 `CONFIG_KERNEL_KPROBE_EVENTS`，运行 dae 可能报错。在 **menuconfig** 中对应路径一般为：**Kernel modules → Other modules** 或 **Global build settings → Kernel build options** 下的 **Kernel debugging** / **Tracing** 相关项（具体菜单名因版本而异）；或直接在 `.config` 中加上上述行。

---

## 四、在本仓库中的具体操作步骤

### 方式 A：直接编译已配置好的项目（推荐）

1. 打开 **Actions → OpenWrt Builder**，点击 **Run workflow**。
2. 在 **要编译的项目** 中选择：
   - **immortalwrt**，或  
   - **padavanonly-mt798x-6.6**
3. 运行完成后在 **Artifacts** 或 **Releases** 中下载固件，dae 和 LuCI 已包含在内。

无需改任何 feed 或 `.config`。

---

### 方式 B：为 hanwckf-mt798x 或新项目添加 dae

**1. 确认 feeds 包含 ImmortalWrt packages**

`projects/hanwckf-mt798x/feeds.conf.default` 示例：

```text
src-git-full packages https://github.com/immortalwrt/packages.git;openwrt-21.02
src-git-full luci https://github.com/immortalwrt/luci.git;openwrt-21.02
```

只要包含 `immortalwrt/packages` 即可，**无需**再添加 daeuniverse 的 feed。

**2. 在 .config 中启用 dae 相关项**

在对应项目的 `.config` 里增加或确认存在（若已存在可跳过）：

```ini
# dae 核心与数据
CONFIG_PACKAGE_dae=y
CONFIG_PACKAGE_dae-geoip=y
CONFIG_PACKAGE_dae-geosite=y

# LuCI
CONFIG_PACKAGE_luci-app-dae=y
CONFIG_PACKAGE_luci-i18n-dae-zh-cn=y

# 依赖（dae 的 Makefile 会声明，选 dae 后一般会自动选上）
CONFIG_PACKAGE_kmod-veth=y
CONFIG_PACKAGE_kmod-sched-core=y
CONFIG_PACKAGE_kmod-sched-bpf=y
CONFIG_PACKAGE_kmod-xdp-sockets-diag=y
CONFIG_PACKAGE_v2ray-geoip=y
CONFIG_PACKAGE_v2ray-geosite=y

# 内核选项（dae eBPF 必需，缺一可能导致运行时报错）
CONFIG_KERNEL_DEBUG_INFO_BTF=y
CONFIG_KERNEL_DEBUG_INFO_BTF_MODULES=y
CONFIG_KERNEL_KPROBES=y
CONFIG_KERNEL_KPROBE_EVENTS=y
CONFIG_KERNEL_BPF_EVENTS=y
```

**3. 若用本地源码 + menuconfig**

```bash
# 克隆/进入 ImmortalWrt 源码目录后
cp feeds.conf.default feeds.conf   # 或你项目用的 feeds
./scripts/feeds update -a
./scripts/feeds install -a
make menuconfig
# 在 Network → Web Servers/Proxies 中勾选 dae、dae-geoip、dae-geosite
# 在 LuCI → Applications 中勾选 luci-app-dae（及 luci-i18n-dae-zh-cn）
# 保存退出
make -j$(nproc)
```

---

## 五、编译完成后使用 dae

- **配置文件**：`/etc/dae/config.dae`（参考 `/etc/dae/` 下示例）。
- **LuCI**：服务里会出现 **dae**，可网页配置。
- **注意**：若同一台机器上还跑 shadowsocks 等 UDP 服务，建议为对应端口加 `l4proto(udp) && sport(端口) -> must_direct`，避免出口 UDP 被误代理（见 [dae 官方说明](https://github.com/daeuniverse/dae)）。

---

## 六、参考

- dae 项目：<https://github.com/daeuniverse/dae>
- ImmortalWrt packages 中的 dae：<https://github.com/immortalwrt/packages/tree/master/net/dae>
- 本仓库多项目说明：见根目录 [README.md](../README.md)
