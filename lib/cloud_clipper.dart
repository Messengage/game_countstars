import 'package:flutter/material.dart';

class CloudClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    // Desenhar a forma de nuvem
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.1, size.height * 0.3,
        size.width * 0.3, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.7,
        size.width * 0.7, size.height * 0.5);
    path.quadraticBezierTo(
        size.width * 0.9, size.height * 0.3, size.width, size.height * 0.5);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
