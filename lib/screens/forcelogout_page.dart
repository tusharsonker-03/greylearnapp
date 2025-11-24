// import 'package:flutter/material.dart';
//
// import 'auth_screen.dart';
//
// class ForceLogoutScreen extends StatelessWidget {
//   const ForceLogoutScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // 👇 Emoji instead of image
//               const Text(
//                 "😔",
//                 style: TextStyle(
//                   fontSize: 100, // bada emoji
//                 ),
//               ),
//               const SizedBox(height: 20),
//               const Text(
//                 "At a time only one login is allowed.",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 30),
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.of(context).pushNamedAndRemoveUntil(
//                     AuthScreen.routeName,
//                         (route) => false,
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green, // 👈 button background green
//                   padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 child: const Text(
//                   "Login Again",
//                   style: TextStyle(
//                     color: Colors.white, // 👈 text white
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
