import 'package:cer_time/main.dart';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import 'main_navigation.dart';
import 'login_screen.dart';

class _OnboardingSlide{
  final IconData icon;
  final String title;
  final String description;
  const _OnboardingSlide({required this.icon, required this.title, required this.description});
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;


  static const _slides = [
    _OnboardingSlide(
      icon: Icons.add_circle_outline,
      title: 'Traccia i tuoi eventi',
      description: 'Registra rapidamente meeting e corsi di formazione con data, orario e durata,',
    ),
    _OnboardingSlide(
        icon: Icons.fact_check_outlined,
        title: 'Compliance garantita',
        description: 'Per ogni corso di formazione inserisci un sommario didattico, evidenzia richiesta per gli audit aziendali.'
    ),
    _OnboardingSlide(
        icon: Icons.ios_share_outlined,
        title: 'Esporta i tuoi report',
        description: 'Condividi lo storico delle tua ettività in formato csv con l\'ufficio del personale in un tap.'
    ),
  ];

  void _completeOnboarding() async {
    await SettingsService.instance.setOnboardingDone();
    if(!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text('Salta'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(slide.icon, size: 96, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 32),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if(_currentPage == _slides.length -1){
                      _completeOnboarding();
                    } else{
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(_currentPage == _slides.length - 1 ? 'Inizia' : 'Avanti'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
