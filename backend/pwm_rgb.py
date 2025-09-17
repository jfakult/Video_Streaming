import RPi.GPIO as GPIO
import time

# Pin definitions
RED_PIN = 17
GREEN_PIN = 27
BLUE_PIN = 22
FREQ = 100  # Hz for PWM

GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)

# Setup
GPIO.setup(RED_PIN, GPIO.OUT)
GPIO.setup(GREEN_PIN, GPIO.OUT)
GPIO.setup(BLUE_PIN, GPIO.OUT)

# Set up PWM
red_pwm = GPIO.PWM(RED_PIN, FREQ)
green_pwm = GPIO.PWM(GREEN_PIN, FREQ)
blue_pwm = GPIO.PWM(BLUE_PIN, FREQ)

red_pwm.start(0)    # Start OFF for common anode (100% duty = LOW)
green_pwm.start(0)  # Start OFF
blue_pwm.start(0)

# Note: LED is comon annode, use 100-x% for brightness

# r, g, b (0-255), duration to keep on in ms (0 or undefined for no time limit)
def set_color(r, g, b, duration = 0):
    r = 100 * ((255 - r) / 255)
    g = 100 * ((255 - g) / 255)
    b = 100 * ((255 - b) / 255)

    r = 100 - r
    g = 100 - g
    b = 100 - b

    #print("rgb:", r,g,b)

    red_pwm.ChangeDutyCycle(r)     # ON
    green_pwm.ChangeDutyCycle(g) # OFF
    blue_pwm.ChangeDutyCycle(b)     # ON

    if duration > 0:
        time.sleep(duration / 1000)
        red_pwm.ChangeDutyCycle(0)
        green_pwm.ChangeDutyCycle(0)
        blue_pwm.ChangeDutyCycle(0)
