.PHONY: help deploy update logs stop start restart clean status backup health check

help: ## Show this help message
	@echo "EventGenie Deployment Makefile"
	@echo "================================"
	@echo ""
	@echo "Available commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""

deploy: ## Deploy EventGenie (clone repos, build, start)
	@echo "🚀 Deploying EventGenie..."
	@chmod +x deploy.sh
	@./deploy.sh

update: ## Update repositories and redeploy
	@echo "🔄 Updating EventGenie..."
	@docker-compose -f docker-compose.prod.yml pull || true
	@./deploy.sh

logs: ## Show logs from all services
	@docker-compose -f docker-compose.prod.yml logs -f

logs-backend: ## Show backend logs
	@docker-compose -f docker-compose.prod.yml logs -f backend-service

logs-agents: ## Show agents service logs
	@docker-compose -f docker-compose.prod.yml logs -f agents-service

logs-frontend: ## Show frontend logs
	@docker-compose -f docker-compose.prod.yml logs -f frontend

logs-postgres: ## Show PostgreSQL logs
	@docker-compose -f docker-compose.prod.yml logs -f postgres

stop: ## Stop all services
	@echo "⏹ Stopping services..."
	@docker-compose -f docker-compose.prod.yml down

start: ## Start all services
	@echo "▶ Starting services..."
	@docker-compose -f docker-compose.prod.yml up -d

restart: ## Restart all services
	@echo "🔄 Restarting services..."
	@docker-compose -f docker-compose.prod.yml restart

restart-backend: ## Restart backend service
	@docker-compose -f docker-compose.prod.yml restart backend-service

restart-agents: ## Restart agents service
	@docker-compose -f docker-compose.prod.yml restart agents-service

clean: ## Stop services and remove volumes (WARNING: deletes data!)
	@echo "🧹 Cleaning up..."
	@echo "⚠️  WARNING: This will delete all data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose -f docker-compose.prod.yml down -v; \
		docker system prune -f; \
		echo "✅ Cleanup complete"; \
	fi

status: ## Show status of all services
	@docker-compose -f docker-compose.prod.yml ps

health: ## Check health of all services
	@echo "🏥 Health Check"
	@echo "=============="
	@echo ""
	@echo "Backend:"
	@curl -s http://localhost:8080/actuator/health || echo "❌ Backend not responding"
	@echo ""
	@echo "Agents:"
	@curl -s http://localhost:8001/health || echo "❌ Agents not responding"
	@echo ""
	@echo "Frontend:"
	@curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:3000 || echo "❌ Frontend not responding"

backup: ## Create database backup
	@echo "💾 Creating database backup..."
	@mkdir -p backups
	@docker-compose -f docker-compose.prod.yml exec -T postgres pg_dump -U eventgenie eventgenie > backups/backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "✅ Backup created in backups/ directory"

restore: ## Restore database from backup (usage: make restore FILE=backups/backup_20250101_120000.sql)
	@if [ -z "$(FILE)" ]; then \
		echo "❌ Please specify backup file: make restore FILE=backups/backup.sql"; \
		exit 1; \
	fi
	@echo "📥 Restoring database from $(FILE)..."
	@docker-compose -f docker-compose.prod.yml exec -T postgres psql -U eventgenie eventgenie < $(FILE)
	@echo "✅ Database restored"

check: ## Check if all required files exist
	@echo "🔍 Checking deployment files..."
	@test -f .env && echo "✅ .env file exists" || echo "❌ .env file missing (copy from .env.example)"
	@test -f docker-compose.prod.yml && echo "✅ docker-compose.prod.yml exists" || echo "❌ docker-compose.prod.yml missing"
	@test -f deploy.sh && echo "✅ deploy.sh exists" || echo "❌ deploy.sh missing"
	@test -f init.sql && echo "✅ init.sql exists" || echo "❌ init.sql missing"
	@test -d repos/eventgenie-backend && echo "✅ Backend repo cloned" || echo "⚠️  Backend repo not cloned (will be cloned on deploy)"
	@test -d repos/eventgenie-frontend && echo "✅ Frontend repo cloned" || echo "⚠️  Frontend repo not cloned (will be cloned on deploy)"
	@test -d repos/eventgenie-agents && echo "✅ Agents repo cloned" || echo "⚠️  Agents repo not cloned (will be cloned on deploy)"

shell-backend: ## Open shell in backend container
	@docker-compose -f docker-compose.prod.yml exec backend-service /bin/sh

shell-agents: ## Open shell in agents container
	@docker-compose -f docker-compose.prod.yml exec agents-service /bin/bash

shell-postgres: ## Open PostgreSQL shell
	@docker-compose -f docker-compose.prod.yml exec postgres psql -U eventgenie eventgenie

build: ## Build Docker images without starting
	@echo "🔨 Building Docker images..."
	@docker-compose -f docker-compose.prod.yml build --no-cache

pull-repos: ## Update all repositories
	@echo "📥 Updating repositories..."
	@cd repos/eventgenie-backend && git pull origin main || git pull origin master || true
	@cd repos/eventgenie-frontend && git pull origin main || git pull origin master || true
	@cd repos/eventgenie-agents && git pull origin main || git pull origin master || true
	@echo "✅ Repositories updated"
