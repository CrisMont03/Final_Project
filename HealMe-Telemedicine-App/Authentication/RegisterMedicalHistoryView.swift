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
    @State private var age: Double = 0 // Cambiado a Double para Slider
    @State private var gender: String = ""
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var bloodType: String = ""
    @State private var diet: String = ""
    @State private var exercise: String = ""
    @State private var allergies: String = ""
    @State private var isSaved: Bool = false

    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9")
    )

    // Opciones para los campos
    private let genderOptions = ["Masculino", "Femenino"]
    private let bloodTypeOptions = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    private let dietOptions = ["Balanceada", "Alta en carbohidratos", "Alta en proteínas", "Vegetariana"]
    private let exerciseOptions = ["Ninguno", "A veces", "Frecuente"]

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

                    // Edad (Slider)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Edad: \(Int(age)) años")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                        Slider(value: $age, in: 0...100, step: 1)
                            .accentColor(colors.blue)
                            .padding(.horizontal)
                            .padding(.vertical)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }

                    // Género (Botones)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Género")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                        HStack(spacing: 10) {
                            ForEach(genderOptions, id: \.self) { option in
                                Button(action: {
                                    gender = option
                                }) {
                                    Text(option)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 16)
                                        .frame(maxWidth: .infinity)
                                        .background(gender == option ? colors.blue : Color.white)
                                        .foregroundColor(gender == option ? .white : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // Peso (TextField)
                        Text("Peso (kg)")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                        TextField("Ej. 10", text: $weight)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .keyboardType(.decimalPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // Altura (TextField)
                        Text("Altura (cm)")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                        TextField("Ej. 170", text: $height)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .keyboardType(.decimalPad)
                    }

                    // Grupo sanguíneo (Botones)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Grupo sanguíneo")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(bloodTypeOptions, id: \.self) { option in
                                Button(action: {
                                    bloodType = option
                                }) {
                                    Text(option)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 16)
                                        .frame(maxWidth: .infinity)
                                        .background(bloodType == option ? colors.blue : Color.white)
                                        .foregroundColor(bloodType == option ? .white : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }

                    // Dieta (Botones)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dieta")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(dietOptions, id: \.self) { option in
                                Button(action: {
                                    diet = option
                                }) {
                                    Text(option)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 16)
                                        .frame(maxWidth: .infinity)
                                        .background(diet == option ? colors.blue : Color.white)
                                        .foregroundColor(diet == option ? .white : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }

                    // Ejercicio (Botones)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ejercicio")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                        HStack(spacing: 10) {
                            ForEach(exerciseOptions, id: \.self) { option in
                                Button(action: {
                                    exercise = option
                                }) {
                                    Text(option)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 16)
                                        .frame(maxWidth: .infinity)
                                        .background(exercise == option ? colors.blue : Color.white)
                                        .foregroundColor(exercise == option ? .white : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // Alergias (TextField)
                        Text("Alergias o enfermedades")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                        TextField("Ej. Alergia al polen", text: $allergies)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }

                    if !authViewModel.errorMessage.isEmpty {
                        Text(authViewModel.errorMessage)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(colors.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Button(action: {
                        guard let userId = Auth.auth().currentUser?.uid,
                              let weightDouble = Double(weight),
                              let heightDouble = Double(height) else {
                            authViewModel.errorMessage = "Por favor, completa todos los campos con datos válidos"
                            return
                        }
                        if gender.isEmpty || bloodType.isEmpty || diet.isEmpty || exercise.isEmpty || allergies.isEmpty {
                            authViewModel.errorMessage = "Por favor, completa todos los campos"
                            return
                        }
                        authViewModel.updateMedicalHistory(
                            userId: userId,
                            age: Int(age), // Convertir Double a Int
                            gender: gender,
                            weight: weightDouble,
                            height: heightDouble,
                            bloodType: bloodType,
                            diet: diet,
                            exercise: exercise,
                            allergies: allergies,
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
                    PatientMenuView()
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
