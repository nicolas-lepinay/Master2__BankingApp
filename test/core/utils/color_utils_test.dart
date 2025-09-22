import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bankapp/core/utils/color_utils.dart';

void main() {
  group('ColorUtils', () {
    group('fromHex', () {
      test('should convert valid HEX with # to Color', () {
        final color = ColorUtils.fromHex('#FF5733');
        
        expect(color, isNotNull);
        expect(color!.red, 255);
        expect(color.green, 87);
        expect(color.blue, 51);
        expect(color.alpha, 255); // Default opaque
      });

      test('should convert valid HEX without # to Color', () {
        final color = ColorUtils.fromHex('FF5733');
        
        expect(color, isNotNull);
        expect(color!.red, 255);
        expect(color.green, 87);
        expect(color.blue, 51);
      });

      test('should convert HEX with alpha to Color', () {
        final color = ColorUtils.fromHex('#80FF5733');
        
        expect(color, isNotNull);
        expect(color!.alpha, 128); // 0x80 = 128
        expect(color.red, 255);
        expect(color.green, 87);
        expect(color.blue, 51);
      });

      test('should return null for invalid HEX', () {
        expect(ColorUtils.fromHex('invalid'), isNull);
        expect(ColorUtils.fromHex('#GGGGGG'), isNull);
        expect(ColorUtils.fromHex(''), isNull);
        expect(ColorUtils.fromHex(null), isNull);
      });
    });

    group('toHex', () {
      test('should convert Color to HEX with alpha', () {
        const color = Color(0xFF5733FF);
        final hex = ColorUtils.toHex(color);
        
        expect(hex, '#FF5733FF');
      });

      test('should convert Color to HEX RGB without alpha', () {
        const color = Color(0xFF5733FF);
        final hex = ColorUtils.toHexRGB(color);
        
        expect(hex, '#5733FF');
      });
    });

    group('smartParse', () {
      test('should parse predefined colors', () {
        final color = ColorUtils.smartParse('primary');
        
        expect(color, Colors.blue);
      });

      test('should parse HEX colors', () {
        final color = ColorUtils.smartParse('#FF5733');
        
        expect(color, isNotNull);
        expect(color!.red, 255);
        expect(color.green, 87);
        expect(color.blue, 51);
      });

      test('should return null for invalid input', () {
        expect(ColorUtils.smartParse('unknown'), isNull);
        expect(ColorUtils.smartParse(''), isNull);
        expect(ColorUtils.smartParse(null), isNull);
      });
    });

    group('roundtrip conversion', () {
      test('should maintain color integrity through conversion', () {
        const originalColor = Color(0xFF5733AA);
        
        // Color -> HEX -> Color
        final hex = ColorUtils.toHex(originalColor);
        final convertedColor = ColorUtils.fromHex(hex);
        
        expect(convertedColor, originalColor);
      });
    });
  });
}