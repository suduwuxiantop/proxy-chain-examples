#!/usr/bin/env bash
# 在本机用 sing-box 搭两台“服务器”（前置 SS + 落地 SOCKS5），
# 分别用 Mihomo 和 sing-box 客户端走链式代理访问 github.com，
# 然后查看两台服务器的日志，确认流量真的是两跳。
# 依赖：sing-box (>=1.12)、mihomo、curl
set -euo pipefail
SB=${SB:-sing-box}; MH=${MH:-mihomo}
D=$(mktemp -d); cd "$D"
PW=$($SB generate rand --hex 16)
cat > hop1.json <<J
{"log":{"level":"info"},"inbounds":[{"type":"shadowsocks","listen":"127.0.0.1","listen_port":21001,"method":"aes-128-gcm","password":"$PW"}],"outbounds":[{"type":"direct"}]}
J
cat > exit.json <<J
{"log":{"level":"info"},"inbounds":[{"type":"socks","listen":"127.0.0.1","listen_port":21002,"users":[{"username":"u1","password":"p1"}]}],"outbounds":[{"type":"direct"}]}
J
cat > mh.yaml <<J
mixed-port: 21080
mode: rule
log-level: info
proxies:
  - {name: 前置, type: ss, server: 127.0.0.1, port: 21001, cipher: aes-128-gcm, password: "$PW", udp: true}
  - {name: 落地, type: socks5, server: 127.0.0.1, port: 21002, username: u1, password: p1, dialer-proxy: 前置}
rules:
  - MATCH,落地
J
cat > sbc.json <<J
{"log":{"level":"info"},"inbounds":[{"type":"mixed","listen":"127.0.0.1","listen_port":22080}],
 "outbounds":[{"type":"shadowsocks","tag":"前置","server":"127.0.0.1","server_port":21001,"method":"aes-128-gcm","password":"$PW"},
  {"type":"socks","tag":"落地","server":"127.0.0.1","server_port":21002,"username":"u1","password":"p1","detour":"前置"}],
 "route":{"final":"落地"}}
J
$SB run -c hop1.json > hop1.log 2>&1 & P1=$!
$SB run -c exit.json > exit.log 2>&1 & P2=$!
$MH -f mh.yaml -d "$D/mh" > mh.log 2>&1 & P3=$!
$SB run -c sbc.json > sbc.log 2>&1 & P4=$!
trap 'kill $P1 $P2 $P3 $P4 2>/dev/null || true' EXIT
sleep 3
curl -s -o /dev/null -w "mihomo   链式 -> HTTP %{http_code}\n" -x socks5h://127.0.0.1:21080 https://github.com --max-time 20 || true
curl -s -o /dev/null -w "sing-box 链式 -> HTTP %{http_code}\n" -x socks5h://127.0.0.1:22080 https://github.com --max-time 20 || true
sleep 1
echo "== 前置服务器看到的目标（应只有落地服务器 127.0.0.1:21002）："; grep -o "inbound connection to [^ ]*" hop1.log | sort | uniq -c
echo "== 落地服务器看到的目标（应为 github.com:443）："; grep -o "inbound connection to [^ ]*" exit.log | sort | uniq -c
