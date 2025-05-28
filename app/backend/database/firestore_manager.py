import firebase_admin
from config import Config
from firebase_admin import credentials, firestore

db = None


def initialize_firestore():
    global db
    if db is not None:
        return db

    try:
        # Try to get an existing app
        firebase_app = firebase_admin.get_app()
    except ValueError:
        # If no app exists, initialize a new one
        cred = credentials.Certificate(Config.FIREBASE_CREDENTIALS)
        firebase_app = firebase_admin.initialize_app(cred)
        print("New Firebase app initialized")
    else:
        print("Existing Firebase app found")

    db = firestore.client(app=firebase_app)
    return db


def get_db():
    global db
    if db is None:
        db = initialize_firestore()
    return db


def generate_document_id(user_id):
    # Replace invalid characters with underscores
    return user_id.replace("/", "_").replace(".", "_")


def add_user(user_data):
    user_ref = (
        get_db().collection("users").document(generate_document_id(user_data["uid"]))
    )
    user_ref.set(user_data)


def get_user(user_id):
    user_ref = get_db().collection("users").document(user_id)
    return user_ref.get().to_dict()


def update_user_stats(user_id, stats_update):
    document_id = generate_document_id(user_id)
    user_ref = get_db().collection("users").document(document_id)
    user_ref.update(stats_update)


def add_shot_analysis(user_id, analysis_data, image_url):
    document_id = generate_document_id(user_id)
    shot_ref = (
        get_db()
        .collection("users")
        .document(document_id)
        .collection("shots")
        .document()
    )
    analysis_data["image_url"] = image_url
    shot_ref.set(analysis_data)
    return shot_ref.id
