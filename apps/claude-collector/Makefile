COMPOSE := docker compose

.PHONY: ci rubocop rubocop.auto_correct steep rbs-collection rbs-inline rspec up down

ci: rubocop rspec steep

rubocop:
	$(COMPOSE) run --rm app bundle exec rubocop

rubocop.auto_correct:
	$(COMPOSE) run --rm app bundle exec rubocop -A

steep:
	$(COMPOSE) run --rm app bundle exec steep check

rbs-collection:
	$(COMPOSE) run --rm app bundle exec rbs collection install

rbs-inline:
	$(COMPOSE) run --rm app bundle exec rbs-inline --output lib/

rspec:
	$(COMPOSE) run --rm app bundle exec rspec || \
	  ($(COMPOSE) run --rm app bundle exec ruby bin/analyze_coverage; exit 1)

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down
