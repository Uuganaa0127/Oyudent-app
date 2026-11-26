part of 'production_app.dart';

class _CourseSlides extends StatefulWidget {
  const _CourseSlides({
    super.key,
    required this.api,
    required this.catalog,
    required this.rows,
    this.compact = false,
  });
  final ProductionApi api;
  final Catalog catalog;
  final List<Record> rows;
  final bool compact;

  @override
  State<_CourseSlides> createState() => _CourseSlidesState();
}

class _CourseSlidesState extends State<_CourseSlides> {
  final controller = PageController(viewportFraction: .94);
  int page = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void move(int next) {
    if (!controller.hasClients || next < 0 || next >= widget.rows.length) {
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.jumpToPage(next);
    } else {
      controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.rows.length;
    final index = page.clamp(0, count - 1);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return Column(
      children: [
        SizedBox(
          height:
              (widget.compact ? 228.0 : 300.0) +
              (scale.clamp(1, 2.5) - 1) * 100,
          child: widget.compact && count == 1
              ? _CourseSlide(
                  api: widget.api,
                  catalog: widget.catalog,
                  row: widget.rows.first,
                )
              : PageView.builder(
                  padEnds: !widget.compact,
                  controller: controller,
                  itemCount: count,
                  onPageChanged: (i) => setState(() => page = i),
                  itemBuilder: (_, i) => AnimatedScale(
                    scale: i == index || reduced ? 1 : .97,
                    duration: reduced
                        ? Duration.zero
                        : const Duration(milliseconds: 240),
                    child: Padding(
                      padding: widget.compact
                          ? const EdgeInsets.only(right: 10)
                          : const EdgeInsets.symmetric(horizontal: 4),
                      child: _CourseSlide(
                        api: widget.api,
                        catalog: widget.catalog,
                        row: widget.rows[i],
                      ),
                    ),
                  ),
                ),
        ),
        if (count > 1)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.compact ? 0 : 16),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ExcludeSemantics(
                      child: SizedBox(
                        width: 38,
                        height: 4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _line,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: (index + 1) / count,
                              heightFactor: 1,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: _brand,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  '${index + 1} / $count',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                IconButton(
                  tooltip: 'Өмнөх сургалт',
                  onPressed: index > 0 ? () => move(index - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  tooltip: 'Дараагийн сургалт',
                  onPressed: index + 1 < count ? () => move(index + 1) : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CourseSlide extends StatelessWidget {
  const _CourseSlide({
    required this.api,
    required this.catalog,
    required this.row,
  });
  final ProductionApi api;
  final Catalog catalog;
  final Record row;

  @override
  Widget build(BuildContext context) {
    final classroom = catalog == Catalog.courses;
    final closed = classroom ? _registrationClosedReason(row) : null;
    final title = catalog.title(row);
    final image = catalog.image(row);
    final schedule = _certificateDate(row['start_date']);
    final metadata = [
      if (classroom && schedule.isNotEmpty) schedule,
      if (!classroom && row['lesson_count'] != null)
        '${row['lesson_count']} хичээл',
      if (!classroom && text(row, ['level_name']).isNotEmpty)
        text(row, ['level_name']),
    ].join('  ·  ');
    void open({bool apply = false}) => _push(
      context,
      _Details(api: api, catalog: catalog, row: row, applyOnOpen: apply),
    );
    return Material(
      color: classroom ? const Color(0xff104e60) : const Color(0xff394363),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: classroom
                    ? const [Color(0xff156370), Color(0xff468b9e)]
                    : const [Color(0xff495680), Color(0xff8182b4)],
              ),
            ),
          ),
          if (image.isEmpty) const CustomPaint(painter: _Contours()),
          if (image.isNotEmpty)
            _WebsiteImage(url: image, icon: catalog.icon)
          else
            Positioned.fill(
              child: Align(
                alignment: const Alignment(.9, -.55),
                child: FractionallySizedBox(
                  widthFactor: .46,
                  heightFactor: .73,
                  child: const CustomPaint(painter: _MolarArt()),
                ),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x22172840),
                  Color(0xb4182b43),
                  Color(0xed142339),
                ],
                stops: [0, .55, 1],
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: open,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                child: LayoutBuilder(
                  builder: (_, bounds) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: bounds.maxHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(catalog.icon, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  catalog.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (metadata.isNotEmpty)
                                  Text(
                                    metadata,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                Text(
                                  title.isEmpty ? catalog.label : title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 23,
                                    height: 1.13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 10,
                                  runSpacing: 4,
                                  children: [
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(
                                          0xff123a32,
                                        ),
                                        disabledBackgroundColor: Colors.white12,
                                        disabledForegroundColor: Colors.white70,
                                      ),
                                      onPressed: closed != null
                                          ? null
                                          : () => open(apply: classroom),
                                      icon: Icon(
                                        closed != null
                                            ? Icons.lock_outline
                                            : classroom
                                            ? Icons.event_available
                                            : Icons.arrow_forward,
                                        size: 16,
                                      ),
                                      label: Text(
                                        classroom
                                            ? 'Бүртгүүлэх'
                                            : 'Дэлгэрэнгүй',
                                      ),
                                    ),
                                    if (closed != null)
                                      Text(
                                        closed,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
