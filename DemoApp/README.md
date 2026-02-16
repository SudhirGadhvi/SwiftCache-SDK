# SwiftCache Demo App

Example iOS app demonstrating SwiftCache features.

## 🚀 How to Run

### Method 1: Using Xcode

1. **Create a new iOS App project** in Xcode
2. **Add SwiftCache package:**
   - File → Add Package Dependencies...
   - Enter: `https://github.com/SudhirGadhvi/SwiftCache-SDK`
   - Select version and add
3. **Copy the demo files:**
   - Use `SwiftCacheDemoApp.swift` as your App file
   - Use `ContentView.swift` as your main view
4. **Enable network access** in Info.plist:
   - Add `App Transport Security Settings` dictionary
   - Add child: `Allow Arbitrary Loads` = YES
5. **Run on device or simulator**

### Method 2: Quick Test

Just copy the code from `ContentView.swift` into a new SwiftUI project and import SwiftCache!

## ✨ Features Demonstrated

- **Image Loading**: Grid of images from the internet
- **Memory Cache**: Instant loading when scrolling
- **Disk Cache**: Fast loading when reopening app
- **Statistics**: View cache performance metrics
  - Memory hits, disk hits, network hits
  - Hit rate percentage
  - Average load time
  - Cache sizes
- **Cache Management**: Clear cache button
- **Progressive Loading**: Smooth image loading experience
- **Adaptive Policy (Optional)**: Configure telemetry-driven cache tuning for real apps

## 🧪 Testing the Cache

1. **First run:** Images download from network (slower)
2. **Scroll around:** Images load from memory cache (instant)
3. **Close and reopen app:** Images load from disk cache (fast)
4. **Tap "Clear" and reload:** Images download from network again

## 📈 Understanding Adaptive Metrics

When **Adaptive Policy** is enabled in the demo:

- **Adaptive Window** = recent telemetry window used for policy decisions.
- **Window Requests** = requests collected in the current window.
- **Window Hit Rate** = successful loads across memory + disk + network.
- **Window Cache Hit** = local cache-only hit rate (memory + disk), the key cache efficiency signal.
- **Window Miss Rate** = failed requests.
- **Evaluate Adaptive Policy Now** = trigger immediate policy evaluation using current telemetry.

Tip for first-run behavior: it is normal to see high overall hit rate with low cache hit rate, because successful network loads count in overall hit rate while cache is still cold.

## 📝 Files Included

- **`SwiftCacheDemoApp.swift`** - App entry point
- **`ContentView.swift`** - Main UI with image grid and stats
- **`Info.plist`** - Pre-configured network permissions

## 💡 Tips

- Make sure your device/simulator has internet access
- The demo uses picsum.photos for random test images
- Tap "Stats" to see detailed performance metrics
- Use "Clear" to test cache behavior from scratch
- Use "Evaluate Adaptive Policy Now" after enough requests to test adaptive decisions quickly

---

**Tip:** For app-specific performance tuning, enable adaptive policy in your app-level `SwiftCache.shared.configure { ... }`.
