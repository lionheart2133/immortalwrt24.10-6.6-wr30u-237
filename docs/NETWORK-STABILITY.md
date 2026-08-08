# 网络稳定性配置建议

本说明整理自典型家庭网络故障现象，用于刷入新固件后的基线配置和复现排查。示例中的地址、接口和终端均使用泛化描述，不对应特定家庭网络。

## 结论分层

观察到的卡顿不是单一原因：

- 自动获取的某个 IPv6 上游 DNS 可能持续超时。
- 过长的最小 TTL 和过期缓存时间可能长期保留不合适的 CDN 结果。
- 个别无线终端可能受 TWT/省电、WPA3/PMF 管理帧兼容性影响，出现局域网延迟尖峰。
- 某个有线端口若反复掉线或降速协商，通常应先排查线材、端口和对端设备。
- 局域网代理进程可能出现“端口仍接受连接，但所有新连接无法转发”的假死；既有长连接可能暂时继续。

## DNS 基线

1. 保留 `dnsmasq-full` 作为唯一 LAN DNS 入口。
2. WAN/WAN6 不接受不稳定的自动 DNS，初期选用两个不同提供方的可靠 IPv4 上游。
3. 初期不通过失效的 IPv6 DNS 地址查询；通过 IPv4 DNS 仍能正常取得 AAAA 记录。
4. 删除旧的 `min_cache_ttl=3600` 和 `use_stale_cache=3600`，尊重权威 TTL；家庭网络缓存量约 1000 即可。
5. 不同时启用 SmartDNS、MosDNS、AdGuardHome、Unbound 和 HomeProxy DNS 接管。
6. 若 HomeProxy 关闭仍发生解析故障，使用 `drill @上游DNS 域名` 分别测试，而不是立刻叠加另一套 DNS 服务。

## HomeProxy

- 使用 `redirect_tproxy`，日志级别保持 `warn`。
- DNS 策略可先使用 `prefer_ipv4`，并选择就近、稳定的直连 DNS。
- 只代理必要目标时优先使用较小的规则集，直连域名不必全部依赖 sing-box。
- 使用大范围绕过或分流模式时，应确认 dnsmasq 是否把全部 DNS 交给 sing-box；HomeProxy 重启期间影响范围更大。
- 不加载无关的大型规则集，不长期打开 debug 日志。
- 256MB RAM 设备不要同时常驻 HomeProxy 与 AdGuardHome/MosDNS/SmartDNS。

## 局域网代理客户端的边界

- 全家代理统一交给路由器 HomeProxy。
- 电脑端代理默认只监听本机回环地址，关闭“允许局域网连接”和 TUN，除非进行短时、受控测试。
- 删除其他家庭设备指向某台电脑私有地址和代理端口的手工代理、PAC 或 WPAD 配置。
- 不串联“路由器透明代理”和“全家经过某台局域网电脑代理”。
- 不混用新旧代理核心和配置目录；升级前先备份客户端配置。
- 出现“旧连接可用、新连接超时”时，分别测试直连与代理端口；该现象不应仅凭浏览器的 `DNS_PROBE_STARTED` 判定为 DNS 故障。

## 无线 A/B 基线

当前源码的 MTK LuCI 已提供所需开关，不需额外插件：

- TWT：关闭。
- 单 AP 环境：先关闭 802.11k/v/r。
- 终端兼容性测试：WPA2-PSK/AES，PMF 关闭或可选。
- HE80/HE160 已不是首要嫌疑；不要用反复切换带宽代替 TWT/WPA3 A/B。
- 使用 `iperf3` 测纯局域网吞吐，用连续 ping 测延迟尖峰。
- 某个有线端口再次掉线或异常降速协商时，先换线、换端口并检查对端供电。

## 建议采样命令

```sh
# DNS：将占位符替换为两个上游，观察耗时、TTL 和返回地址
time drill @DNS_A_ADDRESS example.com
time drill @DNS_B_ADDRESS example.com

# 路径：观察运营商或 CDN 中间跳变化
mtr-nojson -rwzc 30 TEST_TARGET

# 路由器作为 iperf3 服务端，测试局域网而非公网
iperf3 -s

# 只抓 DNS，不记录应用内容
tcpdump -ni any port 53
```

诊断工具默认不常驻；用完即退出，避免长期日志写入闪存。
