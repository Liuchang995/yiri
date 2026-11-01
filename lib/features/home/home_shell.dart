import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import 'future_page.dart';
import 'past_page.dart';
import 'today_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _labels = ['将来', '今日', '过去'];
  late final PageController _controller = PageController(initialPage: 1);
  int _index = 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: PageView(
        controller: _controller,
        onPageChanged: (index) => setState(() => _index = index),
        children: const [FuturePage(), TodayPage(), PastPage()],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(top: BorderSide(color: colors.divider)),
          ),
          child: Row(
            children: [
              for (var index = 0; index < _labels.length; index++)
                Expanded(
                  child: InkWell(
                    onTap: () => _select(index),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          switch (index) {
                            0 => Icons.event_outlined,
                            1 => Icons.today_outlined,
                            _ => Icons.history_outlined,
                          },
                          size: 21,
                          color: index == _index
                              ? colors.primary
                              : colors.secondaryText,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _labels[index],
                          style: TextStyle(
                            color: index == _index
                                ? colors.primary
                                : colors.secondaryText,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
