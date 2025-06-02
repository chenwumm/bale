#!/bin/bash

# Initialize variables
file_content=()
current_line=0
filename=""
search_results=()
search_index=0

# Show help
show_help() {
    echo "?BAFE Help:"
    echo "  i       Enter insert mode (end with '.')"
    echo "  p       Print current line"
    echo "  a       Append text at end"
    echo "  d       Delete current line"
    echo "  w file  Save to file"
    echo "  l file  Load file"
    echo "  /text   Search for text"
    echo "  n       Jump to next match"
    echo "  q       Quit editor"
    echo "  h       Show this help"
    echo "  number  Go to line number (e.g. '3')"
}

# Print current line (with line number)
print_line() {
    if (( current_line >= 0 && current_line < ${#file_content[@]} )); then
        echo "$((current_line + 1)): ${file_content[$current_line]}"
    else
        echo "?Error: Invalid line number"
    fi
}

# Save file
save_file() {
    if [[ -z "$1" ]]; then
        echo "?Error: Please specify filename (e.g. 'w filename')"
        return
    fi
    printf "%s\n" "${file_content[@]}" > "$1"
    echo "File saved to: $1"
    filename="$1"
}

# Load file
load_file() {
    if [[ -z "$1" ]]; then
        echo "?Error: Please specify filename (e.g. 'l filename')"
        return
    fi
    if [[ ! -f "$1" ]]; then
        echo "?Error: File not found"
        return
    fi
    mapfile -t file_content < "$1"
    current_line=0
    echo "Loaded file: $1 (${#file_content[@]} lines)"
    filename="$1"
}

# Search text
search_text() {
    if [[ -z "$1" ]]; then
        echo "?Error: Please enter search term (e.g. '/hello')"
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

# Jump to next match
next_match() {
    if (( ${#search_results[@]} == 0 )); then
        echo "?Error: Search first with '/term'"
        return
    fi
    ((search_index++))
    if (( search_index >= ${#search_results[@]} )); then
        search_index=0
        echo "?Back to first match"
    fi
    current_line="${search_results[$search_index]}"
    print_line
}

# Main loop
echo "?BAFE - Bash Advanced File Editor (type 'h' for help)"
while true; do
    read -p "? " cmd

    case "$cmd" in
        i)  # Insert mode
            echo "Insert mode (enter '.' to finish):"
            while true; do
                read -r input
                if [[ "$input" == "." ]]; then
                    break
                fi
                file_content=("${file_content[@]:0:$current_line}" "$input" "${file_content[@]:$current_line}")
                ((current_line++))
            done
            ;;
        p)  # Print current line
            print_line
            ;;
        a)  # Append line
            echo "Append text (enter '.' to finish):"
            while true; do
                read -r input
                if [[ "$input" == "." ]]; then
                    break
                fi
                file_content+=("$input")
                current_line=${#file_content[@]}
            done
            ;;
        d)  # Delete current line
            if (( current_line >= 0 && current_line < ${#file_content[@]} )); then
                file_content=("${file_content[@]:0:$current_line}" "${file_content[@]:$current_line+1}")
                echo "Line deleted."
            else
                echo "?Error: Invalid line number"
            fi
            ;;
        w*) # Save file
            save_file "${cmd#w }"
            ;;
        l*) # Load file
            load_file "${cmd#l }"
            ;;
        /*) # Search text
            search_text "${cmd#/}"
            ;;
        n)  # Next match
            next_match
            ;;
        q)  # Quit
            echo "Exiting BAFE. Goodbye!"
            exit 0
            ;;
        h)  # Help
            show_help
            ;;
        [0-9]*) # Go to line number
            new_line=$((cmd - 1))
            if (( new_line >= 0 && new_line < ${#file_content[@]} )); then
                current_line="$new_line"
                print_line
            else
                echo "?Error: Line number out of range"
            fi
            ;;
        *)  # Unknown command
            echo "?Error: Unknown command (type 'h' for help)"
            ;;
    esac
done