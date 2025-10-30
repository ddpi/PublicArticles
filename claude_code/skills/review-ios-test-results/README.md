# review-ios-test-results スキル解説

## 概要

`review-ios-test-results`は、iOS プロジェクトのテスト結果を自動的に分析し、失敗したテストの詳細情報を提供するスキルです。

### このスキルができること

- `xcodebuild test`実行後の`.xcresult`ファイルを自動検索
- テスト実行結果の統計情報（成功/失敗/スキップ数）を表示
- 失敗したテストの詳細情報とエラーメッセージを抽出
- ソースコードの該当箇所（`file:line`形式）を特定
- 失敗パターンに基づいた次のアクションを提案

### 使用シーン

- テスト実行後に結果を確認したい時
- テストが失敗した原因を素早く特定したい時
- 複数のテスト失敗がある場合にパターンを把握したい時
- `.xcresult`ファイルの内容を手動で解析する手間を省きたい時

Claude は、ユーザーが「テスト結果を確認して」「失敗したテストを見て」などと発言した際に、このスキルを自動的に起動することを期待しています。

---

このドキュメントでは、このスキルが[Claude Code のスキル仕様](https://docs.claude.com/en/docs/claude-code/skills)に基づいてどのように設計されているかを解説します。

## インストール方法

このスキルを使用するには、以下の手順でセットアップしてください：

### 1. ファイルの配置

`SKILL.md`を以下のいずれかの場所に配置します：

**プロジェクトスコープ（特定のプロジェクトでのみ使用）：**

```
<プロジェクトルート>/.claude/skills/review-ios-test-results/SKILL.md
```

**グローバルスコープ（すべてのプロジェクトで使用）：**

```
~/.claude/skills/review-ios-test-results/SKILL.md
```

### 2. プレースホルダの設定

`SKILL.md`内の以下のプレースホルダを環境に合わせて変更してください：

- `<DerivedDataPath>`: Xcode のビルド出力先

  - デフォルト値: `~/Library/Developer/Xcode/DerivedData/`
  - カスタムパスを使用している場合は、`xcodebuild test -derivedDataPath`で指定したパスに変更

- `<ProjectName>`: プロジェクト名
  - 例: `PaceNote`、`MyApp`など
  - DerivedData 内のフォルダ名に対応（通常は`<ProjectName>-xxxxx`形式）

### 3. 動作確認

スキルが正しく配置されたら、プロジェクトでテストを実行後に「テスト結果を確認して」と発言してスキルが起動することを確認してください。

## スキルの基本構造

### Frontmatter の実装

`SKILL.md`の Frontmatter は、スキルのメタデータを定義します：

```yaml
---
name: review-ios-test-results
description: Analyzes iOS test results from xcodebuild test runs...
allowed-tools: Bash, Read
---
```

#### 各フィールドの解説

##### `name` フィールド

- **概要**: スキルの名前
- **制約**: 小文字、数字、ハイフンのみを使用（最大 64 文字）
- **このスキルでの実装**: iOS 関連のテスト結果レビューという目的が名前から明確に分かる

##### `description` フィールド

- **概要**: 機能と使用コンテキストの両方を説明
- **制約**: 最大 1024 文字
- **このスキルでの実装**:
  - **何をするか**: "Analyzes iOS test results"
  - **いつ使うか**: "Use immediately after running xcodebuild test, when tests fail"
  - **技術的コンテキスト**: ".xcresult file"への言及

##### `allowed-tools` フィールド

- **概要**: スキル実行中に Claude が使用できるツールを制限
- **値**: `Bash, Read`
- **このスキルでの実装**:
  - `Bash`: xcodebuild や xcresulttool の実行に必要
  - `Read`: テスト結果ファイルの読み取りに必要
  - Bash で使用するツールは別途 /permissions 等で指定するか、実行時に許可する必要があります。

### スキル本文の構造

#### 1. When to Use セクション (SKILL.md:9-18)

```markdown
**ALWAYS use this skill when:**

- Just finished running `xcodebuild test` or `swift test`
- Tests failed and need to investigate failures
- User asks about test results, test status, or test failures
- User mentions "テスト結果", "失敗したテスト", "テストエラー"
```

特徴：

- トリガー条件（"ALWAYS use"）として記述
- コンテキスト（xcodebuild test）の提示
- 多言語対応（日本語キーワードも含む）

#### 2. Quick Start セクション (SKILL.md:20-29)

実行可能なコードサンプルを提供：

```bash
# 1. Find latest .xcresult
# Note: <DerivedDataPath> is typically ~/Library/Developer/Xcode/DerivedData/
# but can be changed with xcodebuild's -derivedDataPath option
LATEST_RESULT=$(find <DerivedDataPath>/<ProjectName>-*/Logs/Test -name "*.xcresult" -type d -print0 2>/dev/null | xargs -0 ls -td | head -1)

# 2. Extract summary and detailed results
xcrun xcresulttool get test-results summary --path "${LATEST_RESULT}"
xcrun xcresulttool get test-results tests --path "${LATEST_RESULT}"
```

これにより、Claude はスキル実行時に具体的なコマンドを理解できます。

#### 3. Output Requirements セクション (SKILL.md:31-36)

期待される出力形式を定義：

```markdown
Present results in Japanese with:

1. **統計**: Total, passed, failed, skipped tests
2. **失敗したテスト**: Each failed test with error message and `file:line` reference
3. **次のステップ**: Actionable suggestions based on failure patterns
```

#### 4. Error Handling セクション (SKILL.md:38-42)

想定されるエラーシナリオと対処法：

- .xcresult ファイルが見つからない場合
- 複数の失敗が同じテストスイートで発生した場合
- アサーション失敗の場合

#### 5. Examples セクション (SKILL.md:44-55)

具体的なユーザー発言例とスキル起動の対応：

```
User: "テストを実行したけど失敗した"
→ Invoke this skill immediately
```

## ベストプラクティスの適用

このスキルは、[Claude Code のスキル仕様](https://docs.claude.com/en/docs/claude-code/skills)で推奨されている[ベストプラクティス](https://docs.claude.com/en/docs/claude-code/skills#best-practices)を参考に実装しています：

### 具体的な description

ドキュメントの推奨する「具体的な使用例を含む」という原則に従い、"Use immediately after running xcodebuild test"のような明確なトリガーを記述しています。

### allowed-tools による制約

読み取り専用の操作に必要な最小限のツール（Bash、Read）のみを許可し、安全性を確保しています。

### 段階的な詳細情報

SKILL.md 本文に詳細な手順やコードサンプルを含めることで、Claude が必要に応じて追加のコンテキストを読み込めるようにしています。

## トラブルシューティング

スキルが起動されない場合は以下を確認してください。

1. **ファイルパス**: `.claude/skills/review-ios-test-results/SKILL.md`に配置されているか
2. **Claude Code の再起動**: Claude Code にスキルを認識させるため、再起動が必要です。
