#!/bin/bash
# Health Check Script for MSN-AI Docker Container
# Version: 1.0.0
# Author: Alan Mac-Arthur García Díaz
# Email: alan.mac.arthur.garcia.diaz@gmail.com
# License: GNU General Public License v3.0
# Description: Comprehensive health check for MSN-AI container

# Environment variables
MSN_AI_PORT=${MSN_AI_PORT:-8000}
OLLAMA_HOST=${OLLAMA_HOST:-ollama:11434}

# Exit codes
EXIT_SUCCESS=0
EXIT_FAILURE=1

# Function to check web server
check_web_server() {
    # Check if web server is responding
    if curl -s -f "http://localhost:${MSN_AI_PORT}/msn-ai.html" >/dev/null 2>&1; then
        return 0
    else
        echo "❌ Web server not responding on port $MSN_AI_PORT"
        return 1
    fi
}

# Function to check Ollama connection
check_ollama() {
    # Check if Ollama is reachable (optional for health check)
    if curl -s -f "http://${OLLAMA_HOST}/api/tags" >/dev/null 2>&1; then
        return 0
    else
        # Ollama not responding, but this shouldn't fail the health check
        # since MSN-AI can work without AI (limited functionality)
        echo "⚠️ Ollama not responding (AI features may be limited)"
        return 0
    fi
}

# Function to check critical files
check_files() {
    # Check if main application file exists
    if [ ! -f "/app/msn-ai.html" ]; then
        echo "❌ Main application file missing"
        return 1
    fi

    # Check if assets directory exists
    if [ ! -d "/app/assets" ]; then
        echo "❌ Assets directory missing"
        return 1
    fi

    return 0
}

# Function to check disk space
check_disk_space() {
    # Check if we have at least 100MB free space
    AVAILABLE_SPACE=$(df /app | tail -1 | awk '{print $4}')
    MIN_SPACE=102400  # 100MB in KB

    if [ "$AVAILABLE_SPACE" -lt "$MIN_SPACE" ]; then
        echo "❌ Insufficient disk space: ${AVAILABLE_SPACE}KB available, ${MIN_SPACE}KB required"
        return 1
    fi

    return 0
}

# Function to check memory usage
check_memory() {
    # Check if container has reasonable memory available
    if [ -f /sys/fs/cgroup/memory/memory.usage_in_bytes ] && [ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then
        USAGE=$(cat /sys/fs/cgroup/memory/memory.usage_in_bytes)
        LIMIT=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)

        # If usage is over 95% of limit, that's concerning
        USAGE_PERCENT=$((USAGE * 100 / LIMIT))

        if [ "$USAGE_PERCENT" -gt 95 ]; then
            echo "⚠️ High memory usage: ${USAGE_PERCENT}%"
            # Don't fail on high memory usage, just warn
        fi
    fi

    return 0
}

# Main health check function
main() {
    local checks_passed=0
    local checks_failed=0

    # Perform all checks
    echo "🏥 MSN-AI Health Check..."

    # Critical checks (must pass)
    if check_files; then
        checks_passed=$((checks_passed + 1))
    else
        checks_failed=$((checks_failed + 1))
    fi

    if check_web_server; then
        checks_passed=$((checks_passed + 1))
    else
        checks_failed=$((checks_failed + 1))
    fi

    if check_disk_space; then
        checks_passed=$((checks_passed + 1))
    else
        checks_failed=$((checks_failed + 1))
    fi

    # Non-critical checks (warnings only)
    check_ollama
    check_memory

    # Determine overall health
    if [ "$checks_failed" -eq 0 ]; then
        echo "✅ Container is healthy ($checks_passed checks passed)"
        exit $EXIT_SUCCESS
    else
        echo "❌ Container is unhealthy ($checks_failed checks failed, $checks_passed passed)"
        exit $EXIT_FAILURE
    fi
}

# Run health check
main "$@"
