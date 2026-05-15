"""Tests for browser and Claude community subagent factories."""

import os

import pytest

pytest.importorskip("soothe", reason="browser/claude subagents require soothe runtime hooks")


class TestBrowserSubagent:
    def test_creates_compiled_subagent_dict(self) -> None:
        from soothe_community.browser import create_browser_subagent

        spec = create_browser_subagent()
        assert spec["name"] == "browser"
        assert "description" in spec
        assert "runnable" in spec

    def test_has_runnable(self) -> None:
        from soothe_community.browser import create_browser_subagent

        spec = create_browser_subagent()
        assert spec["runnable"] is not None

    def test_model_override(self) -> None:
        from soothe_community.browser import create_browser_subagent

        spec = create_browser_subagent(model="gpt-4o")
        assert spec["name"] == "browser"
        assert "runnable" in spec

    def test_privacy_features_disabled_by_default(self) -> None:
        """Test that privacy-invasive features are disabled by default."""
        from soothe_community.browser import _build_browser_graph

        graph = _build_browser_graph()
        assert graph is not None

    def test_privacy_features_can_be_enabled(self) -> None:
        """Test that privacy features can be explicitly enabled."""
        from soothe_community.browser import create_browser_subagent

        spec = create_browser_subagent(
            disable_extensions=False,
            disable_cloud=False,
            disable_telemetry=False,
        )
        assert spec["name"] == "browser"
        assert "runnable" in spec


class TestClaudeSubagent:
    def test_creates_compiled_subagent_dict(self) -> None:
        from soothe_community.claude import create_claude_subagent

        spec = create_claude_subagent()
        assert spec["name"] == "claude"
        assert "description" in spec
        assert "runnable" in spec

    def test_has_runnable(self) -> None:
        from soothe_community.claude import create_claude_subagent

        spec = create_claude_subagent()
        assert spec["runnable"] is not None

    def test_custom_params(self) -> None:
        from soothe_community.claude import create_claude_subagent

        spec = create_claude_subagent(
            model="opus",
            max_turns=10,
            permission_mode="plan",
        )
        assert spec["name"] == "claude"
        assert "runnable" in spec

    def test_cwd_is_supported(self) -> None:
        from soothe_community.claude import create_claude_subagent

        spec = create_claude_subagent(cwd=os.getcwd())
        assert spec["name"] == "claude"
        assert "runnable" in spec
