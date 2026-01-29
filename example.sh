#!/usr/bin/env bash
# example.sh — Demo of blaeck.sh capabilities
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/blaeck.sh"
trap bk_cleanup EXIT

clear

# ── Header ──────────────────────────────────────────────────────────
printf '\n'
bk_gradient "  blaeck.sh" 207 39
printf '  '
bk_dim "terminal ui primitives for bash"
printf '\n'
bk_hr '─' 50 gray
printf '\n'

sleep 0.6

# ── Status lines ────────────────────────────────────────────────────
printf '%s  System Check%s\n\n' "$_BK_BOLD" "$_BK_RESET"

checks=(
  "bash version:$(bash --version | head -1 | sed 's/.*version //' | cut -d' ' -f1)"
  "terminal:$TERM"
  "colors:$(tput colors 2>/dev/null || echo '?')"
  "unicode:supported"
  "size:$(tput cols)x$(tput lines)"
)

for entry in "${checks[@]}"; do
  label="${entry%%:*}"
  value="${entry#*:}"
  bk_status ok "$label" "$value" 16
  sleep 0.15
done

printf '\n'
sleep 0.4

# ── Spinner demo ────────────────────────────────────────────────────
printf '%s  Spinners%s\n\n' "$_BK_BOLD" "$_BK_RESET"

spinner_styles=(dots circle arc arrow box simple)
for style in "${spinner_styles[@]}"; do
  bk_spinner --style "$style" --color cyan "  $style" sleep 0.8
  bk_ok "  $style"
done

printf '\n'
sleep 0.3

# ── Progress bars ───────────────────────────────────────────────────
printf '%s  Progress Styles%s\n\n' "$_BK_BOLD" "$_BK_RESET"

styles=(block ascii thin dots braille)
pcolors=(green cyan blue magenta yellow)

for i in "${!styles[@]}"; do
  printf '  %-8s ' "${styles[$i]}"
  bk_progress --style "${styles[$i]}" --width 30 --color "${pcolors[$i]}" --show-percent 73
  printf '\n'
  sleep 0.2
done

printf '\n'

# ── Animated progress ──────────────────────────────────────────────
printf '%s  Live Progress%s\n\n' "$_BK_BOLD" "$_BK_RESET"
printf '  '
bk_progress_run --style block --color green --label "" --width 40 sleep 2
printf '\n'

# ── Table ───────────────────────────────────────────────────────────
printf '%s  Table%s\n\n' "$_BK_BOLD" "$_BK_RESET"

bk_table --header --border round --color gray \
  "Component,Status,Style" \
  "Spinner,$(bk_green '✓ ready'),6 styles" \
  "Progress,$(bk_green '✓ ready'),5 styles" \
  "Box,$(bk_green '✓ ready'),5 borders" \
  "Table,$(bk_green '✓ ready'),bordered" \
  "Select,$(bk_green '✓ ready'),4 indicators" \
  "Confirm,$(bk_green '✓ ready'),inline" \
  "Gradient,$(bk_green '✓ ready'),256-color" \
  "Render,$(bk_green '✓ ready'),log-update"

printf '\n'
sleep 0.3

# ── Boxes ───────────────────────────────────────────────────────────
printf '%s  Box Styles%s\n\n' "$_BK_BOLD" "$_BK_RESET"

bk_box --style round --color cyan --title "round" \
  "The default box style." \
  "Rounded corners look clean."

printf '\n'

bk_box --style bold --color magenta --title "bold" \
  "Heavy borders for emphasis." \
  "Use for important messages."

printf '\n'

bk_box --style double --color yellow --title "double" \
  "Classic double-line border." \
  "Feels very terminal."

printf '\n'
sleep 0.3

# ── Inline re-rendering demo ───────────────────────────────────────
printf '%s  Inline Re-rendering%s\n\n' "$_BK_BOLD" "$_BK_RESET"

steps=("Connecting..." "Authenticating..." "Fetching data..." "Processing..." "Done!")
icons=("○" "○" "○" "○" "○")
icon_colors=("$_BK_GRAY" "$_BK_GRAY" "$_BK_GRAY" "$_BK_GRAY" "$_BK_GRAY")
sframes=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)

bk_render_init 5

for (( step=0; step<5; step++ )); do
  # Mark previous as done
  if (( step > 0 )); then
    icons[$((step-1))]="✓"
    icon_colors[$((step-1))]="$_BK_GREEN"
  fi

  # Animate current step
  for (( f=0; f<12; f++ )); do
    cur_icon="${sframes[$((f % 10))]}"
    cur_color="$_BK_CYAN"

    render_lines=()
    for (( s=0; s<5; s++ )); do
      if (( s == step )); then
        render_lines+=("  ${cur_color}${cur_icon}${_BK_RESET} ${steps[$s]}")
      else
        render_lines+=("  ${icon_colors[$s]}${icons[$s]}${_BK_RESET} ${steps[$s]}")
      fi
    done

    bk_render "${render_lines[@]}"
    sleep 0.07
  done
done

# Final state — all done
icons[4]="✓"
icon_colors[4]="$_BK_GREEN"
final_lines=()
for (( s=0; s<5; s++ )); do
  final_lines+=("  ${icon_colors[$s]}${icons[$s]}${_BK_RESET} ${steps[$s]}")
done
bk_render "${final_lines[@]}"
bk_render_done

printf '\n'

# ── Final box ───────────────────────────────────────────────────────
bk_box --style round --color green \
  "$(bk_green '✓') $(bk_bold 'blaeck.sh') — all features working" \
  "" \
  "  source blaeck.sh" \
  "  bk_spinner \"Loading...\" my_command" \
  "  bk_box --style round \"Hello world\""

printf '\n'
