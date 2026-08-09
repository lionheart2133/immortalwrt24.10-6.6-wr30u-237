# ImmortalWrt 25.12 测试构建：小米 WR30U

这是与正式 `openwrt-24.10-6.6` 分支隔离的迁移测试分支。它用于验证 ImmortalWrt 25.12、Linux 6.12，以及为 hanwckf 多布局 U-Boot 恢复的 WR30U 112M NMBM 布局，不替代已经验证的 24.10 固件。

## 测试基线

| 项目 | 值 |
| --- | --- |
| 本仓库分支 | `25.12-test` |
| 上游源码 | `chasey-dev/immortalwrt-mt798x-rebase` |
| 上游分支 | `25.12` |
| 配置模板 | `defconfig/mt7981-ax3000.config` |
| 设备目标 | `xiaomi_mi-router-wr30u-112m-nmbm` |
| 固件格式 | `sysupgrade.bin`，传统 kernel/rootfs UBI 卷 |
| U-Boot 布局 | hanwckf 多布局 U-Boot 的 `immortalwrt-112m` |
| 默认 LAN | `192.168.2.1` |
| 代理组件 | HomeProxy（sing-box） |
| 诊断工具 | drill、mtr-nojson、iperf3、tcpdump、ethtool |
| UPnP | 不编译 |
| 加速策略 | TurboACC/HNAT 组件随上游保留，但首次测试保持关闭 |
| 候选上游提交 | `6536be32f1db48f342ff9a95f1622c48eeafd47e` |
| 成功测试构建 | 见 [`config/upstream-25.12.commit`](./config/upstream-25.12.commit) |
| `.config` SHA-256 | `bb1cfa1bb01be39f07a9c815eb72d9e4e41cb70d2a261f2cad92bd30ea6c71d8` |

顶层 [`.config`](./.config) 是 25.12 模板与 [`config/custom.config`](./config/custom.config) 合并并执行 `make defconfig` 后的审计快照。跨上游更新只维护精简配置意图，不沿用 24.10 的完整 `.config`。

## 构建与 Release

本分支只允许从 GitHub Actions 手动触发，不设置定时任务，也不响应普通 push。成功后发布中文说明的 **Prerelease**：

- 只发布一份 WR30U 112M NMBM `sysupgrade.bin` 和 `sha256sums`；
- 不上传 Actions artifact；
- 不发布 preloader、FIP 或 recovery，避免误刷；
- 成功后才更新 `config/upstream-25.12.commit`。

正式 24.10 分支仍按原有计划检查上游并发布稳定 Release，两个构建链路互不覆盖。

## 本地刷新配置

在 WSL 中完成 25.12 feeds 初始化后执行：

```bash
cd /path/to/this-repository
./scripts/refresh-config.sh /path/to/immortalwrt-mt798x-rebase-25.12
```

脚本会先应用 [`patches/100-wr30u-112m-nmbm.patch`](./patches/100-wr30u-112m-nmbm.patch)，再合并上游 ax3000 模板、选择 WR30U 112M NMBM 和 HomeProxy、移除 UPnP、保留默认 LAN 改动并同步完整 `.config`。

## 刷机前提

上游已删除 WR30U `112m-nmbm` 目标，因此本分支以小补丁恢复该第三方布局：启用 NMBM，保留 `0x600000 + 0x7000000` 的 112M UBI，并生成 `sysupgrade.bin`。它不是把 FIT 文件改名，而是恢复 hanwckf `immortalwrt-112m` 所需的传统 UBI 镜像契约。

在完成 [`docs/25.12-TESTING.md`](./docs/25.12-TESTING.md) 中的恢复入口、冷启动、配置迁移和回退验证前，不要在日常使用的设备上直接保留配置升级。网络与代理排查建议见 [`docs/NETWORK-STABILITY.md`](./docs/NETWORK-STABILITY.md)，可复用维护流程见 [`docs/MAINTENANCE.md`](./docs/MAINTENANCE.md)。

## 许可证

构建脚本按 [MIT License](./LICENSE) 提供；ImmortalWrt 和各软件包遵循各自上游许可证。
