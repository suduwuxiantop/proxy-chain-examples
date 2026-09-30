# proxy-chain-examples

链式代理（前置节点 → 落地节点）的 **Mihomo / Clash Verge** 与 **sing-box** 配置示例，附一个本机两跳代理的验证脚本。

典型场景：用机场节点做**前置**，保证国内连接稳定；用住宅 / 独享 IP 做**落地**，让 LinkedIn、TikTok、Facebook 等网站看到固定的出口 IP。

📖 配套图文教程：[链式代理怎么设置？Clash Verge（Mihomo）和 sing-box 实战教程](https://main.suduwuxian.top/lianshi-daili-shezhi/)

```
你的设备 → 前置节点（机场） → 落地节点（住宅 / 独享 IP） → 目标网站
```

## 文件

| 文件 | 说明 |
|------|------|
| [`mihomo/config.yaml`](mihomo/config.yaml) | Mihomo 完整配置：机场订阅作前置（自动选香港/日本最低延迟节点），住宅 SOCKS5 作落地，只让指定网站走链式 |
| [`mihomo/clash-verge-merge.yaml`](mihomo/clash-verge-merge.yaml) | Clash Verge Rev 扩展覆写（Merge）写法：在现有订阅上追加链式，更新订阅不会被覆盖 |
| [`sing-box/client.json`](sing-box/client.json) | sing-box 客户端 outbound 示例（`detour`） |
| [`test/local-chain-test.sh`](test/local-chain-test.sh) | 本机搭两台服务器，分别用 Mihomo 和 sing-box 走链式，查看服务器日志验证确实是两跳 |

## 两个关键点

1. **链式字段写在落地节点上。** Mihomo 用 `dialer-proxy`，sing-box 用 `detour`，值都是前置节点（Mihomo 也可以填分组名）。意思是“连这个落地节点时，先经过谁”。
2. **Mihomo 的 `relay` 分组已弃用**，请改用 `dialer-proxy`。官方文档同时建议：被中转的落地节点使用 SS、VMess、SOCKS5 等简单协议，不要用 Hysteria2 / TUIC / WireGuard 这类 UDP 协议，也不要用 REALITY / ShadowTLS。

## 验证

```bash
SB=/path/to/sing-box MH=/path/to/mihomo bash test/local-chain-test.sh
```

期望输出：前置服务器日志里只有“连接到落地服务器”，落地服务器日志里才出现 `github.com:443`。

配置均已通过 `mihomo -t` 与 `sing-box check`（1.14.1）校验。

## 参考

- [Mihomo：dialer-proxy](https://wiki.metacubex.one/en/config/proxies/dialer-proxy/)
- [Mihomo：relay（已弃用）](https://wiki.metacubex.one/en/config/proxy-groups/relay/)
- [sing-box：Dial Fields（detour）](https://sing-box.sagernet.org/configuration/shared/dial/)
- [Clash Verge Rev：Merge 配置](https://clashvergerev.com/guide/merge)

## License

[MIT](LICENSE)
