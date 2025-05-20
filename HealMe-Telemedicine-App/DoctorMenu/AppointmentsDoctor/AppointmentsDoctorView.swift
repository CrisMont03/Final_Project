//
//  AppointmentsDoctorView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 19/05/25.
//

import SwiftUI

struct AppointmentDoctor: Identifiable {
    let id: UUID //ID del paciente
    let date: String
    let hour: String
    let patientName: String
}

struct AppointmentsDoctorView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var appointments: [AppointmentDoctor] = []
    @State private var errorMessage: String = ""
    @State private var selectedVideoCallAppointment: AppointmentDoctor?
    @State private var channelName: String?
    @State private var showDiagnosisModal: Bool = false // Estado para el modal
    @State private var completedAppointment: AppointmentDoctor? // Cita completada

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
                    VStack(spacing: 0) {
                        Text("Citas Pendientes")
                            .font(.system(size: 28, weight: .medium, design: .rounded))
                            .foregroundColor(.black)
                        Text("Revisa tus citas programadas")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 35)
                    .padding(.bottom, 12)

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
                                        guard let doctorId = authViewModel.currentUserId else {
                                            errorMessage = "No se pudo obtener el ID del médico"
                                            print("No doctorId available")
                                            return
                                        }
                                        authViewModel.fetchChannelName(
                                            doctorId: doctorId,
                                            date: appointment.date,
                                            hour: appointment.hour,
                                            patientName: appointment.patientName
                                        ) { channelName in
                                            if let channelName = channelName {
                                                selectedVideoCallAppointment = appointment
                                                self.channelName = channelName
                                                print("Joining video call for appointment: \(appointment), channelName: \(channelName)")
                                            } else {
                                                errorMessage = "No se pudo encontrar el canal de la videollamada"
                                                print("Failed to fetch channelName")
                                            }
                                        }
                                    })
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: Binding(
                get: { selectedVideoCallAppointment != nil && channelName != nil },
                set: { if !$0 {
                    if let completed = selectedVideoCallAppointment {
                        completedAppointment = completed
                        showDiagnosisModal = true
                    }
                    selectedVideoCallAppointment = nil
                    channelName = nil
                } }
            )) {
                if let appointment = selectedVideoCallAppointment, let channelName = channelName {
                    VideoCallRoomDoctorView(
                        channelName: channelName,
                        appointment: appointment,
                        onCallEnded: {
                            completedAppointment = appointment
                            showDiagnosisModal = true
                        }
                    )
                    .environmentObject(authViewModel)
                }
            }
            .sheet(isPresented: $showDiagnosisModal) {
                if let appointment = completedAppointment {
                    DiagnosisFormView(
                        appointment: appointment,
                        authViewModel: authViewModel,
                        onDismiss: { showDiagnosisModal = false }
                    )
                }
            }
            .onAppear {
                fetchAppointments()
            }
        }
    }

    private struct AppointmentCardView: View {
        let appointment: AppointmentDoctor
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
                    Text("Paciente: \(appointment.patientName)")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.black)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("Fecha: \(appointment.date) - \(appointment.hour)")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.blue)
                }
                Button(action: onJoinVideoCall) {
                    HStack(spacing: 8) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text("Iniciar videollamada")
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
        guard let doctorId = authViewModel.currentUserId else {
            print("No doctor ID available")
            appointments = []
            errorMessage = "No se pudo obtener el ID del médico"
            return
        }
        authViewModel.fetchDoctorAppointments(doctorId: doctorId) { fetchedAppointments in
            appointments = fetchedAppointments
            print("Doctor appointments fetched: \(appointments)")
        }
    }
}

struct AppointmentsDoctorView_Previews: PreviewProvider {
    static var previews: some View {
        AppointmentsDoctorView()
            .environmentObject(AuthViewModel())
    }
}
