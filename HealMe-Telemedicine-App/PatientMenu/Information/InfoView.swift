import SwiftUI
import FirebaseFirestore

struct InfoView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var medicalHistory: MedicalHistory = MedicalHistory()
    @State private var ageString: String = ""
    @State private var heightString: String = ""
    @State private var weightString: String = ""
    @State private var originalMedicalHistory: MedicalHistory = MedicalHistory() // Para comparar cambios
    @State private var isEditing = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9"),
        gray: Color(hex: "808080")
    )
    
    var body: some View {
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: colors.blue))
                        .scaleEffect(1.5)
                    Text("Cargando historial médico...")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.black)
                }
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(colors.red)
                        .font(.system(size: 40))
                    Text(errorMessage)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                    Button(action: fetchMedicalHistory) {
                        Text("Reintentar")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding()
                            .background(colors.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        Text("Historial Médico")
                            .font(.system(size: 24, weight: .medium, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.top, 16)
                        
                        Group {
                            HistoryField(label: "Edad", value: $ageString, isEditing: isEditing, type: .number)
                            HistoryField(label: "Alergias", value: $medicalHistory.allergies, isEditing: isEditing, type: .text)
                            HistoryField(label: "Tipo de sangre", value: $medicalHistory.bloodType, isEditing: isEditing, type: .text)
                            HistoryField(label: "Dieta", value: $medicalHistory.diet, isEditing: isEditing, type: .text)
                            HistoryField(label: "Ejercicio", value: $medicalHistory.exercise, isEditing: isEditing, type: .text)
                            HistoryField(label: "Género", value: $medicalHistory.gender, isEditing: isEditing, type: .text)
                            HistoryField(label: "Altura (cm)", value: $heightString, isEditing: isEditing, type: .decimal)
                            HistoryField(label: "Peso (kg)", value: $weightString, isEditing: isEditing, type: .decimal)
                        }
                        .padding(.horizontal, 16)
                        
                        if isEditing {
                            HStack(spacing: 16) {
                                Button(action: saveMedicalHistory) {
                                    Text("Guardar")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(colors.green)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                
                                Button(action: { isEditing = false }) {
                                    Text("Cancelar")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(colors.gray)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        } else {
                            Button(action: { isEditing = true }) {
                                Text("Editar historial")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(colors.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchMedicalHistory()
        }
    }
    
    private func fetchMedicalHistory() {
        guard let userId = authViewModel.currentUserId else {
            errorMessage = "No se encontró el usuario autenticado."
            isLoading = false
            print("Error: No userId found in AuthViewModel")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        db.collection("patients").document(userId).getDocument { (document, error) in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = "Error al cargar el historial: \(error.localizedDescription)"
                    print("Firestore error: \(error)")
                    return
                }
                
                guard let document = document, document.exists, let data = document.data() else {
                    errorMessage = "No se encontró el historial médico."
                    print("No medical history found for userId: \(userId)")
                    return
                }
                
                medicalHistory = MedicalHistory(
                    age: data["age"] as? Int ?? 0,
                    allergies: data["allergies"] as? String ?? "",
                    bloodType: data["bloodType"] as? String ?? "",
                    diet: data["diet"] as? String ?? "",
                    exercise: data["exercise"] as? String ?? "",
                    gender: data["gender"] as? String ?? "",
                    height: data["height"] as? Double ?? 0.0,
                    weight: data["weight"] as? Double ?? 0.0
                )
                originalMedicalHistory = medicalHistory
                ageString = medicalHistory.age == 0 ? "" : String(medicalHistory.age)
                heightString = medicalHistory.height == 0.0 ? "" : String(format: "%.0f", medicalHistory.height * 100) // Metros a cm
                weightString = medicalHistory.weight == 0.0 ? "" : String(format: "%.1f", medicalHistory.weight)
                print("Medical history loaded: \(medicalHistory), ageString: \(ageString), heightString: \(heightString), weightString: \(weightString)")
            }
        }
    }
    
    private func saveMedicalHistory() {
        guard let userId = authViewModel.currentUserId else {
            errorMessage = "No se encontró el usuario autenticado."
            print("Error: No userId found in AuthViewModel")
            return
        }
        
        // Crear diccionario para datos actualizados
        var data: [String: Any] = [:]
        var errors: [String] = []
        
        // Validar edad si cambió
        if ageString != (originalMedicalHistory.age == 0 ? "" : String(originalMedicalHistory.age)) {
            guard let age = Int(ageString), age >= 0, age <= 120 else {
                errors.append("La edad debe ser un número entre 0 y 120.")
                print("Invalid age input: \(ageString)")
                return
            }
            medicalHistory.age = age
            if age != 0 { data["age"] = age }
        } else {
            medicalHistory.age = originalMedicalHistory.age
        }
        
        // Validar altura si cambió (en cm, convertir a m)
        if heightString != (originalMedicalHistory.height == 0.0 ? "" : String(format: "%.0f", originalMedicalHistory.height * 100)) {
            guard let heightCm = Double(heightString.replacingOccurrences(of: ",", with: ".")), heightCm >= 50, heightCm <= 250 else {
                errors.append("La altura debe ser un número entre 50 y 250 cm.")
                print("Invalid height input: \(heightString)")
                return
            }
            medicalHistory.height = heightCm / 100 // Convertir cm a m
            if medicalHistory.height != 0.0 { data["height"] = medicalHistory.height }
        } else {
            medicalHistory.height = originalMedicalHistory.height
        }
        
        // Validar peso si cambió
        if weightString != (originalMedicalHistory.weight == 0.0 ? "" : String(format: "%.1f", originalMedicalHistory.weight)) {
            guard let weight = Double(weightString.replacingOccurrences(of: ",", with: ".")), weight >= 10, weight <= 300 else {
                errors.append("El peso debe ser un número entre 10 y 300 kg.")
                print("Invalid weight input: \(weightString)")
                return
            }
            medicalHistory.weight = weight
            if weight != 0.0 { data["weight"] = weight }
        } else {
            medicalHistory.weight = originalMedicalHistory.weight
        }
        
        // Añadir campos de texto si cambiaron
        if medicalHistory.allergies != originalMedicalHistory.allergies, !medicalHistory.allergies.isEmpty {
            data["allergies"] = medicalHistory.allergies
        }
        if medicalHistory.bloodType != originalMedicalHistory.bloodType, !medicalHistory.bloodType.isEmpty {
            data["bloodType"] = medicalHistory.bloodType
        }
        if medicalHistory.diet != originalMedicalHistory.diet, !medicalHistory.diet.isEmpty {
            data["diet"] = medicalHistory.diet
        }
        if medicalHistory.exercise != originalMedicalHistory.exercise, !medicalHistory.exercise.isEmpty {
            data["exercise"] = medicalHistory.exercise
        }
        if medicalHistory.gender != originalMedicalHistory.gender, !medicalHistory.gender.isEmpty {
            data["gender"] = medicalHistory.gender
        }
        
        // Mostrar errores si los hay
        if !errors.isEmpty {
            errorMessage = errors.joined(separator: " ")
            isLoading = false
            return
        }
        
        // Evitar actualizar si no hay datos válidos
        guard !data.isEmpty else {
            errorMessage = "No se proporcionaron datos válidos para actualizar."
            print("No valid data to update for userId: \(userId)")
            isLoading = false
            isEditing = false
            return
        }
        
        isLoading = true
        db.collection("patients").document(userId).updateData(data) { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = "Error al guardar el historial: \(error.localizedDescription)"
                    print("Firestore update error: \(error)")
                } else {
                    originalMedicalHistory = medicalHistory // Actualizar valores originales
                    isEditing = false
                    print("Medical history updated successfully for userId: \(userId), updated fields: \(data)")
                }
            }
        }
    }
}

struct MedicalHistory {
    var age: Int
    var allergies: String
    var bloodType: String
    var diet: String
    var exercise: String
    var gender: String
    var height: Double
    var weight: Double
    
    init(
        age: Int = 0,
        allergies: String = "",
        bloodType: String = "",
        diet: String = "",
        exercise: String = "",
        gender: String = "",
        height: Double = 0.0,
        weight: Double = 0.0
    ) {
        self.age = age
        self.allergies = allergies
        self.bloodType = bloodType
        self.diet = diet
        self.exercise = exercise
        self.gender = gender
        self.height = height
        self.weight = weight
    }
}

struct HistoryField: View {
    let label: String
    @Binding var value: String
    let isEditing: Bool
    let type: FieldType
    
    enum FieldType {
        case text
        case number
        case decimal
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.black)
                .frame(width: 120, alignment: .leading)
            
            if isEditing {
                TextField("",
                    text: $value,
                    onCommit: {
                        if type == .number {
                            value = String(Int(value) ?? 0)
                        } else if type == .decimal {
                            if let doubleValue = Double(value.replacingOccurrences(of: ",", with: ".")) {
                                value = String(format: type == .decimal && label == "Altura (cm)" ? "%.0f" : "%.1f", doubleValue)
                            } else {
                                value = "0"
                            }
                        }
                    }
                )
                .keyboardType(type == .number ? .numberPad : type == .decimal ? .decimalPad : .default)
                .font(.system(size: 16, design: .rounded))
                .padding(8)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            } else {
                Text(value.isEmpty ? "No registrado" : value)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(value.isEmpty ? .gray : .black)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        InfoView()
            .environmentObject(AuthViewModel())
    }
}
