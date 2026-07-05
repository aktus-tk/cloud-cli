# Skills（Claude Code + Cursor 共通）

このディレクトリが **正本（canonical source）** です。

| ツール | 参照パス |
|--------|----------|
| Claude Code | `.claude/skills/<name>/` → `skills/<name>/` |
| Cursor | `.cursor/skills/<name>/` → `skills/<name>/` |

## 含まれる skills

| Skill | 用途 |
|-------|------|
| [awst-add-command](awst-add-command/SKILL.md) | `awst` サブコマンド追加ワークフロー |

## 追加方法

```bash
mkdir -p skills/my-skill/references
# skills/my-skill/SKILL.md を作成
ln -sfn ../../skills/my-skill .claude/skills/my-skill
ln -sfn ../../skills/my-skill .cursor/skills/my-skill
```

`SKILL.md` の frontmatter は Claude / Cursor 共通:

```yaml
---
name: my-skill
description: Third-person description with trigger terms for when to use this skill.
---
```
