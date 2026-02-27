.PHONY: up up.postgres up.claude-collector up.rails \
       down down.claude-collector down.rails \
       ci rubocop rubocop.claude-collector rubocop.rails \
       rubocop.auto_correct rubocop.auto_correct.claude-collector rubocop.auto_correct.rails \
       rbs-collection rbs-inline steep steep.claude-collector steep.rails \
       rspec rspec.claude-collector rspec.rails brakeman

# ============================================================
# Lifecycle
# ============================================================

up: up.postgres up.claude-collector up.rails

up.postgres:
	docker compose up -d --wait

up.claude-collector:
	@make -C apps/claude-collector up

up.rails:
	@make -C apps/rails up

down: down.claude-collector down.rails
	docker compose down

down.claude-collector:
	@make -C apps/claude-collector down

down.rails:
	@make -C apps/rails down

# ============================================================
# CI（app委譲）
# ============================================================

ci: rubocop brakeman rspec steep

# ============================================================
# RuboCop（app委譲）
# ============================================================

rubocop: rubocop.claude-collector rubocop.rails

rubocop.claude-collector:
	@make -C apps/claude-collector rubocop

rubocop.rails:
	@make -C apps/rails rubocop

# ============================================================
# RuboCop Auto Correct（app委譲）
# ============================================================

rubocop.auto_correct: rubocop.auto_correct.claude-collector rubocop.auto_correct.rails

rubocop.auto_correct.claude-collector:
	@make -C apps/claude-collector rubocop.auto_correct

rubocop.auto_correct.rails:
	@make -C apps/rails rubocop.auto_correct

# ============================================================
# RBS / Steep（app委譲）
# ============================================================

rbs-collection:
	@make -C apps/claude-collector rbs-collection
	@make -C apps/rails rbs-collection

rbs-inline:
	@make -C apps/claude-collector rbs-inline
	@make -C apps/rails rbs-inline

steep: steep.claude-collector steep.rails

steep.claude-collector:
	@make -C apps/claude-collector steep

steep.rails:
	@make -C apps/rails steep

# ============================================================
# RSpec（app委譲）
# ============================================================

rspec: rspec.claude-collector rspec.rails

rspec.claude-collector:
	@make -C apps/claude-collector rspec

rspec.rails:
	@make -C apps/rails rspec

# ============================================================
# Brakeman（app委譲）
# ============================================================

brakeman:
	@make -C apps/rails brakeman
