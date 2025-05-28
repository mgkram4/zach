from flask import Blueprint, jsonify
from database.firestore_manager import get_user

stats_bp = Blueprint("stats", __name__)


@stats_bp.route("/<user_id>", methods=["GET"])
def get_user_stats(user_id):
    user_data = get_user(user_id)
    if user_data:
        stats = {
            "total_shots": user_data.get("total_shots", 0),
            "streak": user_data.get("streak", 0),
            "player_counts": user_data.get("player_counts", {}),
        }
        return jsonify(stats), 200
    return jsonify({"error": "User not found"}), 404
