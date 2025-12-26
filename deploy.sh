#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 EventGenie Deployment Script${NC}"
echo "================================"
echo ""

# Configuration
REPOS_DIR="./repos"
BACKEND_REPO="https://github.com/Jack1337322/eventgenie-backend.git"
FRONTEND_REPO="https://github.com/Jack1337322/eventgenie-frontend.git"
AGENTS_REPO="https://github.com/Jack1337322/eventgenie-agents.git"

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}❌ .env file not found!${NC}"
    echo "Please create .env file from .env.example:"
    echo "  cp .env.example .env"
    echo "  nano .env  # Edit with your values"
    exit 1
fi

# Load environment variables
set -a
source .env
set +a

# Create repos directory
mkdir -p $REPOS_DIR

# Function to clone or update repository
clone_or_update_repo() {
    local repo_url=$1
    local repo_name=$2
    local repo_path="$REPOS_DIR/$repo_name"
    
    if [ -d "$repo_path" ]; then
        echo -e "${YELLOW}📦 Updating $repo_name...${NC}"
        cd "$repo_path"
        # Try main branch first, then master
        if git rev-parse --verify main >/dev/null 2>&1; then
            git pull origin main || git pull origin main --rebase
        elif git rev-parse --verify master >/dev/null 2>&1; then
            git pull origin master || git pull origin master --rebase
        else
            echo -e "${YELLOW}⚠️  No main/master branch found, pulling default${NC}"
            git pull
        fi
        cd - > /dev/null
    else
        echo -e "${GREEN}📥 Cloning $repo_name...${NC}"
        git clone "$repo_url" "$repo_path"
    fi
}

# Clone/update repositories
echo -e "${GREEN}📥 Cloning/updating repositories...${NC}"
clone_or_update_repo "$BACKEND_REPO" "eventgenie-backend"
clone_or_update_repo "$FRONTEND_REPO" "eventgenie-frontend"
clone_or_update_repo "$AGENTS_REPO" "eventgenie-agents"

# Copy init.sql to repos directory if needed
if [ ! -f "$REPOS_DIR/init.sql" ]; then
    if [ -f "./init.sql" ]; then
        cp ./init.sql "$REPOS_DIR/"
    fi
fi

# Build and start services
echo ""
echo -e "${GREEN}🔨 Building Docker images...${NC}"
docker-compose -f docker-compose.prod.yml build --no-cache

echo ""
echo -e "${GREEN}🚀 Starting services...${NC}"
docker-compose -f docker-compose.prod.yml up -d

# Wait for services to be healthy
echo ""
echo -e "${YELLOW}⏳ Waiting for services to start...${NC}"
sleep 15

# Check service status
echo ""
echo -e "${GREEN}📊 Service status:${NC}"
docker-compose -f docker-compose.prod.yml ps

echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo -e "${BLUE}Services available at:${NC}"
echo "  - Frontend: http://${SERVER_HOST:-localhost}:${FRONTEND_PORT:-3000}"
echo "  - Backend: http://${SERVER_HOST:-localhost}:${BACKEND_PORT:-8080}"
echo "  - Agents: http://${SERVER_HOST:-localhost}:${AGENTS_PORT:-8001}"
echo ""
echo -e "${YELLOW}To view logs:${NC}"
echo "  docker-compose -f docker-compose.prod.yml logs -f"
echo ""
echo -e "${YELLOW}To stop services:${NC}"
echo "  docker-compose -f docker-compose.prod.yml down"
