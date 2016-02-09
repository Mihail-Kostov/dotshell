compiler::_dump() {
    local compiler_bin="${1}"; shift
    local compiler_args="${*}"

    print::debug "(${compiler_bin} ${compiler_args}): Begin"
    local args="${compiler_args} -x c -"
    echo "main;" | shell::exec ${compiler_bin} ${args} </dev/null 2>&1
    local retval="$?"
    print::debug "(${compiler_bin} ${compiler_args}): End (${retval})"

    return ${retval}
}

compiler::dump_defines() {
    local compiler_bin="${1}"; shift
    local compiler_args="${*}"

    compiler::_dump ${compiler_bin} "${compiler_args} -dM -E"
}

compiler::dump_flags() {
    local compiler_bin="${1}"; shift
    local compiler_args="${*}"

    compiler::_dump ${compiler_bin} "${compiler_args} -Q -v"
}

compiler::dump_includes() {
    local compiler_bin="${1}"; shift
    local compiler_args="${*}"

    shell::exec ${compiler_bin} -w -H ${compiler_args}
}

compiler::find_typedef() {
    local name="${1}"
    local search_path="${2:-/usr/include}"

    shell::exec egrep -r "'typedef.*${name};'" ${search_path}
}

compiler::disassemble_functions() {
    local binary="${1}"; shift
    local -a functions; functions=( ${*} )

    local args="-nh -batch -quiet -ex 'file ${binary}'"
    args+=" -ex 'set disassembly-flavor intel'"

    for fun in ${functions[@]}; do
        args+=" -ex 'disassemble /m ${fun}'"
    done

    shell::exec gdb ${args}
}
