//
//  InicioView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 17/05/25.
//

import SwiftUI
import FirebaseAuth

struct InicioView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9")
    )
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Bienvenido, Paciente")
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Este es tu panel de inicio")
                .font(.system(size: 16, weight: .light, design: .rounded))
                .foregroundColor(.primary)
            
            Button(action: {
                try? Auth.auth().signOut()
            }) {
                Text("Cerrar Sesión")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colors.red)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
        .navigationBarHidden(true)
    }
}

struct InicioView_Previews: PreviewProvider {
    static var previews: some View {
        InicioView()
            .environmentObject(AuthViewModel())
    }
}
