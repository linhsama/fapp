// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:fapp/screens/splash_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:fapp/components/disconnect_widget.dart';
import 'package:fapp/config_const.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late InAppWebViewController _webViewController;
  String url = apiHome;
  double progress = 0;
  DateTime? lastPressed;

  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  @override
  void initState() {
    super.initState();
    initConnectivity();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
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

  Future<void> _downloadFile(BuildContext context, String url) async {
    bool status;
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    if (deviceInfo.version.sdkInt > 32) {
      status = await Permission.photos.request().isGranted;
    } else {
      status = await Permission.storage.request().isGranted;
    }

    if (!status) {
      // Permission denied, show a snackbar to inform the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission denied for storage")),
      );
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final savePath =
          "${tempDir.path}/${DateTime.now().microsecondsSinceEpoch}.png";
      await Dio().download(url, savePath);
      await GallerySaver.saveImage(savePath);
      debugPrint('Downloaded and saved at $savePath');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Download successful")),
      );
    } catch (error) {
      debugPrint("Download: ${error.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Download failed")),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (await _webViewController.canGoBack()) {
      _webViewController.goBack();
      return false;
    } else {
      if (lastPressed == null ||
          DateTime.now().difference(lastPressed!) >
              const Duration(seconds: 2)) {
        lastPressed = DateTime.now();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Press again to exit")),
        );
        return false;
      }
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: _connectionStatus == ConnectivityResult.none
          ? Scaffold(
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
                    disconnectWidget(),
                    10.heightBox,
                    "disconnet"
                        .text
                        .fontFamily(semiBold)
                        .size(26.0)
                        .color(purpleColor)
                        .make(),
                    10.heightBox,
                    "please check connection!".text.color(purpleColor).make(),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                          onPressed: () =>
                              Get.offAll(() => const SplashScreen()),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: redColor),
                            backgroundColor: redColor,
                          ),
                          child: Row(
                            children: [
                              "retry"
                                  .text
                                  .fontFamily(semiBold)
                                  .color(Colors.white)
                                  .make(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    30.heightBox,
                  ],
                ),
              ),
            )
          : Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: progress < 1.0
                    ? Row(
                        children: [
                          "loading".text.color(purpleColor).make(),
                          20.widthBox,
                          const SpinKitThreeBounce(
                            color: Colors.greenAccent,
                            size: 30.0,
                          ),
                        ],
                      )
                    : appName.text.color(purpleColor).make(),
                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.replay),
                    onPressed: () {
                      _webViewController.reload();
                    },
                  ),
                ],
              ),
              body: Column(
                children: <Widget>[
                  if (progress < 1.0) LinearProgressIndicator(value: progress),
                  Expanded(
                    child: InAppWebView(
                      initialUrlRequest: URLRequest(
                        url: WebUri(Uri.parse(url).toString()),
                      ),
                      initialOptions: InAppWebViewGroupOptions(
                        crossPlatform:
                            InAppWebViewOptions(useOnDownloadStart: true),
                      ),
                      onWebViewCreated: (InAppWebViewController controller) {
                        _webViewController = controller;
                      },
                      onLoadStart: (controller, url) {
                        setState(() {
                          this.url = url.toString();
                        });
                      },
                      onLoadStop: (controller, url) {
                        setState(() {
                          this.url = url?.toString() ?? '';
                        });
                      },
                      onProgressChanged: (controller, progress) {
                        setState(() {
                          this.progress = progress / 100;
                        });
                      },
                      onDownloadStartRequest:
                          (controller, DownloadStartRequest request) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Downloading...")),
                        );
                        _downloadFile(context, request.url.toString());
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
