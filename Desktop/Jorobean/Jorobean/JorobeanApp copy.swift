import SwiftUI
import RealityKit
import CloudKit
import UserNotifications

@main
struct JorobeanApp: SwiftUI.App {
    // CloudKit push notification setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some SwiftUI.Scene {
        WindowGroup {
            MainView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Request notification permissions
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        // Register CloudKit subscription using the correct container
        let container = CKContainer(identifier: "iCloud.com.jorobean.app")
        let db = container.publicCloudDatabase
        let subscriptionID = "jorobean-changes"
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(recordType: "PreOrder", predicate: predicate, subscriptionID: subscriptionID, options: [.firesOnRecordCreation, .firesOnRecordUpdate])
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "A new pre-order or update was made!"
        notificationInfo.shouldBadge = true
        notificationInfo.soundName = "default"
        subscription.notificationInfo = notificationInfo
        db.save(subscription) { _, error in
            if let error = error {
                print("CloudKit subscription error: \(error)")
            } else {
                print("CloudKit subscription registered.")
            }
        }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Device token received, no need to send to server for CloudKit
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Visual feedback: post notification
        NotificationCenter.default.post(name: Notification.Name("CloudKitNotificationReceived"), object: nil)
        completionHandler(.newData)
    }

    // Show banner for foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

struct MainView: View {
    @State private var selectedColor: Color = Color(hex: "#555555")
    private let colors: [(name: String, color: Color)] = [
        ("white", Color(hex: "#ffffff")),
        ("grey", Color(hex: "#555555")),
        ("black", Color(hex: "#151515")),
        ("coffee", Color(hex: "#7a5236")), // darker brown
        ("orange", Color(hex: "#ff4d00")),
        ("red", Color(hex: "#8a1010")),
        ("green", Color(hex: "#14341b")),
        ("blue", Color(hex: "#0066ff")),
    ]
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var showSubmitted: Bool = false
    @State private var emailError: String? = nil
    @State private var nameError: String? = nil
    @State private var buttonPressed: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = "There was an error submitting your pre-order. Please try again."
    @State private var hasSubmitted: Bool = false
    @FocusState private var nameFieldIsFocused: Bool
    @FocusState private var emailFieldIsFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("jorobean_isDarkMode") private var isDarkMode: Bool = false
    @State private var showInfoSheet: Bool = false
    @State private var showCloudKitAlert = false

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
                        .accessibilityLabel("Jorobean logo")
                        .accessibilityHidden(false)
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
                            .accessibilityElement(children: .contain)
                        PreOrderPanel(fullName: $fullName, email: $email, showSubmitted: $showSubmitted, isDarkMode: isDarkMode, emailError: $emailError, nameError: $nameError, buttonPressed: $buttonPressed, isSubmitting: $isSubmitting, showError: $showError, errorMessage: $errorMessage, hasSubmitted: $hasSubmitted)
                            .padding(.top, 8)
                            .accessibilityElement(children: .contain)
                        Spacer(minLength: 12)
                        // Bottom controls and footer
                        VStack(spacing: 8) {
                            HStack(spacing: 18) {
                                Button(action: { 
                                    isDarkMode.toggle()
                                }) {
                                    Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(isDarkMode ? .white : .black)
                                }
                                .accessibilityLabel(isDarkMode ? "Switch to light mode" : "Switch to dark mode")
                                .accessibilityHint("Toggles app theme")
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
                                .accessibilityLabel("Open Jorobean Instagram")
                                .accessibilityHint("Opens Instagram in browser")
                                Button(action: { showInfoSheet = true }) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(isDarkMode ? .white : .black)
                                }
                                .accessibilityLabel("About Jorobean")
                                .accessibilityHint("Shows information about Jorobean")
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
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CloudKitNotificationReceived"))) { _ in
            showCloudKitAlert = true
        }
        .alert(isPresented: $showCloudKitAlert) {
            Alert(title: Text("CloudKit Notification Received!"), message: Text("A new or updated PreOrder was detected."), dismissButton: .default(Text("OK")))
        }
    }
}

struct PreOrderPanel: View {
    @Binding var fullName: String
    @Binding var email: String
    @Binding var showSubmitted: Bool
    var isDarkMode: Bool
    @Binding var emailError: String?
    @Binding var nameError: String?
    @Binding var buttonPressed: Bool
    @Binding var isSubmitting: Bool
    @Binding var showError: Bool
    @Binding var errorMessage: String
    @Binding var hasSubmitted: Bool
    @FocusState private var nameFieldIsFocused: Bool
    @FocusState private var emailFieldIsFocused: Bool
    @State private var errorTimer: Timer? = nil

    func submitPreorder(name: String, email: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "https://formspree.io/f/meoabwgg") else {
            completion(false, "Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let payload: [String: String] = ["name": name, "email": email]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            completion(false, "Failed to encode JSON")
            return
        }
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error as NSError?, error.domain == NSURLErrorDomain {
                completion(false, "Network error: Please check your internet connection and try again.")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false, "No HTTP response")
                return
            }
            let statusCode = httpResponse.statusCode
            let responseString = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            print("Formspree status: \(statusCode), response: \(responseString)")
            if (200...299).contains(statusCode) {
                completion(true, nil)
            } else {
                completion(false, "Status: \(statusCode)\nResponse: \(responseString)")
            }
        }
        task.resume()
    }

    func validateEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: trimmed)
    }

    func showErrorMessage(for field: String) {
        errorTimer?.invalidate()
        errorTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
            if field == "email" { emailError = nil }
            if field == "name" { nameError = nil }
        }
    }

    func validateAndSubmit() {
        emailError = nil
        nameError = nil
        var valid = true
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            nameError = "Please enter your name."
            valid = false
            showErrorMessage(for: "name")
        }
        if trimmedEmail.isEmpty {
            emailError = "Please enter your email."
            valid = false
            showErrorMessage(for: "email")
        } else if !validateEmail(trimmedEmail) {
            emailError = "Please enter a valid email address."
            valid = false
            showErrorMessage(for: "email")
        }
        if valid && !isSubmitting && !hasSubmitted {
            isSubmitting = true
            showError = false
            submitPreorder(name: trimmedName, email: trimmedEmail) { success, errorMsg in
                DispatchQueue.main.async {
                    isSubmitting = false
                    if success {
                        showSubmitted = true
                        // Clear form fields
                        fullName = ""
                        email = ""
                        // Reset errors
                        emailError = nil
                        nameError = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            showSubmitted = false
                            hasSubmitted = true
                        }
                    } else {
                        showError = true
                        errorMessage = errorMsg ?? "There was an error submitting your pre-order. Please try again."
                    }
                }
            }
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(LocalizedStringKey("preorder_title"))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(isDarkMode ? .white : .black)
                .padding(.top, 0)
                .accessibilityAddTraits(.isHeader)
            Text(LocalizedStringKey("preorder_subtitle"))
                .font(.body)
                .foregroundColor(isDarkMode ? .gray.opacity(0.8) : .gray)
                .dynamicTypeSize(.xSmall ... .accessibility5)
                .textCase(nil)
                .multilineTextAlignment(.center) // Center the subtitle text
            VStack(spacing: 16) {
                TextField(LocalizedStringKey("preorder_name_placeholder"), text: $fullName, onCommit: {
                    emailFieldIsFocused = true
                })
                .focused($nameFieldIsFocused)
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
                .disabled(isSubmitting)
                .accessibilityLabel(LocalizedStringKey("preorder_name_placeholder"))
                if let nameError = nameError {
                    Text(LocalizedStringKey(nameError))
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel(LocalizedStringKey(nameError))
                }
                TextField(LocalizedStringKey("preorder_email_placeholder"), text: $email, onCommit: {
                    emailFieldIsFocused = false
                    validateAndSubmit()
                })
                .focused($emailFieldIsFocused)
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
                .autocapitalization(.none)
                .disabled(isSubmitting)
                .accessibilityLabel(LocalizedStringKey("preorder_email_placeholder"))
                if let emailError = emailError {
                    Text(LocalizedStringKey(emailError))
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel(LocalizedStringKey(emailError))
                }
            }
            Button(action: {
                buttonPressed = true
                validateAndSubmit()
            }) {
                ZStack {
                    HStack {
                        Spacer()
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isSubmitting ? LocalizedStringKey("preorder_submitting") : hasSubmitted ? LocalizedStringKey("preorder_thankyou") : LocalizedStringKey("preorder_submit"))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .scaleEffect(buttonPressed ? 0.97 : 1.0)
                            .animation(.easeInOut(duration: 0.12), value: buttonPressed)
                        Spacer()
                    }
                    .opacity(showSubmitted ? 0 : 1)
                    if showSubmitted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.green)
                            .scaleEffect(1)
                            .opacity(1)
                            .animation(.spring(response: 0.4, dampingFraction: 0.5), value: showSubmitted)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                }
                .padding()
                .background(isSubmitting || hasSubmitted ? Color.gray : Color.black)
                .cornerRadius(10)
                .frame(height: 48)
                .accessibilityLabel(hasSubmitted ? LocalizedStringKey("preorder_thankyou") : (isSubmitting ? LocalizedStringKey("preorder_submitting") : LocalizedStringKey("preorder_submit")))
                .accessibilityHint(hasSubmitted ? LocalizedStringKey("preorder_thankyou") : LocalizedStringKey("preorder_submit"))
            }
            .disabled(isSubmitting || fullName.isEmpty || email.isEmpty || hasSubmitted)
            .frame(maxWidth: 340)
            .padding(.top, 4)
            .onChange(of: isSubmitting) { oldValue, newValue in
                if newValue {
                    buttonPressed = false
                }
            }
            .onChange(of: showSubmitted) { oldValue, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        showSubmitted = false
                        hasSubmitted = true
                    }
                }
            }
            if showError {
                Text(LocalizedStringKey(errorMessage))
                    .foregroundColor(.red)
                    .font(.system(size: 16, weight: .medium))
                    .accessibilityLabel(LocalizedStringKey(errorMessage))
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
                .foregroundColor(Color(UIColor.separator))
                .padding(.top, 8)
                .accessibilityHidden(true)
            Text(LocalizedStringKey("about_title"))
                .font(.title3).bold()
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
                .accessibilityAddTraits(.isHeader)
            Text(LocalizedStringKey("about_body"))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .accessibilityLabel(LocalizedStringKey("about_body"))
                .dynamicTypeSize(.xSmall ... .accessibility5)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .accessibilityElement(children: .contain)
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
            Text(LocalizedStringKey("features_title"))
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(isDarkMode ? .white : .black)
                .padding(.bottom, 8)
                .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                FeatureItem(
                    icon: "cube.box.fill",
                    title: LocalizedStringKey("feature_3d_printed"),
                    description: LocalizedStringKey("feature_3d_printed_description"),
                    isDarkMode: isDarkMode,
                    minHeight: minBoxHeight,
                    maxWidth: (boxWidth / 2) - 8 // 2 columns, grid spacing
                )
                FeatureItem(
                    icon: "hands.sparkles.fill",
                    title: LocalizedStringKey("feature_no_glue"),
                    description: LocalizedStringKey("feature_no_glue_description"),
                    isDarkMode: isDarkMode,
                    minHeight: minBoxHeight,
                    maxWidth: (boxWidth / 2) - 8
                )
                FeatureItem(
                    icon: "printer.fill",
                    title: LocalizedStringKey("feature_printed_on_demand"),
                    description: LocalizedStringKey("feature_printed_on_demand_description"),
                    isDarkMode: isDarkMode,
                    minHeight: minBoxHeight,
                    maxWidth: (boxWidth / 2) - 8
                )
                FeatureItem(
                    icon: "wind",
                    title: LocalizedStringKey("feature_lightweight"),
                    description: LocalizedStringKey("feature_lightweight_description"),
                    isDarkMode: isDarkMode,
                    minHeight: minBoxHeight,
                    maxWidth: (boxWidth / 2) - 8
                )
            }
            .padding(.horizontal, horizontalPadding)
            .accessibilityElement(children: .contain)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 0)
    }
}

struct FeatureItem: View {
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
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
                .accessibilityHidden(true)
            // Vertically align titles using fixed height
            ZStack(alignment: .top) {
                Color.clear.frame(height: 30) // Placeholder for alignment
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(isDarkMode ? .white : .black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(height: 30, alignment: .center)
                    .accessibilityAddTraits(.isHeader)
            }
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(isDarkMode ? .gray.opacity(0.8) : .gray)
                .padding(.top, 6)
                .accessibilityLabel(description)
                .dynamicTypeSize(.xSmall ... .accessibility5)
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
