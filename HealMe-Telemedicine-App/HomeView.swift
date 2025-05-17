//
//  HomeView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 16/05/25.
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    var body: some View {
        VStack {
            Text("¡Bienvenido a tu app de Telemedicina!")
                .font(.title)
                .padding()
            Button(action: {
                try? Auth.auth().signOut()
            }) {
                Text("Cerrar Sesión")
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
