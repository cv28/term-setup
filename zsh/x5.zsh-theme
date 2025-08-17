# --- 必备：颜色与 prompt 变量替换 ---
autoload -Uz colors && colors
setopt PROMPT_SUBST

# --- SSH / 任务段 ---
if [[ -n "$BOLT_TASK_ID" ]]; then
  SSH_SEGMENT="%{$fg[magenta]%}[$BOLT_TASK_ID]%{$reset_color%} "
elif [[ -n "$SSH_CONNECTION" ]]; then
  SSH_SEGMENT="%{$fg[magenta]%}[ssh]%{$reset_color%} "
else
  SSH_SEGMENT=""
fi

# --- Git 段配置（需 oh-my-zsh 的 git lib）---
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[red]%}ᴮ"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}%{$fg[yellow]%}✗%{$fg[blue]%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%}"

# 有些环境未加载 git_prompt_info，这里做兼容
if typeset -f git_prompt_info >/dev/null; then
  GIT_SEGMENT='$(git_prompt_info)'
else
  GIT_SEGMENT=''
fi

# --- 返回值符号：上条命令成功绿 λ，失败红 λ ---
# 注意：条件语法应为 %(?.TRUE.FALSE) 而非 %(:...)
RET_STATUS="%(?.%{$fg_bold[green]%}λ.%{$fg_bold[red]%}λ)"

# --- 组装最终 PROMPT ---
PROMPT="${SSH_SEGMENT}${GIT_SEGMENT}%{$fg[cyan]%}%c ${RET_STATUS}%{$reset_color%} "