#!/bin/bash

# 初始化变量
file_content=()
current_line=0
filename=""
search_results=()
search_index=0

# 显示帮助
show_help() {
    echo "?BAFE 帮助："
    echo "  i       进入插入模式（输入 '.' 结束）"
    echo "  p       打印当前行"
    echo "  a       在末尾追加文本"
    echo "  d       删除当前行"
    echo "  w 文件名 保存文件"
    echo "  l 文件名 加载文件"
    echo "  /关键词  搜索内容"
    echo "  n       跳转到下一个匹配项"
    echo "  q       退出编辑器"
    echo "  h       显示帮助"
    echo "  数字    跳转到指定行（如 '3'）"
}

# 打印当前行（带行号）
print_line() {
    if (( current_line >= 0 && current_line < ${#file_content[@]} )); then
        echo "$((current_line + 1)): ${file_content[$current_line]}"
    else
        echo "?错误：无效行号"
    fi
}

# 保存文件
save_file() {
    if [[ -z "$1" ]]; then
        echo "?错误：请指定文件名（如 'w 文件名'）"
        return
    fi
    printf "%s\n" "${file_content[@]}" > "$1"
    echo "文件已保存至: $1"
    filename="$1"
}

# 加载文件
load_file() {
    if [[ -z "$1" ]]; then
        echo "?错误：请指定文件名（如 'l 文件名'）"
        return
    fi
    if [[ ! -f "$1" ]]; then
        echo "?错误：文件不存在"
        return
    fi
    mapfile -t file_content < "$1"
    current_line=0
    echo "已加载文件: $1 (共 ${#file_content[@]} 行)"
    filename="$1"
}

# 搜索内容
search_text() {
    if [[ -z "$1" ]]; then
        echo "?错误：请输入搜索关键词（如 '/hello'）"
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

# 跳转到下一个匹配项
next_match() {
    if (( ${#search_results[@]} == 0 )); then
        echo "?错误：请先使用 '/关键词' 搜索"
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

# 主循环
echo "?BAFE 简易行编辑器 - 输入 'h' 获取帮助"
while true; do
    read -p "? " cmd

    case "$cmd" in
        i)  # 插入模式
            echo "插入模式（输入 '.' 结束）："
            while true; do
                read -r input
                if [[ "$input" == "." ]]; then
                    break
                fi
                file_content=("${file_content[@]:0:$current_line}" "$input" "${file_content[@]:$current_line}")
                ((current_line++))
            done
            ;;
        p)  # 打印当前行
            print_line
            ;;
        a)  # 追加行
            echo "追加文本（输入 '.' 结束）："
            while true; do
                read -r input
                if [[ "$input" == "." ]]; then
                    break
                fi
                file_content+=("$input")
                current_line=${#file_content[@]}
            done
            ;;
        d)  # 删除当前行
            if (( current_line >= 0 && current_line < ${#file_content[@]} )); then
                file_content=("${file_content[@]:0:$current_line}" "${file_content[@]:$current_line+1}")
                echo "行已删除。"
            else
                echo "?错误：无效行号"
            fi
            ;;
        w*) # 保存文件
            save_file "${cmd#w }"
            ;;
        l*) # 加载文件
            load_file "${cmd#l }"
            ;;
        /*) # 搜索内容
            search_text "${cmd#/}"
            ;;
        n)  # 下一个匹配项
            next_match
            ;;
        q)  # 退出
            echo "退出 BAFE。再见！"
            ;;
        h)  # 帮助
            show_help
            ;;
        [0-9]*) # 跳转到指定行
            new_line=$((cmd - 1))
            if (( new_line >= 0 && new_line < ${#file_content[@]} )); then
                current_line="$new_line"
                print_line
            else
                echo "?错误：行号超出范围"
            fi
            ;;
        *)  # 未知命令
            echo "?错误：未知命令（输入 'h' 查看帮助）"
            ;;
    esac
done
