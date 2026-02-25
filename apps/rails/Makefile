.PHONY: ci rubocop rspec

ci: rubocop rspec

rubocop:
	docker compose exec rails-api bundle exec rubocop

rspec:
	docker compose exec rails-api bundle exec rspec
