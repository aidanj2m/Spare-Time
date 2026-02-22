import SwiftUI

struct OnboardingView: View {
    var onComplete: (String) -> Void  // passes userId

    enum Step {
        case name
        case phone
        case otp
    }

    @State private var step: Step = .name
    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var otpCode: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                switch step {
                case .name:
                    nameStep
                case .phone:
                    phoneStep
                case .otp:
                    otpStep
                }

                Spacer()
            }
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Name

    private var nameStep: some View {
        VStack(spacing: 24) {
            Text("What's your name?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.primary)

            TextField("Name", text: $name)
                .textFieldStyle(.plain)
                .foregroundStyle(Theme.primary)
                .padding()
                .background(Theme.surface)
                .cornerRadius(12)
                .autocorrectionDisabled()
                .tint(Theme.neon)

            continueButton(enabled: !name.trimmingCharacters(in: .whitespaces).isEmpty) {
                withAnimation { step = .phone }
            }
        }
    }

    // MARK: - Phone

    private var phoneStep: some View {
        VStack(spacing: 24) {
            Text("Mobile number")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.primary)

            HStack(spacing: 0) {
                Text("+1")
                    .padding(.leading, 16)
                    .padding(.trailing, 8)
                    .foregroundStyle(Theme.secondary)

                TextField("(555) 123-4567", text: $phoneNumber)
                    .textFieldStyle(.plain)
                    .foregroundStyle(Theme.primary)
                    .keyboardType(.numberPad)
                    .tint(Theme.neon)
                    .onChange(of: phoneNumber) { _, newValue in
                        let digits = String(newValue.filter(\.isNumber).prefix(10))
                        let formatted = formatPhoneDisplay(digits)
                        if formatted != newValue {
                            phoneNumber = formatted
                        }
                    }
            }
            .padding(.vertical, 14)
            .background(Theme.surface)
            .cornerRadius(12)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(Theme.error)
            }

            continueButton(enabled: phoneNumber.filter(\.isNumber).count == 10 && !isLoading) {
                Task { await sendOTP() }
            }
        }
    }

    // MARK: - OTP

    private var otpStep: some View {
        VStack(spacing: 24) {
            Text("Enter the code")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.primary)

            Text("Sent to \(phoneNumber)")
                .font(.subheadline)
                .foregroundColor(Theme.secondary)

            TextField("123456", text: $otpCode)
                .textFieldStyle(.plain)
                .foregroundStyle(Theme.primary)
                .padding()
                .background(Theme.surface)
                .cornerRadius(12)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.title3.monospacedDigit())
                .tint(Theme.neon)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(Theme.error)
            }

            continueButton(label: "Verify", enabled: otpCode.count == 6 && !isLoading) {
                Task { await verifyOTP() }
            }

            Button("Resend code") {
                Task { await sendOTP() }
            }
            .font(.subheadline)
            .foregroundColor(Theme.secondary)
        }
    }

    // MARK: - Shared button

    private func continueButton(label: String = "Continue", enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .tint(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Text(label)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .background(enabled ? Theme.neon : Theme.surface)
        .foregroundColor(enabled ? Theme.background : Theme.secondary)
        .cornerRadius(12)
        .disabled(!enabled)
    }

    // MARK: - API calls

    private func sendOTP() async {
        isLoading = true
        errorMessage = nil

        let formatted = formatPhoneNumber(phoneNumber)
        do {
            _ = try await APIService.sendOTP(phoneNumber: formatted)
            withAnimation { step = .otp }
        } catch {
            errorMessage = "Failed to send code. Check your number."
            print("[Auth] sendOTP error: \(error)")
        }
        isLoading = false
    }

    private func verifyOTP() async {
        isLoading = true
        errorMessage = nil

        let formatted = formatPhoneNumber(phoneNumber)
        do {
            let auth = try await APIService.verifyOTP(phoneNumber: formatted, code: otpCode)
            // Store user data
            UserDefaults.standard.set(auth.user_id, forKey: "userId")
            UserDefaults.standard.set(name, forKey: "userName")
            UserDefaults.standard.set(formatted, forKey: "userPhone")

            // Save name to backend
            try await APIService.updateUser(userId: auth.user_id, name: name)

            onComplete(auth.user_id)
        } catch {
            errorMessage = "Invalid or expired code."
            print("[Auth] verifyOTP error: \(error)")
        }
        isLoading = false
    }

    // Formats 10 raw digits into (XXX) XXX-XXXX for display
    private func formatPhoneDisplay(_ digits: String) -> String {
        switch digits.count {
        case 0:
            return ""
        case 1...3:
            return "(\(digits)"
        case 4...6:
            return "(\(digits.prefix(3))) \(digits.dropFirst(3))"
        default:
            return "(\(digits.prefix(3))) \(digits.dropFirst(3).prefix(3))-\(digits.dropFirst(6))"
        }
    }

    // Always sends +1XXXXXXXXXX to Twilio (E.164)
    private func formatPhoneNumber(_ raw: String) -> String {
        let digits = raw.filter(\.isNumber)
        let tenDigits = digits.hasPrefix("1") ? String(digits.dropFirst()) : digits
        return "+1\(tenDigits)"
    }
}

#Preview {
    OnboardingView { userId in
        print("Logged in: \(userId)")
    }
}
