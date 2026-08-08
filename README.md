# ImmortalWrt 24.10 / Linux 6.6 for Xiaomi WR30U

这是小米 WR30U（U-Boot Mod 布局）的可复现 ImmortalWrt 构建配置与 GitHub Actions 工作流。

## 当前基线

| 项目 | 值 |
| --- | --- |
| 上游源码 | `padavanonly/immortalwrt-mt798x-24.10` |
| 上游分支 | `openwrt-24.10-6.6` |
| 配置模板 | `defconfig/mt7981-ax3000.config` |
| 设备目标 | `xiaomi_mi-router-wr30u-ubootmod` |
| 默认 LAN | `192.168.2.1` |
| 代理组件 | HomeProxy（sing-box） |
| 诊断工具 | drill、mtr-nojson、iperf3、tcpdump、ethtool |
| 已验证上游提交 | `ec9ef10efc65da1e6d1de4e2c043c0e13d08eed8` |
| `.config` SHA-256 | `0dd32aa46e5cb6e4efb520c5c7a0d72345a599f37fd5854db8781af83e257b45` |

顶层 [`.config`](./.config) 是执行 `make defconfig` 后的完整快照；[`config/custom.config`](./config/custom.config) 只保存需要跨上游更新长期维护的配置意图。不要直接把旧 `.config` 当作下一次更新的模板。

## 自动构建与 Release

工作流有两种入口：

- 每天北京时间 03:17 检查一次上游分支。只有上游 HEAD 与 [`config/upstream.commit`](./config/upstream.commit) 不同时才构建；构建成功后自动发布 Release，并记录已经构建的上游提交。
- 从 Actions 手动运行时，无论上游是否变化都会构建，并始终发布 Release。

之前的测试构建没有 Release，是因为它由 `push` 触发，而旧工作流只在手动输入 `publish_release=true` 时发布。当前工作流已取消普通 push 编译，避免文档或配置提交意外消耗数小时编译资源。

固件只通过仓库的 [Releases](https://github.com/lionheart2133/immortalwrt24.10-6.6-wr30u-237/releases) 交付，不再上传 Actions artifact。每个 Release 包含固件、完整配置、diffconfig、上游及 feeds 提交、构建元数据和 SHA-256 校验文件；下载固件无需进入 Actions 页面。

## 本地重新生成配置

在 WSL 中执行：

```bash
cd /path/to/this-repository
./scripts/refresh-config.sh /path/to/immortalwrt-mt798x-24.10
```

脚本会合并最新 ax3000 模板与 `config/custom.config`，保留 LAN `192.168.2.1`，执行 `make defconfig`，验证设备、HomeProxy 与诊断工具，然后同步完整 `.config`。

完整更新流程见 [`docs/MAINTENANCE.md`](./docs/MAINTENANCE.md)，DNS、HomeProxy、v2rayN 和无线稳定性建议见 [`docs/NETWORK-STABILITY.md`](./docs/NETWORK-STABILITY.md)。

## 安全提示

- 固件仅适用于 `xiaomi_mi-router-wr30u-ubootmod` 分区布局，不得刷入 stock 布局。
- 首次启动后立即设置管理员强密码。
- HomeProxy 被编译进固件不代表默认启用代理；应在 LuCI 中配置节点和路由。
- 正式本地编译应使用普通 Linux 用户，不建议在 `/root` 中长期编译。
- 刷机前核对 Release 中的 `sha256sums.txt`，并保留可用的 U-Boot 恢复入口。

## 许可证

构建脚本按 [MIT License](./LICENSE) 提供；ImmortalWrt 和各软件包遵循各自上游许可证。
