import 'package:flutter/material.dart';

// Global notifier — call this anywhere to instantly switch language
final localeNotifier = ValueNotifier<Locale>(const Locale('en'));