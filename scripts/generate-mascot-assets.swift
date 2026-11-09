import AppKit

let mascotSVG = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <!-- Background Gradient for App Icon -->
    <linearGradient id="bgGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#161B22"/>
      <stop offset="100%" stop-color="#090D12"/>
    </linearGradient>

    <!-- Helmet Metallic/Ceramic Shading -->
    <linearGradient id="helmetGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#FFFFFF"/>
      <stop offset="40%" stop-color="#F1F5F9"/>
      <stop offset="100%" stop-color="#CBD5E1"/>
    </linearGradient>

    <!-- Helmet Rim Highlight -->
    <linearGradient id="rimGrad" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#94A3B8"/>
      <stop offset="50%" stop-color="#E2E8F0"/>
      <stop offset="100%" stop-color="#94A3B8"/>
    </linearGradient>

    <!-- Visor Gradient -->
    <linearGradient id="visorGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#04080B"/>
      <stop offset="100%" stop-color="#0A1218"/>
    </linearGradient>

    <!-- Mint Eye Glow Gradient -->
    <radialGradient id="mintEyeGlow" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#A7F3D0" stop-opacity="1"/>
      <stop offset="45%" stop-color="#50F1CB" stop-opacity="0.95"/>
      <stop offset="80%" stop-color="#10B981" stop-opacity="0.8"/>
      <stop offset="100%" stop-color="#059669" stop-opacity="0.0"/>
    </radialGradient>

    <!-- Filter for Eye Outer Glow -->
    <filter id="eyeGlow" x="-30%" y="-30%" width="160%" height="160%">
      <feGaussianBlur stdDeviation="6" result="blur"/>
      <feComposite in="SourceGraphic" in2="blur" operator="over"/>
    </filter>
  </defs>

  <!-- Mascot Body (Peeking Robot) -->
  <g id="pipsey-robot">
    <!-- Back Head / Helmet Dome -->
    <path d="M 136 340 C 136 170, 200 110, 256 110 C 312 110, 376 170, 376 340 Z" fill="url(#helmetGrad)" filter="drop-shadow(0px 8px 16px rgba(0,0,0,0.4))"/>

    <!-- Ear/Side Pod Left -->
    <rect x="122" y="240" width="20" height="60" rx="10" fill="#94A3B8"/>
    <rect x="125" y="244" width="14" height="52" rx="7" fill="#E2E8F0"/>

    <!-- Ear/Side Pod Right -->
    <rect x="370" y="240" width="20" height="60" rx="10" fill="#94A3B8"/>
    <rect x="373" y="244" width="14" height="52" rx="7" fill="#E2E8F0"/>

    <!-- Visor Outer Well -->
    <path d="M 148 340 C 148 200, 200 160, 256 160 C 312 160, 364 200, 364 340 Z" fill="#020406"/>

    <!-- Visor Inner Glass -->
    <path d="M 154 340 C 154 208, 204 168, 256 168 C 308 168, 358 208, 358 340 Z" fill="url(#visorGrad)"/>

    <!-- Glass Reflection Arc -->
    <path d="M 175 240 C 200 195, 235 180, 275 180 C 240 186, 210 205, 190 245 Z" fill="#FFFFFF" opacity="0.12"/>

    <!-- Left Mint Eye with Glow -->
    <g filter="url(#eyeGlow)">
      <!-- Outer aura -->
      <ellipse cx="205" cy="272" rx="30" ry="22" fill="#50F1CB" opacity="0.35"/>
      <!-- Main Eye -->
      <ellipse cx="205" cy="272" rx="22" ry="16" fill="url(#mintEyeGlow)"/>
      <!-- Inner Bright Pupil Highlight -->
      <ellipse cx="205" cy="271" rx="12" ry="8" fill="#F0FDF4"/>
    </g>

    <!-- Right Mint Eye with Glow -->
    <g filter="url(#eyeGlow)">
      <!-- Outer aura -->
      <ellipse cx="307" cy="272" rx="30" ry="22" fill="#50F1CB" opacity="0.35"/>
      <!-- Main Eye -->
      <ellipse cx="307" cy="272" rx="22" ry="16" fill="url(#mintEyeGlow)"/>
      <!-- Inner Bright Pupil Highlight -->
      <ellipse cx="307" cy="271" rx="12" ry="8" fill="#F0FDF4"/>
    </g>

    <!-- Edge / Bezel Surface that Pipsey is Peeking Over -->
    <rect x="100" y="340" width="312" height="12" rx="4" fill="#1E293B"/>
    <rect x="100" y="340" width="312" height="3" fill="#475569"/>

    <!-- Left Little Hand -->
    <ellipse cx="185" cy="342" rx="22" ry="14" fill="#F8FAFC" filter="drop-shadow(0px 2px 4px rgba(0,0,0,0.3))"/>
    <ellipse cx="185" cy="341" rx="17" ry="10" fill="#E2E8F0"/>

    <!-- Right Little Hand -->
    <ellipse cx="327" cy="342" rx="22" ry="14" fill="#F8FAFC" filter="drop-shadow(0px 2px 4px rgba(0,0,0,0.3))"/>
    <ellipse cx="327" cy="341" rx="17" ry="10" fill="#E2E8F0"/>
  </g>
</svg>
"""

let appIconSVG = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <!-- Background Gradient for App Icon Squircle -->
    <linearGradient id="iconBg" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#1E2631"/>
      <stop offset="50%" stop-color="#11161D"/>
      <stop offset="100%" stop-color="#080B0F"/>
    </linearGradient>

    <!-- Outer Border Glow -->
    <linearGradient id="iconBorder" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#38BDF8" stop-opacity="0.3"/>
      <stop offset="50%" stop-color="#50F1CB" stop-opacity="0.2"/>
      <stop offset="100%" stop-color="#0F172A" stop-opacity="0.5"/>
    </linearGradient>

    <!-- Helmet Metallic/Ceramic Shading -->
    <linearGradient id="helmetGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#FFFFFF"/>
      <stop offset="40%" stop-color="#F1F5F9"/>
      <stop offset="100%" stop-color="#CBD5E1"/>
    </linearGradient>

    <linearGradient id="visorGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#030608"/>
      <stop offset="100%" stop-color="#091117"/>
    </linearGradient>

    <radialGradient id="mintEyeGlow" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#A7F3D0" stop-opacity="1"/>
      <stop offset="45%" stop-color="#50F1CB" stop-opacity="0.95"/>
      <stop offset="80%" stop-color="#10B981" stop-opacity="0.8"/>
      <stop offset="100%" stop-color="#059669" stop-opacity="0.0"/>
    </radialGradient>

    <filter id="eyeGlow" x="-30%" y="-30%" width="160%" height="160%">
      <feGaussianBlur stdDeviation="8" result="blur"/>
      <feComposite in="SourceGraphic" in2="blur" operator="over"/>
    </filter>

    <clipPath id="squircleClip">
      <rect x="32" y="32" width="448" height="448" rx="100" ry="100"/>
    </clipPath>
  </defs>

  <!-- macOS Squircle Canvas -->
  <g clip-path="url(#squircleClip)">
    <!-- Obsidian Background -->
    <rect x="32" y="32" width="448" height="448" fill="url(#iconBg)"/>

    <!-- Subtle Radial Background Glow behind Mascot -->
    <circle cx="256" cy="300" r="180" fill="#50F1CB" opacity="0.08"/>

    <!-- Mascot Robot (Scaled & Centered within Icon) -->
    <g transform="translate(0, 50)">
      <!-- Back Head / Helmet Dome -->
      <path d="M 126 360 C 126 160, 196 95, 256 95 C 316 95, 386 160, 386 360 Z" fill="url(#helmetGrad)" filter="drop-shadow(0px 10px 24px rgba(0,0,0,0.6))"/>

      <!-- Ear Pods -->
      <rect x="110" y="240" width="22" height="66" rx="11" fill="#94A3B8"/>
      <rect x="113" y="244" width="16" height="58" rx="8" fill="#E2E8F0"/>
      <rect x="380" y="240" width="22" height="66" rx="11" fill="#94A3B8"/>
      <rect x="383" y="244" width="16" height="58" rx="8" fill="#E2E8F0"/>

      <!-- Visor Well -->
      <path d="M 140 360 C 140 196, 196 150, 256 150 C 316 150, 372 196, 372 360 Z" fill="#010304"/>
      <!-- Visor Glass -->
      <path d="M 146 360 C 146 204, 200 158, 256 158 C 312 158, 366 204, 366 360 Z" fill="url(#visorGrad)"/>

      <!-- Glass Sheen -->
      <path d="M 165 240 C 195 190, 235 174, 280 174 C 240 180, 205 202, 185 245 Z" fill="#FFFFFF" opacity="0.14"/>

      <!-- Left Mint Eye -->
      <g filter="url(#eyeGlow)">
        <ellipse cx="202" cy="275" rx="32" ry="23" fill="#50F1CB" opacity="0.4"/>
        <ellipse cx="202" cy="275" rx="23" ry="16" fill="url(#mintEyeGlow)"/>
        <ellipse cx="202" cy="274" rx="12" ry="8" fill="#F0FDF4"/>
      </g>

      <!-- Right Mint Eye -->
      <g filter="url(#eyeGlow)">
        <ellipse cx="310" cy="275" rx="32" ry="23" fill="#50F1CB" opacity="0.4"/>
        <ellipse cx="310" cy="275" rx="23" ry="16" fill="url(#mintEyeGlow)"/>
        <ellipse cx="310" cy="274" rx="12" ry="8" fill="#F0FDF4"/>
      </g>

      <!-- Bezel Bar -->
      <rect x="80" y="360" width="352" height="18" rx="6" fill="#1E293B"/>
      <rect x="80" y="360" width="352" height="3" fill="#64748B"/>

      <!-- Hands Gripping Bezel -->
      <ellipse cx="180" cy="362" rx="24" ry="15" fill="#F8FAFC" filter="drop-shadow(0px 3px 6px rgba(0,0,0,0.4))"/>
      <ellipse cx="180" cy="361" rx="18" ry="10" fill="#E2E8F0"/>
      <ellipse cx="332" cy="362" rx="24" ry="15" fill="#F8FAFC" filter="drop-shadow(0px 3px 6px rgba(0,0,0,0.4))"/>
      <ellipse cx="332" cy="361" rx="18" ry="10" fill="#E2E8F0"/>
    </g>

    <!-- Subtle Inner Border -->
    <rect x="33" y="33" width="446" height="446" rx="99" ry="99" fill="none" stroke="url(#iconBorder)" stroke-width="2"/>
  </g>
</svg>
"""

let templateMenuSVG = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 22 22" width="22" height="22">
  <!-- Monochrome Template Mascot for macOS Menu Bar -->
  <!-- Helmet Dome -->
  <path d="M 4 16 C 4 7, 7 4, 11 4 C 15 4, 18 7, 18 16 Z" fill="black"/>
  <!-- Visor Cutout -->
  <path d="M 5.5 16 C 5.5 9, 8 6.5, 11 6.5 C 14 6.5, 16.5 9, 16.5 16 Z" fill="white"/>
  <!-- Eyes -->
  <ellipse cx="8.5" cy="11.5" rx="1.8" ry="1.3" fill="black"/>
  <ellipse cx="13.5" cy="11.5" rx="1.8" ry="1.3" fill="black"/>
  <!-- Hands -->
  <ellipse cx="7.5" cy="16" rx="1.5" ry="1" fill="black"/>
  <ellipse cx="14.5" cy="16" rx="1.5" ry="1" fill="black"/>
</svg>
"""

func renderSVGToPNG(svgString: String, width: Int, height: Int, destinationURL: URL) {
    guard let svgData = svgString.data(using: .utf8),
          let image = NSImage(data: svgData) else {
        print("Failed to load SVG data")
        return
    }

    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: width, height: height)

    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current = context

    image.draw(
        in: NSRect(x: 0, y: 0, width: width, height: height),
        from: NSRect(origin: .zero, size: image.size),
        operation: .copy,
        fraction: 1.0
    )

    NSGraphicsContext.restoreGraphicsState()

    if let pngData = rep.representation(using: .png, properties: [:]) {
        try? pngData.write(to: destinationURL)
        print("Exported \(destinationURL.lastPathComponent): \(width)x\(height)")
    }
}

// 1. Save SVG files
let assetsDir = URL(fileURLWithPath: "Assets")
try? FileManager.default.createDirectory(at: assetsDir, withIntermediateDirectories: true)

try? mascotSVG.write(to: assetsDir.appendingPathComponent("pipsey-mascot.svg"), atomically: true, encoding: .utf8)
try? appIconSVG.write(to: assetsDir.appendingPathComponent("pipsey-app-icon.svg"), atomically: true, encoding: .utf8)
try? templateMenuSVG.write(to: assetsDir.appendingPathComponent("pipsey-menubar-template.svg"), atomically: true, encoding: .utf8)

// 2. Export Mascot PNGs
renderSVGToPNG(svgString: mascotSVG, width: 512, height: 512, destinationURL: assetsDir.appendingPathComponent("pipsey-mascot-512.png"))
renderSVGToPNG(svgString: mascotSVG, width: 256, height: 256, destinationURL: assetsDir.appendingPathComponent("pipsey-mascot-256.png"))
renderSVGToPNG(svgString: mascotSVG, width: 128, height: 128, destinationURL: assetsDir.appendingPathComponent("pipsey-mascot-128.png"))
renderSVGToPNG(svgString: mascotSVG, width: 64, height: 64, destinationURL: assetsDir.appendingPathComponent("pipsey-mascot-64.png"))
renderSVGToPNG(svgString: mascotSVG, width: 32, height: 32, destinationURL: assetsDir.appendingPathComponent("pipsey-mascot-32.png"))

// 3. Export Menu Bar Template Icon
renderSVGToPNG(svgString: templateMenuSVG, width: 22, height: 22, destinationURL: assetsDir.appendingPathComponent("pipsey-menubar-template@1x.png"))
renderSVGToPNG(svgString: templateMenuSVG, width: 44, height: 44, destinationURL: assetsDir.appendingPathComponent("pipsey-menubar-template@2x.png"))

// 4. Create AppIcon.iconset for iconutil
let iconsetDir = URL(fileURLWithPath: "/tmp/AppIcon.iconset")
try? FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, px) in sizes {
    renderSVGToPNG(svgString: appIconSVG, width: px, height: px, destinationURL: iconsetDir.appendingPathComponent(name))
}

print("✅ Generated all mascot assets and iconset successfully")
