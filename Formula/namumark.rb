class Namumark < Formula
  desc "Parser for Namu Wiki's markup system"
  homepage "https://github.com/ShapeLayer/namumark"
  url "https://github.com/ShapeLayer/namumark/archive/refs/tags/0.1.1.tar.gz"
  sha256 "59ed1be4dd63a7b6b30ccf43e6087a92f0c85253c393d752de9240baf6c6a5bb"
  license "MIT"
  head "https://github.com/ShapeLayer/namumark.git", branch: "main"

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", "-DNAMUMARK_BUILD_TESTING=OFF", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    output = shell_output("#{bin}/namumark -h 2>&1 || true")
    assert_match "namumark", output
  end
end
