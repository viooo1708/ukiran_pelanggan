import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<VerifyOtpScreen> createState() =>
      _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _showSnackBar(
    String message, {
    bool isSuccess = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isSuccess
            ? const Color(0xFF059669)
            : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      _showSnackBar(
        'Masukkan kode OTP 6 digit.',
      );
      return;
    }

    final authProvider =
        Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final success = await authProvider.verifyOtp(
      widget.email,
      otp,
    );

    if (!mounted) return;

    if (success) {
      _showSnackBar(
        'Email berhasil diverifikasi. Silakan login.',
        isSuccess: true,
      );

      await Future.delayed(
        const Duration(milliseconds: 800),
      );

      if (!mounted) return;

      // Kembali ke Login
      Navigator.popUntil(
        context,
        (route) => route.isFirst,
      );
    } else {
      _showSnackBar(
        authProvider.errorMessage,
      );
    }
  }

  Future<void> _resendOtp() async {
    final authProvider =
        Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final success =
        await authProvider.resendOtp(widget.email);

    if (!mounted) return;

    if (success) {
      _showSnackBar(
        'Kode OTP baru telah dikirim ke email Anda.',
        isSuccess: true,
      );
    } else {
      _showSnackBar(
        authProvider.errorMessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        Provider.of<AuthProvider>(context).isLoading;

    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text(
          'Verifikasi Email',
          style: TextStyle(fontSize: 16),
        ),
        backgroundColor:
            Theme.of(context).scaffoldBackgroundColor,

        bottom: PreferredSize(
          preferredSize:
              const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFEADFD8),
            height: 1,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),

            child: Container(
              constraints:
                  const BoxConstraints(
                maxWidth: 480,
              ),

              padding:
                  const EdgeInsets.all(32),

              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(24),
                border: Border.all(
                  color:
                      const Color(0xFFEADFD8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF5D4037,
                    ).withOpacity(0.04),
                    blurRadius: 24,
                    offset:
                        const Offset(0, 12),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,

                children: [

                  const Icon(
                    Icons.mark_email_read_outlined,
                    size: 64,
                    color: Color(0xFF5D4037),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Verifikasi Email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF3E2723),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Kode OTP telah dikirim ke:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    widget.email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),

                  const SizedBox(height: 30),

                  TextField(
                    controller:
                        _otpController,
                    keyboardType:
                        TextInputType.number,
                    maxLength: 6,
                    textAlign:
                        TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: Color(0xFF3E2723),
                    ),
                    decoration:
                        InputDecoration(
                      counterText: '',
                      hintText: '000000',
                      hintStyle:
                          TextStyle(
                        color: Colors
                            .grey.shade300,
                        letterSpacing: 8,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    height: 52,
                    child:
                        ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : _verify,

                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(
                                color:
                                    Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'VERIFIKASI EMAIL',
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 13,
                                letterSpacing:
                                    1,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed:
                        isLoading
                            ? null
                            : _resendOtp,
                    child: const Text(
                      'Kirim Ulang Kode OTP',
                      style: TextStyle(
                        color:
                            Color(0xFF5D4037),
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Kode OTP berlaku selama 10 menit.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}