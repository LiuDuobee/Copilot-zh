# Copilot Desktop 中文化资源

这是一个**独立的、非侵入式**中文化资源项目，用于维护 GitHub Copilot Desktop 的版本化翻译映射，并在新版本发布后自动发现新增界面文本。

本项目不会修改、重打包或绕过 GitHub Copilot Desktop 的代码签名和自动更新机制。只有在官方提供可加载的语言资源接口，或用户明确使用兼容的外部覆盖层时，翻译资源才能被实际加载到客户端。

## 当前功能

- 维护按版本组织的英文键与简体中文翻译。
- 从本地导出的 Desktop 资源文件中扫描英文文本。
- 对照翻译映射，报告缺失翻译。
- 查询 GitHub Releases，检测上游版本变化。
- GitHub Actions 定期检查最新版本并生成待翻译清单。

由于 Copilot Desktop 的官方发布元数据地址不在本项目中公开声明，更新器要求通过
`COPILOT_RELEASES_URL` 显式配置可信的版本元数据接口。接口应返回包含 `tag_name`
或 `name` 字段的 JSON，并可选返回 `html_url`。

## 使用

```powershell
npm run check
npm run scan -- .\resources\copilot-desktop.json
$env:COPILOT_RELEASES_URL = "https://example.invalid/releases/latest"
npm run update
```

`scan` 接受 JSON、JavaScript、HTML 或纯文本资源文件。它只生成报告，不会修改输入文件。

## 资源格式

翻译资源位于 `locales\zh-CN.json`，格式如下：

```json
{
  "meta": {
    "source": "GitHub Copilot Desktop",
    "locale": "zh-CN",
    "upstreamVersion": "latest"
  },
  "messages": {
    "Settings": "设置"
  }
}
```

## 合规说明

请遵守 GitHub Copilot Desktop 的许可、商标和服务条款。不要分发修改后的官方安装包，也不要绕过签名验证或自动更新保护。
