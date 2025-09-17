import subprocess
import sys
import signal

MEDIAMTX_PATH = "/home/pi/Video_Streaming/"  # Adjust path as necessary


# Pass through Ctrl+C to child process
def handle_sigint(sig, frame):
    if process.poll() is None:
        process.terminate()
signal.signal(signal.SIGINT, handle_sigint)

# Start mediamtx
process = subprocess.Popen(
    [MEDIAMTX_PATH + "mediamtx", MEDIAMTX_PATH + "mediamtx.yml"],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    bufsize=1
)

# Stream mediamtx output
try:
    for line in process.stdout:
        print(line, end="")
finally:
    process.wait()
    sys.exit(process.returncode)