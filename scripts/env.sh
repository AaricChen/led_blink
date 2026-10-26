# Source from Git Bash:  source scripts/env.sh
# Adds STM32 CLI tools to PATH for this shell session.

_led_blink_to_unix_path() {
  local p="$1"
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -u "$p"
  else
    printf '%s' "$p"
  fi
}

_led_blink_add_path() {
  local dir="$1"
  dir="$(_led_blink_to_unix_path "$dir")"
  if [[ -d "$dir" ]]; then
    case ":$PATH:" in
      *":$dir:"*) ;;
      *) export PATH="$dir:$PATH" ;;
    esac
  fi
}

_led_blink_add_path "/c/Program Files (x86)/Arm GNU Toolchain arm-none-eabi/14.2 rel1/bin"
_led_blink_add_path "/c/Program Files/Arm GNU Toolchain arm-none-eabi/14.2 rel1/bin"

_winget="${LOCALAPPDATA}/Microsoft/WinGet/Packages"
_winget="$(_led_blink_to_unix_path "$_winget")"
if [[ -d "$_winget" ]]; then
  shopt -s nullglob
  for _oc in "$_winget"/xpack-dev-tools.openocd-xpack_*/xpack-openocd-*/bin; do
    _led_blink_add_path "$_oc"
  done
  for _mk in "$_winget"/ezwinports.make_*/bin; do
    _led_blink_add_path "$_mk"
  done
  for _scr in "$_winget"/xpack-dev-tools.openocd-xpack_*/xpack-openocd-*/openocd/scripts; do
    if [[ -d "$_scr" ]]; then
      export OPENOCD_SCRIPTS="$(_led_blink_to_unix_path "$_scr")"
      break
    fi
  done
  shopt -u nullglob
fi

unset -f _led_blink_to_unix_path _led_blink_add_path
unset _winget _oc _mk _scr
