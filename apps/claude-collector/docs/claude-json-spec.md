# ~/.claude.json 仕様書

Claude Code が `~/.claude.json` に永続化する設定・利用データのJSON構造仕様。

調査日: 2026-02-23
対象バージョン: Claude Code 2.1.50

---

## ファイル概要

- パス: `~/.claude.json`
- 形式: JSON（単一オブジェクト）
- 更新タイミング: セッション終了時に上書き保存（セッション中にも随時更新される）
- サイズ目安: プロジェクト数に比例（20プロジェクトで約2300行）

---

## トップレベル構造

```json
{
  // グローバル設定
  "numStartups": number,
  "installMethod": string,
  "autoUpdates": boolean,
  "theme": string,
  "promptQueueUseCount": number,
  "autoConnectIde": boolean,
  "firstStartTime": string (ISO 8601),
  "claudeCodeFirstTokenDate": string (ISO 8601),
  "userID": string (SHA-256 hash),
  "hasCompletedOnboarding": boolean,
  "lastOnboardingVersion": string,
  "lastReleaseNotesSeen": string,
  "fallbackAvailableWarningThreshold": number,

  // キャッシュ（内部用）
  "cachedStatsigGates": object,
  "cachedDynamicConfigs": object,
  "cachedGrowthBookFeatures": object,

  // MCP サーバー（グローバル）
  "mcpServers": McpServersMap,

  // プロジェクト別データ ★収集対象
  "projects": ProjectsMap,

  // スキル使用統計 ★収集対象
  "skillUsage": SkillUsageMap,

  // GitHub リポジトリマッピング
  "githubRepoPaths": GitHubRepoPathsMap,

  // アカウント情報
  "oauthAccount": OAuthAccount,

  // マイグレーション・UI状態フラグ
  "sonnet45MigrationComplete": boolean,
  "opus45MigrationComplete": boolean,
  "opusProMigrationComplete": boolean,
  "thinkingMigrationComplete": boolean,
  "sonnet1m45MigrationComplete": boolean,
  "hasOpusPlanDefault": boolean,
  "penguinModeOrgEnabled": boolean,
  "showSpinnerTree": boolean,
  // ...その他フラグ多数
}
```

---

## 収集対象データの詳細

### projects（ProjectsMap）

キー: プロジェクトの絶対パス（string）
値: ProjectData オブジェクト

```json
{
  "/Users/xxx/workspace/project-name": ProjectData
}
```

#### ProjectData

| フィールド | 型 | 説明 | 収集優先度 |
|---|---|---|---|
| `lastCost` | `number` | 直近セッションの合計コスト (USD) | **高** |
| `lastModelUsage` | `ModelUsageMap` | モデル別の利用詳細 | **高** |
| `lastTotalInputTokens` | `number` | 直近セッションの総入力トークン数 | **高** |
| `lastTotalOutputTokens` | `number` | 直近セッションの総出力トークン数 | **高** |
| `lastTotalCacheCreationInputTokens` | `number` | キャッシュ作成トークン数 | **高** |
| `lastTotalCacheReadInputTokens` | `number` | キャッシュ読み取りトークン数 | **高** |
| `lastTotalWebSearchRequests` | `number` | Web検索リクエスト数 | 中 |
| `lastDuration` | `number` | セッション総時間 (ms) | 中 |
| `lastAPIDuration` | `number` | API呼び出し総時間 (ms) | 中 |
| `lastAPIDurationWithoutRetries` | `number` | リトライ除外のAPI時間 (ms) | 低 |
| `lastToolDuration` | `number` | ツール実行総時間 (ms) | 中 |
| `lastLinesAdded` | `number` | 追加行数 | 中 |
| `lastLinesRemoved` | `number` | 削除行数 | 中 |
| `lastSessionId` | `string` | セッションID (UUID v4) | **高** |
| `lastFpsAverage` | `number` | 平均FPS | 低 |
| `lastFpsLow1Pct` | `number` | 下位1%FPS | 低 |
| `lastSessionMetrics` | `SessionMetrics` | パフォーマンスメトリクス | 低 |
| `allowedTools` | `string[]` | 許可済みツール一覧 | 対象外 |
| `mcpServers` | `McpServersMap` | プロジェクト固有MCPサーバー | 対象外 |
| `mcpContextUris` | `string[]` | MCPコンテキストURI | 対象外 |
| `disabledMcpServers` | `string[]` | 無効化されたMCPサーバー | 対象外 |
| `hasTrustDialogAccepted` | `boolean` | 信頼ダイアログ承認済み | 対象外 |
| `ignorePatterns` | `string[]` | 無視パターン | 対象外 |
| `projectOnboardingSeenCount` | `number` | オンボーディング表示回数 | 対象外 |
| `hasClaudeMdExternalIncludesApproved` | `boolean` | 外部CLAUDE.MD承認 | 対象外 |
| `hasCompletedProjectOnboarding` | `boolean` | オンボーディング完了 | 対象外 |
| `exampleFiles` | `string[]` | サンプルファイル一覧 | 対象外 |
| `exampleFilesGeneratedAt` | `number` | サンプル生成日時 (epoch ms) | 対象外 |
| `reactVulnerabilityCache` | `object` | React脆弱性キャッシュ | 対象外 |

**注意**: `lastXxx` フィールドはすべて「直近のセッション」のデータのみを保持する。累積値ではない。ファイルが更新されるたびに上書きされるため、定期的な収集が必要。

#### ModelUsageMap

キー: モデルID（string）
値: ModelUsageData オブジェクト

確認済みモデルID:
- `claude-haiku-4-5-20251001`
- `claude-opus-4-5-20251101`
- `claude-opus-4-6`
- `claude-sonnet-4-6`

```json
{
  "claude-opus-4-6": {
    "inputTokens": 34677,
    "outputTokens": 82396,
    "cacheReadInputTokens": 17151726,
    "cacheCreationInputTokens": 422510,
    "webSearchRequests": 0,
    "costUSD": 13.449835499999999
  }
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `inputTokens` | `number` | 入力トークン数 |
| `outputTokens` | `number` | 出力トークン数 |
| `cacheReadInputTokens` | `number` | キャッシュ読み取りトークン数 |
| `cacheCreationInputTokens` | `number` | キャッシュ作成トークン数 |
| `webSearchRequests` | `number` | Web検索リクエスト数 |
| `costUSD` | `number` | コスト (USD) |

#### SessionMetrics

パフォーマンスメトリクス。存在しないプロジェクトもある（任意フィールド）。

```json
{
  "frame_duration_ms_count": 55018,
  "frame_duration_ms_min": 0.134,
  "frame_duration_ms_max": 28.697,
  "frame_duration_ms_avg": 1.681,
  "frame_duration_ms_p50": 1.604,
  "frame_duration_ms_p95": 2.998,
  "frame_duration_ms_p99": 7.299,
  "hook_duration_ms_count": 434,
  "hook_duration_ms_min": 24,
  "hook_duration_ms_max": 13664,
  "hook_duration_ms_avg": 367.732,
  "hook_duration_ms_p50": 151,
  "hook_duration_ms_p95": 567.149,
  "hook_duration_ms_p99": 7612.450,
  "pre_tool_hook_duration_ms_count": 290,
  "pre_tool_hook_duration_ms_min": 0,
  "pre_tool_hook_duration_ms_max": 112,
  "pre_tool_hook_duration_ms_avg": 15.062,
  "pre_tool_hook_duration_ms_p50": 3,
  "pre_tool_hook_duration_ms_p95": 59.75,
  "pre_tool_hook_duration_ms_p99": 85.21
}
```

---

### skillUsage（SkillUsageMap）

キー: スキル名（string）
値: SkillUsageData オブジェクト

```json
{
  "git-commit": {
    "usageCount": 188,
    "lastUsedAt": 1771824797817
  }
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `usageCount` | `number` | 累積使用回数 |
| `lastUsedAt` | `number` | 最終使用日時 (epoch ms) |

---

### githubRepoPaths（GitHubRepoPathsMap）

キー: GitHub リポジトリ識別子 `{owner}/{repo}`（string）
値: ローカルパスの配列 `string[]`

```json
{
  "bomo-inc/wonder-api": [
    "/Users/miya/workspace/wonder/apps/wonder-api"
  ]
}
```

---

### oauthAccount（OAuthAccount）

```json
{
  "accountUuid": "42e88bb1-...",
  "emailAddress": "user@example.com",
  "organizationUuid": "0274d931-...",
  "hasExtraUsageEnabled": true,
  "billingType": "stripe_subscription",
  "accountCreatedAt": "2025-05-29T22:52:36.798106Z",
  "subscriptionCreatedAt": "2025-05-30T01:14:54.141476Z",
  "displayName": "表示名"
}
```

---

## フィールド存在パターン

プロジェクトによってフィールドの有無が異なる。

### 最小構成（セッション未実行）

```json
{
  "allowedTools": [],
  "mcpContextUris": [],
  "hasTrustDialogAccepted": false,
  "projectOnboardingSeenCount": 0,
  "hasClaudeMdExternalIncludesApproved": false,
  "hasClaudeMdExternalIncludesWarningShown": false
}
```

### セッション実行後の追加フィールド

- `lastCost`, `lastDuration`, `lastAPIDuration`, `lastToolDuration`
- `lastLinesAdded`, `lastLinesRemoved`
- `lastTotalInputTokens`, `lastTotalOutputTokens`
- `lastTotalCacheCreationInputTokens`, `lastTotalCacheReadInputTokens`
- `lastTotalWebSearchRequests`
- `lastSessionId`

### 複数セッション実行後の追加フィールド（任意）

- `lastModelUsage` — モデル別利用データ
- `lastAPIDurationWithoutRetries`
- `lastSessionMetrics` — パフォーマンスメトリクス
- `lastFpsAverage`, `lastFpsLow1Pct`

---

## 収集における注意事項

1. **上書き特性**: `lastXxx` フィールドは直近セッションの値で上書きされる。累積データではないため、履歴を保持するには定期的にスナップショットを取得する必要がある。

2. **セッションIDによる重複検知**: `lastSessionId` が変わっていなければ、前回と同じセッションデータ。新しいセッションIDを検知した時のみ収集すればよい。

3. **プロジェクトの増減**: 新しいプロジェクトが追加されることがある。キーの動的な増減に対応する必要がある。

4. **数値精度**: `costUSD` はIEEE 754浮動小数点のため、`0.23118050000000007` のような端数が出る。表示・集計時に丸め処理が必要。

5. **タイムスタンプ形式の混在**:
   - ISO 8601 文字列: `firstStartTime`, `claudeCodeFirstTokenDate`, `oauthAccount` 内
   - Epoch ミリ秒 (number): `exampleFilesGeneratedAt`, `skillUsage.lastUsedAt`

6. **ファイル書き込み中の読み取り**: Claude Code がセッション中にファイルを更新するため、listen で検知した直後は書き込み途中の可能性がある。読み取り時のJSON パースエラーへの対策が必要。
