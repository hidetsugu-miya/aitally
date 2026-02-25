---
phase: tasks
phase_status: completed
tasks:
- {id: 1, status: planning}
- {id: 2, status: pending}
- {id: 3, status: pending}
- {id: 4, status: pending}
- {id: 5, status: pending}
- {id: 6, status: pending}
- {id: 7, status: pending}
- {id: 8, status: pending}
- {id: 9, status: pending}
- {id: 10, status: pending}
- {id: 11, status: pending}
- {id: 12, status: pending}
- {id: 13, status: pending}
- {id: 14, status: pending}
- {id: 15, status: pending}
---

# 引き継ぎ書

## 実装要件

- claude-collectorが収集した利用統計データをAPI経由で参照できるようにする
- テスト基盤を整備し、既存コードを含むアプリケーション全体でコードカバレッジ100%を維持する
- APIドキュメントを自動生成し、API仕様を常に最新の状態で参照できるようにする
- JSON形式でのレスポンス構造を統一的に管理する
- aitally向けのコーディングスタンダードを文書化し、レイヤー構造に基づいた責務分離が実現された開発体制を整備する
- 一覧系APIにページネーション機能を提供する
- ライブラリ導入: rspec, simplecov, rswag, alba, kaminari

---

## 成果物

- `docs/development-flow/requirement.md`
- `docs/development-flow/design.md`
- `docs/development-flow/tasks.md`
- `docs/development-flow/tasks/task01.md` 〜 `task15.md`

---

## 引き継ぎ事項

### ユーザーフィードバック（設計レビュー）

1. **カバレッジ enforcement**: simplecov の minimum_coverage 100% を設計方針として明記すること（FUNC-002 に反映済み）
2. **セッション詳細APIパラメータ変更**: REQ-006 のセッション詳細 API は主キー（id）ではなく session_id カラム（Claude セッション識別子）をパラメータとして使用すること（FUNC-007 に反映済み）
3. **開発順序変更**: FUNC-009（コーディングルールファイル作成）を開発順序の先頭に移動すること。実装時のルール基盤となるため、他機能より先に整備する（反映済み）
4. **FUNC-ID リナンバリング**: コーディングルールファイル作成を FUNC-001 とし、既存 FUNC-001〜008 を FUNC-002〜009 に繰り下げること。全セクション（トレーサビリティマトリクス、機能一覧、機能間依存関係、機能詳細）のIDを一括変更する

---

## 次の作業

実装フェーズでタスク1から実装開始（`/development-flow`）
