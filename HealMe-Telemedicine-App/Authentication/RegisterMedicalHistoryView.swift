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
    @State private var age: Double = 0
    @State private var gender: String = ""
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var bloodType: String = ""
    @State private var diet: String = ""
    @State private var exercise: String = ""
    @State private var allergies: String = ""
    @State private var isSaved: Bool = false
    @State private var errorMessage: String = ""

    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9")
    )

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
                            .foregroundColor(.black)
                        Text("Completa tu información médica:")
                            .font(.system(size: 16, weight: .light, design: .rounded))
                            .foregroundColor(.black)
                    }

                    // Edad (Slider)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Edad: \(Int(age)) años")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.black)
                        Slider(value: $age, in: 0...100, step: 1)
                            .accentColor(colors.blue)
                            .padding(.horizontal)
                            .padding(.vertical)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
                            )
                    }

                    // Género (Botones)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Género")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.black)
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
                                        .foregroundColor(gender == option ? .white : .black.opacity(0.5))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                    
                    // Peso (TextField)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Peso (kg)")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.black)
                        TextField(
                            "",
                            text: $weight,
                            prompt: Text("Ej. 70").foregroundColor(.black.opacity(0.5))
                        )
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
                            )
                            .keyboardType(.decimalPad)
                    }
                    
                    // Altura (TextField)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Altura (cm)")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.black)
                        TextField(
                            "",
                            text: $height,
                            prompt: Text("Ej. 170").foregroundColor(.black.opacity(0.5))
                        )
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
                            )
                            .keyboardType(.decimalPad)
                    }

                    // Grupo sanguíneo (Botones)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Grupo sanguíneo")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.black)
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
                                        .foregroundColor(bloodType == option ? .white : .black.opacity(0.5))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }

                    // Dieta (Botones)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dieta")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.black)
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
                                        .foregroundColor(diet == option ? .white : .black.opacity(0.5))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }

                    // Ejercicio (Botones)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ejercicio")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.black)
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
                                        .foregroundColor(exercise == option ? .white : .black.opacity(0.5))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                    
                    // Alergias (TextField)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Alergias o enfermedades")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.black)
                        TextField(
                            "",
                            text: $allergies,
                            prompt: Text("Ej. Alergia al polen").foregroundColor(.black.opacity(0.5))
                        )
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
                            )
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(colors.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Button(action: {
                        guard let weightDouble = Double(weight), weightDouble > 0 else {
                            errorMessage = "Ingrese un peso válido mayor a 0"
                            return
                        }
                        guard let heightDouble = Double(height), heightDouble > 0 else {
                            errorMessage = "Ingrese una altura válida mayor a 0"
                            return
                        }
                        guard age >= 0 else {
                            errorMessage = "Ingrese una edad válida"
                            return
                        }
                        guard !gender.isEmpty else {
                            errorMessage = "Seleccione un género"
                            return
                        }
                        guard !bloodType.isEmpty else {
                            errorMessage = "Seleccione un grupo sanguíneo"
                            return
                        }
                        guard !diet.isEmpty else {
                            errorMessage = "Seleccione una dieta"
                            return
                        }
                        guard !exercise.isEmpty else {
                            errorMessage = "Seleccione un nivel de ejercicio"
                            return
                        }
                        guard !allergies.isEmpty else {
                            errorMessage = "Ingrese información sobre alergias"
                            return
                        }
                        guard let userId = Auth.auth().currentUser?.uid else {
                            errorMessage = "Usuario no autenticado"
                            return
                        }

                        let data: [String: Any] = [
                            "age": age,
                            "gender": gender,
                            "weight": weightDouble,
                            "height": heightDouble,
                            "bloodType": bloodType,
                            "diet": diet,
                            "exercise": exercise,
                            "allergies": allergies
                        ]
                        print("Saving medical history: \(data)")
                        authViewModel.updateMedicalHistory(
                            userId: userId,
                            age: Int(age),
                            gender: gender,
                            weight: weightDouble,
                            height: heightDouble,
                            bloodType: bloodType,
                            diet: diet,
                            exercise: exercise,
                            allergies: allergies
                        ) { success in
                            if success {
                                authViewModel.signOut()
                                isSaved = true
                            } else {
                                errorMessage = "Error al guardar los datos"
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
                    LoginView()
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

