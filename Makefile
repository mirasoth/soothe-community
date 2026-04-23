# Makefile for soothe-community package
# Development workflow automation

.PHONY: help install install-dev test test-cov lint format build clean docs version check-all

# Default target
.DEFAULT_GOAL := help

# Variables
PYTHON := python3
PIP := $(PYTHON) -m pip
PYTEST := $(PYTHON) -m pytest
RUFF := $(PYTHON) -m ruff
PACKAGE := soothe-community
SRC_DIR := src/soothe_community
TEST_DIR := tests

# ============================================================================
# Installation
# ============================================================================

install: ## Install package in production mode
	$(PIP) install .

install-dev: ## Install package in development mode with all dev dependencies
	$(PIP) install -e ".[dev]"
	@echo "✅ Development environment ready"

install-clean: ## Clean install (remove existing first)
	$(PIP) uninstall -y $(PACKAGE) || true
	$(MAKE) install-dev

# ============================================================================
# Testing
# ============================================================================

test: ## Run all tests
	$(PYTEST) $(TEST_DIR) -v

test-cov: ## Run tests with coverage report
	$(PYTEST) $(TEST_DIR) --cov=$(SRC_DIR) --cov-report=term --cov-report=html -v
	@echo "📊 Coverage report: htmlcov/index.html"

test-quick: ## Run tests quickly (no coverage, failfast)
	$(PYTEST) $(TEST_DIR) -x -q

test-plugin: ## Run tests for specific plugin (usage: make test-plugin PLUGIN=paperscout)
	@if [ -z "$(PLUGIN)" ]; then \
		echo "Usage: make test-plugin PLUGIN=<plugin_name>"; \
		exit 1; \
	fi
	$(PYTEST) $(TEST_DIR)/test_$(PLUGIN) -v

test-integration: ## Run integration tests only
	$(PYTEST) $(TEST_DIR) -v -m integration

test-unit: ## Run unit tests only
	$(PYTEST) $(TEST_DIR) -v -m "not integration"

# ============================================================================
# Code Quality
# ============================================================================

format: ## Format code with ruff
	$(RUFF) format $(SRC_DIR) $(TEST_DIR)
	@echo "✅ Code formatted"

lint: ## Lint code with ruff
	$(RUFF) check $(SRC_DIR) $(TEST_DIR)

lint-fix: ## Lint and auto-fix issues
	$(RUFF) check --fix $(SRC_DIR) $(TEST_DIR)
	@echo "✅ Linting issues fixed"

type-check: ## Run type checking with mypy (if available)
	@if command -v mypy >/dev/null 2>&1; then \
		$(PYTHON) -m mypy $(SRC_DIR); \
	else \
		echo "⚠️  mypy not installed. Run: pip install mypy"; \
	fi

check-all: ## Run all quality checks (format, lint, type-check, test)
	$(MAKE) format
	$(MAKE) lint
	$(MAKE) type-check
	$(MAKE) test-quick
	@echo "✅ All checks passed"

# ============================================================================
# Build & Distribution
# ============================================================================

build: ## Build package distributions (wheel and sdist)
	$(PYTHON) -m build
	@echo "📦 Built distributions in dist/"

build-wheel: ## Build wheel only
	$(PYTHON) -m build --wheel

build-sdist: ## Build source distribution only
	$(PYTHON) -m build --sdist

clean-build: ## Remove build artifacts
	rm -rf build/ dist/ *.egg-info
	rm -rf $(SRC_DIR)/__pycache__ $(TEST_DIR)/__pycache__
	rm -rf .pytest_cache .ruff_cache .coverage htmlcov
	@echo "🧹 Build artifacts cleaned"

# ============================================================================
# Documentation
# ============================================================================

docs: ## Generate documentation (if pdocs available)
	@if command -v pdoc >/dev/null 2>&1; then \
		pdoc $(SRC_DIR) -o docs/html; \
		echo "📚 Documentation generated in docs/html"; \
	else \
		echo "⚠️  pdoc not installed. Run: pip install pdoc3"; \
	fi

docs-clean: ## Remove generated documentation
	rm -rf docs/html
	@echo "🧹 Documentation cleaned"

# ============================================================================
# Version Management
# ============================================================================

version: ## Show current package version
	@grep "__version__" $(SRC_DIR)/__init__.py | head -1

version-bump: ## Bump version (usage: make version-bump TYPE=patch|minor|major)
	@if [ -z "$(TYPE)" ]; then \
		echo "Usage: make version-bump TYPE=patch|minor|major"; \
		exit 1; \
	fi
	@echo "⚠️  Manual version bump required. Edit __version__ in $(SRC_DIR)/__init__.py"

# ============================================================================
# Plugin Development
# ============================================================================

plugin-list: ## List all available plugins
	@echo "📦 Available plugins:"
	@grep -A 3 "soothe.plugins" pyproject.toml | grep "=" | sed 's/^ */  - /'

plugin-template: ## Create new plugin from template (usage: make plugin-template NAME=my_plugin)
	@if [ -z "$(NAME)" ]; then \
		echo "Usage: make plugin-template NAME=<plugin_name>"; \
		exit 1; \
	fi
	@echo "Creating plugin: $(NAME)"
	cp -r $(SRC_DIR)/.plugin_template $(SRC_DIR)/$(NAME)
	@echo "✅ Plugin template created in $(SRC_DIR)/$(NAME)"
	@echo "📝 Next steps:"
	@echo "   1. Edit files in $(SRC_DIR)/$(NAME)/"
	@echo "   2. Add tests in $(TEST_DIR)/test_$(NAME)/"
	@echo "   3. Register in pyproject.toml entry-points"

plugin-validate: ## Validate all plugin entry points
	@echo "Checking plugin entry points in pyproject.toml..."
	@grep -q "soothe.plugins" pyproject.toml && echo "✅ Entry points found" || echo "❌ No entry points"
	@grep -A 3 "soothe.plugins" pyproject.toml | grep "=" | wc -l | awk '{print "✅ " $$1 " plugins registered"}'

# ============================================================================
# Git & Release
# ============================================================================

git-status: ## Show git status summary
	@git status -s
	@echo ""
	@git log --oneline -5

git-clean: ## Remove untracked files (dry run)
	@git clean -n -d
	@echo "Run 'make git-clean-force' to actually remove files"

git-clean-force: ## Remove untracked files (force)
	@git clean -f -d
	@echo "🧹 Untracked files removed"

release-prep: ## Prepare for release (run all checks)
	$(MAKE) check-all
	$(MAKE) build
	@echo "✅ Release preparation complete"
	@echo "📝 Next steps:"
	@echo "   1. Update version in $(SRC_DIR)/__init__.py"
	@echo "   2. git commit -am 'Release v<X.Y.Z>'"
	@echo "   3. git tag v<X.Y.Z>"
	@echo "   4. git push && git push --tags"
	@echo "   5. twine upload dist/*"

# ============================================================================
# Dependencies
# ============================================================================

deps-check: ## Check for outdated dependencies
	$(PIP) list --outdated

deps-update: ## Update dependencies to latest versions
	$(PIP) install --upgrade -e ".[dev]"
	@echo "✅ Dependencies updated"

deps-lock: ## Generate requirements lock file (if using pip-tools)
	@if command -v pip-compile >/dev/null 2>&1; then \
		pip-compile pyproject.toml -o requirements.txt; \
		echo "✅ Requirements locked"; \
	else \
		echo "⚠️  pip-tools not installed"; \
	fi

# ============================================================================
# Development Utilities
# ============================================================================

shell: ## Start Python shell with package loaded
	$(PYTHON) -i -c "from soothe_community import *; print('📦 soothe-community loaded')"

info: ## Show package information
	@echo "📦 Package: $(PACKAGE)"
	@$(MAKE) --no-print-directory version
	@echo ""
	@echo "📂 Structure:"
	@find $(SRC_DIR) -type d | head -10
	@echo ""
	@echo "📋 Entry points:"
	@$(MAKE) --no-print-directory plugin-list

env-info: ## Show environment information
	@echo "🐍 Python: $(PYTHON)"
	@$(PYTHON) --version
	@echo ""
	@echo "📦 Pip: $(PIP)"
	@$(PIP) --version
	@echo ""
	@echo "🔍 Tools:"
	@command -v pytest >/dev/null 2>&1 && echo "  pytest: ✓" || echo "  pytest: ✗"
	@command -v ruff >/dev/null 2>&1 && echo "  ruff: ✓" || echo "  ruff: ✗"
	@command -v mypy >/dev/null 2>&1 && echo "  mypy: ✓" || echo "  mypy: ✗"
	@command -v build >/dev/null 2>&1 && echo "  build: ✓" || echo "  build: ✗"

# ============================================================================
# Cleanup
# ============================================================================

clean: ## Clean all generated files and caches
	$(MAKE) clean-build
	$(MAKE) docs-clean
	$(MAKE) git-clean
	@echo "🧹 All cleaned"

clean-all: ## Deep clean (includes git untracked)
	$(MAKE) clean
	$(MAKE) git-clean-force

# ============================================================================
# Help
# ============================================================================

help: ## Show this help message
	@echo "🛠️  soothe-community Makefile"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@awk '/^## / { \
		if (prev_line ~ /^[a-zA-Z_-]+:/) { \
			target = substr(prev_line, 1, index(prev_line, ":")-1); \
			description = substr($$0, 3); \
			printf "  %-20s %s\n", target, description; \
		} \
	} \
	{ prev_line = $$0 }' $(MAKEFILE_LIST)
	@echo ""
	@echo "Examples:"
	@echo "  make install-dev      # Install for development"
	@echo "  make test             # Run tests"
	@echo "  make check-all        # Run all quality checks"
	@echo "  make plugin-template NAME=my_plugin  # Create new plugin"
	@echo ""
	@echo "For more info: make info"

# ============================================================================
# Quick Shortcuts
# ============================================================================

i: install-dev ## Shortcut: install-dev
t: test-quick ## Shortcut: test-quick
c: check-all ## Shortcut: check-all
b: build ## Shortcut: build
cl: clean ## Shortcut: clean
>>>>>>> fd703fa (Refactor: Adapt community plugins to soothe-sdk architecture)
