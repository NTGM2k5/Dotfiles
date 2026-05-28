#!/usr/bin/env zsh

# Đảm bảo terminal không bị khóa dòng ra
stty -ixon

# Đường dẫn file lưu lịch sử
LOG_FILE="$HOME/.pomo_history"

# Màu sắc giao diện (Tone tối giản, tinh tế)
CLR_TITLE="\e[1;36m" # Cyan
CLR_WORK="\e[1;37m"  # Trắng
CLR_BREAK="\e[1;30m" # Xám tối
CLR_RESET="\e[0m"

# Bộ số ASCII lớn chuẩn Zsh
typeset -A num_0 num_1 num_2 num_3 num_4 num_5 num_6 num_7 num_8 num_9 num_colon
num_0=(1 "┌─┐" 2 "│ │" 3 "└─┘")
num_1=(1 "┐  " 2 "│  " 3 "┴  ")
num_2=(1 "┌─┐" 2 "┌─┘" 3 "└──")
num_3=(1 "┌─┐" 2 " ─┤" 3 "└─┘")
num_4=(1 "│ │" 2 "└─┤" 3 "  ┴")
num_5=(1 "┌──" 2 "└─┐" 3 "──┘")
num_6=(1 "┌──" 2 "├─┐" 3 "└─┘")
num_7=(1 "┌─┐" 2 "  │" 3 "  ┴")
num_8=(1 "┌─┐" 2 "├─┤" 3 "└─┘")
num_9=(1 "┌─┐" 2 "└─┤" 3 "──┘")
num_colon=(1 " " 2 "•" 3 "•")

# Hàm phát âm thanh cốt lõi (Sử dụng ffplay)
play_sound() {
    if [ -f "/usr/share/sounds/freedesktop/stereo/complete.oga" ]; then
        ffplay -nodisp -autoexit /usr/share/sounds/freedesktop/stereo/complete.oga >/dev/null 2>&1 &
    else
        (speaker-test -t sine -f 800 -l 1 & WPID=$!; sleep 0.3; kill $WPID) >/dev/null 2>&1
    fi
}

# Hàm bắn thông báo đẩy màn hình (Tự ẩn sau 5 giây trên Dunst)
send_notification() {
    local title="$1"
    local msg="$2"
    local icon="${3:-appointment-soon}"
    if command -v notify-send &>/dev/null; then
        notify-send "$title" "$msg" --icon="$icon" --urgency=normal -t 5000
    fi
}

print_center() {
    local text="$1"
    local width=$(tput cols)
    local clean_text=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local pad=$(( (width - ${#clean_text}) / 2 ))
    if (( pad > 0 )); then
        printf "%${pad}s%b\n" "" "$text"
    else
        printf "%b\n" "$text"
    fi
}

print_large_time() {
    local time_str="$1"
    local color="$2"
    local width=$(tput cols)
    local total_chars_width=23 
    local pad=$(( (width - total_chars_width) / 2 ))
    local indent=""
    (( pad > 0 )) && indent=$(printf "%${pad}s" "")

    for row in 1 2 3; do
        local line_str=""
        for (( i=0; i<${#time_str}; i++ )); do
            local char="${time_str:$i:1}"
            if [[ "$char" == ":" ]]; then
                line_str+="$num_colon[$row]  "
            else
                local -A char_map
                case $char in
                    0) char_map=(${(kv)num_0}) ;;
                    1) char_map=(${(kv)num_1}) ;;
                    2) char_map=(${(kv)num_2}) ;;
                    3) char_map=(${(kv)num_3}) ;;
                    4) char_map=(${(kv)num_4}) ;;
                    5) char_map=(${(kv)num_5}) ;;
                    6) char_map=(${(kv)num_6}) ;;
                    7) char_map=(${(kv)num_7}) ;;
                    8) char_map=(${(kv)num_8}) ;;
                    9) char_map=(${(kv)num_9}) ;;
                esac
                line_str+="$char_map[$row] "
            fi
        done
        printf "%s%b%s%b\n" "$indent" "$color" "$line_str" "$CLR_RESET"
    done
}

render_header() {
    clear
    echo -e "\n\n"
    print_center "${CLR_TITLE}┌────────────────────────────────┐${CLR_RESET}"
    print_center "${CLR_TITLE}│       TERMINAL POMODORO        │${CLR_RESET}"
    print_center "${CLR_TITLE}└────────────────────────────────┘${CLR_RESET}"
    echo -e "\n"
}

prompt_next_stage() {
    local message="$1"
    render_header
    print_center "$message"
    echo ""
    print_center "Bấm [Enter] hoặc [y] để chạy, [Ctrl+B] về menu, phím khác để thoát."
    echo ""
    
    read -k 1 reply
    if [[ "$reply" == $'\x02' ]]; then # Ctrl + B
        return 2 
    elif [[ "$reply" != "y" && "$reply" != "Y" && "$reply" != $'\n' && "$reply" != "" ]]; then
        clear
        echo -e "\n\e[1;31mĐã thoát ứng dụng.\e[0m"
        exit 0
    fi
    return 0
}

countdown() {
    local minutes=$1
    local mode=$2
    local round_info=$3
    
    local total_seconds=$(( minutes * 60 ))
    local elapsed=0
    local is_paused=false
    
    print -f "\e[?25l"
    
    play_sound
    send_notification "Pomodoro" "Bắt đầu chu kỳ: $mode ($round_info)" "appointment-soon"
    
    local color=$CLR_WORK
    [[ "$mode" == *"Giải lao"* || "$mode" == *"Nghỉ"* ]] && color=$CLR_BREAK

    render_header
    print_center "Chế độ: ${color}${mode} (${round_info})${CLR_RESET}"
    echo -e "\n"
    print -f "\e[s" 

    # --- SỬA LỖI: Xóa sạch hàng đợi phím bấm còn sót lại trước khi vào vòng lặp ---
    while read -t 0 -k 1; do done

    while (( elapsed < total_seconds )); do
        local key=""
        # Đọc phím, nếu quá 0.2s không bấm gì thì bỏ qua để tránh nghẽn
        read -t 0.2 -k 1 key
        
        # Nhận diện chính xác phím Enter xuống dòng thực tế từ bàn phím
        if [[ "$key" == $'\n' || "$key" == $'\r' ]]; then 
            if $is_paused; then is_paused=false; else is_paused=true; fi
        elif [[ "$key" == $'\x02' ]]; then # Ctrl + B để thoát về Menu
            print -f "\e[?25h"
            return 2 
        fi

        if $is_paused; then
            print -f "\e[u"
            local remaining=$(( total_seconds - elapsed ))
            print_large_time "$(printf "%02d:%02d" $(( remaining / 60 )) $(( remaining % 60 )))" "\e[1;33m"
            echo -e "\n"
            print_center "\e[1;33m⚡ [ĐANG TẠM DỪNG] ⚡\e[0m"
            echo -e "\n\n"
            print_center "\e[2m[Enter: Tiếp tục | Ctrl+B: Quay về Menu]\e[0m"
            continue
        fi

        local remaining=$(( total_seconds - elapsed ))
        local time_formatted=$(printf "%02d:%02d" $(( remaining / 60 )) $(( remaining % 60 )))
        
        local bar_length=20
        local filled=$(( elapsed * bar_length / total_seconds ))
        local empty=$(( bar_length - filled ))
        local progress_bar=""
        repeat $filled; do progress_bar+="● "; done
        repeat $empty; do progress_bar+="○ "; done
        
        print -f "\e[u"
        print_large_time "$time_formatted" "$color"
        
        echo -e "\n"
        print_center "${progress_bar}"
        echo -e "\n\n"
        print_center "\e[2m[Enter: Tạm dừng | Ctrl+B: Quay về Menu]\e[0m"
        
        # Điều chỉnh lại nhịp sleep bù trừ cho thời gian chờ của lệnh `read`
        sleep 0.8
        (( elapsed++ ))
    done
    
    print -f "\e[?25h"
    play_sound
    send_notification "Pomodoro" "Đã xong chu kỳ: $mode!" "alarm"

    if [[ "$mode" != *"Giải lao"* && "$mode" != *"Nghỉ"* ]]; then
        echo "$(date +'%d/%m/%Y %H:%M') | Chế độ: $mode | Hoàn thành: $round_info ($minutes phút)" >> "$LOG_FILE"
    fi
    return 0
}

countup_free_mode() {
    local elapsed_offset=0
    local is_paused=false

    print -f "\e[?25l"
    play_sound
    send_notification "Pomodoro" "Bắt đầu tính giờ tự do (Đếm xuôi)" "appointment-soon"
    
    render_header
    print_center "Chế độ: \e[1;36mTự do (Đang đếm xuôi)\e[0m"
    echo -e "\n"
    print -f "\e[s"

    # Xóa sạch hàng đợi phím bấm còn sót lại
    while read -t 0 -k 1; do done

    while true; do
        local key=""
        read -t 0.2 -k 1 key
        
        if [[ "$key" == $'\n' || "$key" == $'\r' ]]; then 
            if $is_paused; then is_paused=false; else is_paused=true; fi
        elif [[ "$key" == $'\x02' ]]; then # Ctrl + B
            return 2
        elif [[ "$key" == "y" || "$key" == "Y" ]]; then 
            break
        fi

        if $is_paused; then
            print -f "\e[u"
            print_large_time "$(printf "%02d:%02d" $(( elapsed_offset / 60 )) $(( elapsed_offset % 60 )))" "\e[1;33m"
            echo -e "\n\n"
            print_center "\e[1;33m⚡ [ĐANG TẠM DỪNG] ⚡\e[0m"
            echo ""
            print_center "\e[2m[Enter: Tiếp tục | Phím Y: Lưu kết quả | Ctrl+B: Về Menu]\e[0m"
            continue
        fi

        local time_formatted=$(printf "%02d:%02d" $(( elapsed_offset / 60 )) $(( elapsed_offset % 60 )))
        
        print -f "\e[u"
        print_large_time "$time_formatted" "\e[1;36m"
        
        echo -e "\n\n"
        print_center "\e[1;32mBấm phím [y] để DỪNG và lưu kết quả.\e[0m"
        echo ""
        print_center "\e[2m[Enter: Tạm dừng | Ctrl+B: Quay về Menu]\e[0m"
        
        sleep 0.8
        (( elapsed_offset++ ))
    done
    
    local total_minutes=$(( elapsed_offset / 60 ))
    (( elapsed_offset % 60 >= 30 )) && (( total_minutes++ )) 

    print -f "\e[?25h"
    play_sound
    send_notification "Pomodoro" "Đã dừng đếm giờ tự do. Kết quả đã lưu." "alarm"

    if (( total_minutes > 0 )); then
        echo "$(date +'%d/%m/%Y %H:%M') | Chế độ: Rảnh | Tự do tập trung: $total_minutes phút" >> "$LOG_FILE"
        render_header
        print_center "\e[1;32m✓ Đã lưu lịch sử: Bạn đã tập trung được $total_minutes phút!\e[0m"
        echo -e "\n"
        sleep 2
    else
        render_header
        print_center "\e[1;33mThời gian quá ngắn (chưa đầy 1 phút), không ghi nhận lịch sử.\e[0m"
        echo -e "\n"
        sleep 2
    fi
    return 0
}

show_log() {
    clear
    local today=$(date +'%d/%m/%Y')
    render_header
    print_center "Lịch sử hoạt động hôm nay ($today):"
    echo -e "\n"

    if [ ! -f "$LOG_FILE" ] || ! grep -q "$today" "$LOG_FILE"; then
        print_center "\e[1;30m(Hôm nay bạn chưa ghi nhận hoạt động nào)\e[0m"
    else
        grep "$today" "$LOG_FILE" | while read -r line; do
            local display_line=$(echo "$line" | cut -d' ' -f2-)
            print_center "✓ $display_line"
        done
    fi
    echo -e "\n"
    print_center "Bấm phím bất kỳ để quay lại Menu chính."
    read -k 1
}

# --- MAIN LOOP (QUẢN LÝ MENU CHÍNH) ---
while true; do
    trap 'stty ixon; print -f "\e[?25h"; clear; echo -e "\n\e[1;33mĐã đóng ứng dụng.\e[0m"; exit' INT
    
    render_header
    print_center "Vui lòng chọn chế độ hoạt động:"
    echo ""
    print_center "\e[1;35m1.\e[0m Học tập (Pomodoro 25/5 chuẩn)"
    print_center "\e[1;32m2.\e[0m Làm việc (Hiệu suất cao 45/15)"
    print_center "\e[1;36m3.\e[0m Rảnh rỗi (Tính giờ tự do - Đếm xuôi)"
    print_center "\e[1;30m4.\e[0m Xem lịch sử ngày hôm nay"
    echo ""
    print_center "Nhập lựa chọn của bạn (1-4): "
    printf "%$(( $(tput cols) / 2 ))s" ""
    read -k 1 choice

    case $choice in
        1)
            while true; do
                prompt_next_stage "Sẵn sàng cho HIỆP HỌC 1 (25 phút) chưa?"
                [[ $? -eq 2 ]] && break
                countdown 25 "Học tập" "Hiệp 1/3"; [[ $? -eq 2 ]] && break
                
                prompt_next_stage "Xong Hiệp 1! Vào 5 phút GIẢI LAO ngắn nhé?"
                [[ $? -eq 2 ]] && break
                countdown 5 "Giải lao ngắn" "Hiệp 1/3"; [[ $? -eq 2 ]] && break

                prompt_next_stage "Hết giải lao. Sẵn sàng cho HIỆP HỌC 2 (25 phút) chưa?"
                [[ $? -eq 2 ]] && break
                countdown 25 "Học tập" "Hiệp 2/3"; [[ $? -eq 2 ]] && break
                
                prompt_next_stage "Xong Hiệp 2! Vào 5 phút GIẢI LAO ngắn tiếp theo?"
                [[ $? -eq 2 ]] && break
                countdown 5 "Giải lao ngắn" "Hiệp 2/3"; [[ $? -eq 2 ]] && break

                prompt_next_stage "Hết giải lao. Sẵn sàng cho HIỆP HỌC 3 (25 phút) chưa?"
                [[ $? -eq 2 ]] && break
                countdown 25 "Học tập" "Hiệp 3/3"; [[ $? -eq 2 ]] && break
                
                prompt_next_stage "Tuyệt vời! Bạn đã hoàn thành 3 hiệp học. Vào 15 phút NGHỈ DÀI nhé?"
                [[ $? -eq 2 ]] && break
                countdown 15 "Nghỉ dài" "Kết thúc vòng"; [[ $? -eq 2 ]] && break
            done
            ;;
        2)
            while true; do
                prompt_next_stage "Sẵn sàng vào HIỆP LÀM VIỆC (45 phút) chưa?"
                [[ $? -eq 2 ]] && break
                countdown 45 "Làm việc" "Hiệp tập trung"; [[ $? -eq 2 ]] && break
                
                prompt_next_stage "Tuyệt vời! Hết giờ, hãy tận hưởng 15 phút GIẢI LAO."
                [[ $? -eq 2 ]] && break
                countdown 15 "Giải lao" "Hiệp nghỉ ngơi"; [[ $? -eq 2 ]] && break
            done
            ;;
        3)
            prompt_next_stage "Bắt đầu tính giờ tự do. Chúc bạn tập trung vui vẻ!"
            [[ $? -ne 2 ]] && countup_free_mode
            ;;
        4)
            show_log
            ;;
        *)
            clear
            echo -e "\n\e[1;31mLựa chọn không hợp lệ.\e[0m"
            sleep 1
            ;;
    esac
done
