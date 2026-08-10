part of '../../app/game_app.dart';

class SceneFrame extends StatelessWidget {
  const SceneFrame({super.key, required this.background, required this.child});
  final String background;
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(background, fit: BoxFit.cover),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xcc05070b), Colors.transparent, Color(0xb307090d)],
            stops: [0, .52, 1],
          ),
        ),
      ),
      child,
    ],
  );
}

class DarkBackdrop extends StatelessWidget {
  const DarkBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(.2, -.3),
        radius: 1.4,
        colors: [Color(0xff242736), Color(0xff0b0d13), Color(0xff050609)],
      ),
    ),
    child: child,
  );
}

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.gold,
    required this.crystals,
    required this.onSettings,
  });
  final int gold;
  final int crystals;
  final VoidCallback onSettings;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final compact = constraints.maxWidth < 620;
      return Container(
        height: 58,
        padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 12),
        decoration: const BoxDecoration(
          color: Color(0xdd0b0d12),
          border: Border(bottom: BorderSide(color: Color(0xff665535))),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 19,
              backgroundColor: Color(0xff4f3821),
              child: Icon(Icons.pets, color: Color(0xffddb870)),
            ),
            SizedBox(width: compact ? 5 : 9),
            if (!compact)
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '월영 Lv.15',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '단장 랭크 B',
                    style: TextStyle(fontSize: 10, color: Colors.white54),
                  ),
                ],
              ),
            const Spacer(),
            Currency(
              icon: Icons.monetization_on,
              value: '$gold',
              color: Color(0xffffc95d),
            ),
            const SizedBox(width: 8),
            Currency(
              icon: Icons.diamond,
              value: '$crystals',
              color: Color(0xff6baee8),
            ),
            if (!compact) ...[
              const SizedBox(width: 8),
              const Icon(Icons.mail_outline, size: 19),
            ],
            SizedBox(width: compact ? 4 : 10),
            Semantics(
              button: true,
              label: '환경 설정 열기',
              child: SmallIconButton(
                icon: Icons.settings_outlined,
                onTap: onSettings,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    this.isError = false,
    this.actionLabel,
    this.onAction,
  });
  final String message;
  final bool isError;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: message,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      color: isError ? const Color(0xff512b2b) : const Color(0xff3b2d18),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            size: 16,
            color: const Color(0xffffd27c),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xffffdf9a), fontSize: 11),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xffffd27c),
                minimumSize: const Size(0, 30),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(actionLabel!, style: const TextStyle(fontSize: 11)),
            ),
          ],
        ],
      ),
    ),
  );
}

class GameStatePanel extends StatelessWidget {
  const GameStatePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool loading;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: loading,
    label: '$title. $message',
    child: GoldPanel(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox.square(
                dimension: 30,
                child: CircularProgressIndicator(
                  color: Color(0xffc49a54),
                  strokeWidth: 2.5,
                ),
              )
            else
              Icon(icon, size: 32, color: const Color(0xffd6bd81)),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xffffd27c),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: 190,
                child: FantasyButton(
                  label: actionLabel!,
                  icon: Icons.refresh,
                  onTap: onAction!,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class TitleBar extends StatelessWidget {
  const TitleBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
  });
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      color: Color(0xee0c0e14),
      border: Border(bottom: BorderSide(color: Color(0xff6e5a37))),
    ),
    child: Row(
      children: [
        SmallIconButton(icon: Icons.arrow_back_ios_new, onTap: onBack),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Color(0xffbfa875)),
            ),
          ],
        ),
      ],
    ),
  );
}

class GoldPanel extends StatelessWidget {
  const GoldPanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xf522242b), Color(0xf50b0d12)],
      ),
      border: Border.all(color: const Color(0xff76613c)),
      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
    ),
    child: child,
  );
}

class HudPanel extends StatelessWidget {
  const HudPanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: const Color(0xb8090b10),
      border: Border.all(color: const Color(0x9969583b)),
    ),
    child: child,
  );
}

class FantasyButton extends StatelessWidget {
  const FantasyButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.prominent = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool prominent;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: prominent
                  ? const [Color(0xff263f5e), Color(0xff15253b)]
                  : const [Color(0xff372a20), Color(0xff191512)],
            ),
            border: Border.all(
              color: prominent
                  ? const Color(0xff7691ad)
                  : const Color(0xff8b7045),
            ),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 7)],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: const Color(0xffd8bd7b), size: 20),
                const SizedBox(width: 9),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
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

class NavButton extends StatelessWidget {
  const NavButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool badge;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: badge ? '$label, 새 알림 있음' : label,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xcc11141a),
              border: Border.all(color: const Color(0xff57482f)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 18, color: const Color(0xffd0b375)),
                      Text(label, style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                if (badge)
                  const Positioned(
                    right: 4,
                    top: 3,
                    child: CircleAvatar(
                      radius: 5,
                      backgroundColor: Color(0xffc34d3f),
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

class Crest extends StatelessWidget {
  const Crest({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(
        colors: [Color(0xff69512d), Color(0xff181719)],
      ),
      border: Border.all(color: const Color(0xffb28a48), width: 2),
    ),
    child: const Icon(Icons.dark_mode, color: Color(0xffffd47b), size: 28),
  );
}

class Currency extends StatelessWidget {
  const Currency({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xaa050609),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white12),
    ),
    child: Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

class SmallIconButton extends StatelessWidget {
  const SmallIconButton({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xaa11141a),
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: Color(0xff6d5937)),
      borderRadius: BorderRadius.circular(2),
    ),
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 18),
      ),
    ),
  );
}

class Meter extends StatelessWidget {
  const Meter({super.key, required this.value, required this.color});
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 3),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(1),
      child: SizedBox(
        height: 5,
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          color: color,
          backgroundColor: Colors.black54,
        ),
      ),
    ),
  );
}
