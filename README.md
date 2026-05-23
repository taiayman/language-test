# Language Test — ALC El Jadida

A cross-platform language testing app built for **ALC El Jadida** (American Language Center, Morocco). Replaces paper exams with an interactive desktop application where students sit listening, reading, and grammar tests, and teachers see results land in real time.

Built Windows-first for the school's lab machines, but the same codebase runs on macOS, Linux, web, Android, and iOS.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-Desktop-0078D6?logo=windows&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-000000?logo=apple&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?logo=linux&logoColor=black)
![Android](https://img.shields.io/badge/Android-3DDC84?logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?logo=apple&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?logo=supabase&logoColor=white)

## What it does

**For students**

- Sit listening, reading, and grammar tests in one app
- Built-in audio player for listening sections (`just_audio` + `media_kit` so it works on Windows where the default Flutter audio plugin doesn't)
- Video-based instructions before each section
- Onboarding tour the first time it's opened (`tutorial_coach_mark`)
- Instant scoring on completion

**For teachers**

- Dashboard with every submission as it comes in
- Per-student breakdown, average scores, completion rates
- Print or export results as PDF
- Auth-gated so only staff can see grades

## Why desktop

The school's lab is Windows PCs, so the primary target is `windows`. The dependency list reflects that:

- `media_kit_libs_windows_video` / `media_kit_libs_windows_audio` — native media playback on Windows
- `just_audio_windows` — keeps the audio API consistent across platforms
- A `dependency_override` on `just_audio_platform_interface` pins the Windows-compatible version

The same code still builds for the other 5 platforms; Windows was just the first one that mattered.

## Stack

| Layer | Tools |
| --- | --- |
| Framework | Flutter (Dart 3, SDK ≥ 3.4.4) |
| Backend | Supabase (auth + Postgres + storage) |
| Media | `just_audio`, `media_kit`, `media_kit_video` |
| UI | `google_fonts`, `flutter_vector_icons`, `tutorial_coach_mark` |
| Files | `file_picker`, `file_selector`, `path_provider` |
| Reports | `pdf`, `printing` |
| Storage | `shared_preferences` |

## Running it locally

```bash
git clone https://github.com/taiayman/language-test.git
cd language-test
flutter pub get
```

Add your Supabase keys (see `lib/` for where they're initialized), then:

```bash
flutter run -d windows   # or macos, linux, chrome, android, ios
```

## Notes

- The audio/video assets in `assets/` are the actual test materials (intentionally kept in-repo so the app works fully offline once installed on lab PCs)
- Built for a specific school, but the architecture (Supabase-backed test runner + dashboard) is reusable for any timed assessment scenario
