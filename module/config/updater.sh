PREDEFINED_LIST_FILES="reestr.txt default.txt google.txt providers.txt"
PREDEFINED_IPSET_FILES="ipset-all.txt"
ZAPRETLISTSDEFAULTLINK="https://raw.githubusercontent.com/sevcator/zapret-magisk/refs/heads/main/module/list/"
ZAPRETIPSETSDEFAULTLINK="https://raw.githubusercontent.com/sevcator/zapret-magisk/refs/heads/main/module/ipset/"
IGNORE_FILES="custom.txt exclude.txt"
get_overwrite_url() {
    file="$1"
    case "$file" in
        "reestr.txt") echo "https://raw.githubusercontent.com/sevcator/zapret-lists/refs/heads/main/module/list/reestr.txt" ;;
        "ipset-all.txt") echo "https://raw.githubusercontent.com/sevcator/zapret-lists/refs/heads/main/module/ipset/ipset-all.txt" ;;
        *) echo "" ;;
    esac
}