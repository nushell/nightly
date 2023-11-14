use std log

# install the latest nightly build of Nushell
#
# this command will
# - get the metadata of the latest build of Nushell in the nightly repo
# - interactively ask for one of them or use architecture-specific defaults
# - download the archive
# - extract the archive
# - install the `nu` binary
export def get-latest-nightly-build [
    --install-dir: path = "~/.local/bin/" # the directory where to install the `nu` binary
    --interactive # ask for the architecture to install interactively
    --full # install Nushell with all extra features enabled
    --musl # install Nushell from the MUSL builds (linux x86_64 only)
]: nothing -> nothing {
    let latest = http get https://api.github.com/repos/nushell/nightly/releases
        | sort-by published_at --reverse
        | first

    let assets = $latest.assets
        | get name
        | where not ($it | str ends-with ".msi")
        | parse --regex 'nu-\d\.\d+\.\d-(?<arch>[a-zA-Z0-9-_]*)\..*'
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
        if $musl and (($nu.os-info.arch != "x86_64") or ($nu.os-info.name != "linux")) {
            error make --unspanned {
                msg: (
                    $"(ansi red_bold)invalid_options(ansi reset):\n"
                  + $"--musl requires to be on 'linux x86_64' but you are using '($nu.os-info.name) ($nu.os-info.arch)'"
                )
            }
        }

        if $full and ($nu.os-info.arch not-in ["aarch64", "x86_64"]) {
            error make --unspanned {
                msg: (
                    $"(ansi red_bold)invalid_options(ansi reset):\n"
                  + $"--full is not available for `($nu.os-info.arch)`"
                )
            }
        }

        match $nu.os-info.name {
            "linux" => {
                if $musl {
                    if $full {
                        "x86_64-linux-musl-full"
                    } else {
                        "x86_64-unknown-linux-musl"
                    }
                } else {
                    if $full {
                        $"($nu.os-info.arch)-linux-gnu-full"
                    } else {
                        $"($nu.os-info.arch)-unknown-linux-gnu"
                    }
                }
            },
            "macos" => {
                if $full {
                    $"($nu.os-info.arch)-darwin-full"
                } else {
                    $"($nu.os-info.arch)-apple-darwin"
                }
            },
            "windows" => {
                if $full {
                    $"($nu.os-info.arch)-windows-msvc-full"
                } else {
                    $"($nu.os-info.arch)-pc-windows-msvc"
                }
            },
            $name => $name,
        }
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

    log info $"pulling down (ansi default_dimmed)($target.name)(ansi reset)..."
    http get $target.browser_download_url | save --progress --force $dump_dir

    match $build.extension {
        "tar.gz" => {
            log info "extracting nushell..."
            ^tar xvf $dump_dir --directory $nu.temp-path
        },
        "zip" => {
            log info "extracting nushell..."
            ^unzip $dump_dir -d $nu.temp-path
        },
        _ => {
            error make --unspanned {
                msg: (
                    $"(ansi red_bold)unexpected_internal_error(ansi reset)\n"
                  + $"unknown extension .($build.extension)"
                )
                help: "you'll have to figure out how to extract this archive ;)"
            }
        },
    }

    let binary = $dump_dir | str replace --regex $'\.($build.extension)$' '' | path join "nu"
    log info "installing `nu`..."
    cp --force --verbose $binary ($install_dir | path expand)
}
