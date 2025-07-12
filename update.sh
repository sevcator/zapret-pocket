#!/system/bin/sh
set +e

MODPATH="/data/adb/modules/zapret"
WGETCMD=$(cat "$MODPATH/wgetpath" 2>/dev/null || echo "wget")
DNSCRYPTLISTSDIR="$MODPATH/dnscrypt"
ZAPRETLISTSDIR="$MODPATH/list"
ZAPRETIPSETSDIR="$MODPATH/ipset"
CLOAKINGUPDATE=$(cat "$MODPATH/config/dnscrypt-cloaking-rules-update" 2>/dev/null || echo "0")
BLOCKEDUPDATE=$(cat "$MODPATH/config/dnscrypt-blocked-names-update" 2>/dev/null || echo "0")
DNSCRYPTFILES_cloaking_rules=$(cat "$MODPATH/config/dnscrypt-cloaking-rules-link" 2>/dev/null || echo "https://raw.githubusercontent.com/sevcator/dnscrypt-proxy-stuff/refs/heads/main/cloaking-rules.txt")
DNSCRYPTFILES_blocked_names=$(cat "$MODPATH/config/dnscrypt-blocked-names-link" 2>/dev/null || echo "https://raw.githubusercontent.com/sevcator/dnscrypt-proxy-stuff/refs/heads/main/blocked-yandex.txt")

source "$MODPATH/config/updater.sh"

update_file() {
    file="$1"
    url="$2"
    name=$(basename "$file")

    remote_size=$(busybox wget --spider -S "$url" 2>&1 | awk 'BEGIN{IGNORECASE=1}/Content-Length:/ {print $2}' | tr -d '\r')
    if [ -z "$remote_size" ] || [ "$remote_size" = "0" ]; then
        return 0
    fi

    local_size=0
    if [ -f "$file" ]; then
        local_size=$(stat -c%s "$file" 2>/dev/null || echo 0)
    fi

    if [ "$remote_size" -ne "$local_size" ] 2>/dev/null; then
        echo "[ $local_size/$remote_size; $name ] Downloading"
        $WGETCMD -q -O "$file" "$url"
    else
        echo "[ $local_size/$remote_size; $name ] Keeping"
    fi
}

update_dir() {
    dir="$1"
    base_url="$2"
    predefined_files="$3"

    mkdir -p "$dir"

    for file_path in "$dir"/*; do
        [ -f "$file_path" ] || continue
        file_name=$(basename "$file_path")
        case " $IGNORE_FILES " in
            *" $file_name "*) continue ;;
        esac

        overwrite_url=$(get_overwrite_url "$file_name")
        if [ -z "$overwrite_url" ]; then
            url="${base_url}${file_name}"
        else
            url="$overwrite_url"
        fi

        update_file "$file_path" "$url"
    done

    for file_name in $predefined_files; do
        case " $IGNORE_FILES " in
            *" $file_name "*) continue ;;
        esac

        file_path="$dir/$file_name"
        if [ ! -f "$file_path" ]; then
            overwrite_url=$(get_overwrite_url "$file_name")
            if [ -z "$overwrite_url" ]; then
                url="${base_url}${file_name}"
            else
                url="$overwrite_url"
            fi
            update_file "$file_path" "$url"
        fi
    done
}

update_dir "$ZAPRETLISTSDIR" "$ZAPRETLISTSDEFAULTLINK" "$PREDEFINED_LIST_FILES"
update_dir "$ZAPRETIPSETSDIR" "$ZAPRETIPSETSDEFAULTLINK" "$PREDEFINED_IPSET_FILES"

[ "$CLOAKINGUPDATE" = "1" ] && update_file "$DNSCRYPTLISTSDIR/cloaking-rules.txt" "$DNSCRYPTFILES_cloaking_rules"
[ "$BLOCKEDUPDATE" = "1" ] && update_file "$DNSCRYPTLISTSDIR/blocked-names.txt" "$DNSCRYPTFILES_blocked_names"
