import os
import json
import argparse
from audio_separator.separator import Separator

def process_audio_file(task):
    """
    Processes a single audio file using audio-separator based on the provided task.

    Args:
        task (dict): A dictionary containing task details:
                     - 'input_file': Path to the input audio file.
                     - 'model_name': Name of the model to use (e.g., 'MDXNet', 'Demucs').
                     - 'output_dir': Directory where separated stems will be saved.
                     - 'stems': Optional list of stems to separate (e.g., ['vocals', 'drums']).
                                If not provided, all available stems for the model will be separated.
                     - 'output_format': Optional output format (e.g., 'WAV', 'MP3'). Defaults to 'WAV'.
                     - 'output_bitrate': Optional output bitrate for MP3 (e.g., 320). Defaults to 256.
    """
    input_file = task['input_file']
    model_name = task['model_name']
    output_dir = task['output_dir']
    stems = task.get('stems')
    output_format = task.get('output_format', 'WAV')
    output_bitrate = task.get('output_bitrate', 256)

    if not os.path.exists(input_file):
        print(f"Error: Input file not found: {input_file}")
        return

    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    print(f"Processing '{input_file}' with model '{model_name}'...")

    try:
        separator = Separator(
            log_level="INFO",
            model_name=model_name,
            output_dir=output_dir,
            output_format=output_format,
            output_bitrate=output_bitrate,
            stems=stems
        )
        separator.load_model()
        separator.separate(input_file)
        print(f"Successfully processed '{input_file}'. Output saved to '{output_dir}'")
    except Exception as e:
        print(f"Error processing '{input_file}': {e}")

def load_queue_from_json(file_path):
    """
    Loads the separation queue from a JSON file.

    Args:
        file_path (str): The path to the JSON file containing the queue.

    Returns:
        list: A list of dictionaries representing the separation queue.
    """
    if not os.path.exists(file_path):
        print(f"Error: Queue file not found at {file_path}")
        return []
    try:
        with open(file_path, 'r') as f:
            queue = json.load(f)
        print(f"Successfully loaded queue from {file_path}")
        return queue
    except json.JSONDecodeError as e:
        print(f"Error decoding JSON from {file_path}: {e}")
        return []
    except Exception as e:
        print(f"An unexpected error occurred while reading {file_path}: {e}")
        return []

def main(queue_file_path=None):
    """
    Main function to define and run the audio separation queue.
    """
    if queue_file_path:
        separation_queue = load_queue_from_json(queue_file_path)
    else:
        # Default hardcoded queue if no file is provided
        separation_queue = [
            {
                'input_file': 'path/to/your/audio1.mp3',
                'model_name': 'MDXNet',
                'output_dir': 'output/audio1_stems',
                'stems': None, # Separate all stems
                'output_format': 'WAV'
            },
            {
                'input_file': 'path/to/your/audio2.wav',
                'model_name': 'Demucs',
                'output_dir': 'output/audio2_drums_only',
                'stems': ['drums'], # Separate only drums
                'output_format': 'MP3',
                'output_bitrate': 320
            },
            # Add more tasks as needed
        ]

    if not separation_queue:
        print("The separation queue is empty. Please add tasks to process.")
        return

    print(f"Starting audio separation queue with {len(separation_queue)} tasks...")
    for i, task in enumerate(separation_queue):
        print(f"\n--- Task {i + 1}/{len(separation_queue)} ---")
        process_audio_file(task)

    print("\nAll tasks in the queue have been processed.")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Process a queue of audio files for stem separation.")
    parser.add_argument(
        '-q', '--queue-file',
        type=str,
        help="Path to a JSON file containing the audio separation queue."
    )
    args = parser.parse_args()

    main(queue_file_path=args.queue_file)
