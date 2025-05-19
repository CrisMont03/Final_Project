//
//  AppointmentsView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 17/05/25.
//

import SwiftUI

struct Appointment: Identifiable, Codable {
    let id = UUID()
    let doctorId: String
    let doctorName: String
    let specialty: String
    let date: String
    let hour: String
    
    enum CodingKeys: String, CodingKey {
        case doctorId
        case doctorName
        case specialty
        case date
        case hour
    }
}

struct AppointmentsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var appointments: [Appointment] = []
    @State private var isShowingForm: Bool = false
    @State private var isShowingQRModal: Bool = false
    @State private var selectedAppointment: Appointment?
    @State private var selectedVideoCallAppointment: Appointment?
    @State private var errorMessage: String = ""

    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9")
    )

    var body: some View {
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()

                VStack {
                    Text("Mis Citas")
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.top, 35)
                        .padding(.bottom, 8)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(colors.red)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }

                    if appointments.isEmpty {
                        Text("No tienes citas pendientes")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.gray)
                            .padding(.top, 20)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(appointments) { appointment in
                                    AppointmentCardView(appointment: appointment, onJoinVideoCall: {
                                        selectedVideoCallAppointment = appointment
                                        print("Joining video call for appointment: \(appointment)")
                                    })
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    Spacer()

                    Button(action: {
                        isShowingForm = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 16, weight: .medium))
                            Text("Agendar cita")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(colors.green)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $isShowingForm) {
                AppointmentsFormView(onAppointmentCreated: { appointment in
                    print("Appointment created in AppointmentsFormView: \(appointment)")
                    DispatchQueue.main.async {
                        selectedAppointment = appointment
                        print("Selected appointment set: \(String(describing: selectedAppointment))")
                        isShowingQRModal = true
                    }
                })
                    .environmentObject(authViewModel)
            }
            .navigationDestination(isPresented: Binding(
                get: { selectedVideoCallAppointment != nil },
                set: { if !$0 { selectedVideoCallAppointment = nil } }
            )) {
                if let appointment = selectedVideoCallAppointment {
                    VideoCallRoomView(appointment: appointment)
                        .environmentObject(authViewModel)
                }
            }
            .sheet(isPresented: $isShowingQRModal) {
                QRScannerModalView(appointment: selectedAppointment) { appointment in
                    print("QRScannerModalView callback received appointment: \(String(describing: appointment))")
                    if let appointment = appointment {
                        authViewModel.createAppointment(appointment: appointment) { success in
                            if success {
                                fetchAppointments()
                                isShowingQRModal = false
                                selectedAppointment = nil
                                errorMessage = ""
                            } else {
                                errorMessage = authViewModel.errorMessage.isEmpty ? "No se pudo crear la cita" : authViewModel.errorMessage
                                print("Failed to create appointment: \(authViewModel.errorMessage)")
                                isShowingQRModal = false
                            }
                        }
                    } else {
                        print("No appointment provided in QRScannerModalView callback")
                        errorMessage = "No se proporcionó una cita válida"
                        isShowingQRModal = false
                    }
                }
            }
            .onChange(of: isShowingQRModal) { oldValue, newValue in
                if newValue {
                    print("Showing QRScannerModalView with selectedAppointment: \(String(describing: selectedAppointment))")
                }
            }
            .onAppear {
                fetchAppointments()
            }
        }
    }

    private struct AppointmentCardView: View {
        let appointment: Appointment
        let onJoinVideoCall: () -> Void
        private let colors = (
            blue: Color(hex: "007AFE"),
            background: Color(hex: "F5F6F9")
        )

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(colors.blue)
                    Text("Dr. \(appointment.doctorName)")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.black)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("Especialidad: \(appointment.specialty)")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.gray)
                    Text("Fecha: \(appointment.date) - \(appointment.hour)")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.blue)
                }
                Button(action: onJoinVideoCall) {
                    HStack(spacing: 8) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text("Unirse a videollamada")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(colors.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
    }

    private func fetchAppointments() {
        guard let userId = authViewModel.currentUserId else {
            print("No user ID available")
            appointments = []
            errorMessage = "No se pudo obtener el ID del usuario"
            return
        }
        authViewModel.fetchPatientAppointments(userId: userId) { fetchedAppointments in
            appointments = fetchedAppointments
            print("Appointments fetched: \(appointments)")
        }
    }
}

struct AppointmentsView_Previews: PreviewProvider {
    static var previews: some View {
        AppointmentsView()
            .environmentObject(AuthViewModel())
    }
}
