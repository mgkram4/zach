import os
import sys

import numpy as np
from scipy.spatial.distance import cosine

# Add media_processing directory to the path for import
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from media_processing.image_processor import extract_pose_landmarks


class PoseSimilarityCalculator:
    def __init__(self):
        self.pro_poses = {}

    def add_pro_pose(self, player_name, landmarks):
        if player_name not in self.pro_poses:
            self.pro_poses[player_name] = []
        self.pro_poses[player_name].append(landmarks)

    def calculate_similarity(self, user_landmarks, player_name=None):
        user_landmarks = np.asarray(user_landmarks).flatten()
        if player_name and player_name in self.pro_poses:
            poses = self.pro_poses[player_name]
            similarities = [
                1 - cosine(user_landmarks, pro_landmarks.flatten())
                for pro_landmarks in poses
            ]
            return max(similarities)
        else:
            similarities = {}
            for player, poses in self.pro_poses.items():
                player_similarities = [
                    1 - cosine(user_landmarks, pro_landmarks.flatten())
                    for pro_landmarks in poses
                ]
                similarities[player] = max(player_similarities)
            return similarities

    def get_angle_differences(self, user_landmarks, player_name):
        user_landmarks = np.asarray(user_landmarks).reshape(-1, 3)
        best_pro_pose = max(
            self.pro_poses[player_name],
            key=lambda x: 1 - cosine(user_landmarks.flatten(), x.flatten()),
        )
        best_pro_pose = np.asarray(best_pro_pose).reshape(-1, 3)

        angle_diffs = {}
        key_joints = [
            ("Elbow", 13, 11, 15),  # Right elbow
            ("Shoulder", 11, 13, 23),  # Right shoulder
            ("Knee", 25, 23, 27),  # Right knee
            ("Hip", 23, 25, 11),  # Right hip
        ]

        for joint_name, p1, p2, p3 in key_joints:
            user_angle = calculate_angle(
                user_landmarks[p1], user_landmarks[p2], user_landmarks[p3]
            )
            pro_angle = calculate_angle(
                best_pro_pose[p1], best_pro_pose[p2], best_pro_pose[p3]
            )
            angle_diffs[joint_name] = pro_angle - user_angle

        return angle_diffs

    def save_pro_poses(self, filename):
        np.save(filename, self.pro_poses)
        print(f"Pro poses saved to {filename}")

    def load_pro_poses(self, filename):
        try:
            self.pro_poses = np.load(filename, allow_pickle=True).item()
            print(f"Pro poses loaded from {filename}")
        except FileNotFoundError:
            print(
                f"Error: The file '{filename}' was not found in the current directory."
            )
            print(f"Current directory: {os.getcwd()}")
            print(
                "Please ensure the file exists or run the process_pro_players function first."
            )
            raise


def calculate_angle(p1, p2, p3):
    v1 = p1 - p2
    v2 = p3 - p2
    angle = np.arccos(np.dot(v1, v2) / (np.linalg.norm(v1) * np.linalg.norm(v2)))
    return np.degrees(angle)


def process_pro_players(pro_dir, output_file):
    if os.path.exists(output_file):
        print(f"{output_file} already exists. Loading existing poses...")
        calculator = PoseSimilarityCalculator()
        calculator.load_pro_poses(output_file)
        return calculator

    calculator = PoseSimilarityCalculator()
    print(f"Processing pro players from directory: {pro_dir}")
    for player in os.listdir(pro_dir):
        player_dir = os.path.join(pro_dir, player)
        if not os.path.isdir(player_dir):
            continue
        print(f"Processing player: {player}")
        for image_name in os.listdir(player_dir):
            image_path = os.path.join(player_dir, image_name)
            print(f"Processing image: {image_path}")
            landmarks = extract_pose_landmarks(image_path)
            if landmarks is not None:
                calculator.add_pro_pose(player, landmarks)
            else:
                print(f"No landmarks detected for image: {image_path}")

    calculator.save_pro_poses(output_file)
    return calculator


def analyze_user_shot(image_path, calculator, player_name="Lebron"):
    try:
        user_landmarks = extract_pose_landmarks(image_path)
        if user_landmarks is None:
            return {"error": "Failed to extract pose landmarks from the image"}

        user_landmarks = np.asarray(user_landmarks)

        # Make the player name check case-insensitive
        player_name_lower = player_name.lower()
        available_players = list(calculator.pro_poses.keys())
        matching_player = next(
            (p for p in available_players if p.lower() == player_name_lower), None
        )

        if not matching_player:
            return {
                "error": f"Player '{player_name}' not found in the database",
                "available_players": available_players,
            }

        similarity_score = calculator.calculate_similarity(
            user_landmarks, matching_player
        )
        angle_differences = calculator.get_angle_differences(
            user_landmarks, matching_player
        )

        suggestions = []
        for joint, diff in angle_differences.items():
            if abs(diff) > 10:  # Threshold for suggesting adjustments
                direction = "increase" if diff > 0 else "decrease"
                suggestions.append(
                    f"{direction} {joint.lower()} angle by about {abs(diff):.1f} degrees"
                )

        return {
            "player": matching_player,
            "similarity_score": similarity_score,
            "angle_differences": angle_differences,
            "suggestions": suggestions,
        }

    except Exception as e:
        print(f"Error analyzing user shot: {e}")
        return {"error": f"An error occurred while analyzing the user shot: {str(e)}"}


def generate_user_friendly_response(result):
    if "error" in result:
        return f"Error: {result['error']}"

    response = f"""
Analysis Results (Compared to {result['player']}):

Similarity Score: {result['similarity_score']:.2%}

Angle Differences:
- Elbow: {result['angle_differences']['Elbow']:.2f} degrees
- Shoulder: {result['angle_differences']['Shoulder']:.2f} degrees
- Knee: {result['angle_differences']['Knee']:.2f} degrees
- Hip: {result['angle_differences']['Hip']:.2f} degrees

General Angle Adjustment Advice:
- Elbow: Aim for a 90-degree angle at the set point. Adjust if significantly different.
- Shoulder: Keep it relaxed and aligned with your body. Small adjustments can have a big impact.
- Knee: Bend for power, typically around 115-125 degrees. Adjust based on your shooting style.
- Hip: Maintain a slight bend for balance. Adjust if you're leaning too far forward or backward.

"""

    if result["suggestions"]:
        response += "Specific Suggestions for Improvement:\n"
        for suggestion in result["suggestions"]:
            response += f"- {suggestion}\n"
    else:
        response += "Great job! Your form is very similar to the pro player. Keep up the good work!\n"

    return response


# Initialize the calculator
current_dir = os.path.dirname(os.path.abspath(__file__))
pro_dir = os.path.join(current_dir, "pro_players")
pro_poses_file = os.path.join(current_dir, "pro_poses.npy")

calculator = process_pro_players(pro_dir, pro_poses_file)

# This line ensures that the 'calculator' object is available when imported
__all__ = ["analyze_user_shot", "calculator"]

if __name__ == "__main__":
    print("Current working directory:", os.getcwd())

    test_image_path = os.path.join(
        current_dir, "test_image.jpg"
    )  # Replace with your test image path
    if os.path.exists(test_image_path):
        result = analyze_user_shot(test_image_path, calculator, "Lebron")
        print("Analysis result (raw):")
        print(result)

        print("\nUser-friendly analysis:")
        print(generate_user_friendly_response(result))
    else:
        print(f"Test image not found at {test_image_path}")
        print(
            "Please place a test image in the 'ml' directory or update the path in the script."
        )
