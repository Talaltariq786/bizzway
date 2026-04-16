import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/constants/app_colors.dart';

class ProfessionalBottomNav extends StatefulWidget {
  final int currentIndex;
  final int itemCount;
  final Function(int) onTap;
  final List<NavItem> items;
  final Color? backgroundColor;
  final Color selectedColor;
  final Color unselectedColor;

  const ProfessionalBottomNav({
    super.key,
    required this.currentIndex,
    required this.itemCount,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedColor = AppColors.primary,
    this.unselectedColor = AppColors.textHint,
  });

  @override
  State<ProfessionalBottomNav> createState() => _ProfessionalBottomNavState();
}

class NavItem {
  final IconData outlineIcon;
  final IconData filledIcon;
  final String label;
  final int? badgeCount;

  NavItem({
    required this.outlineIcon,
    required this.filledIcon,
    required this.label,
    this.badgeCount,
  });
}

class _ProfessionalBottomNavState extends State<ProfessionalBottomNav>
    with TickerProviderStateMixin {
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<Color?>> _colorAnimations;

  @override
  void initState() {
    super.initState();
    _itemControllers = List.generate(
      widget.itemCount,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      ),
    );

    _scaleAnimations = List.generate(
      widget.itemCount,
      (i) => Tween<double>(begin: 0.8, end: 1.15).animate(
        CurvedAnimation(
          parent: _itemControllers[i],
          curve: Curves.elasticOut,
        ),
      ),
    );

    _colorAnimations = List.generate(
      widget.itemCount,
      (i) => ColorTween(
        begin: widget.unselectedColor,
        end: widget.selectedColor,
      ).animate(
        CurvedAnimation(
          parent: _itemControllers[i],
          curve: Curves.easeInOut,
        ),
      ),
    );

    _triggerAnimation();
  }

  @override
  void didUpdateWidget(ProfessionalBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _triggerAnimation();
    }
  }

  void _triggerAnimation() {
    for (int i = 0; i < _itemControllers.length; i++) {
      if (i == widget.currentIndex) {
        _itemControllers[i].forward();
      } else {
        _itemControllers[i].reverse();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (widget.backgroundColor ?? AppColors.surface).withValues(alpha: 0.98),
            (widget.backgroundColor ?? AppColors.surface).withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 32,
            offset: const Offset(0, -8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: widget.selectedColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  widget.itemCount,
                  (index) => _buildNavItem(index),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = widget.currentIndex == index;
    final item = widget.items[index];

    return GestureDetector(
      onTap: () {
        widget.onTap(index);
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimations[index],
          _colorAnimations[index],
        ]),
        builder: (context, child) {
          return ScaleTransition(
            scale: _scaleAnimations[index],
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              widget.selectedColor.withValues(alpha: 0.15),
                              widget.selectedColor.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(18),
                    border: isSelected
                        ? Border.all(
                            color: widget.selectedColor.withValues(alpha: 0.2),
                            width: 1.5,
                          )
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: widget.selectedColor.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    widget.selectedColor.withValues(alpha: 0.2),
                                    widget.selectedColor.withValues(alpha: 0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: !isSelected ? Colors.transparent : null,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isSelected ? item.filledIcon : item.outlineIcon,
                          color: _colorAnimations[index].value,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 5),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: TextStyle(
                          color: _colorAnimations[index].value ?? widget.unselectedColor,
                          fontSize: isSelected ? 12 : 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          letterSpacing: isSelected ? 0.3 : 0,
                        ),
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.badgeCount != null && item.badgeCount! > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.selectedColor,
                            widget.selectedColor.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: widget.selectedColor.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                            spreadRadius: 1,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${item.badgeCount!}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
