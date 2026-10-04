import 'package:flutter/cupertino.dart';

final class AppInputField extends StatelessWidget {
  const AppInputField({
    required this.controller,
    required this.placeholder,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String placeholder;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => Semantics(
    label: placeholder,
    textField: true,
    child: CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
