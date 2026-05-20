import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/localization.dart';
import '../../models/worker_model.dart';
import '../../models/review_model.dart';
import '../../viewmodels/client_viewmodel.dart';

class WorkerReviewsPage extends StatefulWidget {
  final String workerId;

  const WorkerReviewsPage({super.key, required this.workerId});

  @override
  State<WorkerReviewsPage> createState() => _WorkerReviewsPageState();
}

class _WorkerReviewsPageState extends State<WorkerReviewsPage> {
  final Color primaryTeal = const Color(0xFF006D5B);
  List<CustomerReview>? reviews;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchReviews();
    });
  }

  Future<void> _fetchReviews() async {
    final clientVM = Provider.of<ClientViewModel>(context, listen: false);
    final data = await clientVM.getWorkerReviews(widget.workerId);
    if (mounted) {
      setState(() {
        reviews = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppLocalization.translate('reviews'),
          style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryTeal))
          : reviews == null
              ? const Center(child: Text('Failed to load reviews'))
              : _buildReviewsList(),
    );
  }

  Widget _buildReviewsList() {
    if (reviews!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              AppLocalization.translate('no_reviews_yet'),
              style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: reviews!.length,
      itemBuilder: (context, index) {
        final review = reviews![index];
        return _buildReviewCard(review);
      },
    );
  }

  Widget _buildReviewCard(CustomerReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review.customerName,
                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    review.rating.toStringAsFixed(1),
                    style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${review.date.day}/${review.date.month}/${review.date.year}',
            style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: GoogleFonts.cairo(color: Colors.grey[700], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
