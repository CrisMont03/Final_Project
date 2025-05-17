//
//  RegisterMedicalHistoryView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 17/05/25.
//

import SwiftUI
import FirebaseAuth

struct RegisterMedicalHistoryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var age: String = ""
    @State private var gender: String = ""
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var bloodType: String = ""
    @State private var diet: String = ""
    @State private var exercise: String = ""
    @State private var allergies: String = ""
    @State private var medicalCondition: String = ""
    @State private var isSaved: Bool = false

    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9")
    )

    var body: some View {
        ZStack {
            colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .center, spacing: 24) {
                    VStack(alignment: .center, spacing: 5) {
                        Text("Historial Médico")
                            .font(.system(size: 32, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Completa tu información médica:")
                            .font(.system(size: 16, weight: .light, design: .rounded))
                            .foregroundColor(.primary)
                    }

                    TextField("Edad", text: $age)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .keyboardType(.numberPad)

                    TextField("Género", text: $gender)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )

                    TextField("Peso (kg)", text: $weight)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .keyboardType(.decimalPad)

                    TextField("Altura (cm)", text: $height)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .keyboardType(.decimalPad)

                    TextField("Grupo sanguíneo", text: $bloodType)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )

                    TextField("Dieta", text: $diet)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )

                    TextField("Ejercicio", text: $exercise)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )

                    TextField("Alergias o enfermedades", text: $allergies)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )

                    TextField("Condición médica", text: $medicalCondition)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )

                    if !authViewModel.errorMessage.isEmpty {
                        Text(authViewModel.errorMessage)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(colors.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Button(action: {
                        guard let userId = Auth.auth().currentUser?.uid,
                              let ageInt = Int(age),
                              let weightDouble = Double(weight),
                              let heightDouble = Double(height) else {
                            authViewModel.errorMessage = "Por favor, completa todos los campos con datos válidos"
                            return
                        }
                        if gender.isEmpty || bloodType.isEmpty || diet.isEmpty || exercise.isEmpty || allergies.isEmpty || medicalCondition.isEmpty {
                            authViewModel.errorMessage = "Por favor, completa todos los campos"
                            return
                        }
                        authViewModel.updateMedicalHistory(
                            userId: userId,
                            age: ageInt,
                            gender: gender,
                            weight: weightDouble,
                            height: heightDouble,
                            bloodType: bloodType,
                            diet: diet,
                            exercise: exercise,
                            allergies: allergies,
                            medicalCondition: medicalCondition
                        ) { success in
                            if success {
                                isSaved = true
                            }
                        }
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }) {
                        Text("Guardar")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(colors.green)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .navigationDestination(isPresented: $isSaved) {
                    PatientView()
                        .environmentObject(authViewModel)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct RegisterMedicalHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterMedicalHistoryView()
            .environmentObject(AuthViewModel())
    }
}
