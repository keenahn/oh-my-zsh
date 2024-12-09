# vim:ft=zsh ts=2 sw=2 sts=2
#
# agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://github.com/Lokaltog/powerline-fonts).
# Make sure you have a recent version: the code points that Powerline
# uses changed in 2012, and older versions will display incorrectly,
# in confusing ways.
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](http://www.iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
DISABLE_AUTO_TITLE=true
# Special Powerline characters

() {
  local LC_ALL="" LC_CTYPE="en_US.UTF-8"
  # NOTE: This segment separator character is correct.  In 2012, Powerline changed
  # the code points they use for their special characters. This is the new code point.
  # If this is not working for you, you probably have an old version of the
  # Powerline-patched fonts installed. Download and install the new version.
  # Do not submit PRs to change this unless you have reviewed the Powerline code point
  # history and have new information.
  # This is defined using a Unicode escape sequence so it is unambiguously readable, regardless of
  # what font the user is viewing this source code in. Do not replace the
  # escape sequence with a single literal character.
  # Do not change this! Do not make it '\u2b80'; that is the old, wrong code point.
  SEGMENT_SEPARATOR=$'\ue0b0'
}

DISABLE_PATTERNS=("${(b)HOME}/s/projects/dotfiles*" "${(b)HOME}/s/projects/universal-todo*")

init() {
  setopt promptsubst
  autoload -Uz vcs_info

  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:*' get-revision true
  zstyle ':vcs_info:*' check-for-changes true
  zstyle ':vcs_info:*' stagedstr '%F{white}✚%f'
  zstyle ':vcs_info:*' unstagedstr '%F{white}●%f'
  # %s The current version control system, like git or svn.
  # %r The name of the root directory of the repository
  # %S The current path relative to the repository root directory
  # %b Branch information, like master
  # %m In case of Git, show information about stashes
  # %u Show unstaged changes in the repository
  # %c Show staged changes in the repository
  zstyle ':vcs_info:*' formats '%u%c'
  zstyle ':vcs_info:*' actionformats '%u%c'
  zstyle ':vcs_info:*' disable-patterns $DISABLE_PATTERNS
}


# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n "%{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%}"
  else
    echo -n "%{$bg%}%{$fg%}"
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -ne $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ $CURRENT_BG != 'NONE' ]]; then
    echo -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  local hostname username
  if [[ `hostname` == Keenahns-MBP ]]; then
    hostname="mbp"
  else
    hostname="%m"
  fi

  if [[ $USER == 'keenahn' ]]; then
    username="k"
  else
    username=$USER
  fi

  if [[ $USER == 'root' ]]; then
    prompt_segment NONE NONE "%{$fg[red]%}$username%{$fg[white]%}@%{$fg[red]%}${hostname}%{$fg[white]%}:"
  else
    prompt_segment NONE NONE "%{$fg[magenta]%}$username%{$fg[white]%}@%{$fg[green]%}${hostname}%{$fg[white]%}:"
  fi

  # if [[ -n "$SSH_CLIENT" ]]; then
  #   # prompt_segment NONE default "%(!.%{%F{red}%}.)%{$fg_bold{magenta}%}$USER@%{%F{green}%}%m%{%F{default}%}:"
  # fi
}

omz_git_color() {
  local git_status="$(git status 2> /dev/null)"

  if [[ ! $git_status =~ "working directory clean" && ! $git_status =~ "working tree clean"  ]]; then
    prompt_segment red white
  elif [[ $git_status =~ "Your branch is ahead of" ]]; then
    prompt_segment yellow black
  elif [[ $git_status =~ "have diverged" ]]; then
    prompt_segment 054 white
  elif [[ $git_status =~ "nothing to commit" ]]; then
    prompt_segment green black
  else
    prompt_segment cyan black
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  local ref dirty mode repo_path

  # TODO: generalize this
  # if [ -d "${PWD}/.git-crypt"  ]; then;
  if [ "${PWD%%/dotfiles*}" != "$PWD" ] || [ "${PWD%%/universal-todo*}" != "$PWD" ]; then;
    return
  fi
  repo_path=$(git rev-parse --git-dir 2>/dev/null)

  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    # dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
    echo -n " "

    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=" <B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=" >M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
      mode=" >R>"
    fi

    vcs_info
    omz_git_color
    echo -n " ${ref/refs\/heads\//} ${vcs_info_msg_0_%% }${mode}"
  fi
}

# Dir: current working directory
# See: https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html#Shell-state
#
# %d
# %/
# Current working directory. If an integer follows the ‘%’, it specifies a number
# of trailing components of the current working directory to show; zero means the
# whole path. A negative integer specifies leading components, i.e. %-1d specifies the first component.
#
# %~
# As %d and %/, but if the current working directory starts with $HOME, that
# part is replaced by a ‘~’. Furthermore, if it has a named directory as its prefix,
# that part is replaced by a ‘~’ followed by the name of the directory, but only if the
# result is shorter than the full path
#
# %(x.true-text.false-text)
# Specifies a ternary expression.
# The character following the x is arbitrary; the same character is used to
# separate the text for the ‘true’ result from that for the ‘false’ result.
# This separator may not appear in the true-text, except as part of a %-escape sequence. A ‘)’
# may appear in the false-text as ‘%)’. true-text and false-text may both contain
# arbitrarily-nested escape sequences, including further ternary expressions.
#
# So %(5~|%-1~/…/%3~|%4~) means that if the path has 5 or more segments
# show the first segment (-1) followed by literal '...', followed by the last 3 segments
# else, show all segments (%4~)

prompt_dir() {
  prompt_segment NONE blue '%~' # '%(5~|%-1~/…/%3~|%4~) '
}

# prompt_direnv() {
#   if [[ -n "$DIRENV_DIFF" ]]; then
#     prompt_segment red white "!"
#   fi
# }

# Virtualenv: current working virtualenv
prompt_virtualenv() {
  local virtualenv_path="$VIRTUAL_ENV"
  if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
    prompt_segment blue black "(`basename $virtualenv_path`)"
  fi
}

# Status:
# - was there an error?
# - am I root?
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="❌"
  [[ $UID -eq 0 ]] && symbols+="⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="⚙"

  if [[ -n "$symbols" ]]; then
    prompt_end
    echo -ne " $symbols"
    # prompt_segment NONE default "$symbols" && prompt_end
  else
    prompt_end
  fi
}

# Deprecated, use convertms instead
convertsecs() {
  ((h=${1}/3600))
  ((m=(${1}%3600)/60))
  ((s=${1}%60))

  if (($h > 0)); then;
    printf "%02d:%02d:%02d" $h $m $s
  elif (($m > 0)); then;
    printf "%02d:%02d" $m $s
  elif (($s == 0)); then;
    printf ""
  elif (($s > 0)); then;
    printf $s
  fi
}

convertms() {
  if (( ${1} < 1000 )); then
    printf "%dms" ${1}
  else
    t=${1}/1000
    ((h=$t/3600))
    ((m=($t%3600)/60))
    ((s=$t%60))
    ((ms=${1}%1000))

    if (($h > 0)); then
      printf "%02d:%02d:%02d" $h $m $s
    elif (($m > 0)); then
      printf "%02d:%02d" $m $s
    elif (($s == 0)); then
      printf "0ms"
    elif (($s > 0)); then
      printf "%d.%03ds" $s $ms
    fi
  fi
}


prompt_time() {
  # See: https://superuser.com/a/943916
  # prompt_segment NONE cyan " %*"
  prompt_segment NONE cyan " %D{%H:%M:%S}"
}

prompt_tmux_window() {
  prompt_segment white black "$TMUX_WINDOW"
}

prompt_node() {
  root_path=$(git rev-parse --show-toplevel 2>/dev/null)
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    if [[ -e "${root_path}/yarn.lock" ]]; then
      mode=" 🧶"
    elif [[ -e "${root_path}/pnpm-lock.yaml" ]]; then
      mode=" 🔗"
    elif [[ -e "${root_path}/pyproject.toml" ]]; then
      mode=" 🐍"
    fi
    echo -ne "$mode"
  fi
}

prompt_db_environment() {
  root_path=$(git rev-parse --show-toplevel 2>/dev/null)
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    if [[ -e "${root_path}/.env" ]]; then
      database_url=$(grep -v '^#' "${root_path}/.env" | grep 'DATABASE_URL_NON_POOLING' | tail -n 1)
      if [[ -n "$database_url" ]]; then
        if [[ $database_url == *mana-copilot-app-data-staging* ]]; then
          echo -ne "%{$fg[red]%}🐘 staging%{$fg[reset]%}"
        elif [[ $database_url == *mana-copilot-app-data* ]]; then
          echo -ne "%{$fg[red]%}🐘 prod%{$fg[reset]%}"
        fi
      fi
    fi
  fi
}

prompt_node_version() {
  if which node &> /dev/null; then
    echo -ne "%{$fg_bold[green]%}⬢ $(node -v | cut -d'.' -f1 | cut -c2-3)%{$reset_color%}"
  fi
}

prompt_seated_db() {
  SUB='sgpostgres'
  if [[ "$SEATED_DATABASE_URL" == *"$SUB"* ]]; then
    # Use nerd fonts if this doesn't  show up
    # https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/FiraCode.zip
    echo -ne "%{$fg_bold[red]%} prod%{$reset_color%}"
  fi
}

# Show the execution time of the last command in the righthand side prompt
function preexec() {
  # timer=${timer:-$SECONDS}
  ms=`date +%s%3N`
  timer=${timer:-$ms}

}

function precmd() {
  if [ $timer ]; then
    ms=`date +%s%3N`
    timer_show=$(($ms - $timer))
    a="$(convertms $timer_show)"

    export RPROMPT="$a"
    unset timer
  fi
}


## Main prompt
build_prompt() {
  RETVAL=$?
  # prompt_virtualenv
  # prompt_tmux_window
  prompt_context
  prompt_dir
  prompt_time
  prompt_node
  # prompt_node_version
  prompt_db_environment
  prompt_git
  prompt_status
  # prompt_seated_db
}

init
PROMPT='%{%f%b%k%}$(build_prompt)%{$reset_color%} '
