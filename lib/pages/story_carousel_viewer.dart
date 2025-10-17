import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/story.dart';
import '../services/story_service.dart';

class StoryCarouselViewer extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;
  final VoidCallback? onStoryDeleted;

  const StoryCarouselViewer({
    Key? key,
    required this.stories,
    this.initialIndex = 0,
    this.onStoryDeleted,
  }) : super(key: key);

  @override
  State<StoryCarouselViewer> createState() => _StoryCarouselViewerState();
}

class _StoryCarouselViewerState extends State<StoryCarouselViewer>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  late AnimationController _progressController;
  bool _isDeleting = false;
  static const Duration _storyDuration = Duration(seconds: 5);

  // Helper function to capitalize first letter of a string
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _progressController = AnimationController(
      duration: _storyDuration,
      vsync: this,
    );

    _startStoryTimer();
    _markCurrentStoryAsViewed();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _startStoryTimer() {
    _progressController.reset();
    _progressController.forward().then((_) {
      if (mounted) {
        _nextStory();
      }
    });
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _pauseStory() {
    _progressController.stop();
  }

  void _resumeStory() {
    _progressController.forward();
  }

  Future<void> _markCurrentStoryAsViewed() async {
    if (_currentIndex < widget.stories.length) {
      await StoryService.markStoryAsViewed(widget.stories[_currentIndex].id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No stories available',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (_) => _pauseStory(),
        onTapUp: (_) => _resumeStory(),
        onTapCancel: () => _resumeStory(),
        onLongPressStart: (_) => _pauseStory(),
        onLongPressEnd: (_) => _resumeStory(),
        child: Stack(
          children: [
            // Story PageView
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _startStoryTimer();
                _markCurrentStoryAsViewed();
              },
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                return _buildStoryContent(widget.stories[index]);
              },
            ),

            // Navigation areas (invisible tap zones)
            Row(
              children: [
                // Left tap area (previous story)
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: _previousStory,
                    behavior: HitTestBehavior.translucent,
                    child: Container(),
                  ),
                ),
                // Right tap area (next story)
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: _nextStory,
                    behavior: HitTestBehavior.translucent,
                    child: Container(),
                  ),
                ),
              ],
            ),

            // Progress indicators
            _buildProgressIndicators(),

            // Top bar with user info
            _buildTopBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(Story story) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Story Image
          Center(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: Image.network(
                story.storyImage,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.error,
                      color: Colors.white,
                      size: 50,
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom gradient overlay for text
          if (story.storyText.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

          // Story text
          if (story.storyText.isNotEmpty)
            Positioned(
              bottom: 60,
              left: 16,
              right: 16,
              child: Text(
                story.storyText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Location info
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    story.location.locationName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicators() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 70,
      left: 16,
      right: 16,
      child: Row(
        children: List.generate(widget.stories.length, (index) {
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: index < _currentIndex
                      ? 1.0
                      : index == _currentIndex
                          ? _progressController.value
                          : 0.0,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTopBar() {
    final currentStory = widget.stories[_currentIndex];
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUserId == currentStory.userId;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // User Avatar
            CircleAvatar(
              radius: 16,
              backgroundImage: currentStory.userPhoto != null
                  ? NetworkImage(currentStory.userPhoto!)
                  : null,
              child: currentStory.userPhoto == null
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
            const SizedBox(width: 8),

            // Username and time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _capitalizeFirstLetter(currentStory.username),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    currentStory.formattedTimeRemaining,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Story counter
            Text(
              '${_currentIndex + 1}/${widget.stories.length}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Delete button (only for story owner)
            if (isOwner) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isDeleting ? null : _showDeleteDialog,
                icon: _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
            ],

            // Close button
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    _pauseStory();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Story',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3436),
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this story? This action cannot be undone.',
            style: TextStyle(
              color: Color(0xFF636E72),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resumeStory();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF636E72),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _deleteCurrentStory();
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      // Resume story if dialog is dismissed
      _resumeStory();
    });
  }

  Future<void> _deleteCurrentStory() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final currentStory = widget.stories[_currentIndex];
      final success = await StoryService.deleteStory(
        currentStory.id,
        currentStory.userId,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Call callback if provided
        widget.onStoryDeleted?.call();

        // Remove story from list
        widget.stories.removeAt(_currentIndex);

        if (widget.stories.isEmpty) {
          // Close viewer if no stories left
          Navigator.pop(context);
        } else {
          // Adjust current index if needed
          if (_currentIndex >= widget.stories.length) {
            _currentIndex = widget.stories.length - 1;
          }

          // Update page controller
          _pageController = PageController(initialPage: _currentIndex);
          setState(() {});
          _startStoryTimer();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete story'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        _resumeStory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        _resumeStory();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }
}
