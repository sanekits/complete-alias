#!/bin/bash
# setup-complete-alias.h
# Installs github:Stabledog/complete-alias for bash
#
#

die() {
    builtin echo "ERROR: $*" >&2
    exit 1
}

SrcBase="https://github.com/stabledog/complete-alias"
SrcUrl="${SrcBase}/releases/latest"


curl_get_finalurl() { 
    # See https://stackoverflow.com/a/5300429/237059
    command curl --silent --location --head --output /dev/null --write-out '%{url_effective}' -- "$@"; 
}

local_setup() {
    # Assuming we have a copy of complete_alias in some temp dir, we can now do the setup stuff
    # needed for bashrc
    set -x
    [[ -f ./complete_alias ]] || die "Can't find $PWD/complete_alias"
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

    local release_url=$(curl_get_finalurl "${SrcUrl}")
    [[ -n $release_url ]] || die "Failed fetching release URL with curl"

    command curl  "$release_url" > release.html || die "curl failed for url [$release_url]"

    local expr='[0-9]+\.[0-9]+\.[0-9]+'
    local version=$( grep -E '/release' $PWD/release.html | grep -Eo "${expr}" | head -n 1 )
    [[ -n $version ]] || die "Failed to parse release version in $PWD/release.html"

    # Example tarball url:
    # https://github.com/Stabledog/complete-alias/archive/refs/tags/1.18.0.tar.gz
    local tarball_url="${SrcBase}/archive/refs/tags/${version}.tar.gz"
    command curl -Lo complete-alias.tar.gz "${tarball_url}" || die "Failed to download $tarball_url in $PWD"
    command tar xzf ./complete-alias.tar.gz || die "Failed to extract complete-alias.tar.gz in $PWD"
    set -x
    local payload_path="./complete-alias-${version}/complete_alias"
    command cp "$payload_path" . || die "Failed to copy complete_alias to ."

    local_setup || die "local_setup() failed"

    [[ -z $leaveDebris ]] && rm -rf ${tmpdir}
}

[[ -z $sourceMe ]] && {
    do_install "$@"
}


