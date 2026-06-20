class YtdpHost < Formula
  desc "YouTubeDiscordPresence desktop host installer for macOS and Linux"
  homepage "https://github.com/ShapeLayer/youtube-discord-presence-unix"
  url "https://github.com/ShapeLayer/youtube-discord-presence-unix/archive/cebf2210e5ad861b7091cca2812b523e04770c0e.tar.gz"
  version "0.0.1-cebf221"
  sha256 "1bde9ef8ca6122f9fe0a04e1330a920717f6592d9193266786b715d325381c58"
  license "MIT"
  head "https://github.com/ShapeLayer/youtube-discord-presence-unix.git", branch: "main"

  depends_on "node"

  def install
    # The upstream installer is a set of bash scripts that fetch the upstream
    # Node host source at runtime, build a wrapper, and register a Chrome Native
    # Messaging manifest into per-user browser profile directories. None of that
    # can happen inside Homebrew's install sandbox, so we ship the scripts and
    # templates into libexec and expose a `ytdp-host` command the user runs
    # afterwards to perform the actual registration.
    libexec.install "scripts", "templates"

    (bin/"ytdp-host").write <<~SH
      #!/usr/bin/env bash
      #
      # Homebrew wrapper for youtube-discord-presence-unix.
      #
      # The upstream scripts derive REPO_ROOT from their own location and write
      # mutable state (vendor/, build/) next to themselves. Because the Cellar is
      # read-only, we stage the read-only scripts + templates from libexec into a
      # writable per-user state directory and run them from there.
      set -euo pipefail

      LIBEXEC="#{libexec}"

      if [ "${YTDP_OS:-}" = "macos" ] || [ "$(uname -s)" = "Darwin" ]; then
        STATE_DIR="${YTDP_STATE_DIR:-${HOME}/Library/Application Support/ytdp-host}"
      else
        STATE_DIR="${YTDP_STATE_DIR:-${XDG_DATA_HOME:-${HOME}/.local/share}/ytdp-host}"
      fi

      mkdir -p "${STATE_DIR}"
      # Mirror the read-only scripts/templates into the writable state dir so the
      # upstream scripts can create vendor/ and build/ alongside them. Remove any
      # previous copies first so refreshing is idempotent: `cp -R src dest` into
      # an existing directory would otherwise nest dest/scripts/scripts on every
      # run. vendor/ and build/ are siblings, so they are left untouched.
      rm -rf "${STATE_DIR}/scripts" "${STATE_DIR}/templates"
      cp -R "${LIBEXEC}/scripts" "${STATE_DIR}/scripts"
      cp -R "${LIBEXEC}/templates" "${STATE_DIR}/templates"

      usage() {
        cat <<'USAGE'
      ytdp-host - YouTubeDiscordPresence desktop host installer

      Usage:
        ytdp-host install [--]            Build and register the native host with your browser(s)
        ytdp-host build                   Build the host wrapper only (no browser registration)
        ytdp-host uninstall [--purge]     Remove the host and browser manifests
        ytdp-host help                    Show this help

      Environment variables (see project README):
        YTDP_NODE_MODE     bundled (default) | system | pinned
        YTDP_NODE_VERSION  bundled Node.js version, e.g. v20.18.1
        YTDP_REF           upstream ref to build (default: a known-good tag)
        YTDP_REPO          upstream repository URL
        YTDP_STATE_DIR     override the writable working directory
      USAGE
        printf '\nThe working directory used is:\n  %s\n' "${STATE_DIR}"
      }

      cmd="${1:-help}"
      [ "$#" -gt 0 ] && shift || true

      case "${cmd}" in
        install)   exec bash "${STATE_DIR}/scripts/install.sh" "$@" ;;
        build)     exec bash "${STATE_DIR}/scripts/build.sh" "$@" ;;
        uninstall) exec bash "${STATE_DIR}/scripts/uninstall.sh" "$@" ;;
        help|-h|--help) usage ;;
        *) echo "ytdp-host: unknown command '${cmd}'" >&2; echo >&2; usage >&2; exit 64 ;;
      esac
    SH
    chmod 0755, bin/"ytdp-host"
  end

  def caveats
    <<~EOS
      ytdp-host ships the installer only; it does not register the native host
      during `brew install` (Homebrew's sandbox cannot write to your browser
      profiles or fetch the upstream Node host source).

      To build and register the desktop component with your browser(s):
        ytdp-host install

      To remove it later:
        ytdp-host uninstall          # or: ytdp-host uninstall --purge

      You still need the browser extension from the Chrome Web Store, and the
      Discord desktop app running with "Share my activity" enabled. See:
        #{homepage}
    EOS
  end

  test do
    # The wrapper must be runnable and report usage without performing any
    # network access or browser registration.
    output = shell_output("#{bin}/ytdp-host help")
    assert_match "ytdp-host", output
    assert_match "install", output

    # An unknown subcommand should exit non-zero with usage.
    assert_match "unknown command",
      shell_output("#{bin}/ytdp-host bogus 2>&1", 64)

    # The scripts and templates must have been staged into libexec.
    assert_path_exists libexec/"scripts/install.sh"
    assert_path_exists libexec/"templates/com.ytdp.discord.presence.template.json"
  end
end
