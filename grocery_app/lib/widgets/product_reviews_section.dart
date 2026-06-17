import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../consts/firebase_consts.dart';
import '../providers/product_ratings_provider.dart';
import '../services/auth_gate_service.dart';
import '../services/utils.dart';
import 'text_widget.dart';

/// Ratings & reviews stored in Firestore collection `product_reviews`.
///
/// Rules idea (adjust for your project):
/// - allow read if true or auth != null
/// - allow create/update/delete only if request.auth.uid == resource.data.userId
///   and resource.data.productId matches path/query constraints
class ProductReviewsSection extends StatefulWidget {
  const ProductReviewsSection({
    super.key,
    required this.productId,
    this.accent = const Color(0xFFFF6B35),
  });

  final String productId;
  final Color accent;

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  final _commentController = TextEditingController();
  int _draftRating = 5;
  bool _submitting = false;

  static String _reviewDocId(String productId, String uid) {
    final safePid = productId.replaceAll(RegExp(r'[/\s]'), '_');
    return '${safePid}_$uid';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final user = await AuthGateService.requireVerifiedUser(
      context,
      message: 'Sign in with a verified account to leave a review.',
    );
    if (user == null) {
      return;
    }

    final comment = _commentController.text.trim();
    if (_draftRating < 1 || _draftRating > 5) return;

    setState(() => _submitting = true);
    try {
      final name = user.displayName ?? user.email ?? user.uid.substring(0, 8);
      final docId = _reviewDocId(widget.productId, user.uid);
      final ref =
          FirebaseFirestore.instance.collection('product_reviews').doc(docId);
      final existing = await ref.get();
      final payload = <String, dynamic>{
        'productId': widget.productId,
        'userId': user.uid,
        'userName': name,
        'rating': _draftRating,
        'comment': comment,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!existing.exists) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }
      await ref.set(payload, SetOptions(merge: true));

      if (!mounted) return;
      await context.read<ProductRatingsProvider>().refresh();
      if (!mounted) return;
      await Fluttertoast.showToast(
        msg: 'Thanks — your review was saved',
        gravity: ToastGravity.CENTER,
      );
      _commentController.clear();
      setState(() => _draftRating = 5);
    } catch (e) {
      if (mounted) {
        final denied = e is FirebaseException && e.code == 'permission-denied';
        await Fluttertoast.showToast(
          msg: denied
              ? 'Permission denied — allow product_reviews in Firestore rules'
              : 'Could not save review: $e',
          gravity: ToastGravity.CENTER,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Utils(context).color;
    final user = authInstance.currentUser;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
            text: 'Ratings & reviews',
            color: color,
            textSize: 20,
            isTitle: true,
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('product_reviews')
                .where('productId', isEqualTo: widget.productId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                final err = snapshot.error;
                final denied =
                    err is FirebaseException && err.code == 'permission-denied';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    denied
                        ? 'Reviews blocked by Firestore rules. Deploy firestore.rules '
                            '(Firebase Console → Firestore → Rules, or firebase deploy --only firestore:rules).'
                        : 'Could not load reviews',
                    style: TextStyle(color: color.withValues(alpha: 0.7)),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snapshot.data!.docs.toList()
                ..sort((a, b) {
                  final ta = a.data()['updatedAt'] as Timestamp?;
                  final tb = b.data()['updatedAt'] as Timestamp?;
                  if (ta == null && tb == null) return 0;
                  if (ta == null) return 1;
                  if (tb == null) return -1;
                  return tb.compareTo(ta);
                });

              double sum = 0;
              var count = 0;
              for (final d in docs) {
                final r = d.data()['rating'];
                if (r is int) {
                  sum += r.toDouble();
                  count++;
                } else if (r is double) {
                  sum += r;
                  count++;
                }
              }
              final avg = count > 0 ? sum / count : 0.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        avg > 0 ? avg.toStringAsFixed(1) : '—',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(5, (i) {
                              final filled = avg >= i + 0.5;
                              return Icon(
                                filled
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: widget.accent,
                                size: 18,
                              );
                            }),
                          ),
                          Text(
                            '$count review${count == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: color.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (docs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'No reviews yet — be the first.',
                        style: TextStyle(color: color.withValues(alpha: 0.65)),
                      ),
                    )
                  else
                    ...docs.map((d) => _reviewTile(d.data(), color)),
                ],
              );
            },
          ),
          const Divider(height: 32),
          TextWidget(
            text: user == null ? 'Sign in to review' : 'Your review',
            color: color,
            textSize: 16,
            isTitle: true,
          ),
          const SizedBox(height: 10),
          if (user == null)
            Text(
              'Log in from Profile to rate this product.',
              style: TextStyle(color: color.withValues(alpha: 0.65)),
            )
          else ...[
            Row(
              children: List.generate(5, (i) {
                final star = i + 1;
                final selected = star <= _draftRating;
                return InkWell(
                  onTap: () => setState(() => _draftRating = star),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      selected
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: selected
                          ? widget.accent
                          : color.withValues(alpha: 0.35),
                      size: 32,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Share your experience (optional)',
                hintStyle: TextStyle(color: color.withValues(alpha: 0.45)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: TextStyle(color: color),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submitReview,
                style: FilledButton.styleFrom(
                  backgroundColor: widget.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit review'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _reviewTile(Map<String, dynamic> data, Color color) {
    final name = (data['userName'] ?? 'User').toString();
    final rating = (data['rating'] is int)
        ? data['rating'] as int
        : int.tryParse('${data['rating']}') ?? 0;
    final comment = (data['comment'] ?? '').toString().trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.12)),
          color: Theme.of(context).cardColor.withValues(alpha: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 16,
                        color: widget.accent,
                      );
                    }),
                  ),
                ],
              ),
              if (comment.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  comment,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.85),
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
