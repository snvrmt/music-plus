# Music Player — Phase 1

Goal of this phase: prove the "no Mac" pipeline. GitHub builds the iPhone app in the cloud, and you install it with SideStore.

## 1. Put the code on GitHub
1. Create a free account at github.com, then a new **private** repository (e.g. `music-player`). Don't add a README.
2. On the empty repo page click **uploading an existing file**, then drag in everything from this folder, **including the hidden `.github` folder** (on Windows, turn on View → Show → Hidden items if you can't see it).
3. Commit to the `main` branch.

## 2. Let GitHub build it
1. Open the **Actions** tab. A run called "Build iOS (unsigned IPA)" starts on its own (or press **Run workflow**).
2. Wait about 10 minutes for the green tick.
3. Open the run, scroll to **Artifacts** and download `MusicPlayer-ipa`. Unzip it to get `MusicPlayer.ipa`.

## 3. Install with SideStore
1. Get the .ipa onto your iPhone (iCloud Drive, OneDrive or Google Drive all work, then save it to Files).
2. In SideStore go to **My Apps → +** and pick `MusicPlayer.ipa`.
3. Open "Music" on your home screen. You should see three tabs and a mini-player saying "Phase 1 build works!".

## Optional: run it on Windows while developing
Install Flutter and run `flutter create . --platforms=windows` once, then `flutter run -d windows`.
