enum ReturnCalculationMode {
  brut,
  net,
  reel,
}

extension ReturnCalculationModeExtension on ReturnCalculationMode {
  String get label {
    switch (this) {
      case ReturnCalculationMode.brut:
        return 'Brüt';
      case ReturnCalculationMode.net:
        return 'Net';
      case ReturnCalculationMode.reel:
        return 'Reel';
    }
  }

  String get badgeText {
    switch (this) {
      case ReturnCalculationMode.brut:
        return 'BRÜT';
      case ReturnCalculationMode.net:
        return 'NET';
      case ReturnCalculationMode.reel:
        return 'REEL';
    }
  }

  String get title {
    switch (this) {
      case ReturnCalculationMode.brut:
        return 'Brüt Getiri';
      case ReturnCalculationMode.net:
        return 'Net Getiri';
      case ReturnCalculationMode.reel:
        return 'Reel Getiri (TÜFE)';
    }
  }

  String get shortDescription {
    switch (this) {
      case ReturnCalculationMode.brut:
        return 'Stopaj vergisi ve enflasyon kesintisi olmaksızın tam kârı gösterir.';
      case ReturnCalculationMode.net:
        return 'Fon kârlarından yasal stopaj vergisi düşülmüş net tutarları gösterir.';
      case ReturnCalculationMode.reel:
        return 'Enflasyona (TÜFE) göre net getiri oranını (%) gösterir.';
    }
  }

  String get detailedDescription {
    switch (this) {
      case ReturnCalculationMode.brut:
        return 'Tüm varlıklar için stopaj vergisi veya enflasyon düşülmeksizin ham kâr ve getiri oranlarını listeler.';
      case ReturnCalculationMode.net:
        return 'Yatırım fonu kazançlarından yasal stopaj vergisi (%0 - %17,5) düşülerek net kazançları listeler.';
      case ReturnCalculationMode.reel:
        return 'İnternet üzerinden TCMB / TÜİK resmi TÜFE enflasyon verisini çeker; bakiye ve kâr tutarınızı eksiltmeksizin enflasyon karşısındaki reel getiri yüzdenizi (%) sunar.';
    }
  }
}

