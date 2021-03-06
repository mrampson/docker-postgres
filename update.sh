#!/bin/bash
set -eo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
  versions=( */ )
fi
versions=( "${versions[@]%/}" )

packagesUrl='http://apt.postgresql.org/pub/repos/apt/dists/jessie-pgdg/main/binary-amd64/Packages'
packages="$(echo "$packagesUrl" | sed -r 's/[^a-zA-Z.-]+/-/g')"
curl -sSL "${packagesUrl}.bz2" | bunzip2 > "$packages"

travisEnv=
for version in "${versions[@]}"; do
  fullVersion="$(grep -m1 -A10 "^Package: postgresql-$version\$" "$packages" | grep -m1 '^Version: ' | cut -d' ' -f2)"
  (
    # set -x
    echo "Updating for ${version}"
    cp docker-*.sh "${version}"
    cp Dockerfile "${version}"
    sed -i 's/%%PG_MAJOR%%/'$version'/g; s/%%PG_VERSION%%/'$fullVersion'/g' "$version/Dockerfile"
    )
  travisEnv='\n  - VERSION='"$version$travisEnv"
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml

rm "$packages"
