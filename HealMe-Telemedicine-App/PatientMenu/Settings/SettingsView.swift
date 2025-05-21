//
//  SettingsView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 17/05/25.
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9")
    )
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 0) {
                Text("Ajustes")
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundColor(.black)
                Text("Configura tu cuenta y preferencias:")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.gray)
            }
            .padding(.top, 10)
            .padding(.bottom, 12)
            
            // Buttons
            VStack(spacing: 12) {
                // Edit Profile Button
                Button(action: {
                    // Implementar acción para editar perfil
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                        Text("Editar Perfil")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colors.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                
                // Change Password Button
                Button(action: {
                    // Implementar acción para cambiar contraseña
                }) {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                        Text("Cambiar Contraseña")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colors.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                
                // Technical Support Button
                Button(action: {
                    // Implementar acción para soporte técnico
                }) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                        Text("Soporte Técnico")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colors.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                
                // Sign Out Button
                Button(action: {
                    try? Auth.auth().signOut()
                }) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                        Text("Cerrar Sesión")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colors.red)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
        .navigationBarHidden(true)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AuthViewModel())
    }
}
