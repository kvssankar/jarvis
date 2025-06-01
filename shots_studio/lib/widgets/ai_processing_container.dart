import 'package:flutter/material.dart';
import 'dart:math' as math;

class AIProcessingContainer extends StatefulWidget {
  final bool isProcessing;
  final int processedCount;
  final int totalCount;
  final VoidCallback? onStop;

  const AIProcessingContainer({
    super.key,
    required this.isProcessing,
    required this.processedCount,
    required this.totalCount,
    this.onStop,
  });

  @override
  State<AIProcessingContainer> createState() => _AIProcessingContainerState();
}

class _AIProcessingContainerState extends State<AIProcessingContainer>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _stackController;
  late AnimationController _particleController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _stackAnimation1;
  late Animation<Offset> _stackAnimation2;
  late Animation<Offset> _stackAnimation3;
  late Animation<double> _scaleAnimation1;
  late Animation<double> _scaleAnimation2;
  late Animation<double> _scaleAnimation3;
  late Animation<double> _rotationAnimation1;
  late Animation<double> _rotationAnimation2;
  late Animation<double> _rotationAnimation3;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the main container
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.97,
          end: 1.01,
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 60.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.01,
          end: 0.99,
        ).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.99,
          end: 0.97,
        ).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 40.0,
      ),
    ]).animate(_pulseController);

    _stackController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3200),
      vsync: this,
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );

    // Icon stack and scale animations
    _stackAnimation1 = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0.6, -0.8),
    ).animate(
      CurvedAnimation(parent: _stackController, curve: Curves.elasticInOut),
    );

    _stackAnimation2 = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-0.5, -0.7),
    ).animate(
      CurvedAnimation(parent: _stackController, curve: Curves.bounceInOut),
    );

    _stackAnimation3 = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0.3, -0.9),
    ).animate(
      CurvedAnimation(parent: _stackController, curve: Curves.elasticInOut),
    );

    _scaleAnimation1 = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _stackController, curve: Curves.easeInOutBack),
    );

    _scaleAnimation2 = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _stackController, curve: Curves.easeInOutBack),
    );

    _scaleAnimation3 = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _stackController, curve: Curves.easeInOutBack),
    );

    // Rotation animations for spinning effects
    _rotationAnimation1 = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _rotationAnimation2 = Tween<double>(begin: 0.0, end: -0.4).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _rotationAnimation3 = Tween<double>(begin: 0.0, end: 0.3).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    if (widget.isProcessing) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(AIProcessingContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isProcessing && !oldWidget.isProcessing) {
      _startAnimations();
    } else if (!widget.isProcessing && oldWidget.isProcessing) {
      _stopAnimations();
    }
  }

  void _startAnimations() {
    _pulseController.reset();
    _pulseController.repeat(reverse: true);
    _stackController.reset();
    _stackController.repeat(reverse: true);
    _rotationController.reset();
    _rotationController.repeat(reverse: true);
    _particleController.reset();
    _particleController.repeat();
  }

  void _stopAnimations() {
    _pulseController.stop();
    _particleController.stop();
    _rotationController.stop();
    if (_stackController.status == AnimationStatus.forward) {
      _stackController
          .forward(from: _stackController.value)
          .whenComplete(() => _stackController.stop());
    } else {
      _stackController
          .reverse(from: _stackController.value)
          .whenComplete(() => _stackController.stop());
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stackController.dispose();
    _particleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isProcessing) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final progress =
        widget.totalCount > 0 ? widget.processedCount / widget.totalCount : 0.0;
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer.withOpacity(0.8),
                  theme.colorScheme.tertiaryContainer.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 140, // Reduced height
                width: double.infinity,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: (screenWidth - 32) * 0.3,
                      child: Center(child: _buildStackedImages(theme)),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Analysis in Progress',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Images are being processed by AI.',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onPrimaryContainer
                                    .withOpacity(0.8),
                              ),
                            ),
                            Text(
                              'While you can still use the app, some features will be limited.',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onPrimaryContainer
                                    .withOpacity(0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      color: theme.colorScheme.outline
                                          .withOpacity(0.3),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: progress,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                          gradient: LinearGradient(
                                            colors: [
                                              theme.colorScheme.primary,
                                              theme.colorScheme.tertiary,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.processedCount}/${widget.totalCount}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                if (widget.onStop != null) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: widget.onStop,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.error
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(
                                        Icons.stop,
                                        size: 16,
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStackedImages(ThemeData theme) {
    const double containerSize = 40.0;
    const double iconSize = 22.0;
    const double baseRadius = 6.0;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _stackController,
        _particleController,
        _rotationController,
      ]),
      builder: (context, child) {
        // Dynamically center based on parent height
        final double parentHeight = 150; // Should match main container height
        final double iconBaseTop = parentHeight / 2 - containerSize / 2;
        final double particleBaseY = parentHeight / 2;
        return SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 60 + (_pulseAnimation.value * 15),
                height: 60 + (_pulseAnimation.value * 15),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.4),
                      theme.colorScheme.secondary.withOpacity(0.2),
                      Colors.transparent,
                    ],
                    stops: const [0.2, 0.6, 1.0],
                  ),
                ),
              ),
              ..._buildParticles(theme, particleBaseY),
              Positioned(
                left: 40 + (_stackAnimation1.value.dx * 15),
                top: iconBaseTop + (_stackAnimation1.value.dy * 20),
                child: Transform.scale(
                  scale: _scaleAnimation1.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation1.value * 6.28,
                    child: Container(
                      width: containerSize,
                      height: containerSize,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(baseRadius),
                        border: Border.all(
                          color: theme.colorScheme.tertiary.withOpacity(0.6),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.tertiary.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.auto_awesome,
                          size: iconSize,
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 40 + (_stackAnimation2.value.dx * 25),
                top: iconBaseTop + (_stackAnimation2.value.dy * 25),
                child: Transform.scale(
                  scale: _scaleAnimation2.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation2.value * 6.28,
                    child: Container(
                      width: containerSize,
                      height: containerSize,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(baseRadius),
                        border: Border.all(
                          color: theme.colorScheme.secondary.withOpacity(0.6),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.secondary.withOpacity(
                              0.15,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.auto_fix_high,
                          size: iconSize,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 40 + (_stackAnimation3.value.dx * 25),
                top: iconBaseTop + (_stackAnimation3.value.dy * 25),
                child: Transform.scale(
                  scale: _scaleAnimation3.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation3.value * 6.28,
                    child: Container(
                      width: containerSize,
                      height: containerSize,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(baseRadius),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.6),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.auto_awesome_motion,
                          size: iconSize,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildParticles(ThemeData theme, double baseY) {
    final particles = <Widget>[];
    final particleProgress = _particleAnimation.value;
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30.0 + particleProgress * 720) * (3.14159 / 180);
      final radius = 35.0 + (i % 3) * 15.0;
      final opacity = (0.4 + 0.6 * ((particleProgress + i * 0.15) % 1.0)).clamp(
        0.0,
        0.9,
      );
      final x = 60 + radius * math.cos(angle) * 1.0;
      final y = baseY + radius * math.sin(angle) * 0.8;
      final particleSize =
          i % 4 == 0
              ? 6.0
              : i % 4 == 1
              ? 4.0
              : i % 4 == 2
              ? 5.0
              : 3.0;
      particles.add(
        Positioned(
          left: x - particleSize / 2,
          top: y - particleSize / 2,
          child: Transform.scale(
            scale: 0.8 + 0.4 * ((particleProgress + i * 0.1) % 1.0),
            child: Container(
              width: particleSize,
              height: particleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    i % 3 == 0
                        ? theme.colorScheme.primary.withOpacity(opacity)
                        : i % 3 == 1
                        ? theme.colorScheme.secondary.withOpacity(opacity)
                        : theme.colorScheme.tertiary.withOpacity(opacity),
                boxShadow: [
                  BoxShadow(
                    color:
                        i % 3 == 0
                            ? theme.colorScheme.primary.withOpacity(
                              opacity * 0.8,
                            )
                            : i % 3 == 1
                            ? theme.colorScheme.secondary.withOpacity(
                              opacity * 0.8,
                            )
                            : theme.colorScheme.tertiary.withOpacity(
                              opacity * 0.8,
                            ),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    for (int i = 0; i < 3; i++) {
      final starProgress = (particleProgress + i * 0.33) % 1.0;
      final startX = 20.0;
      final startY = baseY + 30.0 + i * 20.0;
      final endX = 100.0;
      final endY = baseY + 30.0 - i * 20.0;
      final currentX = startX + (endX - startX) * starProgress;
      final currentY = startY + (endY - startY) * starProgress;
      final starOpacity = (1.0 - starProgress) * 0.8;
      if (starOpacity > 0.1) {
        particles.add(
          Positioned(
            left: currentX,
            top: currentY,
            child: Container(
              width: 8,
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(starOpacity),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(
                      starOpacity * 0.5,
                    ),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
    return particles;
  }
}
