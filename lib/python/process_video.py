import mediapipe as mp
import cv2
import sys
import os
import subprocess
import json

# Input and output paths from command-line arguments
input_video_path = sys.argv[1]
output_video_path = sys.argv[2]
background_video_path = sys.argv[3]  # New argument for background video

# Check if input and background video files exist
if not os.path.exists(input_video_path):
    print(f"Error: Input video file not found: {input_video_path}")
    sys.exit(1)

if not os.path.exists(background_video_path):
    print(f"Error: Background video file not found: {background_video_path}")
    sys.exit(1)

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

# Check if background video resolution matches the input video
bg_width = int(bg_cap.get(cv2.CAP_PROP_FRAME_WIDTH))
bg_height = int(bg_cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
if bg_width != width or bg_height != height:
    print("Warning: Resizing background video to match input video resolution.")
    resized_bg_path = "resized_background.mp4"
    subprocess.call([
        "ffmpeg", "-y", "-i", background_video_path, "-vf",
        f"scale={width}:{height}", resized_bg_path
    ])
    bg_cap = cv2.VideoCapture(resized_bg_path)
else:
    resized_bg_path = None

# Create a writer for the output video (without audio for now)
temp_video_path = "temp_video.mp4"
out = cv2.VideoWriter(temp_video_path, fourcc, fps, (width, height), True)

# Extract audio from the input video
audio_path = "temp_audio.aac"

def has_audio_stream(video_path):
    try:
        result = subprocess.run(
            [
                "ffprobe", "-v", "error", "-select_streams", "a", "-show_entries",
                "stream=index", "-of", "json", video_path
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        streams = json.loads(result.stdout)
        return bool(streams.get("streams"))
    except Exception as e:
        print(f"Error checking audio stream: {e}")
        return False

if has_audio_stream(input_video_path):
    subprocess.call([
        "ffmpeg", "-y", "-i", input_video_path, "-vn", "-acodec", "aac", audio_path
    ])
else:
    print("No audio stream found in the input video. Adding silent audio.")
    audio_path = "silent_audio.aac"
    subprocess.call([
        "ffmpeg", "-y", "-f", "lavfi", "-i",
        "anullsrc=channel_layout=stereo:sample_rate=44100",
        "-t", str(cap.get(cv2.CAP_PROP_FRAME_COUNT) / fps),
        audio_path
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
if os.path.exists(temp_video_path):
    os.remove(temp_video_path)

if os.path.exists(audio_path):
    os.remove(audio_path)

if resized_bg_path and os.path.exists(resized_bg_path):
    os.remove(resized_bg_path)

print(f"Final video saved as: {output_video_path}")