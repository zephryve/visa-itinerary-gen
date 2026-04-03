# visa-itinerary-gen 项目规则

## 文件结构与依赖关系

```
visa-itinerary-gen/
├── CLAUDE.md              ← 你在读的这个文件
├── SKILL.md               ← Skill 执行逻辑（agent 读这个来干活）
├── README.md              ← GitHub 展示页
├── templates/
│   ├── booking_links_cn.html   ← 预订链接中文模板
│   └── booking_links_en.html   ← 预订链接英文模板
├── scripts/
│   └── setup.sh           ← 依赖安装脚本
└── assets/                ← GitHub 展示用图片（不发布到 ClawHub）
```

## 改动影响图

改了左边，**必须**检查右边是否需要同步：

| 改了 | 必须检查 | 原因 |
|------|----------|------|
| SKILL.md 的 flyai 调用逻辑（Step 3/4/5） | README.md "flyai 调用约束"表格 | README 摘录了调用注意事项 |
| templates/booking_links_cn.html 的结构或样式 | templates/booking_links_en.html | 中英文模板结构必须一致 |
| templates/booking_links_en.html 的结构或样式 | templates/booking_links_cn.html | 同上 |
| SKILL.md metadata 的 version | README.md（如果提到版本号） | 版本要一致 |
| scripts/setup.sh 的依赖命令 | SKILL.md Step 0 的依赖检查 | 两处写了同样的安装命令 |

其他改动（如只改 SKILL.md 的行程表格式规则、只改 README 的文案）是单文件自包含的，不需要同步。

## 已知待修问题

完整清单见 engine：`tasks/007_flyai活动/01_visa-itinerary-gen/review_issues.md`

P0：全部已修复（v1.1.0），含 Step 8 Delivery Review 新增。

P1 剩余：pip/pip3 不一致、playwright 检查过严。其余 P1（License 乱码、PDF 链接）已在 v1.1.0 修复。

## 发布清单（改完后必须执行）

本项目有两个发布渠道，改完代码后**必须都同步**：

### 1. GitHub（main 分支）

```bash
cd ~/zephryve/visa-itinerary-gen
git add -A
git commit -m "描述改了什么"
git push origin main
```

### 2. ClawHub Registry

```bash
clawhub publish ~/zephryve/visa-itinerary-gen --changelog "描述改了什么"
```

直接从本目录发布，不需要中间副本。

### 3. GitHub Pages（仅 PRD HTML 变动时）

大多数改动不涉及 PRD HTML，可跳过。如果改了 PRD：

```bash
git checkout gh-pages
# 更新 index.html
git commit -am "update PRD"
git push origin gh-pages
git checkout main
```

## 工作文档在哪

PRD、review 记录、测试数据、demo 输出等工作文档不在本仓库，在 engine：
`~/zephryve/zephryve-engine/tasks/007_flyai活动/01_visa-itinerary-gen/`

这些文档是开发过程的记录，不是 Skill 的一部分，不需要和本仓库同步。
