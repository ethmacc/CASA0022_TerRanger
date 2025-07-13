#include <vector>
#include <Wire.h> //include Wire for I2C
#include <SparkFun_VL53L5CX_Library.h> //http://librarymanager/All#SparkFun_VL53L5CX
#include <ArduinoBLE.h>
#include <Arduino_LSM9DS1.h>
#include <TerRanger_inferencing.h>

SparkFun_VL53L5CX tof_1;
SparkFun_VL53L5CX tof_2;
VL53L5CX_ResultsData measurementData_1; // Result data class structure, 1356 byes of RAM
VL53L5CX_ResultsData measurementData_2;

uint8_t percent = 30; // Set sharpening percentage
uint8_t freq = 30; // Set ranging frequency
uint8_t res = 4*4; // Set sensor resolution

int imageResolution = 0; //Used to pretty print output
int imageWidth = 0; //Used to pretty print output

#define LPn_1 D3
#define LPn_2 D4

#define buttonPin D2 //Set pin for the button
int buttonState = 0;

// Bluetooth® Low Energy Service
#define BUFFER_SIZE ( (res * 2 ) + 2) * 2 // Buffer size is resolution x 2 sensors x 2 bytes plus 2 * 2 bytes for acc data
BLEService tofService = BLEService("185B");
BLECharacteristic tofChar = BLECharacteristic("2C0A", BLERead | BLENotify, BUFFER_SIZE, false); 

#define CONVERT_G_TO_MS2    9.80665f
#define MAX_ACCEPTED_RANGE  2.0f

static bool debug_nn = false; // Set this to true to see e.g. features generated from the raw signal
static uint32_t run_inference_every_ms = 30;
static rtos::Thread inference_thread(osPriorityLow);

static float buffer[EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE] = { 0 };
static float inference_buffer[EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE];

const char *prediction = "false";

/* Forward declaration */
void run_inference_background();

float accX, accY, accZ;

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

  //IMU initialisation
  if (!IMU.begin()) {
    Serial.println("Failed to initialize IMU!");
    while (1);
  }
  Serial.println("IMU initialised");

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

  //Edge Impulse model axes check
  if (EI_CLASSIFIER_RAW_SAMPLES_PER_FRAME != 6) {
        ei_printf("ERR: EI_CLASSIFIER_RAW_SAMPLES_PER_FRAME should be equal to 6 (the 6 sensor axes)\n");
        return;
  }

  inference_thread.start(mbed::callback(&run_inference_background));
  Serial.println("Inference thread started");

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
      ///Poll sensors and load buffer//
      // Determine the next tick (and then sleep later)
      uint64_t next_tick = micros() + (EI_CLASSIFIER_INTERVAL_MS * 1000);

      // roll the buffer -3 points so we can overwrite the last one
      numpy::roll(buffer, EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE, -6);

      // read to the end of the buffer
      IMU.readAcceleration(
          buffer[EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE - 6],
          buffer[EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE - 5],
          buffer[EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE - 4]
      );

      IMU.readGyroscope(
          buffer[EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE - 3],
          buffer[EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE - 2],
          buffer[EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE - 1]
      );

      for (int i = 0; i < 6; i++) {
          if (fabs(buffer[EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE - 6 + i]) > MAX_ACCEPTED_RANGE) {
              buffer[EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE - 6 + i] = ei_get_sign(buffer[EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE - 6 + i]) * MAX_ACCEPTED_RANGE;
          }
      }

      buffer[EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE - 6] *= CONVERT_G_TO_MS2;
      buffer[EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE - 5] *= CONVERT_G_TO_MS2;
      buffer[EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE - 4] *= CONVERT_G_TO_MS2;

      // check if the pushbutton is pressed. If it is, the buttonState is HIGH:
      
      if (prediction == "true" && millis() - pressTime > 1000) {
        Serial.println("prediction true");
        
        Serial.println("ToF cam1");
        updateDistance(1);
        Serial.println("ToF cam2");
        updateDistance(2);

        if (IMU.accelerationAvailable()) {
          IMU.readAcceleration(accX, accY, accZ);
        }

        float consX = constrain(accX, -1.0, 1.0);
        float consY = constrain(accY, -1.0, 1.0);
        float consZ = constrain(accZ, -1.0, 1.0);

        int roll = calculateRoll(consX, consY, consZ);
        int pitch  = calculatePitch(consX, consY, consZ);

        Serial.println(roll);
        Serial.println(pitch);

        uint16_t roll16 = uint16_t(roll + 180);
        uint16_t pitch16 = uint16_t(pitch + 180);

        Serial.println(roll16);
        Serial.println(pitch16);
          
        uint16_t acc_data[2] = {roll16, pitch16};

        uint16_t * combined_tof = new uint16_t[res * 2];
        std::copy(measurementData_1.distance_mm, measurementData_1.distance_mm + res, combined_tof);
        std::copy(measurementData_2.distance_mm, measurementData_2.distance_mm + res, combined_tof + res);

        uint16_t * all_data = new uint16_t[(res * 2) + 2];
        std::copy(combined_tof, combined_tof + (res * 2), all_data);
        std::copy(acc_data, acc_data + 2, all_data + (res * 2));
        
        tofChar.writeValue(all_data, BUFFER_SIZE);
        pressTime = millis();
      }

      // and wait for next tick
      uint64_t time_to_wait;
      if (micros() >= next_tick) {
          time_to_wait = 0;
      } else {
          time_to_wait = next_tick - micros();
      }
      
      delay((int)floor((float)time_to_wait / 1000.0f));
      delayMicroseconds(time_to_wait % 1000);
    }
     // when the central disconnects, turn off the LED:
    digitalWrite(LED_BUILTIN, LOW);
    Serial.print("Disconnected from central: ");
    Serial.println(central.address());
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

int calculateRoll(float x, float y, float z) {
  return atan2(y , z) * 57.3;
}

int calculatePitch(float x, float y, float z) {
  return atan2((- x) , sqrt(y * y + z * z)) * 57.3;
}

float ei_get_sign(float number) {
    return (number >= 0.0) ? 1.0 : -1.0;
}

void run_inference_background()
{
    // wait until we have a full buffer
    delay((EI_CLASSIFIER_INTERVAL_MS * EI_CLASSIFIER_RAW_SAMPLE_COUNT) + 100);

    // This is a structure that smoothens the output result
    // With the default settings 70% of readings should be the same before classifying.
    ei_classifier_smooth_t smooth;
    ei_classifier_smooth_init(&smooth, 10 /* no. of readings */, 7 /* min. readings the same */, 0.8 /* min. confidence */, 0.3 /* max anomaly */);

    while (1) {
        // copy the buffer
        memcpy(inference_buffer, buffer, EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE * sizeof(float));

        // Turn the raw buffer in a signal which we can the classify
        signal_t signal;
        int err = numpy::signal_from_buffer(inference_buffer, EI_CLASSIFIER_DSP_INPUT_FRAME_SIZE, &signal);
        if (err != 0) {
            ei_printf("Failed to create signal from buffer (%d)\n", err);
            return;
        }

        // Run the classifier
        ei_impulse_result_t result = { 0 };

        err = run_classifier(&signal, &result, debug_nn);
        if (err != EI_IMPULSE_OK) {
            ei_printf("ERR: Failed to run classifier (%d)\n", err);
            return;
        }

        // print the predictions
        ei_printf("Predictions ");
        ei_printf("(DSP: %d ms., Classification: %d ms., Anomaly: %d ms.)",
            result.timing.dsp, result.timing.classification, result.timing.anomaly);
        ei_printf(": ");

        // ei_classifier_smooth_update yields the predicted label
        prediction = ei_classifier_smooth_update(&smooth, &result);
        ei_printf("%s ", prediction);
        // print the cumulative results
        ei_printf(" [ ");
        for (size_t ix = 0; ix < smooth.count_size; ix++) {
            ei_printf("%u", smooth.count[ix]);
            if (ix != smooth.count_size + 1) {
                ei_printf(", ");
            }
            else {
              ei_printf(" ");
            }
        }
        ei_printf("]\n");

        delay(run_inference_every_ms);
    }

    ei_classifier_smooth_free(&smooth);
}

#if !defined(EI_CLASSIFIER_SENSOR) || EI_CLASSIFIER_SENSOR != EI_CLASSIFIER_SENSOR_FUSION
#error "Invalid model for current sensor"
#endif