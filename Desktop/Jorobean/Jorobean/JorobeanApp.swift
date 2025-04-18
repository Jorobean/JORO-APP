import SwiftUI
import RealityKit

@main
struct JorobeanApp: SwiftUI.App {
    var body: some SwiftUI.Scene {
        WindowGroup {
            MainView()
        }
    }
}

struct MainView: View {
    @State private var selectedColor: Color = Color(hex: "#555555")
    private let colors: [(name: String, color: Color)] = [
        ("grey", Color(hex: "#555555")),
        ("black", Color(hex: "#151515")),
        ("coffee", Color(hex: "#a97451")), // lighter brown
        ("green", Color(hex: "#14341b")),
        ("blue", Color(hex: "#0066ff")),
        ("orange", Color(hex: "#ff4d00")),
        ("red", Color(hex: "#8a1010")),
        ("white", Color(hex: "#ffffff")) // Added white color option
    ]
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var showSubmitted: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var isDarkMode: Bool = false
    @State private var showInfoSheet: Bool = false

    var body: some View {
        ZStack {
            (isDarkMode ? Color.black : Color.white).ignoresSafeArea()
            VStack(spacing: 0) {
                // Top bar with logo (fixed)
                HStack(alignment: .center) {
                    Image("logo-heart")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .padding(.leading, 16)
                        .padding(.top, 8)
                    Spacer()
                }
                .frame(height: 60)
                // Scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Main content
                        Model3DView(modelColor: selectedColor, isDarkMode: isDarkMode)
                            .frame(maxWidth: .infinity, minHeight: 440, maxHeight: 540)
                            .padding(.horizontal, 0)
                            .padding(.bottom, 32)
                        // Padding above color picker
                        Spacer().frame(height: 20)
                        HStack(spacing: 12) { 
                            ForEach(colors, id: \.color) { colorTuple in
                                Circle()
                                    .fill(colorTuple.color)
                                    .frame(width: 28, height: 28) 
                                    .overlay(
                                        Circle().stroke((isDarkMode ? Color.white : Color.black).opacity(selectedColor == colorTuple.color ? 0.8 : 0.3), lineWidth: selectedColor == colorTuple.color ? 3 : 1)
                                    )
                                    .shadow(radius: selectedColor == colorTuple.color ? 3 : 0)
                                    .onTapGesture { selectedColor = colorTuple.color }
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill((isDarkMode ? Color(.systemGray5) : Color(.systemGray6)).opacity(0.95))
                                .shadow(color: (isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.14)), radius: 10, x: 0, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke((isDarkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.12)), lineWidth: 1)
                        )
                        Spacer(minLength: 12)
                        FeaturesSection(isDarkMode: isDarkMode)
                        PreOrderPanel(fullName: $fullName, email: $email, showSubmitted: $showSubmitted, isDarkMode: isDarkMode)
                            .padding(.top, 8)
                        Spacer(minLength: 12)
                        // Bottom controls and footer
                        VStack(spacing: 8) {
                            HStack(spacing: 18) {
                                Button(action: { isDarkMode.toggle() }) {
                                    Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(isDarkMode ? .white : .black)
                                }
                                Button(action: {
                                    if let url = URL(string: "https://instagram.com/jorobean") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Image("black-instagram-icon")
                                        .renderingMode(.template)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 28, height: 28)
                                        .foregroundColor(isDarkMode ? .white : .black)
                                }
                                Button(action: { showInfoSheet = true }) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(isDarkMode ? .white : .black)
                                }
                            }
                            Text("JOROBEAN 2025")
                                .font(.footnote)
                                .foregroundColor(isDarkMode ? .gray.opacity(0.8) : .gray)
                                .padding(.top, 2)
                        }
                        .padding(.bottom, 8)
                    }
                    .frame(maxWidth: .infinity)
                }
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .sheet(isPresented: $showInfoSheet) {
            InfoSheetView()
                .presentationDetents([.fraction(0.35)])
        }
        .contentShape(Rectangle())
    }
}

struct PreOrderPanel: View {
    @Binding var fullName: String
    @Binding var email: String
    @Binding var showSubmitted: Bool
    var isDarkMode: Bool
    var body: some View {
        VStack(spacing: 20) {
            Text("Pre-Order Now")
                .font(.system(size: 28, weight: .bold))
                .padding(.top, 20)
                .foregroundColor(isDarkMode ? .white : .black)
            Text("Be among the first to experience JOROBEAN #1.")
                .font(.system(size: 16))
                .foregroundColor(isDarkMode ? .gray.opacity(0.8) : .gray)
            VStack(spacing: 16) {
                TextField("Your full name", text: $fullName)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isDarkMode ? Color.white.opacity(0.12) : Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isDarkMode ? Color.white : Color.black, lineWidth: 2)
                            )
                    )
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isDarkMode ? .white : .black)
                TextField("Your email", text: $email)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isDarkMode ? Color.white.opacity(0.12) : Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isDarkMode ? Color.white : Color.black, lineWidth: 2)
                            )
                    )
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isDarkMode ? .white : .black)
                    .keyboardType(.emailAddress)
            }
            Button(action: {
                showSubmitted = true
            }) {
                HStack {
                    Spacer()
                    Text("Submit Pre-Order")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                .background(Color.black)
                .cornerRadius(10)
            }
            .frame(maxWidth: 340)
            .padding(.top, 4)
            if showSubmitted {
                Text("Thank you for your pre-order!")
                    .foregroundColor(.green)
                    .font(.system(size: 16, weight: .medium))
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(32)
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke((isDarkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.12)), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
}

struct InfoSheetView: View {
    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.gray.opacity(0.3))
                .padding(.top, 8)
            Text("About Jorobean")
                .font(.title3).bold()
                .padding(.top, 8)
            Text("Jorobean is a next-generation footwear company redefining comfort, style, and innovation. Our mission is to create shoes that blend advanced technology with timeless design, delivering an unmatched experience for every step. Be among the first to join the movement!")
                .multilineTextAlignment(.center)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct Model3DView: UIViewRepresentable {
    var modelColor: Color
    var isDarkMode: Bool = false

    class Coordinator: NSObject {
        var entity: Entity?
        var lastLocation: CGPoint?
        var currentColor: UIColor = .gray
        var lastRotation: simd_quatf = simd_quatf(angle: 0, axis: [0,1,0])
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        if isDarkMode {
            arView.environment.background = .color(UIColor(red: 0.094, green: 0.078, blue: 0.078, alpha: 1.0)) // #181414
        } else {
            arView.environment.background = .color(UIColor(red: 0.898, green: 0.898, blue: 0.898, alpha: 1.0)) // #e5e5e5
        }
        if let modelURL = Bundle.main.url(forResource: "joroshoe", withExtension: "usdc") {
            let modelEntity = try? ModelEntity.loadModel(contentsOf: modelURL)
            if let entity = modelEntity {
                let uiColor = UIColor(modelColor)
                setAllMaterialsColor(entity: entity, color: uiColor)
                let bounds = entity.visualBounds(relativeTo: nil)
                let center = bounds.center
                let extent = bounds.extents
                entity.position = SIMD3<Float>(-center.x, -center.y + max(extent.y, extent.z, extent.x) * 0.15, -center.z - max(extent.x, extent.y, extent.z) * 0.22)
                entity.setScale(SIMD3<Float>(repeating: 0.22), relativeTo: nil)
                entity.generateCollisionShapes(recursive: true)
                let anchor = AnchorEntity(world: .zero)
                anchor.addChild(entity)
                arView.scene.anchors.append(anchor)
                context.coordinator.entity = entity
                context.coordinator.currentColor = uiColor
                context.coordinator.lastRotation = entity.transform.rotation
                
                // Combine tilting forward and rotating to the left (Y axis)
                // First tilt forward (X axis), then rotate left (Y axis)
                let tilt = simd_quatf(angle: -.pi/4, axis: SIMD3<Float>(1, 0, 0)) // -45° forward
                let turn = simd_quatf(angle: .pi/3, axis: SIMD3<Float>(0, 1, 0)) // 60° left
                entity.orientation = simd_mul(turn, tilt)
            }
        }
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        arView.addGestureRecognizer(pan)
        return arView
    }
    func updateUIView(_ uiView: ARView, context: Context) {
        let uiColor = UIColor(modelColor)
        if context.coordinator.currentColor != uiColor, let entity = context.coordinator.entity {
            setAllMaterialsColor(entity: entity, color: uiColor)
            context.coordinator.currentColor = uiColor
        }
        // Update background color if dark mode changes
        if isDarkMode {
            uiView.environment.background = .color(UIColor(red: 0.094, green: 0.078, blue: 0.078, alpha: 1.0)) // #181414
        } else {
            uiView.environment.background = .color(UIColor(red: 0.898, green: 0.898, blue: 0.898, alpha: 1.0)) // #e5e5e5
        }
    }
    private func setAllMaterialsColor(entity: Entity, color: UIColor) {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: color)
        material.roughness = 0.75 // slightly less matte, more realistic
        material.metallic = 0.0   // non-metallic
        // No normal map, but this gives a rough, 3D-printed feel
        if let modelEntity = entity as? ModelEntity {
            modelEntity.model?.materials = [material]
        }
        for child in entity.children {
            setAllMaterialsColor(entity: child, color: color)
        }
    }
}

extension Model3DView.Coordinator {
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let entity = entity else { return }
        let translation = gesture.translation(in: gesture.view)
        let dx = Float(translation.x - (lastLocation?.x ?? 0))
        let dy = Float(translation.y - (lastLocation?.y ?? 0))
        let rotY = simd_quatf(angle: dx * 0.01, axis: [0,1,0])
        let rotX = simd_quatf(angle: dy * 0.01, axis: [1,0,0]) // now direct, not inverted
        entity.transform.rotation = rotY * rotX * entity.transform.rotation
        lastLocation = translation
        if gesture.state == .ended || gesture.state == .cancelled {
            lastLocation = nil
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct FeaturesSection: View {
    var isDarkMode: Bool
    // Match PreOrderPanel horizontal padding
    private let horizontalPadding: CGFloat = 16
    private let boxWidth: CGFloat = UIScreen.main.bounds.width - 2 * 16 - 8 // 16 padding on each side, 8 for grid spacing
    private let minBoxHeight: CGFloat = 200 // Ensures all boxes are same height
    var body: some View {
        VStack(spacing: 24) {
            Text("Features")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(isDarkMode ? .white : .black)
                .padding(.bottom, 8)
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                FeatureItem(
                    icon: "cube.box.fill",
                    title: "100% 3D-Printed",
                    description: "Cutting-edge technology creates a shoe that's uniquely yours.",
                    isDarkMode: isDarkMode,
                    minHeight: minBoxHeight,
                    maxWidth: (boxWidth / 2) - 8 // 2 columns, grid spacing
                )
                FeatureItem(
                    icon: "hands.sparkles.fill",
                    title: "No Glue. No Stitching.",
                    description: "One seamless piece for unmatched durability and comfort.",
                    isDarkMode: isDarkMode,
                    minHeight: minBoxHeight,
                    maxWidth: (boxWidth / 2) - 8
                )
                FeatureItem(
                    icon: "printer.fill",
                    title: "Printed On Demand",
                    description: "Zero waste. Made specifically for you when you order.",
                    isDarkMode: isDarkMode,
                    minHeight: minBoxHeight,
                    maxWidth: (boxWidth / 2) - 8
                )
                FeatureItem(
                    icon: "wind",
                    title: "Lightweight & Flexible",
                    description: "Designed for all-day comfort and effortless movement.",
                    isDarkMode: isDarkMode,
                    minHeight: minBoxHeight,
                    maxWidth: (boxWidth / 2) - 8
                )
            }
            .padding(.horizontal, horizontalPadding)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 0)
    }
}

struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String
    var isDarkMode: Bool
    var minHeight: CGFloat = 200
    var maxWidth: CGFloat = 160
    var body: some View {
        VStack(spacing: 0) {
            // Reduce icon size
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(isDarkMode ? .white : .black)
                .padding(.top, 24)
            // Vertically align titles using fixed height
            ZStack(alignment: .top) {
                Color.clear.frame(height: 30) // Placeholder for alignment
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(isDarkMode ? .white : .black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(height: 30, alignment: .center)
            }
            Text(description)
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundColor(isDarkMode ? .gray.opacity(0.8) : .gray)
                .padding(.top, 6)
            Spacer()
        }
        .frame(minWidth: 0, maxWidth: maxWidth, minHeight: minHeight)
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(32)
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke((isDarkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.12)), lineWidth: 1)
        )
        .padding(4)
    }
}
