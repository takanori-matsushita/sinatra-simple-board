.DEFAULT_GOAL := help

init: build db-init ## build develoment environment

build: ## build container
	docker-compose build
	# docker-compose stop sinatra

db-init: ## Initialize database
	docker-compose up -d postgres
	docker-compose exec postgres ash -c 'psql -U postgres -d myapp -f myapp.sql'
	
db-exec: ## Into postgres container
	docker-compose exec postgres ash -c 'psql -U postgres -d myapp'

serve: up attach ## Run Serve

up: ## Run ruby container
	docker-compose up -d

attach: ## Attach running Sinatra container for binding.pry
	docker attach sinatra

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
