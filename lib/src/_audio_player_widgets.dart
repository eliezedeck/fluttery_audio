import 'package:flutter/widgets.dart';
import 'package:fluttery_audio/src/_audio_player.dart';
import 'package:fluttery_audio/fluttery_audio.dart';
import 'package:meta/meta.dart';
import 'package:logging/logging.dart';

final _log = new Logger('AudioPlayerWidget');

class Audio extends StatefulWidget {

  static AudioPlayer of(BuildContext context) {
    _AudioState state = context.ancestorStateOfType(
        new TypeMatcher<_AudioState>()
    );
    return state?._player;
  }

  final String audioUrl;
  final PlaybackState playbackState;
  final List<WatchableAudioProperties> callMe;
  final Widget Function(BuildContext, AudioPlayer) playerCallback;
  final List<WatchableAudioProperties> buildMe;
  final Widget Function(BuildContext, AudioPlayer, Widget child) playerBuilder;
  final Widget child;

  Audio({
    this.audioUrl,
    this.playbackState = PlaybackState.paused,
    this.callMe = const [],
    this.playerCallback,
    this.buildMe = const [],
    this.playerBuilder,
    this.child,
  });

  @override
  _AudioState createState() => new _AudioState();
}

class _AudioState extends State<Audio> {

  AudioPlayer _player;
  String _audioUrl;
  PlaybackState _playbackState;

  @override
  void initState() {
    super.initState();

    // TODO: player ID
    _player = FlutteryAudio.audioPlayer();
    _player.addListener(
      onBufferingUpdate: _onBufferingUpdate,
      onAudioReady: _onAudioReady,
      onPlayerPlaybackUpdate: _onPlayerPlaybackUpdate,
      onStateChanged: _onStateChanged,
      onSeekStarted: () {
        _onSeekingChanged(true);
      },
      onSeekCompleted: () {
        _onSeekingChanged(false);
      }
    );

    _setAudioUrl(widget.audioUrl);
    _playbackState = widget.playbackState;
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _log.fine('Widget changed. Updating Audio Widget state.');
    _setAudioUrl(widget.audioUrl);

    if (widget.playbackState != _playbackState) {
      _log.fine('The desired audio playback state has changed to: ${widget.playbackState}');
      _playbackState = widget.playbackState;
      if (_playbackState == PlaybackState.playing) {
        _player.play();
      } else if (_playbackState == PlaybackState.paused) {
        _player.pause();
      }
    }
  }

  _setAudioUrl(String url) {
    // If the url has changed then we need to switch audio sources.
    if (url != _audioUrl) {
      _audioUrl = url;
      _player.loadMedia(Uri.parse(_audioUrl));
    }
  }

  _onBufferingUpdate(int percent) {
//    _log.fine('on buffering update: $percent');
    if (widget.callMe.contains(WatchableAudioProperties.audioBuffering)) {
      widget.playerCallback(context, _player);
    }
    if (widget.buildMe.contains(WatchableAudioProperties.audioBuffering)) {
      setState(() {});
    }
  }

  _onAudioReady() {
    _log.fine('on audio ready');
    if (_playbackState == PlaybackState.playing) {
      _player.play();
      _log.fine('playing automatically');
    } else if (_playbackState == PlaybackState.paused) {
      _log.fine('not playing because client doesn\'t want it');
    }

    if (widget.callMe.contains(WatchableAudioProperties.audioLength)) {
      widget.playerCallback(context, _player);
    }
    if (widget.buildMe.contains(WatchableAudioProperties.audioLength)) {
      setState(() {});
    }
  }

  _onPlayerPlaybackUpdate(Duration position) {
//    _log.fine('on playback update: $position');
    if (widget.callMe.contains(WatchableAudioProperties.audioPlayhead)) {
      widget.playerCallback(context, _player);
    }
    if (widget.buildMe.contains(WatchableAudioProperties.audioPlayhead)) {
      setState(() {});
    }
  }

  _onStateChanged(AudioPlayerState newState) {
    _log.fine('on state changed: $newState');
    if (widget.callMe.contains(WatchableAudioProperties.audioPlayerState)) {
      widget.playerCallback(context, _player);
    }
    if (widget.buildMe.contains(WatchableAudioProperties.audioPlayerState)) {
      setState(() {});
    }
  }

  _onSeekingChanged(bool isSeeking) {
    _log.fine('on seeking changed: $isSeeking');
    if (widget.callMe.contains(WatchableAudioProperties.audioSeeking)) {
      widget.playerCallback(context, _player);
    }
    if (widget.buildMe.contains(WatchableAudioProperties.audioSeeking)) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _log.fine('building');
    return widget.playerBuilder != null
      ? widget.playerBuilder(context, _player, widget.child)
      : widget.child;
  }
}

enum WatchableAudioProperties {
  audioPlayerState,
  audioLength,
  audioBuffering,
  audioPlayhead,
  audioSeeking,
}

enum PlaybackState {
  playing,
  paused,
}

class AudioComponent extends StatefulWidget {

  final List<WatchableAudioProperties> updateMe;
  final Widget Function(BuildContext, AudioPlayer, Widget child) playerBuilder;
  final Widget child;

  AudioComponent({
    this.updateMe = const [],
    @required this.playerBuilder,
    this.child,
  });

  @override
  _AudioComponentState createState() => new _AudioComponentState();
}

class _AudioComponentState extends State<AudioComponent> {

  AudioPlayer _player;

  @override
  void initState() {
    super.initState();

    _player = Audio.of(context);
    if (_player == null) {
      throw new StateError('AudioComponent could not find an Audio ancestor.');
    }
    _player.addListener(
        onBufferingUpdate: _onBufferingUpdate,
        onAudioReady: _onAudioReady,
        onPlayerPlaybackUpdate: _onPlayerPlaybackUpdate,
        onStateChanged: _onStateChanged,
        onSeekStarted: () {
          _onSeekingChanged(true);
        },
        onSeekCompleted: () {
          _onSeekingChanged(false);
        }
    );
  }

  @override
  void dispose() {
    _player = null;
    super.dispose();
  }

  _onBufferingUpdate(int percent) {
    if (widget.updateMe.contains(WatchableAudioProperties.audioBuffering)) {
      setState(() {});
    }
  }

  _onAudioReady() {
    if (widget.updateMe.contains(WatchableAudioProperties.audioLength)) {
      setState(() {});
    }
  }

  _onPlayerPlaybackUpdate(Duration position) {
    if (widget.updateMe.contains(WatchableAudioProperties.audioPlayhead)) {
      setState(() {});
    }
  }

  _onStateChanged(AudioPlayerState newState) {
    _log.fine('onStateChnaged: $newState');
    if (widget.updateMe.contains(WatchableAudioProperties.audioPlayerState)) {
      setState(() {});
    }
  }

  _onSeekingChanged(bool isSeeking) {
    _log.fine('onSeekingChanged: $isSeeking');
    if (widget.updateMe.contains(WatchableAudioProperties.audioSeeking)) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.playerBuilder != null
        ? widget.playerBuilder(context, _player, widget.child)
        : widget.child;
  }
}
