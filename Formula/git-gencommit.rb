class GitGencommit < Formula
  desc "Generate Git commit messages with LLMs and run add/commit/push"
  homepage "https://github.com/ShapeLayer/git-gencommit"
  url "https://github.com/ShapeLayer/git-gencommit/archive/refs/tags/0.0.1.tar.gz"
  sha256 "087019d91a0847c66cf93674b1368a067dbdb04c29c13772d7c8965985e44465"
  license "MIT"
  head "https://github.com/ShapeLayer/git-gencommit.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "curl"

  def install
    # Reuse upstream installer script while keeping Homebrew installation paths.
    ENV["HOME"] = buildpath
    system "bash", "-c", "scripts/install-git-gencommit.sh < /dev/null"

    bin.install buildpath/"bin/git-gencommit"
  end

  def caveats
    <<~EOS
      git-gencommit installation is complete.

      Run this command to complete interactive configuration:
        git gencommit config
    EOS
  end

  test do
    output = shell_output("git gencommit -h")
    assert_match "Usage:", output
    assert_match "--print-message", output
  end
end
