import os
import random
import sys

import cv2
from flask import Blueprint, Flask, current_app, jsonify, request, url_for
from ml.analyze_shot import analyze_user_shot, calculator
from werkzeug.utils import secure_filename

app = Flask(__name__)
app.config["UPLOAD_FOLDER"] = "uploads"

@app.route("/")
def hello_world():
    return "Hello, World!"

def create_upload_bp(calculator):
    upload_bp = Blueprint("upload_bp", __name__)

    @upload_bp.route("", methods=["POST"])
    def upload_media():
        print("Received analyze request")
        try:
            player = request.form.get("player", "").strip()
            is_video = request.form.get("is_video", "false").lower() == "true"

            print(f"Received player: {player}")
            print(f"Is video: {is_video}")

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
                if is_video:
                    analysis_result = process_video(file_path, calculator, player)
                else:
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
    ALLOWED_EXTENSIONS = {"png", "jpg", "jpeg", "gif", "mp4", "mov", "avi"}
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS

def process_video(video_path, calculator, player):
    try:
        cap = cv2.VideoCapture(video_path)
        frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        fps = int(cap.get(cv2.CAP_PROP_FPS))
        
        # Process every 30th frame or adjust as needed
        interval = 30
        results = []
        
        for i in range(0, frame_count, interval):
            cap.set(cv2.CAP_PROP_POS_FRAMES, i)
            ret, frame = cap.read()
            if ret:
                # Save frame as temporary image
                temp_image_path = f"temp_frame_{i}.jpg"
                cv2.imwrite(temp_image_path, frame)
                
                try:
                    # Analyze the frame
                    frame_result = analyze_user_shot(temp_image_path, calculator, player)
                    if 'similarity_score' not in frame_result:
                        print(f"Warning: similarity_score not found in frame result for frame {i}")
                        continue
                    results.append(frame_result)
                except Exception as e:
                    print(f"Error analyzing frame {i}: {str(e)}")
                finally:
                    # Remove temporary image
                    os.remove(temp_image_path)
        
        cap.release()
        
        if not results:
            return {"error": "No valid frames could be analyzed in the video"}
        
        # Aggregate results
        valid_scores = [r['similarity_score'] for r in results if 'similarity_score' in r]
        if not valid_scores:
            return {"error": "No valid similarity scores found in the video analysis"}
        
        final_result = {
            "average_similarity_score": sum(valid_scores) / len(valid_scores),
            "frame_results": results
        }
        
        return final_result
    except Exception as e:
        print(f"Error in process_video: {str(e)}")
        return {"error": f"An error occurred while processing the video: {str(e)}"}

app.register_blueprint(create_upload_bp(calculator), url_prefix="/upload")

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=8000)