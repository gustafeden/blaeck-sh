# blaeck.sh

Terminal UI primitives for bash scripts. A single file you `source` to get spinners, progress bars, boxes, tables, prompts, flexbox columns, and more — with zero dependencies.

Inspired by [blaeck](https://github.com/gustafeden/blaeck), the Rust inline terminal UI framework.

## Install

Source it directly in your script:

```sh
source <(curl -fsSL https://gustafeden.github.io/blaeck-sh/blaeck.sh)
```

Or from GitHub raw:

```sh
source <(curl -fsSL https://raw.githubusercontent.com/gustafeden/blaeck-sh/main/blaeck.sh)
```

Or download it:

```sh
curl -fsSL https://gustafeden.github.io/blaeck-sh/blaeck.sh -o blaeck.sh
source blaeck.sh
```

## Quick Start

```sh
#!/usr/bin/env bash
source <(curl -fsSL https://gustafeden.github.io/blaeck-sh/blaeck.sh)
trap bk_cleanup EXIT

bk_spinner --style dots --color cyan "Installing..." sleep 2
bk_ok "Installed"

bk_box --style round --color green "Done!"
```

## Components

### Text Styling

```sh
bk_bold "bold text"
bk_dim "dim text"
bk_italic "italic text"
bk_red "red"
bk_green "green"
bk_yellow "yellow"
bk_blue "blue"
bk_cyan "cyan"
bk_magenta "magenta"
bk_gray "gray"

# Composable
bk_style --bold --color cyan "bold cyan text"
bk_style --italic --underline --color magenta "fancy text"

# Gradient (256-color, from code to code)
bk_gradient "gradient text" 207 39
```

### Status Lines

```sh
bk_ok "Compiled main.rs"        # ✓ Compiled main.rs
bk_fail "Build failed"          # ✗ Build failed
bk_warn "3 warnings"            # ! 3 warnings
bk_info "Using cache"           # · Using cache
bk_pending "Waiting..."         # ○ Waiting...

# Columnar status
bk_status ok "Platform" "macOS arm64" 12    # ✓ Platform     macOS arm64
bk_status fail "Tests" "2 failed" 12        # ✗ Tests        2 failed
```

### Spinners

8 built-in styles: `dots`, `circle`, `arc`, `arrow`, `box`, `simple`, `line`, `bounce`

```sh
# Wrap any command — spinner shows while it runs
bk_spinner --style dots --color cyan "Loading..." my_command arg1 arg2
bk_spinner --style arrow --color green "Building..." cargo build --release

# Manual frame control for custom loops
while work_remains; do
  bk_spin_frame dots "Processing..." cyan
  sleep 0.08
done
```

### Progress Bars

5 styles: `block`, `ascii`, `thin`, `dots`, `braille`

```sh
# Static
bk_progress --style block --width 30 --color green --show-percent 73
# Output: █████████████████████░░░░░░░░░ 73%

bk_progress --style ascii --width 30 --color cyan 50
# Output: ==============>---------------

# Animated — wraps a command
bk_progress_run --style block --color green --label "Installing" sleep 3
```

### Boxes

5 border styles: `round`, `single`, `double`, `bold`, `classic`

```sh
bk_box --style round --color cyan "Hello world"
# ╭─────────────╮
# │ Hello world │
# ╰─────────────╯

bk_box --style bold --color green --title "Status" \
  "All systems operational." \
  "Uptime: 42 days"

# Options: --width N, --padding N, --title "text"
```

### Tables

```sh
bk_table --header --border round --color gray --striped \
  "Package,Version,Status" \
  "blaeck,0.2.0,$(bk_green installed)" \
  "serde,1.0.210,$(bk_yellow updating)" \
  "tokio,1.40.0,$(bk_gray optional)"
# ╭─────────┬─────────┬───────────╮
# │ Package │ Version │ Status    │
# ├─────────┼─────────┼───────────┤
# │ blaeck  │ 0.2.0   │ installed │
# │ serde   │ 1.0.210 │ updating  │
# │ tokio   │ 1.40.0  │ optional  │
# ╰─────────┴─────────┴───────────╯

# Options: --border round|single|none, --striped, --sep ","
```

### Text Input

```sh
bk_input --color cyan --label "Email:" --placeholder "you@example.com"
echo "You entered: $BK_INPUT_VALUE"
```

### Password Input

```sh
bk_password --color cyan --label "Password:" --mask "●"
echo "Password: $BK_INPUT_VALUE"
```

### Select Menu

```sh
bk_select --color cyan --indicator arrow --label "Choose a theme:" \
  "Nord" "Dracula" "Solarized" "Gruvbox"
echo "Selected: $BK_SELECTED_VALUE (index: $BK_SELECTED)"
```

Indicator styles: `arrow` (❯), `pointer` (▸), `bullet` (•), `radio` (●/○)

### Multi-Select

```sh
bk_multiselect --color cyan --label "Install plugins:" \
  "syntax-highlighting" "auto-complete" "git-integration"
echo "Selected indices: $BK_MULTI_SELECTED"
echo "Selected values:"
echo "$BK_MULTI_SELECTED_VALUES"
```

### Confirm Prompt

```sh
bk_confirm --color cyan --default yes "Enable experimental features?"
if [[ "$BK_CONFIRMED" == "yes" ]]; then
  echo "Enabled"
fi
# Or use the return code directly:
if bk_confirm "Delete file?"; then
  rm file.txt
fi
```

### Flexbox Columns

```sh
bk_columns --widths "30,30" --gap 4 \
  "$(bk_bold 'Left Column')
First item
Second item" \
  "$(bk_bold 'Right Column')
Other item
Another item"

# Three columns with boxes inside
bk_columns --widths "20,20,20" --gap 2 \
  "$(bk_box --style round --color cyan --width 18 'Files: 142')" \
  "$(bk_box --style round --color green --width 18 'Tests: 98')" \
  "$(bk_box --style round --color magenta --width 18 'Build: 0.8s')"
```

### Inline Re-rendering

Updates lines in place, like blaeck's LogUpdate pattern:

```sh
steps=("Pulling" "Building" "Testing" "Deploying")
bk_render_init 4   # reserve 4 lines

for (( i=0; i<4; i++ )); do
  lines=()
  for (( j=0; j<4; j++ )); do
    if (( j < i )); then
      lines+=("  ${_BK_GREEN}✓${_BK_RESET} ${steps[$j]}")
    elif (( j == i )); then
      lines+=("  ${_BK_CYAN}⠋${_BK_RESET} ${steps[$j]}")
    else
      lines+=("  ${_BK_GRAY}○${_BK_RESET} ${steps[$j]}")
    fi
  done
  bk_render "${lines[@]}"
  sleep 1
done

bk_render_done
```

### Other Utilities

```sh
bk_hr '─' 50 gray          # horizontal rule
bk_banner "Title" cyan 60   # centered title with rules
bk_spacer 2                 # blank lines
echo "indented" | bk_indent 4  # indent piped text
bk_cleanup                  # restore cursor + reset colors (use in trap)
```

## API Reference

| Function | Description | Result variable |
|----------|-------------|-----------------|
| `bk_bold`, `bk_dim`, `bk_italic` | Text modifiers | — |
| `bk_red` ... `bk_gray` | Color wrappers | — |
| `bk_style` | Composable styling | — |
| `bk_gradient` | 256-color gradient | — |
| `bk_hr` | Horizontal rule | — |
| `bk_box` | Bordered box | — |
| `bk_ok`, `bk_fail`, `bk_warn`, `bk_info`, `bk_pending` | Status icons | — |
| `bk_status` | Columnar status line | — |
| `bk_spinner` | Animated spinner wrapping a command | — |
| `bk_spin_frame` | Single spinner frame (manual loop) | — |
| `bk_progress` | Static progress bar | — |
| `bk_progress_run` | Animated progress wrapping a command | — |
| `bk_table` | Table with borders | — |
| `bk_input` | Text input | `$BK_INPUT_VALUE` |
| `bk_password` | Masked password input | `$BK_INPUT_VALUE` |
| `bk_select` | Arrow-key select menu | `$BK_SELECTED`, `$BK_SELECTED_VALUE` |
| `bk_multiselect` | Checkbox multi-select | `$BK_MULTI_SELECTED`, `$BK_MULTI_SELECTED_VALUES` |
| `bk_confirm` | Yes/no confirm | `$BK_CONFIRMED` (+ return code) |
| `bk_columns` | Flexbox-style columns | — |
| `bk_render_init`, `bk_render`, `bk_render_done` | Inline re-rendering | — |
| `bk_banner` | Centered title bar | — |
| `bk_indent` | Indent piped text | — |
| `bk_spacer` | Print blank lines | — |
| `bk_cleanup` | Restore terminal state | — |

## Requirements

- bash 3.2+ (macOS default works)
- A terminal with ANSI color support
- `tput` (included on virtually all systems)

Falls back gracefully to plain text when colors are unavailable.

## Examples

Try them instantly — no clone required:

```sh
# Visual showcase (non-interactive)
bash <(curl -fsSL https://gustafeden.github.io/blaeck-sh/showcase.sh)

# Interactive demo (sign-in, menus, multi-select, dashboard)
bash <(curl -fsSL https://gustafeden.github.io/blaeck-sh/interactive.sh)
```

Or clone and run locally:

```sh
git clone https://github.com/gustafeden/blaeck-sh
cd blaeck-sh
bash examples/showcase.sh
bash examples/interactive.sh
```

See the [examples/](examples/) directory for the source.

## Acknowledgements

Inspired by [blaeck](https://github.com/gustafeden/blaeck) — a declarative, component-based inline terminal UI framework for Rust. blaeck.sh brings the same visual primitives to bash scripts with zero compilation and zero dependencies.

## License

MIT
