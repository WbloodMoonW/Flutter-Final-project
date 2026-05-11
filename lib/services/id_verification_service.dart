class IdVerificationResult {
  final bool isNationalId;
  final String message;
  final String recognizedText;

  const IdVerificationResult({
    required this.isNationalId,
    required this.message,
    this.recognizedText = '',
  });
}

class IdVerificationService {
  Future<IdVerificationResult> verify(String imagePath) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return const IdVerificationResult(
      isNationalId: true,
      message: 'تم رفع الصورة بنجاح ✅',
    );
  }
}
