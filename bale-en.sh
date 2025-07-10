#!/bin/bash
echo ' ____       _      _       _____
| __ )     / \    | |     | ____|
|  _ \    / _ \   | |     |  _|
| |_) |  / ___ \  | |___  | |___
|____/  /_/   \_\ |_____| |_____|
'

file_content=()
current_line=0
filename=""
search_results=()
search_index=0
modified=false

if [ $# -ge 1 ]; then
    if [ -f "$1" ]; then
        filename="$1"
        mapfile -t file_content < "$1"
        echo "File loaded: $1 (total ${#file_content[@]} lines)"
    else
        filename="$1"
        echo "New file: $1"
    fi
fi

show_help() {
    echo "?BALE Line Editor - Help Manual"
    echo " Basic Commands:"
    echo "  i       Enter insert mode (insert before current line, end with '.')"
    echo "  I       Insert at the beginning of the file (end with '.')"
    echo "  a       Append after current position (end with '.')"
    echo "  A       Append at the end of the file (end with '.')"
    echo "  p       Print current line"
    echo "  P       Print all lines (with line numbers)"
    echo "  n       Show total number of lines"
    echo "  d       Delete current line"
    echo "  D       Delete all lines"
    echo "  w [file] Save file,If you don't specify a file name, it will be saved to the w file in this directory."
    echo "  l [file] Load file"
    echo "  /pattern    Search content"
    echo "  N       Jump to next match"
    echo "  g line  Jump to specified line"
    echo "  q       Quit editor (confirm unsaved changes)"
    echo "  Q       Force quit without saving"
    echo "  h       Show help"
    echo "  !command   Execute shell command"
    echo "  s       Directly call sed"
}

print_line() {
    if (( current_line >= 0 && current_line < ${#file_content[@]} )); then
        echo "$((current_line + 1)): ${file_content[$current_line]}"
    else
        echo "?Error: Invalid line number"
    fi
}

print_all() {
    for i in "${!file_content[@]}"; do
        echo "$((i + 1)): ${file_content[$i]}"
    done
}

save_file() {
    if [[ -z "$filename" ]]; then
        echo "?Error: Please specify a filename"
        return
    fi
    local save_name="${1:-$filename}"
    printf "%s\n" "${file_content[@]}" > "$save_name"
    echo "File saved to: $save_name"
    filename="$save_name" 
    modified=false
}

load_file() {
    if [[ -z "$1" ]]; then
        echo "?Error: Please specify a filename"
        return
    fi
    if [[ ! -f "$1" ]]; then
        echo "?Error: File does not exist"
        return
    fi
    if $modified; then
        read -p "Current content is unsaved, are you sure to load a new file? (y/n) " confirm
        [[ "$confirm" != "y" ]] && return
    fi #91
    mapfile -t file_content < "$1"
    current_line=0
    echo "File loaded: $1 (total ${#file_content[@]} lines)"
    filename="$1"
    modified=false
}

search_text() {
    if [[ -z "$1" ]]; then
        echo "?Error: Please enter a search keyword"
        return
    fi
    search_results=()
    for i in "${!file_content[@]}"; do
        if [[ "${file_content[$i]}" == *"$1"* ]]; then
            search_results+=("$i")
        fi
    done
    if (( ${#search_results[@]} == 0 )); then
        echo "?No matches found"
    else
        search_index=0
        current_line="${search_results[$search_index]}"
        echo "Found ${#search_results[@]} matches:"
        print_line
    fi
}

next_match() {
    if (( ${#search_results[@]} == 0 )); then
        echo "?Error: Please search first"
        return
    fi
    ((search_index++))
    if (( search_index >= ${#search_results[@]} )); then
        search_index=0
        echo "?Back to the first match"
    fi
    current_line="${search_results[$search_index]}"
    print_line
}

insert_mode() {
    local insert_at=$1
    echo "Insert mode (end with '.'): "
    local insert_lines=()
    while true; do
        read -r input
        [[ "$input" == "." ]] && break
        insert_lines+=("$input")
    done
    if (( ${#insert_lines[@]} > 0 )); then
        file_content=("${file_content[@]:0:$insert_at}" "${insert_lines[@]}" "${file_content[@]:$insert_at}")
        current_line=$((insert_at + ${#insert_lines[@]} - 1))
        modified=true
    fi
}

append_mode() {
    local append_at=$1
    echo "Append mode (end with '.'): "
    local append_lines=()
    while true; do
        read -r input
        [[ "$input" == "." ]] && break
        append_lines+=("$input")
    done
    if (( ${#append_lines[@]} > 0 )); then
        file_content=("${file_content[@]:0:$append_at+1}" "${append_lines[@]}" "${file_content[@]:$append_at+1}")
        current_line=$((append_at + ${#append_lines[@]}))
        modified=true
    fi
}

delete_all() {
    file_content=()
    current_line=0
    modified=true
    echo "All lines deleted"
}

execute_shell() {
    eval "$@"
}

confirm_exit() {
    if $modified; then
        read -p "There are unsaved changes, are you sure to exit? (y/n) " confirm
        [[ "$confirm" != "y" ]] && return 1
    fi
    return 0
}
replace_text() {
    if [[ -z "$1" ]]; then
        echo "?Error: Please provide a sed command"
        return
    fi
    if [[ "$1" == *"--help"* ]]; then
        sed --help
        return
    fi
    if (( current_line >= 0 && current_line < ${#file_content[@]} )); then
        local old_line="${file_content[$current_line]}"
        local new_line=$(echo "$old_line" | sed "$1")
        if [[ "$old_line" != "$new_line" ]]; then
            file_content[$current_line]="$new_line"
            modified=true
            echo "Line processed:"
            print_line
        else
            echo "?No changes made, sed command had no effect"
        fi
    else
        echo "?Error: Invalid line number"
    fi
}
wnqnld(){
    echo -e "自然赠与你 树冠 微风 肩头 的暴雨\n片刻后生成 忠诚 永恒 不息 的身体\n---山雀"
}

echo "?BALE Line Editor - Type 'h' for help"
while true; do
    read -p "? " cmd

    case "$cmd" in
        i) insert_mode $current_line ;;
        I) insert_mode 0 ;;
        a) append_mode $current_line ;;
        A) append_mode $((${#file_content[@]} - 1)) ;;
        p) print_line ;;
        P) print_all ;;
        n) echo "Total lines: ${#file_content[@]}" ;;
        d) 
            if (( current_line >= 0 && current_line < ${#file_content[@]} )); then
                file_content=("${file_content[@]:0:$current_line}" "${file_content[@]:$current_line+1}")
                modified=true
                echo "Line deleted"
            else
                echo "?Error: Invalid line number"
            fi
            ;;
        D) delete_all ;;
        w*) save_file "${cmd#w }" ;;
        l*) load_file "${cmd#l }" ;;
        /*) search_text "${cmd#/}" ;;
        N) next_match ;;
        g*) 
            new_line=$(( ${cmd#g } - 1 ))
            if (( new_line >= 0 && new_line < ${#file_content[@]} )); then
                current_line=$new_line
                print_line
            else
                echo "?Error: Line number out of range"
            fi
            ;;
        q) 
            if confirm_exit; then 
                echo "Exiting BALE. Good bye! If not exited, type !exit 0"
                return 0
            fi
            ;;
        Q) echo "Force quitting"; return 0;;
        h) show_help ;;
        !*) execute_shell "${cmd#!}" ;;
        [0-9]*) 
            new_line=$((cmd - 1))
            if (( new_line >= 0 && new_line < ${#file_content[@]} )); then
                current_line=$new_line
                print_line
                else
                echo "?Error:Line number is out of range."
            fi
            ;;
        s*) replace_text "${cmd#s}" ;;
        *) echo "?Error:Unknown command (Enter 'h' to view help.)" ;;
    esac
done