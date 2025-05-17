//
//  PatientView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 17/05/25.
//

import SwiftUI
import FirebaseAuth

struct PatientView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Panel del Paciente")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Bienvenido, paciente")
                .font(.title2)

            Button(action: {
                try? Auth.auth().signOut()
            }) {
                Text("Cerrar Sesión")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}

struct PatientView_Previews: PreviewProvider {
    static var previews: some View {
        PatientView()
            .environmentObject(AuthViewModel())
    }
}
