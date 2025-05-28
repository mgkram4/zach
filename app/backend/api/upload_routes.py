import os
import random
import sys

from flask import Blueprint, current_app, jsonify, request, url_for
from ml.analyze_shot import analyze_user_shot, calculator
from werkzeug.utils import secure_filename


def create_upload_bp(calculator):
    upload_bp = Blueprint("upload_bp", __name__)

    @upload_bp.route("", methods=["POST"])
    def upload_media():
        print("Received analyze request")
        try:
            player = request.form.get("player", "").strip()

            print(f"Received player: {player}")

            if not player:
                print("Player name is missing or empty")
                return jsonify({"error": "Player name is required"}), 400

            if "file" not in request.files:
                print("No file part in the request")
                return jsonify({"error": "No file part"}), 400

            file = request.files["file"]

            if file.filename == "":
                print("No selected file")
                return jsonify({"error": "No selected file"}), 400

            if file and allowed_file(file.filename):
                filename = secure_filename(file.filename)
                upload_folder = current_app.config["UPLOAD_FOLDER"]

                # Ensure the upload folder exists
                os.makedirs(upload_folder, exist_ok=True)

                file_path = os.path.join(upload_folder, filename)
                file.save(file_path)
                print(f"File saved to {file_path}")

                print("Starting analysis...")
                analysis_result = analyze_user_shot(file_path, calculator, player)
                print("Analysis completed")
                print(f"Analysis result: {analysis_result}")

                if "error" in analysis_result:
                    return jsonify(analysis_result), 400

                response_data = {
                    "message": "File uploaded and analyzed successfully",
                    "shot_id": f"shot_{random.randint(1000, 9999)}",
                    **analysis_result,
                }

                print(f"Sending response: {response_data}")
                return jsonify(response_data), 200

            print("File type not allowed")
            return jsonify({"error": "File type not allowed"}), 400
        except Exception as e:
            print(f"Unexpected error in analyze_shot: {str(e)}")
            return jsonify({"error": f"An unexpected error occurred: {str(e)}"}), 500

    return upload_bp


def allowed_file(filename):
    ALLOWED_EXTENSIONS = {"png", "jpg", "jpeg", "gif"}
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS
