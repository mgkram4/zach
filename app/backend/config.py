import os


class Config:
    UPLOAD_FOLDER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "uploads")
    SECRET_KEY = os.environ.get("SECRET_KEY") or "your-secret-key"
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16 MB max upload size
    FIREBASE_CREDENTIALS = (
        "/Users/mark/Downloads/aivison-225c2-firebase-adminsdk-xtwka-c84f90ec7c.json"
    )
