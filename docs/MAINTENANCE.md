# 可复用维护流程

本文区分长期可复用步骤和每次上游变化后必须重新确认的内容。

## 文件职责

- `config/custom.config`：长期配置意图，只放设备目标、HomeProxy 和明确需要保留的工具。
- `.config`：基于当前上游生成的完整快照，用于审计和比较，不作为下一次更新模板。
- `config/upstream.commit`：最后一次成功构建并完成收尾的上游提交。
- `diy-part1.sh`：把通用默认 LAN 从上游值改为 `192.168.2.1`；找不到预期锚点时主动失败。
- `diy-part2.sh`：执行 `make defconfig`，校验设备、HomeProxy、sing-box 和诊断工具，并拒绝雷神组件。
- `scripts/refresh-config.sh`：合并上游模板、应用定制、验证并回写 `.config`。
- `.github/workflows/build-openwrt.yml`：检查上游、固定源码提交、编译、发布 Release 并记录成功提交。

## 上游自动检查

GitHub Actions 每天北京时间 03:17 执行轻量检查：

1. 读取上游 `openwrt-24.10-6.6` 的远程 HEAD。
2. 与 `config/upstream.commit` 比较。
3. 相同时结束，不安装依赖、不编译。
4. 不同时固定该提交进行完整构建和 Release。
5. 全部成功后才更新 `config/upstream.commit`。

手动运行始终构建，适用于配置或工具发生变化时，并始终发布 Release。Actions artifact 不作为固件交付渠道。

## 本地更新步骤

1. 备份源码仓库的未提交改动、`.config` 和自定义包。
2. `git fetch origin --prune`，检查差异后使用 `git merge --ff-only origin/openwrt-24.10-6.6`。
3. 执行 `./scripts/feeds update -a` 和 `./scripts/feeds install -a`。
4. 在管理仓库执行 `./scripts/refresh-config.sh <源码目录>`。
5. 检查 `.config`、`./scripts/diffconfig.sh` 和镜像大小。
6. 更新 `config/upstream.commit` 只应发生在该上游提交已经成功构建之后；自动工作流会完成这一步。
7. 提交配置和文档，手动运行 Actions 做本次配置构建。

## 当前长期配置意图

- WR30U U-Boot Mod 单设备目标。
- 默认 LAN `192.168.2.1`。
- HomeProxy 与 sing-box。
- `drill`：DNS 响应、TTL、DNSSEC 和上游对比。
- `mtr-nojson`：持续路径质量诊断。
- `iperf3`：局域网吞吐与无线 A/B 测试。
- 上游模板自带的 tcpdump、ethtool、zram、MTK 加速、EQoS 和基础 LuCI 组件。

前三个诊断工具没有常驻服务，空闲时只占闪存。

## 每次更新后必须复查

- `config_generate` 的默认 LAN 结构是否变化。
- WR30U DTS、U-Boot Mod UBI 分区和 sysupgrade 逻辑是否变化。
- `make defconfig` 后是否仍只选择 `xiaomi_mi-router-wr30u-ubootmod`。
- HomeProxy 是否仍选择版本匹配的 `sing-box`、`kmod-nft-tproxy` 和 `kmod-tun`。
- `drill`、`mtr-nojson`、`iperf3` 的符号及依赖是否仍存在。
- feeds 是否有缺失依赖、包重命名或冲突。
- 完整 `.config` 与提交快照是否一致。
- 镜像是否仍适配约 112MiB UBI 布局，运行内存是否适合 256MB 设备。
- Release 是否只包含 WR30U U-Boot Mod 的设备固件与 `sha256sums`，并抽查校验和是否匹配；配置和维护元数据不作为 Release 资产重复发布。

## 需求变化时

- 新增上游包：更新 feeds，在 `config/custom.config` 增加符号，重新生成并校验。
- 删除包：从 `config/custom.config` 删除，不手工清理完整 `.config` 的依赖行。
- 新增第三方包：固定仓库和提交，记录许可证，不执行未固定的远程安装脚本。
- 更换分区布局：视为另一固件产品，使用独立分支和配置，不能复用现有镜像。
- 升级 OpenWrt/ImmortalWrt 大版本：重新审核设备符号、内核、firewall、包管理器、feeds 和 sysupgrade，不沿用旧完整 `.config`。
- DNS/代理变化：先阅读 `NETWORK-STABILITY.md`，避免同时启用多套 DNS 接管服务。

## 本地环境约束

上游要求在大小写敏感 Linux 文件系统中以普通用户构建。当前 `/root` 源码可用于配置维护，但正式本地编译宜迁移到普通 WSL 用户的 home；路径避免空格和非 ASCII 字符。GitHub Actions runner 使用普通用户，不受此限制。
