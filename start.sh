#!/bin/sh

rc='\033[0m'
red='\033[0;31m'

check() {
    exit_code=$1
    message=$2

    if [ "$exit_code" -ne 0 ]; then
        printf '%sERROR: %s%s\n' "$red" "$message" "$rc"
        exit 1
    fi

    unset exit_code
    unset message
}

findArch() {
    os=$(uname -s)
    machine=$(uname -m)
    case "$os" in
        Darwin)
            case "$machine" in
                arm64) arch="arm64-macos" ;;
                *) check 1 "Unsupported macOS architecture: $machine"
            esac
            ;;
        Linux)
            case "$machine" in
                x86_64|amd64) arch="x86_64" ;;
                aarch64) arch="aarch64" ;;
                armv7l|armv8l|arm64) arch="arm64" ;;
                *) check 1 "Unsupported Linux architecture: $machine"
            esac
            ;;
        *)
            check 1 "Unsupported operating system: $os"
    esac
}

get_latest_release() {
  curl --silent "https://api.github.com/repos/harshav167/linutil/releases/latest" | 
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
}

getUrl() {
    local latest_release=$(get_latest_release)
    case "${arch}" in
        x86_64)
            echo "https://github.com/harshav167/linutil/releases/download/$latest_release/linutil"
            ;;
        aarch64)
            echo "https://github.com/harshav167/linutil/releases/download/$latest_release/linutil-aarch64"
            ;;
        arm64)
            echo "https://github.com/harshav167/linutil/releases/download/$latest_release/linutil-arm64"
            ;;
        arm64-macos)
            echo "https://github.com/harshav167/linutil/releases/download/$latest_release/linutil-arm64-macos"
            ;;
        *)
            check 1 "Unsupported architecture: $arch"
            ;;
    esac
}

findArch
echo "Detected architecture: $arch"

temp_file=$(mktemp)
check $? "Creating the temporary file"

echo "Downloading linutil for ${arch} architecture from $(getUrl)"
curl -fsL "$(getUrl)" -o "$temp_file"
check $? "Downloading linutil"

echo "Making linutil executable"
chmod +x "$temp_file"
check $? "Making linutil executable"

echo "Executing linutil"
"$temp_file"
check $? "Executing linutil"

rm -f "$temp_file"
check $? "Deleting the temporary file"
