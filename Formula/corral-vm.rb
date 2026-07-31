class CorralVm < Formula
  desc "Manage QEMU and KubeVirt VMs/CTs - CLI, TUI, and web UI in one binary"
  homepage "https://github.com/tuna-os/corral"
  url "https://github.com/tuna-os/corral/archive/refs/tags/v0.4.0.tar.gz"
  sha256 "22e816638e105c75e20209ce0a3769829359ea57701be64b65f9ed058f5b4d26"
  license "Apache-2.0"
  head "https://github.com/tuna-os/corral.git", branch: "main"

  # Named corral-vm to avoid clashing with homebrew/core's unrelated "corral".
  # The installed command stays `corral` — the tool's real name, referenced by
  # every doc, completion, and `corral web service` unit.
  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/tuna-os/corral/cmd.version=v#{version}"
    system "go", "build", *std_go_args(output: bin/"corral", ldflags:)
    generate_completions_from_executable(bin/"corral", "completion")
  end

  test do
    assert_match "v#{version}", shell_output("#{bin}/corral version")
    # --demo runs against the built-in fake cluster, so the CLI is
    # exercisable end-to-end with no kubectl or cluster present.
    assert_match "web-prod", shell_output("#{bin}/corral list --demo")
  end
end
