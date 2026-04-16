import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../core/colors.dart';
import '../core/widgets.dart';
import '../services/claude_service.dart';
import 'settings_screen.dart';

enum VoiceState { idle, listening, thinking, speaking }

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen>
    with SingleTickerProviderStateMixin {
  // Voice state machine
  VoiceState _voiceState = VoiceState.idle;

  // Conversation
  final List<Map<String, String>> _conversationHistory = [];
  String  _responseText   = '';
  bool    _showCursor     = false;
  bool    _isKeyError     = false;
  String? _errorText;
  String  _partialTranscript = '';

  // Services
  final _stt    = SpeechToText();
  final _tts    = FlutterTts();
  final _claude = ClaudeService();
  bool _sttInitialized = false;

  // Animation
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;
  Timer? _cursorTimer;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _configureTts();
  }

  Future<void> _configureTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.95);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _voiceState = VoiceState.idle);
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _pulseCtrl.dispose();
    _cursorTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  // ── Permission & STT init ─────────────────────────────────────────────────

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  Future<bool> _ensureSttInitialized() async {
    if (_sttInitialized) return true;
    _sttInitialized = await _stt.initialize(
      onError: (error) {
        if (mounted) {
          setState(() {
            _voiceState   = VoiceState.idle;
            _errorText    = 'COULDN\'T HEAR THAT. TRY AGAIN.';
            _isKeyError   = false;
            _pulseCtrl.stop();
            _pulseCtrl.reset();
          });
        }
      },
    );
    return _sttInitialized;
  }

  // ── Voice interaction loop ────────────────────────────────────────────────

  Future<void> _startListening() async {
    if (_voiceState != VoiceState.idle) return;

    if (!await _ensureMicPermission()) {
      setState(() {
        _errorText  = 'MICROPHONE PERMISSION DENIED.';
        _isKeyError = false;
      });
      return;
    }
    if (!await _ensureSttInitialized()) {
      setState(() {
        _errorText  = 'SPEECH RECOGNITION UNAVAILABLE ON THIS DEVICE.';
        _isKeyError = false;
      });
      return;
    }

    setState(() {
      _voiceState        = VoiceState.listening;
      _partialTranscript = '';
      _errorText         = null;
      _isKeyError        = false;
    });

    _pulseCtrl.repeat(reverse: true);

    await _stt.listen(
      onResult: (result) {
        if (mounted) {
          setState(() => _partialTranscript = result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor:  const Duration(seconds: 5),
      listenOptions: SpeechListenOptions(partialResults: true),
    );
  }

  Future<void> _stopListeningAndProcess() async {
    if (_voiceState != VoiceState.listening) return;
    await _stt.stop();
    _pulseCtrl.stop();
    _pulseCtrl.reset();

    final transcript = _partialTranscript.trim();
    if (transcript.isEmpty) {
      setState(() => _voiceState = VoiceState.idle);
      return;
    }

    _conversationHistory.add({'role': 'user', 'content': transcript});
    setState(() {
      _voiceState  = VoiceState.thinking;
      _responseText = '';
      _showCursor  = true;
      _errorText   = null;
      _isKeyError  = false;
    });

    _cursorTimer?.cancel();
    _cursorTimer = Timer.periodic(
      const Duration(milliseconds: 530),
      (_) { if (mounted) setState(() => _showCursor = !_showCursor); },
    );

    await _streamResponse();
  }

  void _cancelListening() {
    _stt.cancel();
    _pulseCtrl.stop();
    _pulseCtrl.reset();
    setState(() => _voiceState = VoiceState.idle);
  }

  Future<void> _streamResponse() async {
    final buffer = StringBuffer();
    try {
      await for (final chunk in _claude.sendMessage(_conversationHistory)) {
        buffer.write(chunk);
        if (mounted) setState(() => _responseText = buffer.toString());
      }
      _conversationHistory.add(
        {'role': 'assistant', 'content': buffer.toString()});

      _cursorTimer?.cancel();
      setState(() {
        _showCursor  = false;
        _voiceState  = VoiceState.speaking;
      });
      await _tts.speak(buffer.toString());
    } catch (e, stack) {
      debugPrint('=== CLAUDY ERROR ===');
      debugPrint(e.toString());
      debugPrint(stack.toString());
      debugPrint('===================');
      _cursorTimer?.cancel();
      final msg = e.toString().toLowerCase();
      setState(() {
        _showCursor = false;
        _voiceState = VoiceState.idle;
        if (msg.contains('no api key configured')) {
          _errorText  = 'NO API KEY SET. TAP HERE TO ADD ONE.';
          _isKeyError = true;
        } else if (msg.contains('api error 401') || msg.contains('api error 403')) {
          _errorText  = 'INVALID API KEY. TAP HERE TO UPDATE SETTINGS.';
          _isKeyError = true;
        } else if (msg.contains('socket') || msg.contains('network') ||
                   msg.contains('failed host lookup') || msg.contains('connection')) {
          _errorText  = 'NO INTERNET CONNECTION. CHECK YOUR NETWORK.';
          _isKeyError = false;
        } else {
          _errorText  = 'AN ERROR OCCURRED. PLEASE TRY AGAIN.';
          _isKeyError = false;
        }
      });
    }
  }

  void _stopSpeaking() {
    _tts.stop();
    setState(() => _voiceState = VoiceState.idle);
  }

  void _newConversation() {
    setState(() {
      _conversationHistory.clear();
      _responseText = '';
      _errorText    = null;
      _isKeyError   = false;
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _statusText {
    switch (_voiceState) {
      case VoiceState.idle:      return 'SYSTEM STATUS: OPTIMAL';
      case VoiceState.listening: return 'SYSTEM STATUS: LISTENING';
      case VoiceState.thinking:  return 'SYSTEM STATUS: PROCESSING';
      case VoiceState.speaking:  return 'SYSTEM STATUS: RESPONDING';
    }
  }

  String get _buttonLabel {
    switch (_voiceState) {
      case VoiceState.idle:      return 'LISTEN';
      case VoiceState.listening: return 'LISTENING...';
      case VoiceState.thinking:  return 'THINKING...';
      case VoiceState.speaking:  return 'SPEAKING...';
    }
  }

  Color get _buttonColor {
    switch (_voiceState) {
      case VoiceState.idle:      return CL.primaryContainer;
      case VoiceState.listening: return CL.primary;
      case VoiceState.thinking:  return CL.surfaceContainerHigh;
      case VoiceState.speaking:  return CL.primaryContainer;
    }
  }

  IconData get _buttonIcon {
    return _voiceState == VoiceState.listening ? Icons.mic : Icons.mic_none;
  }

  String get _displayText {
    if (_errorText != null) return _errorText!;
    if (_responseText.isEmpty) {
      return '"ALL SYSTEMS ARE STABLE. WOULD YOU LIKE ME TO BREW SOME COFFEE?"';
    }
    return _responseText + (_showCursor ? '▌' : '');
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CL.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header with settings icon ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_statusText,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: CL.secondary, letterSpacing: 4,
                    )),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (ctx, anim, sec) => const SettingsScreen(),
                        transitionsBuilder: (ctx, anim, sec, child) =>
                          SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: anim, curve: Curves.easeInOut)),
                            child: child,
                          ),
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: CL.surfaceContainerHigh,
                        boxShadow: [BoxShadow(
                          color: CL.surfaceContainerLowest,
                          offset: Offset(4, 4))],
                      ),
                      child: const Icon(Icons.settings,
                        color: CL.outline, size: 20),
                    ),
                  ),
                ],
              ),
              Container(
                height: 4, color: CL.surfaceContainerHigh,
                margin: const EdgeInsets.only(top: 8, bottom: 32)),

              // ── ASCII face + response box ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                decoration: BoxDecoration(
                  color: CL.surfaceContainer,
                  border: Border.all(color: CL.primary, width: 8),
                  boxShadow: const [BoxShadow(
                    color: CL.surfaceContainerLowest, offset: Offset(6, 6))],
                ),
                child: Column(
                  children: [
                    Text('( ^ _ ^ )',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 48, fontWeight: FontWeight.w900,
                        color: CL.primary, letterSpacing: 4,
                      )),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: CL.background,
                        border: Border.all(color: CL.primary, width: 2),
                        boxShadow: const [BoxShadow(
                          color: CL.surfaceContainerLowest,
                          offset: Offset(4, 4))],
                      ),
                      child: SingleChildScrollView(
                        child: _isKeyError
                          ? GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (ctx, anim, sec) =>
                                    const SettingsScreen(),
                                  transitionsBuilder: (ctx, anim, sec, child) =>
                                    SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(1, 0),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(
                                        parent: anim,
                                        curve: Curves.easeInOut)),
                                      child: child,
                                    ),
                                  transitionDuration:
                                    const Duration(milliseconds: 300),
                                ),
                              ),
                              child: Text(_displayText,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 18, fontWeight: FontWeight.w900,
                                  color: CL.secondary, letterSpacing: 1,
                                  decoration: TextDecoration.underline,
                                  decorationColor: CL.secondary,
                                )),
                            )
                          : Text(_displayText,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 18, fontWeight: FontWeight.w900,
                                color: _errorText != null
                                  ? CL.secondary
                                  : CL.onSurface,
                                letterSpacing: 1,
                              )),
                      ),
                    ),
                  ],
                ),
              ),

              // ── NEW CONVERSATION button (shown when history exists) ──
              if (_conversationHistory.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _newConversation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                      decoration: const BoxDecoration(
                        color: CL.surfaceContainerHigh,
                        boxShadow: [BoxShadow(
                          color: CL.surfaceContainerLowest,
                          offset: Offset(4, 4))],
                      ),
                      child: Text('NEW CONVERSATION',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: CL.outline, letterSpacing: 3,
                        )),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // ── LISTEN button (push-to-talk, state-aware) ──
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Transform.scale(
                  scale: _voiceState == VoiceState.listening
                    ? _pulseAnim.value
                    : 1.0,
                  child: child,
                ),
                child: GestureDetector(
                  onTapDown: _voiceState == VoiceState.idle
                    ? (_) => _startListening()
                    : null,
                  onTapUp: _voiceState == VoiceState.listening
                    ? (_) => _stopListeningAndProcess()
                    : null,
                  onTapCancel: _voiceState == VoiceState.listening
                    ? () => _cancelListening()
                    : null,
                  onTap: _voiceState == VoiceState.speaking
                    ? () => _stopSpeaking()
                    : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: _buttonColor,
                      border: Border.all(color: CL.primary, width: 4),
                      boxShadow: const [BoxShadow(
                        color: CL.surfaceContainerLowest,
                        offset: Offset(10, 10))],
                    ),
                    child: Column(
                      children: [
                        Icon(_buttonIcon, color: Colors.white, size: 64),
                        const SizedBox(height: 12),
                        Text(_buttonLabel,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16, fontWeight: FontWeight.w900,
                            color: Colors.white, letterSpacing: 8,
                          )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Quick action grid ──
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: const [
                  ActionTile(icon: Icons.lightbulb,
                    label: 'LIGHTS', sub: '6 DEVICES ON',
                    color: CL.secondary),
                  ActionTile(icon: Icons.thermostat,
                    label: 'TEMP', sub: 'SET TO 68.0°',
                    color: CL.primary),
                  ActionTile(icon: Icons.music_note,
                    label: 'MUSIC', sub: 'LO-FI RADIO',
                    color: CL.primary),
                  ActionTile(icon: Icons.settings_input_component,
                    label: 'SCENES', sub: '3 ACTIVE',
                    color: CL.outline),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
