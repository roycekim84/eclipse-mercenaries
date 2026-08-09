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
  const TopBar({super.key, required this.gold, required this.crystals});
  final int gold;
  final int crystals;
  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.symmetric(horizontal: 12),
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
        const SizedBox(width: 9),
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
        const SizedBox(width: 8),
        const Icon(Icons.mail_outline, size: 19),
        const SizedBox(width: 10),
        const Icon(Icons.settings_outlined, size: 19),
      ],
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
  Widget build(BuildContext context) => Material(
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
  Widget build(BuildContext context) => Padding(
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
