#!/bin/bash
# setup-complete-alias.h
# Installs github:sanekits/complete-alias for bash
#
#

die() {
    builtin echo "ERROR: $*" >&2
    exit 1
}

SrcBase="https://github.com/sanekits/complete-alias"
SrcUrl="${SrcBase}/releases/latest"


curl_get_finalurl() {
    # See https://stackoverflow.com/a/5300429/237059
    command curl --silent --location --head --output /dev/null --write-out '%{url_effective}' -- "$@";
}

try_aptget_install_bash_completion() {
    which dpkg &>/dev/null && {
        # This branch works for apt/dpkg environments:
        dpkg -s bash-completion 2>/dev/null | grep -qE 'install ok installed'  && {
            # Tis already installed
            true; return;
        }
        [[ $UID == 0 ]] && {
            useSudo=""
        } || {
            echo "Please enter your sudo password (if prompted) to install dependency 'bash-completion'" >&2
            useSudo="sudo "
        }
        $useSudo apt-get install -y bash-completion && {
            return;
        }
    }
    [[ -f /usr/share/bash-completion/bash_completion ]] && {
        # We'll take it on faith if the key file is present
        return
    }
    return $(die "Failed to install bash-completion.
            Visit https://github.com/scop/bash-completion#readme for guidance, then try again")
}

local_setup_prereqs() {
    if [[ -z "${BASH_COMPLETION_VERSINFO[@]}" ]]; then
        try_aptget_install_bash_completion  && return;
    fi
}

local_setup() {
    # Assuming we have copies of complete_alias and completion_loader in some
    # temp dir, we can now do the setup stuff needed for bashrc:
    [[ -f ./complete_alias ]] || die "Can't find $PWD/complete_alias"
    [[ -d ${HOME}/.bash_completion.d ]] || {
        command mkdir "${HOME}/.bash_completion.d" || die "Couldn't create $HOME/.bash_completion.d/"
    }
    command cp ./complete_alias "${HOME}/.bash_completion.d/" || die "Couldn't copy $PWD/complete_alias to $HOME/.bash_completion/"

    # _complete_alias is not showing up in new shells, so let's get serious:
    [[ -f ./completion_loader ]] || die "Couldn't find $PWD/completion_loader"
    command cp ./completion_loader ${HOME}/.completion_loader || die "Couln't copy $PWD/completion_loader to $HOME/.completion_loader"
    # Let's see if it works now:
    command bash -l -c 'type -t _complete_alias' &>/dev/null || {
        cat >> "${HOME}/.bashrc" <<-EOF
[[ -f "\${HOME}/.completion_loader" ]] && source "\${HOME}/.completion_loader" # Added by setup-complete-alias.sh
EOF
            echo "Added \"source ~/.completion_loader\" to your .bashrc" >&2
    }
}

do_install() {
    # Fetch the latest  complete_alias from github and put it in a temp dir, then
    # invoke local_setup()
    for cmd in mktemp curl grep tar; do
        type -p "${cmd}" &>/dev/null || die "Can't find ${cmd}"
    done

    local tmpdir=$(command mktemp -d)
    builtin cd ${tmpdir} || die "Can't cd to tmp dir ${tmpdir}"
    echo "Working in ${tmpdir}" >&2


    echo "Fetching latest release info from ${SrcUrl}"
    local release_url=$(curl_get_finalurl "${SrcUrl}")
    [[ -n $release_url ]] || die "Failed fetching release URL with curl"

    command curl  -L  "$release_url" > release.html || die "curl failed for url [$release_url]"

    local expr='[0-9]+\.[0-9]+\.[0-9]+'
    local version=$( grep -E '/release' $PWD/release.html | grep -Eo "${expr}" | head -n 1 )
    [[ -n $version ]] || die "Failed to parse release version in $PWD/release.html"

    # Example tarball url:
    # https://github.com/sanekits/complete-alias/archive/refs/tags/1.18.0.tar.gz
    local tarball_url="${SrcBase}/archive/refs/tags/${version}.tar.gz"
    echo "Fetching release tarball [${tarball_url}]:"
    command curl -Lo complete-alias.tar.gz "${tarball_url}" || die "Failed to download $tarball_url in $PWD"
    command tar xzf ./complete-alias.tar.gz || die "Failed to extract complete-alias.tar.gz in $PWD"
    local payload_dir="./complete-alias-${version}"
    command cp ${payload_dir}/{complete_alias,completion_loader} . || die "Failed to copy complete_alias to ."

    local_setup_prereqs || die "Can't satsify prerequisites for complete_alias"
    local_setup || die "local_setup() failed"

    echo "Setup completed.  Restart your shell or run \"bash exec\" to use _complete_alias()"

    [[ -z $leaveDebris ]] && rm -rf ${tmpdir}
}

[[ -z $sourceMe ]] && {
    do_install "$@"
}


