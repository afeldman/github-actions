#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

prepare_artifact() {

    local type="$1"

    mkdir -p artifact

    case "$type" in

        go)
            prepare_go_artifact "$2"
            ;;

        python)
            prepare_python_artifact
            ;;

        node)
            prepare_node_artifact
            ;;

        *)
            warn "Unsupported artifact type '$type'"
            return 1
            ;;
    esac
}

prepare_go_artifact() {

    require_command cp

    local binary="$1"

    info "Preparing Go artifact"

    local file
    file="$(find_go_binary "$binary")"

    [[ -n "$file" ]] || {
        warn "Binary '$binary' not found."
        return 1
    }

    copy_go_binary "$file" "$binary"
}

prepare_python_artifact() {

    require_command cp

    info "Preparing Python artifact"

    [[ -d dist ]] || {
        warn "dist directory not found."
        return 1
    }

    cp -R dist artifact/dist
}

prepare_node_artifact() {

    require_command cp

    info "Preparing Node artifact"

    [[ -d dist ]] || {
        warn "dist directory not found."
        return 1
    }

    cp -R dist artifact/dist
}

find_go_binary() {

    local binary="$1"

    find dist -type f -name "$binary" \
        | grep linux_amd64 \
        | head -n1 || true
}

copy_go_binary() {

    local file="$1"
    local binary="$2"

    cp "$file" "artifact/$binary"
}

artifact_exists() {

    local type="$1"
    local binary="$2"

    case "$type" in

        go)
            [[ -f "artifact/$binary" ]]
            ;;

        python)
            [[ -d artifact/dist ]]
            ;;

        node)
            [[ -d artifact/dist ]]
            ;;

        *)
            warn "Unsupported artifact type '$type'"
            return 1
            ;;
    esac
}

artifact_path() {

    local type="$1"
    local binary="$2"

    case "$type" in

        go)
            echo "artifact/$binary"
            ;;

        python)
            echo "artifact/dist"
            ;;

        node)
            echo "artifact/dist"
            ;;

        *)
            warn "Unsupported artifact type '$type'"
            return 1
            ;;
    esac
}
