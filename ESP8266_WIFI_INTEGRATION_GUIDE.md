# ESP8266 WiFi Integration Setup Guide

## Overview
This guide will help you integrate your ESP8266 device with your Flutter app using WiFi communication instead of SMS. The system now supports:

- **WiFi-based device discovery** - Automatically finds ESP8266 devices on your local network
- **Real-time data transmission** - Sends sensor data from ESP8266 to Flutter app via HTTP
- **User authentication** - Only sends data to logged-in users
- **Firebase integration** - Stores measurements in Firebase
- **SMS alerts** - Still sends SMS for abnormal readings

## Hardware Requirements
- ESP8266 (LoLin model)
- MAX30102 sensor
- OLED display (SSD1306)
- Buzzer
- Jumper wires
- Breadboard (optional)

## Software Requirements
- Arduino IDE
- Flutter SDK
- Firebase project setup

## Step 1: ESP8266 Setup

### 1.1 Install Required Libraries
In Arduino IDE, install these libraries:
- **MAX30105** by SparkFun
- **Adafruit SSD1306** by Adafruit
- **Adafruit GFX Library** by Adafruit
- **ArduinoJson** by Benoit Blanchon
- **ESP8266WiFi** (included with ESP8266 board package)

### 1.2 Configure WiFi Credentials
Edit the `ESP8266_WiFi_Code.ino` file and update these lines:

```cpp
// WiFi credentials - Change these to your network settings
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";
```

### 1.3 Upload Code to ESP8266
1. Select your ESP8266 board in Arduino IDE
2. Set the correct COM port
3. Upload the `ESP8266_WiFi_Code.ino` file
4. Open Serial Monitor to see the IP address

### 1.4 Hardware Connections
```
ESP8266 Pin → Component
D1 (GPIO5) → SDA (MAX30102)
D2 (GPIO4) → SCL (MAX30102)
D5 (GPIO14) → Buzzer (+)
GND → Buzzer (-)
3.3V → VCC (MAX30102, OLED)
GND → GND (MAX30102, OLED)
D1 (GPIO5) → SDA (OLED)
D2 (GPIO4) → SCL (OLED)
```

## Step 2: Flutter App Setup

### 2.1 Dependencies
The following dependencies are already included in your `pubspec.yaml`:
- `http: ^1.1.0` - For HTTP communication
- `provider: ^6.1.2` - For state management
- `cloud_firestore: ^5.4.0` - For Firebase integration

### 2.2 New Files Created
- `lib/services/wifi_service.dart` - WiFi communication service
- `ESP8266_WiFi_Code.ino` - Modified ESP8266 code

### 2.3 Modified Files
- `lib/screens/device_scan_screen.dart` - Updated to use WiFi instead of Bluetooth

## Step 3: Network Configuration

### 3.1 Ensure Same Network
- ESP8266 and your phone/device must be on the same WiFi network
- ESP8266 will get an IP address like `192.168.1.100` (check Serial Monitor)

### 3.2 Firewall Settings
- Ensure your router doesn't block device-to-device communication
- Some corporate networks may block this - use a personal hotspot if needed

## Step 4: Testing the Integration

### 4.1 ESP8266 Testing
1. Upload the code and check Serial Monitor
2. You should see:
   ```
   WiFi connected!
   IP address: 192.168.1.100
   HTTP server started
   Device ready!
   ```

### 4.2 Flutter App Testing
1. Run the Flutter app
2. Go to Device Scan screen
3. Tap "Scan" to find ESP8266 devices
4. Connect to your device
5. Tap "Start Scan" to begin measurement

## Step 5: API Endpoints

The ESP8266 exposes these HTTP endpoints:

### GET /status
Returns device information and current status
```json
{
  "name": "ESP8266 Health Monitor",
  "status": "ready",
  "ip": "192.168.1.100",
  "sensors": "MAX30102, OLED, BUZZER",
  "bpm": 0,
  "spo2": 0,
  "sbp": 0,
  "dbp": 0
}
```

### POST /start_scan
Starts a 30-second measurement
```json
{
  "duration": 30,
  "timestamp": 1234567890
}
```

### GET /data
Returns real-time sensor data
```json
{
  "bpm": 72,
  "spo2": 98.5,
  "sbp": 120,
  "dbp": 80,
  "status": "Normal",
  "measuring": true,
  "timestamp": 1234567890,
  "irValue": 50000,
  "redValue": 45000
}
```

### POST /stop_scan
Stops the current measurement

### POST /disconnect
Disconnects the device

## Step 6: Troubleshooting

### Common Issues

#### ESP8266 Won't Connect to WiFi
- Check SSID and password
- Ensure WiFi network is 2.4GHz (ESP8266 doesn't support 5GHz)
- Check signal strength

#### App Can't Find Device
- Ensure both devices are on same network
- Check ESP8266 IP address in Serial Monitor
- Try manually entering IP address

#### No Data Received
- Check if measurement is actually running
- Verify finger placement on MAX30102 sensor
- Check Serial Monitor for error messages

#### Connection Timeout
- Increase timeout values in `wifi_service.dart`
- Check network stability
- Ensure ESP8266 is not in deep sleep mode

### Debug Steps
1. **ESP8266 Serial Monitor**: Check for error messages
2. **Flutter Debug Console**: Look for HTTP request/response logs
3. **Network Scanner**: Use apps like "Network Analyzer" to verify ESP8266 is reachable
4. **Browser Test**: Try accessing `http://ESP8266_IP:8080/status` in browser

## Step 7: Security Considerations

### Network Security
- Use WPA2/WPA3 WiFi encryption
- Consider using a dedicated IoT network
- Implement device authentication if needed

### Data Security
- All data is transmitted over local network only
- Firebase handles data encryption
- SMS alerts use your existing SMS service

## Step 8: Advanced Configuration

### Customizing Scan Duration
In `ESP8266_WiFi_Code.ino`, modify:
```cpp
if (elapsed >= 30000) { // Change 30000 to desired duration in milliseconds
```

### Adding More Sensors
1. Add sensor initialization in `setup()`
2. Add sensor reading in `loop()`
3. Include sensor data in API responses
4. Update Flutter app to handle new data

### Multiple Devices
The system supports multiple ESP8266 devices on the same network. Each device will appear in the scan results with its unique IP address.

## Step 9: Production Deployment

### ESP8266 Production Setup
1. Use fixed IP addresses for reliability
2. Implement OTA updates for firmware
3. Add error recovery mechanisms
4. Consider power management for battery operation

### Flutter App Production
1. Add proper error handling
2. Implement retry mechanisms
3. Add data validation
4. Consider offline capabilities

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify all connections and configurations
3. Test with a simple HTTP request first
4. Check Serial Monitor for ESP8266 errors
5. Review Flutter debug console for app errors

The integration provides a robust, WiFi-based communication system between your ESP8266 health monitoring device and Flutter app, eliminating the need for SMS while maintaining all the original functionality.


