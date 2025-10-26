# ESP8266 Connection Test Script

## Quick Test Steps

### 1. Verify ESP8266 is Running
Your ESP8266 should show this output in Serial Monitor:
```
WiFi connected!
IP address: 192.168.1.61
HTTP server started
Device ready!
```

### 2. Test ESP8266 Endpoints Manually

Open a web browser and test these URLs (replace 192.168.1.61 with your actual IP):

#### Test Status Endpoint:
```
http://192.168.1.61:8080/status
```
**Expected Response:**
```json
{
  "name": "ESP8266 Health Monitor",
  "status": "ready",
  "ip": "192.168.1.61",
  "sensors": "MAX30102, OLED, BUZZER",
  "bpm": 0,
  "spo2": 0,
  "sbp": 0,
  "dbp": 0
}
```

#### Test Data Endpoint:
```
http://192.168.1.61:8080/data
```
**Expected Response:**
```json
{
  "bpm": 0,
  "spo2": 0,
  "sbp": 0,
  "dbp": 0,
  "status": "Unknown",
  "measuring": false,
  "timestamp": 1234567890,
  "irValue": 0,
  "redValue": 0
}
```

### 3. Test Start Scan Endpoint
Use a tool like Postman or curl to test:

**POST Request to:** `http://192.168.1.61:8080/start_scan`
**Body (JSON):**
```json
{
  "duration": 30,
  "timestamp": 1234567890
}
```

**Expected Response:**
```json
{
  "status": "scan_started",
  "duration": 30,
  "message": "Scan started successfully"
}
```

### 4. Flutter App Testing

1. **Run the Flutter app**
2. **Go to Device Scan screen**
3. **Tap "Scan" button** - should find your ESP8266 device
4. **Connect to the device** - should show "Connected successfully"
5. **Go to Measurement screen**
6. **Tap "Start Scanning"** - should start real measurement
7. **Place finger on MAX30102 sensor**
8. **Wait 30 seconds** - should receive real data

### 5. Troubleshooting

#### If ESP8266 not found:
- Check both devices are on same WiFi network
- Verify ESP8266 IP address in Serial Monitor
- Try manually entering IP address

#### If connection fails:
- Check firewall settings
- Verify ESP8266 is responding to browser test
- Check Serial Monitor for errors

#### If no data received:
- Ensure finger is properly placed on MAX30102 sensor
- Check Serial Monitor shows measurement progress
- Verify sensor readings (irValue should be > 5000 when finger is placed)

#### If measurement screen shows fake data:
- Make sure you're using the updated measurement_screen.dart
- Check that WiFi service is properly connected
- Verify data stream is receiving real data

### 6. Expected Data Flow

1. **ESP8266** reads MAX30102 sensor data
2. **ESP8266** calculates BPM, SpO2, and blood pressure
3. **ESP8266** sends data via HTTP to Flutter app
4. **Flutter app** receives real-time data updates
5. **Flutter app** displays real sensor readings
6. **Flutter app** saves data to Firebase
7. **Flutter app** sends SMS alert if abnormal

### 7. Debug Information

Check these logs:
- **ESP8266 Serial Monitor**: Shows sensor readings and HTTP requests
- **Flutter Debug Console**: Shows HTTP requests and responses
- **Network**: Use network analyzer to verify ESP8266 is reachable

The key difference now is that the measurement screen will show **real data from your ESP8266** instead of fake generated data!


