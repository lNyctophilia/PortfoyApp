import 'package:flutter/material.dart';
import '../models/portfolio.dart';
import '../theme/app_theme.dart';

class AddEditPortfolioDialog extends StatefulWidget {
  final Portfolio? portfolio;
  final Function(String name, String description) onSave;
  final bool isBottomSheet;

  const AddEditPortfolioDialog({
    super.key,
    this.portfolio,
    required this.onSave,
    this.isBottomSheet = false,
  });

  @override
  State<AddEditPortfolioDialog> createState() => _AddEditPortfolioDialogState();
}

class _AddEditPortfolioDialogState extends State<AddEditPortfolioDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.portfolio?.name ?? '');
    _descController =
        TextEditingController(text: widget.portfolio?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSave(_nameController.text.trim(), _descController.text.trim());
      Navigator.of(context).pop();
    }
  }

  Widget _buildFormFields(BuildContext context, bool isEditing) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isEditing ? 'Portföyü Düzenle' : 'Yeni Portföy Oluştur',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () => Navigator.of(context).pop(),
              color: AppTheme.textMuted,
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Portföy İsmi *',
            hintText: 'Örn: Teknoloji & Büyüme Fonları',
            prefixIcon: Icon(Icons.folder_outlined),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Lütfen bir portföy ismi girin';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Açıklama (Opsiyonel)',
            hintText: 'Örn: BIST ve TEFAS teknoloji ağırlıklı yatırımlar',
            prefixIcon: Icon(Icons.notes_rounded),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: Icon(isEditing ? Icons.check_rounded : Icons.add_rounded),
              label: Text(isEditing ? 'Kaydet' : 'Portföyü Oluştur'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.portfolio != null;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    if (widget.isBottomSheet) {
      return Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.borderSubtle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  _buildFormFields(context, isEditing),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 12 : 16,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 18 : 24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: _buildFormFields(context, isEditing),
            ),
          ),
        ),
      ),
    );
  }
}
