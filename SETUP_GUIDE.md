# Flutter Development Setup Guide

## Prerequisites
- Ensure you have a computer with at least 8GB RAM.
- Install the latest version of [Flutter SDK](https://flutter.dev/docs/get-started/install).
- Make sure you have [Git](https://git-scm.com/downloads) installed.
- An IDE such as [Visual Studio Code](https://code.visualstudio.com/) or [Android Studio](https://developer.android.com/studio) with Flutter and Dart plugins.

## Installation Steps
1. **Download Flutter SDK**:
    - Go to the [Flutter SDK releases page](https://flutter.dev/docs/get-started/install) and download the latest stable version.
2. **Extract Zip File**:
    - Extract the downloaded zip file to your desired location (e.g. `C:lutter` on Windows or `~/flutter` on macOS).
3. **Update Path**:
    - Add the Flutter bin directory in your environment variables.
      - **Windows**: Go to System properties -> Environment Variables and add the path to the `flutter/bin` directory.
      - **macOS/Linux**: Add `export PATH="$PATH:/path-to-flutter-sdk/bin"` to your `~/.bashrc` or `~/.zshrc`. Then run `source ~/.bashrc` or `source ~/.zshrc` to apply changes.
4. **Run Flutter Doctor**:
    - Open your terminal or command prompt and run `flutter doctor` to check for any dependencies you may need to install.

## Environment Configuration
- Ensure you have the Android SDK installed. For Android Studio, it is configured during the installation process.
- For iOS development, you'll need Xcode (macOS only).
- Use the command `flutter config --android-sdk <path>` to set your Android SDK if needed.

## Running the App
1. **Clone the Repository**:
   - Run `git clone https://github.com/your_username/taskflow-mobile.git` to clone the repository.
2. **Navigate to the Project Directory**:
   - Use `cd taskflow-mobile` to navigate to the project folder.
3. **Install Dependencies**:
   - Run `flutter pub get` to install all necessary packages.
4. **Run the App**:
   - Use `flutter run` to start the application.

## Backend Connection
- Follow the API documentation of the assigned backend to integrate it with your Flutter app.
- Configure your base URL and any necessary keys/tokens in a configuration file (e.g., `.env`).

## Project Structure
- **lib/**: Contains Dart files and the main Flutter application.
- **assets/**: For images and other assets.
- **test/**: For unit and widget tests.

## Troubleshooting
- If you encounter issues, check the output of `flutter doctor` for missing dependencies.
- Search error messages on [Stack Overflow](https://stackoverflow.com/) or the [Flutter GitHub issues page](https://github.com/flutter/flutter/issues).

## Common Commands
- `flutter clean`: Cleans the build directory.
- `flutter pub get`: Fetches dependencies.
- `flutter run`: Runs the application.
- `flutter build apk`: Builds the APK for release.
- `flutter analyze`: Analyzes the codebase for potential issues.

Feel free to open issues in this repo for further assistance or documentation updates.