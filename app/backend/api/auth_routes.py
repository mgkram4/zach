from database.firestore_manager import add_user
from firebase_admin import auth
from flask import Blueprint, jsonify, request

auth_bp = Blueprint("auth_bp", __name__)


@auth_bp.route("/signup", methods=["POST"])
def signup():
    data = request.json
    email = data.get("email")
    password = data.get("password")

    try:
        # Create user in Firebase Authentication
        user = auth.create_user(email=email, password=password)

        # Prepare user data to store in Firestore
        user_data = {
            "uid": user.uid,
            "email": email,
            "total_shots": 0,
            "streak": 0,
            "player_counts": {},
        }

        # Add user data to Firestore
        add_user(user_data)

        # Log success message to console
        print(f"User {user.uid} added to Firestore successfully")

        # Return success message with user UID
        return jsonify({"message": "User created successfully", "uid": user.uid}), 201

    except Exception as e:
        # Log failure message to console
        print(f"Failed to create user: {str(e)}")

        # Handle any errors during user creation
        return jsonify({"error": str(e)}), 400


@auth_bp.route("/signin", methods=["POST"])
def signin():
    data = request.json
    email = data.get("email")
    password = data.get("password")

    try:
        # Verify the user credentials
        user = auth.get_user_by_email(email)
        # You might want to add password verification here if not using Firebase Authentication
        return (
            jsonify({"message": "User authenticated successfully", "uid": user.uid}),
            200,
        )
    except Exception as e:
        return jsonify({"error": str(e)}), 400
