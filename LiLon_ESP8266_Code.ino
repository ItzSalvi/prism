/*
 * LiLon ESP8266 + MAX30102 + SIM800L Health Monitor
 * 
 * Pin Configuration for LiLon ESP8266:
 * - D0 (GPIO16): Built-in LED (status indicator)
 * - D1 (GPIO5): I2C SCL (MAX30102)
 * - D2 (GPIO4): I2C SDA (MAX30102)
 * - D3 (GPIO0): Boot mode (keep floating)
 * - D4 (GPIO2): WiFi LED (status indicator)
 * - D5 (GPIO14): SIM800L TX
 * - D6 (GPIO12): SIM800L RX
 * - D7 (GPIO13): SIM800L Reset
 * - D8 (GPIO15): SIM800L Power control
 */

#include <Wire.h>
#include <SoftwareSerial.h>
#include "MAX30105.h"
#include "heartRate.h"

// LiLon ESP8266 Pin Definitions
#define LED_PIN 16        // D0 - Built-in LED
#define WIFI_LED_PIN 2    // D4 - WiFi status LED
#define SIM800L_TX 14     // D5 - SIM800L TX
#define SIM800L_RX 12     // D6 - SIM800L RX
#define SIM800L_RST 13    // D7 - SIM800L Reset
#define SIM800L_PWR 15    // D8 - SIM800L Power control

// MAX30102 sensor (I2C on D1/D2)
MAX30105 particleSensor;
const byte RATE_SIZE = 4;
byte rates[RATE_SIZE];
byte rateSpot = 0;
long lastBeat = 0;
float beatsPerMinute;
int beatAvg;

// SIM800L communication (SoftwareSerial on D5/D6)
SoftwareSerial sim800l(SIM800L_RX, SIM800L_TX);
String phoneNumber = "+1234567890"; // Emergency contact number

// Bluetooth communication
String receivedData = "";
bool isScanning = false;
unsigned long scanStartTime = 0;
const unsigned long SCAN_DURATION = 60000; // 60 seconds

// Status tracking
bool systemReady = false;
bool sim800lReady = false;
bool max30102Ready = false;

void setup() {
  Serial.begin(115200);
  sim800l.begin(9600);
  
  // Initialize LiLon ESP8266 pins
  pinMode(LED_PIN, OUTPUT);
  pinMode(WIFI_LED_PIN, OUTPUT);
  pinMode(SIM800L_RST, OUTPUT);
  pinMode(SIM800L_PWR, OUTPUT);
  
  // Initialize status LEDs
  digitalWrite(LED_PIN, HIGH);      // Error indicator (will turn off when ready)
  digitalWrite(WIFI_LED_PIN, LOW);  // WiFi status
  
  // Initialize SIM800L
  initializeSIM800L();
  
  // Initialize MAX30102 (I2C on D1/D2)
  initializeMAX30102();
  
  // System ready
  if (max30102Ready && sim800lReady) {
    systemReady = true;
    digitalWrite(LED_PIN, LOW);      // Ready indicator
    digitalWrite(WIFI_LED_PIN, HIGH); // WiFi status
    Serial.println("LiLon ESP8266 + MAX30102 + SIM800L Ready");
  } else {
    Serial.println("System initialization failed!");
    digitalWrite(LED_PIN, HIGH); // Error indicator
  }
}

void loop() {
  // Handle Bluetooth commands
  if (Serial.available()) {
    String command = Serial.readString();
    command.trim();
    
    if (command == "START_SCAN:60") {
      startScanning();
    } else if (command == "STOP_SCAN") {
      stopScanning();
    } else if (command == "STATUS") {
      sendStatus();
    }
  }
  
  // If scanning, collect sensor data
  if (isScanning && systemReady) {
    collectSensorData();
    
    // Check if scan is complete
    if (millis() - scanStartTime >= SCAN_DURATION) {
      completeScan();
    }
  }
  
  // Blink WiFi LED to show system is alive
  static unsigned long lastBlink = 0;
  if (millis() - lastBlink > 1000) {
    digitalWrite(WIFI_LED_PIN, !digitalRead(WIFI_LED_PIN));
    lastBlink = millis();
  }
  
  delay(100);
}

void initializeSIM800L() {
  Serial.println("Initializing SIM800L...");
  
  // Power on SIM800L
  digitalWrite(SIM800L_RST, HIGH);
  digitalWrite(SIM800L_PWR, HIGH);
  delay(3000); // Wait for SIM800L to boot
  
  // Test communication
  sim800l.println("AT");
  delay(1000);
  
  if (sim800l.available()) {
    String response = sim800l.readString();
    if (response.indexOf("OK") >= 0) {
      sim800lReady = true;
      Serial.println("SIM800L initialized successfully");
      
      // Configure SMS mode
      sim800l.println("AT+CMGF=1");
      delay(1000);
      sim800l.println("AT+CNMI=1,2,0,0,0");
      delay(1000);
    } else {
      Serial.println("SIM800L communication failed");
    }
  }
}

void initializeMAX30102() {
  Serial.println("Initializing MAX30102...");
  
  // Initialize I2C with correct pins for LiLon ESP8266
  Wire.begin(4, 5); // SDA=D2(4), SCL=D1(5)
  
  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("MAX30102 was not found");
    max30102Ready = false;
    return;
  }
  
  // Configure MAX30102
  particleSensor.setup();
  particleSensor.setPulseAmplitudeRed(0x0A);
  particleSensor.setPulseAmplitudeGreen(0);
  
  max30102Ready = true;
  Serial.println("MAX30102 initialized successfully");
}

void startScanning() {
  if (!systemReady) {
    Serial.println("ERROR: System not ready");
    return;
  }
  
  isScanning = true;
  scanStartTime = millis();
  Serial.println("SCAN_STARTED");
  
  // Blink LED to indicate scanning
  digitalWrite(LED_PIN, HIGH);
  delay(100);
  digitalWrite(LED_PIN, LOW);
}

void stopScanning() {
  isScanning = false;
  Serial.println("SCAN_STOPPED");
}

void collectSensorData() {
  long irValue = particleSensor.getIR();
  
  if (checkForBeat(irValue)) {
    long delta = millis() - lastBeat;
    lastBeat = millis();
    beatsPerMinute = 60 / (delta / 1000.0);
    
    if (beatsPerMinute < 255 && beatsPerMinute > 20) {
      rates[rateSpot++] = (byte)beatsPerMinute;
      rateSpot %= RATE_SIZE;
      
      beatAvg = 0;
      for (byte x = 0; x < RATE_SIZE; x++) {
        beatAvg += rates[x];
      }
      beatAvg /= RATE_SIZE;
    }
  }
  
  // Send data to Flutter app every second
  static unsigned long lastDataSend = 0;
  if (millis() - lastDataSend >= 1000) {
    sendSensorData();
    lastDataSend = millis();
  }
}

void sendSensorData() {
  // Calculate SpO2 (simplified)
  float spo2 = calculateSpO2();
  
  // Create JSON data
  String jsonData = "{";
  jsonData += "\"heartRate\":" + String(beatAvg) + ",";
  jsonData += "\"spo2\":" + String(spo2, 1) + ",";
  jsonData += "\"timestamp\":" + String(millis());
  jsonData += "}";
  
  Serial.println(jsonData);
}

float calculateSpO2() {
  // Simplified SpO2 calculation
  float red = particleSensor.getRed();
  float ir = particleSensor.getIR();
  
  if (ir > 0 && red > 0) {
    float ratio = (red / ir);
    float spo2 = 100 - (ratio * 50);
    return constrain(spo2, 70, 100);
  }
  
  return 95.0; // Default value
}

void completeScan() {
  isScanning = false;
  
  // Calculate final blood pressure
  int systolic = calculateSystolic();
  int diastolic = calculateDiastolic();
  
  // Check if abnormal
  if (systolic >= 130 || diastolic >= 80) {
    sendSMSAlert(systolic, diastolic, beatAvg);
  }
  
  // Send final results
  String finalData = "{";
  finalData += "\"systolic\":" + String(systolic) + ",";
  finalData += "\"diastolic\":" + String(diastolic) + ",";
  finalData += "\"heartRate\":" + String(beatAvg) + ",";
  finalData += "\"spo2\":" + String(calculateSpO2(), 1) + ",";
  finalData += "\"scanComplete\":true";
  finalData += "}";
  
  Serial.println(finalData);
  
  // Flash LED to indicate completion
  for (int i = 0; i < 3; i++) {
    digitalWrite(LED_PIN, HIGH);
    delay(200);
    digitalWrite(LED_PIN, LOW);
    delay(200);
  }
}

int calculateSystolic() {
  // Simplified calculation based on heart rate
  return 90 + (beatAvg - 60) * 0.5;
}

int calculateDiastolic() {
  // Simplified calculation
  return 60 + (beatAvg - 60) * 0.3;
}

void sendSMSAlert(int systolic, int diastolic, int heartRate) {
  if (!sim800lReady) {
    Serial.println("SIM800L not ready for SMS");
    return;
  }
  
  String message = "ALERT: Abnormal BP detected! ";
  message += "BP: " + String(systolic) + "/" + String(diastolic);
  message += ", HR: " + String(heartRate);
  
  sim800l.println("AT+CMGS=\"" + phoneNumber + "\"");
  delay(1000);
  sim800l.println(message);
  delay(1000);
  sim800l.println((char)26); // Ctrl+Z to send
  delay(1000);
  
  Serial.println("SMS alert sent: " + message);
}

void sendStatus() {
  String status = "{";
  status += "\"systemReady\":" + String(systemReady ? "true" : "false") + ",";
  status += "\"max30102Ready\":" + String(max30102Ready ? "true" : "false") + ",";
  status += "\"sim800lReady\":" + String(sim800lReady ? "true" : "false") + ",";
  status += "\"isScanning\":" + String(isScanning ? "true" : "false");
  status += "}";
  
  Serial.println(status);
}

bool checkForBeat(long irValue) {
  // Simple beat detection algorithm
  static long lastValue = 0;
  static long threshold = 0;
  
  if (irValue > threshold && lastValue <= threshold) {
    return true;
  }
  
  lastValue = irValue;
  return false;
}









