import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F6DF3),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        'assets/design/icons/AppLogo.svg',
        width: 96,
      ),
    );
  }
}
