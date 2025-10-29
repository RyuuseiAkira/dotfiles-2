import subprocess
import time

def check_webcam_status():
  with open('/sys/devices/platform/msi-ec/webcam', 'r') as f:
    webcam_status = f.read().strip()
  return webcam_status == 'on'

def main():
  blink_script = '/home/akira/.config/hyde/themes/Akira/Scripts/led_blink.sh'
  while True:
    if check_webcam_status():
      subprocess.run([blink_script, 'start'])
    else:
      subprocess.run([blink_script, 'stop'])
    time.sleep(5)

if __name__ == '__main__':
  main()