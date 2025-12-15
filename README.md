<!--
 Copyright (c) 2025 kelejiangjun
 
 This software is released under the MIT License.
 https://opensource.org/licenses/MIT
-->

启动命令

- 首次安装依赖： flutter pub get
- 运行 Web 预览（推荐用于钱包交互测试）：
  - flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5500
  - 或 flutter run -d chrome
- 查看可用设备： flutter devices
- 停止运行（当前终端）： Ctrl + C
- flutter pub get
当前预览

- 已在本机启动： http://127.0.0.1:5500/
建议

- 运行前可检查静态分析： flutter analyze
- 使用安装了 MetaMask 的浏览器打开预览地址，保证 window.ethereum 正常注入
- 若 CDN 受限导致 ethers.js 加载失败，可先不影响导航与页面测试，后续我可为你替换镜像地址或本地化脚本以保障加载稳定性