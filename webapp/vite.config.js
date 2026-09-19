import { defineConfig } from 'vite'

// 输出到 Flutter 资产目录 assets/web，由宿主 WebView 通过本地 HTTP 服务加载
export default defineConfig({
  build: {
    outDir: '../assets/web',
    emptyOutDir: true,
    assetsInlineLimit: 0
  }
})
