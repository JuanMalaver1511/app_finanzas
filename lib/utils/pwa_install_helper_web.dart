import 'dart:html' as html;
import 'dart:js' as js;

Future<bool> isRunningAsInstalledApp() async {
  final standalone =
      html.window.matchMedia('(display-mode: standalone)').matches;

  final fullscreen =
      html.window.matchMedia('(display-mode: fullscreen)').matches;

  final minimalUi =
      html.window.matchMedia('(display-mode: minimal-ui)').matches;

  final iosStandalone = js.context['navigator']['standalone'] == true;

  return standalone || fullscreen || minimalUi || iosStandalone;
}

Future<bool> promptInstallApp() async {
  final canInstall = js.context['kyboCanInstall'] == true;

  if (!canInstall) return false;

  final result = await js.context.callMethod('kyboPromptInstall');

  return result == true;
}