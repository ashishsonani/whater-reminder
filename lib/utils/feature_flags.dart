/// Compile-time feature switches.
///
/// Premium/IAP is disabled for the initial release: IAPService is not wired
/// and App Review rejects visible-but-non-functional purchase UI. Flipping
/// this to true restores the Premium screen entries and drink locks once
/// IAPService and the App Store products exist.
const bool kPremiumEnabled = false;
