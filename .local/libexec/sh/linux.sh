debian::dpkg::list_installed() {
    comm -13 \
         <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort) \
         <(comm -23 \
                <(dpkg-query -W -f='${Package}\n' | sed 1d | sort) \
                <(apt-mark showauto | sort) \
          )
}

debian::dpkg::build() {
    local usage="Usage:
 -c --clean             - Clean before build.
 -j <n> --parallel=<n>  - Parallelize build over n threads.
 -t --test              - Run tests.
 --no-deps              - Skip build dependency check.
 --no-docs              - Don't build documentation.
 --arch=<target>        - Cross-compile package for <target>.
 -h --help              - Print help.
"
    eval $(shell::args_parse "cj:th" "arch:,clean,no-deps,no-docs,parallel:,test,help")

    local opts; typeset -A opts
    opts[clean]=false
    opts[deps]=true
    opts[docs]=true
    opts[parallel]=1
    opts[test]=false
    opts[arch]=$(uname -m)
    while true; do
        case "${1}" in
            --arch) shift; opts[arch]="${1}";;
            -c|--clean) opts[clean]=true;;
            -j|--parallel) shift; opts[parallel]="${1}";;
            --no-deps) opts[deps]=false;;
            --no-docs) opts[docs]=false;;
            -t|--test) opts[test]=true;;
            -h|--help) print::info ${usage}; return 0;;
            --) shift; break;;
            *) print::error "Unknown option ${1}"; return 1;;
        esac
        shift
    done

    local build_args="-b -us -uc"
    if ! ${opts[clean]}; then
        print::debug "Not cleaning before build."
        build_args="${build_args} -nc"
    fi

    if ! ${opts[deps]}; then
        print::debug "Skipping dependency check."
        build_args="${build_args} -d"
    fi

    local build_opts=""
    if [[ 1 -lt "${opts[parallel]}" ]]; then
        print::debug "Parallelizing over ${opts[parallel]} threads."
        build_opts="parallel=${opts[parallel]} ${build_opts}"
    fi

    if ! ${opts[test]}; then
        print::debug "Avoiding tests when possible."
        build_opts="nocheck ${build_opts}"
    fi

    if ! ${opts[docs]}; then
        print::debug "Not building documentation."
        build_opts="nodoc ${build_opts}"
    fi

    local build_cmd="$(path::to dpkg-buildpackage)"
    if [[ "$(uname -m)" != "${opts[arch]}" ]]; then
        print::debug "Cross compiling for ${opts[arch]}."
        build_cmd="$(path::to pdebuild)"
        build_args="--debbuildopts \"${build_args}\""
        build_args="--buildresult ${PWD}/.. ${build_args}"
        build_args="--architecture ${opts[arch]} ${build_args}"
    fi

    local build_env; build_env=( DEB_BUILD_OPTIONS="'${build_opts}'" )
    # Reset local Perl settings.
    build_env+=( PERL5LIB= PERL_LOCAL_LIB_ROOT= PERL_MB_OPT= PERL_MM_OPT= )
    shell::exec_env $(shell::as_array build_env) ${build_cmd} ${build_args}
}

linux::setup() {
    # If Linuxbrew is installed add it to the path so that homebrew.sh is
    # evaluated by .shellrc.
    local brew_path="${HOME}/.linuxbrew/bin"
    file::is_directory ${brew_path} && path::prepend ${brew_path}
}
shell::eval linux::setup
