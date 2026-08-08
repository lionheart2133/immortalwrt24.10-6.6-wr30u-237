# ImmortalWrt 24.10 / Linux 6.6 for Xiaomi WR30U

这是小米 WR30U（U-Boot Mod 布局）的可复现 ImmortalWrt 构建配置与 GitHub Actions 工作流。

## 当前基线

| 项目 | 值 |
| --- | --- |
| 上游源码 | `padavanonly/immortalwrt-mt798x-24.10` |
| 上游分支 | `openwrt-24.10-6.6` |
| 配置基线 | `defconfig/mt7981-ax3000.config` |
| 设备目标 | `xiaomi_mi-router-wr30u-ubootmod` |
| 默认 LAN 地址 | `192.168.2.1` |
| 自定义插件 | HomeProxy（含 sing-box） |
| 配置生成日期 | 2026-08-08 |
| 源码提交 | `ec9ef10efc65da1e6d1de4e2c043c0e13d08eed8` |
| `.config` SHA-256 | `44718aa453bf9ce496e19452d90c4d8a68c71b7b7090647fcd2be855f8d4db35` |

顶层 [`.config`](./.config) 是经过 `make defconfig` 展开的完整快照；[`config/custom.config`](./config/custom.config) 只记录长期维护所需的选择，是以后适配上游变化时的主要配置来源。

## GitHub Actions 构建

1. 打开仓库的 **Actions** 页面。
2. 选择 **Build ImmortalWrt WR30U**。
3. 点击 **Run workflow**。
4. 普通测试保持 `Publish a GitHub Release` 关闭；确认固件可用后再开启发布。
5. 构建完成后下载 artifact，其中会保留固件、软件包清单、完整配置、精简配置、源码提交和 SHA-256 校验值。

工作流每次都会从最新上游重新克隆源码、更新 feeds、以 ax3000 模板合并 `config/custom.config`，不会直接信任可能过期的完整 `.config`。

修改 `.config`、`config/`、配置脚本或构建工作流并推送到默认分支时，也会自动运行一次不发布 Release 的测试构建；纯文档更新不会触发耗时编译。

## 本地重新生成配置

在 WSL 中执行：

```bash
cd /path/to/this-repository
./scripts/refresh-config.sh /path/to/immortalwrt-mt798x-24.10
```

脚本会重新生成源码目录中的 `.config`，校验 WR30U U-Boot Mod 与 HomeProxy 已启用，并把规范化结果同步回本仓库。详细更新流程见 [`docs/MAINTENANCE.md`](./docs/MAINTENANCE.md)。

## 重要提示

- 固件只适用于与 `xiaomi_mi-router-wr30u-ubootmod` 匹配的分区布局；不要刷入原厂 stock 布局设备。
- 默认密码为空，首次启动后应立即设置强密码。
- HomeProxy 默认只被编译进固件，不代表首次启动后自动代理流量；请在 LuCI 中配置节点、DNS 和路由规则。
- 正式本地编译应使用普通 Linux 用户。上游明确不建议以 root 身份编译。

## 可选功能建议

当前模板已经包含 zram、TTYD、流量统计和 MTK 加速组件。以下功能按实际需求再开启，不建议无目的堆叠插件：

- `luci-app-sqm`：链路存在 bufferbloat 时有用，但会降低峰值吞吐并可能与硬件流量卸载冲突。
- `luci-app-ddns`：仅在需要从公网访问且公网地址会变化时启用。
- WireGuard：远程回家比暴露 LuCI/SSH 更安全；需要时再加入客户端或服务端组件。
- `luci-app-upnp`：游戏主机确有自动端口映射需求时启用；同时会扩大局域网设备自动开放端口的权限范围。

## 致谢与许可

构建结构源自 P3TERX Actions-OpenWrt，项目自身脚本按 [MIT License](./LICENSE) 提供；ImmortalWrt 与各软件包遵循各自上游许可证。
