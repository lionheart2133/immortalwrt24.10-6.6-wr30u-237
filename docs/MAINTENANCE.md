# 维护说明

本文把配置中可长期复用的部分与需要随上游重新检查的部分分开，避免源码更新后机械复用旧 `.config`。

## 日常更新流程

1. 在源码仓库保存未提交改动和当前 `.config`。
2. 执行 `git fetch origin --prune`，确认上游差异后使用 `git merge --ff-only origin/openwrt-24.10-6.6`。
3. 执行 `./scripts/feeds update -a && ./scripts/feeds install -a`。
4. 在本管理仓库执行 `./scripts/refresh-config.sh <源码目录>`。
5. 检查 `.config` 的目标、HomeProxy 依赖和 `scripts/diffconfig.sh` 输出。
6. 提交本仓库的 `.config`、文档及必要的脚本变化，再运行 GitHub Actions 测试构建。
7. 只有在确认 artifact 可启动、网络与 sysupgrade 正常后，才运行带 Release 发布选项的构建。

## 可直接复用的内容

- 上游分支：`openwrt-24.10-6.6` 未改名时可复用。
- 基础模板：`defconfig/mt7981-ax3000.config` 未改名时可复用。
- 设备意图：WR30U U-Boot Mod 布局不变时可复用。
- HomeProxy 选择：包名仍为 `luci-app-homeproxy` 时可复用。
- LAN 修改脚本：上游仍使用相同 `config_generate` 结构时可复用；脚本找不到锚点会主动失败，不会静默生成错误固件。
- GitHub artifact、校验值和构建元数据整理逻辑可跨普通源码更新复用。

## 每次上游更新后必须复查

- `git diff` 是否显示上游改动了 `config_generate`、WR30U DTS、镜像分区或 sysupgrade 逻辑。
- `make defconfig` 后目标是否仍唯一指向 `xiaomi_mi-router-wr30u-ubootmod`。
- HomeProxy 是否仍自动选择 `sing-box`、`kmod-nft-tproxy` 和 `kmod-tun`。
- feeds 是否出现缺失依赖、重命名或冲突警告。
- 生成镜像大小是否超过设备布局限制。
- 上游 README 的构建依赖、推荐宿主系统和分支名称是否发生变化。

## 工具或需求变化时如何处理

- 新增普通上游插件：先更新 feeds，在 `config/custom.config` 增加对应 `CONFIG_PACKAGE_...=y`，重新生成并验证 `.config`。
- 新增第三方插件：固定其仓库与提交，记录许可证和兼容性；在 feeds 更新前拉取源码，并在工作流中校验提交，不使用未固定的远程安装脚本。
- 删除插件：从 `config/custom.config` 删除选择并重新生成，不直接手工删完整 `.config` 中的依赖行。
- 更换设备布局：视为新的固件产品，单独建分支或配置文件，不能与现有 U-Boot Mod 固件混用。
- 升级到不同 OpenWrt/ImmortalWrt 大版本：重新审阅全部目标符号、firewall、包管理器和升级兼容性，不沿用完整 `.config`。

## 本地环境约束

上游要求在大小写敏感的 Linux 文件系统上以普通用户构建。当前 `/root` 下的源码适合本轮配置维护，但正式本地编译前应迁移到普通用户的 WSL home，并确保路径中没有空格或非 ASCII 字符。GitHub Actions runner 本身以普通用户构建，不受此问题影响。
