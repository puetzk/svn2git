load 'libs/bats-support/load'
load 'libs/bats-assert/load'
load 'libs/bats-file/load'

setup() {
    commonSetup
}

commonSetup() {
    TEST_TEMP_DIR="$(temp_make --prefix 'svn2git-')"
    BATSLIB_FILE_PATH_REM="#${TEST_TEMP_DIR}"
    BATSLIB_FILE_PATH_ADD='<temp>'

    SVN_REPO="$TEST_TEMP_DIR/svn-repo"
    SVN_WORKTREE="$TEST_TEMP_DIR/svn-worktree"

    tar xf "$BATS_TEST_DIRNAME/base-fixture.tar" --one-top-level="$SVN_REPO"
    if [[ "$OSTYPE" == "msys" ]]; then
        SVN_REPO_URL="file:///$(cygpath --mixed --absolute "$SVN_REPO")"
    else
        SVN_REPO_URL="file:///$SVN_REPO"
    fi
    svn checkout "$SVN_REPO_URL" "$SVN_WORKTREE"
    cd "$SVN_WORKTREE"
}

teardown() {
    commonTeardown
}

commonTeardown() {
    if [ -n "${TEST_TEMP_DIR-}" ]; then
        temp_del "$TEST_TEMP_DIR"
    fi
}

svn2git() {
    if [[ "$OSTYPE" == "msys" ]]; then
        # a windows process can't access /dev/fd/* used by bash process subsitution,
        # so the contents must be copied into real temp files
        args=()
        fd_tmps=()
        for arg in "$@"; do
            case "$arg" in
                /dev/fd/* | /proc/*/fd/*)
                    fd_tmp="$(mktemp)"
                    cp "$arg" "$fd_tmp"
                    arg="$(cygpath -m "$fd_tmp")"
                    fd_tmps+=("$fd_tmp")
                    ;;
            esac
            args+=("$arg")
        done
        "$BATS_TEST_DIRNAME/../svn-all-fast-export" "${args[@]}"
        err=$?
        if [ ${#fd_tmps[@]} -gt 0 ]; then
            rm "${fd_tmps[@]}"
        fi
        return $err
    else
       "$BATS_TEST_DIRNAME/../svn-all-fast-export" "$@"
    fi
}
