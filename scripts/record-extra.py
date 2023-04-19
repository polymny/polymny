#!./.venv/bin/python
import argparse
import subprocess
import os
from rich_argparse import RawDescriptionRichHelpFormatter


last_record_time = 0.0
last_extra_time = 0.0


def event_str_to_dict(event_str: str) -> dict:
    """Convert an event string to a dictionary.

    Args:
        event_str (str): Event string.

    Returns:
        dict: Event dictionary.
    """
    global last_record_time, last_extra_time

    event = event_str.split('-')

    record_time = float(event[0])
    action = event[1]
    if len(event) == 3:
        extra_time = float(event[2])
    else:
        extra_time = last_extra_time + (record_time - last_record_time)

    last_extra_time = extra_time
    last_record_time = record_time

    return {
        'record_time': record_time,
        'action': action,
        'extra_time': extra_time,
    }


def main(args) -> None:
    """Produce a video where it have been recorded on an extra video track.

    Events is a list of strings with the format:
        record_time-action-extra_time
    Where:
        record_time: time in seconds when the event was recorded.
        action: action performed. (play, pause)
        extra_time: time in seconds when the action was performed on the extra video.
                    (optional if action is pause)

    If during the recording the extra video ended, it should add a pause event with
    the extra time equal to the duration of the extra video.

    At the end of the recording, it should add a pause event with the current time
    of the recording.

    Event examples:
        0.0-play-0.0 (play)
        1.0-pause (seeking)
        2.0-play-1.0 (seek)
        3.0-pause-2.0 (pause)
        4.0-play-1.0 (jump)
        6.0-pause (end)

    Args:
        args (argparse.Namespace): Arguments.
    """
    video_path = args.input
    output_path = args.output
    events = eval(args.events)
    print("events before:")
    for event in events:
        print(event)
    events = [event_str_to_dict(event) for event in events]
    print("events after:")
    for event in events:
        print(event)
    print("ffmpeg commands:")
    # for i in range(len(events)-1):
    #     if events[i]['action'] == 'play':
    #         print(f"Play: record dtime = {events[i+1]['record_time'] - events[i]['record_time']}, extra dtime = {events[i+1]['extra_time'] - events[i]['extra_time']}")
    # exit()

    # Get the frame rate of the extra video
    cmd = ['ffprobe', '-i', video_path, '-show_entries', 'stream=avg_frame_rate', '-v', 'quiet', '-of', 'csv=p=0']
    frame_rate = float(subprocess.check_output(cmd).decode('utf-8').split('/')[0])

    # Get the duration of the extra video.
    cmd = ['ffprobe', '-i', video_path, '-show_entries', 'format=duration', '-v', 'quiet', '-of', 'csv=p=0']
    extra_duration = float(subprocess.check_output(cmd).decode('utf-8'))

    # Get subclips of the extra video for each event.
    tmp_files = []
    for i in range(len(events) - 1):
        current_event = events[i]
        next_event = events[i+1]

        # Extract the subclip from the extra video.
        if current_event["action"] == "play":
            start_time = current_event["extra_time"]
            clip_duration = next_event["record_time"] - current_event["record_time"]

            # Generate temporary files.
            tmp_file = subprocess.check_output(['mktemp', '--suffix=.mp4']).decode("utf-8").strip()
            tmp_files.append(tmp_file)

            # Produce the subclip.
            cmd = ['ffmpeg', '-y', '-loglevel', 'error', '-i', video_path,
                   '-ss', str(start_time), '-t', str(clip_duration), tmp_file]
            print(' '.join(cmd))
            subprocess.run(cmd)

        # Create a subclip from a frame.
        elif current_event["action"] == "pause":
            frame_time = min(current_event["extra_time"], extra_duration - 1.0 / frame_rate)
            clip_duration = next_event["record_time"] - current_event["record_time"]

            # Generate temporary files.
            tmp_file = subprocess.check_output(['mktemp', '--suffix=.mp4']).decode("utf-8").strip()
            tmp_files.append(tmp_file)
            tmp_image = subprocess.check_output(['mktemp', '--suffix=.jpg']).decode("utf-8").strip()

            # Extract the frame from the extra video.
            cmd = ['ffmpeg', '-y', '-loglevel', 'error', '-ss',
                   str(frame_time), '-i', video_path, '-frames:v', '1', '-q:v', '2', tmp_image]
            print(' '.join(cmd))
            subprocess.run(cmd)
            # Create a video from the frame.
            cmd = ['ffmpeg', '-y', '-loglevel', 'error', '-loop', '1', '-i', tmp_image, '-t',
                   str(clip_duration), '-pix_fmt', 'yuv420p', '-r', str(frame_rate), tmp_file]
            print(' '.join(cmd))
            subprocess.run(cmd)
            # Remove the temporary image.
            os.remove(tmp_image)

    # Create concat file.
    concat_file = subprocess.check_output(['mktemp', '--suffix=.txt']).decode("utf-8").strip()
    with open(concat_file, 'w') as f:
        for tmp_file in tmp_files:
            f.write(f"file '{tmp_file}'\n")

    # Concatenate the subclips.
    cmd = ['ffmpeg', '-y', '-loglevel', 'error', '-f', 'concat',
           '-safe', '0', '-i', concat_file, output_path]
    print(' '.join(cmd))
    subprocess.run(cmd)

    # Remove the temporary files.
    os.remove(concat_file)
    for tmp_file in tmp_files:
        os.remove(tmp_file)


if __name__ == '__main__':

    # Parse arguments.
    parser = argparse.ArgumentParser(formatter_class=RawDescriptionRichHelpFormatter,
                                     description="""
    Produce a video where it have been recorded on an extra video track.

    Events is a list of strings with the format:
        record_time-action-extra_time
    Where:
        record_time: time in seconds when the event was recorded.
        action: action performed. (play, pause)
        extra_time: time in seconds when the action was performed on the extra video.
                    (optional if action is pause)

    If during the recording the extra video ended, it should add a pause event with
    the extra time equal to the duration of the extra video.

    At the end of the recording, it should add a pause event with the current time
    of the recording.

    Event examples:
        0.0-play-0.0 (play)
        1.0-pause (seeking)
        2.0-play-1.0 (seek)
        3.0-pause-2.0 (pause)
        4.0-play-1.0 (jump)
        6.0-pause (end)"""
                                     )
    parser.add_argument('--input',
                        '-i',
                        action='store',
                        dest='input',
                        required=True,
                        help='extra video file',
                        metavar='INPUT',
                        type=str)
    parser.add_argument('--output',
                        '-o',
                        action='store',
                        dest='output',
                        required=True,
                        help='output file',
                        metavar='OUTPUT',
                        type=str)
    parser.add_argument('--events',
                        '-e',
                        action='store',
                        dest='events',
                        required=True,
                        help='events',
                        metavar='EVENTS',
                        type=str)
    args = parser.parse_args()

    # Run main.
    main(args)
