import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Emtia (Kıymetli Madenler) için Altın Külçeleri Vektör Logosu / İkonu
class EmtiaVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const EmtiaVectorIcon({
    super.key,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFFF59E0B);

    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(
        '''<svg width="$size" height="$size" viewBox="1.783 1.5 14.0 14.0" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Piramit Diziliminde 3 Altın Külçesi / Gold Bullion Bars - Ortalı ve Standart Boyut -->
  <path d="M7.656 5h2.687c.09 0 .17.04.217.107L12.06 7.68c.096.143-.024.32-.216.32H5.715c-.193 0-.313-.177-.217-.32L7.06 5.107A.26.26 0 017.656 5z" fill="currentColor"/>
  <path d="M4.156 9h2.687c.09 0 .17.04.217.107L8.56 11.68c.096.143-.024.32-.217.32H2.215c-.193 0-.313-.177-.217-.32L3.94 9.107A.26.26 0 014.156 9z" fill="currentColor"/>
  <path d="M11.156 9h2.687c.09 0 .17.04.217.107L15.56 11.68c.096.143-.024.32-.216.32H9.215c-.193 0-.313-.177-.217-.32L10.94 9.107A.26.26 0 0111.156 9z" fill="currentColor"/>
</svg>''',
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
      ),
    );
  }
}
