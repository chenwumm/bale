#!/bin/bash
echo ' ____       _      _       _____                                       | __ )     / \    | |     | ____|                                      |  _ \    / _ \   | |     |  _|                                        | |_) |  / ___ \  | |___  | |___                                       |____/  /_/   \_\ |_____| |_____|
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
        echo "已加载文件: $1 (共 ${#file_content[@]} 行)"
    else
        filename="$1"
        echo "新文件: $1"
    fi
fi

show_help() {
    echo "?BALE 行编辑器 - 帮助手册"
    echo " 基本命令:"
    echo "  i       进入插入模式（在当前行前插入，输入 '.' 结束）"
    echo "  I       在文件开头插入（输入 '.' 结束）"
    echo "  a       在当前位置后追加（输入 '.' 结束）"
    echo "  A       在文件末尾追加（输入 '.' 结束）"
    echo "  p       打印当前行"
    echo "  P       打印所有行（带行号）"
    echo "  n       显示总行数"
    echo "  d       删除当前行"
    echo "  D       删除所有行"
    echo "  w [文件] 保存文件"
    echo "  l [文件] 加载文件"
    echo "  /模式    搜索内容"
    echo "  N       跳转到下一个匹配项"
    echo "  g 行号  跳转到指定行"
    echo "  q       退出编辑器（确认未保存更改）"
    echo "  Q       强制退出不保存"
    echo "  h       显示帮助"
    echo "  !命令   执行shell命令"
}

print_line() {
    if (( current_line >= 0 && current_line < ${#file_content[@]} )); then
        echo "$((current_line + 1)): ${file_content[$current_line]}"
    else
        echo "?错误：无效行号"
    fi
}

print_all() {
    for i in "${!file_content[@]}"; do
        echo "$((i + 1)): ${file_content[$i]}"
    done
}

save_file() {
    if [[ -z "$1" && -z "$filename" ]]; then
        echo "?错误：请指定文件名"
        return
    fi
    local save_name="${1:-$filename}"
    printf "%s\n" "${file_content[@]}" > "$save_name"
    echo "文件已保存至: $save_name"
    filename="$save_name"
    modified=false
}

load_file() {
    if [[ -z "$1" ]]; then
        echo "?错误：请指定文件名"
        return
    fi
    if [[ ! -f "$1" ]]; then
        echo "?错误：文件不存在"
        return
    fi
    if $modified; then
        read -p "当前内容未保存，确定加载新文件吗？(y/n) " confirm
        [[ "$confirm" != "y" ]] && return
    fi
    mapfile -t file_content < "$1"
    current_line=0
    echo "已加载文件: $1 (共 ${#file_content[@]} 行)"
    filename="$1"
    modified=false
}

search_text() {
    if [[ -z "$1" ]]; then
        echo "?错误：请输入搜索关键词"
        return
    fi
    search_results=()
    for i in "${!file_content[@]}"; do
        if [[ "${file_content[$i]}" == *"$1"* ]]; then
            search_results+=("$i")
        fi
    done
    if (( ${#search_results[@]} == 0 )); then
        echo "?未找到匹配项"
    else
        search_index=0
        current_line="${search_results[$search_index]}"
        echo "找到 ${#search_results[@]} 处匹配:"
        print_line
    fi
}

next_match() {
    if (( ${#search_results[@]} == 0 )); then
        echo "?错误：请先搜索"
        return
    fi
    ((search_index++))
    if (( search_index >= ${#search_results[@]} )); then
        search_index=0
        echo "?已回到第一个匹配项"
    fi
    current_line="${search_results[$search_index]}"
    print_line
}

insert_mode() {
    local insert_at=$1
    echo "插入模式（输入 '.' 结束）："
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
    echo "追加模式（输入 '.' 结束）："
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
    echo "已删除所有行"
}

execute_shell() {
    eval "$@"
}

confirm_exit() {
    if $modified; then
        read -p "有未保存的更改，确定退出吗？(y/n) " confirm
        [[ "$confirm" != "y" ]] && return 1
    fi
    return 0
}

echo "?BALE 行编辑器 - 输入 'h' 获取帮助"
while true; do
    read -p "? " cmd

    case "$cmd" in
        i) insert_mode $current_line ;;
        I) insert_mode 0 ;;
        a) append_mode $current_line ;;
        A) append_mode $((${#file_content[@]} - 1)) ;;
        p) print_line ;;
        P) print_all ;;
        n) echo "总行数: ${#file_content[@]}" ;;
        d) 
            if (( current_line >= 0 && current_line < ${#file_content[@]} )); then
                file_content=("${file_content[@]:0:$current_line}" "${file_content[@]:$current_line+1}")
                modified=true
                echo "行已删除"
            else
                echo "?错误：无效行号"
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
                echo "?错误：行号超出范围"
            fi
            ;;
        q) 
            if confirm_exit; then 
                echo "退出 BALE。再见！"
                return 0
            fi
            ;;
        Q) echo "强制退出"; return 0;;
        h) show_help ;;
        !*) execute_shell "${cmd#!}" ;;
        [0-9]*) 
            new_line=$((cmd - 1))
            if (( new_line >= 0 && new_line < ${#file_content[@]} )); then
                current_line=$new_line
                print_line
            else
                echo "?错误：行号超出范围"
            fi
            ;;
        *) echo "?错误：未知命令（输入 'h' 查看帮助）" ;;
    esac
done