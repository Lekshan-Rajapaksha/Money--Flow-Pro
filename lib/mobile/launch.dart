part of '../home.dart';

class _LaunchScreen extends StatelessWidget {
  const _LaunchScreen();

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFFD8F489);
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.35, -0.45),
              radius: 1.15,
              colors:
                  dark
                      ? const [Color(0xFF22493A), Color(0xFF111C18)]
                      : const [Color(0xFF28654F), Color(0xFF143D31)],
            ),
          ),
          child: SafeArea(
            child: SizedBox.expand(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 62),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(34),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.55),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x48091610),
                                      blurRadius: 36,
                                      offset: Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Image.asset(
                                    'assets/Pro.png',
                                    width: 112,
                                    height: 112,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              const Text(
                                'Money Flow Pro',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                width: 74,
                                child: LinearProgressIndicator(
                                  value: reduceMotion ? 0.6 : null,
                                  color: accent,
                                  backgroundColor: const Color(0x3FFFFFFF),
                                  minHeight: 3,
                                  borderRadius: BorderRadius.circular(8),
                                  semanticsLabel: 'Loading Money Flow Pro',
                                ),
                              ),
                            ],
                          )
                          .animate(
                            autoPlay: !reduceMotion,
                            value: reduceMotion ? 1 : null,
                          )
                          .fadeIn(duration: 420.ms)
                          .slideY(
                            begin: 0.12,
                            duration: 460.ms,
                            curve: Curves.easeOutCubic,
                          ),
                    ),
                  ),
                  const Positioned(
                    bottom: 28,
                    left: 16,
                    right: 16,
                    child: Text(
                      'Created by LexN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
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
