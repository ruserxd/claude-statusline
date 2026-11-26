#!/usr/bin/env bash
# Claude Code status line: user@host:cwd | model (effort) | context % | cost | plan limits
# Fields missing from the JSON input are skipped.
input=$(cat)
j() { printf '%s' "$input" | jq -r "$1" 2>/dev/null; }

cwd=$(j '.workspace.current_dir // .cwd // empty')
model=$(j '.model.display_name // .model.id // empty')
model_id=$(j '.model.id // empty')
# effort: live value from the input if Claude Code sends one, else modelSettings in settings.json
effort=$(j '(.effort.level // .effort // .model.effort // .effortLevel // empty) | strings')
if [ -z "$effort" ] && [ -n "$model_id" ]; then
  effort=$(jq -r --arg m "$model_id" '.modelSettings[$m].effortLevel // .effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
fi
ctx=$(j '.context_window.used_percentage // empty | floor')
cost=$(j '.cost.total_cost_usd // empty')
five=$(j '.rate_limits.five_hour.used_percentage // empty | floor')
week=$(j '.rate_limits.seven_day.used_percentage // empty | floor')

# green < 50 %, yellow < 80 %, red otherwise
pct() {
  local c=32
  (( $1 >= 50 )) && c=33
  (( $1 >= 80 )) && c=31
  printf '\033[%sm%s%%\033[00m' "$c" "$1"
}

out=$(printf '\033[01;32m%s@%s\033[00m:\033[01;34m%s\033[00m' "$(whoami)" "$(hostname -s)" "$cwd")
[ -n "$model" ] && out+=$(printf ' | \033[35m%s\033[00m' "$model")
[ -n "$effort" ] && out+=$(printf ' \033[36m(%s)\033[00m' "$effort")
[ -n "$ctx" ]   && out+=" | ctx $(pct "$ctx")"
[ -n "$cost" ]  && out+=$(printf ' | $%.2f' "$cost")
if [ -n "$five" ] || [ -n "$week" ]; then
  out+=" |"
  [ -n "$five" ] && out+=" 5h $(pct "$five")"
  [ -n "$week" ] && out+=" 7d $(pct "$week")"
fi
printf '%s' "$out"
