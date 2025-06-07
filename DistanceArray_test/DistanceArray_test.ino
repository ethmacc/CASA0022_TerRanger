#include <vector>
#include <Wire.h> //include Wire for I2C
#include <SparkFun_VL53L5CX_Library.h> //http://librarymanager/All#SparkFun_VL53L5CX

SparkFun_VL53L5CX tof_1;
VL53L5CX_ResultsData measurementData_1;

uint8_t percent = 30; // Set sharpening percentage
uint8_t freq = 15; // Set ranging frequency
uint8_t res = 4*4; // Set sensor resolution

int imageResolution = 0; //Used to pretty print output
int imageWidth = 0; //Used to pretty print output

#define buttonPin D2 //Set pin for the button
int buttonState = 0;

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

  imageResolution = tof_1.getResolution(); //Query sensor for current resolution - either 4x4 or 8x8
  imageWidth = sqrt(imageResolution); //Calculate printing width
}

void loop()
{
  buttonState = digitalRead(buttonPin);
  //Serial.println(buttonState);
  if (buttonState == HIGH && millis() - pressTime > 500) {
    Serial.println("ToF cam1");
    updateDistance(1);

    pressTime = millis();
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
  }
}

void initialiseToF (int cam) {
  switch (cam) {
    case 1:
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
  }
  Serial.print(F("Sensor "));
  Serial.print(cam);
  Serial.println(F(" ready"));
}

