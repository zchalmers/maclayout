# Scrub report

## Summary

MacLayout is a macOS menu-bar application that defines screen zones and snaps a dragged window into a selected zone through the Accessibility API. The copy was scrubbed of a built application, archive, macOS metadata, per-user Xcode state, and an empty image artifact. The source has no employer-specific implementation or network configuration.

## Files removed

- `MacLayout.zip` - built archive, not source.
- `MacLayout.app/` - built application bundle, not source.
- Every `.DS_Store` file - Finder metadata.
- Every `._*` file - AppleDouble metadata.
- `MacLayout.xcodeproj/xcuserdata/` and workspace `xcuserdata/` - per-user Xcode state, including an employee-ID directory name.
- `menubar_check.png` - a blank image with no visible content or source role.

## Substitutions applied

- `com.maclayout.app` became `com.example.maclayout` in both target build configurations.
- No signing team ID or provisioning-profile setting was present, so none needed removal.

## Verification

The following commands were run against the output tree. Commands with no listed lines produced no output.

```text
$ rg -n -i -uuu -f /tmp/maclayout-denylist --glob '!.git/**' .
(no output)

$ rg -n -uuu --glob '!.git/**' 'I[0-9]{6}' .
(no output)

$ find . -path './.git' -prune -o -type f \( -name '.DS_Store' -o -name '._*' -o -name '*.zip' -o -name '*.log' -o -name '*.db' -o -name '*.sqlite' -o -name '*.sqlite3' -o -name '*.pyc' \) -print
(no output)

$ git ls-files | wc -l
32

$ git rev-parse HEAD
51ee00cb7be824b1e935096b330b2ffc21d91716
```

`plutil -lint` reported `OK` for `Info.plist` and `MacLayout.entitlements`. `xcodebuild` was not available in this Linux environment, so a macOS build was not run here.

## Judgement calls

The application is small, but it has a coherent and publishable implementation rather than a stub. The recursive layout model, editor, event handling, overlay rendering, persistence, and Accessibility window placement are all present. I recommend publishing it as a compact macOS utility, with its limited scope described plainly in the README.

The blank root image was treated as an accidental check artifact rather than documentation and removed. The asset catalog and Xcode project were retained in full apart from per-user Xcode state.

## Residual risk

There are no automated tests, and the project was not built in this environment because Xcode is unavailable. The coordinate conversion code uses the primary display height when translating between Quartz and AppKit coordinates, which may need manual checking with vertically arranged or otherwise unusual multi-display layouts. The app relies on the user granting Accessibility permission and may not move windows from applications that restrict accessibility control.
