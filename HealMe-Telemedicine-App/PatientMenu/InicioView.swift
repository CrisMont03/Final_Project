//
//  InicioView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 17/05/25.
//

import SwiftUI
import SwiftUICharts // Importar SwiftUICharts
import FirebaseAuth

struct InicioView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9")
    )
    
    // Datos para el gráfico
    private var chartData: [(String, Double)] {
        let weight = authViewModel.patientMedicalHistory["weight"] as? Double ?? 0
        let height = authViewModel.patientMedicalHistory["height"] as? Double ?? 0
        return [
            ("Peso (kg)", weight),
            ("Altura (cm)", height)
        ]
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Encabezado de bienvenida
            Text("Bienvenido, \(authViewModel.patientName.isEmpty ? "Paciente" : authViewModel.patientName)")
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("Tu resumen médico")
                .font(.system(size: 16, weight: .light, design: .rounded))
                .foregroundColor(.primary)
            
            // Gráfico de barras con SwiftUICharts
            if !chartData.allSatisfy({ $0.1 == 0 }) {
                BarChartView(
                    data: ChartData(values: chartData),
                    title: "Datos Médicos",
                    style: ChartStyle(
                        backgroundColor: Color.white,
                        accentColor: colors.blue,
                        gradientColor: GradientColor(start: colors.blue, end: colors.blue.opacity(0.6)),
                        textColor: .primary,
                        legendTextColor: .primary,
                        dropShadowColor: .gray
                    ),
                    form: CGSize(width: 300, height: 200)
                )
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 24)
            } else {
                Text("Cargando datos médicos...")
                    .font(.system(size: 16, weight: .light, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
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
