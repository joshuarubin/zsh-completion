COMP_WORDBREAKS=${COMP_WORDBREAKS/=/}
COMP_WORDBREAKS=${COMP_WORDBREAKS/@/}
export COMP_WORDBREAKS

if type complete &>/dev/null; then
  _nohap_completion () {
    local si="$IFS"
    IFS=$'\n' COMPREPLY=($(COMP_CWORD="$COMP_CWORD" \
                           COMP_LINE="$COMP_LINE" \
                           COMP_POINT="$COMP_POINT" \
                           nohap completion complete "${COMP_WORDS[@]}")) || return $?
    IFS="$si"
  }
  complete -F _nohap_completion nohap
elif type compdef &>/dev/null; then
  _nohap_completion() {
    si=$IFS
    compadd -- $(COMP_CWORD=$((CURRENT-1)) \
                 COMP_LINE=$BUFFER \
                 COMP_POINT=0 \
                 nohap completion complete "${words[@]}")
    IFS=$si
  }
  compdef _nohap_completion nohap
elif type compctl &>/dev/null; then
  _nohap_completion () {
    local cword line point words si
    read -Ac words
    read -cn cword
    let cword-=1
    read -l line
    read -ln point
    si="$IFS"
    IFS=$'\n' reply=($(COMP_CWORD="$cword" \
                       COMP_LINE="$line" \
                       COMP_POINT="$point" \
                       nohap completion complete "${words[@]}")) || return $?
    IFS="$si"
  }
  compctl -K _nohap_completion nohap
fi
