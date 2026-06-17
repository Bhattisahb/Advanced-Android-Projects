import 'package:flutter/material.dart';
import 'package:grocery_app/admin_fetch_screen.dart';
import 'package:grocery_app/app_scope.dart';
import 'package:grocery_app/fetch_screen.dart';

Widget postAuthHome(BuildContext context) {
  return AppScope.of(context).isCustomerApp
      ? const FetchScreen()
      : const AdminFetchScreen();
}
