#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
THUNAR_WRAPPER_SOURCE="${SCRIPT_DIR}/upscale-selected.sh"
THUNAR_WRAPPER_NAME="upscale-selected"
ACTION_ID="thunar-image-upscale"
ACTION_NAME="Upscale Image (Real-ESRGAN)"
ACTION_DESCRIPTION="Upscale selected image files with Real-ESRGAN."
ACTION_ICON="image-x-generic"
THUNAR_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/Thunar"
THUNAR_UCA_FILE="${THUNAR_CONFIG_DIR}/uca.xml"

usage() {
    cat <<EOF
Usage: $(basename "$0") [--system] [--bin-dir DIR] [--skip-thunar]

Installs image-upscale globally and registers a Thunar right-click action.

Options:
    --system       Install to a system venv at /opt/image-upscale/venv and use /usr/local/bin.
  --bin-dir DIR  Install Thunar wrapper script to a specific bin directory.
  --skip-thunar  Skip writing Thunar custom action.
  -h, --help     Show this help text.
EOF
}

xml_escape() {
    sed \
        -e 's/&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g' <<<"$1"
}

remove_existing_action() {
    local input_file=$1
    local output_file=$2

    awk -v action_id="$ACTION_ID" '
        function flush_action() {
            if (buffer != "" && !drop_buffer) {
                printf "%s", buffer
            }
            buffer = ""
            drop_buffer = 0
            in_action = 0
        }

        BEGIN {
            in_action = 0
            buffer = ""
            drop_buffer = 0
        }

        !in_action {
            if ($0 ~ /<action>/) {
                in_action = 1
                buffer = $0 ORS
            } else {
                print
            }
            next
        }

        {
            buffer = buffer $0 ORS
            if ($0 ~ ("<unique-id>" action_id "</unique-id>")) {
                drop_buffer = 1
            }
            if ($0 ~ /<\/action>/) {
                flush_action()
            }
        }

        END {
            if (in_action) {
                flush_action()
            }
        }
    ' "$input_file" > "$output_file"
}

write_uca_file() {
    local destination=$1
    local escaped_command=$2
    local escaped_description=$3
    local escaped_name=$4
    local escaped_icon=$5

    cat > "$destination" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<actions>
  <action>
    <icon>${escaped_icon}</icon>
    <name>${escaped_name}</name>
    <submenu></submenu>
    <unique-id>${ACTION_ID}</unique-id>
    <command>${escaped_command}</command>
    <description>${escaped_description}</description>
    <patterns>*</patterns>
    <startup-notify/>
    <directories/>
    <audio-files/>
    <image-files/>
    <other-files/>
    <text-files/>
    <video-files/>
  </action>
</actions>
EOF
}

update_thunar_action() {
    local installed_wrapper=$1
    local escaped_command
    local escaped_description
    local escaped_name
    local escaped_icon
    local tmp_clean
    local tmp_final

    escaped_command=$(xml_escape "\"${installed_wrapper}\" %F")
    escaped_description=$(xml_escape "$ACTION_DESCRIPTION")
    escaped_name=$(xml_escape "$ACTION_NAME")
    escaped_icon=$(xml_escape "$ACTION_ICON")

    install -d -m 755 "$THUNAR_CONFIG_DIR"

    if [[ ! -f "$THUNAR_UCA_FILE" ]]; then
        write_uca_file "$THUNAR_UCA_FILE" "$escaped_command" "$escaped_description" "$escaped_name" "$escaped_icon"
        chmod 644 "$THUNAR_UCA_FILE"
        return
    fi

    if ! grep -q '<actions>' "$THUNAR_UCA_FILE" || ! grep -q '</actions>' "$THUNAR_UCA_FILE"; then
        echo "ERROR: ${THUNAR_UCA_FILE} does not look like a valid Thunar custom actions file." >&2
        exit 1
    fi

    tmp_clean=$(mktemp)
    tmp_final=$(mktemp)

    remove_existing_action "$THUNAR_UCA_FILE" "$tmp_clean"

    awk \
        -v action_id="$ACTION_ID" \
        -v action_command="$escaped_command" \
        -v action_description="$escaped_description" \
        -v action_name="$escaped_name" \
        -v action_icon="$escaped_icon" '
            BEGIN {
                inserted = 0
                action_block = "  <action>\n" \
                    "    <icon>" action_icon "</icon>\n" \
                    "    <name>" action_name "</name>\n" \
                    "    <submenu></submenu>\n" \
                    "    <unique-id>" action_id "</unique-id>\n" \
                    "    <command>" action_command "</command>\n" \
                    "    <description>" action_description "</description>\n" \
                    "    <patterns>*</patterns>\n" \
                    "    <startup-notify/>\n" \
                    "    <directories/>\n" \
                    "    <audio-files/>\n" \
                    "    <image-files/>\n" \
                    "    <other-files/>\n" \
                    "    <text-files/>\n" \
                    "    <video-files/>\n" \
                    "  </action>\n"
            }

            /<\/actions>/ && !inserted {
                printf "%s", action_block
                inserted = 1
            }

            {
                print
            }

            END {
                if (!inserted) {
                    exit 1
                }
            }
        ' "$tmp_clean" > "$tmp_final"

    install -m 644 "$tmp_final" "$THUNAR_UCA_FILE"
    rm -f "$tmp_clean" "$tmp_final"
}

install_python_package() {
    local system_install=$1
    local install_dir=$2
    local venv_dir

    if ! command -v python3 >/dev/null 2>&1; then
        echo "ERROR: python3 not found." >&2
        exit 1
    fi

    if [[ $system_install -eq 1 ]]; then
        if [[ $EUID -ne 0 ]]; then
            echo "ERROR: --system requires root privileges (use sudo)." >&2
            exit 1
        fi
        venv_dir="/opt/image-upscale/venv"
    else
        venv_dir="${XDG_DATA_HOME:-$HOME/.local/share}/image-upscale/venv"
    fi

    install -d -m 755 "$(dirname "$venv_dir")"
    python3 -m venv "$venv_dir"
    "$venv_dir/bin/python" -m pip install --upgrade pip
    "$venv_dir/bin/python" -m pip install --upgrade "$SCRIPT_DIR"

    install -d -m 755 "$install_dir"
    install -m 755 "$venv_dir/bin/upscale" "$install_dir/upscale"

    echo "Installed Python package in venv: $venv_dir"
}

main() {
    local system_install=0
    local bin_dir_override=
    local skip_thunar=0
    local install_dir=
    local wrapper_install_path=

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --system)
                system_install=1
                shift
                ;;
            --bin-dir)
                if [[ $# -lt 2 ]]; then
                    echo "ERROR: --bin-dir requires a value." >&2
                    exit 1
                fi
                bin_dir_override=$2
                shift 2
                ;;
            --skip-thunar)
                skip_thunar=1
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "ERROR: Unknown option: $1" >&2
                usage >&2
                exit 1
                ;;
        esac
    done

    if [[ ! -f "$THUNAR_WRAPPER_SOURCE" ]]; then
        echo "ERROR: Could not find ${THUNAR_WRAPPER_SOURCE}." >&2
        exit 1
    fi

    if [[ -n "$bin_dir_override" ]]; then
        install_dir=$bin_dir_override
    elif [[ $system_install -eq 1 || $EUID -eq 0 ]]; then
        install_dir=/usr/local/bin
    else
        install_dir="${HOME}/.local/bin"
    fi

    install_python_package "$system_install" "$install_dir"

    wrapper_install_path="${install_dir}/${THUNAR_WRAPPER_NAME}"

    install -d -m 755 "$install_dir"
    install -m 755 "$THUNAR_WRAPPER_SOURCE" "$wrapper_install_path"

    if [[ $skip_thunar -eq 0 ]]; then
        update_thunar_action "$wrapper_install_path"
    fi

    echo "Installed Python package: image-upscale"
    echo "Installed Thunar wrapper: ${wrapper_install_path}"

    if [[ $skip_thunar -eq 0 ]]; then
        echo "Registered Thunar action: ${ACTION_NAME}"
    fi

    if [[ ":$PATH:" != *":${install_dir}:"* ]]; then
        echo "NOTE: ${install_dir} is not currently in PATH. Add it if you want to run ${THUNAR_WRAPPER_NAME} from a shell."
    fi

    echo "If Thunar is already open, restart it to reload custom actions."
}

main "$@"
