import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/sync/models/offline_queue_entry.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/vesper_logo.dart';
import 'view_models/waiting_reports_view_model.dart';

class WaitingReportsScreen extends StatelessWidget {
  const WaitingReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WaitingReportsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.navy,
        title: const VesperLogo(height: 36),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Reports waiting to send',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (viewModel.message != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  viewModel.message!,
                  style: const TextStyle(color: AppColors.navy, fontSize: 15),
                ),
              ),
            Expanded(child: _body(viewModel)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: viewModel.sending || viewModel.entries.isEmpty
                      ? null
                      : viewModel.sendNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: viewModel.sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Send now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(WaitingReportsViewModel viewModel) {
    if (viewModel.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nothing waiting. Everything has been sent.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.navy, fontSize: 16),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      itemCount: viewModel.entries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _EntryCard(entry: viewModel.entries[index], viewModel: viewModel),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.viewModel});

  final OfflineQueueEntry entry;
  final WaitingReportsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final rejected = viewModel.isRejected(entry);
    final reason = entry.lastError;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            viewModel.typeLabel(entry),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            viewModel.savedAt(entry),
            style: const TextStyle(color: AppColors.white, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.statusLabel(entry),
            style: TextStyle(
              color: rejected ? Colors.red.shade200 : AppColors.cyan,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (rejected && reason != null) ...[
            const SizedBox(height: 4),
            Text(
              reason,
              style: const TextStyle(color: AppColors.white, fontSize: 13),
            ),
          ],
          if (entry.status == QueueStatus.failed)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: viewModel.sending
                    ? null
                    : () => viewModel.retry(entry),
                child: const Text(
                  'Try again',
                  style: TextStyle(color: AppColors.cyan, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
