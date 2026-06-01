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
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    bin.install "build/git-gencommit"
  end

  test do
    output = shell_output("git gencommit -h")
    assert_match "Usage:", output
    assert_match "--print-message", output
  end
end
