# import mediapipe as mp
# import cv2
# import sys
# import os

# # Input and output paths from command-line arguments
# input_video_path = sys.argv[1]
# output_video_path = sys.argv[2]

# # Initialize Mediapipe modules
# mp_selfie_segmentation = mp.solutions.selfie_segmentation
# segmentation = mp_selfie_segmentation.SelfieSegmentation(model_selection=1)

# # Open the input video
# cap = cv2.VideoCapture(input_video_path)
# fps = int(cap.get(cv2.CAP_PROP_FPS))
# width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
# height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
# fourcc = cv2.VideoWriter_fourcc(*'mp4v')

# # Create a writer for the output video
# out = cv2.VideoWriter(output_video_path, fourcc, fps, (width, height), True)
# print(f'Mediapipe version: {mp.__version__}')
# while cap.isOpened():
#     ret, frame = cap.read()
#     if not ret:
#         break

#     # Apply segmentation
#     results = segmentation.process(frame)
#     mask = results.segmentation_mask
#     mask = (mask > 0.1).astype('uint8') * 255

#     # Create transparent background
#     bg_removed = cv2.bitwise_and(frame, frame, mask=mask)

#     # Write the processed frame
#     out.write(bg_removed)

# cap.release()
# out.release()
# import mediapipe as mp
# import cv2
# import sys
# import os
# import subprocess

# # Input and output paths from command-line arguments
# input_video_path = sys.argv[1]
# output_video_path = sys.argv[2]

# # Initialize Mediapipe modules
# mp_selfie_segmentation = mp.solutions.selfie_segmentation
# segmentation = mp_selfie_segmentation.SelfieSegmentation(model_selection=1)

# # Open the input video
# cap = cv2.VideoCapture(input_video_path)
# fps = int(cap.get(cv2.CAP_PROP_FPS))
# width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
# height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
# fourcc = cv2.VideoWriter_fourcc(*'mp4v')

# # Create a writer for the output video (without audio for now)
# temp_video_path = "temp_video.mp4"
# out = cv2.VideoWriter(temp_video_path, fourcc, fps, (width, height), True)
# print(f'Mediapipe version: {mp.__version__}')

# # Extract audio from the input video
# audio_path = "temp_audio.aac"
# subprocess.call([
#     "ffmpeg", "-y", "-i", input_video_path, "-vn", "-acodec", "aac", audio_path
# ])

# # Process video frames
# while cap.isOpened():
#     ret, frame = cap.read()
#     if not ret:
#         break

#     # Apply segmentation
#     results = segmentation.process(frame)
#     mask = results.segmentation_mask
#     mask = (mask > 0.1).astype('uint8') * 255

#     # Create transparent background
#     bg_removed = cv2.bitwise_and(frame, frame, mask=mask)

#     # Write the processed frame
#     out.write(bg_removed)

# cap.release()
# out.release()

# # Combine the processed video and the original audio
# subprocess.call([
#     "ffmpeg", "-y", "-i", temp_video_path, "-i", audio_path, "-c:v", "libx264", "-c:a", "aac",
#     "-strict", "experimental", "-shortest", output_video_path
# ])

# # Clean up temporary files
# os.remove(temp_video_path)
# os.remove(audio_path)

# print(f"Final video saved as: {output_video_path}")

import mediapipe as mp
import cv2
import sys
import os
import subprocess

# Input and output paths from command-line arguments
input_video_path = sys.argv[1]
output_video_path = sys.argv[2]
background_video_path = sys.argv[3]  # New argument for background video

# Initialize Mediapipe modules
mp_selfie_segmentation = mp.solutions.selfie_segmentation
segmentation = mp_selfie_segmentation.SelfieSegmentation(model_selection=1)

# Open the input video
cap = cv2.VideoCapture(input_video_path)
fps = int(cap.get(cv2.CAP_PROP_FPS))
width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
fourcc = cv2.VideoWriter_fourcc(*'mp4v')

# Open the background video
bg_cap = cv2.VideoCapture(background_video_path)
bg_width = int(bg_cap.get(cv2.CAP_PROP_FRAME_WIDTH))
bg_height = int(bg_cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

# Ensure background video has the same size as the input video
if bg_width != width or bg_height != height:
    print("Background video resolution does not match the input video resolution.")
    # Resize background to match the input video resolution
    bg_cap = cv2.VideoCapture(background_video_path)
    bg_cap.set(cv2.CAP_PROP_FRAME_WIDTH, width)
    bg_cap.set(cv2.CAP_PROP_FRAME_HEIGHT, height)

# Create a writer for the output video (without audio for now)
temp_video_path = "temp_video.mp4"
out = cv2.VideoWriter(temp_video_path, fourcc, fps, (width, height), True)
print(f'Mediapipe version: {mp.__version__}')

# Extract audio from the input video
audio_path = "temp_audio.aac"
subprocess.call([
    "ffmpeg", "-y", "-i", input_video_path, "-vn", "-acodec", "aac", audio_path
])

# Process video frames
while cap.isOpened() and bg_cap.isOpened():
    ret, frame = cap.read()
    bg_ret, background_frame = bg_cap.read()

    if not ret or not bg_ret:
        break

    # Apply segmentation
    results = segmentation.process(frame)
    mask = results.segmentation_mask
    mask = (mask > 0.1).astype('uint8') * 255

    # Resize background frame to match the video size
    background_frame = cv2.resize(background_frame, (width, height))

    # Create the foreground by applying the mask
    fg = cv2.bitwise_and(frame, frame, mask=mask)

    # Create the background by inverting the mask and applying it to the background
    inverted_mask = cv2.bitwise_not(mask)
    bg = cv2.bitwise_and(background_frame, background_frame, mask=inverted_mask)

    # Combine the foreground and background
    final_frame = cv2.add(fg, bg)

    # Write the processed frame
    out.write(final_frame)

cap.release()
bg_cap.release()
out.release()

# Combine the processed video and the original audio
subprocess.call([
    "ffmpeg", "-y", "-i", temp_video_path, "-i", audio_path, "-c:v", "libx264", "-c:a", "aac",
    "-strict", "experimental", "-shortest", output_video_path
])

# Clean up temporary files
os.remove(temp_video_path)
os.remove(audio_path)

print(f"Final video saved as: {output_video_path}")