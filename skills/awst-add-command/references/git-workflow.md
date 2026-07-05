# git commit / push（tk ユーザー）

Cursor エージェントは `root` で動くことがある。git push は **tk ユーザー** で実行する。

```bash
sudo -u tk -H bash -lc '
  cd /home/tk/github/aktus-tk/cloud-cli &&
  git -c safe.directory=/home/tk/github/aktus-tk/cloud-cli status &&
  git -c safe.directory=/home/tk/github/aktus-tk/cloud-cli add <files> &&
  git -c safe.directory=/home/tk/github/aktus-tk/cloud-cli commit -m "$(cat <<'"'"'EOF'"'"'
commit message here
EOF
)" &&
  git -c safe.directory=/home/tk/github/aktus-tk/cloud-cli push
'
```

## ルール

- ユーザーが明示的に commit/push を求めたときだけ commit する
- メッセージは 1〜2 文、why を中心に
- `awst <service>: <summary>` 形式
- amend / force push はユーザー指示がない限りしない
