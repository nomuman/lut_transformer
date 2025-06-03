import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:lut_transformer/lut_transformer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  XFile? _pickedVideoFile;
  File? _transformedVideoFile;
  VideoPlayerController? _videoPlayerController;
  double _currentProgress = 0.0;
  String? _progressMessage;
  bool _isProcessing = false;
  String? _errorMessage;
  bool _isDownloading = false;
  String? _downloadMessage;
  bool _flipHorizontally = false;

  @override
  void initState() {
    super.initState();
    _initPlatformState();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  /// プラットフォームバージョンを初期化する
  Future<void> _initPlatformState() async {
    String platformVersion;
    try {
      platformVersion =
          await LutTransformer.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  /// 動画を撮影または選択する
  Future<void> _pickVideo() async {
    setState(() {
      _pickedVideoFile = null;
      _transformedVideoFile = null;
      _videoPlayerController?.dispose();
      _videoPlayerController = null;
      _errorMessage = null;
      _progressMessage = null;
      _currentProgress = 0.0;
      _downloadMessage = null;
    });

    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickMedia();

    if (video != null) {
      setState(() {
        _pickedVideoFile = video;
      });
      _initializeVideoPlayer(File(video.path));
    }
  }

  /// 動画を加工する
  Future<void> _transformVideo() async {
    if (_pickedVideoFile == null) {
      setState(() {
        _errorMessage = '動画が選択されていません。';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _transformedVideoFile = null;
      _videoPlayerController?.dispose();
      _videoPlayerController = null;
      _errorMessage = null;
      _progressMessage = '準備中...';
      _currentProgress = 0.0;
      _downloadMessage = null;
    });

    try {
      final stream = LutTransformer.transformVideo(
        File(_pickedVideoFile!.path),
        lutAsset: 'assets/luts/sample.cube',
        flipHorizontally: _flipHorizontally,
      );

      await for (final event in stream) {
        if (!mounted) return;
        setState(() {
          _currentProgress = event.progress;
          if (event.error != null) {
            _errorMessage =
                '動画の加工中にエラーが発生しました: ${event.error!.message} (コード: ${event.error!.code})';
            _progressMessage = 'エラーが発生しました';
            _isProcessing = false;
          } else if (event.outputPath != null) {
            _transformedVideoFile = File(event.outputPath!);
            _progressMessage = '加工が完了しました！';
            _isProcessing = false; // 完了したのでフラグを倒す
            _initializeVideoPlayer(File(event.outputPath!));
          } else {
            _progressMessage =
                '動画を加工中... (${(_currentProgress * 100).toStringAsFixed(0)}%)';
          }
        });
        // エラーか完了があればループを抜ける
        if (event.error != null || event.outputPath != null) {
          break;
        }
      }
    } on PlatformException catch (e) {
      // このcatchはLutTransformer.transformVideo呼び出し自体のエラー用だが、
      // Stream内でエラーが処理されるため、通常ここには来ないはず。
      if (!mounted) return;
      setState(() {
        _errorMessage = '動画の加工に失敗しました: ${e.message}';
        _isProcessing = false;
        _progressMessage = 'エラーが発生しました';
      });
    } catch (e) {
      // その他の予期せぬエラー
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = '予期せぬエラーが発生しました: $e';
        _progressMessage = 'エラーが発生しました';
      });
    }
  }

  /// 加工済み動画をダウンロードする
  Future<void> _downloadVideo() async {
    if (_transformedVideoFile == null) {
      setState(() {
        _downloadMessage = 'ダウンロードする加工済み動画がありません。';
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadMessage = null;
    });

    try {
      final result = await SaverGallery.saveFile(
        filePath: _transformedVideoFile!.path,
        fileName: 'transformed_video.mp4',
        skipIfExists: true,
      );
      if (result.isSuccess) {
        setState(() {
          _downloadMessage = '動画をギャラリーに保存しました。';
        });
      } else {
        setState(() {
          _downloadMessage = '動画の保存に失敗しました。';
        });
      }
    } catch (e) {
      setState(() {
        _downloadMessage = '動画の保存中にエラーが発生しました: $e';
      });
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  /// 動画プレイヤーを初期化する
  Future<void> _initializeVideoPlayer(File videoFile) async {
    _videoPlayerController = VideoPlayerController.file(videoFile);
    await _videoPlayerController!.initialize();
    setState(() {});
    _videoPlayerController!.play();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('LUT Transformer Example')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Running on: $_platformVersion\n',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              _buildVideoSelectionSection(),
              const SizedBox(height: 20),
              _buildVideoTransformationSection(),
              const SizedBox(height: 20),
              _buildVideoPlayerSection(),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    'エラー: $_errorMessage',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 動画選択セクションを構築する
  Widget _buildVideoSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('1. 動画を選択', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: _pickVideo, child: const Text('動画を撮影/選択')),
        if (_pickedVideoFile != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('選択された動画: ${_pickedVideoFile!.path.split('/').last}'),
          ),
      ],
    );
  }

  /// 動画加工セクションを構築する
  Widget _buildVideoTransformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('2. 動画を加工', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Row(
          children: [
            ElevatedButton(
              onPressed: _pickedVideoFile != null && !_isProcessing
                  ? _transformVideo
                  : null,
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.0,
                      ),
                    )
                  : const Text('動画を加工 (LUT適用)'),
            ),
            const SizedBox(width: 10),
            Text('左右反転:'),
            Switch(
              value: _flipHorizontally,
              onChanged: (value) {
                setState(() {
                  _flipHorizontally = value;
                });
              },
            ),
          ],
        ),
        if (_isProcessing)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              children: [
                LinearProgressIndicator(value: _currentProgress),
                const SizedBox(height: 5),
                Text(_progressMessage ?? '動画を加工中...'),
              ],
            ),
          ),
        if (_transformedVideoFile != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              '加工済み動画: ${_transformedVideoFile!.path.split('/').last}',
            ),
          ),
          const SizedBox(height: 10),
          _buildDownloadButton(),
        ],
        if (_downloadMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_downloadMessage!),
          ),
      ],
    );
  }

  Widget _buildDownloadButton() {
    return ElevatedButton(
      onPressed: _transformedVideoFile != null && !_isDownloading
          ? _downloadVideo
          : null,
      child: _isDownloading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('加工済み動画をダウンロード'),
    );
  }

  /// 動画プレイヤーセクションを構築する
  Widget _buildVideoPlayerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('3. 動画を再生', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        if (_videoPlayerController != null &&
            _videoPlayerController!.value.isInitialized)
          AspectRatio(
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            child: VideoPlayer(_videoPlayerController!),
          )
        else if (_pickedVideoFile != null || _transformedVideoFile != null)
          const Center(child: CircularProgressIndicator())
        else
          const Text('動画を再生するには、まず動画を選択して加工してください。'),
      ],
    );
  }
}
