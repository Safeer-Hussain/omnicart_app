import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../notifiers/ai_copilot_notifier.dart';
import '../widgets/spend_analytics_chart.dart';

class AiShoppingCopilotView extends ConsumerStatefulWidget {
  const AiShoppingCopilotView({super.key});

  @override
  ConsumerState<AiShoppingCopilotView> createState() =>
      _AiShoppingCopilotViewState();
}

class _AiShoppingCopilotViewState extends ConsumerState<AiShoppingCopilotView> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  final List<String> _shortcutPrompts = const [
    'Find Best Promo Code & Bundle Savings for My Cart',
    'Compare Price-to-Spec Value of My Wishlist',
    'Summarize My Monthly Order Spending',
    'Recommend Express 15-Min Essentials',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _inputController.clear();
    final currency = ref.read(currencyProvider);
    ref.read(aiCopilotProvider.notifier).sendUserPrompt(text, currency);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final copilotState = ref.watch(aiCopilotProvider);
    final currency = ref.watch(currencyProvider);

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: colorScheme.surface,
        floatingActionButton: FloatingActionButton.small(
          heroTag: 'fab_ai_shopper_clear',
          backgroundColor: colorScheme.surfaceContainerHighest,
          foregroundColor: colorScheme.onSurface,
          tooltip: 'Reset Conversation',
          onPressed: () {
            ref.read(aiCopilotProvider.notifier).clearConversation();
          },
          child: const Icon(Icons.refresh),
        ),
        body: SafeArea(
          child: isLandscape
              ? _buildLandscapeLayout(
                  context,
                  colorScheme,
                  copilotState,
                  currency,
                )
              : _buildPortraitLayout(
                  context,
                  colorScheme,
                  copilotState,
                  currency,
                ),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    ColorScheme colorScheme,
    AiCopilotState copilotState,
    AppCurrency currency,
  ) {
    return Column(
      children: [
        // Chat Messages & Analytics Stream
        Expanded(
          child: ListView(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Monthly Spend Analytics Chart at top
              SpendAnalyticsChart(
                data: copilotState.monthlySpendData,
                currency: currency,
              ),
              const SizedBox(height: 16),

              // Shortcut Prompt Chips
              Text(
                'RECOMMENDED COPILOT PROMPTS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _shortcutPrompts.map((p) {
                  return ActionChip(
                    backgroundColor: colorScheme.surfaceContainerHigh,
                    side: BorderSide(color: colorScheme.outlineVariant),
                    label: Text(p, style: const TextStyle(fontSize: 11)),
                    onPressed: copilotState.isStreaming
                        ? null
                        : () => _sendMessage(p),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Conversation Messages
              ...copilotState.messages.map(
                (msg) => _buildMessageBubble(msg, colorScheme),
              ),

              // Transient Streaming Indicator
              if (copilotState.transientStatus != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          copilotState.transientStatus!,
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Bottom Input Bar
        _buildBottomInputBar(colorScheme, copilotState),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    ColorScheme colorScheme,
    AiCopilotState copilotState,
    AppCurrency currency,
  ) {
    return Row(
      children: [
        // Left Pane: Conversation & Input
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  children: [
                    ...copilotState.messages.map(
                      (msg) => _buildMessageBubble(msg, colorScheme),
                    ),
                    if (copilotState.transientStatus != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                copilotState.transientStatus!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildBottomInputBar(colorScheme, copilotState),
            ],
          ),
        ),

        VerticalDivider(color: colorScheme.outlineVariant, width: 1),

        // Right Pane: Spend Analytics Chart & Shortcut Prompts
        Expanded(
          flex: 2,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            children: [
              SpendAnalyticsChart(
                data: copilotState.monthlySpendData,
                currency: currency,
              ),
              const SizedBox(height: 12),
              Text(
                'PROMPT SHORTCUTS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              ..._shortcutPrompts.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                    onPressed: copilotState.isStreaming
                        ? null
                        : () => _sendMessage(p),
                    child: Text(
                      p,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(AiMessage msg, ColorScheme colorScheme) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primary
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 2),
            bottomRight: Radius.circular(isUser ? 2 : 14),
          ),
          border: isUser ? null : Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInputBar(
    ColorScheme colorScheme,
    AiCopilotState copilotState,
  ) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                textInputAction: TextInputAction.send,
                onSubmitted: copilotState.isStreaming ? null : _sendMessage,
                decoration: const InputDecoration(
                  hintText: 'Ask Copilot regarding SKUs, promos or spend...',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: copilotState.isStreaming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, size: 18),
              onPressed: copilotState.isStreaming
                  ? null
                  : () => _sendMessage(_inputController.text),
            ),
          ],
        ),
      ),
    );
  }
}
