if ((PROFILE)); then
    zmodload zsh/zprof
fi

. "${HOME}/.shellrc"


zshrc::antigen() {
    ###
    # Setup antigen
    # Disable cache as it breaks history, liquidprompt etc.
    export _ANTIGEN_CACHE_ENABLED=false
    export ADOTDIR="${HOME}/.cache/antigen"
    $(shell::source "${HOME}/.zsh.d/bundle/antigen/antigen.zsh")

    # Load bundles from oh-my-zsh
    antigen use oh-my-zsh
}
shell::is_dumb || shell::eval zshrc::antigen


zshrc::history() {
    alias zhistory="builtin history -di 1"
}
shell::eval zshrc::history


zshrc::zsh_completions() {
    local zsh_completions="/usr/local/share/zsh-completions"
    if file::is_readable ${zsh_completions}; then
        fpath[1,0]=( ${zsh_completions} )

        antigen bundle zsh-users/zsh-completions src
    fi
}
shell::is_dumb || shell::eval zshrc::zsh_completions


zshrc::antigen_bundles() {
    antigen bundles <<EOB
        command-not-found

        # Copy with progress using cpv
        cp

        # Battery status
        battery

        # Extract any archive
        extract

        # Cycle through directory stack with C-<Shift>-<Left>/<Right>
        dircycle

        # Prefer GNU utils
        gnu-utils
EOB

    file::is_directory "${HOME}/.vim/bundle/vundle" && antigen bundle vundle

    for binary in rsync node npm fasd ssh-agent scala sbt ruby svn python pip; do
        path::has_binary "${binary}" && antigen bundle "${binary}"
    done

    path::has_binary task && antigen bundle taskwarrior
    path::has_binary go && antigen bundles <<EOB
        go
        golang
EOB
    path::has_binary tmux && antigen bundles <<EOB
        tmux
        tmuxinator
EOB
    path::has_binary git && antigen bundles <<EOB
        git
        github
EOB
    path::has_binary hg && antigen bundle mercurial
    os::is_darwin && antigen bundle osx
    path::has_binary brew && antigen bundle brew
}
shell::is_dumb || shell::eval zshrc::antigen_bundles


zshrc::liquidprompt() {
    antigen bundle nojhan/liquidprompt
}
shell::is_dumb || shell::eval zshrc::liquidprompt


zshrc::syntax_highlighting() {
    antigen bundle zsh-users/zsh-syntax-highlighting
}
shell::is_dumb || shell::eval zshrc::syntax_highlighting


zshrc::dumb_terminal() {
    # Fallback for dumb terminals (i.e. when running under Emacs Tramp).
    print::debug "Dumb terminal detected, falling back to safe mode."
    unsetopt zle
    unsetopt prompt_cr
    unsetopt prompt_subst
    shell::has_function precmd && unfunction precmd
    shell::has_function preexec && unfunction preexec
}
shell::is_dumb && shell::eval zshrc::dumb_terminal


zshrc::darwin_setup() {
    if path::has_binary brew; then
        unalias run-help
        autoload run-help
        HELPDIR=$(brew --prefix)/share/zsh/help
    fi
}
os::is_darwin && shell::eval zshrc::darwin_setup


$(shell::source "${HOME}/.zshrc.local")
$(shell::source "${HOME}/.zsh_aliases.local")


###
# Apply antigen
shell::is_dumb || shell::eval antigen apply
