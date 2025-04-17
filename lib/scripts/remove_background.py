import numpy as np
from moviepy.editor import VideoFileClip
import mediapipe as mp
import cv2
import numba

def remove_background(input_path, output_path):
    # Initialize MediaPipe Selfie Segmentation with more precise model
    # Use GPU acceleration if available
    selfie_segmentation = mp.solutions.selfie_segmentation.SelfieSegmentation(model_selection=1)
    
    # Pre-create arrays and kernels to avoid reallocating memory
    kernel = np.ones((5,5), np.uint8)
    green_bg = np.zeros((720, 720, 3), dtype=np.uint8)  # Adjust size based on your typical video resolution
    green_bg[:, :] = [0, 255, 0]  # BGR format: pure green

    @numba.jit(nopython=True)
    def blend_frames(frame, mask_3channel, green_bg):
        return frame * mask_3channel + green_bg * (1 - mask_3channel)

    def process_frame(frame):
        try:
            # Resize frame if needed for faster processing
            height, width = frame.shape[:2]
            if height > 720 or width > 720:
                scale = 720 / max(height, width)
                frame = cv2.resize(frame, None, fx=scale, fy=scale)

            # Convert frame to RGB (MediaPipe expects RGB)
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            
            # Get segmentation mask
            results = selfie_segmentation.process(frame_rgb)
            
            if results.segmentation_mask is not None:
                # Convert mask to proper format with lower threshold for better detail
                mask = (results.segmentation_mask > 0.2).astype(np.uint8) * 255
                
                # Apply morphological operations to improve mask
                mask = cv2.dilate(mask, kernel, iterations=1)
                mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)
                
                # Create 3-channel mask more efficiently
                mask_3channel = np.stack([mask] * 3, axis=-1).astype(np.float32) / 255.0
                
                # Ensure green_bg matches frame size
                if green_bg.shape != frame.shape:
                    green_bg_resized = cv2.resize(green_bg, (frame.shape[1], frame.shape[0]))
                else:
                    green_bg_resized = green_bg
                
                # Blend frames using numba-accelerated function
                result = blend_frames(frame.astype(np.float32), mask_3channel, green_bg_resized.astype(np.float32))
                
                # Convert back to uint8
                result = result.astype(np.uint8)
                
                # Apply binary mask for clean edges
                mask_binary = (mask_3channel > 0.1)
                result = np.where(mask_binary, result, green_bg_resized)
                
                return result
            else:
                print("No segmentation mask generated")
                return frame
                
        except Exception as e:
            print(f"Error processing frame: {str(e)}")
            return frame
        
    try:
        # Load video with audio
        video_clip = VideoFileClip(input_path)
        
        # Process each frame
        processed_clip = video_clip.fl_image(process_frame)
        
        # Write output video with optimized encoding parameters
        processed_clip.write_videofile(
            output_path,
            codec='libx264',
            audio=True,
            audio_codec='aac',
            fps=30,  # Set consistent frame rate
            threads=8,  # Use multiple threads for processing
            ffmpeg_params=[
                '-preset', 'veryfast',      # Faster encoding
                '-tune', 'zerolatency',     # Minimize latency
                '-crf', '23',               # Good balance of quality and size
                '-movflags', '+faststart',  # Optimize for web playback
                '-c:a', 'aac',             # Audio codec
                '-ac', '2',                # Stereo audio
                '-b:a', '128k',            # Audio bitrate
            ],
        )
        
        # Close clips
        video_clip.close()
        processed_clip.close()
        
        return True
    except Exception as e:
        print(f"Error processing video: {str(e)}")
        return False

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 3:
        print("Usage: python remove_background.py input_video.mp4 output_video.mp4")
        sys.exit(1)
    
    input_path = sys.argv[1]
    output_path = sys.argv[2]
    remove_background(input_path, output_path)