.PHONY: ci rubocop brakeman rspec

ci: rubocop brakeman rspec

rubocop:
	docker compose exec rails-api bundle exec rubocop

brakeman:
	docker compose exec rails-api bundle exec brakeman --no-pager

rspec:
	docker compose exec rails-api bundle exec rspec
