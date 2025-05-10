import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/token_provider.dart';
import 'login_screen.dart';

class TokenVerificationWrapper extends ConsumerWidget {
  final Widget child;

  const TokenVerificationWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenState = ref.watch(tokenVerificationProvider);

    return tokenState.when(
      data: (isValid) {
        return isValid ? child : const SizedBox.shrink();
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.blue),
        ),
      ),
      error: (err, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err.toString()),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) =>  LoginScreen()),
            (route) => false,
          );
        });
        return const SizedBox.shrink();
      },
    );
  }
}
