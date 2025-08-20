# CASA0022 TerRanger
1. [Introduction](#Introduction)
3. [Materials](#Materials)
4. [Quickstart](#Quickstart)
5. [Advanced Setup](#Advanced-setup)
8. [Future Work](#future-work)
9. [External Links](#External-links)

## Introduction
### Demo Film
[![TerRanger Demo Film](https://img.youtube.com/vi/eogr--X4ssc/0.jpg)](https://www.youtube.com/watch?v=eogr--X4ssc)

### What is TerRanger?
This repository contains the code and 3D models required to build the TerRanger Smart Walking Stick, my dissertation project for the MSc Connected Environments course. The TerRanger system consists of 2 key components: the smart walking stick device and a mobile application that pairs with it using Bluetooth Low Energy (BLE). TerRanger uses two STMicroelectronics VL53L5CX tiny LiDAR sensors to map out the terrain below the hiking stick. This data is then translated into point-cloud form and visualized on the mobile application. TerRanger utilises the terrain surface data to estimate erosion along hiking paths, and is essentially a feasibility study to show that trail erosion monitoring can be semi-automated using embedded, low-cost technology.

## Materials
You will need the following materials:
- A 3D printer (with nozzle size no larger than 0.4mm) & filament
- A UV printer (optional)
- An Arduino Nano BLE 33 Sense (rev1 was used in this build, but rev2 can probably also be used with some modifications)
- Protoboard or stripboard
- Electrical wire
- A capacitor (at least 33µF)
- A 10kΩ resistor
- A tactile button
- A 5V stepup converter/regulator (Pololu 5V S7V8F5)
- A LiPo charging module (Adafruit bq24074)
- A 2000mAh LiPo cell
- 2 x VL53L5CX LiDAR Time-of-Flight sensors
- A toggle switch
- 2x 4 pin JST-SH cables
- Assorted M2 screws and bolts
- Washers
- Pin headers and sockets
- An Android smartphone

## Quickstart
### Hardware
To construct the electronics, the protoboard/stripboard should first be cut to the dimensions 51mm x 62mm. Then, construct the circuit can be constructed using the following breadboard and schematic as a guide:

<img width="600" alt="circuit_diagram_bb" src="https://github.com/user-attachments/assets/1d508ac4-93e4-48ac-977b-1d2bde71f53d" />

*Fritzing breadboard diagram*

<img width="600" alt="circuit_diagram_schem" src="https://github.com/user-attachments/assets/7689529b-ce41-41d2-ba7a-9bcc32572af9" />

*Fritzing circuit schematic*

The circuit contains a number of subcircuits for the following components:
- LiDAR sensors - these should be attached using JST-SH cables can for ease of maintenance and disassembly. However, if you wish, they can also be connected with solder joints. Ensure that the four individal lines of the JST-SH connection are connected to the appropriate pins of the Nano 33 MCU (3v, ground, I2C - SDA & SCL). The green lines in the breadboard diagram denote the LPn connections, and these MUST be connected to the MCU at the appropriate pins to allow for the individual I2C addresses for each sensor to be assigned correctly.
- Tactile button - this is connected using a standard click button circuit (https://docs.arduino.cc/built-in-examples/digital/Button/) to receive a signal when the button is pressed. The 10kΩ resistor is used here
- 5V step-up - this part of the circuit boosts the 3.7V of the LiPo battery to 5V so that it can be fed into the Nano 33's VIN pin. The 33µF capacitor is used here to provide some smoothing when the toggle switch is turned on.
- LiPo charger - this charges the LiPo battery whilst also providing 3.7V from the battery to the 5V step-up. Note that the orientation of the ports should be the same direction as the Nano 33's micro-usb port. This was done for ease of maintenance

The following real images can also be used as a reference in the protoboard construction:
<img width="600" alt="protoboard" src="https://github.com/user-attachments/assets/cdb39e1e-ae4c-45c8-98e2-f6d8b0c20d3b" />

*Protoboard initial build*

<img width="600" alt="protoboard in enclosure" src="https://github.com/user-attachments/assets/744674f6-6f58-4ba2-90db-b6dc672778fe" />

*Protoboard fully connected to components and placed in enclosure*

### Software
The Arduino C++ code for the device is provided in the following folders:
- ```Arduino/DistanceArray_main``` - Push this version to the Nano 33 for the initial device that uses the manual tactile button to trigger the LiDAR sensors to take a sample
- ```Arduino/DistanceArray_ai``` - Push this version to the Nano 33 for the later device that uses gesture recognition (a double tap of the walking stick) to trigger the LiDAR sensors to take a sample

### Enclosure

### Mobile Application

## Advanced Setup

### Sensor Tuning

### Edge AI model

### Mobile Application

## Future Work

## External Links
### Edge Impulse Project
https://studio.edgeimpulse.com/public/732758/live
