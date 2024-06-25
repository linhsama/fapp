// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fapp/components/applogo_widget.dart';
import 'package:fapp/components/disconnect_widget.dart';
import 'package:fapp/screens/home_screen.dart';
import 'package:fapp/config_const.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:velocity_x/velocity_x.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _checkPermissions(); // Check permissions on init
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      debugPrint('Couldn\'t check connectivity status: ${e.toString()}');
      return;
    }

    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
    });
  }

  void _checkPermissions() async {
    bool status;
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    if (deviceInfo.version.sdkInt > 32) {
      status = await Permission.photos.request().isGranted;
    } else {
      status = await Permission.storage.request().isGranted;
    }

    if (!status) {
      // Quyền bị từ chối, hiển thị thông báo cho người dùng
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission denied for storage")),
      );
    }
  }

  void _navigateToNextScreen() {
    Future.delayed(
      const Duration(seconds: 3),
      () {
        if (mounted) {
          Get.off(() => const HomeScreen());
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Image.asset(
                icSplashBg,
                width: 300.0,
              ),
            ),
            _connectionStatus == ConnectivityResult.none
                ? disconnectWidget()
                : appLogoWidget(),
            10.heightBox,
            _connectionStatus == ConnectivityResult.none
                ? "No internet connection"
                    .text
                    .fontFamily(semiBold)
                    .size(26.0)
                    .color(purpleColor)
                    .make()
                : "Application loaded"
                    .text
                    .fontFamily(semiBold)
                    .size(26.0)
                    .color(purpleColor)
                    .make(),
            10.heightBox,
            _connectionStatus == ConnectivityResult.none
                ? "Please check your connection.".text.color(purpleColor).make()
                : appVersion.text.color(purpleColor).make(),
            const Spacer(),
            if (_connectionStatus == ConnectivityResult.none)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.offAll(() => const SplashScreen()),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: redColor),
                      backgroundColor: redColor,
                    ),
                    child: "Retry"
                        .text
                        .fontFamily(semiBold)
                        .color(whiteColor)
                        .make(),
                  ),
                ],
              ),
            30.heightBox,
          ],
        ),
      ),
    );
  }
}
