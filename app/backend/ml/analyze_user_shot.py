import os
import sys

# Add the parent directory to sys.path
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
sys.path.append(parent_dir)

from analyze_shot import analyze_user_shot, process_pro_players

# Set up paths
pro_dir = os.path.join(current_dir, "pro_players")
pro_poses_file = os.path.join(current_dir, "pro_poses.npy")

# Initialize the calculator
try:
    calculator = process_pro_players(pro_dir, pro_poses_file)
    print("Calculator initialized successfully.")
except Exception as e:
    print(f"Error initializing calculator: {str(e)}")
    sys.exit(1)

# Test the analysis
test_image_path = os.path.join(
    current_dir, "test.png"
)  # Replace with your test image path
if os.path.exists(test_image_path):
    try:
        result = analyze_user_shot(test_image_path, calculator)
        print("Analysis result:")
        print(result)
    except Exception as e:
        print(f"Error during analysis: {str(e)}")
else:
    print(f"Test image not found at {test_image_path}")
    print(
        "Please place a test image in the 'ml' directory or update the path in the script."
    )
