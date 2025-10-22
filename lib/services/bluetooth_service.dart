import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothManager {
  static final BluetoothManager _instance = BluetoothManager._internal();
  factory BluetoothManager() => _instance;
  BluetoothManager._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;
  final StreamController<Map<String, dynamic>> _dataController = StreamController.broadcast();
  final StreamController<String> _statusController = StreamController.broadcast();
  final StreamController<int> _scanProgressController = StreamController.broadcast();

  // Getters
  BluetoothDevice? get connectedDevice => _connectedDevice;
  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<int> get scanProgressStream => _scanProgressController.stream;

  // ESP8266 Service and Characteristic UUIDs (you'll need to define these)
  static const String SERVICE_UUID = "12345678-1234-1234-1234-123456789ABC";
  static const String WRITE_CHARACTERISTIC_UUID = "12345678-1234-1234-1234-123456789ABD";
  static const String READ_CHARACTERISTIC_UUID = "12345678-1234-1234-1234-123456789ABE";

  // Scan for ESP8266 devices
  Future<List<BluetoothDevice>> scanForDevices({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      _statusController.add("Scanning for devices...");
      
      // Check if Bluetooth is available
      if (!await FlutterBluePlus.isOn) {
        throw Exception("Bluetooth is not enabled");
      }

      List<BluetoothDevice> devices = [];
      
      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: timeout,
        withServices: [Guid(SERVICE_UUID)],
      );

      // Listen for scan results
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (result.device.platformName.isNotEmpty) {
            devices.add(result.device);
          }
        }
      });

      // Wait for scan to complete
      await Future.delayed(timeout);
      await FlutterBluePlus.stopScan();
      
      _statusController.add("Found ${devices.length} devices");
      return devices;
    } catch (e) {
      _statusController.add("Scan failed: $e");
      throw Exception("Failed to scan for devices: $e");
    }
  }

  // Connect to ESP8266 device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _statusController.add("Connecting to ${device.platformName}...");
      
      await device.connect();
      _connectedDevice = device;

      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      
      for (BluetoothService service in services) {
        if (service.uuid.toString().toUpperCase() == SERVICE_UUID.toUpperCase()) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toUpperCase() == WRITE_CHARACTERISTIC_UUID.toUpperCase()) {
              _writeCharacteristic = characteristic;
            }
            if (characteristic.uuid.toString().toUpperCase() == READ_CHARACTERISTIC_UUID.toUpperCase()) {
              _readCharacteristic = characteristic;
              await characteristic.setNotifyValue(true);
              characteristic.lastValueStream.listen(_onDataReceived);
            }
          }
        }
      }

      if (_writeCharacteristic == null || _readCharacteristic == null) {
        throw Exception("Required characteristics not found");
      }

      _statusController.add("Connected successfully");
      return true;
    } catch (e) {
      _statusController.add("Connection failed: $e");
      return false;
    }
  }

  // Start 60-second sensor scanning
  Future<void> startSensorScan() async {
    if (_writeCharacteristic == null) {
      throw Exception("Device not connected");
    }

    try {
      _statusController.add("Starting sensor scan...");
      
      // Send start command to ESP8266
      String command = "START_SCAN:60";
      await _writeCharacteristic!.write(utf8.encode(command));
      
      // Start progress tracking
      _startProgressTimer();
      
    } catch (e) {
      _statusController.add("Failed to start scan: $e");
      throw Exception("Failed to start sensor scan: $e");
    }
  }

  // Stop sensor scanning
  Future<void> stopSensorScan() async {
    if (_writeCharacteristic == null) return;

    try {
      String command = "STOP_SCAN";
      await _writeCharacteristic!.write(utf8.encode(command));
      _statusController.add("Scan stopped");
    } catch (e) {
      _statusController.add("Failed to stop scan: $e");
    }
  }

  // Handle incoming data from ESP8266
  void _onDataReceived(List<int> data) {
    try {
      String message = utf8.decode(data);
      Map<String, dynamic> sensorData = json.decode(message);
      
      // Process MAX30102 data
      _processSensorData(sensorData);
      
    } catch (e) {
      print("Error processing sensor data: $e");
    }
  }

  // Process MAX30102 sensor data
  void _processSensorData(Map<String, dynamic> data) {
    // Extract heart rate and SpO2 from MAX30102
    double heartRate = data['heartRate']?.toDouble() ?? 0.0;
    double spo2 = data['spo2']?.toDouble() ?? 0.0;
    int timestamp = data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;
    
    // Calculate blood pressure using heart rate and SpO2
    Map<String, dynamic> bloodPressure = _calculateBloodPressure(heartRate, spo2);
    
    // Emit processed data
    _dataController.add({
      'heartRate': heartRate,
      'spo2': spo2,
      'systolic': bloodPressure['systolic'],
      'diastolic': bloodPressure['diastolic'],
      'timestamp': timestamp,
      'rawData': data,
    });
  }

  // Calculate blood pressure from heart rate and SpO2
  Map<String, dynamic> _calculateBloodPressure(double heartRate, double spo2) {
    // This is a simplified calculation - you may need to adjust based on your research
    // Real blood pressure calculation from MAX30102 requires more complex algorithms
    
    double systolic = 90 + (heartRate - 60) * 0.5 + (100 - spo2) * 0.3;
    double diastolic = 60 + (heartRate - 60) * 0.3 + (100 - spo2) * 0.2;
    
    // Ensure values are within reasonable bounds
    systolic = systolic.clamp(80.0, 200.0);
    diastolic = diastolic.clamp(50.0, 120.0);
    
    return {
      'systolic': systolic.round(),
      'diastolic': diastolic.round(),
    };
  }

  // Start progress timer for 60-second scan
  void _startProgressTimer() {
    int elapsed = 0;
    Timer.periodic(Duration(seconds: 1), (timer) {
      elapsed++;
      _scanProgressController.add(elapsed);
      
      if (elapsed >= 60) {
        timer.cancel();
        _statusController.add("Scan completed");
      }
    });
  }

  // Check if blood pressure is abnormal
  bool isAbnormalBloodPressure(int systolic, int diastolic) {
    // Normal blood pressure: Systolic < 120, Diastolic < 80
    // Elevated: Systolic 120-129, Diastolic < 80
    // High: Systolic >= 130 or Diastolic >= 80
    
    return systolic >= 130 || diastolic >= 80;
  }

  // Disconnect from device
  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _writeCharacteristic = null;
        _readCharacteristic = null;
        _statusController.add("Disconnected");
      }
    } catch (e) {
      _statusController.add("Disconnect failed: $e");
    }
  }

  // Cleanup
  void dispose() {
    _dataController.close();
    _statusController.close();
    _scanProgressController.close();
  }
}
