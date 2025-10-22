# ESP8266 + MAX30102 + SIM800L Setup Guide

## Hardware Components Required

### 1. LiLon ESP8266 Development Board
- WiFi-enabled microcontroller
- Built-in USB-to-Serial converter
- 3.3V and 5V power pins
- Multiple GPIO pins for sensor connections

### 2. MAX30102 Sensor
- Heart rate and SpO2 sensor
- I2C communication
- 3.3V operation

### 3. SIM800L v2 Module
- GSM/GPRS module for SMS
- 3.3V or 5V operation (check your module)
- Requires external antenna

### 4. Additional Components
- Breadboard and jumper wires
- 3.3V voltage regulator (if needed)
- Resistors (10kΩ, 4.7kΩ)
- Capacitors (100µF, 10µF)
- Power supply (5V/2A recommended)

## Wiring Diagram for LiLon ESP8266

### LiLon ESP8266 to MAX30102
```
LiLon ESP8266    MAX30102
---------------   --------
3.3V (VCC)    →   VIN
GND           →   GND
D1 (GPIO5)    →   SDA
D2 (GPIO4)    →   SCL
```

### LiLon ESP8266 to SIM800L
```
LiLon ESP8266    SIM800L
---------------   -------
3.3V (VCC)    →   VCC
GND           →   GND
D5 (GPIO14)   →   TX
D6 (GPIO12)   →   RX
D7 (GPIO13)   →   RST
D8 (GPIO15)   →   PWR (Power control)
```

### LiLon ESP8266 Pin Reference
```
Pin    GPIO    Function
---    ----    --------
D0     GPIO16  Built-in LED
D1     GPIO5   I2C SDA (MAX30102)
D2     GPIO4   I2C SCL (MAX30102)
D3     GPIO0   Boot mode (keep floating)
D4     GPIO2   Built-in LED (WiFi status)
D5     GPIO14  SoftwareSerial TX (SIM800L)
D6     GPIO12  SoftwareSerial RX (SIM800L)
D7     GPIO13  Reset pin (SIM800L)
D8     GPIO15  Power control (SIM800L)
```

## ESP8266 Arduino Code

```cpp
#include <Wire.h>
#include <SoftwareSerial.h>
#include "MAX30105.h"
#include "heartRate.h"

// LiLon ESP8266 Pin Definitions
#define LED_PIN 16        // D0 - Built-in LED
#define WIFI_LED_PIN 2    // D4 - WiFi status LED
#define SIM800L_TX 14     // D5 - SIM800L TX
#define SIM800L_RX 12      // D6 - SIM800L RX
#define SIM800L_RST 13     // D7 - SIM800L Reset
#define SIM800L_PWR 15     // D8 - SIM800L Power control

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

void setup() {
  Serial.begin(115200);
  sim800l.begin(9600);
  
  // Initialize LiLon ESP8266 pins
  pinMode(LED_PIN, OUTPUT);
  pinMode(WIFI_LED_PIN, OUTPUT);
  pinMode(SIM800L_RST, OUTPUT);
  pinMode(SIM800L_PWR, OUTPUT);
  
  // Initialize SIM800L
  digitalWrite(SIM800L_RST, HIGH);
  digitalWrite(SIM800L_PWR, HIGH);
  delay(2000); // Wait for SIM800L to boot
  
  // Initialize MAX30102 (I2C on D1/D2)
  Wire.begin(4, 5); // SDA=D2(4), SCL=D1(5) for LiLon ESP8266
  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("MAX30102 was not found");
    digitalWrite(LED_PIN, HIGH); // Error indicator
    while (1);
  }
  
  particleSensor.setup();
  particleSensor.setPulseAmplitudeRed(0x0A);
  particleSensor.setPulseAmplitudeGreen(0);
  
  // Initialize SIM800L communication
  sim800l.println("AT");
  delay(1000);
  sim800l.println("AT+CMGF=1"); // Set SMS text mode
  delay(1000);
  
  // Status LEDs
  digitalWrite(LED_PIN, LOW);      // Ready indicator
  digitalWrite(WIFI_LED_PIN, HIGH); // WiFi status
  
  Serial.println("LiLon ESP8266 + MAX30102 + SIM800L Ready");
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
    }
  }
  
  // If scanning, collect sensor data
  if (isScanning) {
    collectSensorData();
    
    // Check if scan is complete
    if (millis() - scanStartTime >= SCAN_DURATION) {
      completeScan();
    }
  }
  
  delay(100);
}

void startScanning() {
  isScanning = true;
  scanStartTime = millis();
  Serial.println("SCAN_STARTED");
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
  
  // Send data to Flutter app
  if (millis() % 1000 == 0) { // Send every second
    sendSensorData();
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
  // In reality, this requires complex algorithms
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
}

int calculateSystolic() {
  // Simplified calculation based on heart rate
  // Real implementation would use more complex algorithms
  return 90 + (beatAvg - 60) * 0.5;
}

int calculateDiastolic() {
  // Simplified calculation
  return 60 + (beatAvg - 60) * 0.3;
}

void sendSMSAlert(int systolic, int diastolic, int heartRate) {
  String message = "ALERT: Abnormal BP detected! ";
  message += "BP: " + String(systolic) + "/" + String(diastolic);
  message += ", HR: " + String(heartRate);
  
  sim800l.println("AT+CMGS=\"" + phoneNumber + "\"");
  delay(1000);
  sim800l.println(message);
  delay(1000);
  sim800l.println((char)26); // Ctrl+Z to send
  delay(1000);
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
```

## Flutter App Configuration

### 1. Update pubspec.yaml
Add the required dependencies (already done in the code above).

### 2. Android Permissions
Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.SEND_SMS" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
```

### 3. iOS Permissions
Add to `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to connect to your health monitoring device.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs Bluetooth to connect to your health monitoring device.</string>
```

## SMS Service Configuration

### Option 1: Twilio (Recommended)
1. Sign up for Twilio account
2. Get your Account SID and Auth Token
3. Purchase a phone number
4. Update the credentials in `lib/services/sms_service.dart`

### Option 2: AWS SNS
1. Set up AWS account
2. Configure SNS service
3. Update the SMS service implementation

### Option 3: Direct SIM800L Integration
- Modify the ESP8266 code to handle SMS directly
- Update the Flutter app to send commands via Bluetooth

## Testing Steps

1. **Hardware Setup**
   - Wire all components according to the diagram
   - Upload the Arduino code to ESP8266
   - Test individual components

2. **Bluetooth Connection**
   - Run the Flutter app
   - Navigate to Device tab
   - Scan for ESP8266 device
   - Connect to the device

3. **Sensor Testing**
   - Start a 60-second scan
   - Place finger on MAX30102 sensor
   - Monitor real-time data
   - Check if abnormal readings trigger SMS

4. **Firebase Integration**
   - Ensure Firebase is configured
   - Test data storage
   - Verify user profile setup

## LiLon ESP8266 Specific Notes

### Power Requirements:
- **USB Power**: 5V/1A minimum (use good quality USB cable)
- **External Power**: 5V/2A recommended for stable operation
- **3.3V Pin**: Can provide up to 600mA (sufficient for MAX30102)
- **5V Pin**: Can provide up to 1A (for SIM800L if 3.3V version)

### LiLon ESP8266 Features:
- **Built-in LEDs**: 
  - D0 (GPIO16): General purpose LED
  - D4 (GPIO2): WiFi status LED (blinks during connection)
- **USB-to-Serial**: Built-in CH340G chip
- **Reset Button**: Hold to enter bootloader mode
- **Flash Button**: Hold during reset for programming mode

### LiLon-Specific Wiring Tips:
1. **I2C Pull-up Resistors**: Add 4.7kΩ resistors on SDA/SCL lines
2. **SIM800L Power**: Use external 5V supply if using 5V SIM800L
3. **Antenna**: Ensure SIM800L antenna is properly connected
4. **Ground**: Connect all GND pins together

## Troubleshooting

### LiLon ESP8266 Specific Issues:
1. **Upload fails**: Hold Flash button during reset, then release reset
2. **No serial output**: Check USB cable and drivers (CH340G)
3. **WiFi LED not blinking**: Check power supply and connections
4. **I2C not working**: Verify pull-up resistors and wiring

### Common Issues:
1. **Bluetooth not connecting**: Check UUIDs and permissions
2. **No sensor data**: Verify MAX30102 wiring and I2C communication
3. **SMS not sending**: Check SIM800L wiring and phone number format
4. **App crashes**: Check permissions and dependencies

### Debug Tips:
- Use Serial Monitor (115200 baud) to debug ESP8266 code
- Monitor LED status: D0=ready, D4=WiFi status
- Check Flutter console for Bluetooth errors
- Verify Firebase rules and authentication
- Test SMS service with a simple message first

### LiLon ESP8266 LED Status:
- **D0 LED OFF**: System ready
- **D0 LED ON**: Error state (check connections)
- **D4 LED BLINKING**: WiFi connecting
- **D4 LED ON**: WiFi connected
- **D4 LED OFF**: WiFi disconnected

## Next Steps

1. **Calibration**: Fine-tune blood pressure calculation algorithms
2. **Machine Learning**: Implement ML models for better accuracy
3. **Cloud Integration**: Add more sophisticated data analysis
4. **User Interface**: Enhance the scanning experience
5. **Data Visualization**: Add charts and trends

## Safety Notes

⚠️ **Important**: This is a prototype system. For medical use:
- Validate all measurements with professional equipment
- Implement proper calibration procedures
- Add safety checks and error handling
- Consider regulatory requirements
- Consult with medical professionals

## Support

For technical support:
- Check the Flutter Blue Plus documentation
- Review MAX30102 datasheet
- Consult SIM800L manual
- Test each component individually before integration
