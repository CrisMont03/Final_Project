//
//  DiagnosisFormView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 20/05/25.
//

import SwiftUI
import FirebaseFirestore
import UserNotifications

struct Prescription: Identifiable {
    let id: String
    let patientId: String
    let patientName: String
    let doctorId: String
    let doctorName: String
    let date: String
    let hour: String
    let diagnosis: String
    let prescription: String
    let createdAt: Timestamp
}

struct Notification: Identifiable {
    let id: String
    let patientId: String
    let message: String
    let createdAt: Timestamp
    let read: Bool
}

struct DiagnosisFormView: View {
    let appointment: AppointmentDoctor
    @ObservedObject var authViewModel: AuthViewModel
    let onDismiss: () -> Void
    @State private var diagnosis: String = ""
    @State private var prescription: String = ""
    @State private var errorMessage: String = ""
    @State private var isSubmitting: Bool = false
    @Environment(\.dismiss) var dismiss

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

                VStack(spacing: 20) {
                    VStack(spacing: 0) {
                        Text("Receta Médica")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                        // Patient Info
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(colors.green)
                                .font(.system(size: 18))
                            Text("Paciente: \(appointment.patientName)")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 16)

                    // Diagnosis Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(colors.blue)
                                .font(.system(size: 16))
                            Text("Diagnóstico")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.black)
                        }
                        TextEditor(text: $diagnosis)
                            .frame(height: 120)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(colors.blue.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .padding(.horizontal, 16)

                    // Prescription Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "pills.fill")
                                .foregroundColor(colors.blue)
                                .font(.system(size: 16))
                            Text("Receta")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.black)
                        }
                        TextEditor(text: $prescription)
                            .frame(height: 120)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(colors.blue.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .padding(.horizontal, 16)

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
                    }

                    // Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            submitDiagnosis()
                        }) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.white)
                                Text(isSubmitting ? "Enviando..." : "Enviar")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(diagnosis.isEmpty || prescription.isEmpty || isSubmitting ? .gray : colors.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .disabled(diagnosis.isEmpty || prescription.isEmpty || isSubmitting)
                        
                        Button(action: {
                            dismiss()
                            onDismiss()
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                Text("Cancelar")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(colors.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
    }

    private func submitDiagnosis() {
        guard let doctorId = authViewModel.currentUserId else {
            errorMessage = "No se pudo obtener el ID del médico"
            return
        }

        isSubmitting = true
        errorMessage = ""

        let db = Firestore.firestore()
        db.collection("patients")
            .whereField("name", isEqualTo: appointment.patientName)
            .getDocuments { snapshot, error in
                if let error = error {
                    errorMessage = "Error al buscar paciente: \(error.localizedDescription)"
                    isSubmitting = false
                    return
                }

                guard let document = snapshot?.documents.first else {
                    errorMessage = "No se encontró al paciente"
                    isSubmitting = false
                    return
                }

                let patientId = document.documentID
                let prescriptionData: [String: Any] = [
                    "patientId": patientId,
                    "patientName": appointment.patientName,
                    "doctorId": doctorId,
                    "doctorName": authViewModel.doctorData?["name"] as? String ?? "Desconocido",
                    "date": appointment.date,
                    "hour": appointment.hour,
                    "diagnosis": diagnosis,
                    "prescription": prescription,
                    "createdAt": Timestamp()
                ]

                db.collection("prescriptions").addDocument(data: prescriptionData) { error in
                    if let error = error {
                        errorMessage = "Error al guardar la receta: \(error.localizedDescription)"
                        isSubmitting = false
                        return
                    }

                    let notificationData: [String: Any] = [
                        "patientId": patientId,
                        "message": "El Dr. \(authViewModel.doctorData?["name"] as? String ?? "Desconocido") ha enviado una nueva receta",
                        "createdAt": Timestamp(),
                        "read": false
                    ]
                    db.collection("notifications").addDocument(data: notificationData) { error in
                        if let error = error {
                            print("Error al crear notificación: \(error.localizedDescription)")
                        }

                        // Enviar notificación local al médico
                        sendLocalNotification()

                        isSubmitting = false
                        dismiss()
                        onDismiss()
                    }
                }
            }
    }

    private func sendLocalNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Receta Enviada"
        content.body = "La receta para \(appointment.patientName) ha sido enviada correctamente."
        content.sound = UNNotificationSound.default

        // Disparar la notificación inmediatamente
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending local notification: \(error.localizedDescription)")
            } else {
                print("Local notification scheduled successfully")
            }
        }
    }
}
