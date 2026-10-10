import 'package:flutter/material.dart';
import 'package:geomapcam/core/providers/settings_provider.dart';
import 'package:geomapcam/features/capture/domain/capture_metadata.dart';
import 'package:geomapcam/features/settings/data/settings_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geomapcam/core/localization/app_localizations.dart';
import 'package:geomapcam/core/utils/banner_ad_widget.dart';

/// Settings screen for configuring app preferences.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsService = SettingsProvider.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Settings'))),
      body: ListenableBuilder(
        listenable: settingsService,
        builder: (context, _) {
          return ListView(
            children: [
              _buildSectionHeader(theme, context.tr('GENERAL')),
              _buildSimpleTile(
                context,
                Icons.translate,
                context.tr('Language'),
                settingsService.language,
                () {
                  _showOptionsDialog(
                    context,
                    context.tr('Language'),
                    [
                      'English',
                      'Hindi',
                      'Bengali',
                      'Marathi',
                      'Telugu',
                      'Tamil',
                      'Gujarati',
                      'Urdu',
                      'Bhojpuri',
                      'Kannada',
                      'Malayalam',
                      'Odia',
                      'Punjabi',
                      'Assamese',
                      'Maithili',
                    ],
                    settingsService.language,
                    (val) => settingsService.setLanguage(val),
                  );
                },
              ),
              _buildSimpleTile(
                context,
                Icons.light_mode_outlined,
                context.tr('App Theme'),
                settingsService.appThemeMode,
                () {
                  _showOptionsDialog(
                    context,
                    context.tr('App Theme'),
                    ['System', 'Light', 'Dark'],
                    settingsService.appThemeMode,
                    (val) => settingsService.setAppThemeMode(val),
                  );
                },
              ),

              _buildSectionHeader(theme, context.tr('CAMERA')),
              _buildSimpleTile(
                context,
                Icons.photo_outlined,
                context.tr('Photo Quality'),
                settingsService.photoQuality == PhotoQuality.high
                    ? 'High'
                    : 'Standard',
                () {
                  _showOptionsDialog(
                    context,
                    context.tr('Photo Quality'),
                    ['High', 'Standard'],
                    settingsService.photoQuality == PhotoQuality.high
                        ? 'High'
                        : 'Standard',
                    (val) {
                      settingsService.setPhotoQuality(
                        val == 'High'
                            ? PhotoQuality.high
                            : PhotoQuality.standard,
                      );
                    },
                  );
                },
              ),

              _buildSimpleTile(
                context,
                Icons.volume_up_outlined,
                context.tr('Volume Button Action'),
                settingsService.volumeButtonAction,
                () {
                  _showOptionsDialog(
                    context,
                    context.tr('Volume Button Action'),
                    ['Photo Capture', 'Zoom', 'System Volume'],
                    settingsService.volumeButtonAction,
                    (val) => settingsService.setVolumeButtonAction(val),
                  );
                },
              ),
              _buildSimpleTile(
                context,
                Icons.touch_app_outlined,
                context.tr('Screen Tap Action'),
                settingsService.screenTapAction,
                () {
                  _showOptionsDialog(
                    context,
                    context.tr('Screen Tap Action'),
                    ['Focus', 'Focus & Capture', 'None'],
                    settingsService.screenTapAction,
                    (val) => settingsService.setScreenTapAction(val),
                  );
                },
              ),

              _buildSectionHeader(theme, context.tr('STAMP')),
              _buildSimpleTile(
                context,
                Icons.crop_rotate,
                context.tr('Stamp Orientation'),
                'Automatic',
                () {},
                isNew: true,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.branding_watermark_outlined),
                title: Text(context.tr('Show App Logo')),
                subtitle: const Text('GPS Map Camera branding on stamp'),
                value: settingsService.showAppLogo,
                onChanged: settingsService.setShowAppLogo,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.camera_front_outlined),
                title: Text(context.tr('Show Camera Indicator')),
                subtitle: const Text('Front/rear camera icon on stamp'),
                value: settingsService.showCameraIndicator,
                onChanged: settingsService.setShowCameraIndicator,
              ),
              // Keep our core features
              _buildTemplateSelector(context, theme, settingsService),
              SwitchListTile(
                secondary: const Icon(Icons.add_location_alt_outlined),
                title: Text(context.tr('Plus Code')),
                subtitle: const Text('Include global Plus Code in stamp'),
                value: settingsService.plusCodeEnabled,
                onChanged: settingsService.setPlusCodeEnabled,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.access_time),
                title: Text(context.tr('Time Zone')),
                subtitle: const Text('Include local timezone in stamp'),
                value: settingsService.timeZoneEnabled,
                onChanged: settingsService.setTimeZoneEnabled,
              ),
              ListTile(
                leading: const Icon(Icons.note_alt_outlined),
                title: Text(context.tr('Note')),
                subtitle: Text(
                  settingsService.note ?? 'Add an optional note to your photos',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () => _editNote(context, settingsService),
              ),
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: Text(context.tr('Custom Fields')),
                subtitle: Text(
                  '${settingsService.customFields.length}/5 fields defined',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _editCustomFields(context, settingsService),
              ),

              _buildSectionHeader(theme, context.tr('STORAGE')),
              SwitchListTile(
                secondary: const Icon(Icons.save_alt),
                title: Text(context.tr('Auto Save Original Photos')),
                subtitle: const Text('Save two photos - stamped and original'),
                value: settingsService.saveOriginal,
                onChanged: settingsService.setSaveOriginal,
              ),
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: Text(context.tr('File Name Customization')),
                subtitle: const Text('Configure how captured photos are named'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.pushNamed(context, '/filename'),
              ),

              _buildSectionHeader(theme, context.tr('REPORT AFTER CAPTURE')),
              _buildSimpleTile(
                context,
                Icons.email_outlined,
                context.tr('Email Photo'),
                settingsService.emailPhoto,
                () {
                  _showOptionsDialog(
                    context,
                    context.tr('Email Photo'),
                    ['Off', 'Prompt', 'Auto-send'],
                    settingsService.emailPhoto,
                    (val) => settingsService.setEmailPhoto(val),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: Text(context.tr('Photo Report')),
                subtitle: const Text('Generate PDF from stamped photos'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.pushNamed(context, '/reports'),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.share_outlined),
                title: Text(context.tr('Share Photo')),
                subtitle: const Text('Open share options after each capture'),
                value: settingsService.sharePhotoToggle,
                onChanged: settingsService.setSharePhotoToggle,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.analytics_outlined),
                title: Text(context.tr('Reports')),
                subtitle: const Text('Show reports option on camera'),
                value: settingsService.showReportsToggle,
                onChanged: settingsService.setShowReportsToggle,
              ),

              _buildSectionHeader(theme, context.tr('HELP & SUPPORT')),
              ListTile(
                leading: const Icon(Icons.menu_book),
                title: Text(context.tr('How to Use')),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () =>
                    launchUrl(Uri.parse('https://example.com/how-to-use')),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: Text(context.tr('FAQ')),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => launchUrl(Uri.parse('https://example.com/faq')),
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: Text(context.tr('Video Tutorials')),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () =>
                    launchUrl(Uri.parse('https://example.com/tutorials')),
              ),

              _buildSectionHeader(theme, context.tr('ABOUT')),
              ListTile(
                leading: const Icon(Icons.apps),
                title: Text(context.tr('More Apps')),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => launchUrl(
                  Uri.parse(
                    'https://play.google.com/store/apps/developer?id=Example',
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.star_border),
                title: Text(context.tr('Rate App')),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => launchUrl(
                  Uri.parse('market://details?id=com.example.gps_map_camera'),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(context.tr('Share App')),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text:
                          'Check out GPS Map Camera! The best way to add location data to your photos. https://play.google.com/store/apps/details?id=com.example.gps_map_camera',
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(context.tr('Privacy Policy')),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () =>
                    launchUrl(Uri.parse('https://example.com/privacy')),
              ),
              ListTile(
                leading: const Icon(Icons.layers_outlined),
                title: Text(context.tr('App Version')),
                trailing: const Text(
                  '0.1.0',
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {},
              ),

              const SizedBox(height: 16),
              const BannerAdWidget(),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTemplateSelector(
    BuildContext context,
    ThemeData theme,
    SettingsService settingsService,
  ) {
    return ListTile(
      leading: const Icon(Icons.dashboard_customize_outlined),
      title: Text(context.tr('Template')),
      subtitle: Text(
        '${settingsService.selectedTemplate.name} ${context.tr("Template")}',
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => Navigator.pushNamed(context, '/templates'),
    );
  }

  Widget _buildSimpleTile(
    BuildContext context,
    IconData icon,
    String title,
    String trailingText,
    VoidCallback onTap, {
    bool isNew = false,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          if (isNew) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'New',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            trailingText,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showOptionsDialog(
    BuildContext context,
    String title,
    List<String> options,
    String currentValue,
    ValueChanged<String> onChanged,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: currentValue,
                onChanged: (val) {
                  if (val != null) {
                    onChanged(val);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _editNote(BuildContext context, SettingsService settings) {
    final controller = TextEditingController(text: settings.note);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Note'),
          content: TextField(
            controller: controller,
            maxLength: 200,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter an optional note...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                settings.setNote(controller.text);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _editCustomFields(BuildContext context, SettingsService settings) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _CustomFieldsScreen(settings: settings),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: 8.0,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CustomFieldsScreen extends StatefulWidget {
  final SettingsService settings;
  const _CustomFieldsScreen({required this.settings});

  @override
  State<_CustomFieldsScreen> createState() => _CustomFieldsScreenState();
}

class _CustomFieldsScreenState extends State<_CustomFieldsScreen> {
  late List<CustomField> _fields;

  @override
  void initState() {
    super.initState();
    _fields = List.of(widget.settings.customFields);
  }

  void _save() {
    widget.settings.setCustomFields(_fields);
    Navigator.pop(context);
  }

  void _addField() {
    if (_fields.length >= 5) return;
    setState(() {
      _fields.add(
        CustomField(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          label: 'New Field',
          value: '',
        ),
      );
    });
  }

  void _editField(int index) {
    final field = _fields[index];
    final labelCtrl = TextEditingController(text: field.label);
    final valueCtrl = TextEditingController(text: field.value);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Custom Field'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Label (e.g. Project)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueCtrl,
                decoration: const InputDecoration(labelText: 'Value'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _fields.removeAt(index));
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _fields[index] = field.copyWith(
                    label: labelCtrl.text.trim(),
                    value: valueCtrl.text.trim(),
                  );
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Fields'),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: _fields.isEmpty
          ? const Center(child: Text('No custom fields defined.'))
          : ListView.builder(
              itemCount: _fields.length,
              itemBuilder: (context, index) {
                final field = _fields[index];
                return ListTile(
                  title: Text(field.label),
                  subtitle: Text(field.value.isEmpty ? '(Empty)' : field.value),
                  trailing: Switch(
                    value: field.enabled,
                    onChanged: (val) {
                      setState(() {
                        _fields[index] = field.copyWith(enabled: val);
                      });
                    },
                  ),
                  onTap: () => _editField(index),
                );
              },
            ),
      floatingActionButton: _fields.length < 5
          ? FloatingActionButton(
              onPressed: _addField,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
