//
//  RegisterView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 17/05/25.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss // Añadido para regresar a la vista anterior
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var navigateToMedicalHistory: Bool = false

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
                        .foregroundColor(.primary)
                    Text("Crea tu cuenta como paciente:")
                        .font(.system(size: 16, weight: .light, design: .rounded))
                        .foregroundColor(.primary)
                }

                TextField("Nombre completo", text: $name)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .textContentType(.name)

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
                    if name.isEmpty || email.isEmpty || password.isEmpty {
                        authViewModel.errorMessage = "Por favor, completa todos los campos"
                    } else if email.hasSuffix("@healme.doc.co") {
                        authViewModel.errorMessage = "Este correo está reservado para médicos"
                    } else {
                        authViewModel.signUpPatient(email: email, password: password, name: name) { success in
                            if success {
                                navigateToMedicalHistory = true
                            }
                        }
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }) {
                    Text("Registrarse")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(colors.green)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Nuevo enlace para regresar a LoginView
                HStack(spacing: 0) {
                    Text("¿Ya tienes una cuenta? ")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Inicia sesión")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(colors.blue)
                        .onTapGesture {
                            dismiss() // Regresa a la vista anterior (LoginView)
                        }
                }

                // Navegación a RegisterMedicalHistoryView
                .navigationDestination(isPresented: $navigateToMedicalHistory) {
                    RegisterMedicalHistoryView()
                        .environmentObject(authViewModel)
                }
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationBarHidden(true)
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
            .environmentObject(AuthViewModel())
    }
}
