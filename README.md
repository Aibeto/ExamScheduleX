# ExamScheduleX

考试科目看板。Flutter 窗口内嵌 WebView，界面完全由 HTML/CSS/JS 实现（[ak-ui](https://ak-ui.yyj.moe) 设计语言），仅适配 Windows。

## 使用

- 左栏：秒级时钟与当前科目倒计时；右栏：科目列表（开始/结束时间、科目名、时长）。
- 分隔线可拖拽调节左右宽度，双击恢复默认。
- 右上角：亮/暗主题切换、编辑科目列表、锁定界面。锁定后编辑、主题切换与分隔线拖拽全部隐藏，仅保留解锁按钮。
- 科目数据存放在 exe 同目录的 `schedule.json`，格式：

```json
{
  "subjects": [
    { "name": "数学", "start": "2026-09-19 08:00", "end": "2026-09-19 09:30" }
  ]
}
```

- 在编辑器点击保存后，页面始终写入 WebView 缓存；在浏览器中运行时保存会触发下载 `schedule.json`；在 Windows 宿主中则通过 JS 桥直接写入 exe 同目录文件。
- 启动时默认使用缓存课表；若同目录存在内容不一致的 `schedule.json`，会弹出对话框询问使用哪一份。

## 开发

- 前端源码位于 `webapp/`：`pnpm install && pnpm build`，产物输出到 `assets/web/`。
- `assets/web/` 为构建产物，但随仓库提交，Flutter 构建不依赖 Node。注意：Flutter 的 pubspec 目录资产声明**不递归子目录**，因此 `assets/web/` 与 `assets/web/assets/` 需同时声明。Node 环境。
- Flutter 侧仅 [main.dart](lib/main.dart)：启动本地 HTTP 服务从资产内存中提供页面，WebView 加载 `127.0.0.1` 随机端口，并注册 `saveConfig` JS 桥。
- 运行：`flutter run -d windows`；打包：`flutter build windows`。

## 开源许可

| 组件                     | 许可证      |
| ------------------------ | ----------- |
| ak-ui (@yunyoujun/ak-ui) | MIT         |
| Poppins                  | SIL OFL 1.1 |
| Fira Sans                | SIL OFL 1.1 |
| Noto Sans SC             | SIL OFL 1.1 |
| flutter_inappwebview     | Apache-2.0  |
| Vite                     | MIT         |
