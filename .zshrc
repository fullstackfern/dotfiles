eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(starship init zsh)"

alias ls="eza --tree --level 1 --group-directories-first"
alias lsa="eza --tree --level 1 --all --group-directories-first"
alias lst="eza --tree --level 2 --group-directories-first"
alias lsta="eza --tree --level 2 --all --group-directories-first"
alias cat="bat"
alias find="fd"
alias dev="cd ~/Developer"

autoload -Uz compinit && compinit

[[ -f ~/.env ]] && source ~/.env
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z} m:{A-Z}={a-z}'

source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
alias diff='colordiff -y'
