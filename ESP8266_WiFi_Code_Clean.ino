#include <Wire.h>
#include "MAX30105.h"
#include <Adafruit_SSD1306.h>
#include <Adafruit_GFX.h>
#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <ArduinoJson.h>

#define BUZZER_PIN D5
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

// WiFi credentials - Change these to your network settings
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// Web server on port 8080
ESP8266WebServer server(8080);

MAX30105 particleSensor;

unsigned long lastBeat = 0;
unsigned long measureStart = 0;
bool measuring = false;
bool resultsShown = false;
bool scanStarted = false;

int bpm = 0;
float spo2 = 0;
long irValue = 0;
long redValue = 0;
long lastIRValue = 0;
float sbp = 0;
float dbp = 0;

String statusLabel = "Unknown";
String deviceName = "ESP8266 Health Monitor";

void setup() {
  Serial.begin(9600);
  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);

  // Initialize OLED
  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("OLED not found!");
    while (1);
  }

  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println("Initializing...");
  display.display();

  // Initialize MAX30102
  if (!particleSensor.begin(Wire, I2C_SPEED_STANDARD)) {
    Serial.println("MAX30102 not found!");
    display.clearDisplay();
    display.setCursor(0, 0);
    display.println("Sensor error!");
    display.display();
    while (1);
  }

  particleSensor.setup();
  particleSensor.setPulseAmplitudeRed(0x3F);
  particleSensor.setPulseAmplitudeIR(0x3F);
  particleSensor.setPulseAmplitudeGreen(0);

  // Connect to WiFi
  connectToWiFi();

  // Setup web server routes
  setupWebServer();

  display.clearDisplay();
  display.setCursor(0, 0);
  display.println("WiFi Connected!");
  display.print("IP: ");
  display.println(WiFi.localIP());
  display.println("Ready for scan");
  display.display();

  Serial.println("Device ready!");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

void connectToWiFi() {
  display.clearDisplay();
  display.setCursor(0, 0);
  display.println("Connecting to WiFi...");
  display.display();

  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.print(".");
    display.print(".");
    display.display();
  }
  
  Serial.println("");
  Serial.println("WiFi connected!");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

void handleStartScan() {
  Serial.println("=== /start_scan endpoint called ===");
  StaticJsonDocument<200> doc;
  
  // Debug: Print all available arguments
  Serial.print("Number of args: "); Serial.println(server.args());
  for (int i = 0; i < server.args(); i++) {
    Serial.print("Arg "); Serial.print(i); Serial.print(": ");
    Serial.print(server.argName(i)); Serial.print(" = ");
    Serial.println(server.arg(i));
  }
  
  // Try to get duration from query parameters (GET) or form data (POST)
  int duration = 30; // Default value
  bool foundDuration = false;
  
  if (server.hasArg("duration")) {
    duration = server.arg("duration").toInt();
    foundDuration = true;
    Serial.print("Duration from args: "); Serial.println(duration);
  }
  
  // If not found in args, try to parse JSON from plain body (POST)
  if (!foundDuration && server.hasArg("plain")) {
    String body = server.arg("plain");
    Serial.print("Plain body: "); Serial.println(body);
    
    StaticJsonDocument<200> requestDoc;
    DeserializationError error = deserializeJson(requestDoc, body);
    
    if (!error && requestDoc.containsKey("duration")) {
      duration = requestDoc["duration"];
      foundDuration = true;
      Serial.print("Duration from JSON: "); Serial.println(duration);
    }
  }
  
  Serial.print("Final duration: "); Serial.println(duration);
  
  Serial.print("Before start - measuring: "); Serial.print(measuring);
  Serial.print(", scanStarted: "); Serial.print(scanStarted);
  Serial.print(", resultsShown: "); Serial.println(resultsShown);
  
  if (!measuring && !resultsShown && !scanStarted) {
    // FIXED: Only set scanStarted, don't start measuring yet
    scanStarted = true;
    measuring = false;  // Don't start measuring until finger detected
    
    Serial.println("Scan started - waiting for finger detection");
    
    display.clearDisplay();
    display.setCursor(0, 0);
    display.println("Waiting for finger...");
    display.println("Place finger on sensor");
    display.display();
    
    doc["status"] = "scan_started";
    doc["duration"] = duration;
    doc["message"] = "Scan started - waiting for finger detection";
  } else {
    Serial.println("Error: Scan already in progress or results shown");
    doc["status"] = "error";
    doc["message"] = "Scan already in progress or results shown";
  }
  
  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
  Serial.println("=== /start_scan response sent ===");
}

void setupWebServer() {
  // Status endpoint
  server.on("/status", HTTP_GET, []() {
    StaticJsonDocument<200> doc;
    doc["name"] = deviceName;
    doc["status"] = measuring ? "scanning" : "ready";
    doc["ip"] = WiFi.localIP().toString();
    doc["sensors"] = "MAX30102, OLED, BUZZER";
    doc["bpm"] = bpm;
    doc["spo2"] = spo2;
    doc["sbp"] = sbp;
    doc["dbp"] = dbp;
    
    String response;
    serializeJson(doc, response);
    server.send(200, "application/json", response);
  });

  // Start scan endpoint - Handle both GET and POST requests
  server.on("/start_scan", HTTP_GET, handleStartScan);
  server.on("/start_scan", HTTP_POST, handleStartScan);

  // Stop scan endpoint
  server.on("/stop_scan", HTTP_POST, []() {
    Serial.println("=== /stop_scan endpoint called ===");
    StaticJsonDocument<200> doc;
    
    Serial.print("Before stop - measuring: "); Serial.print(measuring);
    Serial.print(", scanStarted: "); Serial.print(scanStarted);
    Serial.print(", resultsShown: "); Serial.println(resultsShown);
    
    if (measuring || scanStarted) {
      measuring = false;
      scanStarted = false;
      resultsShown = false;
      
      Serial.println("Scan stopped - all flags reset");
      
      display.clearDisplay();
      display.setCursor(0, 0);
      display.println("Scan stopped");
      display.println("Ready for scan");
      display.display();
      
      doc["status"] = "scan_stopped";
      doc["message"] = "Scan stopped successfully";
    } else {
      Serial.println("No scan in progress to stop");
      doc["status"] = "error";
      doc["message"] = "No scan in progress";
    }
    
    String response;
    serializeJson(doc, response);
    server.send(200, "application/json", response);
    Serial.println("=== /stop_scan response sent ===");
  });

  // Get real-time data endpoint
  server.on("/data", HTTP_GET, []() {
    StaticJsonDocument<300> doc;
    doc["bpm"] = bpm;
    doc["spo2"] = spo2;
    doc["sbp"] = sbp;
    doc["dbp"] = dbp;
    doc["status"] = statusLabel;
    doc["measuring"] = measuring;
    doc["scanStarted"] = scanStarted;  // Added this field
    doc["timestamp"] = millis();
    doc["irValue"] = irValue;
    doc["redValue"] = redValue;
    
    if (measuring) {
      unsigned long elapsed = millis() - measureStart;
      doc["elapsed"] = elapsed;
      doc["remaining"] = 30000 - elapsed;
    }
    
    String response;
    serializeJson(doc, response);
    server.send(200, "application/json", response);
  });

  // Reset endpoint - Force reset all scan flags
  server.on("/reset", HTTP_POST, []() {
    Serial.println("=== /reset endpoint called ===");
    StaticJsonDocument<200> doc;
    
    Serial.print("Before reset - measuring: "); Serial.print(measuring);
    Serial.print(", scanStarted: "); Serial.print(scanStarted);
    Serial.print(", resultsShown: "); Serial.println(resultsShown);
    
    measuring = false;
    scanStarted = false;
    resultsShown = false;
    bpm = 0;
    spo2 = 0;
    sbp = 0;
    dbp = 0;
    
    Serial.println("All flags reset to default state");
    
    display.clearDisplay();
    display.setCursor(0, 0);
    display.println("System reset");
    display.println("Ready for scan");
    display.display();
    
    doc["status"] = "reset";
    doc["message"] = "All flags reset successfully";
    
    String response;
    serializeJson(doc, response);
    server.send(200, "application/json", response);
    Serial.println("=== /reset response sent ===");
  });

  // Disconnect endpoint
  server.on("/disconnect", HTTP_POST, []() {
    StaticJsonDocument<200> doc;
    doc["status"] = "disconnected";
    doc["message"] = "Device disconnected";
    
    String response;
    serializeJson(doc, response);
    server.send(200, "application/json", response);
  });

  server.begin();
  Serial.println("HTTP server started");
}

void loop() {
  server.handleClient();
  
  irValue = particleSensor.getIR();
  redValue = particleSensor.getRed();

  // Debug: Print sensor values to Serial every 2 seconds
  if (millis() % 2000 < 100) {  
    Serial.print("IR: "); Serial.print(irValue);
    Serial.print(", Red: "); Serial.print(redValue);
    Serial.print(", scanStarted: "); Serial.print(scanStarted);
    Serial.print(", measuring: "); Serial.println(measuring);
    
    // Show sensor values on OLED when waiting for finger
    if (scanStarted && !measuring) {
      display.clearDisplay();
      display.setCursor(0, 0);
      display.println("Waiting for finger...");
      display.print("IR: "); display.println(irValue);
      display.print("Red: "); display.println(redValue);
      display.print("Threshold: 2000");
      display.display();
    }
  }

  // LOWERED THRESHOLD: Changed from 5000 to 2000 for easier finger detection
  if (irValue < 2000) {
    if (measuring) {
      // If we're measuring and finger is removed, stop measuring
      measuring = false;
      resultsShown = false;
      scanStarted = false;
      
      display.clearDisplay();
      display.setCursor(0, 0);
      display.println("Finger removed!");
      display.println("Place finger...");
      display.display();
    } else if (resultsShown) {
      // If results are shown and finger is removed, reset for new scan
      resultsShown = false;
      scanStarted = false;
      
      display.clearDisplay();
      display.setCursor(0, 0);
      display.println("Place finger...");
      display.display();
    }
    // If scanStarted is true but no finger, keep waiting (don't reset scanStarted)
    delay(200);
    return;
  }

  // FIXED: Start measuring when finger is detected AND scan is started
  if (!measuring && !resultsShown && scanStarted) {
    Serial.println("Finger detected - starting measurement!");
    measuring = true;
    measureStart = millis();
    bpm = 0;
    spo2 = 0;
    sbp = dbp = 0;

    display.clearDisplay();
    display.setCursor(0, 0);
    display.println("Measuring 30s...");
    display.display();
  }

  if (measuring) {
    unsigned long elapsed = millis() - measureStart;
    long delta = irValue - lastIRValue;
    if (delta > 50 && millis() - lastBeat > 500) {
      unsigned long now = millis();
      bpm = 60000 / (now - lastBeat);
      lastBeat = now;
      if (bpm < 40 || bpm > 180) bpm = 0;
    }
    lastIRValue = irValue;

    float ratio = (float)redValue / (float)irValue;
    spo2 = 104.0 - 17.0 * ratio;
    spo2 = constrain(spo2, 70, 100);

    sbp = 90 + (bpm * 0.25) - ((spo2 - 95) * 0.5);
    dbp = 60 + (bpm * 0.15) - ((spo2 - 95) * 0.3);
    sbp = constrain(sbp, 80, 180);
    dbp = constrain(dbp, 50, 120);

    display.clearDisplay();
    display.setCursor(0, 0);
    display.print("Scanning: ");
    display.print(30 - (elapsed / 1000));
    display.println("s left");
    display.setCursor(0, 16);
    display.print("BPM: "); display.println(bpm);
    display.print("O2: "); display.print((int)spo2); display.println("%");
    display.print("BP: "); display.print((int)sbp);
    display.print("/"); display.print((int)dbp); display.println(" mmHg");
    display.display();

    if (elapsed >= 30000) {
      measuring = false;
      resultsShown = true;
      scanStarted = false;

      if (sbp >= 90 && sbp <= 120 && dbp >= 60 && dbp <= 80) {
        statusLabel = "Normal";
      } else if (sbp < 90 || dbp < 60) {
        statusLabel = "Low BP";
      } else if (sbp > 120 || dbp > 80) {
        statusLabel = "High BP";
      }

      display.clearDisplay();
      display.setCursor(0, 0);
      display.println("=== FINAL RESULTS ===");
      display.setCursor(0, 16);
      display.print("BPM: "); display.println(bpm);
      display.print("O2: "); display.print((int)spo2); display.println("%");
      display.print("BP: "); display.print((int)sbp);
      display.print("/"); display.print((int)dbp); display.println(" mmHg");
      display.print("Status: "); display.println(statusLabel);
      display.display();

      Serial.println("=== FINAL RESULTS ===");
      Serial.print("BPM: "); Serial.println(bpm);
      Serial.print("SpO2: "); Serial.println(spo2);
      Serial.print("SBP: "); Serial.println(sbp);
      Serial.print("DBP: "); Serial.println(dbp);
      Serial.print("Status: "); Serial.println(statusLabel);

      buzzerPattern(statusLabel);
    }
  }

  delay(100);
}

void buzzerPattern(String status) {
  if (status == "Normal") {
    tone(BUZZER_PIN, 1000, 700);
    delay(700);
    noTone(BUZZER_PIN);
  } else if (status == "Low BP") {
    for (int i = 0; i < 3; i++) {
      tone(BUZZER_PIN, 800, 300);
      delay(600);
      noTone(BUZZER_PIN);
    }
  } else if (status == "High BP") {
    for (int i = 0; i < 4; i++) {
      tone(BUZZER_PIN, 1200, 150);
      delay(300);
      noTone(BUZZER_PIN);
    }
  }
}
