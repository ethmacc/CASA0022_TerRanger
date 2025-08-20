# CASA0022 TerRanger

![IMG_0298 (1)](https://github.com/user-attachments/assets/7553a84d-4ab7-4be7-8c9f-f8f5ce391823)

## Contents
1. [Introduction](#Introduction)
3. [Materials](#Materials)
4. [Quickstart](#Quickstart)
5. [Advanced Setup](#Advanced-setup)
8. [Future Work](#future-work)
9. [External Links](#External-links)
10. [References](#References)

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
- Velcro strap
- A walking stick for hiking
- An Android smartphone

## Quickstart
### Hardware
To construct the electronics, the protoboard/stripboard should first be cut to the dimensions 51mm x 62mm. Then, construct the circuit can be constructed using the following breadboard and schematic as a guide:

<img width="600" alt="circuit_diagram_bb" src="https://github.com/user-attachments/assets/1d508ac4-93e4-48ac-977b-1d2bde71f53d" />

*Fritzing breadboard diagram*

<img width="600" alt="circuit_diagram_schem" src="https://github.com/user-attachments/assets/7689529b-ce41-41d2-ba7a-9bcc32572af9" />

*Fritzing circuit schematic*

The circuit contains a number of subcircuits for the following components:

| **Component subcircuit**       | **Remarks**                                |
|-----------------------|--------------------------------------------|
| LiDAR sensors | These should be attached using JST-SH cables can for ease of maintenance and disassembly. However, if you wish, they can also be connected with solder joints. Ensure that the four individal lines of the JST-SH connection are connected to the appropriate pins of the Nano 33 MCU (3v, ground, I2C - SDA & SCL). The green lines in the breadboard diagram denote the LPn connections, and these MUST be connected to the MCU at the appropriate pins to allow for the individual I2C addresses for each sensor to be assigned correctly. |
| Tactile button | This is connected using a [standard click button circuit](https://docs.arduino.cc/built-in-examples/digital/Button/) to receive a signal when the button is pressed. The 10kΩ resistor is used here. |
| 5V step-up | This part of the circuit boosts the 3.7V of the LiPo battery to 5V so that it can be fed into the Nano 33's VIN pin. The 33µF capacitor is used here to provide some smoothing when the toggle switch is turned on. |
| LiPo charger | This charges the LiPo battery whilst also providing 3.7V from the battery to the 5V step-up. Note that the orientation of the ports should be the same direction as the Nano 33's micro-usb port. This was done for ease of maintenance |

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
The enclosure can be printed by exporting the various components from the Fusion360 file in ```Models/3D/```. Ensure the 3D models are printed with sufficiently high quality settings for the best results. M3 screws and bolts should be used to secure the two halves of the enclosure together.

<img width="600" alt="Screenshot 2025-08-11 183940" src="https://github.com/user-attachments/assets/1ecd7a76-f036-40e4-9649-8b49062c78bf" />

*Fusion360 model of the device enclosure*

If you wish, and have access to a UV printer, you can apply the decals found in ```Models/2D``` to the front face of the enclosure.

### Mobile Application
The Mobile Application was designed initially in Figma and then realised with Flutter.

<img width="1000" height="1696" alt="Mobile Application Wireframe" src="https://github.com/user-attachments/assets/72d19678-198f-45e2-9958-1e8d21ae8d8f" />

*Wireframe for the TerRanger Mobile Application, designed in Figma*

<img width="200" alt="Screenshot 2025-08-13 164600" src="https://github.com/user-attachments/assets/f064c82d-8903-4259-af2f-b1d3c356eba8" />
<img width="200" alt="Screenshot 2025-08-13 164605" src="https://github.com/user-attachments/assets/aa5b445b-dbc4-4c28-bce1-0adc0effe092" />
<img width="200" alt="Screenshot 2025-08-13 164627" src="https://github.com/user-attachments/assets/b53b6430-7c2b-4594-8593-f64f74385ce9" />
<img width="200" height="942" alt="Screenshot 2025-08-13 164633" src="https://github.com/user-attachments/assets/67adcd6c-f419-46c1-b9c3-cb372dc31729" />

*Screens from the finished Flutter build*

To download the latest version of the application, navigate to the [Releases tab](https://github.com/ethmacc/CASA0022_TerRanger/releases) and download the latest release.

### Device Operation
Once the device has been assembled and the mobile application installed on your Android smartphone, follow these steps to prepare the device for use:
1. Thread the velcro strap through the slots in the bracket at the back of the enclosure. Use these to securely attach the TerRanger device to your hiking stick
2. Switch on TerRanger by flipping the toggle switch at the top of the enclosure and wait for a few seconds for the startup routine to complete
3. Pair the device by navigating to the ```Devices``` screen in the mobile application and pressing the ```Connect to device``` button.
4. Once done, use the red-orange centre button in the middle of the bottom app bar to create a new hike and start collecting data

## Advanced Setup

This section is intended for advanced makers to provide further details on the TerRanger system and how these can be modified.

### Software

#### Dependencies

The following key libraries were used in the Arduino code:

| **Library**       | **Purpose**                                |
|-----------------------|--------------------------------------------|
| [vector](https://docs.arduino.cc/libraries/vector/) | Used for [Gyroscopic compensation](Gyroscopic-compensation) |
| [Wire](https://docs.arduino.cc/language-reference/en/functions/communication/wire/) | Required for I2C communication between the LiDAR sensors and the MCU |
| [SparkFun_VL53L5CX_Library](https://docs.arduino.cc/libraries/sparkfun-vl53l5cx-arduino-library/) | Required to interface with the firmware for the VL53L5CX |
| [ArduinoBLE](https://docs.arduino.cc/libraries/arduinoble/) | Used to set a device name and create a BLE characteristic that the data from the sensors can be written to |
| [Arduino_LSM9DS1](https://docs.arduino.cc/libraries/arduino_lsm9ds1/) | To interface with the LSM9DS1 IMU, used for [Gyroscopic compensation](Gyroscopic-compensation) |

#### Sensor tuning

<img width="600" alt="Image of two VL53L5CX sensors attached to the circuit" src="https://github.com/user-attachments/assets/2b81c369-8711-43cd-92a5-43577d9bcf48" />

*Two VL53L5CX sensors attached to the circuit*

The VL53L5CX sensors can be tuned to change their sampling frequency, distance array size and ranging mode, which will have effects on device performance. This can be done by calling the appropriate functions from the imported Sparkfun library in the main Arduino code, for example:

| **Function**       | **Use**                                |
|-----------------------|--------------------------------------------|
| `SparkFun_VL53L5CX.setResolution()` | To change distance array size between 4x4 and 8x8 |
| `SparkFun_VL53L5CX.setRangingMode()` | To set ranging mode. It is possible to select either continuous or autonomous. Continuous uses more power but is more frequent |
| `SparkFun_VL53L5CX..setRangingFrequency()` | To set ranging frequency in continous mode. This has been set to the maximum of 60Hz in the code, to minimize lag time |

For more information, see the Sparkfun VL53L5CX library GitHub repo and VL53L5CX datasheet and manual under [External Links](#External-links))

#### Gyroscopic compensation

The walking stick could be oriented in a direction that is not orthogonal to the ground plane when a sample is taken. Therefore the vector library was used, and the functions ```calculatePitch``` and ```calculateYaw``` make use of this and the [acceleration to pitch & yaw forumla](https://wiki.dfrobot.com/How_to_Use_a_Three-Axis_Accelerometer_for_Tilt_Sensing) to convert the accelerometer readings to pitch and yaw angles in degrees. These angles are transmitted to the mobile application via Bluetooth.

### Edge AI model

If you elect to use the gesture recognition version of the Arduino code in ```Arduino/DistanceArray_ai/```, you will find that it uses a TinyML or Edge AI model to power the gesture recognition functionality. The model embedded in the code as a library is a Convolutional Neural Network (CNN), that has been trained on accelerometer data from performing the gesture of double tapping the hiking stick on the ground.

<img width="600" alt="Screenshot 2025-08-11 201327" src="https://github.com/user-attachments/assets/603c5bcd-c2dc-4ed6-b4d5-eb4694a80e91" />

*Model architecture of the CNN used for gesture recognition in the DistanceArray_ai.ino file*

Other architectures tested included a Recurrent Neural Network (using Long Short Term Memory layers) and a hybrid model with both LSTM and Convolutional layers. The CNN model outperformed the other two architectures by far.

<img width="1000" alt="Screenshot 2025-08-11 203729" src="https://github.com/user-attachments/assets/18e6ec53-cf07-48b4-81df-d691cc250ef5" />

*Comparison of performance across different model architectures*

Using Edge Impulse, it is possible to clone the project and train it on your own data or make further adjustments to the model. To visit the Edge Impulse project page, see [External Links](#External-links))

### Mobile Application

#### Dependencies

The key libraries that have been used in the code are:

| **Library**       | **Purpose**                                |
|-----------------------|--------------------------------------------|
| [flutter_reactive_ble](https://pub.dev/packages/flutter_reactive_ble) | For establishing the Bluetooth Low Energy connection to the device |
| [permission_handler](https://pub.dev/packages/permission_handler) | For handling location and Bluetooth permissions |
| [provider](https://pub.dev/packages/provider) | To provide [app state management](https://docs.flutter.dev/get-started/fundamentals/state-management) |
| [sqflite](https://pub.dev/packages/sqflite) | To persist data in the background in the form of a SQL database |
| [flutter_map](https://pub.dev/packages/flutter_map) & [flutter_map_location_marker](https://pub.dev/packages/flutter_map_location_marker) | to display a map widget |
| [latlong2](https://pub.dev/packages/latlong2) & [geolocator](https://pub.dev/packages/geolocator) | to get the position of the user when a sample is taken |
| [fl_chart](https://pub.dev/packages/fl_chart), [vector_math](https://pub.dev/packages/vector_math) & [ditred](https://pub.dev/packages/ditredi) | To manipulate and visualize the data from the sensors |
| [share_plus](https://pub.dev/packages/share_plus) | to provide backup functionality for the local SQL database where the data is stored |

#### Developer setup

If you wish to develop the mobile application further, first clone this entire repository with:

```git clone https://github.com/ethmacc/CASA0022_TerRanger/```

After which, run the following command to fix and issues in the code and install dependencies (using the ```pubspec.yaml``` file in application root folder):

```flutter clean```

```flutter pub get```

To run the application in a connected Android Device or Emulator, use:

```flutter run```

The application can be built into and apk and installed using the following commands:

```flutter build apk```

```flutter install```

Note that if you want to push an upgrade to an existing version on your Android device without overwriting the existing data collected, you should use:

```adb install -r "smarthiking_app\build\app\outputs\apk\release\app-release.apk"```

instead of ```flutter install```

If you wish to load data from the 3 hikes that were conducting during the course of this project, find them in the folder ```Data/database_backups/``` and load them into your app by using the function on the backups screen.

#### Algorithms
The distance array (from the VL53L5CX sensors) to point-cloud algorithm is based on scaling a list of vectors that point to each of the grid points in the sensor's field of view. This was tested and visualised initially in the Python notebooks  ```/Data/byte_decoder.ipynb``` and ```/Data/byte_decoder_4x4.ipynb```, which can also be used for further development.

<img width="600" alt="newplot (1)" src="https://github.com/user-attachments/assets/a646868b-aab6-4727-bccd-2a108ee6db6b" />

*The vector list visualised as a vector field using plotly in the Python notebook*

The erosion estimation algorthim is based on the Cross-Section Analysis (CSA) method and formula:

<img width="600" alt="Screenshot 2025-08-10 201159" src="https://github.com/user-attachments/assets/7b2805a5-7fc5-4cd2-86aa-759692a3857f" />

*Diagram illustraing the CSA method, taken from [Olive and Marion (2009)](#references)*

## Future Work
A PCB design was developed towards the end of the project, but this was not manufactured or tested. It can be found in ```Models/2D```. A future version of the pojrect might involve miniaturising the device further, taking and advantage of the reduced size of the electronics with a dedicated PCB and surface mount-components

<img width="400" alt="Screenshot 2025-08-18 151321" src="https://github.com/user-attachments/assets/3983a2cd-4c11-4adc-b175-80f2d3d4c0ac" />
<img width="400" alt="Screenshot 2025-08-18 151558" src="https://github.com/user-attachments/assets/5d66ea2f-5f79-4d3f-b1fe-7517f5599325" />

*PCB design schematic (left) and 3D model (right)*

It may also be possible to upgrade the sensors, which during testing were found to be less accurate than desired. The VL53L8CX, an improved model that is more able to cope with environmental factors such as high ambient light, is just starting to become more widely available.

Lastly, it would be an interesting exercise to try adapting the device to another use case, such as surveying for potholes. Pothole damage repair costs the UK approximately £143.5 million annually [(Asphalt Industry Alliance, 2024)](#references).

## External Links

### Sparkfun VL53L5CX library
https://github.com/sparkfun/SparkFun_VL53L5CX_Arduino_Library

### VL53L5CX manual & datasheet
https://www.st.com/resource/en/user_manual/um2884-a-guide-to-using-the-vl53l5cx-multizone-timeofflight-ranging-sensor-with-a-wide-field-of-view-ultra-lite-driver-uld-stmicroelectronics.pdf

https://www.st.com/resource/en/datasheet/vl53l5cx.pdf

### Edge Impulse Project
https://studio.edgeimpulse.com/public/732758/live

## References

Asphalt Industry Alliance. (2024). Annual Local Authority Road Maintenance Survey Report. 2024.

Olive, N. D. and Marion, J. L. (2009). ‘The influence of use-related, environmental, and managerial factors on soil loss from recreational trails’. Journal of Environmental Management, 90 (3), pp. 1483–1493. doi: 10.1016/j.jenvman.2008.10.004.
