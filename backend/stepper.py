from rpi_python_drv8825.stepper import StepperMotor
from time import sleep
import RPi.GPIO as GPIO  
# GPIO setup
tiltEnableGPIO = 6
tiltStepGPIO = 3
tiltDirectionGPIO = 2
tiltMicrostepGPIO = (5,22, 17)

rotateEnableGPIO = 12
rotateStepGPIO = 19
rotateDirectionGPIO = 14
rotateMicrostepGPIO = (16,20,21)

# Stepper motor setup
step_type = '1/32'
fullstep_delay = .005
tiltMotor = StepperMotor(tiltEnableGPIO, tiltStepGPIO, tiltDirectionGPIO, tiltMicrostepGPIO, step_type, fullstep_delay)



rotateMotor = StepperMotor(rotateEnableGPIO, rotateStepGPIO, rotateDirectionGPIO, rotateMicrostepGPIO, step_type, fullstep_delay)

rotateMotor.enable(True)        # enables stepper driver
tiltMotor.enable(True)        # enables stepper driver
tiltMotor.run(960, True)     # run motor 1280 steps clowckwise
sleep(2.5)

rotateMotor.run(1280, True)     # run motor 1280 steps clowckwise
sleep(2.5)


rotateMotor.run(1280, False)     # run motor 1280 steps clowckwise
sleep(2.5)
tiltMotor.run(960, False)     # run motor 1280 steps clowckwise



sleep(5)

tiltMotor.enable(False)       # disable stepper driver
rotateMotor.enable(False)       # disable stepper driver