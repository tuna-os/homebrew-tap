cask "tavern" do
  version "0.1.65"

  name "Tavern"
  desc "Modern Homebrew client built with Python and GTK 4"
  homepage "https://github.com/tuna-os/Tavern"

  # Both published launchers use the Homebrew Python/GTK stack.
  depends_on formula: "pygobject3"
  depends_on formula: "gtk4"
  depends_on formula: "libadwaita"

  livecheck do
    url "https://github.com/tuna-os/Tavern/releases.atom"
    strategy :github_latest
  end

  on_macos do
    sha256 "47c7391ba6266e86d66f07530d623473da175263614a77cc8820c6cf8d5a2dc2"
    url "https://github.com/tuna-os/Tavern/releases/download/v#{version}/Tavern-macOS.zip"

    app "Tavern.app"

    zap trash: [
      "~/Library/Application Support/Tavern",
      "~/Library/Preferences/org.tunaos.tavern.*",
      "~/Library/Caches/org.tunaos.tavern",
    ]
  end

  on_linux do
    sha256 "99441c915f758643c50870ddf4433728d898ffb64308f98ce211a63cab71799c"
    url "https://github.com/tuna-os/Tavern/releases/download/v#{version}/Tavern-Linux.AppImage"

    # The extracted AppImage bundles its own GTK4 but ships only the Adw
    # typelib without libadwaita, and the extracted layout has no AppImage
    # runtime to set up the loader path: the app needs the brew GTK stack
    # for libadwaita (and as fallback libs) plus the LD_LIBRARY_PATH export
    # in preflight below.

    binary "squashfs-root/AppRun", target: "tavern"

    # Verified in the published v0.1.65 AppImage, not inferred from source.
    artifact "squashfs-root/usr/share/icons/hicolor/scalable/apps/org.tunaos.tavern.svg",
             target: "#{Dir.home}/.local/share/icons/hicolor/scalable/apps/org.tunaos.tavern.svg"

    artifact "squashfs-root/usr/share/applications/org.tunaos.tavern.desktop",
             target: "#{Dir.home}/.local/share/applications/org.tunaos.tavern.desktop"

    preflight do
      appimage_path = "#{staged_path}/Tavern-Linux.AppImage"
      FileUtils.chmod 0o755, appimage_path
      system_command appimage_path, args: ["--appimage-extract"], chdir: staged_path
      FileUtils.rm appimage_path

      # PATCH: fix AppRun's $0-based path resolution.
      # When symlinked from HOMEBREW_PREFIX/bin, $0 is the symlink's dir,
      # not the squashfs-root where the script actually lives.
      # Replace:  this_dir="$(readlink -f "$(dirname "$0")")"
      # With:     this_dir="$(dirname "$(readlink -f "$0")")"
      apprun_path = "#{staged_path}/squashfs-root/AppRun"
      apprun = File.read(apprun_path)
      unless apprun.sub!('this_dir="$(readlink -f "$(dirname "$0")")"',
                         'this_dir="$(dirname "$(readlink -f "$0")")"')
        raise "Unsupported AppRun path setup; inspect the released AppImage"
      end
      # PATCH: set TAVERN_DATADIR so the Python script finds gresource/icons
      # relative to the AppDir, not the hardcoded meson prefix (/usr/share/tavern)
      # PATCH: export the bundled usr/lib on LD_LIBRARY_PATH. The AppImage
      # runtime normally does this, but the extracted layout has no runtime:
      # without it the bundled libgtk-4.so.1 is invisible and the app dies
      # importing Gtk (GIRepository cannot load the typelib's library).
      # #{HOMEBREW_PREFIX}/lib covers what the bundle omits (notably
      # libadwaita, declared in depends_on above): bundled libs win, brew
      # libs fill the gaps.
      unless apprun.sub!('exec "$this_dir"/AppRun.wrapped "$@"',
                         "export TAVERN_DATADIR=\"$this_dir/usr/share/tavern\"\n" \
                         "export TAVERN_LOCALEDIR=\"$this_dir/usr/share/locale\"\n" \
                         "export LD_LIBRARY_PATH=\"$this_dir/usr/lib:#{HOMEBREW_PREFIX}/lib:$LD_LIBRARY_PATH\"\n" \
                         'exec "$this_dir"/AppRun.wrapped "$@"')
        raise "Unsupported AppRun entry point; inspect the released AppImage"
      end

      File.write(apprun_path, apprun)

      FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
      FileUtils.mkdir_p "#{Dir.home}/.local/share/icons/hicolor/scalable/apps"

      desktop = File.read("#{staged_path}/squashfs-root/usr/share/applications/org.tunaos.tavern.desktop")
      desktop.gsub!(%r{^Exec=.*}, "Exec=#{HOMEBREW_PREFIX}/bin/tavern")
      desktop.gsub!(%r{^Icon=.*}, "Icon=org.tunaos.tavern")
      File.write("#{staged_path}/squashfs-root/usr/share/applications/org.tunaos.tavern.desktop", desktop)
    end

    postflight do
      system_command "gtk-update-icon-cache",
        args: ["-qtf", "#{Dir.home}/.local/share/icons/hicolor"],
        sudo: false
    rescue StandardError
      nil
    end

    zap trash: [
      "~/.local/share/applications/org.tunaos.tavern.desktop",
      "~/.local/share/icons/hicolor/scalable/apps/org.tunaos.tavern.svg",
      "~/.local/share/org.tunaos.tavern",
      "~/.config/org.tunaos.tavern",
      "~/.cache/tavern",
    ]
  end
end
