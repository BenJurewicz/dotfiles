# Clipboard widgets for the current command and the most recent command output.
# Output capture uses tmux's pane pipe so commands keep talking directly to a TTY.

[[ -o interactive ]] || return

autoload -Uz add-zsh-hook

typeset -g _LAST_COMMAND_TEXT=''
typeset -g _LAST_COMMAND_CAPTURE_DIR=''
typeset -g _LAST_COMMAND_RAW_FILE=''
typeset -g _LAST_COMMAND_CAPTURE_ACTIVE=0
typeset -g _LAST_COMMAND_CAPTURE_AVAILABLE=0
typeset -g _LAST_COMMAND_CAPTURE_REASON='No command output has been captured yet'
typeset -gr _LAST_COMMAND_CAPTURE_LIMIT=$((8 * 1024 * 1024))
typeset -gr _LAST_COMMAND_RENDERER="${${(%):-%N}:A:h}/render-command-output.py"

_last_command_notify() {
    zle -M "$1"
}

_last_command_clipboard() {
    if (( $+commands[pbcopy] )); then
        pbcopy
    elif (( $+commands[wl-copy] )); then
        wl-copy
    else
        return 127
    fi
}

_last_command_prepare_capture_dir() {
    [[ -d "$_LAST_COMMAND_CAPTURE_DIR" ]] && return 0

    _LAST_COMMAND_CAPTURE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/zsh-last-command.XXXXXXXX")" || return 1
    chmod 700 "$_LAST_COMMAND_CAPTURE_DIR" || return 1
    _LAST_COMMAND_RAW_FILE="$_LAST_COMMAND_CAPTURE_DIR/output.raw"
}

_last_command_preexec() {
    _LAST_COMMAND_TEXT=$1
    _LAST_COMMAND_CAPTURE_AVAILABLE=0
    _LAST_COMMAND_CAPTURE_REASON='Last-output capture requires tmux'

    [[ -n "$TMUX" && -n "$TMUX_PANE" ]] || return
    (( $+commands[tmux] )) || return

    if [[ "$(tmux display-message -p -t "$TMUX_PANE" '#{pane_pipe}' 2>/dev/null)" == 1 ]]; then
        _LAST_COMMAND_CAPTURE_REASON='The tmux pane already has an active output pipe'
        return
    fi

    _last_command_prepare_capture_dir || {
        _LAST_COMMAND_CAPTURE_REASON='Could not create the output capture directory'
        return
    }

    : >| "$_LAST_COMMAND_RAW_FILE" || {
        _LAST_COMMAND_CAPTURE_REASON='Could not create the output capture file'
        return
    }
    chmod 600 "$_LAST_COMMAND_RAW_FILE"

    local quoted_file=${_LAST_COMMAND_RAW_FILE//\'/\'\\\'\'}
    # -o prevents replacing a pipe that appeared after the ownership check.
    # Limit capture size so a noisy command cannot fill the temporary volume.
    if tmux pipe-pane -t "$TMUX_PANE" -oO \
        "head -c $_LAST_COMMAND_CAPTURE_LIMIT > '$quoted_file'" 2>/dev/null; then
        _LAST_COMMAND_CAPTURE_ACTIVE=1
        _LAST_COMMAND_CAPTURE_REASON='No output was captured for the last command'
    else
        _LAST_COMMAND_CAPTURE_REASON='Could not start tmux output capture'
    fi
}

_last_command_precmd() {
    (( _LAST_COMMAND_CAPTURE_ACTIVE )) || return

    tmux pipe-pane -t "$TMUX_PANE" 2>/dev/null
    _LAST_COMMAND_CAPTURE_ACTIVE=0
    _LAST_COMMAND_CAPTURE_AVAILABLE=1
}

_last_command_cleanup() {
    if (( _LAST_COMMAND_CAPTURE_ACTIVE )) && [[ -n "$TMUX_PANE" ]]; then
        tmux pipe-pane -t "$TMUX_PANE" 2>/dev/null
    fi
    [[ -n "$_LAST_COMMAND_CAPTURE_DIR" ]] && rm -rf -- "$_LAST_COMMAND_CAPTURE_DIR"
}

# Convert the captured terminal byte stream to readable text. The sibling
# Python script removes terminal control sequences and resolves line redraws.
_last_command_render_output() {
    [[ -r "$_LAST_COMMAND_RAW_FILE" && -r "$_LAST_COMMAND_RENDERER" ]] || return 1
    (( $+commands[python3] )) || return 127

    python3 "$_LAST_COMMAND_RENDERER" \
        "$_LAST_COMMAND_RAW_FILE" "$_LAST_COMMAND_CAPTURE_LIMIT"
}

_last_command_copy_current_or_last() {
    local text message

    if [[ -n "$BUFFER" ]]; then
        text=$BUFFER
        message='Copied current command'
    elif [[ -n "$_LAST_COMMAND_TEXT" ]]; then
        text=$_LAST_COMMAND_TEXT
        message='Copied last command'
    else
        _last_command_notify 'No current or previous command to copy'
        return 1
    fi

    if ! print -rn -- "$text" | _last_command_clipboard; then
        _last_command_notify 'No supported clipboard command found'
        return 1
    fi

    if [[ -n "$BUFFER" ]]; then
        local -a saved_region_highlight=("${region_highlight[@]}")
        region_highlight+=("0 ${#BUFFER} standout")
        zle -R
        sleep 0.15
        region_highlight=("${saved_region_highlight[@]}")
        zle -R
    else
        _last_command_notify "$message"
    fi
}

_last_command_copy_output() {
    if (( ! _LAST_COMMAND_CAPTURE_AVAILABLE )); then
        _last_command_notify "$_LAST_COMMAND_CAPTURE_REASON"
        return 1
    fi

    local output
    output="$(_last_command_render_output)" || {
        _last_command_notify 'Could not render the captured output'
        return 1
    }

    if [[ -z "$output" ]]; then
        _last_command_notify 'The last command produced no output'
        return 1
    fi

    if print -rn -- "$output" | _last_command_clipboard; then
        _last_command_notify 'Copied last output'
    else
        _last_command_notify 'No supported clipboard command found'
        return 1
    fi
}

_last_command_copy_transcript() {
    if [[ -z "$_LAST_COMMAND_TEXT" ]]; then
        _last_command_notify 'No previous command to copy'
        return 1
    fi
    if (( ! _LAST_COMMAND_CAPTURE_AVAILABLE )); then
        _last_command_notify "$_LAST_COMMAND_CAPTURE_REASON"
        return 1
    fi

    local output body fence='```'
    output="$(_last_command_render_output)" || {
        _last_command_notify 'Could not render the captured output'
        return 1
    }
    body="$ ${_LAST_COMMAND_TEXT}"
    [[ -n "$output" ]] && body+=$'\n'"$output"

    while [[ "$body" == *"$fence"* ]]; do
        fence+='`'
    done

    if print -rn -- "$fence"$'\n'"$body"$'\n'"$fence" | _last_command_clipboard; then
        _last_command_notify 'Copied command + output'
    else
        _last_command_notify 'No supported clipboard command found'
        return 1
    fi
}

add-zsh-hook preexec _last_command_preexec
add-zsh-hook precmd _last_command_precmd
add-zsh-hook zshexit _last_command_cleanup

zle -N copy-command-line _last_command_copy_current_or_last
zle -N copy-last-command-output _last_command_copy_output
zle -N copy-last-command-transcript _last_command_copy_transcript

bindkey -M emacs '^Y' copy-command-line
bindkey -M emacs '^[y' copy-last-command-output
bindkey -M emacs '^Xy' copy-last-command-transcript
