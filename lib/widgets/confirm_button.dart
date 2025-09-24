// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class ConfirmButton extends ConsumerWidget {
//   final VoidCallback onClick;
//   final String title;
//   final bool isEnabled;
//   final Color bgColor;
//   final bool isLoading;
//   const ConfirmButton({
//     super.key,
//     this.isEnabled = true,
//     this.bgColor = AppColors.primaryGreen,
//     required this.onClick,
//     required this.title,
//     this.isLoading = false,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final bool effectiveEnabled = isEnabled && !isLoading;

//     return GestureDetector(
//       onTap: () {
//         SystemChannels.textInput.invokeMethod('TextInput.hide');
//         if (effectiveEnabled) {
//           onClick();
//         } else {
//           null;
//         }
//       },
//       child: Container(
//         width: double.maxFinite,
//         height: 48,
//         padding: const EdgeInsets.symmetric(vertical: 13.0),
//         decoration: BoxDecoration(
//           color: effectiveEnabled ? bgColor : AppColors.bgFillBackground,
//           borderRadius: const BorderRadius.all(Radius.circular(8.0)),
//         ),
//         alignment: Alignment.center,
//         child: isLoading
//             ? const SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 5,
//                   valueColor:
//                       AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
//                 ),
//               )
//             : TextWidgets.mainSemiBold(
//                 title: title,
//                 color:
//                     effectiveEnabled ? AppColors.white : AppColors.textDisabled,
//                 fontSize: 16.0,
//               ),
//       ),
//     );
//   }
// }
