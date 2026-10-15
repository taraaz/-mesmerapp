import 'package:flutter/material.dart';

class RememberMeCheckbox extends StatefulWidget {
  const RememberMeCheckbox({super.key});

  @override
  State<RememberMeCheckbox> createState() =>
      _RememberMeCheckboxState();
}

class _RememberMeCheckboxState
    extends State<RememberMeCheckbox> {
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          _rememberMe = !_rememberMe;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: _rememberMe,
            onChanged: (value) {
              setState(() {
                _rememberMe = value ?? false;
              });
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          const Text('Remember me'),
        ],
      ),
    );
  }
}
