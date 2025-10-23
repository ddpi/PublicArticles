# Claude Code のやり取りを Slack にリアルタイム投稿する Hooks 用スクリプトと設定

## はじめに

Claude Code のフック機能を使って、ユーザーの指示と Claude の応答を Slack にリアルタイムで投稿するための、スクリプトと設定です。

## Claude Code のフック機能とは

Claude Code には、特定のイベント発生時にカスタムスクリプトを実行できる「フック機能」があります。フックは`.claude/settings.local.json`等で設定し、以下のようなイベントに対応できます：

- **UserPromptSubmit** - ユーザーがプロンプトを送信したとき
- **Stop** - Claude の応答が完了したとき
- その他、セッション開始/終了などのイベント

これらのフックを活用することで、Claude Code との対話を外部サービスと連携させることができます。

## 実装方法

### 1. 前提条件

- Claude Code がインストールされていること
- Slack Incoming Webhook が設定されていること
- `jq`コマンドがインストールされていること（JSON パース用）
- macOS Tahoe (26.0.1)で動作確認しています

### 2. ディレクトリ構成

プロジェクトのルートディレクトリに以下の構造を作成します：

```
your-project/
├── .claude/
│   ├── hooks/
│   │   ├── user_prompt_submit.sh
│   │   └── assistant_response_complete.sh
│   └── settings.local.json
└── .env
```

### 3. 環境変数の設定

`.env`ファイルに Slack Webhook URL を設定します：

```bash
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

### 4. スクリプト

2 つのシェルスクリプトをプロジェクトルートの.claude/hooks/に配置します。

- [user_prompt_submit.sh](user_prompt_submit.sh) - ユーザー指示を投稿
- [assistant_response_complete.sh](assistant_response_complete.sh) - Claude 応答を投稿

スクリプトには実行権限をつけておいてください。

```bash
chmod +x .claude/hooks/user_prompt_submit.sh
chmod +x .claude/hooks/assistant_response_complete.sh
```

### 5. フックの設定

`.claude/settings.local.json`または`.claude/settings.json`に、フック設定を追加します。
設定例は[settings.example.json](settings.example.json)を参照してください。

## 動作イメージ

Claude Code でコマンドを実行すると、Slack に以下のような投稿が順次表示されます：

```
💬 ユーザ指示受信

プロジェクトのREADMEを更新してください
```

```
🤖 Claude応答完了

READMEファイルを更新しました。以下の変更を行いました：
- プロジェクト概要の追加
- インストール手順の詳細化
- ...
```

## 注意点

1. **機密情報**: プロンプトや応答に機密情報が含まれる可能性があるため、投稿先の Slack チャンネルのアクセス権限を適切に設定してください。.env は.gitignore に追加し、リポジトリに登録しないように注意してください。
2. **文字数制限**: Slack API には投稿サイズの制限があるため、長いメッセージは切り詰めています

## 参考リンク

- [Claude Code ドキュメント](https://docs.claude.com/en/docs/claude-code)
- [Slack Incoming Webhooks](https://api.slack.com/messaging/webhooks)
