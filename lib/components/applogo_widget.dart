import 'package:fapp/config_const.dart';
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

Widget appLogoWidget() {
  return Image.asset(
    icLogo,
    fit: BoxFit.cover,
    height: 100,
  ).box.white.padding(const EdgeInsets.all(10.0)).rounded.make();
}
