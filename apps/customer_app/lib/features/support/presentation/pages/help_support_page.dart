import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbare_ui/mbare_ui.dart';

/// Help and support page with FAQs and contact form
class HelpSupportPage extends ConsumerStatefulWidget {
  const HelpSupportPage({super.key});

  @override
  ConsumerState<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends ConsumerState<HelpSupportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'FAQs', icon: Icon(Icons.help_outline)),
            Tab(text: 'Contact Us', icon: Icon(Icons.email_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FAQsTab(),
          _ContactUsTab(),
        ],
      ),
    );
  }
}

/// FAQs tab widget
class _FAQsTab extends StatelessWidget {
  const _FAQsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Frequently Asked Questions',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Orders Category
        _CategoryHeader(title: 'Orders'),
        const SizedBox(height: AppSpacing.sm),
        _FAQItem(
          question: 'How do I track my order?',
          answer:
              'You can track your order by going to "My Orders" in your profile. '
              'Click on any order to see its current status and delivery information.',
        ),
        const SizedBox(height: AppSpacing.sm),
        _FAQItem(
          question: 'Can I cancel or modify my order?',
          answer:
              'Orders can be cancelled or modified within 5 minutes of placement. '
              'After that, please contact the vendor directly or our support team.',
        ),
        const SizedBox(height: AppSpacing.sm),
        _FAQItem(
          question: 'What are the delivery times?',
          answer:
              'Delivery times vary by vendor and location. Most orders are delivered '
              'within 1-3 hours during business hours. You can see estimated delivery '
              'time during checkout.',
        ),

        const SizedBox(height: AppSpacing.lg),

        // Payment Category
        _CategoryHeader(title: 'Payment'),
        const SizedBox(height: AppSpacing.sm),
        _FAQItem(
          question: 'What payment methods do you accept?',
          answer:
              'We accept credit/debit cards, mobile money (EcoCash, OneMoney), '
              'and cash on delivery for eligible orders.',
        ),
        const SizedBox(height: AppSpacing.sm),
        _FAQItem(
          question: 'Is it safe to save my payment information?',
          answer:
              'Yes, all payment information is encrypted and stored securely. '
              'We never store your full card details.',
        ),
        const SizedBox(height: AppSpacing.sm),
        _FAQItem(
          question: 'How do refunds work?',
          answer:
              'Refunds are processed within 5-7 business days to your original '
              'payment method. For cash on delivery orders, refunds are issued '
              'via mobile money or bank transfer.',
        ),

        const SizedBox(height: AppSpacing.lg),

        // Account Category
        _CategoryHeader(title: 'Account'),
        const SizedBox(height: AppSpacing.sm),
        _FAQItem(
          question: 'How do I reset my password?',
          answer:
              'Click "Forgot Password" on the login page and follow the instructions '
              'sent to your email.',
        ),
        const SizedBox(height: AppSpacing.sm),
        _FAQItem(
          question: 'Can I change my registered email?',
          answer:
              'Currently, email changes require contacting our support team. '
              'Please use the Contact Us form with your request.',
        ),
        const SizedBox(height: AppSpacing.sm),
        _FAQItem(
          question: 'How do I delete my account?',
          answer:
              'To delete your account, please contact our support team. Note that '
              'this action is permanent and cannot be undone.',
        ),

        const SizedBox(height: AppSpacing.xl),

        // Still need help card
        Card(
          color: AppColors.primary.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const Icon(
                  Icons.support_agent,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Still need help?',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Contact our support team and we\'ll get back to you as soon as possible.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: () {
                    DefaultTabController.of(context).animateTo(1);
                  },
                  icon: const Icon(Icons.email),
                  label: const Text('Contact Us'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Contact Us tab widget
class _ContactUsTab extends ConsumerStatefulWidget {
  const _ContactUsTab();

  @override
  ConsumerState<_ContactUsTab> createState() => _ContactUsTabState();
}

class _ContactUsTabState extends ConsumerState<_ContactUsTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'General Inquiry';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // TODO: Implement actual submission to backend
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your message has been sent successfully!'),
        backgroundColor: AppColors.success,
      ),
    );

    // Clear form
    _nameController.clear();
    _emailController.clear();
    _subjectController.clear();
    _messageController.clear();
    setState(() => _selectedCategory = 'General Inquiry');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Get in Touch',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Fill out the form below and our team will get back to you within 24 hours.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter your name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                enabled: !_isSubmitting,
              ),

              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                enabled: !_isSubmitting,
              ),

              const SizedBox(height: AppSpacing.md),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'General Inquiry',
                    child: Text('General Inquiry'),
                  ),
                  DropdownMenuItem(
                    value: 'Order Issue',
                    child: Text('Order Issue'),
                  ),
                  DropdownMenuItem(
                    value: 'Payment Issue',
                    child: Text('Payment Issue'),
                  ),
                  DropdownMenuItem(
                    value: 'Technical Issue',
                    child: Text('Technical Issue'),
                  ),
                  DropdownMenuItem(
                    value: 'Vendor Complaint',
                    child: Text('Vendor Complaint'),
                  ),
                  DropdownMenuItem(
                    value: 'Feedback',
                    child: Text('Feedback'),
                  ),
                ],
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
              ),

              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  hintText: 'Brief description of your issue',
                  prefixIcon: Icon(Icons.subject),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a subject';
                  }
                  return null;
                },
                enabled: !_isSubmitting,
              ),

              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Describe your issue in detail',
                  prefixIcon: Icon(Icons.message_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your message';
                  }
                  if (value.length < 10) {
                    return 'Message must be at least 10 characters';
                  }
                  return null;
                },
                enabled: !_isSubmitting,
              ),

              const SizedBox(height: AppSpacing.xl),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitForm,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isSubmitting ? 'Sending...' : 'Send Message'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Contact info card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Other Ways to Reach Us',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _ContactInfoRow(
                  icon: Icons.email,
                  label: 'Email',
                  value: 'support@mbaretoyou.co.zw',
                ),
                const SizedBox(height: AppSpacing.sm),
                _ContactInfoRow(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: '+263 XX XXX XXXX',
                ),
                const SizedBox(height: AppSpacing.sm),
                _ContactInfoRow(
                  icon: Icons.access_time,
                  label: 'Support Hours',
                  value: 'Mon-Sat: 8:00 AM - 6:00 PM',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Category header widget
class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// FAQ item widget
class _FAQItem extends StatefulWidget {
  const _FAQItem({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() => _isExpanded = !_isExpanded);
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.primary,
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.answer,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
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

/// Contact info row widget
class _ContactInfoRow extends StatelessWidget {
  const _ContactInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
