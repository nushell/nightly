# pull down the latest nightly build of Nushell
#
# this command will
# - get the metadata of the latest build of Nushell in the nightly repo
# - filter the assets that match the search pattern `target`
# - fuzzy-ask one of them or use the single match
# - download the archive
# - give some hints about the version and the hash and how to extract the archive
export def get-latest-nightly-build [
    target: string = "" # the target architecture, matches all of them by default
]: nothing -> nothing {
    let latest = http get https://api.github.com/repos/nushell/nightly/releases
        | sort-by published_at --reverse
        | first

    let matches = $latest.assets
        | get name
        | where $it =~ $target
        | parse --regex 'nu-\d\.\d+\.\d-(?<arch>[a-zA-Z0-9-_]*)\..*'
        | get arch

    let arch = match ($matches | length) {
        0 => {
            let span = metadata $target | get span
            error make {
                msg: $"(ansi red_bold)no_match(ansi reset)"
                label: {
                    text: $"no architecture matching this in ($latest.html_url)"
                    start: $span.start
                    end: $span.end
                }
            }
        },
        1 => { $matches.0 },
        _ => {
            let choice = $matches | input list --fuzzy $"Please (ansi cyan)choose one architecture(ansi reset):"
            if ($choice | is-empty) {
                print "user chose to exit"
                return
            }

            $choice
        },
    }

    let target = $latest.assets | where name =~ $arch
    if ($target | length) != 1 {
        error make --unspanned {
            msg: (
                  $"(ansi red_bold)unexpected_internal_error(ansi reset):\n"
                + $"expected one match, found ($target | length)\n"
                + $"matches: ($target.name)"
            )
        }
    }
    let target = $target | first

    let build = $target.name
        | parse --regex 'nu-(?<version>\d\.\d+\.\d)-(?<arch>[a-zA-Z0-9-_]*)\.(?<extension>.*)'
        | first
        | insert hash { $latest.tag_name | parse "nightly-{hash}" | get 0.hash }

    http get $target.browser_download_url | save --progress --force $target.name

    print $"latest nightly build \(version: ($build.version), hash: ($build.hash)\) saved as `(ansi default_dimmed)($target.name)(ansi reset)`"
    match $build.extension {
        "tar.gz" => {
            print $"(ansi cyan)hint(ansi reset): run `(ansi default_dimmed)tar xvf ($target.name) --directory .(ansi reset)` to unpack the tarball"
        },
        "zip" => {
            print $"(ansi cyan)hint(ansi reset): run `(ansi default_dimmed)unzip ($target.name) -d .(ansi reset)` to unpack the archive"
        },
        _ => {
            print $"unknown extension ($build.extension), you'll have to figure out how to extract this archive ;)"
        },
    }
}
