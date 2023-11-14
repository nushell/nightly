# pull down the latest nightly build of Nushell
#
# this command will
# - get the metadata of the latest build of Nushell in the nightly repo
# - fuzzy-ask one of them or use the single match
# - download the archive
# - give some hints about the version and the hash and how to extract the archive
export def get-latest-nightly-build [
    --install-dir: path = "~/.local/bin/" # the directory where to install the `nu` binary
    --interactive # ask for the architecture to install interactively
]: nothing -> nothing {
    let latest = http get https://api.github.com/repos/nushell/nightly/releases
        | sort-by published_at --reverse
        | first

    let assets = $latest.assets
        | get name
        | parse --regex 'nu-\d\.\d+\.\d-(?<arch>[a-zA-Z0-9-_]*\..*)'
        | get arch

    let arch = if $interactive {
        match ($assets | length) {
            0 => {
                error make --unspanned {
                    msg: (
                          $"(ansi red_bold)unexpected_internal_error(ansi reset):\n"
                        + "no nightly build..."
                    )
                }
            },
            1 => { $assets.0 },
            _ => {
                let choice = $assets | input list --fuzzy $"Please (ansi cyan)choose one architecture(ansi reset):"
                if ($choice | is-empty) {
                    print "user chose to exit"
                    return
                }

                $choice
            },
        }
    } else {
        error make --unspanned { msg: "TODO" }
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

    let dump_dir = $nu.temp-path | path join $target.name

    let build = $target.name
        | parse --regex 'nu-(?<version>\d\.\d+\.\d)-(?<arch>[a-zA-Z0-9-_]*)\.(?<extension>.*)'
        | into record

    http get $target.browser_download_url | save --progress --force $dump_dir

    match $build.extension {
        "tar.gz" => {
            ^tar xvf $dump_dir --directory $nu.temp-path
        },
        "zip" => {
            ^unzip $dump_dir -d $nu.temp-path
        },
        _ => {
            error make --unspanned {
                msg: (
                    $"(ansi red_bold)unknown_archive_extension(ansi reset)\n"
                  + $"unknown extension ($build.extension)"
                )
                help: "you'll have to figure out how to extract this archive ;)"
            }
        },
    }

    let binary = $dump_dir | str replace --regex $'\.($build.extension)$' '' | path join "nu"
    cp --force --verbose $binary ($install_dir | path expand)
}
