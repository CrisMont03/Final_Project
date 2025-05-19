//
//  RegisterView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 17/05/25.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var navigateToMedicalHistory: Bool = false
    @State private var isLoading: Bool = false

    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9")
    )

    var body: some View {
        ZStack {
            colors.background
                .ignoresSafeArea()

            VStack(alignment: .center, spacing: 24) {
                VStack(alignment: .center, spacing: 5) {
                    Text("Regístrate")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                    Text("Crea tu cuenta como paciente:")
                        .font(.system(size: 16, weight: .light, design: .rounded))
                        .foregroundColor(.black)
                }

                TextField(
                    "",
                    text: $name,
                    prompt: Text("Nombre completo").foregroundColor(.black.opacity(0.5))
                )
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )
                    .textContentType(.name)

                TextField(
                    "",
                    text: $email,
                    prompt: Text("Correo").foregroundColor(.black.opacity(0.5))
                )
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)

                SecureField(
                    "",
                    text: $password,
                    prompt: Text("Contraseña").foregroundColor(.black.opacity(0.5))
                )
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
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
                    guard !isLoading else { return }
                    if name.isEmpty || email.isEmpty || password.isEmpty {
                        authViewModel.errorMessage = "Por favor, completa todos los campos"
                    } else if email.hasSuffix("@healme.doc.co") {
                        authViewModel.errorMessage = "Este correo está reservado para médicos"
                    } else if password.count < 6 {
                        authViewModel.errorMessage = "La contraseña debe tener al menos 6 caracteres"
                    } else {
                        isLoading = true
                        print("Attempting to sign up with email: \(email), name: \(name)")
                        authViewModel.signUpPatient(email: email, password: password, name: name) { success in
                            isLoading = false
                            if success {
                                print("Sign-up successful, navigating to RegisterMedicalHistoryView")
                                navigateToMedicalHistory = true
                            } else {
                                print("Sign-up failed, error: \(authViewModel.errorMessage)")
                                if authViewModel.errorMessage.isEmpty {
                                    authViewModel.errorMessage = "Error al registrarse, intenta de nuevo"
                                }
                            }
                        }
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }) {
                    Text(isLoading ? "Registrando..." : "Registrarse")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isLoading ? colors.green.opacity(0.5) : colors.green)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isLoading)

                HStack(spacing: 0) {
                    Text("¿Ya tienes una cuenta? ")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.black)
                    
                    Text("Inicia sesión")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(colors.blue)
                        .onTapGesture {
                            print("Dismiss tapped, returning to LoginView")
                            dismiss()
                        }
                }
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationDestination(isPresented: $navigateToMedicalHistory) {
                RegisterMedicalHistoryView()
                    .environmentObject(authViewModel)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("RegisterView appeared, clearing errorMessage")
            authViewModel.errorMessage = ""
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
            .environmentObject(AuthViewModel())
    }
}
