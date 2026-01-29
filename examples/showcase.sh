#!/usr/bin/env bash
# showcase.sh — Non-interactive visual showcase of all blaeck.sh components
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/blaeck.sh"
trap bk_cleanup EXIT

clear

# ── Header ──────────────────────────────────────────────────────────
printf '\n'
bk_gradient "  ██████╗ ██╗      █████╗ ███████╗ ██████╗██╗  ██╗" 207 39; printf '\n'
bk_gradient "  ██╔══██╗██║     ██╔══██╗██╔════╝██╔════╝██║ ██╔╝" 207 39; printf '\n'
bk_gradient "  ██████╔╝██║     ███████║█████╗  ██║     █████╔╝ " 207 39; printf '\n'
bk_gradient "  ██╔══██╗██║     ██╔══██║██╔══╝  ██║     ██╔═██╗ " 207 39; printf '\n'
bk_gradient "  ██████╔╝███████╗██║  ██║███████╗╚██████╗██║  ██╗" 207 39; printf '\n'
bk_gradient "  ╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝" 207 39; printf '\n'
printf '\n'
bk_banner "terminal ui primitives for bash" gray 58
printf '\n'

sleep 0.8

# ── Text styling ────────────────────────────────────────────────────
printf '%s  Text Styling%s\n\n' "$_BK_BOLD" "$_BK_RESET"

bk_columns --widths "22,22" --gap 4 \
  "  $(bk_bold 'bold text')
  $(bk_dim 'dim text')
  $(bk_italic 'italic text')
  $(bk_style --underline 'underline')
  $(bk_style --strikethrough 'strikethrough')" \
  "  $(bk_red 'red') $(bk_green 'green') $(bk_yellow 'yellow')
  $(bk_blue 'blue') $(bk_magenta 'magenta') $(bk_cyan 'cyan')
  $(bk_style --bold --color cyan 'bold cyan')
  $(bk_style --italic --color magenta 'italic mag')
  $(bk_gradient 'gradient text!' 196 21)"

printf '\n'
sleep 0.3

# ── Status lines ────────────────────────────────────────────────────
printf '%s  Status Lines%s\n\n' "$_BK_BOLD" "$_BK_RESET"

bk_columns --widths "26,26" --gap 4 \
  "$(bk_status ok 'Compiled' 'main.rs' 12)
$(bk_status ok 'Tests' '42 passed' 12)
$(bk_status warn 'Warnings' '3 found' 12)
$(bk_status fail 'Linting' '1 error' 12)" \
  "$(bk_status ok 'Platform' 'macOS arm64' 12)
$(bk_status ok 'Rust' '1.82.0' 12)
$(bk_status ok 'Node' '22.1.0' 12)
$(bk_status info 'Python' 'not found' 12)"

printf '\n'
sleep 0.3

# ── Box styles ──────────────────────────────────────────────────────
printf '%s  Box Styles%s\n\n' "$_BK_BOLD" "$_BK_RESET"

bk_columns --widths "26,26" --gap 4 \
  "$(bk_box --style round --color cyan --title 'round' \
    'Rounded corners.' \
    'Default style.')
$(bk_box --style single --color blue --title 'single' \
    'Sharp corners.' \
    'Classic look.')" \
  "$(bk_box --style bold --color magenta --title 'bold' \
    'Heavy borders.' \
    'For emphasis.')
$(bk_box --style double --color yellow --title 'double' \
    'Mixed weight.' \
    'Thick + thin.')"

printf '\n'
sleep 0.3

# ── Spinners ────────────────────────────────────────────────────────
printf '%s  Spinners%s\n\n' "$_BK_BOLD" "$_BK_RESET"

spinner_styles=(dots circle arc arrow box simple)
for style in "${spinner_styles[@]}"; do
  bk_spinner --style "$style" --color cyan "  $style" sleep 0.7
  bk_ok "  $style"
done

printf '\n'
sleep 0.3

# ── Progress bars ───────────────────────────────────────────────────
printf '%s  Progress Bars%s\n\n' "$_BK_BOLD" "$_BK_RESET"

styles=(block ascii thin dots braille)
pcolors=(green cyan blue magenta yellow)

for i in "${!styles[@]}"; do
  printf '  %-8s ' "${styles[$i]}"
  bk_progress --style "${styles[$i]}" --width 30 --color "${pcolors[$i]}" --show-percent 73
  printf '\n'
  sleep 0.15
done

printf '\n'

# Animated progress
printf '  '
bk_progress_run --style block --color green --label "  compiling" --width 35 sleep 1.5
printf '\n'
sleep 0.3

# ── Table ───────────────────────────────────────────────────────────
printf '%s  Tables%s\n\n' "$_BK_BOLD" "$_BK_RESET"

bk_table --header --border round --color gray --striped \
  "Package,Version,Size,Status" \
  "blaeck,0.2.0,142 KB,$(bk_green 'installed')" \
  "taffy,0.5.2,89 KB,$(bk_green 'installed')" \
  "crossterm,0.28.1,201 KB,$(bk_green 'installed')" \
  "serde,1.0.210,56 KB,$(bk_yellow 'updating')" \
  "tokio,1.40.0,1.2 MB,$(bk_gray 'optional')"

printf '\n'
sleep 0.3

# ── Inline re-rendering ────────────────────────────────────────────
printf '%s  Inline Re-rendering%s\n\n' "$_BK_BOLD" "$_BK_RESET"

deploy_steps=("Pulling changes" "Building" "Running tests" "Deploying" "Verifying")
icons=("○" "○" "○" "○" "○")
icon_colors=("$_BK_GRAY" "$_BK_GRAY" "$_BK_GRAY" "$_BK_GRAY" "$_BK_GRAY")
sframes=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)

bk_render_init 5

for (( step=0; step<5; step++ )); do
  if (( step > 0 )); then
    icons[$((step-1))]="✓"
    icon_colors[$((step-1))]="$_BK_GREEN"
  fi

  for (( f=0; f<10; f++ )); do
    cur_icon="${sframes[$((f % 10))]}"
    render_lines=()
    for (( s=0; s<5; s++ )); do
      if (( s == step )); then
        render_lines+=("  ${_BK_CYAN}${cur_icon}${_BK_RESET} ${deploy_steps[$s]}")
      else
        render_lines+=("  ${icon_colors[$s]}${icons[$s]}${_BK_RESET} ${deploy_steps[$s]}")
      fi
    done
    bk_render "${render_lines[@]}"
    sleep 0.05
  done
done

icons[4]="✓"
icon_colors[4]="$_BK_GREEN"
final_lines=()
for (( s=0; s<5; s++ )); do
  final_lines+=("  ${icon_colors[$s]}${icons[$s]}${_BK_RESET} ${deploy_steps[$s]}")
done
bk_render "${final_lines[@]}"
bk_render_done

printf '\n'

# ── Flexbox columns ────────────────────────────────────────────────
printf '%s  Flexbox Columns%s\n\n' "$_BK_BOLD" "$_BK_RESET"

bk_columns --widths "18,18,18" --gap 2 \
  "$(bk_box --style round --color cyan --width 16 \
    "$(bk_cyan '  142') files" \
    "$(bk_gray '  src/')")
  $(bk_gray '  TypeScript')" \
  "$(bk_box --style round --color green --width 16 \
    "$(bk_green '   98') tests" \
    "$(bk_gray '  all pass')")
  $(bk_gray '  Coverage 94%')" \
  "$(bk_box --style round --color magenta --width 16 \
    "$(bk_magenta '  0.8s') build" \
    "$(bk_gray '  release')")
  $(bk_gray '  Optimized')"

printf '\n'

# ── Dashboard layout ───────────────────────────────────────────────
printf '%s  Dashboard%s\n\n' "$_BK_BOLD" "$_BK_RESET"

bk_columns --widths "28,28" --gap 2 \
  "$(bk_box --style round --color gray --title 'CPU' --width 26 \
    "  $(bk_progress --style block --width 16 --color green 34) 34%" \
    "  $(bk_dim 'Load: 1.2 1.5 1.1')")" \
  "$(bk_box --style round --color gray --title 'Memory' --width 26 \
    "  $(bk_progress --style block --width 16 --color yellow 67) 67%" \
    "  $(bk_dim '10.7 / 16 GB')")"

printf '\n'

bk_columns --widths "28,28" --gap 2 \
  "$(bk_box --style round --color gray --title 'Disk' --width 26 \
    "  $(bk_progress --style block --width 16 --color cyan 42) 42%" \
    "  $(bk_dim '201 / 500 GB')")" \
  "$(bk_box --style round --color gray --title 'Network' --width 26 \
    "  $(bk_green '↑') 2.4 MB/s" \
    "  $(bk_cyan '↓') 14.8 MB/s")"

printf '\n'

# ── Final ───────────────────────────────────────────────────────────
bk_box --style round --color green \
  "$(bk_green '✓') $(bk_bold 'blaeck.sh') — $(bk_dim 'source it and go')" \
  "" \
  "  source <(curl -fsSL .../blaeck.sh)" \
  "" \
  "  $(bk_gray 'Zero dependencies. Pure bash. Works everywhere.')"

printf '\n'
