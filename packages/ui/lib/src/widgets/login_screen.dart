import 'package:flutter/material.dart';

import '../theme/app_extra_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';

/// The sign-in page both apps share. It holds no Bloc: the app passes in what to show and gets the typed values back
/// through [onSubmit], so `ui` keeps depending only on Flutter and the domain.
///
/// The login and password live only in this widget's text fields, so an error or a busy state never clears them.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.title,
    required this.onSubmit,
    this.subtitle,
    this.busy = false,
    this.errorText,
    this.noticeText,
    this.appBar,
  });

  final String title;
  final String? subtitle;

  /// Called with the fields as typed. Trimming the login is the `LogIn` use case's job.
  final void Function(String login, String password) onSubmit;

  /// While true the fields and the button are disabled and the button shows a spinner.
  final bool busy;

  /// The last attempt failed, e.g. a wrong password. Shown in the destructive tone.
  final String? errorText;

  /// Why the user is here, e.g. an expired session. Shown in the warning tone.
  final String? noticeText;

  /// Lets mobile show a back arrow to the public pages.
  final PreferredSizeWidget? appBar;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _login = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _canSubmit => !widget.busy && _login.text.trim().isNotEmpty && _password.text.isNotEmpty;

  void _submit() {
    if (_canSubmit) {
      widget.onSubmit(_login.text, _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final extra = AppExtraColors.of(context);
    final subtitle = widget.subtitle;
    final noticeText = widget.noticeText;
    final errorText = widget.errorText;

    return Scaffold(
      appBar: widget.appBar,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.px24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.px24),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(widget.title, style: AppTextStyles.heading2xl, textAlign: TextAlign.center),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.px8),
                        Text(
                          subtitle,
                          style: AppTextStyles.bodyBase.copyWith(color: scheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.px24),
                      if (noticeText != null) ...[
                        _Message(noticeText, background: extra.warningSubtle, foreground: extra.warningForeground),
                        const SizedBox(height: AppSpacing.px16),
                      ],
                      if (errorText != null) ...[
                        _Message(errorText, background: scheme.errorContainer, foreground: scheme.onErrorContainer),
                        const SizedBox(height: AppSpacing.px16),
                      ],
                      TextField(
                        controller: _login,
                        enabled: !widget.busy,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: const [AutofillHints.username],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Korisničko ime'),
                      ),
                      const SizedBox(height: AppSpacing.px12),
                      TextField(
                        controller: _password,
                        enabled: !widget.busy,
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(labelText: 'Lozinka'),
                      ),
                      const SizedBox(height: AppSpacing.px24),
                      // Rebuilds on every keystroke, so the button turns on as soon as both fields have text.
                      ListenableBuilder(
                        listenable: Listenable.merge([_login, _password]),
                        builder: (context, _) => FilledButton(
                          onPressed: _canSubmit ? _submit : null,
                          child: widget.busy ? const _Spinner() : const Text('Prijavi se'),
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
    );
  }
}

/// A notice or an error above the fields. A live region, so a screen reader reads it out when it appears.
class _Message extends StatelessWidget {
  const _Message(this.text, {required this.background, required this.foreground});

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.px12),
          child: Text(text, style: AppTextStyles.bodySm.copyWith(color: foreground)),
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    // The button hands its (disabled) label color down through IconTheme, so the spinner matches the label.
    return SizedBox.square(
      dimension: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: IconTheme.of(context).color,
        semanticsLabel: 'Prijava u toku',
      ),
    );
  }
}
