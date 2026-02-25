# タスク分解

## 関連ドキュメント

- **要件定義**: docs/development-flow/requirement.md
- **基本設計**: docs/development-flow/design.md

## タスク詳細

以下のタスクは**FUNC単位・実装順序順**に記載されています。

---

### 機能: FUNC-001（コーディングルールファイル作成）

#### Task 1. CodingRulesFiles【Config Task】

→ 詳細: docs/development-flow/tasks/task01.md

---

### 機能: FUNC-002（rspec 基盤構築）

#### Task 2. RspecSetup【Config Task】

→ 詳細: docs/development-flow/tasks/task02.md

---

### 機能: FUNC-003（simplecov 導入）

#### Task 3. SimplecovSetup【Config Task】

→ 詳細: docs/development-flow/tasks/task03.md

---

### 機能: FUNC-004（rswag 導入）

#### Task 4. RswagSetup【Config Task】

→ 詳細: docs/development-flow/tasks/task04.md

---

### 機能: FUNC-005（alba 導入）

#### Task 5. AlbaSetup【Config Task】

→ 詳細: docs/development-flow/tasks/task05.md

---

### 機能: FUNC-006（kaminari 導入）

#### Task 6. KaminariSetup【Config Task】

→ 詳細: docs/development-flow/tasks/task06.md

---

### 共通コンポーネント

#### Task 7. PaginationMeta【Shared Component Task】

→ 詳細: docs/development-flow/tasks/task07.md

---

### 機能: FUNC-007（セッション一覧 API）/ FUNC-008（セッション詳細 API）

> Sessions API はセッション一覧（FUNC-007）とセッション詳細（FUNC-008）を同一コントローラ（SessionsController）が担当するため、Phase 構造でグループ化する。

#### Phase 1: 共通基盤・セッション一覧

#### Task 8. Api::V1::BaseController【Shared Component Task】

→ 詳細: docs/development-flow/tasks/task08.md

#### Task 9. ClaudeCollector::SessionResource【Feature Task】

→ 詳細: docs/development-flow/tasks/task09.md

#### Task 10. Api::V1::ClaudeCollector::SessionsController（index）【Feature Task】

→ 詳細: docs/development-flow/tasks/task10.md

#### Phase 2: セッション詳細

#### Task 11. ClaudeCollector::ModelUsageResource【Feature Task】

→ 詳細: docs/development-flow/tasks/task11.md

#### Task 12. ClaudeCollector::SessionDetailResource【Feature Task】

→ 詳細: docs/development-flow/tasks/task12.md

#### Task 13. Api::V1::ClaudeCollector::SessionsController（show）【Feature Task】

→ 詳細: docs/development-flow/tasks/task13.md

---

### 機能: FUNC-009（モデル別利用量一覧 API）

#### Task 14. Api::V1::ClaudeCollector::ModelUsagesController【Feature Task】

→ 詳細: docs/development-flow/tasks/task14.md

---

### 共通: 確認テストタスク

#### Task 15. ExistingClassesTest【確認テストタスク】

→ 詳細: docs/development-flow/tasks/task15.md
