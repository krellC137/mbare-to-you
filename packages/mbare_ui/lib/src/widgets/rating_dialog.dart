import 'package:flutter/material.dart';
import 'package:mbare_ui/mbare_ui.dart';

/// Dialog for rating and reviewing a vendor or driver
class RatingDialog extends StatefulWidget {
  const RatingDialog({
    required this.targetName,
    required this.targetType,
    this.existingRating,
    this.existingComment,
    required this.onSubmit,
    super.key,
  });

  final String targetName;
  final String targetType; // "vendor" or "driver"
  final int? existingRating;
  final String? existingComment;
  final Future<bool> Function(int rating, String? comment) onSubmit;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late int _rating;
  late TextEditingController _commentController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingRating ?? 0;
    _commentController = TextEditingController(text: widget.existingComment);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final comment = _commentController.text.trim();
      final success = await widget.onSubmit(
        _rating,
        comment.isEmpty ? null : comment,
      );

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit review. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existingRating != null
            ? 'Edit Your Review'
            : 'Rate ${widget.targetType == 'vendor' ? 'Vendor' : 'Driver'}',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target name
            Text(
              widget.targetName,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Star rating
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  return IconButton(
                    iconSize: 40,
                    icon: Icon(
                      starValue <= _rating ? Icons.star : Icons.star_border,
                      color: AppColors.warning,
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            setState(() => _rating = starValue);
                          },
                  );
                }),
              ),
            ),

            // Rating text
            if (_rating > 0)
              Center(
                child: Text(
                  _getRatingText(_rating),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

            const SizedBox(height: AppSpacing.lg),

            // Comment field
            Text(
              'Your Review (Optional)',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _commentController,
              enabled: !_isSubmitting,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText:
                    'Share your experience with this ${widget.targetType}...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.existingRating != null ? 'Update' : 'Submit'),
        ),
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}
