import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animate_gradient/animate_gradient.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/constants/gradient_colors.dart';
import 'package:bankapp/presentation/widgets/astroid.dart';
import 'package:bankapp/presentation/widgets/add_transaction_bottom_sheet.dart';
import 'package:bankapp/core/constants/app_constants.dart';

class FloatingNavbar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isDarkBackground; // true = fond foncé, false = fond clair

  const FloatingNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isDarkBackground = true,
  });

  @override
  State<FloatingNavbar> createState() => _FloatingNavbarState();
}

class _FloatingNavbarState extends State<FloatingNavbar>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _expandController;
  late AnimationController _scaleController;
  late Animation<double> _expandAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _leftButtonSlide;
  late Animation<Offset> _rightButtonSlide;

  @override
  void initState() {
    super.initState();

    // Controller pour l'expansion des boutons
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Controller pour l'animation de scale
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Animation d'expansion
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutBack,
    );

    // Animation de scale pour le feedback tactile
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Animation de glissement pour le bouton gauche (-)
    _leftButtonSlide = Tween<Offset>(
      begin: const Offset(0, 0), // Commence au centre
      end: const Offset(-1, 0), // Glisse vers la gauche
    ).animate(_expandAnimation);

    // Animation de glissement pour le bouton droit (+)
    _rightButtonSlide = Tween<Offset>(
      begin: const Offset(0, 0), // Commence au centre
      end: const Offset(1, 0), // Glisse vers la droite
    ).animate(_expandAnimation);
  }

  @override
  void dispose() {
    _expandController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }

    // Animation de scale pour le feedback tactile
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
  }

  void _closeExpansion() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
      });
      _expandController.reverse();
    }
  }

  void _showAddTransactionBottomSheet(String transactionType) {
    _closeExpansion(); // Fermer les boutons d'abord

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionBottomSheet(
        preselectedTransactionType: transactionType,
      ),
    ).then((_) {
      // Quand la bottom sheet se ferme, s'assurer que l'expansion est fermée
      _closeExpansion();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Couleurs adaptatives selon le fond
    final navbarColor = widget.isDarkBackground
        ? AppColors.white
        : AppColors.containerBlack;
    final activeIconColor = widget.isDarkBackground
        ? AppColors.textDark
        : AppColors.textLight;
    final inactiveIconColor = activeIconColor.withOpacity(0.3);

    return Positioned(
      bottom: 50,
      left: 40,
      right: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Boutons animés (-) et (+) avec AnimateGradient
          if (_isExpanded) ...[
            // Bouton (-) pour débit - centré à gauche
            Positioned(
              bottom: 90, // Au-dessus de la navbar
              left:
                  MediaQuery.of(context).size.width / 2 -
                  100, // Centré à gauche
              child: AnimatedBuilder(
                animation: _leftButtonSlide,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      _leftButtonSlide.value.dx * 30,
                      _leftButtonSlide.value.dy * 20,
                    ),
                    child: ScaleTransition(
                      scale: _expandAnimation,
                      child: GestureDetector(
                        onTap: () => _showAddTransactionBottomSheet(
                          AppConstants.transactionTypeDebit,
                        ),
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: AnimateGradient(
                              primaryColors: [
                                Colors.white,
                                Colors.white,
                              ], //GradientColors.primaryColors,
                              secondaryColors: [
                                Colors.white,
                                Colors.white,
                              ], //GradientColors.secondaryColors,
                              duration: GradientColors.animationDuration,
                              child: SizedBox(
                                width: 50,
                                height: 50,
                                child: const Center(
                                  child: Icon(
                                    Icons.remove,
                                    color: Colors.black,
                                    size: 50,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bouton (+) pour crédit - centré à droite
            Positioned(
              bottom: 90, // Au-dessus de la navbar
              right:
                  MediaQuery.of(context).size.width / 2 -
                  100, // Centré à droite
              child: AnimatedBuilder(
                animation: _rightButtonSlide,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      _rightButtonSlide.value.dx * 30,
                      _rightButtonSlide.value.dy * 20,
                    ),
                    child: ScaleTransition(
                      scale: _expandAnimation,
                      child: GestureDetector(
                        onTap: () => _showAddTransactionBottomSheet(
                          AppConstants.transactionTypeCredit,
                        ),
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: AnimateGradient(
                              primaryColors: [
                                Colors.white,
                                Colors.white,
                              ], //GradientColors.primaryColors,
                              secondaryColors: [
                                Colors.white,
                                Colors.white,
                              ], //GradientColors.secondaryColors,
                              duration: GradientColors.animationDuration,
                              child: SizedBox(
                                width: 50,
                                height: 50,
                                child: const Center(
                                  child: Icon(
                                    Icons.add,
                                    color: Colors.black,
                                    size: 50,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Navbar principale
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: navbarColor,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Icône Home
                _buildNavItem(
                  iconPath: 'assets/icons/system/home.svg',
                  index: 0,
                  isActive: widget.currentIndex == 0,
                  activeColor: activeIconColor,
                  inactiveColor: inactiveIconColor,
                ),

                // Icône App (Menu)
                _buildNavItem(
                  iconPath: 'assets/icons/system/app.svg',
                  index: 1,
                  isActive: widget.currentIndex == 1,
                  activeColor: activeIconColor,
                  inactiveColor: inactiveIconColor,
                ),

                // Icône centrale (Astroid) - UNE SEULE FOIS
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: GestureDetector(
                    onTap: _toggleExpansion,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: Astroid(
                        size: 30,
                        curvature: 0.25,
                        primaryColors: GradientColors.primaryColors,
                        secondaryColors: GradientColors.secondaryColors,
                        duration: GradientColors.animationDuration,
                      ),
                    ),
                  ),
                ),

                // Icône Chart (Statistiques)
                _buildNavItem(
                  iconPath: 'assets/icons/system/chart.svg',
                  index: 2,
                  isActive: widget.currentIndex == 2,
                  activeColor: activeIconColor,
                  inactiveColor: inactiveIconColor,
                ),

                // Icône Settings
                _buildNavItem(
                  iconPath: 'assets/icons/system/settings.svg',
                  index: 3,
                  isActive: widget.currentIndex == 3,
                  activeColor: activeIconColor,
                  inactiveColor: inactiveIconColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String iconPath,
    required int index,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    return GestureDetector(
      onTap: () {
        _closeExpansion(); // Fermer l'expansion si ouverte
        widget.onTap(index);
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: SvgPicture.asset(
            iconPath,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              isActive ? activeColor : inactiveColor,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
