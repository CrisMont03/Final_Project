//
//  PrescriptionsView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 17/05/25.
//

import SwiftUI
import FirebaseFirestore

struct PrescriptionsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var prescriptions: [Prescription] = []
    @State private var notifications: [Notification] = []
    @State private var errorMessage: String = ""

    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9")
    )

    var body: some View {
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 0) {
                        Text("Mis Recetas")
                            .font(.system(size: 28, weight: .medium, design: .rounded))
                            .foregroundColor(.black)
                        Text("Consulta tus recetas médicas:")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 8) // Reducido para minimizar espacio superior
                    .padding(.bottom, 8)

                    // Error Message
                    if !errorMessage.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(colors.red)
                                .font(.system(size: 16))
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(colors.red)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }

                    // Notifications
                    if !notifications.isEmpty {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(colors.blue)
                                .font(.system(size: 16))
                            Text("Tienes \(notifications.count) notificación(es) nueva(s)")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 16)
                    }

                    // Prescriptions List
                    if prescriptions.isEmpty {
                        Text("No tienes recetas disponibles")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.gray)
                            .padding(.top, 20)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(prescriptions) { prescription in
                                    PrescriptionCardView(prescription: prescription)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    Spacer()
                }
                .padding(.top, 1) // Mínimo padding para evitar espacio extra
            }
            .navigationBarHidden(true)
            .onAppear {
                fetchPrescriptionsAndNotifications()
            }
        }
    }

    private struct PrescriptionCardView: View {
        let prescription: Prescription
        private let colors = (
            blue: Color(hex: "007AFE"),
            background: Color(hex: "F5F6F9")
        )

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(colors.blue)
                    Text("Dr. \(prescription.doctorName)")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.black)
                }
                VStack(spacing: 4) {
                    Text("Fecha: \(prescription.date) - \(prescription.hour)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.blue)
                    Text("Diagnóstico: \(prescription.diagnosis)")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.black)
                    Text("Receta: \(prescription.prescription)")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.black)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }

    private func fetchPrescriptionsAndNotifications() {
        guard let patientId = authViewModel.currentUserId else {
            errorMessage = "No se pudo obtener el ID del paciente"
            return
        }

        authViewModel.fetchPatientPrescriptions(patientId: patientId) { fetchedPrescriptions in
            prescriptions = fetchedPrescriptions
            print("Prescriptions fetched: \(prescriptions.count)")
        }

        authViewModel.fetchPatientNotifications(patientId: patientId) { fetchedNotifications in
            notifications = fetchedNotifications
            print("Notifications fetched: \(notifications.count)")

            // Marcar notificaciones como leídas
            for notification in notifications {
                authViewModel.markNotificationAsRead(notificationId: notification.id) { success in
                    if !success {
                        print("Failed to mark notification as read: \(notification.id)")
                    }
                }
            }
        }
    }
}
