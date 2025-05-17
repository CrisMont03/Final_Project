//
//  LoginView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 16/05/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""

    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9")
    )

    var body: some View {
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()

                VStack(alignment: .center, spacing: 24) {
                    VStack(alignment: .center, spacing: 5) {
                        Text("Bienvenido")
                            .font(.system(size: 32, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Inicia sesión y accede a tu cuenta:")
                            .font(.system(size: 16, weight: .light, design: .rounded))
                            .foregroundColor(.primary)
                    }

                    TextField("Correo", text: $email)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)

                    SecureField("Contraseña", text: $password)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .textContentType(.password)

                    if !authViewModel.errorMessage.isEmpty {
                        Text(authViewModel.errorMessage)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(colors.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Button(action: {
                        if email.isEmpty || password.isEmpty {
                            authViewModel.errorMessage = "Por favor, completa todos los campos"
                        } else {
                            authViewModel.signIn(email: email, password: password)
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }) {
                        Text("Iniciar Sesión")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(colors.green)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    HStack(spacing: 0) {
                        Text("¿No tienes una cuenta? ")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.primary)
                        
                        NavigationLink {
                            RegisterView()
                                .environmentObject(authViewModel)
                        } label: {
                            Text("Regístrate")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(colors.blue)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationBarHidden(true)
        }
    }
}

// Extension to support hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
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

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel())
    }
}
