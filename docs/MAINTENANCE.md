# 25.12 测试分支维护流程

本文记录可以复用的构建步骤，以及每次 25.12 上游更新后必须重新确认的设备契约。正式 24.10 分支的定时构建保持不变。

## 文件职责

- `config/custom.config`：WR30U、HomeProxy、诊断工具和禁用 UPnP 的长期配置意图。
- `.config`：当前 25.12 上游生成的完整审计快照，不作为下一次更新模板。
- `config/upstream-25.12.commit`：最后一次成功测试构建的 25.12 上游提交。
- `patches/100-wr30u-112m-nmbm.patch`：恢复[上游已作为第三方 U-Boot 布局删除](https://github.com/openwrt/openwrt/commit/1b7e62b20b1735fcdc498a35e005afcd775abcf4)的 WR30U 112M NMBM 设备树、`sysupgrade.bin` 镜像定义，以及 U-Boot 环境、LED、网口和 MAC 地址的运行时识别。
- `diy-part1.sh`：应用 112M NMBM 补丁并将上游默认 LAN 改为 `192.168.2.1`；任一预期锚点变化即失败。
- `diy-part2.sh`：执行 `make defconfig`，验证设备、HomeProxy、sing-box、诊断工具和 UPnP 排除项。
- `scripts/refresh-config.sh`：合并上游模板、应用定制并更新 `.config`。
- `.github/workflows/build-openwrt.yml`：仅手动构建并发布 25.12 Prerelease。
- `docs/25.12-TESTING.md`：真机测试、回退和晋级条件。

## 可复用更新步骤

1. 获取 `chasey-dev/immortalwrt-mt798x-rebase` 的 `25.12` 最新提交并记录差异。
2. 更新和安装 feeds，不执行来源不明的远程安装脚本。
3. 对固定的上游提交应用 112M NMBM 补丁，再从 `defconfig/mt7981-ax3000.config` 重新开始并合并 `config/custom.config`。
4. 执行 `make defconfig` 和 `diy-part2.sh`，更新顶层 `.config`。
5. 检查 `.config` 差异、依赖变更、镜像格式和预计闪存占用。
6. 提交配置与文档，手动触发 Actions。
7. 只有编译、配置校验和 Prerelease 全部成功后才记录上游提交。
8. 只有真机测试满足晋级条件，才考虑调整正式构建主线。

## 每次更新必须重新验证

- MediaTek 目标仍使用 Linux 6.12，且 feeds 全部指向匹配的 `openwrt-25.12` 分支。
- WR30U 目标仍为 `xiaomi_mi-router-wr30u-112m-nmbm`，且补丁仍能无偏移、无模糊匹配地应用。
- 设备树仍包含 `mediatek,nmbm`、64 个保留块上限，以及 `reg = <0x600000 0x7000000>`。
- 镜像仍为单一 `sysupgrade.bin`，使用传统 kernel/rootfs UBI 卷，不得重新混入 `sysupgrade.itb`、`KERNEL_IN_UBI`、`UBOOTENV_IN_UBI` 或 `/dev/fit0` 契约。
- HomeProxy 仍能选择 sing-box、firewall4、`kmod-nft-tproxy` 和所需 ucode 模块。
- UPnP/miniupnpd 没有因依赖重新进入配置。
- apk 被正确选择，不混用 24.10 的 opkg 软件源或离线包。
- Release 仅包含设备 sysupgrade 固件与 `sha256sums`，并标记为 Prerelease。
- Release 中文说明仍明确标注 hanwckf `immortalwrt-112m`、NMBM、`.bin` 格式和不可直接保留配置升级。

任一设备契约发生变化时，应让工作流失败并人工审阅，不能仅修改 grep 规则绕过校验。

## 配置与运行原则

- HomeProxy 编译进固件，但不预置节点、订阅或私有网络信息。
- TurboACC/HNAT 保留为可测试组件；首次启动和代理稳定性基线测试时保持关闭。
- 不编译 UPnP；当前网络环境不能从它获得可靠公网入站能力。
- 同一时刻只允许一套 DNS 接管链路，避免 dnsmasq、HomeProxy 和局域网代理主机形成循环。
- `drill`、`mtr-nojson` 和 `iperf3` 没有常驻服务，适合作为固件内诊断工具。

## 分支与发布策略

- `openwrt-24.10-6.6`：正式稳定分支，继续定时检查上游并发布普通 Release。
- `25.12-test`：手动试验分支，只发布 Prerelease，不自动跟随上游构建。
- 不在两个分支之间复制完整 `.config`、`config/upstream*.commit` 或固件文件。
- 不使用相同的 Release tag 前缀，避免用户混淆。

## 晋级条件

至少完成一次可重复构建，并按 `25.12-TESTING.md` 验证：U-Boot 恢复入口、校验、冷启动、有线和无线、DNS、HomeProxy、连接跟踪、重启、断电恢复及回退。连续运行 48～72 小时没有阻断性问题后，才能讨论将 25.12 设为正式主线。

若测试失败，保留构建日志和匿名化诊断信息，正式 24.10 分支不随之回滚或改动。
