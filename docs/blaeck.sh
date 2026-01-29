#!/usr/bin/env bash
# blaeck.sh — Terminal UI primitives for bash scripts
# Source this file: source blaeck.sh
# Requires: bash 4+, tput

# ---------------------------------------------------------------------------
# Guard
# ---------------------------------------------------------------------------
[[ -n "$_BLAECK_SH_LOADED" ]] && return 0
_BLAECK_SH_LOADED=1

# ---------------------------------------------------------------------------
# Terminal capabilities
# ---------------------------------------------------------------------------
_bk_cols() { tput cols 2>/dev/null || echo 80; }
_bk_has_color() { [[ -t 1 ]] && [[ "$(tput colors 2>/dev/null)" -ge 8 ]]; }

# ---------------------------------------------------------------------------
# ANSI codes
# ---------------------------------------------------------------------------
if _bk_has_color; then
  _BK_RESET=$'\033[0m'
  _BK_BOLD=$'\033[1m'
  _BK_DIM=$'\033[2m'
  _BK_ITALIC=$'\033[3m'
  _BK_UNDERLINE=$'\033[4m'
  _BK_INVERSE=$'\033[7m'
  _BK_STRIKETHROUGH=$'\033[9m'
  _BK_RED=$'\033[31m'
  _BK_GREEN=$'\033[32m'
  _BK_YELLOW=$'\033[33m'
  _BK_BLUE=$'\033[34m'
  _BK_MAGENTA=$'\033[35m'
  _BK_CYAN=$'\033[36m'
  _BK_WHITE=$'\033[37m'
  _BK_GRAY=$'\033[90m'
  _BK_BG_RED=$'\033[41m'
  _BK_BG_GREEN=$'\033[42m'
  _BK_BG_YELLOW=$'\033[43m'
  _BK_BG_BLUE=$'\033[44m'
  _BK_BG_MAGENTA=$'\033[45m'
  _BK_BG_CYAN=$'\033[46m'
  _BK_BG_WHITE=$'\033[47m'
else
  _BK_RESET='' _BK_BOLD='' _BK_DIM='' _BK_ITALIC='' _BK_UNDERLINE=''
  _BK_INVERSE='' _BK_STRIKETHROUGH=''
  _BK_RED='' _BK_GREEN='' _BK_YELLOW='' _BK_BLUE='' _BK_MAGENTA=''
  _BK_CYAN='' _BK_WHITE='' _BK_GRAY=''
  _BK_BG_RED='' _BK_BG_GREEN='' _BK_BG_YELLOW='' _BK_BG_BLUE=''
  _BK_BG_MAGENTA='' _BK_BG_CYAN='' _BK_BG_WHITE=''
fi

# Color lookup
_bk_color() {
  case "$1" in
    red)     echo "$_BK_RED";;
    green)   echo "$_BK_GREEN";;
    yellow)  echo "$_BK_YELLOW";;
    blue)    echo "$_BK_BLUE";;
    magenta) echo "$_BK_MAGENTA";;
    cyan)    echo "$_BK_CYAN";;
    white)   echo "$_BK_WHITE";;
    gray)    echo "$_BK_GRAY";;
    *)       echo "";;
  esac
}

# ---------------------------------------------------------------------------
# ANSI stripping (BSD sed on macOS doesn't understand \x1b)
# ---------------------------------------------------------------------------
_bk_strip_ansi() {
  printf '%s' "$1" | sed $'s/\033\\[[0-9;]*m//g'
}

# ---------------------------------------------------------------------------
# Cursor / line management
# ---------------------------------------------------------------------------
_bk_hide_cursor() { printf '\033[?25l'; }
_bk_show_cursor() { printf '\033[?25h'; }
_bk_cursor_up()   { printf '\033[%dA' "$1"; }
_bk_erase_line()  { printf '\033[2K\r'; }
_bk_save_cursor() { printf '\033[s'; }
_bk_restore_cursor() { printf '\033[u'; }

# Erase N lines above cursor and move cursor back up
_bk_erase_lines() {
  local n=$1
  for (( i=0; i<n; i++ )); do
    _bk_erase_line
    [[ $i -lt $((n-1)) ]] && _bk_cursor_up 1
  done || true
}

# ---------------------------------------------------------------------------
# Text styling helpers
# ---------------------------------------------------------------------------
bk_style() {
  local text="" color="" bg="" mods=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --bold)          mods+="$_BK_BOLD"; shift;;
      --dim)           mods+="$_BK_DIM"; shift;;
      --italic)        mods+="$_BK_ITALIC"; shift;;
      --underline)     mods+="$_BK_UNDERLINE"; shift;;
      --inverse)       mods+="$_BK_INVERSE"; shift;;
      --strikethrough) mods+="$_BK_STRIKETHROUGH"; shift;;
      --color)         color=$(_bk_color "$2"); shift 2;;
      --bg)            bg=$(_bk_color "$2" | sed 's/\[3/[4/'); shift 2;;
      *)               text="$1"; shift;;
    esac
  done
  printf '%s%s%s%s%s' "$mods" "$color" "$bg" "$text" "$_BK_RESET"
}

# Convenience wrappers
bk_bold()    { printf '%s%s%s' "$_BK_BOLD" "$*" "$_BK_RESET"; }
bk_dim()     { printf '%s%s%s' "$_BK_DIM" "$*" "$_BK_RESET"; }
bk_italic()  { printf '%s%s%s' "$_BK_ITALIC" "$*" "$_BK_RESET"; }

bk_red()     { printf '%s%s%s' "$_BK_RED" "$*" "$_BK_RESET"; }
bk_green()   { printf '%s%s%s' "$_BK_GREEN" "$*" "$_BK_RESET"; }
bk_yellow()  { printf '%s%s%s' "$_BK_YELLOW" "$*" "$_BK_RESET"; }
bk_blue()    { printf '%s%s%s' "$_BK_BLUE" "$*" "$_BK_RESET"; }
bk_magenta() { printf '%s%s%s' "$_BK_MAGENTA" "$*" "$_BK_RESET"; }
bk_cyan()    { printf '%s%s%s' "$_BK_CYAN" "$*" "$_BK_RESET"; }
bk_gray()    { printf '%s%s%s' "$_BK_GRAY" "$*" "$_BK_RESET"; }

# ---------------------------------------------------------------------------
# Horizontal rule
# ---------------------------------------------------------------------------
bk_hr() {
  local char="${1:-─}" width="${2:-$(_bk_cols)}" color="${3:-gray}"
  local c; c=$(_bk_color "$color")
  local line=""
  for (( i=0; i<width; i++ )); do line+="$char"; done || true
  printf '%s%s%s\n' "$c" "$line" "$_BK_RESET"
}

# ---------------------------------------------------------------------------
# Box drawing
# ---------------------------------------------------------------------------
# Usage: bk_box [--style round|single|double|bold|classic] [--color COLOR]
#              [--padding N] [--width N] [--title "TITLE"] "content line" ...
bk_box() {
  local style="round" color="white" padding=1 width=0 title=""
  local -a lines=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --style)   style="$2"; shift 2;;
      --color)   color="$2"; shift 2;;
      --padding) padding="$2"; shift 2;;
      --width)   width="$2"; shift 2;;
      --title)   title="$2"; shift 2;;
      *)         lines+=("$1"); shift;;
    esac
  done

  # Border characters
  local tl tr bl br h v
  case "$style" in
    single)  tl='┌' tr='┐' bl='└' br='┘' h='─' v='│';;
    double)  tl='┍' tr='┑' bl='┕' br='┙' h='━' v='│';;
    round)   tl='╭' tr='╮' bl='╰' br='╯' h='─' v='│';;
    bold)    tl='┏' tr='┓' bl='┗' br='┛' h='━' v='┃';;
    classic) tl='+' tr='+' bl='+' br='+' h='-' v='|';;
  esac

  # Calculate width from content if not specified
  if [[ $width -eq 0 ]]; then
    local max_len=0
    for line in "${lines[@]}"; do
      local stripped
      stripped=$(_bk_strip_ansi "$line")
      local len=${#stripped}
      [[ $len -gt $max_len ]] && max_len=$len
    done
    if [[ -n "$title" ]]; then
      local title_len=${#title}
      [[ $((title_len + 2)) -gt $max_len ]] && max_len=$((title_len + 2))
    fi
    width=$((max_len + padding * 2))
  fi

  local c; c=$(_bk_color "$color")
  local pad=""
  for (( i=0; i<padding; i++ )); do pad+=" "; done || true

  # Top border
  local hline=""
  for (( i=0; i<width; i++ )); do hline+="$h"; done || true

  if [[ -n "$title" ]]; then
    local before_len=$(( (width - ${#title} - 2) / 2 ))
    local after_len=$(( width - ${#title} - 2 - before_len ))
    local before="" after=""
    for (( i=0; i<before_len; i++ )); do before+="$h"; done || true
    for (( i=0; i<after_len; i++ )); do after+="$h"; done || true
    printf '%s%s%s %s %s%s%s\n' "$c" "$tl" "$before" "$title" "$after" "$tr" "$_BK_RESET"
  else
    printf '%s%s%s%s%s\n' "$c" "$tl" "$hline" "$tr" "$_BK_RESET"
  fi

  # Content lines
  for line in "${lines[@]}"; do
    local stripped
    stripped=$(printf '%s' "$line" | sed 's/\x1b\[[0-9;]*m//g')
    local visible_len=${#stripped}
    local fill_len=$(( width - padding * 2 - visible_len ))
    local fill=""
    for (( i=0; i<fill_len; i++ )); do fill+=" "; done || true
    printf '%s%s%s%s%s%s%s%s%s\n' \
      "$c" "$v" "$_BK_RESET" "$pad" "$line" "$fill" "$pad" "$c$v" "$_BK_RESET"
  done || true

  # Bottom border
  printf '%s%s%s%s%s\n' "$c" "$bl" "$hline" "$br" "$_BK_RESET"
}

# ---------------------------------------------------------------------------
# Status lines:  bk_ok / bk_fail / bk_warn / bk_info / bk_pending
# ---------------------------------------------------------------------------
bk_ok()      { printf '%s✓%s %s\n' "$_BK_GREEN" "$_BK_RESET" "$*"; }
bk_fail()    { printf '%s✗%s %s\n' "$_BK_RED" "$_BK_RESET" "$*"; }
bk_warn()    { printf '%s!%s %s\n' "$_BK_YELLOW" "$_BK_RESET" "$*"; }
bk_info()    { printf '%s·%s %s\n' "$_BK_BLUE" "$_BK_RESET" "$*"; }
bk_pending() { printf '%s○%s %s\n' "$_BK_GRAY" "$_BK_RESET" "$*"; }

# Status with label columns:  bk_status ok "Platform" "macOS arm64"
bk_status() {
  local kind="$1" label="$2" value="$3" label_width="${4:-12}"
  local icon color
  case "$kind" in
    ok)      icon="✓" color="$_BK_GREEN";;
    fail)    icon="✗" color="$_BK_RED";;
    warn)    icon="!" color="$_BK_YELLOW";;
    info)    icon="·" color="$_BK_BLUE";;
    pending) icon="○" color="$_BK_GRAY";;
    *)       icon="·" color="";;
  esac
  printf '%s%s%s %-*s %s\n' "$color" "$icon" "$_BK_RESET" "$label_width" "$label" "$value"
}

# ---------------------------------------------------------------------------
# Spinner
# ---------------------------------------------------------------------------
# Spinner frame sets
_BK_SPIN_DOTS=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
_BK_SPIN_LINE=('|' '/' '-' '\')
_BK_SPIN_CIRCLE=(◐ ◓ ◑ ◒)
_BK_SPIN_ARC=(◜ ◝ ◞ ◟)
_BK_SPIN_ARROW=(← ↖ ↑ ↗ → ↘ ↓ ↙)
_BK_SPIN_BOUNCE=('[=   ]' '[ =  ]' '[  = ]' '[   =]' '[  = ]' '[ =  ]')
_BK_SPIN_BOX=(◰ ◳ ◲ ◱)
_BK_SPIN_SIMPLE_DOTS=(⠁ ⠂ ⠄ ⠂)

# Get spinner frames array name for a style
_bk_spin_frames() {
  case "${1:-dots}" in
    dots)    echo "_BK_SPIN_DOTS";;
    line)    echo "_BK_SPIN_LINE";;
    circle)  echo "_BK_SPIN_CIRCLE";;
    arc)     echo "_BK_SPIN_ARC";;
    arrow)   echo "_BK_SPIN_ARROW";;
    bounce)  echo "_BK_SPIN_BOUNCE";;
    box)     echo "_BK_SPIN_BOX";;
    simple)  echo "_BK_SPIN_SIMPLE_DOTS";;
    *)       echo "_BK_SPIN_DOTS";;
  esac
}

# Run a command with a spinner: bk_spinner [--style dots] [--color cyan] "label" command [args...]
bk_spinner() {
  local style="dots" color="cyan" label=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --style) style="$2"; shift 2;;
      --color) color="$2"; shift 2;;
      *)       break;;
    esac
  done
  label="$1"; shift

  local frames_var; frames_var=$(_bk_spin_frames "$style")
  eval "local frame_count=\${#${frames_var}[@]}"
  local c; c=$(_bk_color "$color")
  local idx=0

  _bk_hide_cursor

  # Run command in background
  "$@" &
  local pid=$!

  # Animate
  while kill -0 "$pid" 2>/dev/null; do
    eval "local frame=\${${frames_var}[$idx]}"
    printf '\r%s%s%s %s' "$c" "$frame" "$_BK_RESET" "$label"
    idx=$(( (idx + 1) % frame_count ))
    sleep 0.08
  done

  # Get exit code
  wait "$pid"
  local exit_code=$?

  # Clear spinner line
  _bk_erase_line
  _bk_show_cursor

  return $exit_code
}

# Inline spinner — doesn't run a command, just prints one frame.
# Use in your own loops: while ...; do bk_spin_frame; sleep 0.08; done
_bk_spin_idx=0
bk_spin_frame() {
  local style="${1:-dots}" label="${2:-}" color="${3:-cyan}"
  local frames_var; frames_var=$(_bk_spin_frames "$style")
  eval "local frame_count=\${#${frames_var}[@]}"
  local c; c=$(_bk_color "$color")
  eval "local frame=\${${frames_var}[$_bk_spin_idx]}"
  printf '\r%s%s%s %s' "$c" "$frame" "$_BK_RESET" "$label"
  _bk_spin_idx=$(( (_bk_spin_idx + 1) % frame_count ))
}

# ---------------------------------------------------------------------------
# Progress bar
# ---------------------------------------------------------------------------
# Usage: bk_progress [--style block|ascii|thin|dots|braille] [--width N]
#        [--color COLOR] [--label "TEXT"] [--show-percent] VALUE
#   VALUE is 0-100
bk_progress() {
  local style="block" width=30 color="green" label="" show_pct=0 value=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --style)        style="$2"; shift 2;;
      --width)        width="$2"; shift 2;;
      --color)        color="$2"; shift 2;;
      --label)        label="$2"; shift 2;;
      --show-percent) show_pct=1; shift;;
      *)              value="$1"; shift;;
    esac
  done

  [[ $value -gt 100 ]] && value=100
  [[ $value -lt 0 ]] && value=0

  local filled=$(( value * width / 100 ))
  local empty=$(( width - filled ))

  local fill_char empty_char head_char
  case "$style" in
    block)   fill_char='█' empty_char='░' head_char='';;
    ascii)   fill_char='=' empty_char='-' head_char='>';;
    thin)    fill_char='─' empty_char='─' head_char='○';;
    dots)    fill_char='●' empty_char='○' head_char='';;
    braille) fill_char='⣿' empty_char='⣀' head_char='';;
    *)       fill_char='█' empty_char='░' head_char='';;
  esac

  local c; c=$(_bk_color "$color")
  local bar=""

  # Build bar
  if [[ -n "$head_char" && $filled -gt 0 && $filled -lt $width ]]; then
    for (( i=0; i<filled-1; i++ )); do bar+="$fill_char"; done || true
    bar+="$head_char"
  else
    for (( i=0; i<filled; i++ )); do bar+="$fill_char"; done || true
  fi

  local empty_part=""
  for (( i=0; i<empty; i++ )); do empty_part+="$empty_char"; done || true

  # Assemble output
  local out=""
  [[ -n "$label" ]] && out+="$label "
  out+="${c}${bar}${_BK_RESET}${_BK_GRAY}${empty_part}${_BK_RESET}"
  [[ $show_pct -eq 1 ]] && out+=" ${value}%"

  printf '%s' "$out"
}

# Animated progress — runs a command and shows progress ticking up
# bk_progress_run [--style block] [--color green] [--label "Installing"] command [args...]
bk_progress_run() {
  local style="block" color="green" label="" width=30
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --style) style="$2"; shift 2;;
      --color) color="$2"; shift 2;;
      --label) label="$2"; shift 2;;
      --width) width="$2"; shift 2;;
      *)       break;;
    esac
  done

  "$@" &
  local pid=$!
  local value=0

  _bk_hide_cursor
  while kill -0 "$pid" 2>/dev/null; do
    printf '\r'
    bk_progress --style "$style" --width "$width" --color "$color" \
      --label "$label" --show-percent "$value"
    # Ease toward 90% while command runs
    [[ $value -lt 90 ]] && value=$((value + 1 + RANDOM % 3))
    sleep 0.1
  done
  wait "$pid"
  local exit_code=$?

  # Jump to 100% on success
  printf '\r'
  if [[ $exit_code -eq 0 ]]; then
    bk_progress --style "$style" --width "$width" --color "$color" \
      --label "$label" --show-percent 100
  else
    bk_progress --style "$style" --width "$width" --color "red" \
      --label "$label" --show-percent "$value"
  fi
  printf '\n'
  _bk_show_cursor
  return $exit_code
}

# ---------------------------------------------------------------------------
# Table
# ---------------------------------------------------------------------------
# Usage: bk_table [--header] [--border single|round|none] [--striped]
#        [--color COLOR] "Col1,Col2,Col3" "val1,val2,val3" ...
bk_table() {
  local has_header=0 border="none" striped=0 color="white" sep=","
  local -a raw_rows=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --header)  has_header=1; shift;;
      --border)  border="$2"; shift 2;;
      --striped) striped=1; shift;;
      --color)   color="$2"; shift 2;;
      --sep)     sep="$2"; shift 2;;
      *)         raw_rows+=("$1"); shift;;
    esac
  done

  [[ ${#raw_rows[@]} -eq 0 ]] && return

  # Parse rows into 2D array
  local -a all_cells=()   # flat array
  local num_cols=0 num_rows=${#raw_rows[@]}

  for row_str in "${raw_rows[@]}"; do
    IFS="$sep" read -ra cells <<< "$row_str"
    [[ ${#cells[@]} -gt $num_cols ]] && num_cols=${#cells[@]}
    all_cells+=("${cells[@]}")
    # Pad short rows
    local pad=$(( num_cols - ${#cells[@]} ))
    for (( p=0; p<pad; p++ )); do all_cells+=(""); done || true
  done || true

  # Calculate column widths
  local -a col_widths=()
  for (( c=0; c<num_cols; c++ )); do col_widths[$c]=0; done || true

  for (( r=0; r<num_rows; r++ )); do
    for (( c=0; c<num_cols; c++ )); do
      local cell="${all_cells[$((r * num_cols + c))]}"
      local stripped
      stripped=$(_bk_strip_ansi "$cell")
      local len=${#stripped}
      [[ $len -gt ${col_widths[$c]} ]] && col_widths[$c]=$len
    done || true
  done || true

  # Border characters
  local bc; bc=$(_bk_color "$color")
  local tl="" tr="" bl="" br="" h="" v="" cross="" t_down="" t_up="" t_left="" t_right=""
  case "$border" in
    single) tl='┌' tr='┐' bl='└' br='┘' h='─' v='│' cross='┼' t_down='┬' t_up='┴' t_left='┤' t_right='├';;
    round)  tl='╭' tr='╮' bl='╰' br='╯' h='─' v='│' cross='┼' t_down='┬' t_up='┴' t_left='┤' t_right='├';;
    none)   ;;
  esac

  local gap=2  # space between columns

  # Render a horizontal border line
  _bk_table_hline() {
    local left="$1" mid="$2" right="$3" hc="$4"
    printf '%s%s' "$bc" "$left"
    for (( c=0; c<num_cols; c++ )); do
      local w=$(( col_widths[c] + gap ))
      for (( i=0; i<w; i++ )); do printf '%s' "$hc"; done || true
      if (( c < num_cols - 1 )); then printf '%s' "$mid"; fi
    done || true
    printf '%s%s\n' "$right" "$_BK_RESET"
  }

  # Top border
  [[ "$border" != "none" ]] && _bk_table_hline "$tl" "$t_down" "$tr" "$h"

  # Rows
  for (( r=0; r<num_rows; r++ )); do
    # Striped background
    local row_style=""
    if [[ $striped -eq 1 && $((r % 2)) -eq 1 && ($has_header -eq 0 || $r -gt 0) ]]; then
      row_style="$_BK_DIM"
    fi

    [[ "$border" != "none" ]] && printf '%s%s%s' "$bc" "$v" "$_BK_RESET"

    for (( c=0; c<num_cols; c++ )); do
      local cell="${all_cells[$((r * num_cols + c))]}"
      local stripped
      stripped=$(_bk_strip_ansi "$cell")
      local visible_len=${#stripped}
      local pad_len=$(( col_widths[c] - visible_len ))
      local pad=""
      for (( i=0; i<pad_len; i++ )); do pad+=" "; done || true

      # Header row bold
      if [[ $has_header -eq 1 && $r -eq 0 ]]; then
        printf ' %s%s%s%s ' "$_BK_BOLD" "$cell" "$pad" "$_BK_RESET"
      else
        printf ' %s%s%s%s ' "$row_style" "$cell" "$pad" "$_BK_RESET"
      fi

      if [[ "$border" != "none" && $c -lt $((num_cols - 1)) ]]; then
        printf '%s%s%s' "$bc" "$v" "$_BK_RESET"
      fi
    done || true

    [[ "$border" != "none" ]] && printf '%s%s%s' "$bc" "$v" "$_BK_RESET"
    printf '\n'

    # Divider after header
    if [[ $has_header -eq 1 && $r -eq 0 ]]; then
      if [[ "$border" != "none" ]]; then
        _bk_table_hline "$t_right" "$cross" "$t_left" "$h"
      else
        for (( c=0; c<num_cols; c++ )); do
          local w=$(( col_widths[c] + gap ))
          for (( i=0; i<w; i++ )); do printf '─'; done || true
        done || true
        printf '\n'
      fi
    fi
  done || true

  # Bottom border
  [[ "$border" != "none" ]] && _bk_table_hline "$bl" "$t_up" "$br" "$h"
}

# ---------------------------------------------------------------------------
# Select prompt
# ---------------------------------------------------------------------------
# Usage: bk_select [--color cyan] [--indicator arrow|pointer|bullet|radio]
#        [--label "Choose one:"] "Option 1" "Option 2" "Option 3"
#   Returns selected index (0-based) in BK_SELECTED and value in BK_SELECTED_VALUE
bk_select() {
  local color="cyan" indicator="arrow" label=""
  local -a options=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --color)     color="$2"; shift 2;;
      --indicator) indicator="$2"; shift 2;;
      --label)     label="$2"; shift 2;;
      *)           options+=("$1"); shift;;
    esac
  done

  [[ ${#options[@]} -eq 0 ]] && return 1

  local sel_char uns_char
  case "$indicator" in
    arrow)   sel_char='❯' uns_char=' ';;
    pointer) sel_char='▸' uns_char=' ';;
    bullet)  sel_char='•' uns_char=' ';;
    radio)   sel_char='●' uns_char='○';;
    *)       sel_char='❯' uns_char=' ';;
  esac

  local c; c=$(_bk_color "$color")
  local idx=0
  local count=${#options[@]}
  local total_lines=$count
  [[ -n "$label" ]] && total_lines=$((total_lines + 1))

  _bk_hide_cursor

  # Trap to restore cursor on exit
  trap '_bk_show_cursor' RETURN

  # Render function
  _bk_select_render() {
    # Move up to overwrite (except first render)
    [[ ${1:-0} -eq 1 ]] && _bk_cursor_up "$total_lines"

    [[ -n "$label" ]] && printf '%s%s%s\n' "$_BK_BOLD" "$label" "$_BK_RESET"

    for (( i=0; i<count; i++ )); do
      _bk_erase_line
      if [[ $i -eq $idx ]]; then
        printf '%s%s %s%s\n' "$c" "$sel_char" "${options[$i]}" "$_BK_RESET"
      else
        printf '%s%s%s %s%s\n' "$_BK_GRAY" "$uns_char" "$_BK_RESET" "${options[$i]}" "$_BK_RESET"
      fi
    done || true
  }

  # Initial render
  _bk_select_render 0

  # Input loop
  while true; do
    read -rsn1 key
    case "$key" in
      $'\x1b')
        read -rsn2 rest
        case "$rest" in
          '[A') [[ $idx -gt 0 ]] && idx=$((idx - 1));;          # Up
          '[B') [[ $idx -lt $((count - 1)) ]] && idx=$((idx + 1));;  # Down
        esac
        ;;
      '') break;;  # Enter
      'q') _bk_show_cursor; return 1;;
    esac
    _bk_select_render 1
  done

  _bk_show_cursor
  BK_SELECTED=$idx
  BK_SELECTED_VALUE="${options[$idx]}"
  return 0
}

# ---------------------------------------------------------------------------
# Confirm prompt
# ---------------------------------------------------------------------------
# Usage: bk_confirm [--color cyan] [--default yes|no] "Question?"
#   Returns 0 for yes, 1 for no. Result also in BK_CONFIRMED (yes/no).
bk_confirm() {
  local color="cyan" default="yes" question=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --color)   color="$2"; shift 2;;
      --default) default="$2"; shift 2;;
      *)         question="$1"; shift;;
    esac
  done

  local c; c=$(_bk_color "$color")
  local sel="$default"

  _bk_hide_cursor
  trap '_bk_show_cursor' RETURN

  _bk_confirm_render() {
    [[ ${1:-0} -eq 1 ]] && printf '\r' && _bk_erase_line

    printf '%s%s%s ' "$_BK_BOLD" "$question" "$_BK_RESET"
    if [[ "$sel" == "yes" ]]; then
      printf '%s[Yes]%s / No' "$c" "$_BK_RESET"
    else
      printf 'Yes / %s[No]%s' "$c" "$_BK_RESET"
    fi
  }

  _bk_confirm_render 0

  while true; do
    read -rsn1 key
    case "$key" in
      $'\x1b')
        read -rsn2 rest
        case "$rest" in
          '[C'|'[D') [[ "$sel" == "yes" ]] && sel="no" || sel="yes";;
        esac
        ;;
      y|Y) sel="yes"; _bk_confirm_render 1; break;;
      n|N) sel="no"; _bk_confirm_render 1; break;;
      '')  break;;  # Enter
    esac
    _bk_confirm_render 1
  done

  printf '\n'
  _bk_show_cursor
  BK_CONFIRMED="$sel"
  [[ "$sel" == "yes" ]]
}

# ---------------------------------------------------------------------------
# Multi-line render block (inline re-rendering like blaeck's LogUpdate)
# ---------------------------------------------------------------------------
# Usage:
#   bk_render_init N    — reserve N lines
#   bk_render "line1" "line2" ...  — overwrite those N lines
#   bk_render_done      — finalize (cursor below block)
_BK_RENDER_LINES=0

bk_render_init() {
  _BK_RENDER_LINES=$1
  # Print empty lines to reserve space, cursor stays at bottom.
  # bk_render will cursor_up to the top before writing.
  for (( i=0; i<_BK_RENDER_LINES; i++ )); do printf '\n'; done || true
  _bk_hide_cursor
}

bk_render() {
  # Move to top of block
  [[ $_BK_RENDER_LINES -gt 0 ]] && _bk_cursor_up "$_BK_RENDER_LINES"

  local count=0
  for line in "$@"; do
    _bk_erase_line
    printf '%s\n' "$line"
    count=$((count + 1))
  done

  # Clear remaining lines if fewer args than reserved
  while (( count < _BK_RENDER_LINES )); do
    _bk_erase_line
    printf '\n'
    count=$((count + 1))
  done
}

bk_render_done() {
  _bk_show_cursor
  _BK_RENDER_LINES=0
}

# Resize a live render block to a new line count without leaving duplicates.
# Erases the current block, then reserves the new size.
bk_render_resize() {
  local new_lines=$1
  # Move to top of current block and erase each line going down
  if [[ $_BK_RENDER_LINES -gt 0 ]]; then
    _bk_cursor_up "$_BK_RENDER_LINES"
    for (( i=0; i<_BK_RENDER_LINES; i++ )); do
      _bk_erase_line
      printf '\n'
    done || true
    # Cursor is now at the bottom of the old block — move back to top
    _bk_cursor_up "$_BK_RENDER_LINES"
  fi
  # Reserve new space (print newlines from top position)
  _BK_RENDER_LINES=$new_lines
  for (( i=0; i<_BK_RENDER_LINES; i++ )); do printf '\n'; done || true
}

# ---------------------------------------------------------------------------
# Gradient text (simple 2-color left-to-right using 256-color)
# ---------------------------------------------------------------------------
bk_gradient() {
  local text="$1"
  local from="${2:-196}" to="${3:-21}"  # ANSI 256 color codes
  local len=${#text}
  [[ $len -eq 0 ]] && return

  for (( i=0; i<len; i++ )); do
    local color_code=$(( from + (to - from) * i / (len - 1) ))
    [[ $color_code -lt 0 ]] && color_code=$(( -color_code ))
    printf '\033[38;5;%dm%s' "$color_code" "${text:$i:1}"
  done || true
  printf '%s' "$_BK_RESET"
}

# ---------------------------------------------------------------------------
# Text input
# ---------------------------------------------------------------------------
# Usage: bk_input [--color cyan] [--placeholder "text"] [--label "Name:"]
#   Result in BK_INPUT_VALUE
bk_input() {
  local color="cyan" placeholder="" label=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --color)       color="$2"; shift 2;;
      --placeholder) placeholder="$2"; shift 2;;
      --label)       label="$2"; shift 2;;
      *)             shift;;
    esac
  done

  local c; c=$(_bk_color "$color")
  local value=""

  _bk_input_render() {
    _bk_erase_line
    printf '%s%s%s ' "$_BK_BOLD" "$label" "$_BK_RESET"
    if [[ -z "$value" && -n "$placeholder" ]]; then
      printf '%s%s%s' "$_BK_GRAY" "$placeholder" "$_BK_RESET"
    else
      printf '%s%s%s' "$c" "$value" "$_BK_RESET"
    fi
  }

  _bk_input_render

  while true; do
    read -rsn1 key
    case "$key" in
      '')  # Enter
        break
        ;;
      $'\x7f'|$'\x08')  # Backspace
        if [[ ${#value} -gt 0 ]]; then
          value="${value%?}"
        fi
        ;;
      $'\x1b')  # Escape sequences
        read -rsn2 -t 0.01 rest 2>/dev/null || true
        ;;
      *)
        # Printable character
        if [[ "$key" =~ [[:print:]] ]]; then
          value+="$key"
        fi
        ;;
    esac
    _bk_input_render
  done

  printf '\n'
  BK_INPUT_VALUE="$value"
}

# ---------------------------------------------------------------------------
# Password input (masked)
# ---------------------------------------------------------------------------
# Usage: bk_password [--color cyan] [--mask "●"] [--label "Password:"]
#   Result in BK_INPUT_VALUE
bk_password() {
  local color="cyan" mask="●" label=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --color) color="$2"; shift 2;;
      --mask)  mask="$2"; shift 2;;
      --label) label="$2"; shift 2;;
      *)       shift;;
    esac
  done

  local c; c=$(_bk_color "$color")
  local value=""

  _bk_pw_render() {
    _bk_erase_line
    printf '%s%s%s ' "$_BK_BOLD" "$label" "$_BK_RESET"
    local masked=""
    for (( i=0; i<${#value}; i++ )); do masked+="$mask"; done || true
    printf '%s%s%s' "$c" "$masked" "$_BK_RESET"
  }

  _bk_pw_render

  while true; do
    read -rsn1 key
    case "$key" in
      '')
        break
        ;;
      $'\x7f'|$'\x08')
        if [[ ${#value} -gt 0 ]]; then
          value="${value%?}"
        fi
        ;;
      $'\x1b')
        read -rsn2 -t 0.01 rest 2>/dev/null || true
        ;;
      *)
        if [[ "$key" =~ [[:print:]] ]]; then
          value+="$key"
        fi
        ;;
    esac
    _bk_pw_render
  done

  printf '\n'
  BK_INPUT_VALUE="$value"
}

# ---------------------------------------------------------------------------
# Multi-select (checkboxes)
# ---------------------------------------------------------------------------
# Usage: bk_multiselect [--color cyan] [--label "Select:"] "Opt 1" "Opt 2" ...
#   Results in BK_MULTI_SELECTED (space-separated indices) and
#   BK_MULTI_SELECTED_VALUES (newline-separated values)
bk_multiselect() {
  local color="cyan" label=""
  local -a options=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --color) color="$2"; shift 2;;
      --label) label="$2"; shift 2;;
      *)       options+=("$1"); shift;;
    esac
  done

  [[ ${#options[@]} -eq 0 ]] && return 1

  local c; c=$(_bk_color "$color")
  local idx=0
  local count=${#options[@]}
  local -a checked=()
  for (( i=0; i<count; i++ )); do checked[$i]=0; done || true

  local total_lines=$count
  [[ -n "$label" ]] && total_lines=$((total_lines + 1))
  local footer_lines=1
  total_lines=$((total_lines + footer_lines))

  _bk_hide_cursor
  trap '_bk_show_cursor' RETURN

  _bk_ms_render() {
    [[ ${1:-0} -eq 1 ]] && _bk_cursor_up "$total_lines"

    [[ -n "$label" ]] && printf '%s%s%s\n' "$_BK_BOLD" "$label" "$_BK_RESET"

    for (( i=0; i<count; i++ )); do
      _bk_erase_line
      local check_icon
      if [[ ${checked[$i]} -eq 1 ]]; then
        check_icon="${_BK_GREEN}◼${_BK_RESET}"
      else
        check_icon="${_BK_GRAY}◻${_BK_RESET}"
      fi
      if [[ $i -eq $idx ]]; then
        printf '%s❯%s %s %s%s%s\n' "$c" "$_BK_RESET" "$check_icon" "$c" "${options[$i]}" "$_BK_RESET"
      else
        printf '  %s %s\n' "$check_icon" "${options[$i]}"
      fi
    done || true

    _bk_erase_line
    printf '%s↑↓ move  space toggle  enter confirm%s\n' "$_BK_GRAY" "$_BK_RESET"
  }

  _bk_ms_render 0

  while true; do
    read -rsn1 key
    case "$key" in
      $'\x1b')
        read -rsn2 rest
        case "$rest" in
          '[A') [[ $idx -gt 0 ]] && idx=$((idx - 1));;
          '[B') [[ $idx -lt $((count - 1)) ]] && idx=$((idx + 1));;
        esac
        ;;
      ' ')  # Space toggles
        if [[ ${checked[$idx]} -eq 1 ]]; then
          checked[$idx]=0
        else
          checked[$idx]=1
        fi
        ;;
      '') break;;
      'q') _bk_show_cursor; return 1;;
    esac
    _bk_ms_render 1
  done

  _bk_show_cursor
  BK_MULTI_SELECTED=""
  BK_MULTI_SELECTED_VALUES=""
  for (( i=0; i<count; i++ )); do
    if [[ ${checked[$i]} -eq 1 ]]; then
      BK_MULTI_SELECTED+="$i "
      BK_MULTI_SELECTED_VALUES+="${options[$i]}"$'\n'
    fi
  done || true
  BK_MULTI_SELECTED="${BK_MULTI_SELECTED% }"
  BK_MULTI_SELECTED_VALUES="${BK_MULTI_SELECTED_VALUES%$'\n'}"
  return 0
}

# ---------------------------------------------------------------------------
# Layout helpers — flexbox-inspired columns
# ---------------------------------------------------------------------------
# Usage: bk_columns [--gap N] [--widths "W1,W2,..."] "col1 text" "col2 text" ...
#   Widths can be absolute numbers or percentages (e.g. "30,50,20")
bk_columns() {
  local gap=2
  local widths_str=""
  local -a cols=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --gap)    gap="$2"; shift 2;;
      --widths) widths_str="$2"; shift 2;;
      *)        cols+=("$1"); shift;;
    esac
  done

  local num_cols=${#cols[@]}
  [[ $num_cols -eq 0 ]] && return

  local term_width; term_width=$(_bk_cols)
  local -a widths=()

  if [[ -n "$widths_str" ]]; then
    IFS=',' read -ra widths <<< "$widths_str"
  else
    # Equal widths
    local each=$(( (term_width - gap * (num_cols - 1)) / num_cols ))
    for (( i=0; i<num_cols; i++ )); do widths[$i]=$each; done || true
  fi

  # Split each column text by newlines, find max height
  local max_height=0
  local -a col_lines=()  # flat: col_lines[col * max + row]

  for (( c=0; c<num_cols; c++ )); do
    local text="${cols[$c]}"
    local h=0
    while IFS= read -r line; do
      col_lines+=("$line")
      h=$((h + 1))
    done <<< "$text"
    [[ $h -gt $max_height ]] && max_height=$h
  done || true

  # Pad shorter columns
  # Re-parse to get per-column arrays
  local -a col_data=()  # col_data[c * max_height + r]
  local offset=0
  for (( c=0; c<num_cols; c++ )); do
    local text="${cols[$c]}"
    local r=0
    while IFS= read -r line; do
      col_data[$((c * max_height + r))]="$line"
      r=$((r + 1))
    done <<< "$text"
    while (( r < max_height )); do
      col_data[$((c * max_height + r))]=""
      r=$((r + 1))
    done
  done || true

  # Render row by row
  for (( r=0; r<max_height; r++ )); do
    for (( c=0; c<num_cols; c++ )); do
      local cell="${col_data[$((c * max_height + r))]}"
      local stripped
      stripped=$(_bk_strip_ansi "$cell")
      local visible_len=${#stripped}
      local w=${widths[$c]}
      local pad_len=$(( w - visible_len ))
      [[ $pad_len -lt 0 ]] && pad_len=0

      printf '%s' "$cell"
      for (( p=0; p<pad_len; p++ )); do printf ' '; done || true

      if (( c < num_cols - 1 )); then
        for (( g=0; g<gap; g++ )); do printf ' '; done || true
      fi
    done || true
    printf '\n'
  done || true
}

# ---------------------------------------------------------------------------
# Spacer / blank lines
# ---------------------------------------------------------------------------
bk_spacer() { local n="${1:-1}"; for (( i=0; i<n; i++ )); do printf '\n'; done; } || true

# ---------------------------------------------------------------------------
# Indent helper
# ---------------------------------------------------------------------------
bk_indent() {
  local n="${1:-2}"
  local pad=""
  for (( i=0; i<n; i++ )); do pad+=" "; done || true
  while IFS= read -r line; do
    printf '%s%s\n' "$pad" "$line"
  done
}

# ---------------------------------------------------------------------------
# Banner / header
# ---------------------------------------------------------------------------
bk_banner() {
  local text="$1" color="${2:-cyan}" width="${3:-$(_bk_cols)}"
  local c; c=$(_bk_color "$color")
  local text_len=${#text}
  local pad_left=$(( (width - text_len) / 2 ))
  local pad_right=$(( width - text_len - pad_left ))
  local left="" right=""
  for (( i=0; i<pad_left-1; i++ )); do left+="─"; done || true
  for (( i=0; i<pad_right-1; i++ )); do right+="─"; done || true

  printf '%s%s %s%s%s %s%s\n' "$c" "$left" "$_BK_BOLD" "$text" "$_BK_RESET$c" "$right" "$_BK_RESET"
}

# ---------------------------------------------------------------------------
# Range picker (numeric)
# ---------------------------------------------------------------------------
# Usage: bk_range [--color cyan] [--label "Pick a number:"] MIN MAX [DEFAULT]
#   Result in BK_RANGE_VALUE
bk_range() {
  local color="cyan" label=""
  local min=0 max=100 value=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --color) color="$2"; shift 2;;
      --label) label="$2"; shift 2;;
      *)       break;;
    esac
  done

  min="${1:-0}"; max="${2:-100}"; value="${3:-$min}"
  [[ $value -lt $min ]] && value=$min
  [[ $value -gt $max ]] && value=$max

  local c; c=$(_bk_color "$color")

  _bk_hide_cursor
  trap '_bk_show_cursor' RETURN

  _bk_range_render() {
    _bk_erase_line
    [[ -n "$label" ]] && printf '%s%s%s ' "$_BK_BOLD" "$label" "$_BK_RESET"
    printf '%s%s%s %s❮%s %s%s%s %s❯%s %s%s%s' \
      "$_BK_GRAY" "$min" "$_BK_RESET" \
      "$_BK_GRAY" "$_BK_RESET" \
      "$c" "$value" "$_BK_RESET" \
      "$_BK_GRAY" "$_BK_RESET" \
      "$_BK_GRAY" "$max" "$_BK_RESET"
  }

  _bk_range_render

  while true; do
    read -rsn1 key
    case "$key" in
      $'\x1b')
        read -rsn2 rest
        case "$rest" in
          '[D'|'[A') # Left / Up
            [[ $value -gt $min ]] && value=$((value - 1))
            ;;
          '[C'|'[B') # Right / Down
            [[ $value -lt $max ]] && value=$((value + 1))
            ;;
        esac
        ;;
      '') break;;  # Enter
      'q') _bk_show_cursor; return 1;;
    esac
    _bk_range_render
  done

  printf '\n'
  _bk_show_cursor
  BK_RANGE_VALUE=$value
  return 0
}

# ---------------------------------------------------------------------------
# Editor (open $EDITOR for multi-line input)
# ---------------------------------------------------------------------------
# Usage: bk_editor [--label "Edit config:"]
#   Result in BK_EDITOR_VALUE
bk_editor() {
  local label=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --label) label="$2"; shift 2;;
      *)       shift;;
    esac
  done

  local tmpfile
  tmpfile=$(mktemp "${TMPDIR:-/tmp}/blaeck-editor.XXXXXX")

  [[ -n "$label" ]] && printf '%s%s%s\n' "$_BK_BOLD" "$label" "$_BK_RESET"

  "${EDITOR:-vi}" "$tmpfile" </dev/tty >/dev/tty

  if [[ -s "$tmpfile" ]]; then
    BK_EDITOR_VALUE=$(<"$tmpfile")
    printf '%s%s%s\n' "$_BK_CYAN" "$(sed 's/^/  /' "$tmpfile")" "$_BK_RESET"
  else
    BK_EDITOR_VALUE=""
  fi

  rm -f "$tmpfile"
}

# ---------------------------------------------------------------------------
# Validation wrapper
# ---------------------------------------------------------------------------
# Usage: bk_validate "prompt_command" validation_function
#   Repeats prompt_command until validation_function returns 0.
#   validation_function receives the value as $1.
#   If it fails (returns non-zero), its stdout is shown as the error message.
#
# Example:
#   not_empty() { [[ -n "$1" ]] || { echo "Cannot be empty"; return 1; }; }
#   bk_validate 'bk_input --label "Name:"' not_empty
#   echo "$BK_INPUT_VALUE"
bk_validate() {
  local prompt_cmd="$1"
  local validate_fn="$2"

  while true; do
    eval "$prompt_cmd"
    # Grab the most recent result variable
    local val=""
    [[ -n "${BK_INPUT_VALUE:-}" ]] && val="$BK_INPUT_VALUE"
    [[ -n "${BK_SELECTED_VALUE:-}" ]] && val="$BK_SELECTED_VALUE"
    [[ -n "${BK_RANGE_VALUE:-}" ]] && val="$BK_RANGE_VALUE"
    [[ -n "${BK_EDITOR_VALUE:-}" ]] && val="$BK_EDITOR_VALUE"

    local err_msg
    if err_msg=$("$validate_fn" "$val" 2>&1); then
      break
    else
      [[ -n "$err_msg" ]] && printf '%s✗ %s%s\n' "$_BK_RED" "$err_msg" "$_BK_RESET"
    fi
  done
}

# ---------------------------------------------------------------------------
# Leveled logging
# ---------------------------------------------------------------------------
# Usage:
#   bk_log_level info          # set threshold (debug|info|warn|error)
#   bk_log debug "details"
#   bk_log info "starting"
#   bk_log warn "careful"
#   bk_log error "failed"
_BK_LOG_LEVEL=1  # default: info

bk_log_level() {
  case "${1:-info}" in
    debug) _BK_LOG_LEVEL=0;;
    info)  _BK_LOG_LEVEL=1;;
    warn)  _BK_LOG_LEVEL=2;;
    error) _BK_LOG_LEVEL=3;;
  esac
}

bk_log() {
  local level="$1" message="$2"
  local level_num color level_label

  case "$level" in
    debug) level_num=0; color="$_BK_BLUE";    level_label="DEBUG";;
    info)  level_num=1; color="$_BK_CYAN";    level_label="INFO ";;
    warn)  level_num=2; color="$_BK_YELLOW";  level_label="WARN ";;
    error) level_num=3; color="$_BK_RED";     level_label="ERROR";;
    *)     level_num=1; color="$_BK_CYAN";    level_label="INFO ";;
  esac

  [[ $level_num -lt $_BK_LOG_LEVEL ]] && return

  local timestamp
  timestamp=$(date +'%Y-%m-%dT%H:%M:%S')

  printf '[%s%s%s] %s%s%s %s\n' \
    "$color" "$level_label" "$_BK_RESET" \
    "$_BK_MAGENTA" "$timestamp" "$_BK_RESET" \
    "$message"
}

# ---------------------------------------------------------------------------
# OS detection
# ---------------------------------------------------------------------------
# Usage: bk_detect_os → prints: macos, linux, windows, bsd, or unknown
bk_detect_os() {
  case "$(uname -s)" in
    Darwin)  echo "macos";;
    Linux)   echo "linux";;
    MINGW*|MSYS*|CYGWIN*) echo "windows";;
    *BSD)    echo "bsd";;
    *)       echo "unknown";;
  esac
}

# Usage: bk_detect_arch → prints: x86_64, aarch64, or the raw uname -m
bk_detect_arch() {
  local arch
  arch=$(uname -m)
  case "$arch" in
    arm64) echo "aarch64";;
    *)     echo "$arch";;
  esac
}

# ---------------------------------------------------------------------------
# Open link in browser
# ---------------------------------------------------------------------------
# Usage: bk_open "https://example.com"
bk_open() {
  local url="$1"
  local cmd=""

  case "$(bk_detect_os)" in
    macos)   cmd="open";;
    linux)   cmd="xdg-open";;
    windows) cmd="start";;
  esac

  if [[ -n "$cmd" ]] && command -v "$cmd" >/dev/null 2>&1; then
    "$cmd" "$url" 2>/dev/null
  else
    printf 'Open this URL in your browser:\n  %s%s%s\n' "$_BK_CYAN" "$url" "$_BK_RESET"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Cleanup trap helper
# ---------------------------------------------------------------------------
bk_cleanup() {
  _bk_show_cursor
  printf '%s' "$_BK_RESET"
}
