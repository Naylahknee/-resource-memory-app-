# Resource Memory

Save useful coding resources once. Find them again when a project actually needs them.

## MVP

Resource Memory is a Flutter app built from the open-source Taskee foundation. The V1 core loop is:

**Save → Understand → Store → Search → Resurface for a project**

### Working features

- Save URLs from YouTube, GitHub, Threads, and general websites
- Automatically enrich YouTube links with oEmbed metadata
- Automatically enrich public GitHub repositories with repository metadata
- Capture creator/platform context for Threads links
- Save screenshots from the photo library
- Store resources locally with Hive
- Search the personal resource library
- Open saved links externally
- Delete resources
- Describe a new project in plain language
- Rank saved resources against the project context
- Show why a result matched
- Taskee-derived dark UI, typography, cards, routing patterns, and local-first structure
- Web, iOS, and Android shell branding for Resource Memory

## Product rule

The MVP exists to prove one behavior:

> A user saves something useful now, forgets about it, starts related work later, and the app brings the resource back.

The app should reduce organizational labor rather than create more tagging work.

## Current enrichment behavior

V1 uses lightweight platform-aware enrichment rather than a hosted AI backend:

- **YouTube:** title, creator, thumbnail, platform and generated retrieval context
- **GitHub:** repository name, owner, description, language, topics and generated retrieval context
- **Threads:** creator handle when available plus generated retrieval context
- **Other websites:** domain-based fallback context
- **Screenshots:** local visual-reference capture

A later backend can add richer AI extraction and screenshot understanding without changing the core Resource model.

## Tech stack

- Flutter / Dart
- Hive local storage
- GoRouter
- Google Fonts / existing Taskee theme system
- `http` for supported public metadata lookups
- `image_picker` for screenshots
- `url_launcher` for opening saved resources

## Run locally

```bash
flutter pub get
flutter run
```

For web:

```bash
flutter run -d chrome
```

## Structure

```text
lib/
  app/
    routing/
    theme/
  features/
    resource/
      data/
      domain/
      presentation/
    project/
      domain/
      presentation/
```

Legacy Taskee task/note source remains in the fork for reference but is no longer bootstrapped by the Resource Memory app.

## CI

`.github/workflows/flutter-ci.yml` runs dependency install, analysis, tests, and a release web build when GitHub Actions is enabled for the fork.

## Attribution and license

This project is derived from **Taskee** by **Junaid Jamel** and retains the original MIT License and copyright notice. Taskee's architecture and visual foundation were intentionally used as the starting point for Resource Memory.

See `LICENSE` for the full license text.
