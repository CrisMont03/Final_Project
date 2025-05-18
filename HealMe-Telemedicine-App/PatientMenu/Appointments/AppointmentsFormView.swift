//
//  AppointmentsFormView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 17/05/25.
//

import SwiftUI

struct AppointmentsFormView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var specialty: String = ""
    @State private var date: Date = Date()
    @State private var hour: Date = Date()
    @State private var selectedDoctor: String? // Nombre del doctor asignado
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    let onAppointmentCreated: (Appointment) -> Void

    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9")
    )

    // Lista de especialidades (puedes ajustar según tus necesidades)
    private let specialties = ["Cardiología", "Pediatría", "Dermatología", "Neurología"]

    var body: some View {
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Título
                    Text("Agendar Cita")
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.top, 35)

                    // Especialidad
                    Picker("Especialidad", selection: $specialty) {
                        Text("Seleccionar").tag("")
                        ForEach(specialties, id: \.self) { specialty in
                            Text(specialty).tag(specialty)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )

                    // Fecha
                    DatePicker(
                        "Fecha",
                        selection: $date,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )

                    // Hora
                    DatePicker(
                        "Hora",
                        selection: $hour,
                        displayedComponents: [.hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )

                    // Mensaje de error
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(colors.red)
                            .multilineTextAlignment(.center)
                    }

                    // Doctor asignado
                    if let doctor = selectedDoctor {
                        Text("Doctor asignado: \(doctor)")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.top, 8)
                    }

                    // Botón de enviar
                    Button(action: {
                        isLoading = true
                        errorMessage = ""
                        checkDoctorAvailability()
                    }) {
                        Text(isLoading ? "Buscando..." : "Buscar Doctor")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isLoading ? colors.green.opacity(0.5) : colors.green)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isLoading || specialty.isEmpty)

                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            .navigationBarHidden(true)
        }
    }

    private func checkDoctorAvailability() {
        guard authViewModel.currentUserId != nil else {
            errorMessage = "No se pudo obtener el ID del usuario"
            isLoading = false
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.string(from: date)

        let hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "HH:mm"
        let formattedHour = hourFormatter.string(from: hour)

        print("Checking doctor availability for specialty: \(specialty), date: \(formattedDate), hour: \(formattedHour)")

        authViewModel.findAvailableDoctor(
            specialty: specialty,
            date: formattedDate,
            hour: formattedHour
        ) { doctorId, doctorName in
            isLoading = false
            if let doctorId = doctorId, let doctorName = doctorName {
                print("Doctor found: \(doctorName) (ID: \(doctorId))")
                selectedDoctor = doctorName
                let appointment = Appointment(
                    doctorId: doctorId,
                    doctorName: doctorName,
                    specialty: specialty,
                    date: formattedDate,
                    hour: formattedHour
                )
                print("Created appointment: \(appointment)")
                onAppointmentCreated(appointment)
                dismiss()
            } else {
                errorMessage = "No hay doctores disponibles para la fecha y hora seleccionadas"
                print("No doctor available for the selected time")
            }
        }
    }
}

struct AppointmentsFormView_Previews: PreviewProvider {
    static var previews: some View {
        AppointmentsFormView { _ in }
            .environmentObject(AuthViewModel())
    }
}
