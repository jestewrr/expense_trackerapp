import 'package:flutter/material.dart';

class ResponsiveDialog {
  static Widget createDialog({
    required BuildContext context,
    required Widget child,
    double? maxHeight,
    double? maxWidth,
    EdgeInsets? insetPadding,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;
    final isVerySmallScreen = screenSize.height < 500;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: insetPadding ?? EdgeInsets.symmetric(
        horizontal: isVerySmallScreen ? 10 : 16,
        vertical: isVerySmallScreen ? 20 : 30,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight ?? (isVerySmallScreen ? screenSize.height * 0.8 : screenSize.height * 0.6),
          maxWidth: maxWidth ?? (isVerySmallScreen ? screenSize.width * 0.95 : screenSize.width * 0.9),
          minHeight: isVerySmallScreen ? 200 : 250,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: isSmallScreen ? 15 : 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  static Widget createScrollableDialog({
    required BuildContext context,
    required Widget child,
    double? maxHeight,
    double? maxWidth,
    EdgeInsets? insetPadding,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;
    final isVerySmallScreen = screenSize.height < 500;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: insetPadding ?? EdgeInsets.symmetric(
        horizontal: isVerySmallScreen ? 10 : 16,
        vertical: isVerySmallScreen ? 20 : 30,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight ?? (isVerySmallScreen ? screenSize.height * 0.8 : screenSize.height * 0.6),
          maxWidth: maxWidth ?? (isVerySmallScreen ? screenSize.width * 0.95 : screenSize.width * 0.9),
          minHeight: isVerySmallScreen ? 200 : 250,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: isSmallScreen ? 15 : 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: child,
          ),
        ),
      ),
    );
  }

  static Widget createConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
    IconData? icon,
    Color? iconColor,
    Color? confirmColor,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;
    final isVerySmallScreen = screenSize.height < 500;
    
    return createDialog(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              color: (iconColor ?? Colors.blue).withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isSmallScreen ? 12 : 16),
                topRight: Radius.circular(isSmallScreen ? 12 : 16),
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                    decoration: BoxDecoration(
                      color: (iconColor ?? Colors.blue).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor ?? Colors.blue,
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 16),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Text(
              message,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.black87,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Buttons
          Container(
            padding: EdgeInsets.fromLTRB(
              isSmallScreen ? 16 : 20,
              0,
              isSmallScreen ? 16 : 20,
              isSmallScreen ? 16 : 20,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 12 : 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                      ),
                    ),
                    child: Text(
                      cancelText,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor ?? Colors.red,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 12 : 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
