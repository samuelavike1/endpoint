import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/request_provider.dart';

class AuthEditor extends StatefulWidget {
  final AuthConfig auth;
  final ValueChanged<AuthConfig> onChanged;

  const AuthEditor({
    super.key,
    required this.auth,
    required this.onChanged,
  });

  @override
  State<AuthEditor> createState() => _AuthEditorState();
}

class _AuthEditorState extends State<AuthEditor> {
  late TextEditingController _tokenController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _apiKeyNameController;
  late TextEditingController _apiKeyValueController;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.auth.token);
    _usernameController = TextEditingController(text: widget.auth.username);
    _passwordController = TextEditingController(text: widget.auth.password);
    _apiKeyNameController = TextEditingController(text: widget.auth.apiKeyName);
    _apiKeyValueController =
        TextEditingController(text: widget.auth.apiKeyValue);
  }

  @override
  void didUpdateWidget(AuthEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.auth.type != widget.auth.type) {
      _tokenController.text = widget.auth.token;
      _usernameController.text = widget.auth.username;
      _passwordController.text = widget.auth.password;
      _apiKeyNameController.text = widget.auth.apiKeyName;
      _apiKeyValueController.text = widget.auth.apiKeyValue;
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _apiKeyNameController.dispose();
    _apiKeyValueController.dispose();
    super.dispose();
  }

  void _updateAuth(AuthConfig Function(AuthConfig) updater) {
    widget.onChanged(updater(widget.auth));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auth Type Selector
          _buildTypeSelector(),
          const SizedBox(height: 16),

          // Auth Type specific fields
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _buildAuthFields(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: AuthType.values.map((type) {
          final isActive = widget.auth.type == type;
          final label = switch (type) {
            AuthType.none => 'None',
            AuthType.bearer => 'Bearer',
            AuthType.basic => 'Basic',
            AuthType.apiKey => 'API Key',
          };

          return Expanded(
            child: GestureDetector(
              onTap: () => _updateAuth((a) => a.copyWith(type: type)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppColors.primary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAuthFields() {
    switch (widget.auth.type) {
      case AuthType.none:
        return _buildNoAuth();
      case AuthType.bearer:
        return _buildBearerAuth();
      case AuthType.basic:
        return _buildBasicAuth();
      case AuthType.apiKey:
        return _buildApiKeyAuth();
    }
  }

  Widget _buildNoAuth() {
    return Container(
      key: const ValueKey('none'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.no_encryption_outlined,
              size: 32,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 8),
            Text(
              'No Authentication',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Request will be sent without auth headers',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textTertiary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBearerAuth() {
    return Container(
      key: const ValueKey('bearer'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Token'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _tokenController,
            hint: 'Enter bearer token...',
            onChanged: (v) => _updateAuth((a) => a.copyWith(token: v)),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _buildInfoChip(
            icon: Icons.info_outline_rounded,
            text: 'Adds "Authorization: Bearer <token>" header',
          ),
        ],
      ),
    );
  }

  Widget _buildBasicAuth() {
    return Container(
      key: const ValueKey('basic'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Username'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _usernameController,
            hint: 'Username',
            onChanged: (v) => _updateAuth((a) => a.copyWith(username: v)),
          ),
          const SizedBox(height: 12),
          _buildLabel('Password'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _passwordController,
            hint: 'Password',
            onChanged: (v) => _updateAuth((a) => a.copyWith(password: v)),
            obscure: true,
          ),
          const SizedBox(height: 12),
          _buildInfoChip(
            icon: Icons.info_outline_rounded,
            text: 'Adds "Authorization: Basic base64(user:pass)" header',
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyAuth() {
    return Container(
      key: const ValueKey('apikey'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Key Name'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _apiKeyNameController,
            hint: 'e.g. X-API-Key',
            onChanged: (v) => _updateAuth((a) => a.copyWith(apiKeyName: v)),
          ),
          const SizedBox(height: 12),
          _buildLabel('Key Value'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _apiKeyValueController,
            hint: 'Enter API key value...',
            onChanged: (v) =>
                _updateAuth((a) => a.copyWith(apiKeyValue: v)),
          ),
          const SizedBox(height: 12),
          _buildLabel('Add to'),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _buildToggleOption(
                  label: 'Header',
                  isActive: widget.auth.apiKeyInHeader,
                  onTap: () =>
                      _updateAuth((a) => a.copyWith(apiKeyInHeader: true)),
                ),
                _buildToggleOption(
                  label: 'Query Param',
                  isActive: !widget.auth.apiKeyInHeader,
                  onTap: () =>
                      _updateAuth((a) => a.copyWith(apiKeyInHeader: false)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      obscureText: obscure,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          color: AppColors.textTertiary.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
