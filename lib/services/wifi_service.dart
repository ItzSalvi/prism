import 'dart:async';
import 'dart:convert';
import 'dart:io';

class WiFiDeviceManager {
  static final WiFiDeviceManager _instance = WiFiDeviceManager._internal();
  factory WiFiDeviceManager() => _instance;
  WiFiDeviceManager._internal();

  String? _deviceIP;
  int? _devicePort;
  bool _isConnected = false;
  
  StreamController<Map<String, dynamic>> _dataController = StreamController.broadcast();
  StreamController<String> _statusController = StreamController.broadcast();
  StreamController<int> _scanProgressController = StreamController.broadcast();
  StreamController<List<Map<String, dynamic>>> _devicesController = StreamController.broadcast();

  // Getters
  bool get isConnected => _isConnected;
  String? get deviceIP => _deviceIP;
  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<int> get scanProgressStream => _scanProgressController.stream;
  Stream<List<Map<String, dynamic>>> get devicesStream => _devicesController.stream;

  // Default ESP8266 configuration
  static const int DEFAULT_PORT = 8080;
  static const Duration CONNECTION_TIMEOUT = Duration(seconds: 5);
  static const Duration SCAN_TIMEOUT = Duration(seconds: 10);

  // Helper method to safely add status updates
  void _addStatusUpdate(String status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  // Helper method to safely add device updates
  void _addDeviceUpdate(List<Map<String, dynamic>> devices) {
    if (!_devicesController.isClosed) {
      _devicesController.add(devices);
    }
  }

  // Scan for ESP8266 devices on local network
  Future<List<Map<String, dynamic>>> scanForDevices({Duration timeout = SCAN_TIMEOUT}) async {
    _ensureControllersActive();
    try {
      _addStatusUpdate("Scanning for ESP8266 devices...");
      
      List<Map<String, dynamic>> devices = [];
      
      // Get local network IP range
      String? localIP = await _getLocalIP();
      if (localIP == null) {
        throw Exception("Could not determine local IP address");
      }
      
      String networkPrefix = localIP.substring(0, localIP.lastIndexOf('.'));
      
      // Scan common IP addresses in the network
      List<Future<Map<String, dynamic>?>> scanTasks = [];
      
      for (int i = 1; i <= 254; i++) {
        String targetIP = '$networkPrefix.$i';
        scanTasks.add(_scanIP(targetIP));
      }
      
      // Wait for all scans to complete or timeout
      List<Map<String, dynamic>?> results = await Future.wait(
        scanTasks,
        eagerError: false,
      );
      
      // Filter out null results (devices not found)
      devices = results.where((device) => device != null).cast<Map<String, dynamic>>().toList();
      
      _addDeviceUpdate(devices);
      _addStatusUpdate("Found ${devices.length} ESP8266 devices");
      
      return devices;
    } catch (e) {
      _addStatusUpdate("Scan failed: $e");
      throw Exception("Failed to scan for devices: $e");
    }
  }

  // Scan a specific IP address
  Future<Map<String, dynamic>?> _scanIP(String ip) async {
    try {
      HttpClient client = HttpClient();
      client.connectionTimeout = Duration(seconds: 2);
      
      HttpClientRequest request = await client.getUrl(Uri.parse('http://$ip:$DEFAULT_PORT/status'));
      HttpClientResponse response = await request.close();
      
      if (response.statusCode == 200) {
        String responseBody = await response.transform(utf8.decoder).join();
        Map<String, dynamic> deviceInfo = json.decode(responseBody);
        
        return {
          'ip': ip,
          'port': DEFAULT_PORT,
          'name': deviceInfo['name'] ?? 'ESP8266 Device',
          'status': deviceInfo['status'] ?? 'ready',
          'sensors': deviceInfo['sensors'] ?? ['MAX30102', 'OLED', 'BUZZER'],
          'lastSeen': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      // Device not found or not responding - this is normal during scanning
    }
    return null;
  }

  // Connect to ESP8266 device
  Future<bool> connectToDevice(String ip, {int port = DEFAULT_PORT}) async {
    _ensureControllersActive();
    try {
      _addStatusUpdate("Connecting to $ip:$port...");
      
      // Test HTTP connection first
      HttpClient client = HttpClient();
      client.connectionTimeout = CONNECTION_TIMEOUT;
      
      HttpClientRequest request = await client.getUrl(Uri.parse('http://$ip:$port/status'));
      HttpClientResponse response = await request.close();
      
      if (response.statusCode == 200) {
        String responseBody = await response.transform(utf8.decoder).join();
        Map<String, dynamic> deviceInfo = json.decode(responseBody);
        
        _deviceIP = ip;
        _devicePort = port;
        _isConnected = true;
        
        _addStatusUpdate("Connected to ${deviceInfo['name'] ?? 'ESP8266 Device'}");
        return true;
      } else {
        throw Exception("Device responded with status code: ${response.statusCode}");
      }
    } catch (e) {
      _addStatusUpdate("Connection failed: $e");
      return false;
    }
  }

  // Start sensor scanning
  Future<void> startSensorScan() async {
    _ensureControllersActive();
    if (!_isConnected || _deviceIP == null) {
      throw Exception("Device not connected");
    }

    try {
      _addStatusUpdate("Starting sensor scan...");
      
      // Send start command to ESP8266 - Try GET request with query parameters
      HttpClient client = HttpClient();
      HttpClientRequest request = await client.getUrl(
        Uri.parse('http://$_deviceIP:$_devicePort/start_scan?duration=30&timestamp=${DateTime.now().millisecondsSinceEpoch}')
      );
      
      print('Sending GET request to: http://$_deviceIP:$_devicePort/start_scan?duration=30&timestamp=${DateTime.now().millisecondsSinceEpoch}');
      
      HttpClientResponse response = await request.close();
      
      if (response.statusCode == 200) {
        _startProgressTimer();
        _addStatusUpdate("Scan started successfully");
      } else {
        throw Exception("Failed to start scan. Status: ${response.statusCode}");
      }
    } catch (e) {
      _addStatusUpdate("Failed to start scan: $e");
      throw Exception("Failed to start sensor scan: $e");
    }
  }

  // Stop sensor scanning
  Future<void> stopSensorScan() async {
    if (!_isConnected || _deviceIP == null) return;

    try {
      HttpClient client = HttpClient();
      HttpClientRequest request = await client.postUrl(
        Uri.parse('http://$_deviceIP:$_devicePort/stop_scan')
      );
      
      HttpClientResponse response = await request.close();
      
      if (response.statusCode == 200) {
        _addStatusUpdate("Scan stopped");
      }
    } catch (e) {
      _addStatusUpdate("Failed to stop scan: $e");
    }
  }

  // Get real-time data from device
  Future<Map<String, dynamic>?> getRealTimeData() async {
    if (!_isConnected || _deviceIP == null) return null;

    try {
      HttpClient client = HttpClient();
      HttpClientRequest request = await client.getUrl(
        Uri.parse('http://$_deviceIP:$_devicePort/data')
      );
      
      HttpClientResponse response = await request.close();
      
      if (response.statusCode == 200) {
        String responseBody = await response.transform(utf8.decoder).join();
        Map<String, dynamic> data = json.decode(responseBody);
        
        // Process and emit the data
        _processSensorData(data);
        return data;
      }
    } catch (e) {
      print("Error getting real-time data: $e");
    }
    return null;
  }

  // Process sensor data from ESP8266
  void _processSensorData(Map<String, dynamic> data) {
    try {
      // Extract data from ESP8266 response
      int bpm = data['bpm'] ?? 0;
      double spo2 = data['spo2']?.toDouble() ?? 0.0;
      double sbp = data['sbp']?.toDouble() ?? 0.0;
      double dbp = data['dbp']?.toDouble() ?? 0.0;
      String status = data['status'] ?? 'Unknown';
      int timestamp = data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;
      
      // Emit processed data only if controller is not closed
      if (!_dataController.isClosed) {
        _dataController.add({
          'heartRate': bpm,
          'spo2': spo2,
          'systolic': sbp.round(),
          'diastolic': dbp.round(),
          'status': status,
          'timestamp': timestamp,
          'rawData': data,
        });
      }
    } catch (e) {
      print("Error processing sensor data: $e");
    }
  }

  // Start progress timer for scan
  void _startProgressTimer() {
    int elapsed = 0;
    bool deviceStartedMeasuring = false;
    
    Timer.periodic(Duration(seconds: 1), (timer) {
      elapsed++;
      
      // Get real-time data every second (async call)
      getRealTimeData().then((data) {
        if (data != null) {
          // Check if device has actually started measuring
          if (data['measuring'] == true && !deviceStartedMeasuring) {
            deviceStartedMeasuring = true;
            _addStatusUpdate("Device started measuring!");
          }
          
          // Check if scan was started but waiting for finger
          if (data['scanStarted'] == true && !deviceStartedMeasuring) {
            if (!_statusController.isClosed) {
              _statusController.add("Waiting for finger detection...");
            }
          }
          
          // Only start progress when device is actually measuring
          if (deviceStartedMeasuring) {
            // Only add progress if controller is not closed
            if (!_scanProgressController.isClosed) {
              _scanProgressController.add(elapsed);
            }
          }
        }
      });
      
      if (elapsed >= 30) {
        timer.cancel();
        if (!_statusController.isClosed) {
          _statusController.add("Scan completed");
        }
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

  // Get local IP address
  Future<String?> _getLocalIP() async {
    try {
      for (NetworkInterface interface in await NetworkInterface.list()) {
        for (InternetAddress address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4 && !address.isLoopback) {
            return address.address;
          }
        }
      }
    } catch (e) {
      print("Error getting local IP: $e");
    }
    return null;
  }

  // Reset device state
  Future<void> resetDevice() async {
    if (!_isConnected || _deviceIP == null) return;

    try {
      HttpClient client = HttpClient();
      HttpClientRequest request = await client.postUrl(
        Uri.parse('http://$_deviceIP:$_devicePort/reset')
      );
      
      HttpClientResponse response = await request.close();
      
      if (response.statusCode == 200) {
        _addStatusUpdate("Device reset successfully");
      }
    } catch (e) {
      _addStatusUpdate("Failed to reset device: $e");
    }
  }

  // Disconnect from device
  Future<void> disconnect() async {
    try {
      if (_isConnected && _deviceIP != null) {
        // Send disconnect command
        HttpClient client = HttpClient();
        HttpClientRequest request = await client.postUrl(
          Uri.parse('http://$_deviceIP:$_devicePort/disconnect')
        );
        await request.close();
      }
      
      _isConnected = false;
      _deviceIP = null;
      _devicePort = null;
      _addStatusUpdate("Disconnected");
    } catch (e) {
      _addStatusUpdate("Disconnect failed: $e");
    }
  }

  // Reinitialize service if controllers are closed
  void _ensureControllersActive() {
    if (_dataController.isClosed) {
      _dataController = StreamController<Map<String, dynamic>>.broadcast();
    }
    if (_statusController.isClosed) {
      _statusController = StreamController<String>.broadcast();
    }
    if (_scanProgressController.isClosed) {
      _scanProgressController = StreamController<int>.broadcast();
    }
    if (_devicesController.isClosed) {
      _devicesController = StreamController<List<Map<String, dynamic>>>.broadcast();
    }
  }

  // Cleanup
  void dispose() {
    _dataController.close();
    _statusController.close();
    _scanProgressController.close();
    _devicesController.close();
  }
}
