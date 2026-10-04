import 'package:flutter/cupertino.dart';

final class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isDestructive = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: CupertinoButton.filled(
      onPressed: isLoading ? null : onPressed,
      color: isDestructive ? CupertinoColors.destructiveRed : null,
      child: isLoading
          ? const CupertinoActivityIndicator()
          : Text(label, textAlign: TextAlign.center),
    ),
  );
}
