.PHONY: ci rubocop steep rspec

ci: rubocop steep rspec

rubocop:
	docker compose exec claude-collector bundle exec rubocop

steep:
	docker compose exec claude-collector bundle exec steep check

rspec:
	docker compose exec claude-collector bundle exec rspec || \
	  (docker compose exec claude-collector bundle exec ruby bin/analyze_coverage; exit 1)
