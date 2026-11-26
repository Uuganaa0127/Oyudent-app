part of 'production_app.dart';

typedef _Story = ({Catalog catalog, Record row});

class _CourseStories extends StatefulWidget {
  const _CourseStories({required this.api, required this.stories});
  final ProductionApi api;
  final List<_Story> stories;
  @override
  State<_CourseStories> createState() => _CourseStoriesState();
}

class _CourseStoriesState extends State<_CourseStories> {
  final seen = <String>{};
  String id(_Story story) => '${story.catalog.name}/${story.row['id']}';
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 78 + 2.7 * MediaQuery.textScalerOf(context).scale(12),
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: widget.stories.length,
      separatorBuilder: (_, _) => const SizedBox(width: 14),
      itemBuilder: (context, i) {
        final s = widget.stories[i];
        final title = s.catalog.title(s.row);
        return SizedBox(
          width: 74,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              setState(() => seen.add(id(s)));
              await _push(
                context,
                _StoryViewer(
                  api: widget.api,
                  stories: widget.stories,
                  initial: i,
                  onSeen: (story) {
                    if (mounted) setState(() => seen.add(id(story)));
                  },
                ),
              );
            },
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: seen.contains(id(s))
                          ? Colors.blueGrey.shade200
                          : _brand,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: s.catalog.image(s.row).isEmpty
                        ? const ColoredBox(
                            color: _night,
                            child: CustomPaint(painter: _MolarArt()),
                          )
                        : _WebsiteImage(
                            url: s.catalog.image(s.row),
                            icon: s.catalog.icon,
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _StoryViewer extends StatefulWidget {
  const _StoryViewer({
    required this.api,
    required this.stories,
    required this.initial,
    required this.onSeen,
  });
  final ProductionApi api;
  final List<_Story> stories;
  final int initial;
  final ValueChanged<_Story> onSeen;
  @override
  State<_StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<_StoryViewer> {
  late int page = widget.initial;
  late final controller = PageController(initialPage: page);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void move(int index) => controller.animateToPage(
    index,
    duration: const Duration(milliseconds: 230),
    curve: Curves.easeOut,
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff182e49),
    appBar: AppBar(title: const Text('Сургалтын стори')),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                for (var i = 0; i < widget.stories.length; i++)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 3,
                      color: i <= page ? Colors.white : Colors.white24,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: controller,
              itemCount: widget.stories.length,
              onPageChanged: (i) {
                setState(() => page = i);
                widget.onSeen(widget.stories[i]);
              },
              itemBuilder: (context, i) {
                final s = widget.stories[i];
                final image = s.catalog.image(s.row);
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: image.isEmpty
                                  ? Center(
                                      child: Icon(
                                        s.catalog.icon,
                                        size: 86,
                                        color: Colors.white70,
                                      ),
                                    )
                                  : _WebsiteImage(
                                      url: image,
                                      icon: s.catalog.icon,
                                      fit: BoxFit.contain,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            s.catalog.label,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            s.catalog.title(s.row),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            onPressed: () => _push(
                              context,
                              _Details(
                                api: widget.api,
                                catalog: s.catalog,
                                row: s.row,
                              ),
                            ),
                            child: const Text('Сургалт үзэх'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                color: Colors.white,
                tooltip: 'Өмнөх стори',
                onPressed: page == 0 ? null : () => move(page - 1),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${page + 1} / ${widget.stories.length}',
                style: const TextStyle(color: Colors.white),
              ),
              IconButton(
                tooltip: 'Дараагийн стори',
                color: Colors.white,
                onPressed: page + 1 == widget.stories.length
                    ? null
                    : () => move(page + 1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
