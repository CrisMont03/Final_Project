//
//  InicioView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 17/05/25.
//

import SwiftUI
import Charts
import SwiftUICharts
import FirebaseAuth

struct MedicalData: Identifiable {
    let id = UUID()
    let type: String
    let value: Double
}

struct InicioView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isDataLoaded: Bool = false
    
    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9")
    )
    
    // Datos para el gráfico de barras (Resumen Vital)
    private var barChartData: [MedicalData] {
        guard isDataLoaded else {
            print("BarChartData: Data not loaded yet")
            return []
        }
        let weight = authViewModel.patientMedicalHistory["weight"] as? Double ?? 0
        let height = authViewModel.patientMedicalHistory["height"] as? Double ?? 0
        let age = authViewModel.patientMedicalHistory["age"] as? Double ?? 0
        guard weight > 0 && !weight.isNaN && !weight.isInfinite &&
              height > 0 && !height.isNaN && !height.isInfinite &&
              age >= 0 && !age.isNaN && !age.isInfinite else {
            print("BarChartData: Invalid data - weight=\(weight), height=\(height), age=\(age)")
            return []
        }
        let bmi = weight / ((height / 100) * (height / 100))
        guard !bmi.isNaN && !bmi.isInfinite else {
            print("BarChartData: Invalid BMI=\(bmi)")
            return []
        }
        let data = [
            MedicalData(type: "Peso", value: weight),
            MedicalData(type: "Altura", value: height),
            MedicalData(type: "Edad", value: age),
            MedicalData(type: "IMC", value: bmi)
        ]
        print("BarChartData: \(data.map { ($0.type, $0.value) })")
        return data
    }
    
    // Datos para el gráfico de líneas (Tendencia de Peso)
    private var lineChartData: [MedicalData] {
        guard isDataLoaded else {
            print("LineChartData: Data not loaded yet")
            return []
        }
        let weight = authViewModel.patientMedicalHistory["weight"] as? Double ?? 0
        guard weight > 0 && !weight.isNaN && !weight.isInfinite else {
            print("LineChartData: Invalid weight=\(weight)")
            return []
        }
        let data = [MedicalData(type: "Hoy", value: weight)]
        print("LineChartData: \(data.map { ($0.type, $0.value) })")
        return data
    }
    
    // Datos para el gráfico de barras horizontales (Nivel de Ejercicio)
    private var exerciseChartData: [MedicalData] {
        guard isDataLoaded else {
            print("ExerciseChartData: Data not loaded yet")
            return []
        }
        let exercise = authViewModel.patientMedicalHistory["exercise"] as? String ?? "Ninguno"
        let exerciseValue: Double
        switch exercise {
        case "Ninguno":
            exerciseValue = 1
        case "A veces":
            exerciseValue = 2
        case "Frecuente":
            exerciseValue = 3
        default:
            exerciseValue = 0
        }
        guard exerciseValue > 0 else {
            print("ExerciseChartData: Invalid exercise=\(exercise)")
            return []
        }
        let data = [MedicalData(type: exercise, value: exerciseValue)]
        print("ExerciseChartData: \(data.map { ($0.type, $0.value) })")
        return data
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 0) {
                    // Encabezado de bienvenida
                    Text("¡Hola, \(authViewModel.patientName.isEmpty ? "Paciente!" : authViewModel.patientName)!")
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundColor(.black)
                    Text("Observa tu resumen médico de los últimos días:")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.gray)
                }
                .padding(.top, 7)
                .padding(.bottom, 15)
                
                // Tarjeta: Gráfico de barras (Resumen Vital)
                if isDataLoaded && !barChartData.isEmpty {
                    ChartCardView(
                        title: "Resumen Vital",
                        icon: "heart.fill",
                        chart: {
                            Chart(barChartData) { data in
                                BarMark(
                                    x: .value("Tipo", data.type),
                                    y: .value("Valor", data.value)
                                )
                                .foregroundStyle(colors.blue)
                                .annotation(position: .top) {
                                    Text(String(format: "%.1f", data.value))
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.gray) // Cambiado a gris para medidas
                                }
                            }
                            .chartXAxis {
                                AxisMarks { _ in
                                    AxisValueLabel()
                                        .foregroundStyle(.black) // Etiquetas del eje X en negro
                                }
                            }
                            .chartYAxis {
                                AxisMarks { _ in
                                    AxisValueLabel()
                                        .foregroundStyle(.black) // Etiquetas del eje Y en negro
                                }
                            }
                            .frame(height: 180)
                        }
                    )
                } else {
                    ChartCardView(
                        title: "Resumen Vital",
                        icon: "heart.fill",
                        chart: {
                            Text("Cargando datos...")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.gray)
                        }
                    )
                }
                
                // Tarjeta: Gráfico de líneas (Tendencia de Peso)
                if isDataLoaded && !lineChartData.isEmpty {
                    ChartCardView(
                        title: "Tendencia de Peso",
                        icon: "scalemass.fill",
                        chart: {
                            Chart(lineChartData) { data in
                                LineMark(
                                    x: .value("Fecha", data.type),
                                    y: .value("Peso", data.value)
                                )
                                .foregroundStyle(colors.green)
                                .symbol(Circle())
                                .symbolSize(100)
                                .annotation(position: .top) {
                                    Text(String(format: "%.1f", data.value))
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.gray) // Cambiado a gris para medidas
                                }
                            }
                            .chartXAxis {
                                AxisMarks { _ in
                                    AxisValueLabel()
                                        .foregroundStyle(.black) // Etiquetas del eje X en negro
                                }
                            }
                            .chartYAxis {
                                AxisMarks { _ in
                                    AxisValueLabel()
                                        .foregroundStyle(.black) // Etiquetas del eje Y en negro
                                }
                            }
                            .frame(height: 180)
                        }
                    )
                } else {
                    ChartCardView(
                        title: "Tendencia de Peso",
                        icon: "scalemass.fill",
                        chart: {
                            Text("Cargando datos...")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.gray)
                        }
                    )
                }
                
                // Tarjeta: Gráfico de barras horizontales (Nivel de Ejercicio)
                if isDataLoaded && !exerciseChartData.isEmpty {
                    ChartCardView(
                        title: "Nivel de Ejercicio",
                        icon: "figure.walk",
                        chart: {
                            Chart(exerciseChartData) { data in
                                BarMark(
                                    x: .value("Valor", data.value),
                                    y: .value("Nivel", data.type)
                                )
                                .foregroundStyle(by: .value("Nivel", data.type))
                                .annotation(position: .trailing) {
                                    Text(data.type)
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.black) // Categorías en negro
                                }
                            }
                            .chartForegroundStyleScale([
                                "Ninguno": colors.blue,
                                "A veces": colors.blue.opacity(0.7),
                                "Frecuente": colors.blue.opacity(0.4)
                            ])
                            .chartXAxis {
                                AxisMarks { _ in
                                    AxisValueLabel()
                                        .foregroundStyle(.black) // Etiquetas del eje X en negro
                                }
                            }
                            .chartYAxis {
                                AxisMarks { _ in
                                    AxisValueLabel()
                                        .foregroundStyle(.black) // Etiquetas del eje Y en negro
                                }
                            }
                            .frame(height: 100)
                            .padding(.top, 12)
                            .foregroundColor(.gray)
                        }
                    )
                } else {
                    ChartCardView(
                        title: "Nivel de Ejercicio",
                        icon: "figure.walk",
                        chart: {
                            Text("Cargando datos...")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.gray)
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 35)
        }
        .background(colors.background)
        .navigationBarHidden(true)
        .onAppear {
            print("InicioView appeared, patientMedicalHistory: \(authViewModel.patientMedicalHistory)")
            if !authViewModel.patientMedicalHistory.isEmpty {
                isDataLoaded = true
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isDataLoaded = !authViewModel.patientMedicalHistory.isEmpty
                    print("Data load check: isDataLoaded=\(isDataLoaded), patientMedicalHistory=\(authViewModel.patientMedicalHistory)")
                }
            }
        }
    }
}

// Vista auxiliar para las tarjetas de gráficas
struct ChartCardView<Content: View>: View {
    let title: String
    let icon: String
    let chart: () -> Content
    
    private let colors = (
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9"),
        green: Color(hex: "28A745")
    )
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(colors.green)
                Text(title)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.black)
                Spacer()
            }
            chart()
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

struct InicioView_Previews: PreviewProvider {
    static var previews: some View {
        InicioView()
            .environmentObject(AuthViewModel())
    }
}
