import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../core/app_colors.dart';
import 'camera_capture_page.dart';
import '../../core/date_utils.dart';
import '../../core/widgets.dart';
import '../../data/database/diary_repository.dart';
import '../../data/images/app_image_storage.dart';
import '../../data/preferences/draft_store.dart';
import '../../data/weather/weather_service.dart';
import '../../models/diary_entry.dart';
import '../../models/mood.dart';
import '../../models/weather_code.dart';
import '../backup/backup_models.dart';
import '../backup/export_flow.dart';
import 'widgets/image_preview.dart';
import 'widgets/mood_selector.dart';
import 'widgets/weather_picker.dart';

class EditorPage extends ConsumerStatefulWidget {
  const EditorPage({super.key, required this.date});

  final DateTime date;

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage>
    with WidgetsBindingObserver {
  static const Uuid _uuid = Uuid();
  static const int _maxImages = 9;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  late final DateTime _date = dateOnly(widget.date);
  late DraftStore _draftStore;
  late AppImageStorage _imageStorage;

  Mood? _mood;
  String? _weatherCode;
  int? _temperature;
  String? _city;
  bool _isFavorite = false;
  List<String> _images = [];
  List<String> _originalImages = [];
  String _entryId = _uuid.v4();
  DateTime _createdAt = DateTime.now();
  String? _imagesRoot;

  bool _initialized = false;
  bool _saving = false;
  bool _compressing = false;
  bool _hasExisting = false;
  bool _weatherManuallyChosen = false;
  bool _completed = false;
  Timer? _draftTimer;

  @override
  void initState() {
    super.initState();
    _draftStore = ref.read(draftStoreProvider);
    _imageStorage = ref.read(appImageStorageProvider);
    WidgetsBinding.instance.addObserver(this);
    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
    unawaited(_load());
  }

  Future<void> _load() async {
    final repository = ref.read(diaryRepositoryProvider);
    final existing = await repository.getByDate(_date);
    var draft = await _draftStore.read(_date);
    if (draft != null &&
        existing != null &&
        !draft.updatedAt.isAfter(existing.updatedAt)) {
      await _draftStore.clear(_date);
      draft = null;
    }
    final base = draft ?? existing;
    final imagesDirectory = await _imageStorage.imagesDirectory();
    if (!mounted) return;

    _initialized = false;
    _titleController.text = base?.title ?? '';
    _contentController.text = base?.content ?? '';
    setState(() {
      _imagesRoot = imagesDirectory.parent.path;
      _mood = base?.mood;
      _weatherCode = base?.weatherCode;
      _temperature = base?.temperature;
      _city = base?.city;
      _isFavorite = base?.isFavorite ?? false;
      _images = List.of(base?.images ?? const <String>[]);
      _originalImages = List.of(existing?.images ?? const <String>[]);
      _entryId = base?.id.trim().isNotEmpty == true ? base!.id : _uuid.v4();
      _createdAt = base?.createdAt ?? DateTime.now();
      _hasExisting = existing != null;
      _initialized = true;
    });
    if (_weatherCode == null || _city == null) {
      unawaited(_autoWeather());
    }
  }

  void _onChanged() {
    if (!_initialized || _completed) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(seconds: 2), () {
      unawaited(_saveDraftNow());
    });
  }

  DiaryEntry _buildEntry({DateTime? updatedAt}) {
    return DiaryEntry(
      id: _entryId,
      date: _date,
      title: _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim(),
      content: _contentController.text,
      mood: _mood,
      weatherCode: _weatherCode,
      temperature: _temperature,
      city: _city,
      isFavorite: _isFavorite,
      images: List.of(_images),
      createdAt: _createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  bool get _hasSavableContent =>
      _contentController.text.trim().isNotEmpty ||
      _titleController.text.trim().isNotEmpty ||
      _images.isNotEmpty;

  Future<void> _saveDraftNow() async {
    _draftTimer?.cancel();
    _draftTimer = null;
    if (!_initialized || _saving || _completed) return;
    final entry = _buildEntry();
    try {
      if (!entry.hasContent) {
        await _draftStore.clear(_date);
      } else {
        await _draftStore.save(entry);
      }
    } catch (_) {
      // 草稿失败不影响继续写作。
    }
  }

  Future<void> _handleBack() async {
    if (_saving) return;
    await _saveDraftNow();
    _completed = true;
    if (mounted) Navigator.of(context).pop(false);
  }

  Future<DiaryEntry?> _persist({required bool pop}) async {
    if (!_hasSavableContent) {
      showAppSnackBar(context, '写点什么再保存');
      return null;
    }
    if (_saving) return null;
    setState(() => _saving = true);
    final repository = ref.read(diaryRepositoryProvider);
    try {
      final saved = await repository.save(_buildEntry());
      final removed = _originalImages
          .where((image) => !_images.contains(image))
          .toList(growable: false);
      await _imageStorage.deletePaths(removed);
      await _draftStore.clear(_date);
      if (!mounted) return saved;

      setState(() {
        _entryId = saved.id;
        _createdAt = saved.createdAt;
        _originalImages = List.of(_images);
        _hasExisting = true;
        _saving = false;
        if (pop) _completed = true;
      });
      if (pop) {
        Navigator.of(context).pop(true);
      }
      return saved;
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showAppSnackBar(context, '保存失败，请稍后重试');
      }
      return null;
    }
  }

  Future<void> _shareCurrent() async {
    if (_saving) return;
    if (!_hasSavableContent) {
      showAppSnackBar(context, '写点什么再分享');
      return;
    }
    final saved = await _persist(pop: false);
    if (!mounted || saved == null) return;
    await ExportFlow.start(context, scope: ExportScope.single(saved.id));
  }

  Future<void> _deleteEntry() async {
    if (!_hasExisting || _saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除这篇日记？'),
        content: const Text('正文和图片都会从本机删除，且不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: dialogContext.colors.danger,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref.read(diaryRepositoryProvider).deleteById(_entryId);
      await _draftStore.clear(_date);
      final files = <String>{..._originalImages, ..._images};
      await _imageStorage.deletePaths(files);
      _completed = true;
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showAppSnackBar(context, '删除失败，请稍后重试');
      }
    }
  }

  Future<void> _autoWeather() async {
    if (_weatherManuallyChosen || (_weatherCode != null && _city != null)) {
      return;
    }
    final snapshot = await ref.read(weatherServiceProvider).currentWeather();
    if (!mounted || snapshot == null || _weatherManuallyChosen) return;
    setState(() {
      _weatherCode ??= snapshot.code.code;
      _temperature ??= snapshot.temperature;
      _city ??= snapshot.city;
    });
    _onChanged();
  }

  Future<void> _chooseWeather() async {
    final weather = await showWeatherPicker(context);
    if (!mounted || weather == null) return;
    setState(() {
      _weatherManuallyChosen = true;
      _weatherCode = weather.code;
    });
    _onChanged();
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    _onChanged();
  }

  Future<void> _showImageSourceSheet() async {
    if (_compressing || _images.length >= _maxImages) return;
    final source = await showModalBottomSheet<_ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      useSafeArea: true,
      builder: (context) {
        final colors = context.colors;
        return Material(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    leading: Icon(
                      Icons.photo_library_outlined,
                      color: colors.primary,
                    ),
                    title: const Text('从相册选择'),
                    onTap: () =>
                        Navigator.of(context).pop(_ImageSource.gallery),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.photo_camera_outlined,
                      color: colors.primary,
                    ),
                    title: const Text('拍照'),
                    onTap: () => Navigator.of(context).pop(_ImageSource.camera),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (!mounted || source == null) return;
    if (source == _ImageSource.camera) {
      await _capturePhoto();
    } else {
      await _pickImages(source);
    }
  }

  Future<void> _capturePhoto() async {
    final remaining = _maxImages - _images.length;
    if (_compressing || remaining <= 0) return;
    final path = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CameraCapturePage()),
    );
    if (!mounted || path == null) return;
    setState(() => _compressing = true);
    try {
      final relative = await _imageStorage.importAndCompress(path);
      if (!mounted) return;
      setState(() => _images.add(relative));
      _onChanged();
      showAppSnackBar(context, '已添加 1 张照片');
    } catch (error) {
      debugPrint('camera image import failed: $error');
      if (mounted) showAppSnackBar(context, '照片保存失败，请重试');
    } finally {
      if (mounted) setState(() => _compressing = false);
    }
  }

  Future<void> _pickImages(_ImageSource source) async {
    final remaining = _maxImages - _images.length;
    if (remaining <= 0) return;

    List<XFile> picked;
    try {
      if (source == _ImageSource.gallery) {
        picked = await _imagePicker.pickMultiImage();
      } else {
        final single = await _imagePicker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
        );
        picked = single == null ? const [] : [single];
      }
    } on PlatformException {
      if (mounted) {
        showAppSnackBar(
          context,
          source == _ImageSource.gallery ? '无法访问相册' : '无法使用相机',
        );
      }
      return;
    } catch (error) {
      if (mounted) showAppSnackBar(context, '没有选择图片：$error');
      return;
    }
    if (picked.isEmpty || !mounted) {
      if (mounted && source == _ImageSource.camera) {
        showAppSnackBar(context, '相机没有返回照片，请重试');
      }
      return;
    }
    if (picked.length > remaining) {
      picked = picked.take(remaining).toList();
      showAppSnackBar(context, '最多添加 $_maxImages 张图片');
    }

    setState(() => _compressing = true);
    var failures = 0;
    var added = 0;
    for (final file in picked) {
      if (!mounted) return;
      try {
        final relative = await _imageStorage.importAndCompress(file.path);
        if (!mounted) return;
        setState(() => _images.add(relative));
        added++;
        _onChanged();
      } catch (error) {
        failures++;
        debugPrint('image import failed: $error');
      }
    }
    if (!mounted) return;
    setState(() => _compressing = false);
    if (added > 0) {
      showAppSnackBar(context, '已添加 $added 张照片');
    }
    if (failures > 0) {
      showAppSnackBar(context, '有 $failures 张图片处理失败，请重试');
    }
  }

  Future<void> _openPreview(int index) async {
    final root = _imagesRoot;
    if (root == null || _images.isEmpty) return;
    final absolute = _images
        .map((relative) => p.join(root, relative))
        .toList(growable: false);
    final removed = await showImagePreview(
      context,
      absolutePaths: absolute,
      initialIndex: index,
    );
    if (!mounted || removed == null) return;
    if (removed < 0 || removed >= _images.length) return;
    final relative = _images[removed];
    setState(() => _images.removeAt(removed));
    if (!_originalImages.contains(relative)) {
      await _imageStorage.deletePaths([relative]);
    }
    _onChanged();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_saveDraftNow());
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateLabel = editorDateLabel(_date, now: DateTime.now());

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) unawaited(_saveDraftNow());
      },
      child: Scaffold(
        backgroundColor: colors.background,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              _EditorHeader(
                dateLabel: dateLabel,
                saving: _saving,
                onBack: _handleBack,
                onShare: _shareCurrent,
                onSave: () => _persist(pop: true),
                isFavorite: _isFavorite,
                onFavorite: _toggleFavorite,
              ),
              Expanded(
                child: !_initialized
                    ? const SizedBox.shrink()
                    : Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: SingleChildScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionCaption(text: '心情'),
                                const SizedBox(height: 2),
                                MoodSelector(
                                  value: _mood,
                                  onChanged: (mood) {
                                    setState(() => _mood = mood);
                                    _onChanged();
                                  },
                                ),
                                const SizedBox(height: 18),
                                _SectionCaption(text: '天气'),
                                const SizedBox(height: 8),
                                WeatherChip(
                                  code: WeatherCode.fromCode(_weatherCode),
                                  temperature: _temperature,
                                  city: _city,
                                  onTap: _chooseWeather,
                                ),
                                const SizedBox(height: 22),
                                TextField(
                                  controller: _titleController,
                                  style: TextStyle(
                                    color: colors.text,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '标题（可选）',
                                    hintStyle: TextStyle(
                                      color: colors.secondaryText.withValues(
                                        alpha: 0.72,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _contentController,
                                  minLines: 12,
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  style: TextStyle(
                                    color: colors.text,
                                    fontSize: 16.5,
                                    height: 1.8,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '写点什么…',
                                    hintStyle: TextStyle(
                                      color: colors.secondaryText.withValues(
                                        alpha: 0.62,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                ),
                                if (_images.isNotEmpty || _compressing) ...[
                                  const SizedBox(height: 18),
                                  _ImageGrid(
                                    images: _images,
                                    imagesRoot: _imagesRoot,
                                    compressing: _compressing,
                                    onAdd: _showImageSourceSheet,
                                    onPreview: _openPreview,
                                  ),
                                ],
                                if (_hasExisting) ...[
                                  const SizedBox(height: 36),
                                  TextButton(
                                    onPressed: _saving ? null : _deleteEntry,
                                    style: TextButton.styleFrom(
                                      foregroundColor: colors.danger,
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 32),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      '删除本篇',
                                      style: TextStyle(fontSize: 12.5),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _EditorBottomBar(
          imageCount: _images.length,
          maxImages: _maxImages,
          busy: _compressing,
          onCamera: _capturePhoto,
          onGallery: () => _pickImages(_ImageSource.gallery),
        ),
      ),
    );
  }
}

class _EditorBottomBar extends StatelessWidget {
  const _EditorBottomBar({
    required this.imageCount,
    required this.maxImages,
    required this.busy,
    required this.onCamera,
    required this.onGallery,
  });

  final int imageCount;
  final int maxImages;
  final bool busy;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      top: false,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: colors.background,
          border: Border(top: BorderSide(color: colors.divider)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: busy || imageCount >= maxImages ? null : onCamera,
              icon: const Icon(Icons.photo_camera_outlined, size: 20),
              label: const Text('拍照'),
              style: TextButton.styleFrom(foregroundColor: colors.primary),
            ),
            TextButton.icon(
              onPressed: busy || imageCount >= maxImages ? null : onGallery,
              icon: const Icon(Icons.photo_library_outlined, size: 20),
              label: const Text('相册'),
              style: TextButton.styleFrom(foregroundColor: colors.primary),
            ),
            const Spacer(),
            Text(
              '$imageCount/$maxImages',
              style: TextStyle(color: colors.secondaryText, fontSize: 12),
            ),
            const SizedBox(width: 18),
          ],
        ),
      ),
    );
  }
}

enum _ImageSource { gallery, camera }

class _EditorHeader extends StatelessWidget {
  const _EditorHeader({
    required this.dateLabel,
    required this.saving,
    required this.onBack,
    required this.onShare,
    required this.onSave,
    required this.isFavorite,
    required this.onFavorite,
  });

  final String dateLabel;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final bool isFavorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: Row(
        children: [
          TopIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: '返回',
            onTap: saving ? () {} : onBack,
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  dateLabel,
                  maxLines: 1,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
          TopIconButton(
            icon: isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            color: isFavorite ? colors.primary : null,
            tooltip: isFavorite ? '取消收藏' : '收藏',
            onTap: saving ? () {} : onFavorite,
          ),
          TopIconButton(
            icon: Icons.ios_share_rounded,
            tooltip: '导出本篇',
            onTap: saving ? () {} : onShare,
          ),
          TextButton(
            onPressed: saving ? null : onSave,
            style: TextButton.styleFrom(
              foregroundColor: colors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 44),
            ),
            child: Text(
              saving ? '保存中' : '保存',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCaption extends StatelessWidget {
  const _SectionCaption({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.colors.secondaryText.withValues(alpha: 0.8),
        fontSize: 10.5,
        letterSpacing: 2,
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({
    required this.images,
    required this.imagesRoot,
    required this.compressing,
    required this.onAdd,
    required this.onPreview,
  });

  final List<String> images;
  final String? imagesRoot;
  final bool compressing;
  final VoidCallback onAdd;
  final ValueChanged<int> onPreview;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final showAdd = images.length < 9;
    final itemCount = images.length + (showAdd ? 1 : 0);
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        if (showAdd && index == images.length) {
          return InkWell(
            onTap: compressing ? null : onAdd,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: colors.field,
                borderRadius: BorderRadius.circular(10),
              ),
              child: compressing
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 1.8),
                      ),
                    )
                  : Icon(
                      Icons.add_rounded,
                      size: 24,
                      color: colors.secondaryText,
                    ),
            ),
          );
        }
        final relative = images[index];
        final absolute = imagesRoot == null
            ? null
            : p.join(imagesRoot!, relative);
        return GestureDetector(
          onTap: () => onPreview(index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: absolute == null
                ? ColoredBox(color: colors.field)
                : Image.file(
                    File(absolute),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => ColoredBox(
                      color: colors.field,
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 20,
                        color: colors.secondaryText,
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
