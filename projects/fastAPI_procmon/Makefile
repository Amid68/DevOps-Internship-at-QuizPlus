.PHONY: help build up down logs clean dev prod

help:
	@echo "Process Monitor - Docker Commands"
	@echo ""
	@echo "  make build    - Build all containers"
	@echo "  make up       - Start all services"
	@echo "  make down     - Stop all services"
	@echo "  make logs     - View logs"
	@echo "  make clean    - Clean up containers and images"
	@echo "  make dev      - Run in development mode"
	@echo "  make prod     - Run in production mode"

build:
	docker-compose build

up:
	docker-compose up -d

down:
	docker-compose down

logs:
	docker-compose logs -f

clean:
	docker-compose down -v
	docker system prune -af

dev:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

prod:
	docker-compose up -d

backend-logs:
	docker logs -f procmon-backend

frontend-logs:
	docker logs -f procmon-frontend

restart:
	docker-compose restart

status:
	docker-compose ps
