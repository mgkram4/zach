from config import Config
from database.firestore_manager import add_shot_analysis, update_user_stats
from flask import Blueprint, jsonify, request
from media_processing import image_processor, video_processor
from werkzeug.utils import secure_filename

upload_bp = Blueprint("upload", __name__)

ALLOWED_EXTENSIONS = {"png", "jpg", "jpeg", "gif", "mp4", "mov", "avi"}


def allowed_file(filename):
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS


@upload_bp.route("/", methods=["POST"])
def upload_media():
    if "file" not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files["file"]
    user_id = request.form.get("user_id")
    target_player = request.form.get("target_player")

    if not target_player:
        return jsonify({"error": "No target player specified"}), 400

    if file.filename == "":
        return jsonify({"error": "No selected file"}), 400

    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        file_path = os.path.join(Config.UPLOAD_FOLDER, filename)
        file.save(file_path)

        if file.filename.lower().endswith((".png", ".jpg", ".jpeg", ".gif")):
            analysis_result = image_processor.analyze(file_path, target_player)
        elif file.filename.lower().endswith((".mp4", ".mov", ".avi")):
            analysis_result = video_processor.analyze(file_path, target_player)
        else:
            return jsonify({"error": "Unsupported file type"}), 400

        # Update user stats
        update_user_stats(
            user_id,
            {
                "total_shots": firestore.Increment(1),
                "streak": firestore.Increment(1),
                f"player_counts.{target_player}": firestore.Increment(1),
            },
        )

        # Add shot analysis to user's history
        shot_id = add_shot_analysis(
            user_id,
            {
                "file_path": file_path,
                "target_player": target_player,
                "analysis_result": analysis_result,
                "timestamp": firestore.SERVER_TIMESTAMP,
            },
        )

        return (
            jsonify(
                {
                    "message": "File uploaded and analyzed successfully",
                    "shot_id": shot_id,
                    "analysis": analysis_result,
                }
            ),
            200,
        )

    return jsonify({"error": "File type not allowed"}), 400
