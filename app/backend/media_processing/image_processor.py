import cv2
import mediapipe as mp
import numpy as np

mp_pose = mp.solutions.pose
mp_drawing = mp.solutions.drawing_utils


def extract_pose_landmarks(image_path):
    image = cv2.imread(image_path)
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    with mp_pose.Pose(static_image_mode=True, min_detection_confidence=0.5) as pose:
        results = pose.process(image_rgb)

    if results.pose_landmarks:
        landmarks = np.array(
            [[lm.x, lm.y, lm.z] for lm in results.pose_landmarks.landmark]
        )
        return landmarks
    else:
        return None
