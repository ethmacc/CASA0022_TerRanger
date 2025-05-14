#include <vector>
#include <Wire.h> //include Wire for I2C
#include <SparkFun_VL53L5CX_Library.h> //http://librarymanager/All#SparkFun_VL53L5CX
#include <ArduinoBLE.h>

SparkFun_VL53L5CX tof_1;
SparkFun_VL53L5CX tof_2;
VL53L5CX_ResultsData measurementData_1; // Result data class structure, 1356 byes of RAM
VL53L5CX_ResultsData measurementData_2;

uint8_t percent = 30; // Set sharpening percentage
uint8_t freq = 15; // Set ranging frequency
uint8_t res = 8*8; // Set sensor resolution

int imageResolution = 0; //Used to pretty print output
int imageWidth = 0; //Used to pretty print output

#define LPn_1 D3
#define LPn_2 D4

#define buttonPin D2 //Set pin for the button
int buttonState = 0;

// Bluetooth® Low Energy Service
#define BUFFER_SIZE res * 2 * 2 // Buffer size is resolution x 2 sensors x 2 bytes
BLEService tofService = BLEService("185B");
BLECharacteristic tofChar = BLECharacteristic("2C0A", BLERead | BLENotify, BUFFER_SIZE, false); 

unsigned long pressTime = millis();

void setup()
{
  Serial.begin(115200);
  delay(1000);  

  // Set LED for BLE connection indicator
  pinMode(LED_BUILTIN, OUTPUT);

  //Initialise I2C
  Wire.begin(); //This resets to 100kHz I2C
  Wire.setClock(400000); //Sensor has max I2C freq of 400kHz 
  
  //Initialise ToF
  Serial.println("Initializing ToF sensors. This can take up to 10s. Please wait.");

  //Initialise ToF cams
  initialiseToF(1);
  initialiseToF(2);

  imageResolution = tof_1.getResolution(); //Query sensor for current resolution - either 4x4 or 8x8
  imageWidth = sqrt(imageResolution); //Calculate printing width

  // BLE begin initialization
  if (!BLE.begin()) {
    Serial.println("starting BLE failed!");
    while (1);
  }
  Serial.println("BLE initialised");

  //BLE set device name, UUIDs 
  BLE.setLocalName("SH_v1");
  BLE.setDeviceName("SH_v1");

  BLE.setAdvertisedService(tofService);
  tofService.addCharacteristic(tofChar);
  BLE.addService(tofService);
  BLE.advertise();

  Serial.println("All initialisation complete");
}

void loop()
{
  // wait for a Bluetooth® Low Energy central
  BLEDevice central = BLE.central();

  // if a central is connected to the peripheral:
  if (central) {
    Serial.print("Connected to central: ");
    // print the central's BT address:
    Serial.println(central.address());
    // turn on the LED to indicate the connection:
    digitalWrite(LED_BUILTIN, HIGH);

    while (central.connected()) {
        // read the state of the pushbutton value:
        buttonState = digitalRead(buttonPin);
        // check if the pushbutton is pressed. If it is, the buttonState is HIGH:
        if (buttonState == HIGH && millis() - pressTime > 500) {
          Serial.println("ToF cam1");
          updateDistance(1);
          Serial.println("ToF cam2");
          updateDistance(2);

          uint16_t * all_data = new uint16_t[res * 2];
          std::copy(measurementData_1.distance_mm, measurementData_1.distance_mm + res, all_data);
          std::copy(measurementData_2.distance_mm, measurementData_2.distance_mm + res, all_data + res);
          tofChar.writeValue(all_data, BUFFER_SIZE);
          pressTime = millis();
        }
    }
     // when the central disconnects, turn off the LED:
    digitalWrite(LED_BUILTIN, LOW);
    Serial.print("Disconnected from central: ");
    Serial.println(central.address());
  } else {
    buttonState = digitalRead(buttonPin);
    if (buttonState == HIGH && millis() - pressTime > 500) {
      Serial.println("Warning! No connection to central. Data not transmitted");
      Serial.println("ToF cam1");
      updateDistance(1);
      Serial.println("ToF cam2");
      updateDistance(2);
      pressTime = millis();
    }
  }
}
 
void updateDistance(int cam) {
  switch (cam) {
    case 1:
      //Poll sensor for new data
      if (tof_1.isDataReady() == true)
      {
        if (tof_1.getRangingData(&measurementData_1)) //Read distance data into array
        {
          //tofChar.writeValue(measurementData_1.distance_mm, 128);
          //The ST library returns the data transposed from zone mapping shown in datasheet
          //Pretty-print data with increasing y, decreasing x to reflect reality
          for (int y = 0 ; y <= imageWidth * (imageWidth - 1) ; y += imageWidth)
          {
            for (int x = imageWidth - 1 ; x >= 0 ; x--)
            {
              Serial.print("\t");
              Serial.print(measurementData_1.distance_mm[x + y]);
            }
            Serial.println();
          }
          Serial.println();
        }
      }
      break;
    case 2:
      //Poll sensor for new data
      if (tof_2.isDataReady() == true)
      {
        if (tof_2.getRangingData(&measurementData_2)) //Read distance data into array
        {
          //tofChar.writeValue(measurementData_1.distance_mm, 128);
          //The ST library returns the data transposed from zone mapping shown in datasheet
          //Pretty-print data with increasing y, decreasing x to reflect reality
          for (int y = 0 ; y <= imageWidth * (imageWidth - 1) ; y += imageWidth)
          {
            for (int x = imageWidth - 1 ; x >= 0 ; x--)
            {
              Serial.print("\t");
              Serial.print(measurementData_2.distance_mm[x + y]);
            }
            Serial.println();
          }
          Serial.println();
        }
      }
      break;
  }
  
}

void initialiseToF (int cam) {
  switch (cam) {
    case 1:
      digitalWrite(LPn_1, HIGH);
      digitalWrite(LPn_2, LOW);

      if (tof_1.begin() == false)
      {
        Serial.println(F("Sensor 1 not found - check your wiring. Freezing"));
        while (1);
      }
      tof_1.setAddress(0x50);
      tof_1.setResolution(res); 
      tof_1.setSharpenerPercent(percent); //increase sharpener slightly to reduce veiling glare
      tof_1.setRangingMode(SF_VL53L5CX_RANGING_MODE::CONTINUOUS);
      tof_1.setRangingFrequency(freq); // increase ranging frequency to 15Hz to reduce lag
      tof_1.startRanging();
      break;
    case 2:
      digitalWrite(LPn_1, LOW);
      digitalWrite(LPn_2, HIGH);

      if (tof_2.begin() == false)
      {
        Serial.println(F("Sensor 2 not found - check your wiring. Freezing"));
        while (1);
      }
      tof_2.setAddress(0x51);
      tof_2.setResolution(res); 
      tof_2.setSharpenerPercent(percent);
      tof_2.setRangingMode(SF_VL53L5CX_RANGING_MODE::CONTINUOUS);
      tof_2.setRangingFrequency(freq); // increase ranging frequency to 15Hz to reduce lag
      tof_2.startRanging();
      break;
  }
  Serial.print(F("Sensor "));
  Serial.print(cam);
  Serial.println(F(" ready"));

  //Ensure all sensors awake
  digitalWrite(LPn_1, HIGH);
  digitalWrite(LPn_2, HIGH);
}
