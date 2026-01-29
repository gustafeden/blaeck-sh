#!/usr/bin/env bash
# interactive.sh — Full interactive demo: menus, inputs, passwords, layouts
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)"
if [[ -f "$SCRIPT_DIR/blaeck.sh" ]]; then
  source "$SCRIPT_DIR/blaeck.sh"
else
  eval "$(curl -fsSL https://gustafeden.github.io/blaeck-sh/blaeck.sh)"
fi
trap bk_cleanup EXIT

clear

# ── Welcome screen ──────────────────────────────────────────────────
printf '\n'
bk_banner "blaeck.sh interactive demo" cyan 56
printf '\n'

bk_columns --widths "28,28" --gap 2 \
  "$(bk_gray '  Components')
  $(bk_cyan '❯') Text input
  $(bk_cyan '❯') Password input
  $(bk_cyan '❯') Select menu
  $(bk_cyan '❯') Multi-select
  $(bk_cyan '❯') Confirm prompt
  $(bk_cyan '❯') Flexbox layout" \
  "$(bk_gray '  Features')
  $(bk_green '✓') Inline re-render
  $(bk_green '✓') Cursor management
  $(bk_green '✓') ANSI colors
  $(bk_green '✓') Box drawing
  $(bk_green '✓') Tables
  $(bk_green '✓') Spinners"

printf '\n'
bk_hr '─' 58 gray
printf '\n'

sleep 0.5

# ── 1. Sign-in form ────────────────────────────────────────────────
printf '%s  1. Sign In%s\n\n' "$_BK_BOLD" "$_BK_RESET"

bk_box --style round --color gray --width 44 \
  "Enter your credentials below." \
  "$(bk_gray '(this is a demo — nothing is sent)')"

printf '\n'

printf '  '
bk_input --color cyan --label "  Username:" --placeholder "you@example.com"
username="$BK_INPUT_VALUE"

printf '  '
bk_password --color cyan --label "  Password:" --mask "●"
password="$BK_INPUT_VALUE"

printf '\n'

if [[ -n "$username" && -n "$password" ]]; then
  bk_spinner --style dots --color green "  Authenticating..." sleep 1.2
  bk_ok "  Signed in as $(bk_cyan "$username")"
else
  bk_warn "  Skipped sign-in (empty fields)"
fi

printf '\n'
sleep 0.3

# ── 2. Select menu ─────────────────────────────────────────────────
printf '%s  2. Select a Theme%s\n\n' "$_BK_BOLD" "$_BK_RESET"

bk_select --color cyan --indicator arrow --label "  Choose your color theme:" \
  "Nord" \
  "Dracula" \
  "Solarized" \
  "Gruvbox" \
  "Catppuccin"

theme="$BK_SELECTED_VALUE"
printf '\n'
bk_ok "  Theme set to $(bk_cyan "$theme")"
printf '\n'

sleep 0.3

# ── 3. Multi-select ────────────────────────────────────────────────
printf '%s  3. Install Plugins%s\n\n' "$_BK_BOLD" "$_BK_RESET"

bk_multiselect --color cyan --label "  Select plugins to install:" \
  "syntax-highlighting" \
  "auto-complete" \
  "git-integration" \
  "file-manager" \
  "status-line"

printf '\n'

if [[ -n "$BK_MULTI_SELECTED_VALUES" ]]; then
  while IFS= read -r plugin; do
    bk_spinner --style dots --color cyan "  Installing $plugin..." sleep 0.6
    bk_ok "  Installed $(bk_cyan "$plugin")"
  done <<< "$BK_MULTI_SELECTED_VALUES"
else
  bk_info "  No plugins selected"
fi

printf '\n'
sleep 0.3

# ── 4. Confirm ──────────────────────────────────────────────────────
printf '%s  4. Confirm Setup%s\n\n' "$_BK_BOLD" "$_BK_RESET"

printf '  '
bk_confirm --color cyan "  Enable experimental features?"
if [[ "$BK_CONFIRMED" == "yes" ]]; then
  bk_ok "  Experimental features enabled"
else
  bk_info "  Using stable features only"
fi

printf '\n'
sleep 0.3

# ── 5. Flexbox layout: summary dashboard ───────────────────────────
printf '%s  5. Configuration Summary%s\n\n' "$_BK_BOLD" "$_BK_RESET"

# Build plugin list for display
plugin_display=""
if [[ -n "$BK_MULTI_SELECTED_VALUES" ]]; then
  while IFS= read -r p; do
    plugin_display+="    $(bk_green '✓') $p"$'\n'
  done <<< "$BK_MULTI_SELECTED_VALUES"
else
  plugin_display="    $(bk_gray 'none')"$'\n'
fi
plugin_display="${plugin_display%$'\n'}"

exp_status="$(bk_red 'off')"
[[ "$BK_CONFIRMED" == "yes" ]] && exp_status="$(bk_green 'on')"

# Two-column layout
bk_columns --widths "26,26" --gap 4 \
  "$(bk_bold '  Account')
  $(bk_gray '  ────────────────────')
  $(bk_status ok 'User' "$username" 8 | bk_indent 2)
  $(bk_status ok 'Auth' 'password' 8 | bk_indent 2)" \
  "$(bk_bold '  Preferences')
  $(bk_gray '  ────────────────────')
  $(bk_status ok 'Theme' "$theme" 8 | bk_indent 2)
  $(bk_status ok 'Exper.' "$exp_status" 8 | bk_indent 2)"

printf '\n'
printf '  %s  Plugins%s\n' "$_BK_BOLD" "$_BK_RESET"
printf '  %s\n' "$(bk_gray '  ────────────────────')"
printf '%s\n' "$plugin_display"

printf '\n'

# ── 6. Progress: "applying" configuration ──────────────────────────
printf '%s  6. Applying Configuration%s\n\n' "$_BK_BOLD" "$_BK_RESET"

apply_steps=("Writing config" "Setting theme" "Loading plugins" "Verifying" "Done")
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
        render_lines+=("  ${_BK_CYAN}${cur_icon}${_BK_RESET} ${apply_steps[$s]}")
      else
        render_lines+=("  ${icon_colors[$s]}${icons[$s]}${_BK_RESET} ${apply_steps[$s]}")
      fi
    done
    bk_render "${render_lines[@]}"
    sleep 0.06
  done
done

icons[4]="✓"
icon_colors[4]="$_BK_GREEN"
final_lines=()
for (( s=0; s<5; s++ )); do
  final_lines+=("  ${icon_colors[$s]}${icons[$s]}${_BK_RESET} ${apply_steps[$s]}")
done
bk_render "${final_lines[@]}"
bk_render_done

printf '\n'

# ── Final result ────────────────────────────────────────────────────
bk_box --style round --color green \
  "$(bk_green '✓') $(bk_bold 'Setup complete!')" \
  "" \
  "  user:   $username" \
  "  theme:  $theme" \
  "  config: ~/.config/app/config.toml"

printf '\n'
