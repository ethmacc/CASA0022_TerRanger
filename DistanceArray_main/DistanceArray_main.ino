#include <Wire.h> //include Wire for I2C
#include <SparkFun_VL53L5CX_Library.h> //http://librarymanager/All#SparkFun_VL53L5CX
#include <ArduinoBLE.h>

SparkFun_VL53L5CX myImager;
VL53L5CX_ResultsData measurementData; // Result data class structure, 1356 byes of RAM

int imageResolution = 0; //Used to pretty print output
int imageWidth = 0; //Used to pretty print output

#define buttonPin D2 //Set pin for the button
int buttonState = 0;

// Bluetooth® Low Energy Service
#define BUFFER_SIZE 128
BLEService tofService = BLEService("185B");
BLECharacteristic tofChar = BLECharacteristic("2C0A", BLERead | BLENotify, BUFFER_SIZE, false); 

void setup()
{
  Serial.begin(115200);
  delay(1000);
  Serial.println("VL53L5CX Imager with BLE broadcast");

  pinMode(LED_BUILTIN, OUTPUT);

  Wire.begin(); //This resets to 100kHz I2C
  Wire.setClock(400000); //Sensor has max I2C freq of 400kHz 
  
  Serial.println("Initializing sensor board. This can take up to 10s. Please wait.");
  if (myImager.begin() == false)
  {
    Serial.println(F("Sensor not found - check your wiring. Freezing"));
    while (1);
  }
  
  myImager.setResolution(8*8); //Enable all 64 pads
  
  imageResolution = myImager.getResolution(); //Query sensor for current resolution - either 4x4 or 8x8
  imageWidth = sqrt(imageResolution); //Calculate printing width

  myImager.startRanging();
  Serial.println("Sensor ready");

  // begin initialization
  if (!BLE.begin()) {
    Serial.println("starting BLE failed!");
    while (1);
  }

  //Set device name, UUIDs 
  BLE.setLocalName("SH_v1");
  BLE.setDeviceName("SH_v1");

  BLE.setAdvertisedService(tofService);
  tofService.addCharacteristic(tofChar);
  BLE.addService(tofService);
  BLE.advertise();
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
        if (buttonState == HIGH) {
          updateDistance();
        }
    }
     // when the central disconnects, turn off the LED:
    digitalWrite(LED_BUILTIN, LOW);
    Serial.print("Disconnected from central: ");
    Serial.println(central.address());
  }
}
 
void updateDistance() {
  //Poll sensor for new data
  if (myImager.isDataReady() == true)
  {
    if (myImager.getRangingData(&measurementData)) //Read distance data into array
    {
      tofChar.writeValue(measurementData.distance_mm, 128);
      //The ST library returns the data transposed from zone mapping shown in datasheet
      //Pretty-print data with increasing y, decreasing x to reflect reality
      for (int y = 0 ; y <= imageWidth * (imageWidth - 1) ; y += imageWidth)
      {
        for (int x = imageWidth - 1 ; x >= 0 ; x--)
        {
          Serial.print("\t");
          Serial.print(measurementData.distance_mm[x + y]);
        }
        Serial.println();
      }
      Serial.println();
    }
  }
}
