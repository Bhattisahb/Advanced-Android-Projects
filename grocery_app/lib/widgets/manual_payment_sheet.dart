import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/consts/manual_payment_info.dart';
import 'package:grocery_app/services/utils.dart';
import 'package:grocery_app/widgets/text_widget.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showManualPaymentCheckoutSheet(
  BuildContext context, {
  required String summaryLine,
  required Future<void> Function() onPlaceOrder,
}) async {
  final whatsAppMessage = '''
$summaryLine

I have paid / will pay using the details in the app. Payment screenshot attached.
'''.trim();

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final color = Utils(context).color;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: 24 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextWidget(
                  text: 'Manual payment',
                  color: color,
                  textSize: 20,
                  isTitle: true,
                ),
                const SizedBox(height: 8),
                Text(
                  summaryLine,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pay using the account below. Then open WhatsApp and send your '
                  'payment screenshot so we can confirm your order.',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.85),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                _detailTile(
                  context,
                  'Account name',
                  ManualPaymentInfo.accountHolder,
                  color,
                ),
                _detailTile(
                  context,
                  'Account number',
                  ManualPaymentInfo.bankAccountNumber,
                  color,
                ),
                _detailTile(
                  context,
                  'IBAN',
                  ManualPaymentInfo.iban,
                  color,
                ),
                _detailTile(
                  context,
                  'Easypaisa / JazzCash',
                  '${ManualPaymentInfo.walletDisplayName}\n${ManualPaymentInfo.walletPhoneDisplay}',
                  color,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: ManualPaymentInfo.copyBlock()),
                    );
                    if (sheetContext.mounted) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(content: Text('Payment details copied')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  label: const Text('Copy payment details'),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () async {
                    final uri =
                        ManualPaymentInfo.whatsAppUriWithMessage(whatsAppMessage);
                    final ok = await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                    if (!ok && sheetContext.mounted) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Could not open WhatsApp. Chat ${ManualPaymentInfo.walletPhoneDisplay}',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.chat_rounded, size: 22),
                  label: const Text('Open WhatsApp'),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          await onPlaceOrder();
                        },
                        child: const Text('Place order'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _detailTile(
  BuildContext context,
  String label,
  String value,
  Color color,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.55),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: TextStyle(color: color, height: 1.35),
        ),
      ],
    ),
  );
}
