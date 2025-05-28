# Jumpshot-Tracker---Moblie-MediaPipes

## Project Overview

This project is a mobile application with a Python backend designed to track and analyze basketball jumpshots using MediaPipe.

## Directory Structure

- `app/backend/`: Contains the Python Flask backend application.
- `app/frontend/`: Contains the Flutter mobile application.

## Backend (Python/Flask)

The backend is built with Python and Flask, providing APIs for user authentication, video/image upload, and shot analysis.

### Setup

1.  **Navigate to the backend directory:**
    ```bash
    cd app/backend
    ```
2.  **Create a virtual environment (recommended):**
    ```bash
    python3 -m venv new_myenv
    source new_myenv/bin/activate
    ```
    (On Windows, use `new_myenv\Scripts\activate`)
3.  **Install dependencies:**
    ```bash
    pip install -r requirements.txt
    ```
4.  **Set up Firebase Admin SDK:**
    - Download your Firebase Admin SDK JSON key file.
    - Place it in a secure location (e.g., `app/backend/database/firebase_admin_sdk.json`).
    - Ensure this path is correctly referenced in your `config.py` or backend initialization, or set the `GOOGLE_APPLICATION_CREDENTIALS` environment variable.
    ```bash
    export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/firebase_admin_sdk.json"
    ```
    *Note: Make sure `firebase_admin_sdk.json` is added to your `.gitignore` if it's within the project directory to avoid committing sensitive credentials.*

### Running the Backend Server

1.  **Ensure your virtual environment is activated.**
2.  **Start the Flask development server:**
    ```bash
    python main.py
    ```
    Or using Gunicorn (often preferred for production-like environments):
    ```bash
    gunicorn --bind 0.0.0.0:5000 main:app
    ```
    The backend server will typically run on `http://127.0.0.1:5000`.

## Frontend (Flutter)

The frontend is a Flutter application for iOS and Android.

### Setup

1.  **Navigate to the frontend directory:**
    ```bash
    cd app/frontend
    ```
2.  **Ensure you have Flutter SDK installed and configured.** (See [Flutter installation guide](https://flutter.dev/docs/get-started/install))
3.  **Get Flutter packages:**
    ```bash
    flutter pub get
    ```
4.  **Firebase Setup (FlutterFire):**
    - Follow the FlutterFire CLI installation and setup instructions: [FlutterFire Overview](https://firebase.flutter.dev/docs/overview/)
    - Ensure you have `firebase-tools` installed and you are logged in (`firebase login`).
    - Configure your Flutter app for Firebase:
      ```bash
      flutterfire configure
      ```
    - This will typically generate `lib/firebase_options.dart` and update native Firebase configuration files. Make sure the correct `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) are in their respective `app/frontend/android/app/` and `app/frontend/ios/Runner/` directories.

### Running the Frontend Application

1.  **Ensure an emulator is running or a device is connected.** (Check with `flutter devices`)
2.  **Run the app:**
    ```bash
    flutter run
    ```
    To run on a specific device:
    ```bash
    flutter run -d <deviceId>
    ```

## Contributing

[Optional: Add guidelines for contributing to the project, if applicable.]

## License

[Optional: Add license information, e.g., MIT, Apache 2.0.]
