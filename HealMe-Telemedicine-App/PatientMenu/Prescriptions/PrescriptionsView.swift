//
//  PrescriptionsView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 17/05/25.
//

import SwiftUI

struct PrescriptionsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9")
    )
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Recetas")
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Aquí verás tus recetas médicas")
                .font(.system(size: 16, weight: .light, design: .rounded))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
        .navigationBarHidden(true)
    }
}

struct PrescriptionsView_Previews: PreviewProvider {
    static var previews: some View {
        PrescriptionsView()
            .environmentObject(AuthViewModel())
    }
}
