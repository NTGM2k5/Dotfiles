
# 🌸 NTGM "arch" Rice

![preview](preview.png)

My personal dotfiles for CachyOS + Kitty + Zsh.

## 📦 Contents

| File/Folder | Description |
|---|---|
| `fastfetch/` | Fastfetch config with NTGM ascii art |
| `kitty.conf` | Kitty terminal config |
| `pomo/pomodoro-terminal.sh` | Terminal Pomodoro timer (Zsh) |

---

## 🍅 Pomodoro Terminal

A minimal Pomodoro timer running in Kitty terminal.

### Dependencies

```bash
sudo pacman -S ffmpeg libnotify dunst
```

### Install (one-liner)

```bash
curl -fsSL https://raw.githubusercontent.com/NTGM2k5/Dotfiles/main/pomo/pomodoro-terminal.sh \
  -o ~/.local/bin/pomodoro-terminal && chmod +x ~/.local/bin/pomodoro-terminal
```

### Run

```bash
pomodoro-terminal
# hoặc thêm alias vào .zshrc:
echo 'alias pomo="pomodoro-terminal"' >> ~/.zshrc
```

### Modes

| Key | Mode |
|---|---|
| `1` | Study — 25 min / 5 min break × 3 + 15 min long break |
| `2` | Work — 45 min / 15 min break |
| `3` | Free timer (count-up) |
| `4` | View today's history |

### Controls

| Key | Action |
|---|---|
| `Enter` | Pause / Resume |
| `Ctrl+B` | Back to menu |
| `Ctrl+C` | Quit app entirely |
