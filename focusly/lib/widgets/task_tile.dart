import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TaskTile extends StatefulWidget {
  final String taskId;
  final String initialText;
  final bool isCompleted;
  final Function(String) onChanged;
  final Function(bool) onCompletedChanged;
  final VoidCallback onDelete;

  const TaskTile({
    super.key,
    required this.taskId,
    required this.initialText,
    required this.isCompleted,
    required this.onChanged,
    required this.onCompletedChanged,
    required this.onDelete,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  late TextEditingController _controller;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _isCompleted = widget.isCompleted;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isCompleted ? Colors.green.shade300 : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: GestureDetector(
          onTap:
              _controller.text.isEmpty
                  ? null
                  : () {
                    setState(() => _isCompleted = !_isCompleted);
                    widget.onCompletedChanged(_isCompleted);
                  },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  _controller.text.isEmpty
                      ? Colors.grey.shade200
                      : (_isCompleted
                          ? Colors.green.shade400
                          : Colors.grey.shade200),
            ),
            child: Icon(
              _isCompleted ? Icons.check : Icons.circle_outlined,
              color:
                  _controller.text.isEmpty
                      ? Colors.grey.shade400
                      : (_isCompleted ? Colors.white : Colors.grey),
              size: 24,
            ),
          ),
        ),
        title: TextField(
          controller: _controller,
          onChanged: (v) => widget.onChanged(v),
          decoration: InputDecoration(
            hintText: l10n.todoAddTask,
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey.shade400),
          ),
          style: TextStyle(
            fontSize: 16,
            color: _isCompleted ? Colors.grey.shade400 : Colors.black,
          ),
        ),
        trailing: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder:
                  (BuildContext context) => AlertDialog(
                    title: Text(l10n.deleteTask),
                    content: Text(l10n.deleteConfirmation),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onDelete();
                        },
                        child: Text(
                          l10n.delete,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
            );
          },
          child: Icon(
            Icons.delete_outline,
            color: Colors.red.shade400,
            size: 20,
          ),
        ),
      ),
    );
  }
}
